// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_contents.h"

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

namespace {

using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = UberSDFPipeline::VertexShader;
using FS = UberSDFPipeline::FragmentShader;

Scalar ToShaderType(UberSDFParameters::Type type) {
  switch (type) {
    case UberSDFParameters::Type::kCircle:
      return 0.0f;
    case UberSDFParameters::Type::kRect:
      return 1.0f;
    case UberSDFParameters::Type::kOval:
      return 2.0f;
    case UberSDFParameters::Type::kRoundedRect:
      return 3.0f;
    case UberSDFParameters::Type::kRoundedSuperellipse:
      return 4.0f;
  }
}

Scalar ToShaderStrokeJoin(Join join) {
  switch (join) {
    case Join::kMiter:
      return 0.0f;
    case Join::kBevel:
      return 1.0f;
    case Join::kRound:
      return 2.0f;
  }
}

}  // namespace

std::unique_ptr<UberSDFContents> UberSDFContents::Make(
    const UberSDFParameters& params,
    std::unique_ptr<Geometry> geometry) {
  return std::unique_ptr<UberSDFContents>(
      new UberSDFContents(params, std::move(geometry)));
}

UberSDFContents::UberSDFContents(const UberSDFParameters& params,
                                 std::unique_ptr<Geometry> geometry)
    : params_(params), geometry_(std::move(geometry)) {}

UberSDFContents::~UberSDFContents() = default;

bool UberSDFContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.type = ToShaderType(params_.type);
  frag_info.color =
      params_.color.WithAlpha(params_.color.alpha * GetOpacityFactor());
  frag_info.center = params_.center;
  frag_info.size = params_.size;
  frag_info.radii =
      Vector4(params_.radii.bottom_right.width, params_.radii.top_right.width,
              params_.radii.bottom_left.width, params_.radii.top_left.width);
  frag_info.radii_right =
      Vector4(params_.radii.bottom_right.height, params_.radii.top_right.height,
              params_.radii.bottom_left.height, params_.radii.top_left.height);
  frag_info.stroked = params_.stroke ? 1.0f : 0.0f;
  frag_info.stroke_width = params_.stroke ? params_.stroke->width : 0.0f;
  frag_info.stroke_join =
      params_.stroke ? ToShaderStrokeJoin(params_.stroke->join) : 0.0f;
  frag_info.aa_pixels = UberSDFParameters::kAntialiasPixels;
  frag_info.superellipse_degrees_top = params_.superellipse_degrees_top;
  frag_info.superellipse_degrees_right = params_.superellipse_degrees_right;
  frag_info.superellipse_semi_axes_top = params_.superellipse_semi_axes_top;
  frag_info.superellipse_semi_axes_right = params_.superellipse_semi_axes_right;
  frag_info.angle_spans_top = params_.angle_spans_top;
  frag_info.angle_spans_right = params_.angle_spans_right;
  frag_info.octant_offsets_c = params_.octant_offsets_c;
  frag_info.radii_width = params_.radii_width;
  frag_info.radii_height = params_.radii_height;
  frag_info.circle_centers_top_x = params_.circle_centers_top_x;
  frag_info.circle_centers_top_y = params_.circle_centers_top_y;
  frag_info.circle_centers_right_x = params_.circle_centers_right_x;
  frag_info.circle_centers_right_y = params_.circle_centers_right_y;
  frag_info.superellipse_scales_x = params_.superellipse_scales_x;
  frag_info.superellipse_scales_y = params_.superellipse_scales_y;
  frag_info.quadrant_centers_x = params_.quadrant_centers_x;
  frag_info.quadrant_centers_y = params_.quadrant_centers_y;
  frag_info.quadrant_splits = params_.quadrant_splits;

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetUberSDFPipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, GetGeometry(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("UberSDF");
        return true;
      },
      /*force_stencil=*/false,
      /*create_geom_callback=*/
      [geometry_result = std::move(geometry_result)](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass,
          const Geometry* geometry) { return geometry_result; });
}

std::optional<Rect> UberSDFContents::GetCoverage(const Entity& entity) const {
  return GetGeometry()->GetCoverage(entity.GetTransform());
}

const Geometry* UberSDFContents::GetGeometry() const {
  return geometry_.get();
}

Color UberSDFContents::GetColor() const {
  return params_.color;
}

bool UberSDFContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  params_.color = color_filter_proc(params_.color);
  return true;
}

}  // namespace impeller

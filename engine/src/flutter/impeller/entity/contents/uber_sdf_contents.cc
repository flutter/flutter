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

}  // namespace

std::unique_ptr<UberSDFContents> UberSDFContents::Make(
    UberSDFParameters params,
    std::unique_ptr<Geometry> geometry) {
  return std::unique_ptr<UberSDFContents>(
      new UberSDFContents(params, std::move(geometry)));
}

UberSDFContents::UberSDFContents(UberSDFParameters params,
                                 std::unique_ptr<Geometry> geometry)
    : params_(params), geometry_(std::move(geometry)) {}

UberSDFContents::~UberSDFContents() = default;

bool UberSDFContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info = {};
  frag_info.type =
      params_.GetType() == UberSDFParameters::Type::kCircle ? 0.0f : 1.0f;
  frag_info.color = params_.GetColor().WithAlpha(params_.GetColor().alpha *
                                                 GetOpacityFactor());
  frag_info.center = params_.GetCenter();
  frag_info.size = params_.GetSize();
  frag_info.stroked = params_.GetStroke() ? 1.0f : 0.0f;
  if (params_.GetStroke()) {
    frag_info.stroke_width = params_.GetStroke()->width;
    switch (params_.GetStroke()->join) {
      case Join::kMiter:
        frag_info.stroke_join = 0.0f;
        break;
      case Join::kBevel:
        frag_info.stroke_join = 1.0f;
        break;
      case Join::kRound:
        frag_info.stroke_join = 2.0f;
        break;
    }
  }
  frag_info.aa_pixels = UberSDFParameters::kAntialiasPadding;

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
  return params_.GetColor();
}

bool UberSDFContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  params_.SetColor(color_filter_proc(params_.GetColor()));
  return true;
}

}  // namespace impeller

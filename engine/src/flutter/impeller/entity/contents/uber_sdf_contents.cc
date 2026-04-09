// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_contents.h"

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

namespace {
using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = UberSDFPipeline::VertexShader;
using FS = UberSDFPipeline::FragmentShader;

}  // namespace

std::unique_ptr<UberSDFContents> UberSDFContents::MakeRect(
    Color color,
    Scalar stroke_width,
    Join stroke_join,
    bool stroked,
    const FillRectGeometry* geometry) {
  Rect bounding_box = geometry->GetRect();
  Scalar aa_padding = 1.0f;
  return std::make_unique<UberSDFContents>(Type::kRect, bounding_box, color,
                                           stroke_width, stroke_join, stroked,
                                           geometry, aa_padding);
}

std::unique_ptr<UberSDFContents> UberSDFContents::MakeCircle(
    Color color,
    bool stroked,
    const CircleGeometry* geometry) {
  Point center = geometry->GetCenter();
  Scalar radius = geometry->GetRadius();
  Rect bounding_box = Rect::MakeXYWH(center.x - radius, center.y - radius,
                                     radius * 2, radius * 2);
  Scalar aa_padding = geometry->GetAntialiasPadding();
  return std::unique_ptr<UberSDFContents>(new UberSDFContents(
      Type::kCircle, bounding_box, color, geometry->GetStrokeWidth(),
      Join::kMiter, stroked, geometry, aa_padding));
}

UberSDFContents::UberSDFContents(Type type,
                                 Rect bounding_box,
                                 Color color,
                                 Scalar stroke_width,
                                 Join stroke_join,
                                 bool stroked,
                                 const Geometry* geometry,
                                 Scalar aa_padding)
    : type_(type),
      bounding_box_(bounding_box),
      color_(color),
      stroke_width_(stroke_width),
      stroke_join_(stroke_join),
      stroked_(stroked),
      geometry_(geometry),
      aa_padding_(aa_padding) {}

UberSDFContents::~UberSDFContents() = default;

bool UberSDFContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.center = bounding_box_.GetCenter();
  frag_info.size =
      Point(bounding_box_.GetWidth() / 2.0f, bounding_box_.GetHeight() / 2.0f);
  frag_info.stroke_width = stroke_width_;
  switch (stroke_join_) {
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
  frag_info.aa_pixels = aa_padding_;
  frag_info.stroked = stroked_ ? 1.0f : 0.0f;
  frag_info.type = type_ == Type::kCircle ? 0.0f : 1.0f;

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
  return geometry_;
}

Color UberSDFContents::GetColor() const {
  return color_;
}

bool UberSDFContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  color_ = color_filter_proc(color_);
  return true;
}

}  // namespace impeller

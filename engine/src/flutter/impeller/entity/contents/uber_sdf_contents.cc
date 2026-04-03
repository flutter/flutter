// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_contents.h"

#include <memory>

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

std::unique_ptr<UberSDFContents> UberSDFContents::MakeRect(
    Color color,
    Scalar stroke_width,
    Join stroke_join,
    bool stroked,
    const FillRectGeometry* geometry) {
  return std::make_unique<RectSDFContents>(color, stroke_width, stroke_join,
                                           stroked, geometry);
}

std::unique_ptr<UberSDFContents> UberSDFContents::MakeCircle(
    Color color,
    bool stroked,
    const CircleGeometry* geometry) {
  return std::make_unique<CircleSDFContents>(color, stroked, geometry);
}

UberSDFContents::UberSDFContents(Color color,
                                 bool stroked,
                                 Scalar stroke_width,
                                 Join stroke_join)
    : color_(color),
      stroked_(stroked),
      stroke_width_(stroke_width),
      stroke_join_(stroke_join) {}

UberSDFContents::~UberSDFContents() = default;

void UberSDFContents::SetCommonUniforms(FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = stroked_ ? 1.0f : 0.0f;
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
}

bool UberSDFContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;

  if (!BindData(renderer, entity, pass, frag_info)) {
    return false;
  }

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  auto pipeline_callback = [&renderer](ContentContextOptions options) {
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

Color UberSDFContents::GetColor() const {
  return color_;
}

bool UberSDFContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  color_ = color_filter_proc(color_);
  return true;
}

// CircleSDFContents

CircleSDFContents::CircleSDFContents(Color color,
                                     bool stroked,
                                     const CircleGeometry* geometry)
    : UberSDFContents(color, stroked, geometry->GetStrokeWidth(), Join::kMiter),
      geometry_(geometry) {}

CircleSDFContents::~CircleSDFContents() = default;

const Geometry* CircleSDFContents::GetGeometry() const {
  return geometry_;
}

bool CircleSDFContents::BindData(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass,
                                 FS::FragInfo& frag_info) const {
  SetCommonUniforms(frag_info);
  frag_info.type = 0.0f;  // kCircle
  frag_info.center = geometry_->GetCenter();
  Scalar radius = geometry_->GetRadius();
  frag_info.size = Point(radius, radius);
  frag_info.aa_pixels = geometry_->GetAntialiasPadding();
  return true;
}

// RectSDFContents

RectSDFContents::RectSDFContents(Color color,
                                 Scalar stroke_width,
                                 Join stroke_join,
                                 bool stroked,
                                 const FillRectGeometry* geometry)
    : UberSDFContents(color, stroked, stroke_width, stroke_join),
      geometry_(geometry) {}

RectSDFContents::~RectSDFContents() = default;

const Geometry* RectSDFContents::GetGeometry() const {
  return geometry_;
}

bool RectSDFContents::BindData(const ContentContext& renderer,
                               const Entity& entity,
                               RenderPass& pass,
                               FS::FragInfo& frag_info) const {
  SetCommonUniforms(frag_info);
  frag_info.type = 1.0f;  // kRect
  Rect rect = geometry_->GetRect();
  frag_info.center = rect.GetCenter();
  frag_info.size = Point(rect.GetWidth() / 2.0f, rect.GetHeight() / 2.0f);
  // Rects were hardcoded to 1.0 aa_padding in the original implementation.
  frag_info.aa_pixels = 1.0f;
  return true;
}

}  // namespace impeller

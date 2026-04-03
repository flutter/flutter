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

template <typename T>
bool UberSDFContents<T>::Render(const ContentContext& renderer,
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

template <>
bool UberSDFContents<CircleGeometry>::BindData(const ContentContext& renderer,
                                               const Entity& entity,
                                               RenderPass& pass,
                                               FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = geometry_->GetStrokeWidth() < 0 ? 0.0f : 1.0f;
  frag_info.stroke_width = geometry_->GetStrokeWidth();
  frag_info.stroke_join = 0.0f;  // kMiter
  frag_info.type = 0.0f;         // kCircle
  frag_info.center = geometry_->GetCenter();
  Scalar radius = geometry_->GetRadius();
  frag_info.size = Point(radius, radius);
  frag_info.aa_pixels = geometry_->GetAntialiasPadding();
  return true;
}

template <>
bool UberSDFContents<FillRectGeometry>::BindData(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = 0.0f;
  frag_info.stroke_width = 0.0f;
  frag_info.stroke_join = 0.0f;  // kMiter
  frag_info.type = 1.0f;         // kRect
  Rect rect = geometry_->GetRect();
  frag_info.center = rect.GetCenter();
  frag_info.size = Point(rect.GetWidth() / 2.0f, rect.GetHeight() / 2.0f);
  frag_info.aa_pixels = 1.0f;
  return true;
}

template <>
bool UberSDFContents<StrokeRectGeometry>::BindData(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    FS::FragInfo& frag_info) const {
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.stroked = 1.0f;
  frag_info.stroke_width = geometry_->GetStrokeWidth();
  switch (geometry_->GetStrokeJoin()) {
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
  frag_info.type = 1.0f;  // kRect
  Rect rect = geometry_->GetRect();
  frag_info.center = rect.GetCenter();
  frag_info.size = Point(rect.GetWidth() / 2.0f, rect.GetHeight() / 2.0f);
  frag_info.aa_pixels = 1.0f;
  return true;
}

template class UberSDFContents<CircleGeometry>;
template class UberSDFContents<FillRectGeometry>;
template class UberSDFContents<StrokeRectGeometry>;

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/circle_contents.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/geometry/point.h"

namespace impeller {

namespace {

constexpr Scalar kAntialiasPadding = 1.0f;

using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = CirclePipeline::VertexShader;
using FS = CirclePipeline::FragmentShader;

}  // namespace

std::unique_ptr<CircleContents> CircleContents::Make(
    Color color,
    const Point& center,
    Scalar radius,
    std::optional<Scalar> stroke_width) {
  auto stroke_padding = stroke_width ? stroke_width.value() * 0.5f : 0.0f;
  Rect geometry_rect = Rect::MakeXYWH(center.x - radius, center.y - radius,
                                      radius * 2, radius * 2);
  std::unique_ptr<FillRectGeometry> geometry =
      std::make_unique<FillRectGeometry>(geometry_rect.Expand(stroke_padding));
  return std::unique_ptr<CircleContents>(new CircleContents(
      color, center, radius, stroke_width, std::move(geometry)));
}

CircleContents::CircleContents(Color color,
                               const Point& center,
                               Scalar radius,
                               std::optional<Scalar> stroke_width,
                               std::unique_ptr<FillRectGeometry> geometry)
    : color_(color),
      center_(center),
      radius_(radius),
      stroke_width_(stroke_width),
      geometry_(std::move(geometry)) {
  geometry_->SetAntialiasPadding(kAntialiasPadding);
}

bool CircleContents::Render(const ContentContext& renderer,
                            const Entity& entity,
                            RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.center = center_;
  frag_info.radius = radius_;
  frag_info.stroke_width = stroke_width_.value_or(0.0f);
  frag_info.aa_pixels = kAntialiasPadding;
  frag_info.stroked = stroke_width_ ? 1.0f : 0.0f;

  auto geometry_result = geometry_->GetPositionBuffer(renderer, entity, pass);

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetCirclePipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, geometry_.get(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("Circle");
        return true;
      },
      /*force_stencil=*/false,
      /*create_geom_callback=*/
      [geometry_result = std::move(geometry_result)](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass,
          const Geometry* geometry) { return geometry_result; });
}

std::optional<Rect> CircleContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

const Geometry* CircleContents::GetGeometry() const {
  return geometry_.get();
}

}  // namespace impeller

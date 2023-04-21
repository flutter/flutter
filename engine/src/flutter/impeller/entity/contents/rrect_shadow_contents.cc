// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/rrect_shadow_contents.h"
#include <optional>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {

RRectShadowContents::RRectShadowContents() = default;

RRectShadowContents::~RRectShadowContents() = default;

void RRectShadowContents::SetRRect(std::optional<Rect> rect,
                                   Scalar corner_radius) {
  rect_ = rect;
  corner_radius_ = corner_radius;
}

void RRectShadowContents::SetSigma(Sigma sigma) {
  sigma_ = sigma;
}

void RRectShadowContents::SetColor(Color color) {
  color_ = color.Premultiply();
}

Color RRectShadowContents::GetColor() const {
  return color_;
}

std::optional<Rect> RRectShadowContents::GetCoverage(
    const Entity& entity) const {
  if (!rect_.has_value()) {
    return std::nullopt;
  }

  Scalar radius = sigma_.sigma * 2;

  auto ltrb = rect_->GetLTRB();
  Rect bounds = Rect::MakeLTRB(ltrb[0] - radius, ltrb[1] - radius,
                               ltrb[2] + radius, ltrb[3] + radius);
  return bounds.TransformBounds(entity.GetTransformation());
};

bool RRectShadowContents::Render(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  if (!rect_.has_value()) {
    return true;
  }

  using VS = RRectBlurPipeline::VertexShader;
  using FS = RRectBlurPipeline::FragmentShader;

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;

  auto blur_radius = sigma_.sigma * 2;
  auto positive_rect = rect_->GetPositive();
  {
    auto left = -blur_radius;
    auto top = -blur_radius;
    auto right = positive_rect.size.width + blur_radius;
    auto bottom = positive_rect.size.height + blur_radius;

    vtx_builder.AddVertices({
        {Point(left, top)},
        {Point(right, top)},
        {Point(left, bottom)},
        {Point(left, bottom)},
        {Point(right, top)},
        {Point(right, bottom)},
    });
  }

  Command cmd;
  cmd.label = "RRect Shadow";
  auto opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangle;
  cmd.pipeline = renderer.GetRRectBlurPipeline(opts);
  cmd.stencil_reference = entity.GetStencilDepth();

  cmd.BindVertices(vtx_builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

  VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                   entity.GetTransformation() *
                   Matrix::MakeTranslation({positive_rect.origin});
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frame_info));

  FS::FragInfo frag_info;
  frag_info.color = color_;
  frag_info.blur_sigma = sigma_.sigma;
  frag_info.rect_size = Point(positive_rect.size);
  frag_info.corner_radius =
      std::min(corner_radius_, std::min(positive_rect.size.width / 2.0f,
                                        positive_rect.size.height / 2.0f));
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  if (!pass.AddCommand(std::move(cmd))) {
    return false;
  }

  return true;
}

}  // namespace impeller

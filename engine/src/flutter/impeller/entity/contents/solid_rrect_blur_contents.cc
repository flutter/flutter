// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/solid_rrect_blur_contents.h"
#include <optional>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

namespace {
// Generous padding to make sure blurs with large sigmas are fully visible.
// Used to expand the geometry around the rrect.
Scalar PadForSigma(Scalar sigma) {
  return sigma * 4.0;
}
}  // namespace

SolidRRectBlurContents::SolidRRectBlurContents() = default;

SolidRRectBlurContents::~SolidRRectBlurContents() = default;

void SolidRRectBlurContents::SetRRect(std::optional<Rect> rect,
                                      Scalar corner_radius) {
  rect_ = rect;
  corner_radius_ = corner_radius;
}

void SolidRRectBlurContents::SetSigma(Sigma sigma) {
  sigma_ = sigma;
}

void SolidRRectBlurContents::SetColor(Color color) {
  color_ = color.Premultiply();
}

Color SolidRRectBlurContents::GetColor() const {
  return color_;
}

std::optional<Rect> SolidRRectBlurContents::GetCoverage(
    const Entity& entity) const {
  if (!rect_.has_value()) {
    return std::nullopt;
  }

  Scalar radius = PadForSigma(sigma_.sigma);

  auto ltrb = rect_->GetLTRB();
  Rect bounds = Rect::MakeLTRB(ltrb[0] - radius, ltrb[1] - radius,
                               ltrb[2] + radius, ltrb[3] + radius);
  return bounds.TransformBounds(entity.GetTransform());
};

bool SolidRRectBlurContents::Render(const ContentContext& renderer,
                                    const Entity& entity,
                                    RenderPass& pass) const {
  // Early return if sigma is close to zero to avoid rendering NaNs.
  if (!rect_.has_value() || std::fabs(sigma_.sigma) <= kEhCloseEnough) {
    return true;
  }

  using VS = RRectBlurPipeline::VertexShader;
  using FS = RRectBlurPipeline::FragmentShader;

  VertexBufferBuilder<VS::PerVertexData> vtx_builder;

  // Clamp the max kernel width/height to 1000.
  auto blur_sigma = std::min(sigma_.sigma, 250.0f);
  // Increase quality by making the radius a bit bigger than the typical
  // sigma->radius conversion we use for slower blurs.
  auto blur_radius = PadForSigma(blur_sigma);
  auto positive_rect = rect_->GetPositive();
  {
    auto left = -blur_radius;
    auto top = -blur_radius;
    auto right = positive_rect.GetWidth() + blur_radius;
    auto bottom = positive_rect.GetHeight() + blur_radius;

    vtx_builder.AddVertices({
        {Point(left, top)},
        {Point(right, top)},
        {Point(left, bottom)},
        {Point(right, bottom)},
    });
  }

  ContentContextOptions opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangleStrip;
  Color color = color_;
  if (entity.GetBlendMode() == BlendMode::kClear) {
    opts.is_for_rrect_blur_clear = true;
    color = Color::White();
  }

  VS::FrameInfo frame_info;
  frame_info.mvp = pass.GetOrthographicTransform() * entity.GetTransform() *
                   Matrix::MakeTranslation(positive_rect.GetOrigin());

  FS::FragInfo frag_info;
  frag_info.color = color;
  frag_info.blur_sigma = blur_sigma;
  frag_info.rect_size = Point(positive_rect.GetSize());
  frag_info.corner_radius =
      std::min(corner_radius_, std::min(positive_rect.GetWidth() / 2.0f,
                                        positive_rect.GetHeight() / 2.0f));

  pass.SetCommandLabel("RRect Shadow");
  pass.SetPipeline(renderer.GetRRectBlurPipeline(opts));
  pass.SetStencilReference(entity.GetClipDepth());
  pass.SetVertexBuffer(
      vtx_builder.CreateVertexBuffer(renderer.GetTransientsBuffer()));
  VS::BindFrameInfo(pass,
                    renderer.GetTransientsBuffer().EmplaceUniform(frame_info));
  FS::BindFragInfo(pass,
                   renderer.GetTransientsBuffer().EmplaceUniform(frag_info));

  if (!pass.Draw().ok()) {
    return false;
  }

  return true;
}

bool SolidRRectBlurContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  color_ = color_filter_proc(color_);
  return true;
}

}  // namespace impeller

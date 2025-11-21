// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/solid_rrect_like_blur_contents.h"
#include <optional>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

namespace {
// Generous padding to make sure blurs with large sigmas are fully visible. Used
// to expand the geometry around the rrect.  Larger sigmas have more subtle
// gradients so they need larger padding to avoid hard cutoffs.  Sigma is
// maximized to 3.5 since that should cover 99.95% of all samples.  3.0 should
// cover 99.7% but that was seen to be not enough for large sigmas.
Scalar PadForSigma(Scalar sigma) {
  Scalar scalar = std::min((1.0f / 47.6f) * sigma + 2.5f, 3.5f);
  return sigma * scalar;
}
}  // namespace

SolidRRectLikeBlurContents::SolidRRectLikeBlurContents() = default;

SolidRRectLikeBlurContents::~SolidRRectLikeBlurContents() = default;

void SolidRRectLikeBlurContents::SetShape(Rect rect, Scalar corner_radius) {
  rect_ = rect;
  corner_radius_ = corner_radius;
}

void SolidRRectLikeBlurContents::SetSigma(Sigma sigma) {
  sigma_ = sigma;
}

void SolidRRectLikeBlurContents::SetColor(Color color) {
  color_ = color.Premultiply();
}

Color SolidRRectLikeBlurContents::GetColor() const {
  return color_;
}

static Point eccentricity(Point v, double sInverse) {
  Point vOverS = v * sInverse * 0.5;
  Point vOverS_squared = -(vOverS * vOverS);
  return {std::exp(vOverS_squared.x), std::exp(vOverS_squared.y)};
}

static Scalar kTwoOverSqrtPi = 2.0 / std::sqrt(kPi);

// use crate::math::compute_erf7;
static Scalar computeErf7(Scalar x) {
  x *= kTwoOverSqrtPi;
  float xx = x * x;
  x = x + (0.24295 + (0.03395 + 0.0104 * xx) * xx) * (x * xx);
  return x / sqrt(1.0 + x * x);
}

static Point NegPos(Scalar v) {
  return {std::min(v, 0.0f), std::max(v, 0.0f)};
}

bool SolidRRectLikeBlurContents::PopulateFragContext(PassContext& pass_context,
                                                     Scalar blurSigma,
                                                     Point center,
                                                     Point rSize,
                                                     Scalar radius) {
  Scalar sigma = std::max(blurSigma * kSqrt2, 1.f);

  pass_context.center = rSize * 0.5f;
  pass_context.minEdge = std::min(rSize.x, rSize.y);
  double rMax = 0.5 * pass_context.minEdge;
  double r0 = std::min(std::hypot(radius, sigma * 1.15), rMax);
  pass_context.r1 = std::min(std::hypot(radius, sigma * 2.0), rMax);

  pass_context.exponent = 2.0 * pass_context.r1 / r0;

  pass_context.sInv = 1.0 / sigma;

  // Pull in long end (make less eccentric).
  Point eccentricV = eccentricity(rSize, pass_context.sInv);
  double delta = 1.25 * sigma * (eccentricV.x - eccentricV.y);
  rSize += NegPos(delta);

  pass_context.adjust = rSize * 0.5 - pass_context.r1;
  pass_context.exponentInv = 1.0 / pass_context.exponent;
  pass_context.scale =
      0.5 * computeErf7(pass_context.sInv * 0.5 *
                        (std::max(rSize.x, rSize.y) - 0.5 * radius));

  return pass_context.center.IsFinite() &&           //
         pass_context.adjust.IsFinite() &&           //
         std::isfinite(pass_context.minEdge) &&      //
         std::isfinite(pass_context.r1) &&           //
         std::isfinite(pass_context.exponent) &&     //
         std::isfinite(pass_context.sInv) &&         //
         std::isfinite(pass_context.exponentInv) &&  //
         std::isfinite(pass_context.scale);
}

std::optional<Rect> SolidRRectLikeBlurContents::GetCoverage(
    const Entity& entity) const {
  Scalar radius = PadForSigma(sigma_.sigma);

  return rect_.Expand(radius).TransformBounds(entity.GetTransform());
}

bool SolidRRectLikeBlurContents::Render(const ContentContext& renderer,
                                        const Entity& entity,
                                        RenderPass& pass) const {
  using VS = RrectLikeBlurVertexShader;

  Matrix basis_invert = entity.GetTransform().Basis().Invert();
  Vector2 max_sigmas =
      Vector2((basis_invert * Vector2(500.f, 0.f)).GetLength(),
              (basis_invert * Vector2(0.f, 500.f)).GetLength());
  Scalar max_sigma = std::min(max_sigmas.x, max_sigmas.y);
  // Clamp the max kernel width/height to 1000 (@ 2x) to limit the extent
  // of the blur and to kEhCloseEnough to prevent NaN calculations
  // trying to evaluate a Gaussian distribution with a sigma of 0.
  auto blur_sigma = std::clamp(sigma_.sigma, kEhCloseEnough, max_sigma);
  // Increase quality by making the radius a bit bigger than the typical
  // sigma->radius conversion we use for slower blurs.
  Scalar blur_radius = PadForSigma(blur_sigma);
  Rect positive_rect = rect_.GetPositive();
  Scalar left = -blur_radius;
  Scalar top = -blur_radius;
  Scalar right = positive_rect.GetWidth() + blur_radius;
  Scalar bottom = positive_rect.GetHeight() + blur_radius;

  ContentContextOptions opts = OptionsFromPassAndEntity(pass, entity);
  opts.primitive_type = PrimitiveType::kTriangleStrip;
  Color color = color_;
  if (entity.GetBlendMode() == BlendMode::kClear) {
    opts.is_for_rrect_blur_clear = true;
    color = Color::White();
  }

  std::array<VS::PerVertexData, 4> vertices = {
      VS::PerVertexData{Point(left, top)},
      VS::PerVertexData{Point(right, top)},
      VS::PerVertexData{Point(left, bottom)},
      VS::PerVertexData{Point(right, bottom)},
  };

  PassContext pass_context = {
      .opts = opts,
  };

  Scalar radius = std::min(std::clamp(corner_radius_, kEhCloseEnough,
                                      positive_rect.GetWidth() * 0.5f),
                           std::clamp(corner_radius_, kEhCloseEnough,
                                      positive_rect.GetHeight() * 0.5f));
  if (!PopulateFragContext(pass_context, blur_sigma, positive_rect.GetCenter(),
                           Point(positive_rect.GetSize()), radius)) {
    return true;
  }

  if (!SetPassInfo(pass, renderer, pass_context)) {
    return true;
  }

  VS::FrameInfo frame_info;
  frame_info.mvp = Entity::GetShaderTransform(
      entity.GetShaderClipDepth(), pass,
      entity.GetTransform() *
          Matrix::MakeTranslation(positive_rect.GetOrigin()));

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  pass.SetVertexBuffer(CreateVertexBuffer(vertices, data_host_buffer));
  VS::BindFrameInfo(pass, data_host_buffer.EmplaceUniform(frame_info));

  if (!pass.Draw().ok()) {
    return false;
  }

  return true;
}

bool SolidRRectLikeBlurContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  color_ = color_filter_proc(color_);
  return true;
}

Vector4 SolidRRectLikeBlurContents::Concat(Vector2& a, Vector2& b) {
  return {a.x, a.y, b.x, b.y};
}

}  // namespace impeller

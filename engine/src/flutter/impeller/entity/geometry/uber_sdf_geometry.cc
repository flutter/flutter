// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

UberSDFGeometry::UberSDFGeometry(const UberSDFParameters& params)
    : params_(params) {
  base_bounds_ = Rect::MakeLTRB(
      /*left=*/params_.center.x - params_.size.x,
      /*top=*/params_.center.y - params_.size.y,
      /*right=*/params_.center.x + params_.size.x,
      /*bottom=*/params_.center.y + params_.size.y);
  if (params_.stroke) {
    base_bounds_ = base_bounds_.Expand(params_.stroke->width * 0.5);
  }
}

UberSDFGeometry::~UberSDFGeometry() = default;

GeometryResult UberSDFGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  Vector2 transform_basis_scaling = entity.GetTransform().GetBasisScaleXY();
  Vector2 device_pixel_size = {
      transform_basis_scaling.x != 0 ? 1.0f / transform_basis_scaling.x : 0,
      transform_basis_scaling.y != 0 ? 1.0f / transform_basis_scaling.y : 0};

  Vector2 aa_padding = UberSDFParameters::kAntialiasPixels * device_pixel_size;
  Vector2 hairline_stroke_padding =
      params_.IsHairlineStroked() ? 0.5f * device_pixel_size : Vector2{};

  // Return a quad (FillRectGeometry) that covers the base shape expanded by
  // padding for AA and hairline stroke.
  //
  // For future performance enhancements (if the fill rate is a limiting factor)
  // this can be optimized to use a tighter geometry for specific shapes. E.g.
  // Using a tighter polygon, or cutting out the interior for stroked shapes.
  FillRectGeometry frg(
      base_bounds_.Expand(aa_padding + hairline_stroke_padding));
  return frg.GetPositionBuffer(renderer, entity, pass);
}

std::optional<Rect> UberSDFGeometry::GetCoverage(
    const Matrix& transform) const {
  // The coverage rect of the SDF is the bounds of the base shape, expanded by
  // padding for AA and hairline stroke.
  Rect transformed_bounds = base_bounds_.TransformAndClipBounds(transform);
  Scalar hairline_stroke_padding = params_.IsHairlineStroked() ? 0.5f : 0.0f;
  return transformed_bounds.Expand(UberSDFParameters::kAntialiasPixels +
                                   hairline_stroke_padding);
}

bool UberSDFGeometry::CoversArea(const Matrix& transform,
                                 const Rect& rect) const {
  if (params_.type == UberSDFParameters::Type::kRect && !params_.stroke &&
      transform.IsTranslationScaleOnly()) {
    // The SDF is a filled axis-aligned rectangle. It covers the input rect if
    // the SDF's rect covers the input rect, subtracting the AA padding from the
    // SDF rect.
    Rect transformed_bounds = base_bounds_.TransformAndClipBounds(transform);
    return transformed_bounds.Expand(-UberSDFParameters::kAntialiasPixels)
        .Contains(rect);
  }

  // Conservatively return false. We can optimize to handle more cases in the
  // future if needed for performance reasons.
  return false;
}

bool UberSDFGeometry::IsAxisAlignedRect() const {
  return (params_.type == UberSDFParameters::Type::kRect && !params_.stroke);
}

}  // namespace impeller

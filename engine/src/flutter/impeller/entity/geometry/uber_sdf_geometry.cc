// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

UberSDFGeometry::UberSDFGeometry(const UberSDFParameters& params)
    : params_(params) {
  base_bounds_ = Rect::MakeEllipseBounds(params_.center, params_.size);
  if (params_.stroke) {
    base_bounds_ = base_bounds_.Expand(params_.stroke->width * 0.5);
  }
}

UberSDFGeometry::~UberSDFGeometry() = default;

GeometryResult UberSDFGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  // Calculate the AA padding's local space value by dividing the AA's device
  // space value by the maximum axis scaling of the entity transform.
  Scalar max_basis = entity.GetTransform().GetMaxBasisLengthXY();
  Scalar aa_padding =
      max_basis == 0 ? 0 : UberSDFParameters::kAntialiasPixels / max_basis;

  // Return a quad (FillRectGeometry) that covers the base shape expanded by the
  // AA padding.
  //
  // For future performance enhancements (if the fill rate is a limiting factor)
  // this can be optimized to use a tighter geometry for specific shapes. E.g.
  // Using a tighter polygon, or cutting out the interior for stroked shapes.
  FillRectGeometry frg(base_bounds_.Expand(aa_padding));
  return frg.GetPositionBuffer(renderer, entity, pass);
}

std::optional<Rect> UberSDFGeometry::GetCoverage(
    const Matrix& transform) const {
  // The coverage rect of the SDF is the bounds of the base shape, expanded by
  // the AA padding.
  Rect transformed_bounds = base_bounds_.TransformAndClipBounds(transform);
  return transformed_bounds.Expand(UberSDFParameters::kAntialiasPixels);
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

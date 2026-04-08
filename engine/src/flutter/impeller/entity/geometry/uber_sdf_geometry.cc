// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

UberSDFGeometry::UberSDFGeometry(const UberSDFParameters& params)
    : params_(params) {}

UberSDFGeometry::~UberSDFGeometry() = default;

Rect UberSDFGeometry::GetBaseBounds() const {
  Rect bounds = Rect::MakeOriginSize(params_.center - params_.size,
                                     Size(params_.size.x, params_.size.y) * 2);
  if (params_.stroke) {
    bounds = bounds.Expand(params_.stroke->width * 0.5);
  }
  return bounds;
}

GeometryResult UberSDFGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  // Calculate the AA padding's local space value by dividing the AA's device
  // space value by the maximum axis scaling of the entity transform.
  Scalar max_basis = entity.GetTransform().GetMaxBasisLengthXY();
  Scalar aa_padding =
      max_basis == 0 ? 0 : UberSDFParameters::kAntialiasPadding / max_basis;

  // Return a quad (FillRectGeometry) that covers the base shape expanded by the
  // AA padding.
  FillRectGeometry frg(GetBaseBounds().Expand(aa_padding));
  return frg.GetPositionBuffer(renderer, entity, pass);
}

std::optional<Rect> UberSDFGeometry::GetCoverage(
    const Matrix& transform) const {
  // The coverage rect of the SDF is the bounds of the base shape, expanded by
  // the AA fringe.
  Rect transformed_bounds = GetBaseBounds().TransformAndClipBounds(transform);
  return transformed_bounds.Expand(UberSDFParameters::kAntialiasPadding);
}

bool UberSDFGeometry::CoversArea(const Matrix& transform,
                                 const Rect& rect) const {
  // Conservatively return false for most cases. This can be optimized to cover
  // more cases in the future if needed for performance reasons.
  if (params_.type != UberSDFParameters::Type::kRect || params_.stroke) {
    return false;
  }
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }

  // The SDF is a filled rectangle. It covers the input rect if the SDF's rect
  // covers the input rect, subtracting the AA fringe from the SDF rect.
  Rect transformed_bounds = GetBaseBounds().TransformAndClipBounds(transform);
  return transformed_bounds.Expand(-UberSDFParameters::kAntialiasPadding)
      .Contains(rect);
}

bool UberSDFGeometry::IsAxisAlignedRect() const {
  return (params_.type == UberSDFParameters::Type::kRect && !params_.stroke);
}

}  // namespace impeller

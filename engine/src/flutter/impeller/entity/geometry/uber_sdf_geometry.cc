// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

UberSDFGeometry::UberSDFGeometry(const UberSDFParameters& params)
    : params_(params) {}

UberSDFGeometry::~UberSDFGeometry() = default;

Rect UberSDFGeometry::GetExpandedBaseBounds() const {
  Rect bounds = Rect::MakeOriginSize(params_.center,
                                     Size(params_.size.x, params_.size.y));
  if (params_.stroke) {
    bounds = bounds.Expand(params_.stroke->width);
  }
  return bounds;
}

Rect UberSDFGeometry::GetExpandedDeviceBounds(const Matrix& transform,
                                              bool inset) const {
  Rect bounds = GetExpandedBaseBounds().TransformAndClipBounds(transform);
  return bounds.Expand(params_.kAntialiasPadding * (inset ? -1.0f : 1.0f));
}

Rect UberSDFGeometry::GetExpandedLocalBounds(const Matrix& transform) const {
  return GetExpandedBaseBounds().Expand(params_.kAntialiasPadding /
                                        transform.GetMaxBasisLengthXY());
}

GeometryResult UberSDFGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  FillRectGeometry frg(GetExpandedLocalBounds(entity.GetTransform()));
  return frg.GetPositionBuffer(renderer, entity, pass);
}

std::optional<Rect> UberSDFGeometry::GetCoverage(
    const Matrix& transform) const {
  return GetExpandedDeviceBounds(transform, false);
}

bool UberSDFGeometry::CoversArea(const Matrix& transform,
                                 const Rect& rect) const {
  if (params_.type != UberSDFParameters::Type::kRect || params_.stroke) {
    return false;
  }
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }
  return GetExpandedDeviceBounds(transform, true).Contains(rect);
}

bool UberSDFGeometry::IsAxisAlignedRect() const {
  return (params_.type == UberSDFParameters::Type::kRect && !params_.stroke);
}

}  // namespace impeller

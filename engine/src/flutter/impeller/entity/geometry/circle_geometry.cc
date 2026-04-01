// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "flutter/impeller/entity/geometry/circle_geometry.h"

#include "flutter/impeller/entity/geometry/line_geometry.h"
#include "impeller/core/formats.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

CircleGeometry::CircleGeometry(const Point& center, Scalar radius)
    : center_(center),
      radius_(radius),
      stroke_width_(-1.0f),
      padding_pixels_(0.0f) {
  FML_DCHECK(radius >= 0);
}

CircleGeometry::~CircleGeometry() = default;

CircleGeometry::CircleGeometry(const Point& center,
                               Scalar radius,
                               Scalar stroke_width)
    : center_(center),
      radius_(radius),
      stroke_width_(std::max(stroke_width, 0.0f)),
      padding_pixels_(0.0) {
  FML_DCHECK(radius >= 0);
  FML_DCHECK(stroke_width >= 0);
}

// |Geometry|
Scalar CircleGeometry::ComputeAlphaCoverage(const Matrix& transform) const {
  if (stroke_width_ < 0) {
    return 1;
  }
  return Geometry::ComputeStrokeAlphaCoverage(transform, stroke_width_);
}

Point CircleGeometry::GetCenter() const {
  return center_;
}

Scalar CircleGeometry::GetRadius() const {
  return radius_;
}

Scalar CircleGeometry::GetStrokeWidth() const {
  return stroke_width_;
}

void CircleGeometry::SetAntialiasPadding(Scalar extra_padding) {
  padding_pixels_ = extra_padding;
}

Scalar CircleGeometry::GetAntialiasPadding() const {
  return padding_pixels_;
}

GeometryResult CircleGeometry::GetPositionBuffer(const ContentContext& renderer,
                                                 const Entity& entity,
                                                 RenderPass& pass) const {
  auto& transform = entity.GetTransform();

  Scalar max_basis = transform.GetMaxBasisLengthXY();
  Scalar expansion = max_basis == 0 ? 0.0 : padding_pixels_ / max_basis;

  if (stroke_width_ < 0) {
    auto generator = renderer.GetTessellator().FilledCircle(
        transform, center_, radius_ + expansion);
    return ComputePositionGeometry(renderer, generator, entity, pass);
  }

  Scalar half_width =
      LineGeometry::ComputePixelHalfWidth(transform, stroke_width_);

  auto generator = renderer.GetTessellator().StrokedCircle(
      transform, center_, radius_, half_width + expansion);

  return ComputePositionGeometry(renderer, generator, entity, pass);
}

std::optional<Rect> CircleGeometry::GetCoverage(const Matrix& transform) const {
  Scalar max_basis = transform.GetMaxBasisLengthXY();
  Scalar expansion = max_basis == 0 ? 0.0 : padding_pixels_ / max_basis;

  Scalar half_width = stroke_width_ < 0 ? 0.0 : stroke_width_ * 0.5f;
  Scalar outer_radius = radius_ + half_width + expansion;
  return Rect::MakeLTRB(-outer_radius, -outer_radius,  //
                        +outer_radius, +outer_radius)
      .Shift(center_)
      .TransformAndClipBounds(transform);
}

bool CircleGeometry::CoversArea(const Matrix& transform,
                                const Rect& rect) const {
  return false;
}

bool CircleGeometry::IsAxisAlignedRect() const {
  return false;
}

}  // namespace impeller

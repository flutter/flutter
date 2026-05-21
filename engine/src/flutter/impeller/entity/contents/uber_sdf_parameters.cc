// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_parameters.h"

namespace impeller {

UberSDFParameters UberSDFParameters::MakeRect(
    Color color,
    const Rect& rect,
    std::optional<StrokeParameters> stroke) {
  // Size is the x and y extents from the center of the rect.
  Point size = Point(rect.GetSize() * 0.5f);

  // Stroke may be changed from miter to bevel joins depending on the miter
  // limit.
  std::optional<StrokeParameters> adjusted_stroke =
      stroke && stroke->join == Join::kMiter && stroke->miter_limit < kSqrt2
          ? std::make_optional(StrokeParameters(
                {.width = stroke->width, .join = Join::kBevel}))
          : stroke;

  return UberSDFParameters{.type = Type::kRect,
                           .color = color,
                           .center = rect.GetCenter(),
                           .size = size,
                           .stroke = adjusted_stroke};
}

UberSDFParameters UberSDFParameters::MakeCircle(
    Color color,
    const Point& center,
    Scalar radius,
    std::optional<StrokeParameters> stroke) {
  // Both size parameters are the same, but this allows us to treat this
  // case as if it were an oval to share code down the line. We can also
  // share bounds calculations without having to test for circle vs rect.
  Point size = Point(radius, radius);

  return UberSDFParameters{.type = Type::kCircle,
                           .color = color,
                           .center = center,
                           .size = size,
                           .stroke = stroke};
}

UberSDFParameters UberSDFParameters::MakeOval(
    Color color,
    const Rect& bounds,
    std::optional<StrokeParameters> stroke) {
  Point size = Point(bounds.GetSize() * 0.5f);
  return UberSDFParameters{.type = Type::kOval,
                           .color = color,
                           .center = bounds.GetCenter(),
                           .size = size,
                           .stroke = stroke};
}

UberSDFParameters UberSDFParameters::MakeRoundedRect(
    Color color,
    const Rect& rect,
    const RoundingRadii& radii,
    std::optional<StrokeParameters> stroke) {
  Point size = Point(rect.GetSize() * 0.5f);
  return UberSDFParameters{.type = Type::kRoundedRect,
                           .color = color,
                           .center = rect.GetCenter(),
                           .size = size,
                           .stroke = stroke,
                           .radii = radii};
}

UberSDFParameters UberSDFParameters::MakeRoundedSuperellipse(
    Color color,
    Rect rect,
    Point superellipse_degree,
    Point superellipse_a,
    RoundingRadii radii,
    Point corner_angle_span,
    Point corner_circle_center_top,
    Point corner_circle_center_right,
    Scalar superellipse_c,
    Point superellipse_scale,
    std::optional<StrokeParameters> stroke) {
  Point size = Point(rect.GetSize() * 0.5f);
  return UberSDFParameters{
      .type = Type::kRoundedSuperellipse,
      .color = color,
      .center = rect.GetCenter(),
      .size = size,
      .stroke = stroke,
      .radii = radii,
      .superellipse_degree = superellipse_degree,
      .superellipse_a = superellipse_a,
      .corner_angle_span = corner_angle_span,
      .corner_circle_center_top = corner_circle_center_top,
      .corner_circle_center_right = corner_circle_center_right,
      .superellipse_c = superellipse_c,
      .superellipse_scale = superellipse_scale};
}

}  // namespace impeller

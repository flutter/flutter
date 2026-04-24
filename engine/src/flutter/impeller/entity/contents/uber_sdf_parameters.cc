// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_parameters.h"

#include "impeller/geometry/constants.h"

namespace impeller {

UberSDFParameters UberSDFParameters::MakeRect(
    Color color,
    const Rect& rect,
    std::optional<StrokeParameters> stroke) {
  Point size = Point(rect.GetSize() * 0.5f);
  return UberSDFParameters{.type = Type::kRect,
                           .color = color,
                           .center = rect.GetCenter(),
                           .size = size,
                           .stroke = stroke};
}

UberSDFParameters UberSDFParameters::MakeCircle(
    Color color,
    const Point& center,
    Scalar radius,
    std::optional<StrokeParameters> stroke) {
  return UberSDFParameters{.type = Type::kCircle,
                           .color = color,
                           .center = center,
                           .size = Point(radius, radius),
                           .stroke = stroke};
}

UberSDFParameters UberSDFParameters::MakeOval(
    Color color,
    const Rect& bounds,
    std::optional<StrokeParameters> stroke) {
  // Size here refers to the extent of the oval along each axis from the center
  Point size = Point(bounds.GetSize() * 0.5);

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
    const Rect& rect,
    Scalar degree_top,
    const RoundingRadii& radii_top,
    Scalar corner_angle_span_top,
    Point corner_circle_center_top,
    Scalar degree_right,
    const RoundingRadii& radii_right,
    Scalar corner_angle_span_right,
    Point corner_circle_center_right,
    Scalar superellipse_c,
    Point superellipse_scale,
    std::optional<StrokeParameters> stroke) {
  Point size = Point(rect.GetSize() * 0.5f);
  return UberSDFParameters{
      .type = Type::kRoundSuperellipse,
      .color = color,
      .center = rect.GetCenter(),
      .size = size,
      .stroke = stroke,
      .radii = radii_top,
      .radii_right = radii_right,
      .superellipse_degree_top = degree_top,
      .corner_angle_span_top = corner_angle_span_top,
      .corner_circle_center_top = corner_circle_center_top,
      .superellipse_degree_right = degree_right,
      .corner_angle_span_right = corner_angle_span_right,
      .corner_circle_center_right = corner_circle_center_right,
      .superellipse_c = superellipse_c,
      .superellipse_scale = superellipse_scale};
}

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_parameters.h"

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

UberSDFParameters UberSDFParameters::MakeRoundSuperellipse(
    Color color,
    const Rect& rect,
    Scalar n,
    Scalar corner_radius,
    Scalar corner_angle_start,
    Scalar corner_angle_span,
    Point corner_circle_center,
    std::optional<StrokeParameters> stroke) {
  Point size = Point(rect.GetSize() * 0.5f);
  return UberSDFParameters{.type = Type::kRoundSuperellipse,
                           .color = color,
                           .center = rect.GetCenter(),
                           .size = size,
                           .stroke = stroke,
                           .superellipse_n = n,
                           .corner_radius = corner_radius,
                           .corner_angle_start = corner_angle_start,
                           .corner_angle_span = corner_angle_span,
                           .corner_circle_center = corner_circle_center};
}

}  // namespace impeller

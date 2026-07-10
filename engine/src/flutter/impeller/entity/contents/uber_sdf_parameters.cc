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
  return UberSDFParameters{
      .type = Type::kRoundedRect,
      .color = color,
      .center = rect.GetCenter(),
      .size = size,
      .stroke = stroke,
      .radii = Vector4(radii.bottom_right.width, radii.top_right.width,
                       radii.bottom_left.width, radii.top_left.width)};
}

UberSDFParameters UberSDFParameters::MakeRoundedSuperellipse(
    Color color,
    const Rect& bounds,
    const RoundSuperellipseParam& round_superellipse_params,
    std::optional<StrokeParameters> stroke) {
  FML_DCHECK(round_superellipse_params.all_corners_same);
  Point center = bounds.GetCenter();

  RoundSuperellipseParam::Quadrant top_right =
      round_superellipse_params.top_right;

  Point size = Point(bounds.GetSize() * 0.5f);

  return UberSDFParameters{
      .type = Type::kRoundedSuperellipseSymmetric,
      .color = color,
      .center = center,
      .size = size,
      .stroke = stroke,
      .superellipse_degree = Point(top_right.top.se_n, top_right.right.se_n),
      .superellipse_semi_axis = Point(top_right.top.se_a, top_right.right.se_a),
      .angle_span = Point(top_right.top.circle_max_angle.radians,
                          top_right.right.circle_max_angle.radians),
      .octant_offset_c = top_right.top.se_a - top_right.right.se_a,
      .circle_center_top = top_right.top.circle_center,
      .circle_center_right = top_right.right.circle_center,
      .superellipse_scale = top_right.signed_scale.Abs(),
      .radii = Vector4(top_right.top.circle_radius,
                       top_right.right.circle_radius, 0.0f, 0.0f)};
}

}  // namespace impeller

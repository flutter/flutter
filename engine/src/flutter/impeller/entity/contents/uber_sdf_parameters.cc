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
      .radii_width = Vector4(radii.bottom_right.width, radii.top_right.width,
                             radii.bottom_left.width, radii.top_left.width)};
}

UberSDFParameters UberSDFParameters::MakeRoundedSuperellipse(
    Color color,
    const Rect& bounds,
    const RoundSuperellipseParam& round_superellipse_params,
    std::optional<StrokeParameters> stroke) {
  Point center = bounds.GetCenter();

  RoundSuperellipseParam::Quadrant top_right =
      round_superellipse_params.top_right;
  RoundSuperellipseParam::Quadrant bottom_right =
      round_superellipse_params.all_corners_same
          ? top_right
          : round_superellipse_params.bottom_right;
  RoundSuperellipseParam::Quadrant bottom_left =
      round_superellipse_params.all_corners_same
          ? top_right
          : round_superellipse_params.bottom_left;
  RoundSuperellipseParam::Quadrant top_left =
      round_superellipse_params.all_corners_same
          ? top_right
          : round_superellipse_params.top_left;

  Point top_right_center_relative = top_right.offset - center;
  Point bottom_right_center_relative = bottom_right.offset - center;
  Point bottom_left_center_relative = bottom_left.offset - center;
  Point top_left_center_relative = top_left.offset - center;

  Point size = Point(bounds.GetSize() * 0.5f);
  Type type = round_superellipse_params.all_corners_same
                  ? Type::kRoundedSuperellipseSymmetric
                  : Type::kRoundedSuperellipse;

  return UberSDFParameters{
      .type = type,
      .color = color,
      .center = center,
      .size = size,
      .stroke = stroke,
      .superellipse_degrees_top =
          Vector4(bottom_right.top.se_n, top_right.top.se_n,
                  bottom_left.top.se_n, top_left.top.se_n),
      .superellipse_degrees_right =
          Vector4(bottom_right.right.se_n, top_right.right.se_n,
                  bottom_left.right.se_n, top_left.right.se_n),
      .superellipse_semi_axes_top =
          Vector4(bottom_right.top.se_a, top_right.top.se_a,
                  bottom_left.top.se_a, top_left.top.se_a),
      .superellipse_semi_axes_right =
          Vector4(bottom_right.right.se_a, top_right.right.se_a,
                  bottom_left.right.se_a, top_left.right.se_a),
      .angle_spans_top = Vector4(bottom_right.top.circle_max_angle.radians,
                                 top_right.top.circle_max_angle.radians,
                                 bottom_left.top.circle_max_angle.radians,
                                 top_left.top.circle_max_angle.radians),
      .angle_spans_right = Vector4(bottom_right.right.circle_max_angle.radians,
                                   top_right.right.circle_max_angle.radians,
                                   bottom_left.right.circle_max_angle.radians,
                                   top_left.right.circle_max_angle.radians),
      .octant_offsets_c =
          Vector4(bottom_right.top.se_a - bottom_right.right.se_a,
                  top_right.top.se_a - top_right.right.se_a,
                  bottom_left.top.se_a - bottom_left.right.se_a,
                  top_left.top.se_a - top_left.right.se_a),
      .radii_width =
          Vector4(bottom_right.top.circle_radius, top_right.top.circle_radius,
                  bottom_left.top.circle_radius, top_left.top.circle_radius),
      .radii_height = Vector4(
          bottom_right.right.circle_radius, top_right.right.circle_radius,
          bottom_left.right.circle_radius, top_left.right.circle_radius),
      .circle_centers_top_x = Vector4(
          bottom_right.top.circle_center.x, top_right.top.circle_center.x,
          bottom_left.top.circle_center.x, top_left.top.circle_center.x),
      .circle_centers_top_y = Vector4(
          bottom_right.top.circle_center.y, top_right.top.circle_center.y,
          bottom_left.top.circle_center.y, top_left.top.circle_center.y),
      .circle_centers_right_x = Vector4(
          bottom_right.right.circle_center.x, top_right.right.circle_center.x,
          bottom_left.right.circle_center.x, top_left.right.circle_center.x),
      .circle_centers_right_y = Vector4(
          bottom_right.right.circle_center.y, top_right.right.circle_center.y,
          bottom_left.right.circle_center.y, top_left.right.circle_center.y),
      .superellipse_scales_x = Vector4(
          bottom_right.signed_scale.Abs().x, top_right.signed_scale.Abs().x,
          bottom_left.signed_scale.Abs().x, top_left.signed_scale.Abs().x),
      .superellipse_scales_y = Vector4(
          bottom_right.signed_scale.Abs().y, top_right.signed_scale.Abs().y,
          bottom_left.signed_scale.Abs().y, top_left.signed_scale.Abs().y),
      .quadrant_centers_x =
          Vector4(bottom_right_center_relative.x, top_right_center_relative.x,
                  bottom_left_center_relative.x, top_left_center_relative.x),
      .quadrant_centers_y =
          Vector4(bottom_right_center_relative.y, top_right_center_relative.y,
                  bottom_left_center_relative.y, top_left_center_relative.y),
      .quadrant_splits =
          Vector4(round_superellipse_params.top_split - center.x,
                  round_superellipse_params.bottom_split - center.x,
                  round_superellipse_params.left_split - center.y,
                  round_superellipse_params.right_split - center.y)};
}

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

#include <optional>

#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/round_rect.h"
#include "impeller/geometry/stroke_parameters.h"
#include "impeller/geometry/vector.h"

namespace impeller {

/// Parameters for rendering shapes using the UberSDF shader.
struct UberSDFParameters {
  /// The amount by which the UberSDF shader fades the edge of the drawn shapes,
  /// in pixels.
  static constexpr Scalar kAntialiasPixels = 1.0f;

  /// The type of primitive shape.
  enum class Type {
    kCircle,
    kRect,
    kOval,
    kRoundedRect,
    kRoundedSuperellipse,
  };

  /// Creates UberSDFParameters for a rectangle.
  static UberSDFParameters MakeRect(Color color,
                                    const Rect& rect,
                                    std::optional<StrokeParameters> stroke);

  /// Creates UberSDFParameters for a circle.
  static UberSDFParameters MakeCircle(Color color,
                                      const Point& center,
                                      Scalar radius,
                                      std::optional<StrokeParameters> stroke);

  /// Creates UberSDFParameters for an Oval.
  static UberSDFParameters MakeOval(Color color,
                                    const Rect& bounds,
                                    std::optional<StrokeParameters> stroke);

  /// Creates UberSDFParameters for a rounded rectangle.
  static UberSDFParameters MakeRoundedRect(
      Color color,
      const Rect& rect,
      const RoundingRadii& radii,
      std::optional<StrokeParameters> stroke);

  /// Creates UberSDFParameters for a symmetric round superellipse.
  static UberSDFParameters MakeRoundedSuperellipse(
      Color color,
      const Rect& bounds,
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
      std::optional<StrokeParameters> stroke);

  /// The type of shape to render.
  Type type;

  /// The color used for filling or stroking the shape.
  Color color;

  /// The center point of the shape in local coordinates.
  Point center;

  /// For a rectangle, this is half the width and height.
  /// For a circle, this is the radius in both dimensions.
  /// For an oval, this is half the width and height of the bounds.
  Point size;

  /// The stroke parameters. If std::nullopt, the shape is filled.
  std::optional<StrokeParameters> stroke;

  /// The corner radii for the top octants of a RoundSuperellipse.
  RoundingRadii radii;

  /// The corner radii for the right octants of a RoundSuperellipse.
  RoundingRadii radii_right;

  /// The degree of the top octant of a RoundSuperellipse.
  Scalar superellipse_degree_top;

  /// The span of the top circular arc in a RoundSuperellipse.
  Scalar corner_angle_span_top;

  /// The center of the top circular arc in a RoundSuperellipse.
  Point corner_circle_center_top;

  /// The degree of the right octant of a RoundSuperellipse.
  Scalar superellipse_degree_right;

  /// The span of the right circular arc in a RoundSuperellipse.
  Scalar corner_angle_span_right;

  /// The center of the right circular arc in a RoundSuperellipse.
  Point corner_circle_center_right;

  /// The offset of the octants in a RoundSuperellipse.
  Scalar superellipse_c;

  /// The scale of the superellipse.
  Point superellipse_scale;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

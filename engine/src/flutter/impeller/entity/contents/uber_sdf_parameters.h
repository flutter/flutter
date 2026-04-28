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
      Rect bounds,
      Point superellipse_degree,
      Point superellipse_a,
      RoundingRadii radii,
      Point corner_angle_span,
      Point corner_circle_center_top,
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

  /// The corner radii for a rounded shapes.
  ///
  /// For RoundSuperellipse, the 'width' component holds the top-octant radius
  /// and the 'height' component holds the right-octant radius.
  RoundingRadii radii;

  /// The degrees of the top (.x) and right (.y) octants of a RoundSuperellipse.
  Point superellipse_degree;

  /// The semi-axes of the top (.x) and right (.y) superellipse segments.
  Point superellipse_a;

  /// The spans of the top (.x) and right (.y) circular arcs.
  Point corner_angle_span;

  /// The center of the top circular arc in a RoundSuperellipse.
  Point corner_circle_center_top;

  /// The center of the right circular arc in a RoundSuperellipse.
  Point corner_circle_center_right;

  /// The offset of the octants in a RoundSuperellipse.
  Scalar superellipse_c;

  /// The scale of the superellipse.
  Point superellipse_scale;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

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
#include "impeller/geometry/round_superellipse_param.h"
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
    kRoundedSuperellipseSymmetric,
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

  /// Creates UberSDFParameters for an asymmetric round superellipse.
  static UberSDFParameters MakeRoundedSuperellipse(
      Color color,
      const Rect& bounds,
      const RoundSuperellipseParam& round_superellipse_params,
      std::optional<StrokeParameters> stroke);

  /// Creates UberSDFParameters for a horizontal line centered at the origin.
  static UberSDFParameters MakeLine(Color color,
                                    Scalar length,
                                    const StrokeParameters& stroke);

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

  /// The degree (n) of the superellipse curve for the top and right octants.
  Point superellipse_degree;

  /// The semi-axis length of the superellipse curve for the top and right
  /// octants.
  Point superellipse_semi_axis;

  /// The angular span of the circular cap for the top and right octants.
  Point angle_span;

  /// The geometric offset 'c' used to connect the two octants of each quadrant.
  float octant_offset_c;

  /// The circular cap center for the top octant of each
  /// quadrant.
  Point circle_center_top;

  /// The circular cap center for the right octant of each
  /// quadrant.
  Point circle_center_right;

  /// The scaling factors used to transform normalized superellipses to their
  /// true size.
  Point superellipse_scale;

  /// Rounding radii for standard rounded rects and corner radii for circular
  /// caps of superellipses for top and right octants.
  Vector4 radii;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

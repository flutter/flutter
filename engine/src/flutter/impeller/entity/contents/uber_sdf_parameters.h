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

  /// Creates UberSDFParameters for an asymmetric round superellipse.
  static UberSDFParameters MakeRoundedSuperellipse(
      Color color,
      const Rect& bounds,
      const RoundSuperellipseParam& round_superellipse_params,
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

  /// The degree (n) of the superellipse curve for the top octant of each
  /// quadrant.
  Vector4 superellipse_degrees_top;

  /// The degree (n) of the superellipse curve for the right octant of each
  /// quadrant.
  Vector4 superellipse_degrees_right;

  /// The semi-axis length of the superellipse curve for the top octant of each
  /// quadrant.
  Vector4 superellipse_semi_axes_top;

  /// The semi-axis length of the superellipse curve for the right octant of
  /// each quadrant.
  Vector4 superellipse_semi_axes_right;

  /// The angular span of the circular cap for the top octant of each quadrant.
  Vector4 angle_spans_top;

  /// The angular span of the circular cap for the right octant of each
  /// quadrant.
  Vector4 angle_spans_right;

  /// The geometric offset 'c' used to connect the two octants of each quadrant.
  Vector4 octant_offsets_c;

  /// The horizontal corner radii for rounded shapes and circular caps of
  /// superellipses.
  Vector4 radii_width;

  /// The vertical corner radii for rounded shapes and circular caps of
  /// superellipses.
  Vector4 radii_height;

  /// The X coordinates of the circular cap centers for the top octant of each
  /// quadrant.
  Vector4 circle_centers_top_x;

  /// The Y coordinates of the circular cap centers for the top octant of each
  /// quadrant.
  Vector4 circle_centers_top_y;

  /// The X coordinates of the circular cap centers for the right octant of each
  /// quadrant.
  Vector4 circle_centers_right_x;

  /// The Y coordinates of the circular cap centers for the right octant of each
  /// quadrant.
  Vector4 circle_centers_right_y;

  /// The X scaling factors used to transform normalized superellipses to their
  /// true size.
  Vector4 superellipse_scales_x;

  /// The Y scaling factors used to transform normalized superellipses to their
  /// true size.
  Vector4 superellipse_scales_y;

  /// The X coordinates of the geometric centers for each of the four corner
  /// quadrants.
  Vector4 quadrant_centers_x;

  /// The Y coordinates of the geometric centers for each of the four corner
  /// quadrants.
  Vector4 quadrant_centers_y;

  /// The local coordinate split points (top, bottom, left, right) dividing the
  /// quadrants.
  Vector4 quadrant_splits;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

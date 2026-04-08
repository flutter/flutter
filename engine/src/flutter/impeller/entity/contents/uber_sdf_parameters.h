// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

#include <optional>

#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/stroke_parameters.h"

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

  /// The type of shape to render.
  Type type;

  /// The color used for filling or stroking the shape.
  Color color;

  /// The center point of the shape in local coordinates.
  Point center;

  /// The half-extents of the shape. For a rectangle, this is half the width
  /// and height. For a circle, this is the radius in both dimensions.
  Point size;

  /// The stroke parameters. If std::nullopt, the shape is filled.
  std::optional<StrokeParameters> stroke;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

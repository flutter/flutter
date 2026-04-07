// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_parameters.h"

#include <memory>

#include "impeller/geometry/constants.h"

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
  // Size x value is the radius of the circle, y value is ignored.
  Point size = Point(radius, 0.0f);

  return UberSDFParameters{.type = Type::kCircle,
                           .color = color,
                           .center = center,
                           .size = size,
                           .stroke = stroke};
}

}  // namespace impeller

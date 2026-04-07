// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_parameters.h"

#include <memory>

#include "impeller/entity/geometry/rect_geometry.h"
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

  // Create FillRectGeometry that covers the rectangle including stroke width.
  auto stroke_padding = stroke ? stroke->width * 0.5f : 0.0f;
  std::unique_ptr<FillRectGeometry> geometry =
      std::make_unique<FillRectGeometry>(rect.Expand(stroke_padding));
  geometry->SetAntialiasPadding(kAntialiasPadding);

  return UberSDFParameters(Type::kRect, color, rect.GetCenter(), size,
                           adjusted_stroke, std::move(geometry));
}

UberSDFParameters UberSDFParameters::MakeCircle(
    Color color,
    const Point& center,
    Scalar radius,
    std::optional<StrokeParameters> stroke) {
  // Size x value is the radius of the circle, y value is ignored.
  Point size = Point(radius, 0.0f);

  // Create FillRectGeometry that covers the circle including stroke width.
  auto stroke_padding = stroke ? stroke->width * 0.5f : 0.0f;
  std::unique_ptr<FillRectGeometry> geometry =
      std::make_unique<FillRectGeometry>(
          Rect::MakeXYWH(center.x, center.y, 0.0f, 0.0f)
              .Expand(radius + stroke_padding));
  geometry->SetAntialiasPadding(kAntialiasPadding);

  return UberSDFParameters(Type::kCircle, color, center, size, stroke,
                           std::move(geometry));
}

UberSDFParameters::UberSDFParameters(Type type,
                                     Color color,
                                     Point center,
                                     Point size,
                                     std::optional<StrokeParameters> stroke,
                                     std::unique_ptr<Geometry> geometry)
    : type_(type),
      color_(color),
      center_(center),
      size_(size),
      stroke_(stroke),
      geometry_(std::move(geometry)) {}

}  // namespace impeller

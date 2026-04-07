// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/uber_sdf_geometry.h"

#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

std::unique_ptr<Geometry> UberSDFGeometry::Make(
    const UberSDFParameters& params) {
  auto stroke = params.GetStroke();
  auto stroke_padding = stroke ? stroke->width * 0.5f : 0.0f;

  switch (params.GetType()) {
    case UberSDFParameters::Type::kRect: {
      Point center = params.GetCenter();
      Point size = params.GetSize();
      Rect rect = Rect::MakeXYWH(center.x - size.x, center.y - size.y,
                                 size.x * 2, size.y * 2);
      auto geometry =
          std::make_unique<FillRectGeometry>(rect.Expand(stroke_padding));
      geometry->SetAntialiasPadding(UberSDFParameters::kAntialiasPadding);
      return geometry;
    }
    case UberSDFParameters::Type::kCircle: {
      Point center = params.GetCenter();
      Scalar radius = params.GetSize().x;
      std::unique_ptr<FillRectGeometry> geometry =
          std::make_unique<FillRectGeometry>(
              Rect::MakeXYWH(center.x, center.y, 0.0f, 0.0f)
                  .Expand(radius + stroke_padding));
      geometry->SetAntialiasPadding(UberSDFParameters::kAntialiasPadding);
      return geometry;
    }
  }
}

}  // namespace impeller

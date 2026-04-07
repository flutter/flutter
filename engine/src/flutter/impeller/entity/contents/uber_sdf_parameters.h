// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

#include <memory>
#include <optional>

#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

struct UberSDFParameters {
  static constexpr Scalar kAntialiasPadding = 1.0f;

  enum class Type {
    kCircle,
    kRect,
  };

  static UberSDFParameters MakeRect(Color color,
                                    const Rect& rect,
                                    std::optional<StrokeParameters> stroke);

  static UberSDFParameters MakeCircle(Color color,
                                      const Point& center,
                                      Scalar radius,
                                      std::optional<StrokeParameters> stroke);

  Type type;
  Color color;
  Point center;
  Point size;
  std::optional<StrokeParameters> stroke;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_PARAMETERS_H_

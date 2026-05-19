// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_TYPES_H_
#define FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_TYPES_H_

#include "flutter/impeller/geometry/matrix.h"
#include "flutter/impeller/geometry/rect.h"
#include "flutter/impeller/geometry/round_rect.h"
#include "flutter/impeller/geometry/round_superellipse.h"
#include "flutter/impeller/geometry/rstransform.h"
#include "flutter/impeller/geometry/scalar.h"

namespace flutter {

using DlScalar = impeller::Scalar;
using DlDegrees = impeller::Degrees;
using DlRadians = impeller::Radians;

using DlPoint = impeller::Point;
using DlVector2 = impeller::Vector2;
using DlVector3 = impeller::Vector3;
using DlIPoint = impeller::IPoint32;
using DlSize = impeller::Size;
using DlISize = impeller::ISize32;
using DlRect = impeller::Rect;
using DlIRect = impeller::IRect32;
using DlRoundRect = impeller::RoundRect;
using DlRoundSuperellipse = impeller::RoundSuperellipse;
using DlRoundingRadii = impeller::RoundingRadii;
using DlMatrix = impeller::Matrix;
using DlQuad = impeller::Quad;
using DlRSTransform = impeller::RSTransform;

static constexpr DlScalar kEhCloseEnough = impeller::kEhCloseEnough;
static constexpr DlScalar kPi = impeller::kPi;

constexpr inline bool DlScalarNearlyZero(DlScalar x,
                                         DlScalar tolerance = kEhCloseEnough) {
  return impeller::ScalarNearlyZero(x, tolerance);
}

constexpr inline bool DlScalarNearlyEqual(DlScalar x,
                                          DlScalar y,
                                          DlScalar tolerance = kEhCloseEnough) {
  return impeller::ScalarNearlyEqual(x, y, tolerance);
}

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_TYPES_H_

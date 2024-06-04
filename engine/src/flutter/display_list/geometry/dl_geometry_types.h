// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_TYPES_H_
#define FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_TYPES_H_

#include "flutter/impeller/geometry/matrix.h"
#include "flutter/impeller/geometry/rect.h"
#include "flutter/impeller/geometry/scalar.h"

#include "flutter/third_party/skia/include/core/SkM44.h"
#include "flutter/third_party/skia/include/core/SkMatrix.h"
#include "flutter/third_party/skia/include/core/SkRect.h"
#include "flutter/third_party/skia/include/core/SkSize.h"

namespace flutter {

using DlScalar = impeller::Scalar;
using DlDegrees = impeller::Degrees;
using DlRadians = impeller::Radians;

using DlPoint = impeller::Point;
using DlIPoint = impeller::IPoint32;
using DlSize = impeller::Size;
using DlISize = impeller::ISize32;
using DlRect = impeller::Rect;
using DlIRect = impeller::IRect32;
using DlMatrix = impeller::Matrix;

static_assert(sizeof(SkPoint) == sizeof(DlPoint));
static_assert(sizeof(SkIPoint) == sizeof(DlIPoint));
static_assert(sizeof(SkSize) == sizeof(DlSize));
static_assert(sizeof(SkISize) == sizeof(DlISize));
static_assert(sizeof(SkRect) == sizeof(DlRect));
static_assert(sizeof(SkIRect) == sizeof(DlIRect));

inline const DlPoint& ToDlPoint(const SkPoint& point) {
  return *reinterpret_cast<const DlPoint*>(&point);
}

inline const DlRect& ToDlRect(const SkRect& rect) {
  return *reinterpret_cast<const DlRect*>(&rect);
}

inline const DlISize& ToDlISize(const SkISize& size) {
  return *reinterpret_cast<const DlISize*>(&size);
}

inline constexpr DlMatrix ToDlMatrix(const SkMatrix& matrix) {
  // clang-format off
  return DlMatrix::MakeColumn(
      matrix[SkMatrix::kMScaleX], matrix[SkMatrix::kMSkewY],  0.0f, matrix[SkMatrix::kMPersp0],
      matrix[SkMatrix::kMSkewX],  matrix[SkMatrix::kMScaleY], 0.0f, matrix[SkMatrix::kMPersp1],
      0.0f,                       0.0f,                       1.0f, 0.0f,
      matrix[SkMatrix::kMTransX], matrix[SkMatrix::kMTransY], 0.0f, matrix[SkMatrix::kMPersp2]
  );
  // clang-format on
}

inline constexpr DlMatrix ToDlMatrix(const SkM44& matrix) {
  DlMatrix dl_matrix;
  matrix.getColMajor(dl_matrix.m);
  return dl_matrix;
}

inline const SkPoint& ToSkPoint(const DlPoint& point) {
  return *reinterpret_cast<const SkPoint*>(&point);
}

inline const SkRect& ToSkRect(const DlRect& rect) {
  return *reinterpret_cast<const SkRect*>(&rect);
}

inline const SkISize& ToSkISize(const DlISize& size) {
  return *reinterpret_cast<const SkISize*>(&size);
}

inline constexpr SkMatrix ToSkMatrix(const DlMatrix& matrix) {
  return SkMatrix::MakeAll(matrix.m[0], matrix.m[4], matrix.m[12],  //
                           matrix.m[1], matrix.m[5], matrix.m[13],  //
                           matrix.m[3], matrix.m[7], matrix.m[15]);
}

inline constexpr SkM44 ToSkM44(const DlMatrix& matrix) {
  return SkM44::ColMajor(matrix.m);
}

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_GEOMETRY_DL_GEOMETRY_TYPES_H_

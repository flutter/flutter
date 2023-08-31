// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "display_list/dl_color.h"
#include "impeller/core/formats.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkM44.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace impeller {
namespace skia_conversions {

Rect ToRect(const SkRect& rect);

std::optional<Rect> ToRect(const SkRect* rect);

std::vector<Rect> ToRects(const SkRect tex[], int count);

std::vector<Point> ToPoints(const SkPoint points[], int count);

Point ToPoint(const SkPoint& point);

Color ToColor(const flutter::DlColor& color);

std::vector<Matrix> ToRSXForms(const SkRSXform xform[], int count);

PathBuilder::RoundingRadii ToRoundingRadii(const SkRRect& rrect);

Path ToPath(const SkPath& path);

Path ToPath(const SkRRect& rrect);

Path PathDataFromTextBlob(const sk_sp<SkTextBlob>& blob);

std::optional<impeller::PixelFormat> ToPixelFormat(SkColorType type);

constexpr SkM44 ToSkM44(const Matrix& matrix) {
  // SkM44 construction is in row major order (even though it stores the data in
  // column major).
  // clang-format off
  return SkM44(
    matrix.vec[0].x, matrix.vec[1].x, matrix.vec[2].x, matrix.vec[3].x,
    matrix.vec[0].y, matrix.vec[1].y, matrix.vec[2].y, matrix.vec[3].y,
    matrix.vec[0].z, matrix.vec[1].z, matrix.vec[2].z, matrix.vec[3].z,
    matrix.vec[0].w, matrix.vec[1].w, matrix.vec[2].w, matrix.vec[3].w
  );
  // clang-format on
}

constexpr SkMatrix ToSkMatrix(const Matrix& matrix) {
  // SkMatrix is in row major order.
  // clang-format off
  return SkMatrix::MakeAll(
    matrix.vec[0].x, matrix.vec[1].x, matrix.vec[3].x,
    matrix.vec[0].y, matrix.vec[1].y, matrix.vec[3].y,
    matrix.vec[0].w, matrix.vec[1].w, matrix.vec[3].w
  );
  /// clang-format on
}

}  // namespace skia_conversions
}  // namespace impeller

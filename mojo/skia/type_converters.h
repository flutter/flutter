// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SKIA_TYPE_CONVERTERS_H_
#define MOJO_SKIA_TYPE_CONVERTERS_H_

#include "mojo/services/geometry/interfaces/geometry.mojom.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRect.h"

namespace mojo {

template <>
struct TypeConverter<SkPoint, mojo::Point> {
  static SkPoint Convert(const mojo::Point& input);
};
template <>
struct TypeConverter<mojo::Point, SkPoint> {
  static mojo::Point Convert(const SkPoint& input);
};

template <>
struct TypeConverter<SkRect, mojo::Rect> {
  static SkRect Convert(const mojo::Rect& input);
};
template <>
struct TypeConverter<mojo::Rect, SkRect> {
  static mojo::Rect Convert(const SkRect& input);
};

template <>
struct TypeConverter<SkRRect, mojo::RRect> {
  static SkRRect Convert(const mojo::RRect& input);
};
template <>
struct TypeConverter<mojo::RRect, SkRRect> {
  static mojo::RRect Convert(const SkRRect& input);
};

// Note: This transformation is lossy since Transform is 4x4 whereas
// SkMatrix is only 3x3.
template <>
struct TypeConverter<SkMatrix, mojo::TransformPtr> {
  static SkMatrix Convert(const mojo::TransformPtr& input);
};
template <>
struct TypeConverter<mojo::TransformPtr, SkMatrix> {
  static mojo::TransformPtr Convert(const SkMatrix& input);
};

}  // namespace mojo

#endif  // MOJO_SKIA_TYPE_CONVERTERS_H_

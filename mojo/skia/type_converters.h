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
#include "third_party/skia/include/core/SkMatrix44.h"

namespace mojo {

template <>
struct TypeConverter<SkIPoint, mojo::Point> {
  static SkIPoint Convert(const mojo::Point& input);
};
template <>
struct TypeConverter<mojo::Point, SkIPoint> {
  static mojo::Point Convert(const SkIPoint& input);
};

template <>
struct TypeConverter<SkPoint, mojo::PointF> {
  static SkPoint Convert(const mojo::PointF& input);
};
template <>
struct TypeConverter<mojo::PointF, SkPoint> {
  static mojo::PointF Convert(const SkPoint& input);
};

template <>
struct TypeConverter<SkIRect, mojo::Rect> {
  static SkIRect Convert(const mojo::Rect& input);
};
template <>
struct TypeConverter<mojo::Rect, SkIRect> {
  static mojo::Rect Convert(const SkIRect& input);
};

template <>
struct TypeConverter<SkRect, mojo::RectF> {
  static SkRect Convert(const mojo::RectF& input);
};
template <>
struct TypeConverter<mojo::RectF, SkRect> {
  static mojo::RectF Convert(const SkRect& input);
};

template <>
struct TypeConverter<SkRRect, mojo::RRectF> {
  static SkRRect Convert(const mojo::RRectF& input);
};
template <>
struct TypeConverter<mojo::RRectF, SkRRect> {
  static mojo::RRectF Convert(const SkRRect& input);
};

// Note: This transformation is lossy since Transform is 4x4 whereas
// SkMatrix is only 3x3 so we drop the 3rd row and column.
template <>
struct TypeConverter<SkMatrix, mojo::TransformPtr> {
  static SkMatrix Convert(const mojo::TransformPtr& input);
};
template <>
struct TypeConverter<mojo::TransformPtr, SkMatrix> {
  static mojo::TransformPtr Convert(const SkMatrix& input);
};

// Note: This transformation is lossless.
template <>
struct TypeConverter<SkMatrix44, mojo::TransformPtr> {
  static SkMatrix44 Convert(const mojo::TransformPtr& input);
};
template <>
struct TypeConverter<mojo::TransformPtr, SkMatrix44> {
  static mojo::TransformPtr Convert(const SkMatrix44& input);
};

}  // namespace mojo

#endif  // MOJO_SKIA_TYPE_CONVERTERS_H_

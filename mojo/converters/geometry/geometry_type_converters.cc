// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/geometry/geometry_type_converters.h"

namespace mojo {

// static
PointPtr TypeConverter<PointPtr, gfx::Point>::Convert(const gfx::Point& input) {
  PointPtr point(Point::New());
  point->x = input.x();
  point->y = input.y();
  return point.Pass();
}

// static
gfx::Point TypeConverter<gfx::Point, PointPtr>::Convert(const PointPtr& input) {
  if (input.is_null())
    return gfx::Point();
  return gfx::Point(input->x, input->y);
}

// static
PointFPtr TypeConverter<PointFPtr, gfx::PointF>::Convert(
    const gfx::PointF& input) {
  PointFPtr point(PointF::New());
  point->x = input.x();
  point->y = input.y();
  return point.Pass();
}

// static
gfx::PointF TypeConverter<gfx::PointF, PointFPtr>::Convert(
    const PointFPtr& input) {
  if (input.is_null())
    return gfx::PointF();
  return gfx::PointF(input->x, input->y);
}

// static
SizePtr TypeConverter<SizePtr, gfx::Size>::Convert(const gfx::Size& input) {
  SizePtr size(Size::New());
  size->width = input.width();
  size->height = input.height();
  return size.Pass();
}

// static
gfx::Size TypeConverter<gfx::Size, SizePtr>::Convert(const SizePtr& input) {
  if (input.is_null())
    return gfx::Size();
  return gfx::Size(input->width, input->height);
}

// static
RectPtr TypeConverter<RectPtr, gfx::Rect>::Convert(const gfx::Rect& input) {
  RectPtr rect(Rect::New());
  rect->x = input.x();
  rect->y = input.y();
  rect->width = input.width();
  rect->height = input.height();
  return rect.Pass();
}

// static
gfx::Rect TypeConverter<gfx::Rect, RectPtr>::Convert(const RectPtr& input) {
  if (input.is_null())
    return gfx::Rect();
  return gfx::Rect(input->x, input->y, input->width, input->height);
}

// static
RectFPtr TypeConverter<RectFPtr, gfx::RectF>::Convert(const gfx::RectF& input) {
  RectFPtr rect(RectF::New());
  rect->x = input.x();
  rect->y = input.y();
  rect->width = input.width();
  rect->height = input.height();
  return rect.Pass();
}

// static
gfx::RectF TypeConverter<gfx::RectF, RectFPtr>::Convert(const RectFPtr& input) {
  if (input.is_null())
    return gfx::RectF();
  return gfx::RectF(input->x, input->y, input->width, input->height);
}

// static
TransformPtr TypeConverter<TransformPtr, gfx::Transform>::Convert(
    const gfx::Transform& input) {
  std::vector<float> storage(16);
  input.matrix().asRowMajorf(&storage[0]);
  mojo::Array<float> matrix;
  matrix.Swap(&storage);
  TransformPtr transform(Transform::New());
  transform->matrix = matrix.Pass();
  return transform.Pass();
}

// static
gfx::Transform TypeConverter<gfx::Transform, TransformPtr>::Convert(
    const TransformPtr& input) {
  if (input.is_null())
    return gfx::Transform();
  gfx::Transform transform(gfx::Transform::kSkipInitialization);
  transform.matrix().setRowMajorf(&input->matrix.storage()[0]);
  return transform;
}

// static
Size TypeConverter<Size, gfx::Size>::Convert(const gfx::Size& input) {
  Size size;
  size.width = input.width();
  size.height = input.height();
  return size;
}

// static
gfx::Size TypeConverter<gfx::Size, Size>::Convert(const Size& input) {
  return gfx::Size(input.width, input.height);
}

// static
Rect TypeConverter<Rect, gfx::Rect>::Convert(const gfx::Rect& input) {
  Rect rect;
  rect.x = input.x();
  rect.y = input.y();
  rect.width = input.width();
  rect.height = input.height();
  return rect;
}

// static
gfx::Rect TypeConverter<gfx::Rect, Rect>::Convert(const Rect& input) {
  return gfx::Rect(input.x, input.y, input.width, input.height);
}

}  // namespace mojo

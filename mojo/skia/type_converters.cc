// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/skia/type_converters.h"

namespace mojo {

SkIPoint TypeConverter<SkIPoint, mojo::Point>::Convert(
    const mojo::Point& input) {
  return SkIPoint::Make(input.x, input.y);
}

mojo::Point TypeConverter<mojo::Point, SkIPoint>::Convert(
    const SkIPoint& input) {
  mojo::Point output;
  output.x = input.x();
  output.y = input.y();
  return output;
}

SkPoint TypeConverter<SkPoint, mojo::PointF>::Convert(
    const mojo::PointF& input) {
  return SkPoint::Make(input.x, input.y);
}

mojo::PointF TypeConverter<mojo::PointF, SkPoint>::Convert(
    const SkPoint& input) {
  mojo::PointF output;
  output.x = input.x();
  output.y = input.y();
  return output;
}

SkIRect TypeConverter<SkIRect, mojo::Rect>::Convert(const mojo::Rect& input) {
  return SkIRect::MakeXYWH(input.x, input.y, input.width, input.height);
}

mojo::Rect TypeConverter<mojo::Rect, SkIRect>::Convert(const SkIRect& input) {
  mojo::Rect output;
  output.x = input.x();
  output.y = input.y();
  output.width = input.width();
  output.height = input.height();
  return output;
}

SkRect TypeConverter<SkRect, mojo::RectF>::Convert(const mojo::RectF& input) {
  return SkRect::MakeXYWH(input.x, input.y, input.width, input.height);
}

mojo::RectF TypeConverter<mojo::RectF, SkRect>::Convert(const SkRect& input) {
  mojo::RectF output;
  output.x = input.x();
  output.y = input.y();
  output.width = input.width();
  output.height = input.height();
  return output;
}

SkRRect TypeConverter<SkRRect, mojo::RRectF>::Convert(
    const mojo::RRectF& input) {
  SkVector radii[4] = {
      {input.top_left_radius_x, input.top_left_radius_y},
      {input.top_right_radius_x, input.top_right_radius_y},
      {input.bottom_left_radius_x, input.bottom_left_radius_y},
      {input.bottom_right_radius_x, input.bottom_right_radius_y}};
  SkRRect output;
  output.setRectRadii(
      SkRect::MakeXYWH(input.x, input.y, input.width, input.height), radii);
  return output;
}

mojo::RRectF TypeConverter<mojo::RRectF, SkRRect>::Convert(
    const SkRRect& input) {
  mojo::RRectF output;
  output.x = input.rect().x();
  output.y = input.rect().y();
  output.width = input.rect().width();
  output.height = input.rect().height();
  output.top_left_radius_x = input.radii(SkRRect::kUpperLeft_Corner).x();
  output.top_left_radius_y = input.radii(SkRRect::kUpperLeft_Corner).y();
  output.top_right_radius_x = input.radii(SkRRect::kUpperRight_Corner).x();
  output.top_right_radius_y = input.radii(SkRRect::kUpperRight_Corner).y();
  output.bottom_left_radius_x = input.radii(SkRRect::kLowerLeft_Corner).x();
  output.bottom_left_radius_y = input.radii(SkRRect::kLowerLeft_Corner).y();
  output.bottom_right_radius_x = input.radii(SkRRect::kLowerRight_Corner).x();
  output.bottom_right_radius_y = input.radii(SkRRect::kLowerRight_Corner).y();
  return output;
}

SkMatrix TypeConverter<SkMatrix, mojo::TransformPtr>::Convert(
    const mojo::TransformPtr& input) {
  if (!input)
    return SkMatrix::I();

  // Drop 3D components during conversion from 4x4 to 3x3.
  SkMatrix output;
  output.setAll(input->matrix[0], input->matrix[1], input->matrix[3],
                input->matrix[4], input->matrix[5], input->matrix[7],
                input->matrix[12], input->matrix[13], input->matrix[15]);
  return output;
}

mojo::TransformPtr TypeConverter<mojo::TransformPtr, SkMatrix>::Convert(
    const SkMatrix& input) {
  // Expand 3x3 to 4x4.
  auto output = mojo::Transform::New();
  output->matrix.resize(16u);
  output->matrix[0] = input[0];
  output->matrix[1] = input[1];
  output->matrix[2] = 0.f;
  output->matrix[3] = input[2];
  output->matrix[4] = input[3];
  output->matrix[5] = input[4];
  output->matrix[6] = 0.f;
  output->matrix[7] = input[5];
  output->matrix[8] = 0.f;
  output->matrix[9] = 0.f;
  output->matrix[10] = 1.f;
  output->matrix[11] = 0.f;
  output->matrix[12] = input[6];
  output->matrix[13] = input[7];
  output->matrix[14] = 0.f;
  output->matrix[15] = input[8];
  return output.Pass();
}

SkMatrix44 TypeConverter<SkMatrix44, mojo::TransformPtr>::Convert(
    const mojo::TransformPtr& input) {
  if (!input)
    return SkMatrix44::I();

  SkMatrix44 output(SkMatrix44::kUninitialized_Constructor);
  output.setRowMajorf(input->matrix.data());
  return output;
}

mojo::TransformPtr TypeConverter<mojo::TransformPtr, SkMatrix44>::Convert(
    const SkMatrix44& input) {
  auto output = mojo::Transform::New();
  output->matrix.resize(16u);
  input.asRowMajorf(output->matrix.data());
  return output.Pass();
}

}  // namespace mojo

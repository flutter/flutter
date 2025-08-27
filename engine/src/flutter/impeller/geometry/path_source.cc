// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/path_source.h"

namespace impeller {

RectPathSource::~RectPathSource() = default;

bool RectPathSource::IsConvex() const {
  return true;
}

FillType RectPathSource::GetFillType() const {
  return FillType::kNonZero;
}

Rect RectPathSource::GetBounds() const {
  return rect_;
}

void RectPathSource::Dispatch(PathReceiver& receiver) const {
  receiver.MoveTo(rect_.GetLeftTop(), true);
  receiver.LineTo(rect_.GetRightTop());
  receiver.LineTo(rect_.GetRightBottom());
  receiver.LineTo(rect_.GetLeftBottom());
  receiver.LineTo(rect_.GetLeftTop());
  receiver.Close();
}

EllipsePathSource::EllipsePathSource(const Rect& bounds) : bounds_(bounds) {}

EllipsePathSource::~EllipsePathSource() = default;

FillType EllipsePathSource::GetFillType() const {
  return FillType::kNonZero;
}

Rect EllipsePathSource::GetBounds() const {
  return bounds_;
}

bool EllipsePathSource::IsConvex() const {
  return true;
}

void EllipsePathSource::Dispatch(PathReceiver& receiver) const {
  Scalar left = bounds_.GetLeft();
  Scalar right = bounds_.GetRight();
  Scalar top = bounds_.GetTop();
  Scalar bottom = bounds_.GetBottom();
  Point center = bounds_.GetCenter();

  receiver.MoveTo(Point(left, center.y), true);
  receiver.ConicTo(Point(left, top), Point(center.x, top), kSqrt2Over2);
  receiver.ConicTo(Point(right, top), Point(right, center.y), kSqrt2Over2);
  receiver.ConicTo(Point(right, bottom), Point(center.x, bottom), kSqrt2Over2);
  receiver.ConicTo(Point(left, bottom), Point(left, center.y), kSqrt2Over2);

  receiver.Close();
}

}  // namespace impeller

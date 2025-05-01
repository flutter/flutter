// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/path_source.h"

namespace impeller {

OvalPathSource::OvalPathSource(const Rect& bounds) : bounds_(bounds) {}

OvalPathSource::~OvalPathSource() = default;

FillType OvalPathSource::GetFillType() const {
  return FillType::kNonZero;
}

Rect OvalPathSource::GetBounds() const {
  return bounds_;
}

bool OvalPathSource::IsConvex() const {
  return true;
}

void OvalPathSource::Dispatch(PathReceiver& receiver) const {
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
  receiver.PathEnd();
}

}  // namespace impeller

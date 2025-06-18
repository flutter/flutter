// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/geometry/dashed_line_path_source.h"

namespace impeller {

DashedLinePathSource::DashedLinePathSource(Point p0,
                                           Point p1,
                                           Scalar on_length,
                                           Scalar off_length)
    : p0_(p0), p1_(p1), on_length_(on_length), off_length_(off_length) {}

DashedLinePathSource::~DashedLinePathSource() = default;

FillType DashedLinePathSource::GetFillType() const {
  return FillType::kNonZero;
}

Rect DashedLinePathSource::GetBounds() const {
  return Rect::MakeLTRB(p0_.x, p0_.y, p1_.x, p1_.y).GetPositive();
}

bool DashedLinePathSource::IsConvex() const {
  return false;
}

void DashedLinePathSource::Dispatch(PathReceiver& receiver) const {
  // Exceptional conditions:
  // - length is non-positive - result will draw only a "dot"
  // - off_length is non-positive - no gaps, result is a solid line
  // - on_length is negative - invalid dashing
  // Note that a 0 length "on" dash will draw "dot"s every "off" distance
  // apart so we still generate the dashing for that case.
  //
  // Note that Canvas will detect these conditions and use its own DrawLine
  // method directly for performance reasons for a single line, but in case
  // someone uses this PathSource with these exceptional cases, we degenerate
  // gracefully into a single line segment path description below.
  Scalar length = p0_.GetDistance(p1_);
  if (length > 0.0f && on_length_ >= 0.0f && off_length_ > 0.0f) {
    Point delta = (p1_ - p0_) / length;  // length > 0 already verified

    Scalar consumed = 0.0f;
    while (consumed < length) {
      receiver.MoveTo(p0_ + delta * consumed, false);

      Scalar dash_end = consumed + on_length_;
      if (dash_end < length) {
        receiver.LineTo(p0_ + delta * dash_end);
      } else {
        receiver.LineTo(p1_);
        // Should happen anyway due to the math, but let's make it explicit
        // in case of bit errors. We're done with this line.
        break;
      }

      consumed = dash_end + off_length_;
    }
  } else {
    receiver.MoveTo(p0_, false);
    receiver.LineTo(p1_);
  }
}

}  // namespace impeller

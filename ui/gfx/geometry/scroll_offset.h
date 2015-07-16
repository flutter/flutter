// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_SCROLL_OFFSET_H_
#define UI_GFX_GEOMETRY_SCROLL_OFFSET_H_

#include <iosfwd>
#include <string>

#include "ui/gfx/geometry/safe_integer_conversions.h"
#include "ui/gfx/geometry/vector2d.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

class GFX_EXPORT ScrollOffset {
 public:
  ScrollOffset() : x_(0), y_(0) {}
  ScrollOffset(double x, double y) : x_(x), y_(y) {}
  explicit ScrollOffset(const Vector2dF& v) : x_(v.x()), y_(v.y()) {}
  explicit ScrollOffset(const Vector2d& v) : x_(v.x()), y_(v.y()) {}

  double x() const { return x_; }
  void set_x(double x) { x_ = x; }

  double y() const { return y_; }
  void set_y(double y) { y_ = y; }

  // True if both components are 0.
  bool IsZero() const {
    return x_ == 0 && y_ == 0;
  }

  // Add the components of the |other| ScrollOffset to the current ScrollOffset.
  void Add(const ScrollOffset& other) {
    x_ += other.x_;
    y_ += other.y_;
  }

  // Subtract the components of the |other| ScrollOffset from the current
  // ScrollOffset.
  void Subtract(const ScrollOffset& other) {
    x_ -= other.x_;
    y_ -= other.y_;
  }

  Vector2dF DeltaFrom(const ScrollOffset& v) const {
    return Vector2dF(x_ - v.x(), y_ - v.y());
  }

  void operator+=(const ScrollOffset& other) { Add(other); }
  void operator-=(const ScrollOffset& other) { Subtract(other); }

  void SetToMin(const ScrollOffset& other) {
    x_ = x_ <= other.x_ ? x_ : other.x_;
    y_ = y_ <= other.y_ ? y_ : other.y_;
  }

  void SetToMax(const ScrollOffset& other) {
    x_ = x_ >= other.x_ ? x_ : other.x_;
    y_ = y_ >= other.y_ ? y_ : other.y_;
  }

  void Scale(double scale) { Scale(scale, scale); }
  void Scale(double x_scale, double y_scale) {
    x_ *= x_scale;
    y_ *= y_scale;
  }

  std::string ToString() const;

 private:
  double x_;
  double y_;
};

inline bool operator==(const ScrollOffset& lhs, const ScrollOffset& rhs) {
  return lhs.x() == rhs.x() && lhs.y() == rhs.y();
}

inline bool operator!=(const ScrollOffset& lhs, const ScrollOffset& rhs) {
  return lhs.x() != rhs.x() || lhs.y() != rhs.y();
}

inline ScrollOffset operator-(const ScrollOffset& v) {
  return ScrollOffset(-v.x(), -v.y());
}

inline ScrollOffset operator+(const ScrollOffset& lhs,
                              const ScrollOffset& rhs) {
  ScrollOffset result = lhs;
  result.Add(rhs);
  return result;
}

inline ScrollOffset operator-(const ScrollOffset& lhs,
                              const ScrollOffset& rhs) {
  ScrollOffset result = lhs;
  result.Add(-rhs);
  return result;
}

inline Vector2d ScrollOffsetToFlooredVector2d(const ScrollOffset& v) {
  return Vector2d(ToFlooredInt(v.x()), ToFlooredInt(v.y()));
}

inline Vector2dF ScrollOffsetToVector2dF(const ScrollOffset& v) {
  return Vector2dF(v.x(), v.y());
}

inline ScrollOffset ScrollOffsetWithDelta(const ScrollOffset& offset,
                                          const Vector2dF& delta) {
  return ScrollOffset(offset.x() + delta.x(),
                      offset.y() + delta.y());
}

// This is declared here for use in gtest-based unit tests but is defined in
// the gfx_test_support target. Depend on that to use this in your unit test.
// This should not be used in production code - call ToString() instead.
void PrintTo(const ScrollOffset& scroll_offset, ::std::ostream* os);

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_SCROLL_OFFSET_H_

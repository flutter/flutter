// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_QUAD_F_H_
#define UI_GFX_GEOMETRY_QUAD_F_H_

#include <algorithm>
#include <cmath>
#include <iosfwd>
#include <string>

#include "base/logging.h"
#include "ui/gfx/geometry/point_f.h"
#include "ui/gfx/geometry/rect_f.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

// A Quad is defined by four corners, allowing it to have edges that are not
// axis-aligned, unlike a Rect.
class GFX_EXPORT QuadF {
 public:
  QuadF() {}
  QuadF(const PointF& p1, const PointF& p2, const PointF& p3, const PointF& p4)
      : p1_(p1),
        p2_(p2),
        p3_(p3),
        p4_(p4) {}

  explicit QuadF(const RectF& rect)
      : p1_(rect.x(), rect.y()),
        p2_(rect.right(), rect.y()),
        p3_(rect.right(), rect.bottom()),
        p4_(rect.x(), rect.bottom()) {}

  void operator=(const RectF& rect);

  void set_p1(const PointF& p) { p1_ = p; }
  void set_p2(const PointF& p) { p2_ = p; }
  void set_p3(const PointF& p) { p3_ = p; }
  void set_p4(const PointF& p) { p4_ = p; }

  const PointF& p1() const { return p1_; }
  const PointF& p2() const { return p2_; }
  const PointF& p3() const { return p3_; }
  const PointF& p4() const { return p4_; }

  // Returns true if the quad is an axis-aligned rectangle.
  bool IsRectilinear() const;

  // Returns true if the points of the quad are in counter-clockwise order. This
  // assumes that the quad is convex, and that no three points are collinear.
  bool IsCounterClockwise() const;

  // Returns true if the |point| is contained within the quad, or lies on on
  // edge of the quad. This assumes that the quad is convex.
  bool Contains(const gfx::PointF& point) const;

  // Returns a rectangle that bounds the four points of the quad. The points of
  // the quad may lie on the right/bottom edge of the resulting rectangle,
  // rather than being strictly inside it.
  RectF BoundingBox() const {
    float rl = std::min(std::min(p1_.x(), p2_.x()), std::min(p3_.x(), p4_.x()));
    float rr = std::max(std::max(p1_.x(), p2_.x()), std::max(p3_.x(), p4_.x()));
    float rt = std::min(std::min(p1_.y(), p2_.y()), std::min(p3_.y(), p4_.y()));
    float rb = std::max(std::max(p1_.y(), p2_.y()), std::max(p3_.y(), p4_.y()));
    return RectF(rl, rt, rr - rl, rb - rt);
  }

  // Realigns the corners in the quad by rotating them n corners to the right.
  void Realign(size_t times) {
    DCHECK_LE(times, 4u);
    for (size_t i = 0; i < times; ++i) {
      PointF temp = p1_;
      p1_ = p2_;
      p2_ = p3_;
      p3_ = p4_;
      p4_ = temp;
    }
  }

  // Add a vector to the quad, offseting each point in the quad by the vector.
  void operator+=(const Vector2dF& rhs);
  // Subtract a vector from the quad, offseting each point in the quad by the
  // inverse of the vector.
  void operator-=(const Vector2dF& rhs);

  // Scale each point in the quad by the |scale| factor.
  void Scale(float scale) { Scale(scale, scale); }

  // Scale each point in the quad by the scale factors along each axis.
  void Scale(float x_scale, float y_scale);

  // Returns a string representation of quad.
  std::string ToString() const;

 private:
  PointF p1_;
  PointF p2_;
  PointF p3_;
  PointF p4_;
};

inline bool operator==(const QuadF& lhs, const QuadF& rhs) {
  return
      lhs.p1() == rhs.p1() && lhs.p2() == rhs.p2() &&
      lhs.p3() == rhs.p3() && lhs.p4() == rhs.p4();
}

inline bool operator!=(const QuadF& lhs, const QuadF& rhs) {
  return !(lhs == rhs);
}

// Add a vector to a quad, offseting each point in the quad by the vector.
GFX_EXPORT QuadF operator+(const QuadF& lhs, const Vector2dF& rhs);
// Subtract a vector from a quad, offseting each point in the quad by the
// inverse of the vector.
GFX_EXPORT QuadF operator-(const QuadF& lhs, const Vector2dF& rhs);

// This is declared here for use in gtest-based unit tests but is defined in
// the gfx_test_support target. Depend on that to use this in your unit test.
// This should not be used in production code - call ToString() instead.
void PrintTo(const QuadF& quad, ::std::ostream* os);

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_QUAD_F_H_

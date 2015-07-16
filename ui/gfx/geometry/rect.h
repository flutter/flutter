// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Defines a simple integer rectangle class.  The containment semantics
// are array-like; that is, the coordinate (x, y) is considered to be
// contained by the rectangle, but the coordinate (x + width, y) is not.
// The class will happily let you create malformed rectangles (that is,
// rectangles with negative width and/or height), but there will be assertions
// in the operations (such as Contains()) to complain in this case.

#ifndef UI_GFX_GEOMETRY_RECT_H_
#define UI_GFX_GEOMETRY_RECT_H_

#include <cmath>
#include <iosfwd>
#include <string>

#include "ui/gfx/geometry/point.h"
#include "ui/gfx/geometry/rect_f.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/geometry/vector2d.h"

namespace gfx {

class Insets;

class GFX_EXPORT Rect {
 public:
  Rect() {}
  Rect(int width, int height) : size_(width, height) {}
  Rect(int x, int y, int width, int height)
      : origin_(x, y), size_(width, height) {}
  explicit Rect(const Size& size) : size_(size) {}
  Rect(const Point& origin, const Size& size) : origin_(origin), size_(size) {}

  ~Rect() {}

  operator RectF() const {
    return RectF(origin().x(), origin().y(), size().width(), size().height());
  }

  int x() const { return origin_.x(); }
  void set_x(int x) { origin_.set_x(x); }

  int y() const { return origin_.y(); }
  void set_y(int y) { origin_.set_y(y); }

  int width() const { return size_.width(); }
  void set_width(int width) { size_.set_width(width); }

  int height() const { return size_.height(); }
  void set_height(int height) { size_.set_height(height); }

  const Point& origin() const { return origin_; }
  void set_origin(const Point& origin) { origin_ = origin; }

  const Size& size() const { return size_; }
  void set_size(const Size& size) { size_ = size; }

  int right() const { return x() + width(); }
  int bottom() const { return y() + height(); }

  Point top_right() const { return Point(right(), y()); }
  Point bottom_left() const { return Point(x(), bottom()); }
  Point bottom_right() const { return Point(right(), bottom()); }

  Vector2d OffsetFromOrigin() const { return Vector2d(x(), y()); }

  void SetRect(int x, int y, int width, int height) {
    origin_.SetPoint(x, y);
    size_.SetSize(width, height);
  }

  // Shrink the rectangle by a horizontal and vertical distance on all sides.
  void Inset(int horizontal, int vertical) {
    Inset(horizontal, vertical, horizontal, vertical);
  }

  // Shrink the rectangle by the given insets.
  void Inset(const Insets& insets);

  // Shrink the rectangle by the specified amount on each side.
  void Inset(int left, int top, int right, int bottom);

  // Move the rectangle by a horizontal and vertical distance.
  void Offset(int horizontal, int vertical);
  void Offset(const Vector2d& distance) { Offset(distance.x(), distance.y()); }
  void operator+=(const Vector2d& offset);
  void operator-=(const Vector2d& offset);

  Insets InsetsFrom(const Rect& inner) const;

  // Returns true if the area of the rectangle is zero.
  bool IsEmpty() const { return size_.IsEmpty(); }

  // A rect is less than another rect if its origin is less than
  // the other rect's origin. If the origins are equal, then the
  // shortest rect is less than the other. If the origin and the
  // height are equal, then the narrowest rect is less than.
  // This comparison is required to use Rects in sets, or sorted
  // vectors.
  bool operator<(const Rect& other) const;

  // Returns true if the point identified by point_x and point_y falls inside
  // this rectangle.  The point (x, y) is inside the rectangle, but the
  // point (x + width, y + height) is not.
  bool Contains(int point_x, int point_y) const;

  // Returns true if the specified point is contained by this rectangle.
  bool Contains(const Point& point) const {
    return Contains(point.x(), point.y());
  }

  // Returns true if this rectangle contains the specified rectangle.
  bool Contains(const Rect& rect) const;

  // Returns true if this rectangle intersects the specified rectangle.
  // An empty rectangle doesn't intersect any rectangle.
  bool Intersects(const Rect& rect) const;

  // Computes the intersection of this rectangle with the given rectangle.
  void Intersect(const Rect& rect);

  // Computes the union of this rectangle with the given rectangle.  The union
  // is the smallest rectangle containing both rectangles.
  void Union(const Rect& rect);

  // Computes the rectangle resulting from subtracting |rect| from |*this|,
  // i.e. the bounding rect of |Region(*this) - Region(rect)|.
  void Subtract(const Rect& rect);

  // Fits as much of the receiving rectangle into the supplied rectangle as
  // possible, becoming the result. For example, if the receiver had
  // a x-location of 2 and a width of 4, and the supplied rectangle had
  // an x-location of 0 with a width of 5, the returned rectangle would have
  // an x-location of 1 with a width of 4.
  void AdjustToFit(const Rect& rect);

  // Returns the center of this rectangle.
  Point CenterPoint() const;

  // Becomes a rectangle that has the same center point but with a size capped
  // at given |size|.
  void ClampToCenteredSize(const Size& size);

  // Splits |this| in two halves, |left_half| and |right_half|.
  void SplitVertically(Rect* left_half, Rect* right_half) const;

  // Returns true if this rectangle shares an entire edge (i.e., same width or
  // same height) with the given rectangle, and the rectangles do not overlap.
  bool SharesEdgeWith(const Rect& rect) const;

  // Returns the manhattan distance from the rect to the point. If the point is
  // inside the rect, returns 0.
  int ManhattanDistanceToPoint(const Point& point) const;

  // Returns the manhattan distance between the contents of this rect and the
  // contents of the given rect. That is, if the intersection of the two rects
  // is non-empty then the function returns 0. If the rects share a side, it
  // returns the smallest non-zero value appropriate for int.
  int ManhattanInternalDistance(const Rect& rect) const;

  std::string ToString() const;

 private:
  gfx::Point origin_;
  gfx::Size size_;
};

inline bool operator==(const Rect& lhs, const Rect& rhs) {
  return lhs.origin() == rhs.origin() && lhs.size() == rhs.size();
}

inline bool operator!=(const Rect& lhs, const Rect& rhs) {
  return !(lhs == rhs);
}

GFX_EXPORT Rect operator+(const Rect& lhs, const Vector2d& rhs);
GFX_EXPORT Rect operator-(const Rect& lhs, const Vector2d& rhs);

inline Rect operator+(const Vector2d& lhs, const Rect& rhs) {
  return rhs + lhs;
}

GFX_EXPORT Rect IntersectRects(const Rect& a, const Rect& b);
GFX_EXPORT Rect UnionRects(const Rect& a, const Rect& b);
GFX_EXPORT Rect SubtractRects(const Rect& a, const Rect& b);

// Constructs a rectangle with |p1| and |p2| as opposite corners.
//
// This could also be thought of as "the smallest rect that contains both
// points", except that we consider points on the right/bottom edges of the
// rect to be outside the rect.  So technically one or both points will not be
// contained within the rect, because they will appear on one of these edges.
GFX_EXPORT Rect BoundingRect(const Point& p1, const Point& p2);

inline Rect ScaleToEnclosingRect(const Rect& rect,
                                 float x_scale,
                                 float y_scale) {
  int x = std::floor(rect.x() * x_scale);
  int y = std::floor(rect.y() * y_scale);
  int r = rect.width() == 0 ? x : std::ceil(rect.right() * x_scale);
  int b = rect.height() == 0 ? y : std::ceil(rect.bottom() * y_scale);
  return Rect(x, y, r - x, b - y);
}

inline Rect ScaleToEnclosingRect(const Rect& rect, float scale) {
  return ScaleToEnclosingRect(rect, scale, scale);
}

inline Rect ScaleToEnclosedRect(const Rect& rect,
                                float x_scale,
                                float y_scale) {
  int x = std::ceil(rect.x() * x_scale);
  int y = std::ceil(rect.y() * y_scale);
  int r = rect.width() == 0 ? x : std::floor(rect.right() * x_scale);
  int b = rect.height() == 0 ? y : std::floor(rect.bottom() * y_scale);
  return Rect(x, y, r - x, b - y);
}

inline Rect ScaleToEnclosedRect(const Rect& rect, float scale) {
  return ScaleToEnclosedRect(rect, scale, scale);
}

// This is declared here for use in gtest-based unit tests but is defined in
// the gfx_test_support target. Depend on that to use this in your unit test.
// This should not be used in production code - call ToString() instead.
void PrintTo(const Rect& rect, ::std::ostream* os);

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_RECT_H_

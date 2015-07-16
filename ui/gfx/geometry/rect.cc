// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/rect.h"

#include <algorithm>

#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "ui/gfx/geometry/insets.h"

namespace gfx {

void AdjustAlongAxis(int dst_origin, int dst_size, int* origin, int* size) {
  *size = std::min(dst_size, *size);
  if (*origin < dst_origin)
    *origin = dst_origin;
  else
    *origin = std::min(dst_origin + dst_size, *origin + *size) - *size;
}

}  // namespace

namespace gfx {

void Rect::Inset(const Insets& insets) {
  Inset(insets.left(), insets.top(), insets.right(), insets.bottom());
}

void Rect::Inset(int left, int top, int right, int bottom) {
  origin_ += Vector2d(left, top);
  set_width(std::max(width() - left - right, static_cast<int>(0)));
  set_height(std::max(height() - top - bottom, static_cast<int>(0)));
}

void Rect::Offset(int horizontal, int vertical) {
  origin_ += Vector2d(horizontal, vertical);
}

void Rect::operator+=(const Vector2d& offset) {
  origin_ += offset;
}

void Rect::operator-=(const Vector2d& offset) {
  origin_ -= offset;
}

Insets Rect::InsetsFrom(const Rect& inner) const {
  return Insets(inner.y() - y(),
                inner.x() - x(),
                bottom() - inner.bottom(),
                right() - inner.right());
}

bool Rect::operator<(const Rect& other) const {
  if (origin_ == other.origin_) {
    if (width() == other.width()) {
      return height() < other.height();
    } else {
      return width() < other.width();
    }
  } else {
    return origin_ < other.origin_;
  }
}

bool Rect::Contains(int point_x, int point_y) const {
  return (point_x >= x()) && (point_x < right()) && (point_y >= y()) &&
         (point_y < bottom());
}

bool Rect::Contains(const Rect& rect) const {
  return (rect.x() >= x() && rect.right() <= right() && rect.y() >= y() &&
          rect.bottom() <= bottom());
}

bool Rect::Intersects(const Rect& rect) const {
  return !(IsEmpty() || rect.IsEmpty() || rect.x() >= right() ||
           rect.right() <= x() || rect.y() >= bottom() || rect.bottom() <= y());
}

void Rect::Intersect(const Rect& rect) {
  if (IsEmpty() || rect.IsEmpty()) {
    SetRect(0, 0, 0, 0);
    return;
  }

  int rx = std::max(x(), rect.x());
  int ry = std::max(y(), rect.y());
  int rr = std::min(right(), rect.right());
  int rb = std::min(bottom(), rect.bottom());

  if (rx >= rr || ry >= rb)
    rx = ry = rr = rb = 0;  // non-intersecting

  SetRect(rx, ry, rr - rx, rb - ry);
}

void Rect::Union(const Rect& rect) {
  if (IsEmpty()) {
    *this = rect;
    return;
  }
  if (rect.IsEmpty())
    return;

  int rx = std::min(x(), rect.x());
  int ry = std::min(y(), rect.y());
  int rr = std::max(right(), rect.right());
  int rb = std::max(bottom(), rect.bottom());

  SetRect(rx, ry, rr - rx, rb - ry);
}

void Rect::Subtract(const Rect& rect) {
  if (!Intersects(rect))
    return;
  if (rect.Contains(*this)) {
    SetRect(0, 0, 0, 0);
    return;
  }

  int rx = x();
  int ry = y();
  int rr = right();
  int rb = bottom();

  if (rect.y() <= y() && rect.bottom() >= bottom()) {
    // complete intersection in the y-direction
    if (rect.x() <= x()) {
      rx = rect.right();
    } else if (rect.right() >= right()) {
      rr = rect.x();
    }
  } else if (rect.x() <= x() && rect.right() >= right()) {
    // complete intersection in the x-direction
    if (rect.y() <= y()) {
      ry = rect.bottom();
    } else if (rect.bottom() >= bottom()) {
      rb = rect.y();
    }
  }
  SetRect(rx, ry, rr - rx, rb - ry);
}

void Rect::AdjustToFit(const Rect& rect) {
  int new_x = x();
  int new_y = y();
  int new_width = width();
  int new_height = height();
  AdjustAlongAxis(rect.x(), rect.width(), &new_x, &new_width);
  AdjustAlongAxis(rect.y(), rect.height(), &new_y, &new_height);
  SetRect(new_x, new_y, new_width, new_height);
}

Point Rect::CenterPoint() const {
  return Point(x() + width() / 2, y() + height() / 2);
}

void Rect::ClampToCenteredSize(const Size& size) {
  int new_width = std::min(width(), size.width());
  int new_height = std::min(height(), size.height());
  int new_x = x() + (width() - new_width) / 2;
  int new_y = y() + (height() - new_height) / 2;
  SetRect(new_x, new_y, new_width, new_height);
}

void Rect::SplitVertically(Rect* left_half, Rect* right_half) const {
  DCHECK(left_half);
  DCHECK(right_half);

  left_half->SetRect(x(), y(), width() / 2, height());
  right_half->SetRect(
      left_half->right(), y(), width() - left_half->width(), height());
}

bool Rect::SharesEdgeWith(const Rect& rect) const {
  return (y() == rect.y() && height() == rect.height() &&
          (x() == rect.right() || right() == rect.x())) ||
         (x() == rect.x() && width() == rect.width() &&
          (y() == rect.bottom() || bottom() == rect.y()));
}

int Rect::ManhattanDistanceToPoint(const Point& point) const {
  int x_distance =
      std::max<int>(0, std::max(x() - point.x(), point.x() - right()));
  int y_distance =
      std::max<int>(0, std::max(y() - point.y(), point.y() - bottom()));

  return x_distance + y_distance;
}

int Rect::ManhattanInternalDistance(const Rect& rect) const {
  Rect c(*this);
  c.Union(rect);

  static const int kEpsilon = std::numeric_limits<int>::is_integer
                                  ? 1
                                  : std::numeric_limits<int>::epsilon();

  int x = std::max<int>(0, c.width() - width() - rect.width() + kEpsilon);
  int y = std::max<int>(0, c.height() - height() - rect.height() + kEpsilon);
  return x + y;
}

std::string Rect::ToString() const {
  return base::StringPrintf("%s %s",
                            origin().ToString().c_str(),
                            size().ToString().c_str());
}

Rect operator+(const Rect& lhs, const Vector2d& rhs) {
  Rect result(lhs);
  result += rhs;
  return result;
}

Rect operator-(const Rect& lhs, const Vector2d& rhs) {
  Rect result(lhs);
  result -= rhs;
  return result;
}

Rect IntersectRects(const Rect& a, const Rect& b) {
  Rect result = a;
  result.Intersect(b);
  return result;
}

Rect UnionRects(const Rect& a, const Rect& b) {
  Rect result = a;
  result.Union(b);
  return result;
}

Rect SubtractRects(const Rect& a, const Rect& b) {
  Rect result = a;
  result.Subtract(b);
  return result;
}

Rect BoundingRect(const Point& p1, const Point& p2) {
  int rx = std::min(p1.x(), p2.x());
  int ry = std::min(p1.y(), p2.y());
  int rr = std::max(p1.x(), p2.x());
  int rb = std::max(p1.y(), p2.y());
  return Rect(rx, ry, rr - rx, rb - ry);
}

}  // namespace gfx

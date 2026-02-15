// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GEOMETRY_GEOMETRY_H_
#define FLUTTER_SHELL_GEOMETRY_GEOMETRY_H_

#include <cmath>
#include <limits>
#include <optional>

namespace flutter {

// A point in Cartesian space relative to a separately-maintained origin.
class Point {
 public:
  Point() = default;
  Point(double x, double y) : x_(x), y_(y) {}
  Point(const Point& point) = default;
  Point& operator=(const Point& other) = default;

  double x() const { return x_; }
  double y() const { return y_; }

  bool operator==(const Point& other) const {
    return x_ == other.x_ && y_ == other.y_;
  }

 private:
  double x_ = 0.0;
  double y_ = 0.0;
};

// A 2D floating-point size with non-negative dimensions.
class Size {
 public:
  Size() = default;
  Size(double width, double height)
      : width_(std::fmax(0.0, width)), height_(std::fmax(0.0, height)) {}

  Size(const Size& size) = default;
  Size& operator=(const Size& other) = default;

  double width() const { return width_; }
  double height() const { return height_; }

  bool operator==(const Size& other) const = default;

 private:
  double width_ = 0.0;
  double height_ = 0.0;
};

// A rectangle with position in Cartesian space specified relative to a
// separately-maintained origin.
class Rect {
 public:
  Rect() = default;
  Rect(const Point& origin, const Size& size) : origin_(origin), size_(size) {}
  Rect(const Rect& rect) = default;
  Rect& operator=(const Rect& other) = default;

  double left() const { return origin_.x(); }
  double top() const { return origin_.y(); }
  double right() const { return origin_.x() + size_.width(); }
  double bottom() const { return origin_.y() + size_.height(); }
  double width() const { return size_.width(); }
  double height() const { return size_.height(); }
  Point origin() const { return origin_; }
  Size size() const { return size_; }

  bool operator==(const Rect& other) const {
    return origin_ == other.origin_ && size_ == other.size_;
  }

 private:
  Point origin_;
  Size size_;
};

// Encapsulates a min and max size that represents the constraints that some
// arbitrary box is able to take up.
class BoxConstraints {
 public:
  BoxConstraints() = default;
  BoxConstraints(const std::optional<Size>& smallest,
                 const std::optional<Size>& biggest)
      : smallest_(smallest.value_or(Size(0, 0))),
        biggest_(
            biggest.value_or(Size(std::numeric_limits<double>::infinity(),
                                  std::numeric_limits<double>::infinity()))) {}
  BoxConstraints(const BoxConstraints& other) = default;
  Size biggest() const { return biggest_; }
  Size smallest() const { return smallest_; }

  bool IsSatisfiedBy(Size size) {
    return smallest().width() <= size.width() &&
           size.width() <= biggest().width() &&
           smallest().height() <= size.height() &&
           size.height() <= biggest().height();
  }

 private:
  Size smallest_ = Size(0, 0);
  Size biggest_ = Size(std::numeric_limits<double>::infinity(),
                       std::numeric_limits<double>::infinity());
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GEOMETRY_GEOMETRY_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>
#include "Point.h"
#include "Size.h"

namespace rl {
namespace geom {

struct Rect {
  Point origin;
  Size size;

  Rect() : origin({0.0, 0.0}), size({0.0, 0.0}) {}
  Rect(Size size) : origin({0.0, 0.0}), size(size) {}
  Rect(Point origin, Size size) : origin(origin), size(size) {}
  Rect(const double components[4])
      : origin(components[0], components[1]),
        size(components[2], components[3]) {}
  Rect(double x, double y, double width, double height)
      : origin(x, y), size(width, height) {}

  /*
   *  Operator overloads
   */
  Rect operator+(const Rect& r) const {
    return Rect({origin.x + r.origin.x, origin.y + r.origin.y},
                {size.width + r.size.width, size.height + r.size.height});
  }

  Rect operator-(const Rect& r) const {
    return Rect({origin.x - r.origin.x, origin.y - r.origin.y},
                {size.width - r.size.width, size.height - r.size.height});
  }

  Rect operator*(double scale) const {
    return Rect({origin.x * scale, origin.y * scale},
                {size.width * scale, size.height * scale});
  }

  Rect operator*(const Rect& r) const {
    return Rect({origin.x * r.origin.x, origin.y * r.origin.y},
                {size.width * r.size.width, size.height * r.size.height});
  }

  bool operator==(const Rect& r) const {
    return origin == r.origin && size == r.size;
  }

  bool contains(const Point& p) const {
    return p.x >= origin.x && p.x <= size.width && p.y >= origin.y &&
           p.y <= size.height;
  }

  bool isZero() const { return size.isZero(); }

  Rect withPoint(const Point& p) const;

  Rect withPoints(const std::vector<Point>& points) const;

  std::string toString() const;

  void fromString(const std::string& str);
};

}  // namespace geom
}  // namespace rl

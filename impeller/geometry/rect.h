// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"

namespace impeller {

struct Rect {
  Point origin;
  Size size;

  constexpr Rect() : origin({0.0, 0.0}), size({0.0, 0.0}) {}

  constexpr Rect(Size size) : origin({0.0, 0.0}), size(size) {}

  constexpr Rect(Point origin, Size size) : origin(origin), size(size) {}

  constexpr Rect(const Scalar components[4])
      : origin(components[0], components[1]),
        size(components[2], components[3]) {}

  constexpr Rect(Scalar x, Scalar y, Scalar width, Scalar height)
      : origin(x, y), size(width, height) {}

  /*
   *  Operator overloads
   */
  constexpr Rect operator+(const Rect& r) const {
    return Rect({origin.x + r.origin.x, origin.y + r.origin.y},
                {size.width + r.size.width, size.height + r.size.height});
  }

  constexpr Rect operator-(const Rect& r) const {
    return Rect({origin.x - r.origin.x, origin.y - r.origin.y},
                {size.width - r.size.width, size.height - r.size.height});
  }

  constexpr Rect operator*(Scalar scale) const {
    return Rect({origin.x * scale, origin.y * scale},
                {size.width * scale, size.height * scale});
  }

  constexpr Rect operator*(const Rect& r) const {
    return Rect({origin.x * r.origin.x, origin.y * r.origin.y},
                {size.width * r.size.width, size.height * r.size.height});
  }

  constexpr bool operator==(const Rect& r) const {
    return origin == r.origin && size == r.size;
  }

  constexpr bool Contains(const Point& p) const {
    return p.x >= origin.x && p.x <= size.width && p.y >= origin.y &&
           p.y <= size.height;
  }

  constexpr bool IsZero() const { return size.IsZero(); }

  Rect WithPoint(const Point& p) const;

  Rect WithPoints(const std::vector<Point>& points) const;

  std::string ToString() const;

  void FromString(const std::string& str);
};

static_assert(sizeof(Rect) == 4 * sizeof(Scalar));

}  // namespace impeller

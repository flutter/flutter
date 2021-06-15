// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cmath>
#include <string>

#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"

namespace impeller {

struct Point {
  Scalar x = 0.0;
  Scalar y = 0.0;

  constexpr Point() = default;

  constexpr Point(Scalar x, Scalar y) : x(x), y(y) {}

  constexpr bool operator==(const Point& p) const {
    return p.x == x && p.y == y;
  }

  constexpr bool operator!=(const Point& p) const {
    return p.x != x || p.y != y;
  }

  constexpr Point operator-() const { return {-x, -y}; }

  constexpr Point operator+(const Point& p) const { return {x + p.x, y + p.y}; }

  constexpr Point operator+(const Size& s) const {
    return {x + s.width, y + s.height};
  }

  constexpr Point operator-(const Point& p) const { return {x - p.x, y - p.y}; }

  constexpr Point operator-(const Size& s) const {
    return {x - s.width, y - s.height};
  }

  constexpr Point operator*(Scalar scale) const {
    return {x * scale, y * scale};
  }

  constexpr Point operator*(const Point& p) const { return {x * p.x, y * p.y}; }

  constexpr Point operator*(const Size& s) const {
    return {x * s.width, y * s.height};
  }

  constexpr Point operator/(Scalar d) const { return {x / d, y / d}; }

  constexpr Point operator/(const Point& p) const { return {x / p.x, y / p.y}; }

  constexpr Point operator/(const Size& s) const {
    return {x / s.width, y / s.height};
  }

  constexpr Scalar GetDistanceSquared(const Point& p) const {
    double dx = p.x - x;
    double dy = p.y - y;
    return dx * dx + dy * dy;
  }

  constexpr Scalar GetDistance(const Point& p) const {
    return sqrt(GetDistanceSquared(p));
  }

  std::string ToString() const;

  void FromString(const std::string& str);
};

static_assert(sizeof(Point) == 2 * sizeof(Scalar));

}  // namespace impeller

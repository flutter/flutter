// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cmath>
#include <string>
#include "Size.h"

namespace rl {
namespace geom {

struct Point {
  double x;
  double y;

  constexpr Point() : x(0.0), y(0.0) {}

  constexpr Point(double x, double y) : x(x), y(y) {}

  /*
   *  Operator overloads
   */
  bool operator==(const Point& p) const { return p.x == x && p.y == y; }

  bool operator!=(const Point& p) const { return p.x != x || p.y != y; }

  Point operator-() const { return {-x, -y}; }

  Point operator+(const Point& p) const { return {x + p.x, y + p.y}; }
  Point operator+(const Size& s) const { return {x + s.width, y + s.height}; }

  Point operator-(const Point& p) const { return {x - p.x, y - p.y}; }
  Point operator-(const Size& s) const { return {x - s.width, y - s.height}; }

  Point operator*(double scale) const { return {x * scale, y * scale}; }
  Point operator*(const Point& p) const { return {x * p.x, y * p.y}; }
  Point operator*(const Size& s) const { return {x * s.width, y * s.height}; }

  Point operator/(double d) const { return {x / d, y / d}; }
  Point operator/(const Point& p) const { return {x / p.x, y / p.y}; }
  Point operator/(const Size& s) const { return {x / s.width, y / s.height}; }

  double distanceSquared(const Point& p) const;

  double distance(const Point& p) const;

  std::string toString() const;

  void fromString(const std::string& str);
};

}  // namespace geom
}  // namespace rl

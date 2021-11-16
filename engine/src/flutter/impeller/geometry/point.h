// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cmath>
#include <string>

#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"

namespace impeller {

template <class T>
struct TPoint {
  using Type = T;

  Type x = {};
  Type y = {};

  constexpr TPoint() = default;

  template <class U>
  explicit constexpr TPoint(const TPoint<U>& other)
      : TPoint(static_cast<Type>(other.x), static_cast<Type>(other.y)) {}

  constexpr TPoint(Type x, Type y) : x(x), y(y) {}

  static constexpr TPoint<Type> MakeXY(Type x, Type y) { return {x, y}; }

  constexpr bool operator==(const TPoint& p) const {
    return p.x == x && p.y == y;
  }

  constexpr bool operator!=(const TPoint& p) const {
    return p.x != x || p.y != y;
  }

  constexpr TPoint operator-() const { return {-x, -y}; }

  constexpr TPoint operator+(const TPoint& p) const {
    return {x + p.x, y + p.y};
  }

  constexpr TPoint operator+(const TSize<Type>& s) const {
    return {x + s.width, y + s.height};
  }

  constexpr TPoint operator-(const TPoint& p) const {
    return {x - p.x, y - p.y};
  }

  constexpr TPoint operator-(const TSize<Type>& s) const {
    return {x - s.width, y - s.height};
  }

  constexpr TPoint operator*(Type scale) const {
    return {x * scale, y * scale};
  }

  constexpr TPoint operator*(const TPoint& p) const {
    return {x * p.x, y * p.y};
  }

  constexpr TPoint operator*(const TSize<Type>& s) const {
    return {x * s.width, y * s.height};
  }

  constexpr TPoint operator/(Type d) const { return {x / d, y / d}; }

  constexpr TPoint operator/(const TPoint& p) const {
    return {x / p.x, y / p.y};
  }

  constexpr TPoint operator/(const TSize<Type>& s) const {
    return {x / s.width, y / s.height};
  }

  constexpr Type GetDistanceSquared(const TPoint& p) const {
    double dx = p.x - x;
    double dy = p.y - y;
    return dx * dx + dy * dy;
  }

  constexpr Type GetDistance(const TPoint& p) const {
    return sqrt(GetDistanceSquared(p));
  }
};

using Point = TPoint<Scalar>;
using IPoint = TPoint<int64_t>;

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_POINT_H_
#define FLUTTER_IMPELLER_GEOMETRY_POINT_H_

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <ostream>
#include <string>
#include <type_traits>

#include "fml/logging.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"
#include "impeller/geometry/type_traits.h"

namespace impeller {

#define ONLY_ON_FLOAT_M(Modifiers, Return) \
  template <typename U = T>                \
  Modifiers std::enable_if_t<std::is_floating_point_v<U>, Return>
#define ONLY_ON_FLOAT(Return) DL_ONLY_ON_FLOAT_M(, Return)

template <class T>
struct TPoint {
  using Type = T;

  Type x = {};
  Type y = {};

  constexpr TPoint() = default;

  template <class U>
  explicit constexpr TPoint(const TPoint<U>& other)
      : TPoint(static_cast<Type>(other.x), static_cast<Type>(other.y)) {}

  template <class U>
  explicit constexpr TPoint(const TSize<U>& other)
      : TPoint(static_cast<Type>(other.width),
               static_cast<Type>(other.height)) {}

  constexpr TPoint(Type x, Type y) : x(x), y(y) {}

  static constexpr TPoint<Type> MakeXY(Type x, Type y) { return {x, y}; }

  template <class U>
  static constexpr TPoint Round(const TPoint<U>& other) {
    return TPoint{static_cast<Type>(std::round(other.x)),
                  static_cast<Type>(std::round(other.y))};
  }

  constexpr bool operator==(const TPoint& p) const {
    return p.x == x && p.y == y;
  }

  constexpr bool operator!=(const TPoint& p) const {
    return p.x != x || p.y != y;
  }

  template <class U>
  inline TPoint operator+=(const TPoint<U>& p) {
    x += static_cast<Type>(p.x);
    y += static_cast<Type>(p.y);
    return *this;
  }

  template <class U>
  inline TPoint operator+=(const TSize<U>& s) {
    x += static_cast<Type>(s.width);
    y += static_cast<Type>(s.height);
    return *this;
  }

  template <class U>
  inline TPoint operator-=(const TPoint<U>& p) {
    x -= static_cast<Type>(p.x);
    y -= static_cast<Type>(p.y);
    return *this;
  }

  template <class U>
  inline TPoint operator-=(const TSize<U>& s) {
    x -= static_cast<Type>(s.width);
    y -= static_cast<Type>(s.height);
    return *this;
  }

  template <class U>
  inline TPoint operator*=(const TPoint<U>& p) {
    x *= static_cast<Type>(p.x);
    y *= static_cast<Type>(p.y);
    return *this;
  }

  template <class U>
  inline TPoint operator*=(const TSize<U>& s) {
    x *= static_cast<Type>(s.width);
    y *= static_cast<Type>(s.height);
    return *this;
  }

  template <class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
  inline TPoint operator*=(U scale) {
    x *= static_cast<Type>(scale);
    y *= static_cast<Type>(scale);
    return *this;
  }

  template <class U>
  inline TPoint operator/=(const TPoint<U>& p) {
    x /= static_cast<Type>(p.x);
    y /= static_cast<Type>(p.y);
    return *this;
  }

  template <class U>
  inline TPoint operator/=(const TSize<U>& s) {
    x /= static_cast<Type>(s.width);
    y /= static_cast<Type>(s.height);
    return *this;
  }

  template <class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
  inline TPoint operator/=(U scale) {
    x /= static_cast<Type>(scale);
    y /= static_cast<Type>(scale);
    return *this;
  }

  constexpr TPoint operator-() const { return {-x, -y}; }

  constexpr TPoint operator+(const TPoint& p) const {
    return {x + p.x, y + p.y};
  }

  template <class U>
  constexpr TPoint operator+(const TSize<U>& s) const {
    return {x + static_cast<Type>(s.width), y + static_cast<Type>(s.height)};
  }

  constexpr TPoint operator-(const TPoint& p) const {
    return {x - p.x, y - p.y};
  }

  template <class U>
  constexpr TPoint operator-(const TSize<U>& s) const {
    return {x - static_cast<Type>(s.width), y - static_cast<Type>(s.height)};
  }

  template <class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
  constexpr TPoint operator*(U scale) const {
    return {static_cast<Type>(x * scale), static_cast<Type>(y * scale)};
  }

  constexpr TPoint operator*(const TPoint& p) const {
    return {x * p.x, y * p.y};
  }

  template <class U>
  constexpr TPoint operator*(const TSize<U>& s) const {
    return {x * static_cast<Type>(s.width), y * static_cast<Type>(s.height)};
  }

  template <class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
  constexpr TPoint operator/(U d) const {
    return {static_cast<Type>(x / d), static_cast<Type>(y / d)};
  }

  constexpr TPoint operator/(const TPoint& p) const {
    return {x / p.x, y / p.y};
  }

  template <class U>
  constexpr TPoint operator/(const TSize<U>& s) const {
    return {x / static_cast<Type>(s.width), y / static_cast<Type>(s.height)};
  }

  constexpr Type GetDistanceSquared(const TPoint& p) const {
    double dx = p.x - x;
    double dy = p.y - y;
    return dx * dx + dy * dy;
  }

  constexpr TPoint Min(const TPoint& p) const {
    return {std::min<Type>(x, p.x), std::min<Type>(y, p.y)};
  }

  constexpr TPoint Max(const TPoint& p) const {
    return {std::max<Type>(x, p.x), std::max<Type>(y, p.y)};
  }

  constexpr TPoint Floor() const { return {std::floor(x), std::floor(y)}; }

  constexpr TPoint Ceil() const { return {std::ceil(x), std::ceil(y)}; }

  constexpr TPoint Round() const { return {std::round(x), std::round(y)}; }

  constexpr Type GetDistance(const TPoint& p) const {
    return sqrt(GetDistanceSquared(p));
  }

  constexpr Type GetLengthSquared() const {
    return static_cast<double>(x) * x + static_cast<double>(y) * y;
  }

  constexpr Type GetLength() const { return std::sqrt(GetLengthSquared()); }

  /// Returns the distance (squared) from this point to the closest point on
  /// the line segment p0 -> p1.
  ///
  /// If the projection of this point onto the line defined by the two points
  /// is between them, the distance (squared) to that point is returned.
  /// Otherwise, we return the distance (squared) to the endpoint that is
  /// closer to the projected point.
  Type GetDistanceToSegmentSquared(TPoint p0, TPoint p1) const {
    // Compute relative vectors to one endpoint of the segment (p0)
    TPoint u = p1 - p0;
    TPoint v = *this - p0;

    // Compute the projection of (this point) onto p0->p1.
    Scalar dot = u.Dot(v);
    if (dot <= 0) {
      // The projection lands outside the segment on the p0 side.
      // The result is the (square of the) distance to p0 (length of v).
      return v.GetLengthSquared();
    }

    // The dot product is the product of the length of the two vectors
    // ||u|| and ||v|| and the cosine of the angle between them. The length
    // of the v vector times the cosine is the same as the length of
    // the projection of the v vector onto the u vector (consider a right
    // triangle [(0,0), v, v_projected], the length of v multipled by the
    // cosine is the length of v_projected).
    //
    // Thus the dot product is also the product of the u vector and the
    // projected shadow of the v vector onto the u vector.
    //
    // So, if the dot product is larger than the square of the length of
    // the u vector, then the v vector was projected onto the line beyond
    // the end of the u vector and so we can use the distance formula to
    // that endpoint as our result.
    Scalar uLengthSquared = u.GetLengthSquared();
    if (dot >= uLengthSquared) {
      // The projection lands outside the segment on the p1 side.
      // The result is the (square of the) distance to p1.
      return GetDistanceSquared(p1);
    }

    // We must now compute the distance from this point to its projection
    // on to the segment.
    //
    // We compute the cross product of the two vectors u and v which
    // gives us the area of the parallelogram [(0,0), u, u+v, v]. That
    // parallelogram area is also the product of the length of one of its
    // sides and the height perpendicular to that side. We have the length
    // of one side which is the length of the segment itself (squared) as
    // uLengthSquared, so if we divide the parallelogram area (squared)
    // by uLengthSquared then we will get its height (squared) relative to u.
    //
    // That height is also the distance from this point to the line segment.
    Scalar cross = u.Cross(v);
    // The cross product may currently be signed, but we will square it later.

    // To get our height (squared), we want to compute:
    //   result^2 == h^2 == (cross * cross / uLengthSquared)
    //
    // We reorder the equation slightly to avoid infinities:
    return (cross / uLengthSquared) * cross;
  }

  /// Returns the distance from this point to the closest point on the line
  /// segment p0 -> p1.
  ///
  /// If the projection of this point onto the line defined by the two points
  /// is between them, the distance to that point is returned. Otherwise,
  /// we return the distance to the endpoint that is closer to the projected
  /// point.
  constexpr Type GetDistanceToSegment(TPoint p0, TPoint p1) const {
    return std::sqrt(GetDistanceToSegmentSquared(p0, p1));
  }

  constexpr TPoint Normalize() const {
    const auto length = GetLength();
    if (length == 0) {
      return {1, 0};
    }
    return {x / length, y / length};
  }

  constexpr TPoint Abs() const { return {std::fabs(x), std::fabs(y)}; }

  constexpr Type Cross(const TPoint& p) const { return (x * p.y) - (y * p.x); }

  /// Return the cross product representing the sign (turning direction) and
  /// magnitude (sin of the angle) of the angle from p1 to p2 as viewed from
  /// p0.
  ///
  /// Equivalent to ((p1 - p0).Cross(p2 - p0)).
  static constexpr Type Cross(const TPoint& p0,
                              const TPoint& p1,
                              const TPoint& p2) {
    return (p1 - p0).Cross(p2 - p0);
  }

  constexpr Type Dot(const TPoint& p) const { return (x * p.x) + (y * p.y); }

  constexpr TPoint Reflect(const TPoint& axis) const {
    return *this - axis * this->Dot(axis) * 2;
  }

  constexpr TPoint Rotate(const Radians& angle) const {
    const auto cos_a = std::cosf(angle.radians);
    const auto sin_a = std::sinf(angle.radians);
    return {x * cos_a - y * sin_a, x * sin_a + y * cos_a};
  }

  /// Return the perpendicular vector turning to the right (Clockwise)
  /// in the logical coordinate system where X increases to the right and Y
  /// increases downward.
  constexpr TPoint PerpendicularRight() const { return {-y, x}; }

  /// Return the perpendicular vector turning to the left (Counterclockwise)
  /// in the logical coordinate system where X increases to the right and Y
  /// increases downward.
  constexpr TPoint PerpendicularLeft() const { return {y, -x}; }

  constexpr Radians AngleTo(const TPoint& p) const {
    return Radians{std::atan2(this->Cross(p), this->Dot(p))};
  }

  constexpr TPoint Lerp(const TPoint& p, Scalar t) const {
    return *this + (p - *this) * t;
  }

  constexpr bool IsZero() const { return x == 0 && y == 0; }

  ONLY_ON_FLOAT_M(constexpr, bool)
  IsFinite() const { return std::isfinite(x) && std::isfinite(y); }
};

// Specializations for mixed (float & integer) algebraic operations.

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator+(const TPoint<F>& p1, const TPoint<I>& p2) {
  return {p1.x + static_cast<F>(p2.x), p1.y + static_cast<F>(p2.y)};
}

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator+(const TPoint<I>& p1, const TPoint<F>& p2) {
  return p2 + p1;
}

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator-(const TPoint<F>& p1, const TPoint<I>& p2) {
  return {p1.x - static_cast<F>(p2.x), p1.y - static_cast<F>(p2.y)};
}

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator-(const TPoint<I>& p1, const TPoint<F>& p2) {
  return {static_cast<F>(p1.x) - p2.x, static_cast<F>(p1.y) - p2.y};
}

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator*(const TPoint<F>& p1, const TPoint<I>& p2) {
  return {p1.x * static_cast<F>(p2.x), p1.y * static_cast<F>(p2.y)};
}

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator*(const TPoint<I>& p1, const TPoint<F>& p2) {
  return p2 * p1;
}

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator/(const TPoint<F>& p1, const TPoint<I>& p2) {
  return {p1.x / static_cast<F>(p2.x), p1.y / static_cast<F>(p2.y)};
}

template <class F, class I, class = MixedOp<F, I>>
constexpr TPoint<F> operator/(const TPoint<I>& p1, const TPoint<F>& p2) {
  return {static_cast<F>(p1.x) / p2.x, static_cast<F>(p1.y) / p2.y};
}

// RHS algebraic operations with arithmetic types.

template <class T, class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
constexpr TPoint<T> operator*(U s, const TPoint<T>& p) {
  return p * s;
}

template <class T, class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
constexpr TPoint<T> operator/(U s, const TPoint<T>& p) {
  return {static_cast<T>(s) / p.x, static_cast<T>(s) / p.y};
}

// RHS algebraic operations with TSize.

template <class T, class U>
constexpr TPoint<T> operator+(const TSize<U>& s, const TPoint<T>& p) {
  return p + s;
}

template <class T, class U>
constexpr TPoint<T> operator-(const TSize<U>& s, const TPoint<T>& p) {
  return {static_cast<T>(s.width) - p.x, static_cast<T>(s.height) - p.y};
}

template <class T, class U>
constexpr TPoint<T> operator*(const TSize<U>& s, const TPoint<T>& p) {
  return p * s;
}

template <class T, class U>
constexpr TPoint<T> operator/(const TSize<U>& s, const TPoint<T>& p) {
  return {static_cast<T>(s.width) / p.x, static_cast<T>(s.height) / p.y};
}

template <class T>
constexpr TPoint<T> operator-(const TPoint<T>& p, T v) {
  return {p.x - v, p.y - v};
}

using Point = TPoint<Scalar>;
using IPoint = TPoint<int64_t>;
using IPoint32 = TPoint<int32_t>;
using UintPoint32 = TPoint<uint32_t>;
using Vector2 = Point;
using Quad = std::array<Point, 4>;

[[maybe_unused]]
static constexpr impeller::Vector2 kQuadrantAxes[4] = {
    {1.0f, 0.0f},
    {0.0f, 1.0f},
    {-1.0f, 0.0f},
    {0.0f, -1.0f},
};

#undef ONLY_ON_FLOAT
#undef ONLY_ON_FLOAT_M

}  // namespace impeller

namespace std {

template <class T>
inline std::ostream& operator<<(std::ostream& out,
                                const impeller::TPoint<T>& p) {
  out << "(" << p.x << ", " << p.y << ")";
  return out;
}

}  // namespace std

#endif  // FLUTTER_IMPELLER_GEOMETRY_POINT_H_

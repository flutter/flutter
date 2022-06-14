// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cmath>
#include <string>

#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"

namespace impeller {

struct Vector3 {
  union {
    struct {
      Scalar x = 0.0;
      Scalar y = 0.0;
      Scalar z = 0.0;
    };
    Scalar e[3];
  };

  constexpr Vector3(){};

  constexpr Vector3(const Color& c) : x(c.red), y(c.green), z(c.blue) {}

  constexpr Vector3(const Point& p) : x(p.x), y(p.y) {}

  constexpr Vector3(const Size& s) : x(s.width), y(s.height) {}

  constexpr Vector3(Scalar x, Scalar y) : x(x), y(y) {}

  constexpr Vector3(Scalar x, Scalar y, Scalar z) : x(x), y(y), z(z) {}

  /**
   *  The length (or magnitude of the vector).
   *
   *  @return the calculated length.
   */
  Scalar Length() const { return sqrt(x * x + y * y + z * z); }

  constexpr Vector3 Normalize() const {
    const auto len = Length();
    return {x / len, y / len, z / len};
  }

  constexpr Scalar Dot(const Vector3& other) const {
    return ((x * other.x) + (y * other.y) + (z * other.z));
  }

  constexpr Vector3 Cross(const Vector3& other) const {
    return {
        (y * other.z) - (z * other.y),  //
        (z * other.x) - (x * other.z),  //
        (x * other.y) - (y * other.x)   //
    };
  }

  constexpr bool operator==(const Vector3& v) const {
    return v.x == x && v.y == y && v.z == z;
  }

  constexpr bool operator!=(const Vector3& v) const {
    return v.x != x || v.y != y || v.z != z;
  }

  constexpr Vector3 operator+=(const Vector3& p) {
    x += p.x;
    y += p.y;
    z += p.z;
    return *this;
  }

  constexpr Vector3 operator-=(const Vector3& p) {
    x -= p.x;
    y -= p.y;
    z -= p.z;
    return *this;
  }

  constexpr Vector3 operator*=(const Vector3& p) {
    x *= p.x;
    y *= p.y;
    z *= p.z;
    return *this;
  }

  constexpr Vector3 operator/=(const Vector3& p) {
    x /= p.x;
    y /= p.y;
    z /= p.z;
    return *this;
  }

  constexpr Vector3 operator-() const { return Vector3(-x, -y, -z); }

  constexpr Vector3 operator+(const Vector3& v) const {
    return Vector3(x + v.x, y + v.y, z + v.z);
  }

  constexpr Vector3 operator-(const Vector3& v) const {
    return Vector3(x - v.x, y - v.y, z - v.z);
  }

  /**
   *  Make a linear combination of two vectors and return the result.
   *
   *  @param a      the first vector.
   *  @param aScale the scale to use for the first vector.
   *  @param b      the second vector.
   *  @param bScale the scale to use for the second vector.
   *
   *  @return the combined vector.
   */
  static constexpr Vector3 Combine(const Vector3& a,
                                   Scalar aScale,
                                   const Vector3& b,
                                   Scalar bScale) {
    return {
        aScale * a.x + bScale * b.x,  //
        aScale * a.y + bScale * b.y,  //
        aScale * a.z + bScale * b.z,  //
    };
  }

  std::string ToString() const;
};

struct Vector4 {
  union {
    struct {
      Scalar x = 0.0;
      Scalar y = 0.0;
      Scalar z = 0.0;
      Scalar w = 1.0;
    };
    Scalar e[4];
  };

  constexpr Vector4() {}

  constexpr Vector4(const Color& c)
      : x(c.red), y(c.green), z(c.blue), w(c.alpha) {}

  constexpr Vector4(Scalar x, Scalar y, Scalar z, Scalar w)
      : x(x), y(y), z(z), w(w) {}

  constexpr Vector4(const Vector3& v) : x(v.x), y(v.y), z(v.z) {}

  constexpr Vector4(const Point& p) : x(p.x), y(p.y) {}

  Vector4 Normalize() const {
    const Scalar inverse = 1.0 / sqrt(x * x + y * y + z * z + w * w);
    return Vector4(x * inverse, y * inverse, z * inverse, w * inverse);
  }

  constexpr bool operator==(const Vector4& v) const {
    return (x == v.x) && (y == v.y) && (z == v.z) && (w == v.w);
  }

  constexpr bool operator!=(const Vector4& v) const {
    return (x != v.x) || (y != v.y) || (z != v.z) || (w != v.w);
  }

  constexpr Vector4 operator+(const Vector4& v) const {
    return Vector4(x + v.x, y + v.y, z + v.z, w + v.w);
  }

  constexpr Vector4 operator-(const Vector4& v) const {
    return Vector4(x - v.x, y - v.y, z - v.z, w - v.w);
  }

  std::string ToString() const;
};

static_assert(sizeof(Vector3) == 3 * sizeof(Scalar));
static_assert(sizeof(Vector4) == 4 * sizeof(Scalar));

}  // namespace impeller

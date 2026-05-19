// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_SCALAR_H_
#define FLUTTER_IMPELLER_GEOMETRY_SCALAR_H_

#include <cfloat>
#include <ostream>
#include <type_traits>
#include <valarray>

#include "impeller/geometry/constants.h"

namespace impeller {

// NOLINTBEGIN(google-explicit-constructor)

using Scalar = float;

template <class T, class = std::enable_if_t<std::is_arithmetic_v<T>>>
constexpr T Absolute(const T& val) {
  return val >= T{} ? val : -val;
}

template <>
constexpr Scalar Absolute<Scalar>(const float& val) {
  return fabsf(val);
}

constexpr inline bool ScalarNearlyZero(Scalar x,
                                       Scalar tolerance = kEhCloseEnough) {
  return Absolute(x) <= tolerance;
}

constexpr inline bool ScalarNearlyEqual(Scalar x,
                                        Scalar y,
                                        Scalar tolerance = kEhCloseEnough) {
  return ScalarNearlyZero(x - y, tolerance);
}

struct Degrees;

struct Radians {
  Scalar radians = 0.0;

  constexpr Radians() = default;

  explicit constexpr Radians(Scalar p_radians) : radians(p_radians) {}

  constexpr bool IsFinite() const { return std::isfinite(radians); }

  constexpr Radians operator-() { return Radians{-radians}; }

  constexpr Radians operator+(Radians r) {
    return Radians{radians + r.radians};
  }

  constexpr Radians operator-(Radians r) {
    return Radians{radians - r.radians};
  }

  constexpr auto operator<=>(const Radians& r) const = default;
};

struct Degrees {
  Scalar degrees = 0.0;

  constexpr Degrees() = default;

  explicit constexpr Degrees(Scalar p_degrees) : degrees(p_degrees) {}

  constexpr operator Radians() const {
    return Radians{degrees * kPi / 180.0f};
  };

  constexpr bool IsFinite() const { return std::isfinite(degrees); }

  constexpr Degrees operator-() const { return Degrees{-degrees}; }

  constexpr Degrees operator+(Degrees d) const {
    return Degrees{degrees + d.degrees};
  }

  constexpr Degrees operator-(Degrees d) const {
    return Degrees{degrees - d.degrees};
  }

  constexpr auto operator<=>(const Degrees& d) const = default;

  constexpr Degrees GetPositive() const {
    Scalar deg = std::fmod(degrees, 360.0f);
    if (deg < 0.0f) {
      deg += 360.0f;
    }
    return Degrees{deg};
  }
};

// NOLINTEND(google-explicit-constructor)

}  // namespace impeller

namespace std {

inline std::ostream& operator<<(std::ostream& out, const impeller::Degrees& d) {
  return out << "Degrees(" << d.degrees << ")";
}

inline std::ostream& operator<<(std::ostream& out, const impeller::Radians& r) {
  return out << "Radians(" << r.radians << ")";
}

}  // namespace std

#endif  // FLUTTER_IMPELLER_GEOMETRY_SCALAR_H_

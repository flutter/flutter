// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_SCALAR_H_
#define FLUTTER_IMPELLER_GEOMETRY_SCALAR_H_

#include <cfloat>
#include <optional>
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

/// @brief   Returns the t value for executing a lerp based on where a
///          reference Scalar value (v) falls along the range defined by
///          the 2 indicated values (val1) and (val2), if such a value
///          exists.
///
/// If the indicated values val1 and val2 are the same then the result
/// can only be computed if the desired_value is also the same. The
/// function returns 0 in that case, or std::nullopt if the desired_value
/// is not equal to the common interpolation value.
///
/// Otherwise, returns 0.0f if the desired_value is equal to val1, or
/// 1.0f if the desired_value is equal to val2, otherwise computes a T
/// value that is consistent with the [0,1] return values just described.
/// The T value is not constrained to the range [0,1] if the desired_value
/// is not between val1 and val2.
///
/// For example, if you want to find the color between 2 other colors
/// where the alpha value is A, you could compute:
///
///    std::optional<Scalar> t = GetLerpTValue(color1.alpha, color2.alpha, A);
///    if (t.has_value()) {
///      Color result = Color::Lerp(color1, color2, t.value());
///      FML_DCHECK(ScalarNearlyEqual(A, result.alpha));
///    }
///
/// @param val1            The first value to interpolate from.
/// @param val2            The second value to interpolate to.
/// @param desired_value   The value you want the result to interpolate.
/// @return   The "t" value used to interpolate between val1 and val2 to
///           produce the indicated desired_value, or std::nullopt if such
///           interpolation is not possible.
constexpr inline std::optional<Scalar> GetLerpTValue(Scalar val1,
                                                     Scalar val2,
                                                     Scalar desired_value) {
  Scalar denominator = val2 - val1;
  if (denominator != 0.0f) {
    return (desired_value - val1) / denominator;
  } else if (desired_value == val1) {
    return 0.0f;
  } else {
    return std::nullopt;
  }
}

/// @brief   Returns the T instance that is interpolated using a and b
///          resulting in the desired_value in the indicated field if
///          such a value exists.
///
/// If the indicated field has the same value in a and b and that value
/// does not match the desired_value, then a std::nullopt is returned,
/// otherwise the value a is returned even if it is not the same as b,
/// no further interpolation happens.
///
/// While the most common case is that the desired_value of the field is
/// between the field values in a and b, the function will happily interpolate
/// to a T value that does not lie between a and b if the desired_value is
/// outside of their field values.
///
/// For example, if you want to find the color between 2 other colors
/// where the alpha value is A, you could compute:
///
///    std::optional<Color> result =
///        LerpToFieldValue(color1, color2, &Color::alpha, A);
///    if (result.has_value()) {
///      FML_DCHECK(ScalarNearlyEqual(result->alpha, A));
///      std::optional<Color> result2 =
///          LerpToFieldValue(color2, color1, &Color::alpha, A);
///      FML_DCHECK(result == result2);
///    }
///
/// Note that the order of a and b (color1 and color2 in the example) does
/// not matter because the method interpolates to a field value, not based
/// on a preconceived notion of "from this value to that value".
///
/// @param a               The first instance to interpolate between.
/// @param b               The second instance to interpolate between.
/// @param fieldPtr        The field on the instances to interpolate to the
///                        desired_value.
/// @param desired_value   The value you want the result to contain in
///                        the specified field.
/// @return   The instance of T which exists on a linear space defined by
///           a and b, but whose indicated field contains the desired_value.
template <typename T>
constexpr std::optional<T> LerpToFieldValue(const T& a,
                                            const T& b,
                                            Scalar T::* fieldPtr,
                                            Scalar desired_value) {
  std::optional<Scalar> t =
      GetLerpTValue(a.*fieldPtr, b.*fieldPtr, desired_value);
  if (t.has_value()) {
    return T::Lerp(a, b, t.value());
  } else {
    return std::nullopt;
  }
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

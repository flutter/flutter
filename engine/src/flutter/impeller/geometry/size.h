// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <algorithm>
#include <cmath>
#include <limits>
#include <ostream>
#include <string>

#include "impeller/geometry/scalar.h"

namespace impeller {

template <class T>
struct TSize {
  using Type = T;

  Type width = {};
  Type height = {};

  constexpr TSize() {}

  constexpr TSize(Type width, Type height) : width(width), height(height) {}

  template <class U>
  explicit constexpr TSize(const TSize<U>& other)
      : TSize(static_cast<Type>(other.width), static_cast<Type>(other.height)) {
  }

  static constexpr TSize MakeWH(Type width, Type height) {
    return TSize{width, height};
  }

  static constexpr TSize Infinite() {
    return TSize{std::numeric_limits<Type>::max(),
                 std::numeric_limits<Type>::max()};
  }

  constexpr TSize operator*(Scalar scale) const {
    return {width * scale, height * scale};
  }

  constexpr TSize operator/(Scalar scale) const {
    return {static_cast<Scalar>(width) / scale,
            static_cast<Scalar>(height) / scale};
  }

  constexpr TSize operator/(const TSize& s) const {
    return {width / s.width, height / s.height};
  }

  constexpr bool operator==(const TSize& s) const {
    return s.width == width && s.height == height;
  }

  constexpr bool operator!=(const TSize& s) const {
    return s.width != width || s.height != height;
  }

  constexpr TSize operator+(const TSize& s) const {
    return {width + s.width, height + s.height};
  }

  constexpr TSize operator-(const TSize& s) const {
    return {width - s.width, height - s.height};
  }

  constexpr TSize Min(const TSize& o) const {
    return {
        std::min(width, o.width),
        std::min(height, o.height),
    };
  }

  constexpr TSize Max(const TSize& o) const {
    return {
        std::max(width, o.width),
        std::max(height, o.height),
    };
  }

  constexpr TSize Floor() const {
    return {std::floor(width), std::floor(height)};
  }

  constexpr TSize Ceil() const { return {std::ceil(width), std::ceil(height)}; }

  constexpr TSize Round() const {
    return {std::round(width), std::round(height)};
  }

  constexpr Type Area() const { return width * height; }

  constexpr bool IsPositive() const { return width > 0 && height > 0; }

  constexpr bool IsNegative() const { return width < 0 || height < 0; }

  constexpr bool IsZero() const { return width == 0 || height == 0; }

  constexpr bool IsEmpty() const { return IsNegative() || IsZero(); }

  template <class U>
  static constexpr TSize Ceil(const TSize<U>& other) {
    return TSize{static_cast<Type>(std::ceil(other.width)),
                 static_cast<Type>(std::ceil(other.height))};
  }

  constexpr size_t MipCount() const {
    constexpr size_t minimum_mip = 1u;
    if (!IsPositive()) {
      return minimum_mip;
    }
    size_t result = std::max(ceil(log2(width)), ceil(log2(height)));
    return std::max(result, minimum_mip);
  }
};

// RHS algebraic operations with arithmetic types.

template <class T, class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
constexpr TSize<T> operator*(U s, const TSize<T>& p) {
  return p * s;
}

template <class T, class U, class = std::enable_if_t<std::is_arithmetic_v<U>>>
constexpr TSize<T> operator/(U s, const TSize<T>& p) {
  return {static_cast<T>(s) / p.x, static_cast<T>(s) / p.y};
}

using Size = TSize<Scalar>;
using ISize = TSize<int64_t>;

static_assert(sizeof(Size) == 2 * sizeof(Scalar));

}  // namespace impeller

namespace std {

template <class T>
inline std::ostream& operator<<(std::ostream& out,
                                const impeller::TSize<T>& s) {
  out << "(" << s.width << ", " << s.height << ")";
  return out;
}

}  // namespace std

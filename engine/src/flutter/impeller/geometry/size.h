// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <limits>
#include <string>

namespace impeller {

struct Size {
  double width = 0.0;
  double height = 0.0;

  constexpr Size() {}

  constexpr Size(double width, double height) : width(width), height(height) {}

  static constexpr Size Infinite() {
    return Size{std::numeric_limits<double>::max(),
                std::numeric_limits<double>::max()};
  }

  /*
   *  Operator overloads
   */
  constexpr Size operator*(double scale) const {
    return {width * scale, height * scale};
  }

  constexpr bool operator==(const Size& s) const {
    return s.width == width && s.height == height;
  }

  constexpr bool operator!=(const Size& s) const {
    return s.width != width || s.height != height;
  }

  constexpr Size operator+(const Size& s) const {
    return {width + s.width, height + s.height};
  }

  constexpr Size operator-(const Size& s) const {
    return {width - s.width, height - s.height};
  }

  constexpr Size Union(const Size& o) const {
    return {
        std::max(width, o.width),
        std::max(height, o.height),
    };
  }

  constexpr Size Intersection(const Size& o) const {
    return {
        std::min(width, o.width),
        std::min(height, o.height),
    };
  }

  constexpr bool IsZero() const { return width * height == 0.0; }

  constexpr bool IsPositive() const { return width * height > 0.0; }

  constexpr bool IsEmpty() { return !IsPositive(); }

  std::string ToString() const;

  void FromString(const std::string& str);
};

}  // namespace impeller

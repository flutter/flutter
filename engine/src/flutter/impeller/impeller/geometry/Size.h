// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

namespace rl {
namespace geom {

struct Size {
  double width = 0.0;
  double height = 0.0;

  Size() {}

  Size(double width, double height) : width(width), height(height) {}

  /*
   *  Operator overloads
   */
  Size operator*(double scale) const { return {width * scale, height * scale}; }

  bool operator==(const Size& s) const {
    return s.width == width && s.height == height;
  }

  bool operator!=(const Size& s) const {
    return s.width != width || s.height != height;
  }

  Size operator+(const Size& s) const {
    return {width + s.width, height + s.height};
  }

  Size operator-(const Size& s) const {
    return {width - s.width, height - s.height};
  }

  Size Union(const Size& o) const {
    return {
        std::max(width, o.width),
        std::max(height, o.height),
    };
  }

  bool IsZero() const { return width * height == 0.0; }

  bool IsPositive() const { return width > 0.0 && height > 0.0; }

  std::string ToString() const;

  void FromString(const std::string& str);
};

}  // namespace geom
}  // namespace rl

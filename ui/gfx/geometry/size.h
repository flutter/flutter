// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_SIZE_H_
#define UI_GFX_GEOMETRY_SIZE_H_

#include <iosfwd>
#include <string>

#include "base/compiler_specific.h"
#include "ui/gfx/geometry/size_f.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

// A size has width and height values.
class GFX_EXPORT Size {
 public:
  Size() : width_(0), height_(0) {}
  Size(int width, int height)
      : width_(width < 0 ? 0 : width), height_(height < 0 ? 0 : height) {}
  ~Size() {}

  int width() const { return width_; }
  int height() const { return height_; }

  void set_width(int width) { width_ = width < 0 ? 0 : width; }
  void set_height(int height) { height_ = height < 0 ? 0 : height; }

  int GetArea() const;

  void SetSize(int width, int height) {
    set_width(width);
    set_height(height);
  }

  void Enlarge(int grow_width, int grow_height);

  void SetToMin(const Size& other);
  void SetToMax(const Size& other);

  bool IsEmpty() const { return !width() || !height(); }

  operator SizeF() const {
    return SizeF(width(), height());
  }

  std::string ToString() const;

 private:
  int width_;
  int height_;
};

inline bool operator==(const Size& lhs, const Size& rhs) {
  return lhs.width() == rhs.width() && lhs.height() == rhs.height();
}

inline bool operator!=(const Size& lhs, const Size& rhs) {
  return !(lhs == rhs);
}

// This is declared here for use in gtest-based unit tests but is defined in
// the gfx_test_support target. Depend on that to use this in your unit test.
// This should not be used in production code - call ToString() instead.
void PrintTo(const Size& size, ::std::ostream* os);

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_SIZE_H_

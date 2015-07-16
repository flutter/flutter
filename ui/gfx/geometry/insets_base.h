// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_INSETS_BASE_H_
#define UI_GFX_GEOMETRY_INSETS_BASE_H_

#include "ui/gfx/gfx_export.h"

namespace gfx {

// An insets represents the borders of a container (the space the container must
// leave at each of its edges).
template<typename Class, typename Type>
class GFX_EXPORT InsetsBase {
 public:
  Type top() const { return top_; }
  Type left() const { return left_; }
  Type bottom() const { return bottom_; }
  Type right() const { return right_; }

  // Returns the total width taken up by the insets, which is the sum of the
  // left and right insets.
  Type width() const { return left_ + right_; }

  // Returns the total height taken up by the insets, which is the sum of the
  // top and bottom insets.
  Type height() const { return top_ + bottom_; }

  // Returns true if the insets are empty.
  bool empty() const { return width() == 0 && height() == 0; }

  void Set(Type top, Type left, Type bottom, Type right) {
    top_ = top;
    left_ = left;
    bottom_ = bottom;
    right_ = right;
  }

  bool operator==(const Class& insets) const {
    return top_ == insets.top_ && left_ == insets.left_ &&
           bottom_ == insets.bottom_ && right_ == insets.right_;
  }

  bool operator!=(const Class& insets) const {
    return !(*this == insets);
  }

  void operator+=(const Class& insets) {
    top_ += insets.top_;
    left_ += insets.left_;
    bottom_ += insets.bottom_;
    right_ += insets.right_;
  }

  Class operator-() const {
    return Class(-top_, -left_, -bottom_, -right_);
  }

 protected:
  InsetsBase(Type top, Type left, Type bottom, Type right)
      : top_(top),
        left_(left),
        bottom_(bottom),
        right_(right) {}

  // Destructor is intentionally made non virtual and protected.
  // Do not make this public.
  ~InsetsBase() {}

 private:
  Type top_;
  Type left_;
  Type bottom_;
  Type right_;
};

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_INSETS_BASE_H_

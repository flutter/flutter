// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_INSETS_H_
#define UI_GFX_GEOMETRY_INSETS_H_

#include <string>

#include "build/build_config.h"
#include "ui/gfx/geometry/insets_base.h"
#include "ui/gfx/geometry/insets_f.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

// An integer version of gfx::Insets.
class GFX_EXPORT Insets : public InsetsBase<Insets, int> {
 public:
  Insets();
  Insets(int top, int left, int bottom, int right);

  ~Insets();

  Insets Scale(float scale) const {
    return Scale(scale, scale);
  }

  Insets Scale(float x_scale, float y_scale) const {
    return Insets(static_cast<int>(top() * y_scale),
                  static_cast<int>(left() * x_scale),
                  static_cast<int>(bottom() * y_scale),
                  static_cast<int>(right() * x_scale));
  }

  operator InsetsF() const {
    return InsetsF(top(), left(), bottom(), right());
  }

  // Returns a string representation of the insets.
  std::string ToString() const;
};

#if !defined(COMPILER_MSVC) && !defined(__native_client__)
extern template class InsetsBase<Insets, int>;
#endif

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_INSETS_H_

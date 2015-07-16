// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_INSETS_F_H_
#define UI_GFX_GEOMETRY_INSETS_F_H_

#include <string>

#include "build/build_config.h"
#include "ui/gfx/geometry/insets_base.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

// A floating versin of gfx::Insets.
class GFX_EXPORT InsetsF : public InsetsBase<InsetsF, float> {
 public:
  InsetsF();
  InsetsF(float top, float left, float bottom, float right);
  ~InsetsF();

  // Returns a string representation of the insets.
  std::string ToString() const;
};

#if !defined(COMPILER_MSVC) && !defined(__native_client__)
extern template class InsetsBase<InsetsF, float>;
#endif

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_INSETS_F_H_

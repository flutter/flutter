// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/base/comparable.h"
#include "impeller/geometry/rect.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A typeface, usually obtained from a font-file, on disk describes
///             the intrinsic properties of the font. Typefaces are rarely used
///             directly. Instead, font refer to typefaces along with any
///             modifications applied to its intrinsic properties.
///
class Typeface : public Comparable<Typeface> {
 public:
  Typeface();

  virtual ~Typeface();

  virtual bool IsValid() const = 0;

 private:
  Typeface(const Typeface&) = delete;

  Typeface& operator=(const Typeface&) = delete;
};

}  // namespace impeller

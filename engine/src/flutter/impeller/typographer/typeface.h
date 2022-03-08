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

  //----------------------------------------------------------------------------
  /// @brief      Get the union of the bounding boxes of all glyphs in the
  ///             typeface. This box is unit-scaled and conservatively large to
  ///             cover all glyphs.
  ///
  /// @return     The conservative unit-scaled bounding box.
  ///
  virtual Rect GetBoundingBox() const = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Typeface);
};

}  // namespace impeller

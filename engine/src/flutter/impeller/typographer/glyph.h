// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>
#include <functional>

#include "flutter/fml/macros.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      The glyph index in the typeface.
///
struct Glyph {
  uint16_t index = 0;

  Glyph(uint16_t p_index) : index(p_index) {}
};

}  // namespace impeller

template <>
struct std::hash<impeller::Glyph> {
  constexpr std::size_t operator()(const impeller::Glyph& g) const {
    return g.index;
  }
};

template <>
struct std::less<impeller::Glyph> {
  constexpr bool operator()(const impeller::Glyph& lhs,
                            const impeller::Glyph& rhs) const {
    return lhs.index < rhs.index;
  }
};

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>
#include <functional>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "impeller/geometry/rect.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      The glyph index in the typeface.
///
struct Glyph {
  enum class Type : uint8_t {
    kPath,
    kBitmap,
  };

  uint16_t index = 0;

  //------------------------------------------------------------------------------
  /// @brief  Whether the glyph is a path or a bitmap.
  ///
  Type type = Type::kPath;

  //------------------------------------------------------------------------------
  /// @brief  Visibility coverage of the glyph in text run space (relative to
  ///         the baseline, no scaling applied).
  ///
  Rect bounds;

  Glyph(uint16_t p_index, Type p_type, Rect p_bounds)
      : index(p_index), type(p_type), bounds(p_bounds) {}
};

// Many Glyph instances are instantiated, so care should be taken when
// increasing the size.
static_assert(sizeof(Glyph) == 20);

}  // namespace impeller

template <>
struct std::hash<impeller::Glyph> {
  constexpr std::size_t operator()(const impeller::Glyph& g) const {
    static_assert(sizeof(g.index) == 2);
    static_assert(sizeof(g.type) == 1);
    return (static_cast<size_t>(g.type) << 16) | g.index;
  }
};

template <>
struct std::equal_to<impeller::Glyph> {
  constexpr bool operator()(const impeller::Glyph& lhs,
                            const impeller::Glyph& rhs) const {
    return lhs.index == rhs.index && lhs.type == rhs.type;
  }
};

template <>
struct std::less<impeller::Glyph> {
  constexpr bool operator()(const impeller::Glyph& lhs,
                            const impeller::Glyph& rhs) const {
    return lhs.index < rhs.index;
  }
};

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/glyph.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A font along with a glyph in that font rendered at a particular
///             scale. Used in glyph atlases as keys.
///
struct FontGlyphPair {
  struct Hash;
  struct Equal;

  using Set = std::unordered_set<FontGlyphPair, Hash, Equal>;

  Font font;
  Glyph glyph;
  Scalar scale;

  struct Hash {
    std::size_t operator()(const FontGlyphPair& p) const {
      static_assert(sizeof(p.glyph.index) == 2);
      static_assert(sizeof(p.glyph.type) == 1);
      size_t index = p.glyph.index;
      size_t type = static_cast<size_t>(p.glyph.type);
      // By packaging multiple values in a single size_t the hash function is
      // more efficient without losing entropy.
      if (sizeof(size_t) == 8 && sizeof(Scalar) == 4) {
        const float* fScale = &p.scale;
        size_t nScale = *reinterpret_cast<const uint32_t*>(fScale);
        size_t index_type_scale = nScale << 32 | index << 16 | type;
        return fml::HashCombine(p.font.GetHash(), index_type_scale);
      }
      size_t index_type = index << 16 | type;
      return fml::HashCombine(p.font.GetHash(), index_type, p.scale);
    }
  };
  struct Equal {
    bool operator()(const FontGlyphPair& lhs, const FontGlyphPair& rhs) const {
      return lhs.font.IsEqual(rhs.font) && lhs.glyph.index == rhs.glyph.index &&
             lhs.glyph.type == rhs.glyph.type && lhs.scale == rhs.scale;
    }
  };
};

}  // namespace impeller

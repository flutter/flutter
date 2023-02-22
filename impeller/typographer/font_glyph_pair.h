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
/// @brief      A font along with a glyph in that font. Used in glyph atlases as
///             keys.
///
struct FontGlyphPair {
  struct Hash;
  struct Equal;

  using Set = std::unordered_set<FontGlyphPair, Hash, Equal>;
  using Vector = std::vector<FontGlyphPair>;

  Font font;
  Glyph glyph;

  struct Hash {
    std::size_t operator()(const FontGlyphPair& p) const {
      return fml::HashCombine(p.font.GetHash(), p.glyph.index, p.glyph.type);
    }
  };
  struct Equal {
    bool operator()(const FontGlyphPair& lhs, const FontGlyphPair& rhs) const {
      return lhs.font.IsEqual(rhs.font) && lhs.glyph.index == rhs.glyph.index &&
             lhs.glyph.type == rhs.glyph.type;
    }
  };
};

}  // namespace impeller

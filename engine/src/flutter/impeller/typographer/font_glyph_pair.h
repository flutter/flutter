// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_FONT_GLYPH_PAIR_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_FONT_GLYPH_PAIR_H_

#include <unordered_map>
#include <unordered_set>

#include "fml/hash_combine.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/glyph.h"

namespace impeller {

struct GlyphProperties {
  Color color = Color::Black();
  Scalar stroke_width = 0.0;
  Cap stroke_cap = Cap::kButt;
  Join stroke_join = Join::kMiter;
  Scalar stroke_miter = 4.0;
  bool stroke = false;
};

//------------------------------------------------------------------------------
/// @brief      A font and a scale.  Used as a key that represents a typeface
///             within a glyph atlas.
///
struct ScaledFont {
  Font font;
  Scalar scale;

  struct Hash {
    constexpr std::size_t operator()(const impeller::ScaledFont& sf) const {
      return fml::HashCombine(sf.font.GetHash(), sf.scale);
    }
  };

  struct Equal {
    constexpr bool operator()(const impeller::ScaledFont& lhs,
                              const impeller::ScaledFont& rhs) const {
      return lhs.font.IsEqual(rhs.font) && lhs.scale == rhs.scale;
    }
  };
};

//------------------------------------------------------------------------------
/// @brief      A glyph and its subpixel position.
///
struct SubpixelGlyph {
  Glyph glyph;
  Point subpixel_offset;
  std::optional<GlyphProperties> properties;

  SubpixelGlyph(Glyph p_glyph,
                Point p_subpixel_offset,
                std::optional<GlyphProperties> p_properties)
      : glyph(p_glyph),
        subpixel_offset(p_subpixel_offset),
        properties(p_properties) {}

  struct Hash {
    constexpr std::size_t operator()(const impeller::SubpixelGlyph& sg) const {
      if (!sg.properties.has_value()) {
        return fml::HashCombine(sg.glyph.index, sg.subpixel_offset.x,
                                sg.subpixel_offset.y);
      }
      return fml::HashCombine(
          sg.glyph.index, sg.subpixel_offset.x, sg.subpixel_offset.y,
          sg.properties->color.ToARGB(), sg.properties->stroke,
          sg.properties->stroke_cap, sg.properties->stroke_join,
          sg.properties->stroke_miter, sg.properties->stroke_width);
    }
  };

  struct Equal {
    constexpr bool operator()(const impeller::SubpixelGlyph& lhs,
                              const impeller::SubpixelGlyph& rhs) const {
      if (!lhs.properties.has_value() && !rhs.properties.has_value()) {
        return lhs.glyph.index == rhs.glyph.index &&
               lhs.glyph.type == rhs.glyph.type &&
               lhs.subpixel_offset == rhs.subpixel_offset;
      }
      return lhs.glyph.index == rhs.glyph.index &&
             lhs.glyph.type == rhs.glyph.type &&
             lhs.subpixel_offset == rhs.subpixel_offset &&
             lhs.properties.has_value() && rhs.properties.has_value() &&
             lhs.properties->color.ToARGB() == rhs.properties->color.ToARGB() &&
             lhs.properties->stroke == rhs.properties->stroke &&
             lhs.properties->stroke_cap == rhs.properties->stroke_cap &&
             lhs.properties->stroke_join == rhs.properties->stroke_join &&
             lhs.properties->stroke_miter == rhs.properties->stroke_miter &&
             lhs.properties->stroke_width == rhs.properties->stroke_width;
    }
  };
};

using FontGlyphMap =
    std::unordered_map<ScaledFont,
                       std::unordered_set<SubpixelGlyph,
                                          SubpixelGlyph::Hash,
                                          SubpixelGlyph::Equal>,
                       ScaledFont::Hash,
                       ScaledFont::Equal>;

//------------------------------------------------------------------------------
/// @brief      A font along with a glyph in that font rendered at a particular
///             scale and subpixel position.
///
struct FontGlyphPair {
  FontGlyphPair(const ScaledFont& sf, const SubpixelGlyph& g)
      : scaled_font(sf), glyph(g) {}
  const ScaledFont& scaled_font;
  const SubpixelGlyph& glyph;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_FONT_GLYPH_PAIR_H_

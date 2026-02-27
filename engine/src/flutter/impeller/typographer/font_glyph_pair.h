// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_FONT_GLYPH_PAIR_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_FONT_GLYPH_PAIR_H_

#include <optional>

#include "impeller/geometry/color.h"
#include "impeller/geometry/rational.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/stroke_parameters.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/glyph.h"

namespace impeller {

struct GlyphProperties {
  Color color = Color::Black();
  std::optional<StrokeParameters> stroke;

  struct Equal {
    inline bool operator()(const impeller::GlyphProperties& lhs,
                           const impeller::GlyphProperties& rhs) const {
      return lhs.color.ToARGB() == rhs.color.ToARGB() &&
             lhs.stroke == rhs.stroke;
    }
  };
};

//------------------------------------------------------------------------------
/// @brief      A font and a scale.  Used as a key that represents a typeface
///             within a glyph atlas.
///
struct ScaledFont {
  Font font;
  Rational scale;

  template <typename H>
  friend H AbslHashValue(H h, const ScaledFont& sf) {
    return H::combine(std::move(h), sf.font.GetHash(), sf.scale.GetHash());
  }

  struct Equal {
    inline bool operator()(const impeller::ScaledFont& lhs,
                           const impeller::ScaledFont& rhs) const {
      return lhs.font.IsEqual(rhs.font) && lhs.scale == rhs.scale;
    }
  };
};

/// All possible positions for a subpixel alignment.
/// The name is in the format kSubpixelXY where X and Y are numerators to 1/4
/// fractions in their respective directions.
enum SubpixelPosition : uint8_t {
  // Subpixel at {0, 0}.
  kSubpixel00 = 0x0,
  // Subpixel at {0.25, 0}.
  kSubpixel10 = 0x1,
  // Subpixel at {0.5, 0}.
  kSubpixel20 = 0x2,
  // Subpixel at {0.75, 0}.
  kSubpixel30 = 0x3,
  // Subpixel at {0, 0.25}.
  kSubpixel01 = kSubpixel10 << 2,
  // Subpixel at {0, 0.5}.
  kSubpixel02 = kSubpixel20 << 2,
  // Subpixel at {0, 0.75}.
  kSubpixel03 = kSubpixel30 << 2,
  kSubpixel11 = kSubpixel10 | kSubpixel01,
  kSubpixel12 = kSubpixel10 | kSubpixel02,
  kSubpixel13 = kSubpixel10 | kSubpixel03,
  kSubpixel21 = kSubpixel20 | kSubpixel01,
  kSubpixel22 = kSubpixel20 | kSubpixel02,
  kSubpixel23 = kSubpixel20 | kSubpixel03,
  kSubpixel31 = kSubpixel30 | kSubpixel01,
  kSubpixel32 = kSubpixel30 | kSubpixel02,
  kSubpixel33 = kSubpixel30 | kSubpixel03,
};

//------------------------------------------------------------------------------
/// @brief      A glyph and its subpixel position.
///
struct SubpixelGlyph {
  Glyph glyph;
  SubpixelPosition subpixel_offset;
  std::optional<GlyphProperties> properties;

  SubpixelGlyph(Glyph p_glyph,
                SubpixelPosition p_subpixel_offset,
                std::optional<GlyphProperties> p_properties)
      : glyph(p_glyph),
        subpixel_offset(p_subpixel_offset),
        properties(p_properties) {}

  template <typename H>
  friend H AbslHashValue(H h, const SubpixelGlyph& sg) {
    if (!sg.properties.has_value()) {
      return H::combine(std::move(h), sg.glyph.index, sg.subpixel_offset);
    }
    StrokeParameters stroke;
    bool has_stroke = sg.properties->stroke.has_value();
    if (has_stroke) {
      stroke = sg.properties->stroke.value();
    }
    return H::combine(std::move(h), sg.glyph.index, sg.subpixel_offset,
                      sg.properties->color.ToARGB(), has_stroke, stroke.cap,
                      stroke.join, stroke.miter_limit, stroke.width);
  }

  struct Equal {
    constexpr bool operator()(const impeller::SubpixelGlyph& lhs,
                              const impeller::SubpixelGlyph& rhs) const {
      // Check simple non-optionals first.
      if (lhs.glyph.index != rhs.glyph.index ||
          lhs.glyph.type != rhs.glyph.type ||
          lhs.subpixel_offset != rhs.subpixel_offset ||
          // Mixmatch properties.
          lhs.properties.has_value() != rhs.properties.has_value()) {
        return false;
      }
      if (lhs.properties.has_value()) {
        // Both have properties.
        return GlyphProperties::Equal{}(lhs.properties.value(),
                                        rhs.properties.value());
      }
      return true;
    }
  };
};

//------------------------------------------------------------------------------
/// @brief      A font along with a glyph in that font rendered at a particular
///             scale and subpixel position.
///
struct FontGlyphPair {
  FontGlyphPair(const ScaledFont& sf, const SubpixelGlyph& g)
      : scaled_font(sf), glyph(g) {}
  ScaledFont scaled_font;
  SubpixelGlyph glyph;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_FONT_GLYPH_PAIR_H_

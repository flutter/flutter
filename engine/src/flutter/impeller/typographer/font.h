// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/renderer/comparable.h"
#include "impeller/typographer/glyph.h"
#include "impeller/typographer/typeface.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Describes a typeface along with any modifications to its
///             intrinsic properties.
///
class Font : public Comparable<Font> {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Describes the modifications made to the intrinsic properties
  ///             of a typeface.
  ///
  ///             The coordinate system of a font has its origin at (0, 0) on
  ///             the baseline with an upper-left-origin coordinate system.
  ///
  struct Metrics {
    //--------------------------------------------------------------------------
    /// The point size of the font.
    ///
    Scalar point_size = 12.0f;
    //--------------------------------------------------------------------------
    /// The font ascent relative to the baseline. This is usually negative as
    /// moving upwards (ascending) in an upper-left-origin coordinate system
    /// yields smaller numbers.
    ///
    Scalar ascent = 0.0f;
    //--------------------------------------------------------------------------
    /// The font descent relative to the baseline. This is usually positive as
    /// moving downwards (descending) in an upper-left-origin coordinate system
    /// yields larger numbers.
    ///
    Scalar descent = 0.0f;

    constexpr bool operator==(const Metrics& o) const {
      return point_size == o.point_size && ascent == o.ascent &&
             descent == o.descent;
    }
  };

  Font(std::shared_ptr<Typeface> typeface, Metrics metrics);

  ~Font();

  bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @brief      The typeface whose intrinsic properties this font modifies.
  ///
  /// @return     The typeface.
  ///
  const std::shared_ptr<Typeface>& GetTypeface() const;

  //----------------------------------------------------------------------------
  /// @brief      A conservatively large scaled bounding box of all glyphs in
  ///             this font.
  ///
  /// @return     The scaled glyph size.
  ///
  std::optional<ISize> GetGlyphSize() const;

  const Metrics& GetMetrics() const;

  // |Comparable<Font>|
  std::size_t GetHash() const override;

  // |Comparable<Font>|
  bool IsEqual(const Font& other) const override;

 private:
  std::shared_ptr<Typeface> typeface_;
  Metrics metrics_ = {};
  bool is_valid_ = false;
};

}  // namespace impeller

template <>
struct std::hash<impeller::Font::Metrics> {
  constexpr std::size_t operator()(const impeller::Font::Metrics& m) const {
    return fml::HashCombine(m.point_size, m.ascent, m.descent);
  }
};

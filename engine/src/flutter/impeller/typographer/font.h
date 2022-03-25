// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/base/comparable.h"
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
    /// The scaling factor that should be used when rendering this font to an
    /// atlas. This should normally be set in accordance with the transformation
    /// matrix that will be used to position glyph geometry.
    ///
    Scalar scale = 1.0f;
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
    //--------------------------------------------------------------------------
    /// The minimum glyph extents relative to the origin. Typically negative in
    /// an upper-left-origin coordinate system.
    ///
    Point min_extent;
    //--------------------------------------------------------------------------
    /// The maximum glyph extents relative to the origin. Typically positive in
    /// an upper-left-origin coordinate system.
    ///
    Point max_extent;

    //--------------------------------------------------------------------------
    /// @brief      The union of the bounding boxes of all the glyphs.
    ///
    /// @return     The bounding box.
    ///
    constexpr Rect GetBoundingBox() const {
      return Rect::MakeLTRB(min_extent.x,  //
                            min_extent.y,  //
                            max_extent.x,  //
                            max_extent.y   //
      );
    }

    constexpr bool operator==(const Metrics& o) const {
      return scale == o.scale && point_size == o.point_size &&
             ascent == o.ascent && descent == o.descent &&
             min_extent == o.min_extent && max_extent == o.max_extent;
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
    return fml::HashCombine(m.scale, m.point_size, m.ascent, m.descent);
  }
};

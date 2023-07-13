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
    bool embolden = false;
    Scalar skewX = 0.0f;
    Scalar scaleX = 1.0f;

    constexpr bool operator==(const Metrics& o) const {
      return scale == o.scale && point_size == o.point_size &&
             embolden == o.embolden && skewX == o.skewX && scaleX == o.scaleX;
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
    return fml::HashCombine(m.scale, m.point_size);
  }
};

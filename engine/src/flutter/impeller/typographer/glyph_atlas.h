// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/typographer/font_glyph_pair.h"
#include "impeller/typographer/rectangle_packer.h"

namespace impeller {

class FontGlyphAtlas;

//------------------------------------------------------------------------------
/// @brief      A texture containing the bitmap representation of glyphs in
///             different fonts along with the ability to query the location of
///             specific font glyphs within the texture.
///
class GlyphAtlas {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Describes how the glyphs are represented in the texture.
  enum class Type {
    //--------------------------------------------------------------------------
    /// The glyphs are reprsented at their requested size using only an 8-bit
    /// alpha channel.
    ///
    kAlphaBitmap,

    //--------------------------------------------------------------------------
    /// The glyphs are reprsented at their requested size using N32 premul
    /// colors.
    ///
    kColorBitmap,
  };

  //----------------------------------------------------------------------------
  /// @brief      Create an empty glyph atlas.
  ///
  /// @param[in]  type  How the glyphs are represented in the texture.
  ///
  explicit GlyphAtlas(Type type);

  ~GlyphAtlas();

  bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @brief      Describes how the glyphs are represented in the texture.
  ///
  Type GetType() const;

  //----------------------------------------------------------------------------
  /// @brief      Set the texture for the glyph atlas.
  ///
  /// @param[in]  texture  The texture
  ///
  void SetTexture(std::shared_ptr<Texture> texture);

  //----------------------------------------------------------------------------
  /// @brief      Get the texture for the glyph atlas.
  ///
  /// @return     The texture.
  ///
  const std::shared_ptr<Texture>& GetTexture() const;

  //----------------------------------------------------------------------------
  /// @brief      Record the location of a specific font-glyph pair within the
  ///             atlas.
  ///
  /// @param[in]  pair  The font-glyph pair
  /// @param[in]  rect  The rectangle
  ///
  void AddTypefaceGlyphPosition(const FontGlyphPair& pair, Rect rect);

  //----------------------------------------------------------------------------
  /// @brief      Get the number of unique font-glyph pairs in this atlas.
  ///
  /// @return     The glyph count.
  ///
  size_t GetGlyphCount() const;

  //----------------------------------------------------------------------------
  /// @brief      Iterate of all the glyphs along with their locations in the
  ///             atlas.
  ///
  /// @param[in]  iterator  The iterator. Return `false` from the iterator to
  ///                       stop iterating.
  ///
  /// @return     The number of glyphs iterated over.
  ///
  size_t IterateGlyphs(
      const std::function<bool(const ScaledFont& scaled_font,
                               const Glyph& glyph,
                               const Rect& rect)>& iterator) const;

  //----------------------------------------------------------------------------
  /// @brief      Find the location of a specific font-glyph pair in the atlas.
  ///
  /// @param[in]  pair  The font-glyph pair
  ///
  /// @return     The location of the font-glyph pair in the atlas.
  ///             `std::nullopt` if the pair is not in the atlas.
  ///
  std::optional<Rect> FindFontGlyphBounds(const FontGlyphPair& pair) const;

  //----------------------------------------------------------------------------
  /// @brief      Obtain an interface for querying the location of glyphs in the
  ///             atlas for the given font and scale.  This provides a more
  ///             efficient way to look up a run of glyphs in the same font.
  ///
  /// @param[in]  font  The font
  /// @param[in]  scale The scale
  ///
  /// @return     A pointer to a FontGlyphAtlas, or nullptr if the font and
  ///             scale are not available in the atlas.  The pointer is only
  ///             valid for the lifetime of the GlyphAtlas.
  ///
  const FontGlyphAtlas* GetFontGlyphAtlas(const Font& font, Scalar scale) const;

 private:
  const Type type_;
  std::shared_ptr<Texture> texture_;

  std::unordered_map<ScaledFont, FontGlyphAtlas> font_atlas_map_;

  FML_DISALLOW_COPY_AND_ASSIGN(GlyphAtlas);
};

//------------------------------------------------------------------------------
/// @brief      A container for caching a glyph atlas across frames.
///
class GlyphAtlasContext {
 public:
  virtual ~GlyphAtlasContext();

  //----------------------------------------------------------------------------
  /// @brief      Retrieve the current glyph atlas.
  std::shared_ptr<GlyphAtlas> GetGlyphAtlas() const;

  //----------------------------------------------------------------------------
  /// @brief      Retrieve the size of the current glyph atlas.
  const ISize& GetAtlasSize() const;

  //----------------------------------------------------------------------------
  /// @brief      Retrieve the previous (if any) rect packer.
  std::shared_ptr<RectanglePacker> GetRectPacker() const;

  //----------------------------------------------------------------------------
  /// @brief      Update the context with a newly constructed glyph atlas.
  void UpdateGlyphAtlas(std::shared_ptr<GlyphAtlas> atlas, ISize size);

  void UpdateRectPacker(std::shared_ptr<RectanglePacker> rect_packer);

 protected:
  GlyphAtlasContext();

 private:
  std::shared_ptr<GlyphAtlas> atlas_;
  ISize atlas_size_;
  std::shared_ptr<RectanglePacker> rect_packer_;

  FML_DISALLOW_COPY_AND_ASSIGN(GlyphAtlasContext);
};

//------------------------------------------------------------------------------
/// @brief      An object that can look up glyph locations within the GlyphAtlas
///             for a particular typeface.
///
class FontGlyphAtlas {
 public:
  FontGlyphAtlas() = default;

  //----------------------------------------------------------------------------
  /// @brief      Find the location of a glyph in the atlas.
  ///
  /// @param[in]  glyph The glyph
  ///
  /// @return     The location of the glyph in the atlas.
  ///             `std::nullopt` if the glyph is not in the atlas.
  ///
  std::optional<Rect> FindGlyphBounds(const Glyph& glyph) const;

 private:
  friend class GlyphAtlas;
  std::unordered_map<Glyph, Rect> positions_;

  FML_DISALLOW_COPY_AND_ASSIGN(FontGlyphAtlas);
};

}  // namespace impeller

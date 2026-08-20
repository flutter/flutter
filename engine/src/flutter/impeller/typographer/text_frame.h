// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_

#include <cstdint>
#include <optional>

#include "flutter/display_list/geometry/dl_path.h"
#include "fml/status_or.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rational.h"
#include "impeller/typographer/glyph.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_run.h"

namespace impeller {

using PathCreator = std::function<fml::StatusOr<flutter::DlPath>()>;

//------------------------------------------------------------------------------
/// @brief      A single vector layer of a COLR/CPAL color glyph: an outline
///             plus the CPAL color it should be filled with.
struct ColorGlyphLayer {
  flutter::DlPath path;
  Color color;
  /// When true, fill with the current paint color instead of [color] (COLR
  /// palette index 0xFFFF = "text foreground color").
  bool use_foreground_color = false;
};

using ColorPathCreator = std::function<std::vector<ColorGlyphLayer>()>;

//------------------------------------------------------------------------------
/// @brief      Represents a collection of shaped text runs.
///
///             This object is typically the entrypoint in the Impeller type
///             rendering subsystem.
class TextFrame {
 public:
  TextFrame();

  TextFrame(std::vector<TextRun>& runs,
            Rect bounds,
            bool has_color,
            const PathCreator& path_creator = {},
            const ColorPathCreator& color_path_creator = {});

  ~TextFrame();

  static SubpixelPosition ComputeSubpixelPosition(
      const TextRun::GlyphPosition& glyph_position,
      AxisAlignment alignment,
      const Matrix& transform);

  static Rational RoundScaledFontSize(Scalar scale);
  static Rational RoundScaledFontSize(Rational scale);

  //----------------------------------------------------------------------------
  /// @brief      The conservative bounding box for this text frame.
  ///
  /// @return     The bounds rectangle. If there are no glyphs in this text
  ///             frame an empty Rectangle is returned instead.
  ///
  Rect GetBounds() const;

  //----------------------------------------------------------------------------
  /// @brief      The number of runs in this text frame.
  ///
  /// @return     The run count.
  ///
  size_t GetRunCount() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns a reference to all the text runs in this frame.
  ///
  /// @return     The runs in this frame.
  ///
  const std::vector<TextRun>& GetRuns() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns whether any glyph in any run in this TextFrame
  ///             is colored and so would be cached with color already
  ///             baked in to the colored glyph.
  ///
  ///             Non-bitmap/COLR fonts only store an alpha bitmap, but
  ///             COLR fonts can potentially use the paint color in the glyph
  ///             atlas, so the color the text is being rendered with must
  ///             be considered as part of the cache key.
  bool HasColor() const;

  //----------------------------------------------------------------------------
  /// @brief      The type of atlas this run should be place in.
  ///
  ///             This return value depends primarily on the HasColor
  ///             property.
  GlyphAtlas::Type GetAtlasType() const;

  /// @brief If this text frame contains a single glyph (such as for an Icon),
  ///        then return it, otherwise std::nullopt.
  std::optional<Glyph> AsSingleGlyph() const;

  /// @brief Return the font of the first glyph run.
  const Font& GetFont() const;

  fml::StatusOr<flutter::DlPath> GetPath() const;

  //----------------------------------------------------------------------------
  /// @brief      For a COLR/CPAL color text frame, the per-glyph color layer
  ///             outlines (see [ColorGlyphLayer]). Empty if this frame has no
  ///             color path data available (e.g. non-color text, or a color
  ///             format other than COLRv0).
  std::vector<ColorGlyphLayer> GetColorPaths() const;

  /// @brief Toggle the platform-specific contrast and gamma correction in the
  ///        fragment shader.
  ///
  ///        By default, this is true on Linux to compensate for FreeType
  ///        rasterization in linear space, and false elsewhere. Setting a
  ///        value overrides this default behavior.
  void SetEnableGammaCorrection(std::optional<bool> value) {
    enable_gamma_correction_ = value;
  }
  std::optional<bool> GetEnableGammaCorrection() const {
    return enable_gamma_correction_;
  }

 private:
  std::vector<TextRun> runs_;
  Rect bounds_;
  bool has_color_;
  const PathCreator path_creator_;
  const ColorPathCreator color_path_creator_;
  std::optional<bool> enable_gamma_correction_ = std::nullopt;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_

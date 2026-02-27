// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_

#include <cstdint>

#include "flutter/display_list/geometry/dl_path.h"
#include "fml/status_or.h"
#include "impeller/geometry/rational.h"
#include "impeller/typographer/glyph.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_run.h"

namespace impeller {

using PathCreator = std::function<fml::StatusOr<flutter::DlPath>()>;

//------------------------------------------------------------------------------
/// @brief      Represents a collection of shaped text runs.
///
///             This object is typically the entrypoint in the Impeller type
///             rendering subsystem.
///
/// A text frame should not be reused in multiple places within a single frame,
/// as internally it is used as a cache for various glyph properties.
class TextFrame {
 public:
  TextFrame();

  TextFrame(std::vector<TextRun>& runs,
            Rect bounds,
            bool has_color,
            const PathCreator& path_creator = {});

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
  ///             frame and empty Rectangle is returned instead.
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
  /// @brief      Returns the paint color this text frame was recorded with.
  ///
  ///             Non-bitmap/COLR fonts always use a black text color here, but
  ///             COLR fonts can potentially use the paint color in the glyph
  ///             atlas, so this color must be considered as part of the cache
  ///             key.
  bool HasColor() const;

  //----------------------------------------------------------------------------
  /// @brief      The type of atlas this run should be place in.
  GlyphAtlas::Type GetAtlasType() const;

  /// @brief If this text frame contains a single glyph (such as for an Icon),
  ///        then return it, otherwise std::nullopt.
  std::optional<Glyph> AsSingleGlyph() const;

  /// @brief Return the font of the first glyph run.
  const Font& GetFont() const;

  fml::StatusOr<flutter::DlPath> GetPath() const;

  Point GetOffset() const;

 private:
  std::vector<TextRun> runs_;
  Rect bounds_;
  bool has_color_;
  const PathCreator path_creator_;
};

struct RenderableText {
  const std::shared_ptr<TextFrame> text_frame;
  const Matrix origin_transform;
  const std::optional<GlyphProperties> properties;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_

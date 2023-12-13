// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_

#include "flutter/fml/macros.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_run.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Represents a collection of shaped text runs.
///
///             This object is typically the entrypoint in the Impeller type
///             rendering subsystem.
///
class TextFrame {
 public:
  TextFrame();

  TextFrame(std::vector<TextRun>& runs, Rect bounds, bool has_color);

  ~TextFrame();

  void CollectUniqueFontGlyphPairs(FontGlyphMap& glyph_map, Scalar scale) const;

  static Scalar RoundScaledFontSize(Scalar scale, Scalar point_size);

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
  /// @brief      Whether any of the glyphs of this run are potentially
  /// overlapping
  ///
  ///             It is always safe to return true from this method. Generally,
  ///             any large blobs of text should return true to avoid
  ///             computationally complex calculations. This information is used
  ///             to apply opacity peephole optimizations to text blobs.
  bool MaybeHasOverlapping() const;

  //----------------------------------------------------------------------------
  /// @brief      The type of atlas this run should be emplaced in.
  GlyphAtlas::Type GetAtlasType() const;

  TextFrame& operator=(TextFrame&& other) = default;

  TextFrame(const TextFrame& other) = default;

 private:
  std::vector<TextRun> runs_;
  Rect bounds_;
  bool has_color_ = false;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_

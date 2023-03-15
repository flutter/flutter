// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
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

  ~TextFrame();

  //----------------------------------------------------------------------------
  /// @brief      The conservative bounding box for this text frame.
  ///
  /// @return     The bounds rectangle. If there are no glyphs in this text
  ///             frame, std::nullopt is returned.
  ///
  std::optional<Rect> GetBounds() const;

  //----------------------------------------------------------------------------
  /// @brief      The number of runs in this text frame.
  ///
  /// @return     The run count.
  ///
  size_t GetRunCount() const;

  //----------------------------------------------------------------------------
  /// @brief      Adds a new text run to the text frame.
  ///
  /// @param[in]  run   The run
  ///
  /// @return     If the text run could be added to this frame.
  ///
  bool AddTextRun(const TextRun& run);

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
  /// @brief      Whether any run in this frame has color.
  bool HasColor() const;

 private:
  std::vector<TextRun> runs_;
  bool has_color_ = false;
};

}  // namespace impeller

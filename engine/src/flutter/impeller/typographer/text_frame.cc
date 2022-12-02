// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/text_frame.h"

namespace impeller {

TextFrame::TextFrame() = default;

TextFrame::~TextFrame() = default;

std::optional<Rect> TextFrame::GetBounds() const {
  std::optional<Rect> result;

  for (const auto& run : runs_) {
    for (const auto& glyph_position : run.GetGlyphPositions()) {
      Rect glyph_rect =
          Rect(glyph_position.position + glyph_position.glyph.bounds.origin,
               glyph_position.glyph.bounds.size);
      result = result.has_value() ? result->Union(glyph_rect) : glyph_rect;
    }
  }

  return result;
}

bool TextFrame::AddTextRun(const TextRun& run) {
  if (!run.IsValid()) {
    return false;
  }
  has_color_ |= run.HasColor();
  runs_.emplace_back(run);
  return true;
}

size_t TextFrame::GetRunCount() const {
  return runs_.size();
}

const std::vector<TextRun>& TextFrame::GetRuns() const {
  return runs_;
}

bool TextFrame::HasColor() const {
  return has_color_;
}

}  // namespace impeller

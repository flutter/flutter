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
    const auto glyph_bounds = run.GetFont().GetMetrics().GetBoundingBox();
    for (const auto& glyph_position : run.GetGlyphPositions()) {
      Rect glyph_rect = Rect(glyph_position.position + glyph_bounds.origin,
                             glyph_bounds.size);
      result = result.has_value() ? result->Union(glyph_rect) : glyph_rect;
    }
  }

  return result;
}

bool TextFrame::AddTextRun(TextRun run) {
  if (!run.IsValid()) {
    return false;
  }
  runs_.emplace_back(std::move(run));
  return true;
}

size_t TextFrame::GetRunCount() const {
  return runs_.size();
}

const std::vector<TextRun>& TextFrame::GetRuns() const {
  return runs_;
}

}  // namespace impeller

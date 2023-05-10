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

GlyphAtlas::Type TextFrame::GetAtlasType() const {
  return has_color_ ? GlyphAtlas::Type::kColorBitmap
                    : GlyphAtlas::Type::kAlphaBitmap;
}

bool TextFrame::MaybeHasOverlapping() const {
  if (runs_.size() > 1) {
    return true;
  }
  auto glyph_positions = runs_[0].GetGlyphPositions();
  if (glyph_positions.size() > 10) {
    return true;
  }
  if (glyph_positions.size() == 1) {
    return false;
  }
  // To avoid quadradic behavior the overlapping is checked against an
  // accumulated bounds rect. This gives faster but less precise information
  // on text runs.
  auto first_position = glyph_positions[0];
  auto overlapping_rect =
      Rect(first_position.position + first_position.glyph.bounds.origin,
           first_position.glyph.bounds.size);
  for (auto i = 1u; i < glyph_positions.size(); i++) {
    auto glyph_position = glyph_positions[i];
    auto glyph_rect =
        Rect(glyph_position.position + glyph_position.glyph.bounds.origin,
             glyph_position.glyph.bounds.size);
    auto intersection = glyph_rect.Intersection(overlapping_rect);
    if (intersection.has_value()) {
      return true;
    }
    overlapping_rect = overlapping_rect.Union(glyph_rect);
  }
  return false;
}

}  // namespace impeller

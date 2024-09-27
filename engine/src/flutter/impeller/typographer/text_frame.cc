// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/text_frame.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/font_glyph_pair.h"

namespace impeller {

TextFrame::TextFrame() = default;

TextFrame::TextFrame(std::vector<TextRun>& runs, Rect bounds, bool has_color)
    : runs_(std::move(runs)), bounds_(bounds), has_color_(has_color) {}

TextFrame::~TextFrame() = default;

Rect TextFrame::GetBounds() const {
  return bounds_;
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

bool TextFrame::HasColor() const {
  return has_color_;
}

// static
Scalar TextFrame::RoundScaledFontSize(Scalar scale, Scalar point_size) {
  // An arbitrarily chosen maximum text scale to ensure that regardless of the
  // CTM, a glyph will fit in the atlas. If we clamp significantly, this may
  // reduce fidelity but is preferable to the alternative of failing to render.
  constexpr Scalar kMaximumTextScale = 48;
  Scalar result = std::round(scale * 100) / 100;
  return std::clamp(result, 0.0f, kMaximumTextScale);
}

static constexpr Scalar ComputeFractionalPosition(Scalar value) {
  value += 0.125;
  value = (value - floorf(value));
  if (value < 0.25) {
    return 0;
  }
  if (value < 0.5) {
    return 0.25;
  }
  if (value < 0.75) {
    return 0.5;
  }
  return 0.75;
}

// Compute subpixel position for glyphs based on X position and provided
// max basis length (scale).
// This logic is based on the SkPackedGlyphID logic in SkGlyph.h
// static
Point TextFrame::ComputeSubpixelPosition(
    const TextRun::GlyphPosition& glyph_position,
    AxisAlignment alignment,
    Point offset,
    Scalar scale) {
  Point pos = glyph_position.position + offset;
  switch (alignment) {
    case AxisAlignment::kNone:
      return Point(0, 0);
    case AxisAlignment::kX:
      return Point(ComputeFractionalPosition(pos.x * scale), 0);
    case AxisAlignment::kY:
      return Point(0, ComputeFractionalPosition(pos.y * scale));
    case AxisAlignment::kAll:
      return Point(ComputeFractionalPosition(pos.x * scale),
                   ComputeFractionalPosition(pos.y * scale));
  }
}

void TextFrame::CollectUniqueFontGlyphPairs(
    FontGlyphMap& glyph_map,
    Scalar scale,
    Point offset,
    const GlyphProperties& properties) const {
  std::optional<GlyphProperties> lookup =
      (properties.stroke || HasColor())
          ? std::optional<GlyphProperties>(properties)
          : std::nullopt;
  for (const TextRun& run : GetRuns()) {
    const Font& font = run.GetFont();
    auto rounded_scale =
        RoundScaledFontSize(scale, font.GetMetrics().point_size);
    auto& set = glyph_map[ScaledFont{font, rounded_scale}];
    for (const TextRun::GlyphPosition& glyph_position :
         run.GetGlyphPositions()) {
      Point subpixel = ComputeSubpixelPosition(
          glyph_position, font.GetAxisAlignment(), offset, scale);
      set.emplace(glyph_position.glyph, subpixel, lookup);
    }
  }
}

}  // namespace impeller

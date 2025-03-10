// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/text_frame.h"
#include "impeller/geometry/scalar.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/font_glyph_pair.h"

namespace impeller {

namespace {
static bool TextPropertiesEquals(const std::optional<GlyphProperties>& a,
                                 const std::optional<GlyphProperties>& b) {
  if (!a.has_value() && !b.has_value()) {
    return true;
  }
  if (a.has_value() && b.has_value()) {
    return GlyphProperties::Equal{}(a.value(), b.value());
  }
  return false;
}
}  // namespace

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

namespace {
constexpr uint32_t kDenominator = 200;
constexpr Rational kMaximumTextScale(48 * kDenominator, kDenominator);
}  // namespace

// static
Rational TextFrame::RoundScaledFontSize(Scalar scale) {
  // An arbitrarily chosen maximum text scale to ensure that regardless of the
  // CTM, a glyph will fit in the atlas. If we clamp significantly, this may
  // reduce fidelity but is preferable to the alternative of failing to render.
  Rational result = Rational(std::round(scale * kDenominator), kDenominator);
  return std::clamp(result, Rational(0, kDenominator), kMaximumTextScale);
}

Rational TextFrame::RoundScaledFontSize(Rational scale) {
  Rational result = Rational(
      std::round((scale.GetNumerator() * static_cast<Scalar>(kDenominator))) /
          scale.GetDenominator(),
      kDenominator);
  return std::clamp(result, Rational(0, kDenominator), kMaximumTextScale);
}

static constexpr SubpixelPosition ComputeFractionalPosition(Scalar value) {
  value += 0.125;
  value = (value - floorf(value));
  if (value < 0.25) {
    return SubpixelPosition::kSubpixel00;
  }
  if (value < 0.5) {
    return SubpixelPosition::kSubpixel01;
  }
  if (value < 0.75) {
    return SubpixelPosition::kSubpixel02;
  }
  return SubpixelPosition::kSubpixel03;
}

// Compute subpixel position for glyphs based on X position and provided
// max basis length (scale).
// This logic is based on the SkPackedGlyphID logic in SkGlyph.h
// static
SubpixelPosition TextFrame::ComputeSubpixelPosition(
    const TextRun::GlyphPosition& glyph_position,
    AxisAlignment alignment,
    const Matrix& transform) {
  Point pos = transform * glyph_position.position;
  switch (alignment) {
    case AxisAlignment::kNone:
      return SubpixelPosition::kSubpixel00;
    case AxisAlignment::kX:
      return ComputeFractionalPosition(pos.x);
    case AxisAlignment::kY:
      return static_cast<SubpixelPosition>(ComputeFractionalPosition(pos.y)
                                           << 2);
    case AxisAlignment::kAll:
      return static_cast<SubpixelPosition>(
          ComputeFractionalPosition(pos.x) |
          (ComputeFractionalPosition(pos.y) << 2));
  }
}

void TextFrame::SetPerFrameData(Rational scale,
                                Point offset,
                                const Matrix& transform,
                                std::optional<GlyphProperties> properties) {
  if (!transform_.Equals(transform) || scale_ != scale ||
      !ScalarNearlyEqual(offset_.x, offset.x) ||
      !ScalarNearlyEqual(offset_.y, offset.y) ||
      !TextPropertiesEquals(properties_, properties)) {
    bound_values_.clear();
  }
  scale_ = scale;
  offset_ = offset;
  properties_ = properties;
  transform_ = transform;
}

Rational TextFrame::GetScale() const {
  return scale_;
}

Point TextFrame::GetOffset() const {
  return offset_;
}

std::optional<GlyphProperties> TextFrame::GetProperties() const {
  return properties_;
}

void TextFrame::AppendFrameBounds(const FrameBounds& frame_bounds) {
  bound_values_.push_back(frame_bounds);
}

void TextFrame::ClearFrameBounds() {
  bound_values_.clear();
}

bool TextFrame::IsFrameComplete() const {
  size_t run_size = 0;
  for (const auto& x : runs_) {
    run_size += x.GetGlyphCount();
  }
  return bound_values_.size() == run_size;
}

const FrameBounds& TextFrame::GetFrameBounds(size_t index) const {
  FML_DCHECK(index < bound_values_.size());
  return bound_values_[index];
}

std::pair<size_t, intptr_t> TextFrame::GetAtlasGenerationAndID() const {
  return std::make_pair(generation_, atlas_id_);
}

void TextFrame::SetAtlasGeneration(size_t value, intptr_t atlas_id) {
  generation_ = value;
  atlas_id_ = atlas_id;
}

}  // namespace impeller

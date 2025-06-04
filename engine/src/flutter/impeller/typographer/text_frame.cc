// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/text_frame.h"
#include "flutter/display_list/geometry/dl_path.h"  // nogncheck
#include "fml/status.h"
#include "impeller/geometry/scalar.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/font_glyph_pair.h"

namespace impeller {

TextFrame::TextFrame() = default;

TextFrame::TextFrame(std::vector<TextRun>& runs,
                     Rect bounds,
                     bool has_color,
                     const PathCreator& path_creator)
    : runs_(std::move(runs)),
      bounds_(bounds),
      has_color_(has_color),
      path_creator_(path_creator) {}

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
constexpr int32_t kMaximumTextScale = 48;
constexpr Rational kZero(0, kDenominator);
}  // namespace

// static
Rational TextFrame::RoundScaledFontSize(Scalar scale) {
  if (scale > kMaximumTextScale) {
    return Rational(kMaximumTextScale * kDenominator, kDenominator);
  }
  // An arbitrarily chosen maximum text scale to ensure that regardless of the
  // CTM, a glyph will fit in the atlas. If we clamp significantly, this may
  // reduce fidelity but is preferable to the alternative of failing to render.
<<<<<<< HEAD
  constexpr Scalar kMaximumTextScale = 48;
  Scalar result = std::round(scale * 200) / 200;
  return std::clamp(result, 0.0f, kMaximumTextScale);
=======
  Rational result = Rational(std::round(scale * kDenominator), kDenominator);
  return result < kZero ? kZero : result;
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
}

Rational TextFrame::RoundScaledFontSize(Rational scale) {
  Rational result = Rational(
      std::round((scale.GetNumerator() * static_cast<Scalar>(kDenominator))) /
          scale.GetDenominator(),
      kDenominator);
  return std::clamp(result, Rational(0, kDenominator),
                    Rational(kMaximumTextScale * kDenominator, kDenominator));
}

static constexpr SubpixelPosition ComputeFractionalPosition(Scalar value) {
  value += 0.125;
  value = (value - floorf(value));
  if (value < 0.25) {
    return SubpixelPosition::kSubpixel00;
  }
  if (value < 0.5) {
    return SubpixelPosition::kSubpixel10;
  }
  if (value < 0.75) {
    return SubpixelPosition::kSubpixel20;
  }
  return SubpixelPosition::kSubpixel30;
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
<<<<<<< HEAD
      return Point(ComputeFractionalPosition(pos.x), 0);
    case AxisAlignment::kY:
      return Point(0, ComputeFractionalPosition(pos.y));
    case AxisAlignment::kAll:
      return Point(ComputeFractionalPosition(pos.x),
                   ComputeFractionalPosition(pos.y));
=======
      return ComputeFractionalPosition(pos.x);
    case AxisAlignment::kY:
      return static_cast<SubpixelPosition>(ComputeFractionalPosition(pos.y)
                                           << 2);
    case AxisAlignment::kAll:
      return static_cast<SubpixelPosition>(
          ComputeFractionalPosition(pos.x) |
          (ComputeFractionalPosition(pos.y) << 2));
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
  }
}

Matrix TextFrame::GetOffsetTransform() const {
  return transform_ * Matrix::MakeTranslation(offset_);
}

<<<<<<< HEAD
void TextFrame::SetPerFrameData(Scalar scale,
=======
void TextFrame::SetPerFrameData(Rational scale,
>>>>>>> b25305a8832cfc6ba632a7f87ad455e319dccce8
                                Point offset,
                                const Matrix& transform,
                                std::optional<GlyphProperties> properties) {
  bound_values_.clear();
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

fml::StatusOr<flutter::DlPath> TextFrame::GetPath() const {
  if (path_creator_) {
    return path_creator_();
  }
  return fml::Status(fml::StatusCode::kCancelled, "no path creator specified.");
}

bool TextFrame::IsFrameComplete() const {
  size_t run_size = 0;
  for (const auto& x : runs_) {
    run_size += x.GetGlyphCount();
  }
  return bound_values_.size() == run_size;
}

const Font& TextFrame::GetFont() const {
  return runs_[0].GetFont();
}

std::optional<Glyph> TextFrame::AsSingleGlyph() const {
  if (runs_.size() == 1 && runs_[0].GetGlyphCount() == 1) {
    return runs_[0].GetGlyphPositions()[0].glyph;
  }
  return std::nullopt;
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

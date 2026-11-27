// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/text_frame.h"
#include "flutter/display_list/geometry/dl_path.h"  // nogncheck
#include "impeller/geometry/scalar.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/font_glyph_pair.h"
#include "third_party/abseil-cpp/absl/status/status.h"

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
  Rational result = Rational(std::round(scale * kDenominator), kDenominator);
  return result < kZero ? kZero : result;
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

// Only translation along an axis that no run uses can be omitted from the
// membership key. Integer translation on an active axis is kept exact because
// changing it can affect the floating-point subpixel bucket at a boundary.
Matrix TextFrame::GetGlyphCacheTransform(const Matrix& transform) const {
  bool uses_x = false;
  bool uses_y = false;
  for (const auto& run : GetRuns()) {
    switch (run.GetFont().GetAxisAlignment()) {
      case AxisAlignment::kNone:
        break;
      case AxisAlignment::kX:
        uses_x = true;
        break;
      case AxisAlignment::kY:
        uses_y = true;
        break;
      case AxisAlignment::kAll:
        uses_x = true;
        uses_y = true;
        break;
    }
  }
  Matrix result = transform;
  if (!uses_x) {
    result.m[12] = 0;
  }
  if (!uses_y) {
    result.m[13] = 0;
  }
  return result;
}

absl::StatusOr<flutter::DlPath> TextFrame::GetPath() const {
  if (path_creator_) {
    return path_creator_();
  }
  return absl::Status(absl::StatusCode::kCancelled,
                      "no path creator specified.");
}

}  // namespace impeller

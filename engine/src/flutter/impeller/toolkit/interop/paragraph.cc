// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/paragraph.h"

namespace impeller::interop {

Paragraph::Paragraph(std::unique_ptr<txt::Paragraph> paragraph)
    : paragraph_(std::move(paragraph)) {}

Paragraph::~Paragraph() = default;

Scalar Paragraph::GetMaxWidth() const {
  return paragraph_->GetMaxWidth();
}

Scalar Paragraph::GetHeight() const {
  return paragraph_->GetHeight();
}

Scalar Paragraph::GetLongestLineWidth() const {
  return paragraph_->GetLongestLine();
}

Scalar Paragraph::GetMinIntrinsicWidth() const {
  return paragraph_->GetMinIntrinsicWidth();
}

Scalar Paragraph::GetMaxIntrinsicWidth() const {
  return paragraph_->GetMaxIntrinsicWidth();
}

Scalar Paragraph::GetIdeographicBaseline() const {
  return paragraph_->GetIdeographicBaseline();
}

Scalar Paragraph::GetAlphabeticBaseline() const {
  return paragraph_->GetAlphabeticBaseline();
}

uint32_t Paragraph::GetLineCount() const {
  return paragraph_->GetNumberOfLines();
}

const std::unique_ptr<txt::Paragraph>& Paragraph::GetHandle() const {
  return paragraph_;
}

ScopedObject<LineMetrics> Paragraph::GetLineMetrics() const {
  // Line metrics are expensive to calculate and the recommendation is that
  // the metric after each layout must be cached. But interop::Paragraphs are
  // immutable. So do the caching on behalf of the caller.
  if (lazy_line_metrics_) {
    return lazy_line_metrics_;
  }
  lazy_line_metrics_ = Create<LineMetrics>(paragraph_->GetLineMetrics());
  return lazy_line_metrics_;
}

ScopedObject<GlyphInfo> Paragraph::GetGlyphInfoAtCodeUnitIndex(
    size_t code_unit_index) const {
  skia::textlayout::Paragraph::GlyphInfo info = {};
  if (paragraph_->GetGlyphInfoAt(code_unit_index, &info)) {
    return Create<GlyphInfo>(info);
  }
  return nullptr;
}

ScopedObject<GlyphInfo> Paragraph::GetClosestGlyphInfoAtParagraphCoordinates(
    double x,
    double y) const {
  skia::textlayout::Paragraph::GlyphInfo info = {};
  if (paragraph_->GetClosestGlyphInfoAtCoordinate(x, y, &info)) {
    return Create<GlyphInfo>(info);
  }
  return nullptr;
}

ImpellerRange Paragraph::GetWordBoundary(size_t code_unit_index) const {
  const auto range = paragraph_->GetWordBoundary(code_unit_index);
  return ImpellerRange{range.start, range.end};
}

}  // namespace impeller::interop

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_SKIA_PARAGRAPH_SKIA_H_
#define FLUTTER_TXT_SRC_SKIA_PARAGRAPH_SKIA_H_

#include <optional>

#include "txt/paragraph.h"

#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

namespace txt {

// Implementation of Paragraph based on Skia's text layout module.
class ParagraphSkia : public Paragraph {
 public:
  ParagraphSkia(std::unique_ptr<skia::textlayout::Paragraph> paragraph,
                std::vector<flutter::DlPaint>&& dl_paints,
                bool impeller_enabled,
                TextDirection text_direction = TextDirection::ltr);

  virtual ~ParagraphSkia() = default;

  double GetMaxWidth() override;

  double GetHeight() override;

  double GetLongestLine() override;

  double GetMinIntrinsicWidth() override;

  double GetMaxIntrinsicWidth() override;

  double GetAlphabeticBaseline() override;

  double GetIdeographicBaseline() override;

  std::vector<LineMetrics>& GetLineMetrics() override;

  bool GetLineMetricsAt(
      int lineNumber,
      skia::textlayout::LineMetrics* lineMetrics) const override;

  size_t GetNumberOfLines() const override;

  int GetLineNumberAt(size_t utf16Offset) const override;

  bool DidExceedMaxLines() override;

  void Layout(double width) override;

  void LayoutWithShrinkLock(double width, bool lock_width) override;

  double ComputeScrollFadeOpacity(double current_width,
                                  double current_height,
                                  double fade_end_fraction = 0.5) override;

  bool Paint(flutter::DisplayListBuilder* builder, double x, double y) override;

  bool PaintMasked(
      flutter::DisplayListBuilder* builder,
      double x,
      double y,
      double clip_left,
      double clip_top,
      double clip_right,
      double clip_bottom,
      double opacity = 1.0,
      bool fade_horizontal = false,
      OverflowPosition overflow_position = OverflowPosition::kEnd) override;

  std::vector<TextBox> GetRectsForRange(
      size_t start,
      size_t end,
      RectHeightStyle rect_height_style,
      RectWidthStyle rect_width_style) override;

  std::vector<TextBox> GetRectsForPlaceholders() override;

  PositionWithAffinity GetGlyphPositionAtCoordinate(double dx,
                                                    double dy) override;

  bool GetGlyphInfoAt(
      unsigned offset,
      skia::textlayout::Paragraph::GlyphInfo* glyphInfo) const override;

  bool GetClosestGlyphInfoAtCoordinate(
      double dx,
      double dy,
      skia::textlayout::Paragraph::GlyphInfo* glyphInfo) const override;

  Range<size_t> GetWordBoundary(size_t offset) override;

 private:
  void LayoutInternal(double width);

  TextStyle SkiaToTxt(const skia::textlayout::TextStyle& skia);

  std::unique_ptr<skia::textlayout::Paragraph> paragraph_;
  std::vector<flutter::DlPaint> dl_paints_;
  std::optional<std::vector<LineMetrics>> line_metrics_;
  std::vector<TextStyle> line_metrics_styles_;
  const bool impeller_enabled_;
  const TextDirection text_direction_;
  double locked_max_width_ = 0.0;
  double locked_max_height_ = 0.0;
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_SKIA_PARAGRAPH_SKIA_H_

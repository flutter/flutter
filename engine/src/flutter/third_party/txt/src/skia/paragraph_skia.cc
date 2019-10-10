/*
 * Copyright 2019 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "paragraph_skia.h"

#include <algorithm>

namespace txt {

namespace skt = skia::textlayout;

namespace {

// Convert SkFontStyle::Weight values (ranging from 100-900) to txt::FontWeight
// values (ranging from 0-8).
txt::FontWeight GetTxtFontWeight(int font_weight) {
  int txt_weight = (font_weight - 100) / 100;
  txt_weight = std::clamp(txt_weight, static_cast<int>(txt::FontWeight::w100),
                          static_cast<int>(txt::FontWeight::w900));
  return static_cast<txt::FontWeight>(txt_weight);
}

txt::FontStyle GetTxtFontStyle(SkFontStyle::Slant font_slant) {
  return font_slant == SkFontStyle::Slant::kUpright_Slant
             ? txt::FontStyle::normal
             : txt::FontStyle::italic;
}

TextStyle SkiaToTxt(const skt::TextStyle& skia) {
  TextStyle txt;

  txt.color = skia.getColor();
  txt.decoration = static_cast<TextDecoration>(skia.getDecorationType());
  txt.decoration_color = skia.getDecorationColor();
  txt.decoration_style =
      static_cast<TextDecorationStyle>(skia.getDecorationStyle());
  txt.decoration_thickness_multiplier =
      SkScalarToDouble(skia.getDecorationThicknessMultiplier());
  txt.font_weight = GetTxtFontWeight(skia.getFontStyle().weight());
  txt.font_style = GetTxtFontStyle(skia.getFontStyle().slant());

  txt.text_baseline = static_cast<TextBaseline>(skia.getTextBaseline());

  for (const SkString& font_family : skia.getFontFamilies()) {
    txt.font_families.emplace_back(font_family.c_str());
  }

  txt.font_size = SkScalarToDouble(skia.getFontSize());
  txt.letter_spacing = SkScalarToDouble(skia.getLetterSpacing());
  txt.word_spacing = SkScalarToDouble(skia.getWordSpacing());
  txt.height = SkScalarToDouble(skia.getHeight());

  txt.locale = skia.getLocale().c_str();
  if (skia.hasBackground()) {
    txt.background = skia.getBackground();
  }
  if (skia.hasForeground()) {
    txt.foreground = skia.getForeground();
  }

  txt.text_shadows.clear();
  for (const skt::TextShadow& skia_shadow : skia.getShadows()) {
    txt::TextShadow shadow;
    shadow.offset = skia_shadow.fOffset;
    shadow.blur_radius = skia_shadow.fBlurRadius;
    shadow.color = skia_shadow.fColor;
    txt.text_shadows.emplace_back(shadow);
  }

  return txt;
}

}  // anonymous namespace

ParagraphSkia::ParagraphSkia(std::unique_ptr<skt::Paragraph> paragraph)
    : paragraph_(std::move(paragraph)) {}

double ParagraphSkia::GetMaxWidth() {
  return SkScalarToDouble(paragraph_->getMaxWidth());
}

double ParagraphSkia::GetHeight() {
  return SkScalarToDouble(paragraph_->getHeight());
}

double ParagraphSkia::GetLongestLine() {
  return SkScalarToDouble(paragraph_->getLongestLine());
}

std::vector<LineMetrics>& ParagraphSkia::GetLineMetrics() {
  if (!line_metrics_) {
    std::vector<skt::LineMetrics> metrics;
    paragraph_->getLineMetrics(metrics);

    line_metrics_.emplace();
    for (const skt::LineMetrics& skm : metrics) {
      LineMetrics& txtm = line_metrics_->emplace_back(
          skm.fStartIndex, skm.fEndIndex, skm.fEndExcludingWhitespaces,
          skm.fEndIncludingNewline, skm.fHardBreak);
      txtm.ascent = skm.fAscent;
      txtm.descent = skm.fDescent;
      txtm.unscaled_ascent = skm.fUnscaledAscent;
      txtm.height = skm.fHeight;
      txtm.width = skm.fWidth;
      txtm.left = skm.fLeft;
      txtm.baseline = skm.fBaseline;
      txtm.line_number = skm.fLineNumber;

      for (const auto& sk_iter : skm.fLineMetrics) {
        const skt::StyleMetrics& sk_style_metrics = sk_iter.second;
        line_metrics_styles_.push_back(SkiaToTxt(*sk_style_metrics.text_style));
        txtm.run_metrics.emplace(
            std::piecewise_construct, std::forward_as_tuple(sk_iter.first),
            std::forward_as_tuple(&line_metrics_styles_.back(),
                                  sk_style_metrics.font_metrics));
      }
    }
  }

  return line_metrics_.value();
}

double ParagraphSkia::GetMinIntrinsicWidth() {
  return SkScalarToDouble(paragraph_->getMinIntrinsicWidth());
}

double ParagraphSkia::GetMaxIntrinsicWidth() {
  return SkScalarToDouble(paragraph_->getMaxIntrinsicWidth());
}

double ParagraphSkia::GetAlphabeticBaseline() {
  return SkScalarToDouble(paragraph_->getAlphabeticBaseline());
}

double ParagraphSkia::GetIdeographicBaseline() {
  return SkScalarToDouble(paragraph_->getIdeographicBaseline());
}

bool ParagraphSkia::DidExceedMaxLines() {
  return paragraph_->didExceedMaxLines();
}

void ParagraphSkia::Layout(double width) {
  paragraph_->layout(width);
}

void ParagraphSkia::Paint(SkCanvas* canvas, double x, double y) {
  paragraph_->paint(canvas, x, y);
}

std::vector<Paragraph::TextBox> ParagraphSkia::GetRectsForRange(
    size_t start,
    size_t end,
    RectHeightStyle rect_height_style,
    RectWidthStyle rect_width_style) {
  std::vector<skt::TextBox> skia_boxes = paragraph_->getRectsForRange(
      start, end, static_cast<skt::RectHeightStyle>(rect_height_style),
      static_cast<skt::RectWidthStyle>(rect_width_style));

  std::vector<Paragraph::TextBox> boxes;
  for (const skt::TextBox skia_box : skia_boxes) {
    boxes.emplace_back(skia_box.rect,
                       static_cast<TextDirection>(skia_box.direction));
  }

  return boxes;
}

std::vector<Paragraph::TextBox> ParagraphSkia::GetRectsForPlaceholders() {
  std::vector<skt::TextBox> skia_boxes = paragraph_->getRectsForPlaceholders();

  std::vector<Paragraph::TextBox> boxes;
  for (const skt::TextBox skia_box : skia_boxes) {
    boxes.emplace_back(skia_box.rect,
                       static_cast<TextDirection>(skia_box.direction));
  }

  return boxes;
}

Paragraph::PositionWithAffinity ParagraphSkia::GetGlyphPositionAtCoordinate(
    double dx,
    double dy) {
  skt::PositionWithAffinity skia_pos =
      paragraph_->getGlyphPositionAtCoordinate(dx, dy);

  return ParagraphSkia::PositionWithAffinity(
      skia_pos.position, static_cast<Affinity>(skia_pos.affinity));
}

Paragraph::Range<size_t> ParagraphSkia::GetWordBoundary(size_t offset) {
  skt::SkRange<size_t> range = paragraph_->getWordBoundary(offset);
  return Paragraph::Range<size_t>(range.start, range.end);
}

}  // namespace txt

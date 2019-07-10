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

namespace txt {

namespace skt = skia::textlayout;

ParagraphSkia::ParagraphSkia(std::unique_ptr<skt::Paragraph> paragraph)
    : paragraph_(std::move(paragraph)) {}

double ParagraphSkia::GetMaxWidth() {
  return paragraph_->getMaxWidth();
}

double ParagraphSkia::GetHeight() {
  return paragraph_->getHeight();
}

double ParagraphSkia::GetLongestLine() {
  // TODO: implement
  return 0;
}

double ParagraphSkia::GetMinIntrinsicWidth() {
  return paragraph_->getMinIntrinsicWidth();
}

double ParagraphSkia::GetMaxIntrinsicWidth() {
  return paragraph_->getMaxIntrinsicWidth();
}

double ParagraphSkia::GetAlphabeticBaseline() {
  return paragraph_->getAlphabeticBaseline();
}

double ParagraphSkia::GetIdeographicBaseline() {
  return paragraph_->getIdeographicBaseline();
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
  // TODO: implement
  return {};
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

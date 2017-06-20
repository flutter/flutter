/*
 * Copyright 2017 Google Inc.
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

#include "lib/txt/src/paragraph.h"

#include <algorithm>
#include <limits>
#include <tuple>
#include <utility>
#include <vector>

#include <minikin/Layout.h>
#include "lib/ftl/logging.h"
#include "lib/txt/src/font_collection.h"
#include "lib/txt/src/font_skia.h"
#include "minikin/LineBreaker.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace txt {
namespace {

const sk_sp<SkTypeface>& GetTypefaceForGlyph(const minikin::Layout& layout,
                                             size_t index) {
  const FontSkia* font = static_cast<const FontSkia*>(layout.getFont(index));
  return font->GetSkTypeface();
}

// Return the number of glyphs until the typeface changes.
size_t GetBlobLength(const minikin::Layout& layout, size_t blob_start) {
  const size_t glyph_count = layout.nGlyphs();
  const sk_sp<SkTypeface>& typeface = GetTypefaceForGlyph(layout, blob_start);
  for (size_t blob_end = blob_start + 1; blob_end < glyph_count; ++blob_end) {
    if (GetTypefaceForGlyph(layout, blob_end).get() != typeface.get())
      return blob_end - blob_start;
  }
  return glyph_count - blob_start;
}

int GetWeight(const FontWeight weight) {
  switch (weight) {
    case FontWeight::w100:
      return 1;
    case FontWeight::w200:
      return 2;
    case FontWeight::w300:
      return 3;
    case FontWeight::w400:  // Normal.
      return 4;
    case FontWeight::w500:
      return 5;
    case FontWeight::w600:
      return 6;
    case FontWeight::w700:  // Bold.
      return 7;
    case FontWeight::w800:
      return 8;
    case FontWeight::w900:
      return 9;
  }
}

int GetWeight(const TextStyle& style) {
  return GetWeight(style.font_weight);
}

bool GetItalic(const TextStyle& style) {
  switch (style.font_style) {
    case FontStyle::normal:
      return false;
    case FontStyle::italic:
      return true;
  }
}

void GetFontAndMinikinPaint(const TextStyle& style,
                            minikin::FontStyle* font,
                            minikin::MinikinPaint* paint) {
  *font = minikin::FontStyle(GetWeight(style), GetItalic(style));
  paint->size = style.font_size;
  paint->letterSpacing = style.letter_spacing;
  paint->wordSpacing = style.word_spacing;  // Likely not working yet.
  // TODO(abarth):  word_spacing.
}

void GetPaint(const TextStyle& style, SkPaint* paint) {
  paint->setTextSize(style.font_size);
  paint->setFakeBoldText(style.fake_bold);
}

}  // namespace

Paragraph::Paragraph() = default;

Paragraph::~Paragraph() = default;

void Paragraph::SetText(std::vector<uint16_t> text, StyledRuns runs) {
  text_ = std::move(text);
  runs_ = std::move(runs);

  breaker_.setLocale(icu::Locale(), nullptr);
  breaker_.resize(text_.size());
  memcpy(breaker_.buffer(), text_.data(), text_.size() * sizeof(text_[0]));
  breaker_.setText();
}

void Paragraph::AddRunsToLineBreaker(const std::string& rootdir) {
  minikin::FontStyle font;
  minikin::MinikinPaint paint;
  for (size_t i = 0; i < runs_.size(); ++i) {
    auto run = runs_.GetRun(i);
    auto collection =
        FontCollection::GetFontCollection(rootdir)
            .GetMinikinFontCollectionForFamily(run.style.font_family);
    GetFontAndMinikinPaint(run.style, &font, &paint);
    breaker_.addStyleRun(&paint, collection, font, run.start, run.end, false);
  }
}

void Paragraph::Layout(double width,
                       const std::string& rootdir,
                       const double x_offset,
                       const double y_offset) {
  breaker_.setLineWidths(0.0f, 0, width);
  width_ = width;
  AddRunsToLineBreaker(rootdir);
  size_t breaks_count = breaker_.computeBreaks();
  const int* breaks = breaker_.getBreaks();

  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);

  minikin::FontStyle font;
  minikin::MinikinPaint minikin_paint;

  SkTextBlobBuilder builder;

  // Reset member variables so Layout still works when called more than once
  max_intrinsic_width_ = 0.0f;
  lines_ = 0;

  minikin::Layout layout;
  SkScalar x = x_offset;
  y_ = y_offset;
  size_t break_index = 0;
  double letter_spacing_offset = 0.0f;
  double word_spacing_offset = 0.0f;
  double max_line_spacing = 0.0f;

  for (size_t run_index = 0; run_index < runs_.size(); ++run_index) {
    auto run = runs_.GetRun(run_index);
    auto collection =
        FontCollection::GetFontCollection(rootdir)
            .GetMinikinFontCollectionForFamily(run.style.font_family);
    GetFontAndMinikinPaint(run.style, &font, &minikin_paint);
    GetPaint(run.style, &paint);

    // Subtract inital offset to avoid big gap at start of run.
    letter_spacing_offset -= run.style.letter_spacing;

    size_t layout_start = run.start;

    // Layout until the end of the run or too many lines.
    while (layout_start < run.end && lines_ < paragraph_style_.max_lines) {
      const size_t next_break = (break_index > breaks_count - 1)
                                    ? std::numeric_limits<size_t>::max()
                                    : breaks[break_index];
      const size_t layout_end = std::min(run.end, next_break);

      int bidiFlags = 0;
      layout.doLayout(text_.data(), layout_start, layout_end - layout_start,
                      text_.size(), bidiFlags, font, minikin_paint, collection);

      const size_t glyph_count = layout.nGlyphs();
      size_t blob_start = 0;
      // Each word/blob.
      while (blob_start < glyph_count) {
        const size_t blob_length = GetBlobLength(layout, blob_start);
        // TODO(abarth): Precompute when we can use allocRunPosH.
        paint.setTypeface(GetTypefaceForGlyph(layout, blob_start));

        auto buffer = builder.allocRunPos(paint, blob_length);

        letter_spacing_offset += run.style.letter_spacing;

        // Each Glyph/Letter.
        for (size_t blob_index = 0; blob_index < blob_length; ++blob_index) {
          const size_t glyph_index = blob_start + blob_index;
          buffer.glyphs[blob_index] = layout.getGlyphId(glyph_index);
          const size_t pos_index = 2 * blob_index;
          buffer.pos[pos_index] = layout.getX(glyph_index) +
                                  letter_spacing_offset + word_spacing_offset;
          letter_spacing_offset += run.style.letter_spacing;
          buffer.pos[pos_index + 1] = layout.getY(glyph_index);
        }
        blob_start += blob_length;

        // Subtract letter offset to avoid big gap at end of run. This my be
        // removed depending on the specifications for letter spacing.
        // letter_spacing_offset -= run.style.letter_spacing;

        word_spacing_offset += run.style.word_spacing;

        max_intrinsic_width_ +=
            layout.getX(blob_start - 1) + letter_spacing_offset;
      }

      // Subtract word offset to avoid big gap at end of run. This my be
      // removed depending on the specificatins for word spacing.
      word_spacing_offset -= run.style.word_spacing;
      // TODO(abarth): We could keep the same SkTextBlobBuilder as long as the
      // color stayed the same.
      // TODO(garyq): Ensure that the typeface does not change throughout a
      // run.
      SkPaint::FontMetrics metrics;
      paint.getFontMetrics(&metrics);
      records_.push_back(PaintRecord{run.style.color, SkPoint::Make(x, y_),
                                     builder.make(), metrics});
      decorations_.push_back(
          std::make_tuple(run.style.decoration, run.style.decoration_color,
                          run.style.decoration_style, run.style.font_weight));
      if (max_line_spacing < -metrics.fAscent * run.style.height)
        max_line_spacing = -metrics.fAscent * run.style.height;

      if (layout_end == next_break) {
        y_ += max_line_spacing;

        max_line_spacing = 0.0f;
        x = 0.0f;
        letter_spacing_offset = 0.0f;
        word_spacing_offset = 0.0f;
        // TODO(abarth): Use the line height, which is something like the max
        // font_size for runs in this line times the paragraph's line height.
        break_index += 1;
        lines_++;
      } else {
        x += layout.getAdvance();
      }

      layout_start = layout_end;
    }
  }
}

const ParagraphStyle& Paragraph::GetParagraphStyle() const {
  return paragraph_style_;
}

double Paragraph::GetAlphabeticBaseline() const {
  // TODO(garyq): Implement.
  return FLT_MAX;
}

double Paragraph::GetIdeographicBaseline() const {
  // TODO(garyq): Implement.
  return FLT_MAX;
}

double Paragraph::GetMaxIntrinsicWidth() const {
  return max_intrinsic_width_;
}

double Paragraph::GetMinIntrinsicWidth() const {
  // TODO(garyq): Implement.
  return min_intrinsic_width_;
}

double Paragraph::GetHeight() const {
  return y_;
}

void Paragraph::SetParagraphStyle(const ParagraphStyle& style) {
  paragraph_style_ = style;
}

void Paragraph::Paint(SkCanvas* canvas, double x, double y) {
  int i = 0;
  for (const auto& record : records_) {
    SkPaint paint;
    paint.setColor(record.color());
    const SkPoint& offset = record.offset();
    canvas->drawTextBlob(record.text(), x + offset.x(), y + offset.y(), paint);
    PaintDecorations(canvas, x + offset.x(), y + offset.y(), decorations_[i],
                     record.metrics(), record.text());
    i++;
  }
}

void Paragraph::PaintDecorations(
    SkCanvas* canvas,
    double x,
    double y,
    std::tuple<TextDecoration, SkColor, TextDecorationStyle, FontWeight>
        decoration,
    SkPaint::FontMetrics metrics,
    SkTextBlob* blob) {
  if (std::get<0>(decoration) != TextDecoration::kNone) {
    SkPaint paint;
    paint.setStyle(SkPaint::kStroke_Style);
    paint.setColor(std::get<1>(decoration));
    paint.setAntiAlias(true);

    double width = blob->bounds().fRight + blob->bounds().fLeft;

    if (std::get<0>(decoration) & 0x1) {
      paint.setStrokeWidth(metrics.fUnderlineThickness);
      canvas->drawLine(x, y + metrics.fUnderlineThickness, x + width,
                       y + metrics.fUnderlineThickness, paint);
    }
    if (std::get<0>(decoration) & 0x2) {
      paint.setStrokeWidth(metrics.fUnderlineThickness);
      canvas->drawLine(x, y + metrics.fAscent, x + width, y + metrics.fAscent,
                       paint);
    }
    if (std::get<0>(decoration) & 0x4) {
      paint.setStrokeWidth(metrics.fUnderlineThickness);
      canvas->drawLine(x, y - metrics.fCapHeight / 2.5, x + width,
                       y - metrics.fCapHeight / 2.5, paint);
    }
  }
}

int Paragraph::GetLineCount() const {
  return lines_;
}

bool Paragraph::DidExceedMaxLines() const {
  if (lines_ > paragraph_style_.max_lines)
    return true;
  return false;
}

}  // namespace txt

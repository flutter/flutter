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
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkDiscretePathEffect.h"

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
  width_ = width;

  breaker_.setLineWidths(0.0f, 0, width);
  AddRunsToLineBreaker(rootdir);
  size_t breaks_count = breaker_.computeBreaks();
  const int* breaks = breaker_.getBreaks();

  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);

  minikin::FontStyle font;
  minikin::MinikinPaint minikin_paint;
  minikin::Layout layout;

  SkTextBlobBuilder builder;

  // Reset member variables so Layout still works when called more than once
  max_intrinsic_width_ = 0.0f;
  lines_ = 0;

  SkScalar x = x_offset;
  SkScalar y = y_offset;
  size_t break_index = 0;
  double letter_spacing_offset = 0.0f;
  double word_spacing_offset = 0.0f;
  double max_line_spacing = 0.0f;
  double max_descent = 0.0f;
  double prev_max_descent = 0.0f;
  double line_width = 0.0f;
  std::vector<SkScalar> x_queue;

  auto flush = [this, &x_queue, &y]() -> void {
    for (size_t i = 0; i < x_queue.size(); ++i) {
      records_[records_.size() - (x_queue.size() - i)].SetOffset(
          SkPoint::Make(x_queue[i], y));
    }
    x_queue.clear();
  };

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
          buffer.pos[pos_index + 1] = layout.getY(glyph_index);

          letter_spacing_offset += run.style.letter_spacing;
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
      records_.push_back(
          PaintRecord{run.style, builder.make(), metrics, lines_});
      line_width +=
          std::abs(records_[records_.size() - 1].text()->bounds().fRight +
                   records_[records_.size() - 1].text()->bounds().fLeft);

      // Must adjust each line to the largest text in the line, so cannot
      // directly push the offset property of PaintRecord until line is
      // finished.
      x_queue.push_back(x);

      if (max_line_spacing <
          (-metrics.fAscent + metrics.fLeading) * run.style.height) {
        max_line_spacing = lines_ == 0 ? -metrics.fAscent * run.style.height
                                       : (-metrics.fAscent + metrics.fLeading) *
                                             run.style.height;
        // Record the alphabetic_baseline_:
        if (lines_ == 0) {
          alphabetic_baseline_ = -metrics.fAscent * run.style.height;
          // TODO(garyq): Properly implement ideographic_baseline_.
          ideographic_baseline_ =
              ((metrics.fDescent / 2) - metrics.fAscent) * run.style.height;
        }
      }
      if (max_descent < metrics.fDescent * run.style.height)
        max_descent = metrics.fDescent * run.style.height;

      if (layout_end == next_break) {
        y += max_line_spacing + prev_max_descent;
        prev_max_descent = max_descent;
        line_widths_.push_back(line_width);
        flush();

        max_line_spacing = 0.0f;
        max_descent = 0.0f;
        x = 0.0f;
        letter_spacing_offset = 0.0f;
        word_spacing_offset = 0.0f;
        line_width = 0.0f;
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
  y += max_line_spacing;
  flush();
  if (line_width != 0)
    line_widths_.push_back(line_width);

  height_ = y + max_descent;
}

const ParagraphStyle& Paragraph::GetParagraphStyle() const {
  return paragraph_style_;
}

double Paragraph::GetAlphabeticBaseline() const {
  return alphabetic_baseline_;
}

double Paragraph::GetIdeographicBaseline() const {
  // TODO(garyq): Implement.
  return ideographic_baseline_;
}

double Paragraph::GetMaxIntrinsicWidth() const {
  return max_intrinsic_width_;
}

double Paragraph::GetMinIntrinsicWidth() const {
  // TODO(garyq): Implement.
  return min_intrinsic_width_;
}

double Paragraph::GetHeight() const {
  return height_;
}

void Paragraph::SetParagraphStyle(const ParagraphStyle& style) {
  paragraph_style_ = style;
}

void Paragraph::Paint(SkCanvas* canvas, double x, double y) {
  for (const auto& record : records_) {
    SkPaint paint;
    paint.setColor(record.style().color);
    SkPoint offset = record.offset();
    // TODO(garyq): Fix alignment for paragraphs with multiple styles per line.
    switch (paragraph_style_.text_align) {
      case TextAlign::left:
        break;
      case TextAlign::right: {
        offset.offset(width_ - line_widths_[record.line()], 0);
        break;
      }
      case TextAlign::center: {
        offset.offset((width_ - line_widths_[record.line()]) / 2, 0);
        break;
      }
      case TextAlign::justify: {
        // TODO(garyq): implement justify.
        break;
      }
    }
    canvas->drawTextBlob(record.text(), x + offset.x(), y + offset.y(), paint);
    PaintDecorations(canvas, x + offset.x(), y + offset.y(), record.style(),
                     record.metrics(), record.text());
  }
}

void Paragraph::PaintDecorations(SkCanvas* canvas,
                                 double x,
                                 double y,
                                 TextStyle style,
                                 SkPaint::FontMetrics metrics,
                                 SkTextBlob* blob) {
  if (style.decoration != TextDecoration::kNone) {
    SkPaint paint;
    paint.setStyle(SkPaint::kStroke_Style);
    paint.setColor(style.decoration_color);
    paint.setAntiAlias(true);

    // This is set to 2 for the double line style
    int decoration_count = 1;

    switch (style.decoration_style) {
      case TextDecorationStyle::kSolid:
        break;
      case TextDecorationStyle::kDouble: {
        decoration_count = 2;
        break;
      }
      case TextDecorationStyle::kDotted: {
        const SkScalar intervals[] = {3.0f, 5.0f, 3.0f, 5.0f};
        size_t count = sizeof(intervals) / sizeof(intervals[0]);
        paint.setPathEffect(SkPathEffect::MakeCompose(
            SkDashPathEffect::Make(intervals, count, 0.0f),
            SkDiscretePathEffect::Make(0, 0)));
        break;
      }
      case TextDecorationStyle::kDashed: {
        const SkScalar intervals[] = {10.0f, 5.0f, 10.0f, 5.0f};
        size_t count = sizeof(intervals) / sizeof(intervals[0]);
        paint.setPathEffect(SkPathEffect::MakeCompose(
            SkDashPathEffect::Make(intervals, count, 0.0f),
            SkDiscretePathEffect::Make(0, 0)));
        break;
      }
      case TextDecorationStyle::kWavy: {
        // TODO(garyq): Wave currently does a random wave instead of an ordered
        // wave.
        const SkScalar intervals[] = {1};
        size_t count = sizeof(intervals) / sizeof(intervals[0]);
        paint.setPathEffect(SkPathEffect::MakeCompose(
            SkDashPathEffect::Make(intervals, count, 0.0f),
            SkDiscretePathEffect::Make(metrics.fAvgCharWidth / 10.0f,
                                       metrics.fAvgCharWidth / 10.0f)));
        break;
      }
    }

    double width = blob->bounds().fRight + blob->bounds().fLeft;

    for (int i = 0; i < decoration_count; i++) {
      double y_offset = i * metrics.fUnderlineThickness * 3.0f;
      if (style.decoration & 0x1) {
        paint.setStrokeWidth(metrics.fUnderlineThickness);
        canvas->drawLine(x, y + metrics.fUnderlineThickness + y_offset,
                         x + width, y + metrics.fUnderlineThickness + y_offset,
                         paint);
      }
      if (style.decoration & 0x2) {
        paint.setStrokeWidth(metrics.fUnderlineThickness);
        canvas->drawLine(x, y + metrics.fAscent + y_offset, x + width,
                         y + metrics.fAscent + y_offset, paint);
      }
      if (style.decoration & 0x4) {
        paint.setStrokeWidth(metrics.fUnderlineThickness);
        canvas->drawLine(x, y - metrics.fXHeight / 2 + y_offset, x + width,
                         y - metrics.fXHeight / 2 + y_offset, paint);
      }
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

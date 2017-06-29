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
#include "lib/txt/libs/minikin/LayoutUtils.h"
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
  paint->wordSpacing = style.word_spacing;
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
  needs_layout_ = true;
  if (text.size() == 0)
    return;
  text_ = std::move(text);
  runs_ = std::move(runs);

  breaker_.setLocale(icu::Locale(), nullptr);
  breaker_.resize(text_.size());
  memcpy(breaker_.buffer(), text_.data(), text_.size() * sizeof(text_[0]));
  breaker_.setText();
}

void Paragraph::AddRunsToLineBreaker(
    std::shared_ptr<minikin::FontCollection>& collection,
    std::string& prev_font_family) {
  minikin::FontStyle font;
  minikin::MinikinPaint paint;
  for (size_t i = 0; i < runs_.size(); ++i) {
    auto run = runs_.GetRun(i);
    // Only obtain new font family if the font has changed between runs.
    if (run.style.font_family != prev_font_family || collection == nullptr) {
      collection = font_collection_->GetMinikinFontCollectionForFamily(
          run.style.font_family);
    }
    prev_font_family = run.style.font_family;
    GetFontAndMinikinPaint(run.style, &font, &paint);
    breaker_.addStyleRun(&paint, collection, font, run.start, run.end, false);
  }
}

void Paragraph::Layout(double width, bool force) {
  // Do not allow calling layout multiple times without changing anything.
  if (!needs_layout_ && !force)
    return;
  needs_layout_ = false;

  width_ = width;

  std::shared_ptr<minikin::FontCollection> collection = nullptr;
  std::string prev_font_family = "";

  breaker_.setLineWidths(0.0f, 0, width_);
  AddRunsToLineBreaker(collection, prev_font_family);
  breaker_.setJustified(paragraph_style_.text_align == TextAlign::justify);
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

  SkScalar x = 0.0f;
  SkScalar y = 0.0f;
  size_t break_index = 0;
  double letter_spacing_offset = 0.0f;
  double max_line_spacing = 0.0f;
  double max_descent = 0.0f;
  double prev_max_descent = 0.0f;
  double line_width = 0.0f;
  std::vector<SkScalar> x_queue;
  size_t character_index = 0;

  auto postprocess_line = [this, &x_queue, &y]() -> void {
    size_t record_index = 0;
    for (size_t i = 0; i < x_queue.size(); ++i) {
      record_index = records_.size() - (x_queue.size() - i);
      records_[record_index].SetOffset(SkPoint::Make(x_queue[i], y));
      // TODO(garyq): Fix alignment for paragraphs with multiple styles per
      // line.
      switch (paragraph_style_.text_align) {
        case TextAlign::left:
          break;
        case TextAlign::right: {
          records_[record_index].SetOffset(SkPoint::Make(
              records_[record_index].offset().x() + width_ -
                  breaker_.getWidths()[records_[record_index].line()],
              records_[record_index].offset().y()));
          break;
        }
        case TextAlign::center: {
          records_[record_index].SetOffset(SkPoint::Make(
              records_[record_index].offset().x() +
                  (width_ -
                   breaker_.getWidths()[records_[record_index].line()]) /
                      2,
              records_[record_index].offset().y()));
          break;
        }
        case TextAlign::justify: {
          break;
        }
      }
    }
    x_queue.clear();
  };
  for (size_t run_index = 0; run_index < runs_.size(); ++run_index) {
    auto run = runs_.GetRun(run_index);

    // Only obtain new font family if the font has changed between runs.
    if (run.style.font_family != prev_font_family || collection == nullptr) {
      collection = font_collection_->GetMinikinFontCollectionForFamily(
          run.style.font_family);
    }
    prev_font_family = run.style.font_family;
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
      // Each blob.
      std::vector<const SkTextBlobBuilder::RunBuffer*> buffers;
      std::vector<size_t> buffer_sizes;
      int word_count = 0;
      while (blob_start < glyph_count) {
        const size_t blob_length = GetBlobLength(layout, blob_start);
        buffer_sizes.push_back(blob_length);
        // TODO(abarth): Precompute when we can use allocRunPosH.
        paint.setTypeface(GetTypefaceForGlyph(layout, blob_start));

        buffers.push_back(&builder.allocRunPos(paint, blob_length));

        letter_spacing_offset += run.style.letter_spacing;

        // Each Glyph/Letter.
        bool whitespace_ended = true;
        for (size_t blob_index = 0; blob_index < blob_length; ++blob_index) {
          const size_t glyph_index = blob_start + blob_index;
          buffers.back()->glyphs[blob_index] = layout.getGlyphId(glyph_index);
          // Check if the current Glyph is a whitespace and handle multiple
          // whitespaces in a row.
          if (minikin::isWordSpace(text_[character_index])) {
            // Only increment word_count if it is the first in a series of
            // whitespaces.
            if (whitespace_ended)
              ++word_count;
            whitespace_ended = false;
          } else {
            whitespace_ended = true;
          }
          ++character_index;
          const size_t pos_index = 2 * blob_index;

          buffers.back()->pos[pos_index] =
              layout.getX(glyph_index) + letter_spacing_offset;
          buffers.back()->pos[pos_index + 1] = layout.getY(glyph_index);

          letter_spacing_offset += run.style.letter_spacing;
        }
        blob_start += blob_length;

        // Subtract letter offset to avoid big gap at end of run. This my be
        // removed depending on the specifications for letter spacing.
        // letter_spacing_offset -= run.style.letter_spacing;

        max_intrinsic_width_ +=
            layout.getX(blob_start - 1) + letter_spacing_offset;
      }

      // TODO(abarth): We could keep the same SkTextBlobBuilder as long as the
      // color stayed the same.
      // TODO(garyq): Ensure that the typeface does not change throughout a
      // run.
      SkPaint::FontMetrics metrics;
      paint.getFontMetrics(&metrics);
      // Apply additional word spacing if the text is justified.
      if (paragraph_style_.text_align == TextAlign::justify &&
          buffer_sizes.size() > 0) {
        JustifyLine(buffers, buffer_sizes, word_count, character_index);
      }
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
        max_line_spacing = lines_ == 0 ? metrics.fCapHeight * run.style.height
                                       : (-metrics.fAscent + metrics.fLeading) *
                                             run.style.height;
        // Record the alphabetic_baseline_:
        if (lines_ == 0) {
          alphabetic_baseline_ = metrics.fCapHeight * run.style.height;
          // TODO(garyq): Properly implement ideographic_baseline_.
          ideographic_baseline_ =
              (metrics.fDescent + metrics.fCapHeight) * run.style.height;
        }
      }
      if (max_descent < metrics.fDescent * run.style.height)
        max_descent = metrics.fDescent * run.style.height;

      if (layout_end == next_break) {
        y += max_line_spacing + prev_max_descent;
        prev_max_descent = max_descent;
        line_widths_.push_back(line_width);
        postprocess_line();

        max_line_spacing = 0.0f;
        max_descent = 0.0f;
        x = 0.0f;
        letter_spacing_offset = 0.0f;
        word_count = 0;
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
  postprocess_line();
  if (line_width != 0)
    line_widths_.push_back(line_width);

  height_ = y + max_descent;
}

// Amends the buffers to incorporate justification.
void Paragraph::JustifyLine(
    std::vector<const SkTextBlobBuilder::RunBuffer*>& buffers,
    std::vector<size_t>& buffer_sizes,
    int word_count,
    size_t character_index) {
  // TODO(garyq): Add letter_spacing_offset back in. It is Temporarily
  // removed.
  double justify_spacing =
      (width_ - breaker_.getWidths()[lines_]) / (word_count - 1);
  word_count = 0;
  // Set up index to properly access text_ because minikin::isWordSpace()
  // takes uint_16 instead of GlyphIDs.
  size_t line_character_index = character_index;
  for (size_t i = 0; i < buffers.size(); ++i)
    line_character_index -= buffer_sizes[i];
  bool whitespace_ended = true;
  for (size_t i = 0; i < buffers.size(); ++i) {
    for (size_t glyph_index = 0; glyph_index < buffer_sizes[i]; ++glyph_index) {
      // Check if the current Glyph is a whitespace and handle multiple
      // whitespaces in a row.
      if (minikin::isWordSpace(text_[line_character_index])) {
        // Only increment word_count and add justification spacing to
        // whitespace if it is the first in a series of whitespaces.
        if (whitespace_ended) {
          ++word_count;
          buffers[i]->pos[glyph_index * 2] += justify_spacing * word_count;
        }
        whitespace_ended = false;
      } else {
        // Add justification spacing for all non-whitespace glyphs.
        buffers[i]->pos[glyph_index * 2] += justify_spacing * word_count;
        whitespace_ended = true;
      }
      ++line_character_index;
    }
  }
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
  needs_layout_ = true;
  paragraph_style_ = style;
}

void Paragraph::SetFontCollection(FontCollection* font_collection) {
  font_collection_ = font_collection;
}

void Paragraph::Paint(SkCanvas* canvas, double x, double y) {
  for (const auto& record : records_) {
    SkPaint paint;
    paint.setColor(record.style().color);
    SkPoint offset = record.offset();
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

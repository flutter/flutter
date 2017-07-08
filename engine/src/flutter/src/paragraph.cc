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
    std::unordered_map<std::string, std::shared_ptr<minikin::FontCollection>>&
        collection_map) {
  minikin::FontStyle font;
  minikin::MinikinPaint paint;
  for (size_t i = 0; i < runs_.size(); ++i) {
    auto run = runs_.GetRun(i);
    GetFontAndMinikinPaint(run.style, &font, &paint);
    breaker_.addStyleRun(&paint,
                         font_collection_->GetMinikinFontCollectionForFamily(
                             run.style.font_family),
                         font, run.start, run.end, false,
                         run.style.letter_spacing);
  }
}

void Paragraph::Layout(double width, bool force) {
  // Do not allow calling layout multiple times without changing anything.
  if (!needs_layout_ && !force)
    return;
  needs_layout_ = false;

  width_ = width;

  std::unordered_map<std::string, std::shared_ptr<minikin::FontCollection>>
      collection_map;

  breaker_.setLineWidths(0.0f, 0, width_);
  AddRunsToLineBreaker(collection_map);
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
  line_widths_ = std::vector<double>();
  line_heights_ = std::vector<double>();

  // Set padding elements to have a minimum point.
  line_heights_.push_back(0);
  glyph_position_x_ = std::vector<std::vector<double>>();
  glyph_position_x_.push_back(std::vector<double>());
  std::vector<double> glyph_single_line_position_x;
  glyph_single_line_position_x.push_back(0);

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
    // Correct positions stored in the member vars.
    for (size_t y_index = 0; y_index < lines_; ++y_index) {
      switch (paragraph_style_.text_align) {
        case TextAlign::left:
          break;
        case TextAlign::right: {
          for (size_t i = 0; i < glyph_position_x_[y_index].size(); ++i) {
            glyph_position_x_[y_index][i] +=
                width_ - breaker_.getWidths()[y_index];
          }
          break;
        }
        case TextAlign::center: {
          for (size_t i = 0; i < glyph_position_x_[y_index].size(); ++i) {
            glyph_position_x_[y_index][i] +=
                (width_ - breaker_.getWidths()[y_index]) / 2;
          }
          break;
        }
        case TextAlign::justify: {
          // TODO(garyq): Track position changes due to justify in justify
          // method.
          break;
        }
      }
    }
    x_queue.clear();
  };
  for (size_t run_index = 0; run_index < runs_.size(); ++run_index) {
    auto run = runs_.GetRun(run_index);

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
                      text_.size(), bidiFlags, font, minikin_paint,
                      font_collection_->GetMinikinFontCollectionForFamily(
                          run.style.font_family));
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

        // Check if we should remove trailing whitespace of blobs.
        size_t trailing_length = 0;
        while (
            paragraph_style_.text_align == TextAlign::justify &&
            minikin::isWordSpace(
                text_[character_index + blob_length - trailing_length - 1]) &&
            layout_end == next_break) {
          ++trailing_length;
        }

        buffers.push_back(
            &builder.allocRunPos(paint, blob_length - trailing_length));

        letter_spacing_offset += run.style.letter_spacing;

        // TODO(garyq): Implement RTL.
        // Each Glyph/Letter.
        bool whitespace_ended = true;
        for (size_t blob_index = 0; blob_index < blob_length - trailing_length;
             ++blob_index) {
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
          glyph_single_line_position_x.push_back(
              buffers.back()->pos[pos_index]);
          buffers.back()->pos[pos_index + 1] = layout.getY(glyph_index);

          letter_spacing_offset += run.style.letter_spacing;
        }
        blob_start += blob_length;
        character_index += trailing_length;

        // Subtract letter offset to avoid big gap at end of run. This my be
        // removed depending on the specifications for letter spacing.
        // letter_spacing_offset -= run.style.letter_spacing;

        max_intrinsic_width_ +=
            layout.getX(blob_start - 1) + letter_spacing_offset;
      }

      // TODO(abarth): We could keep the same SkTextBlobBuilder as long as the
      // color stayed the same.
      SkPaint::FontMetrics metrics;
      paint.getFontMetrics(&metrics);
      // Apply additional word spacing if the text is justified.
      if (paragraph_style_.text_align == TextAlign::justify &&
          buffer_sizes.size() > 0 && character_index != text_.size()) {
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
              (metrics.fUnderlinePosition + metrics.fCapHeight) *
              run.style.height;
        }
      }
      if (max_descent < metrics.fDescent * run.style.height)
        max_descent = metrics.fDescent * run.style.height;

      if (layout_end == next_break) {
        y += max_line_spacing + prev_max_descent;
        line_heights_.push_back(
            (line_heights_.empty() ? 0 : line_heights_.back()) +
            max_line_spacing + max_descent);
        glyph_single_line_position_x.push_back(FLT_MAX);
        glyph_position_x_.push_back(glyph_single_line_position_x);
        prev_max_descent = max_descent;
        line_widths_.push_back(line_width);
        postprocess_line();

        max_line_spacing = 0.0f;
        max_descent = 0.0f;
        x = 0.0f;
        letter_spacing_offset = 0.0f;
        word_count = 0;
        line_width = 0.0f;
        character_index = layout_end;
        break_index += 1;
        lines_++;
        glyph_single_line_position_x = std::vector<double>();
        glyph_single_line_position_x.push_back(0);
      } else {
        x += layout.getAdvance();
      }

      layout_start = layout_end;
    }
  }
  y += max_line_spacing;
  height_ = y + max_descent;
  postprocess_line();
  if (line_width != 0)
    line_widths_.push_back(line_width);

  line_heights_.push_back(FLT_MAX);
  glyph_single_line_position_x.push_back(FLT_MAX);
  glyph_position_x_.push_back(glyph_single_line_position_x);
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
  // TODO(garyq): Currently fCapHeight + fUnderlinePosition. Verify this.
  return ideographic_baseline_;
}

double Paragraph::GetMaxIntrinsicWidth() const {
  return max_intrinsic_width_;
}

double Paragraph::GetMinIntrinsicWidth() const {
  // TODO(garyq): This is a lower bound. Actual value may be slightly higher.
  return max_intrinsic_width_ / paragraph_style_.max_lines;
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

// The x,y coordinates will be the very top left corner of the rendered
// paragraph.
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

    // Filled when drawing wavy decorations.
    std::vector<WaveCoordinates> wave_coords;

    double width = blob->bounds().fRight + blob->bounds().fLeft;

    paint.setStrokeWidth(metrics.fUnderlineThickness *
                         style.decoration_thickness);

    switch (style.decoration_style) {
      case TextDecorationStyle::kSolid: {
        break;
      }
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
        int wave_count = 0;
        double x_start = 0;
        double y_top = -metrics.fUnderlineThickness;
        double y_bottom = metrics.fUnderlineThickness;
        while (x_start + metrics.fUnderlineThickness * 2 < x + width) {
          wave_coords.push_back(
              WaveCoordinates(x_start, wave_count % 2 == 0 ? y_bottom : y_top,
                              x_start + metrics.fUnderlineThickness * 2,
                              wave_count % 2 == 0 ? y_top : y_bottom));
          x_start += metrics.fUnderlineThickness * 2;
          ++wave_count;
        }
        break;
      }
    }

    // Use a for loop for "kDouble" decoration style
    for (int i = 0; i < decoration_count; i++) {
      double y_offset = i * metrics.fUnderlineThickness * 3.0f;
      // Underline
      if (style.decoration & 0x1) {
        if (style.decoration_style != TextDecorationStyle::kWavy)
          canvas->drawLine(x, y + metrics.fUnderlinePosition + y_offset,
                           x + width, y + metrics.fUnderlinePosition + y_offset,
                           paint);
        else
          PaintWavyDecoration(canvas, wave_coords, paint, x, y,
                              metrics.fUnderlineThickness, width);
      }
      // Overline
      if (style.decoration & 0x2) {
        if (style.decoration_style != TextDecorationStyle::kWavy)
          canvas->drawLine(x, y + metrics.fAscent - y_offset, x + width,
                           y + metrics.fAscent - y_offset, paint);
        else
          PaintWavyDecoration(canvas, wave_coords, paint, x, y, metrics.fAscent,
                              width);
      }
      // Strikethrough
      if (style.decoration & 0x4) {
        if (style.decoration_style != TextDecorationStyle::kWavy)
          canvas->drawLine(x, y - metrics.fXHeight / 2 + y_offset, x + width,
                           y - metrics.fXHeight / 2 + y_offset, paint);
        else
          PaintWavyDecoration(canvas, wave_coords, paint, x, y,
                              -metrics.fXHeight / 2, width);
      }
    }
  }
}

void Paragraph::PaintWavyDecoration(SkCanvas* canvas,
                                    std::vector<WaveCoordinates> wave_coords,
                                    SkPaint paint,
                                    double x,
                                    double y,
                                    double y_offset,
                                    double width) {
  for (size_t i = 0; i < wave_coords.size(); ++i) {
    WaveCoordinates coords = wave_coords[i];
    canvas->drawLine(x + coords.x_start, y + y_offset + coords.y_start,
                     x + coords.x_end, y + y_offset + coords.y_end, paint);
  }
}

std::vector<SkRect> Paragraph::GetRectsForRange(size_t start,
                                                size_t end) const {
  std::vector<SkRect> rects;
  end = fmin(end, text_.size() - 1);
  while (start <= end) {
    SkIPoint word_bounds = GetWordBoundary(start);
    word_bounds.fY = fmin(end + 1, word_bounds.fY);
    word_bounds.fX = fmax(start, word_bounds.fX);
    start = word_bounds.fY;
    SkRect left_limits = GetCoordinatesForGlyphPosition(word_bounds.fX + 1);
    SkRect right_limits = GetCoordinatesForGlyphPosition(word_bounds.fY);
    if (left_limits.top() < right_limits.top()) {
      rects.push_back(SkRect::MakeLTRB(
          0, right_limits.top(), right_limits.right(), right_limits.bottom()));
    } else {
      rects.push_back(SkRect::MakeLTRB(left_limits.left(), left_limits.top(),
                                       right_limits.right(),
                                       right_limits.bottom()));
    }
  }
  return rects;
}

SkRect Paragraph::GetCoordinatesForGlyphPosition(size_t pos) const {
  size_t remainder = fmin(pos, text_.size());
  size_t line = 1;
  for (line = 1; line < line_heights_.size() - 1; ++line) {
    if (remainder > glyph_position_x_[line].size() - 2) {
      remainder -= glyph_position_x_[line].size() - 2;
    } else {
      break;
    }
  }
  return SkRect::MakeLTRB(glyph_position_x_[line][remainder],
                          line_heights_[line - 1],
                          remainder < glyph_position_x_[line].size() - 2
                              ? glyph_position_x_[line][remainder + 1]
                              : line_widths_[line - 1],
                          line_heights_[line]);
}

size_t Paragraph::GetGlyphPositionAtCoordinate(double dx, double dy) const {
  size_t offset = 0;
  size_t y_index = 1;
  size_t prev_count = 0;
  for (y_index = 1; y_index < line_heights_.size(); ++y_index) {
    if (dy < line_heights_[y_index]) {
      offset += prev_count;
      break;
    } else {
      offset += prev_count;
      prev_count = glyph_position_x_[y_index].size() - 2;
    }
  }
  prev_count = 0;
  for (size_t x_index = 1; x_index < glyph_position_x_[y_index].size();
       ++x_index) {
    if (dx < glyph_position_x_[y_index][x_index]) {
      break;
    } else {
      offset += prev_count;
      prev_count = 1;
    }
  }
  return offset;
}

SkIPoint Paragraph::GetWordBoundary(size_t offset) const {
  // TODO(garyq): Implement.
  return SkIPoint::Make(0, offset + 1);
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

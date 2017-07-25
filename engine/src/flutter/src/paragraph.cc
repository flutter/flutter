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

#include <hb.h>
#include <algorithm>
#include <limits>
#include <tuple>
#include <utility>
#include <vector>

#include <minikin/Layout.h>
#include "lib/ftl/logging.h"
#include "lib/txt/libs/minikin/HbFontCache.h"
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
  // Divide by font size so letter spacing is pixels, not proportional to font
  // size.
  paint->letterSpacing = style.letter_spacing / style.font_size;
  paint->wordSpacing = style.word_spacing;
  paint->scaleX = 1;
  // Prevent spacing rounding in Minikin.
  paint->paintFlags = 0xFF;
}

void GetPaint(const TextStyle& style, SkPaint* paint) {
  paint->setTextSize(style.font_size);
}

}  // namespace

static const float kDoubleDecorationSpacing = 3.0f;

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

// NOTE: Minikin LineBreaker addStyleRun() has an O(N^2) (according to
// benchmarks) time complexity where N is the total number of characters.
// However, this is not significant for reasonably sized paragraphs. It is
// currently recommended to break up very long paragraphs (10k+ characters) to
// ensure speedy layout.
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

void Paragraph::FillWhitespaceSet(size_t start,
                                  size_t end,
                                  hb_font_t* hb_font) {
  uint32_t unusedGlyph;
  for (size_t i = start; i < end; ++i) {
    if (minikin::isWordSpace(text_[i])) {
      hb_font_get_glyph(hb_font, text_[i], 0, &unusedGlyph);
      whitespace_set_.insert(unusedGlyph);
    }
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
  // TODO(garyq): Get hyphenator working. Hyphenator should be created with
  // a pattern binary dataset. Should be something along these lines:
  //
  //   minikin::Hyphenator* hyph =
  //     minikin::Hyphenator::loadBinary(<paramsgohere>);
  //   breaker_.setLocale(icu::Locale::getRoot(), &hyph);
  //
  AddRunsToLineBreaker(collection_map);
  breaker_.setJustified(paragraph_style_.text_align == TextAlign::justify);
  breaker_.setStrategy(paragraph_style_.break_strategy);
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
  lines_ = 0;
  width_ = 0.0f;
  line_widths_ = std::vector<double>();
  line_heights_ = std::vector<double>();
  line_heights_.push_back(0);
  records_ = std::vector<PaintRecord>();
  height_ = 0.0f;

  // Set padding elements to have a minimum point.
  glyph_position_x_ = std::vector<std::vector<double>>();
  glyph_position_x_.push_back(std::vector<double>());
  std::vector<double> glyph_single_line_position_x;
  glyph_single_line_position_x.push_back(0);
  double previous_run_x_position = 0.0f;

  SkScalar x = 0.0f;
  SkScalar y = 0.0f;
  size_t break_index = 0;
  double max_line_spacing = 0.0f;
  double max_descent = 0.0f;
  double prev_max_descent = 0.0f;
  double line_width = 0.0f;
  std::vector<SkScalar> x_queue;
  double justify_spacing = 0.0f;
  double prev_word_pos = 0.0f;
  double prev_char_advance = 0.0f;

  std::vector<const SkTextBlobBuilder::RunBuffer*> buffers;
  std::vector<size_t> buffer_sizes;
  int word_count = 0;

  auto postprocess_line = [this, &x_queue, &y]() -> void {
    size_t record_index = 0;
    for (size_t i = 0; i < x_queue.size(); ++i) {
      record_index = records_.size() - (x_queue.size() - i);
      records_[record_index].SetOffset(SkPoint::Make(x_queue[i], y));
      // Adjust the offsets for each of the different alignments.
      switch (paragraph_style_.text_align) {
        case TextAlign::left:
          break;
        case TextAlign::right: {
          records_[record_index].SetOffset(SkPoint::Make(
              records_[record_index].offset().x() + width_ -
                  breaker_.getWidths()[records_[record_index].line()],
              records_[record_index].offset().y()));
          records_[record_index].SetWidthModifier(
              records_[record_index].GetWidthModifier() + width_ -
              breaker_.getWidths()[records_[record_index].line()]);
          break;
        }
        case TextAlign::center: {
          records_[record_index].SetOffset(SkPoint::Make(
              records_[record_index].offset().x() +
                  (width_ -
                   breaker_.getWidths()[records_[record_index].line()]) /
                      2,
              records_[record_index].offset().y()));

          records_[record_index].SetWidthModifier(
              records_[record_index].GetWidthModifier() +
              (width_ - breaker_.getWidths()[records_[record_index].line()]) /
                  2);
          break;
        }
        case TextAlign::justify: {
          records_[record_index].SetWidthModifier(
              records_[record_index].GetWidthModifier() +
              records_[record_index].GetWidthModifier() + width_ -
              breaker_.getWidths()[records_[record_index].line()]);
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

    size_t layout_start = run.start;
    // Layout until the end of the run or too many lines.
    while (layout_start < run.end && lines_ < paragraph_style_.max_lines) {
      const size_t next_break = (break_index > breaks_count - 1)
                                    ? std::numeric_limits<size_t>::max()
                                    : breaks[break_index];
      const size_t layout_end = std::min(run.end, next_break);

      bool bidiFlags = paragraph_style_.rtl;
      // NOTE: Minikin Layout doLayout() has an O(N^2) (according to
      // benchmarks) time complexity where N is the total number of characters.
      // However, this is not significant for reasonably sized paragraphs. It is
      // currently recommended to break up very long paragraphs (10k+
      // characters) to ensure speedy layout.
      layout.doLayout(text_.data() + layout_start, 0, layout_end - layout_start,
                      layout_end - layout_start, bidiFlags, font, minikin_paint,
                      font_collection_->GetMinikinFontCollectionForFamily(
                          run.style.font_family));
      FillWhitespaceSet(layout_start, layout_end,
                        minikin::getHbFontLocked(layout.getFont(0)));

      const size_t glyph_count = layout.nGlyphs();
      size_t blob_start = 0;

      // Each blob.
      buffers = std::vector<const SkTextBlobBuilder::RunBuffer*>();
      buffer_sizes = std::vector<size_t>();
      word_count = 0;
      double temp_line_spacing = 0;
      double current_x_position = previous_run_x_position;
      while (blob_start < glyph_count) {
        const size_t blob_length = GetBlobLength(layout, blob_start);
        buffer_sizes.push_back(blob_length);
        // TODO(abarth): Precompute when we can use allocRunPosH.
        paint.setTypeface(GetTypefaceForGlyph(layout, blob_start));

        // Check if we should remove trailing whitespace of blobs.
        size_t trailing_length = 0;
        while (paragraph_style_.text_align == TextAlign::justify &&
               minikin::isWordSpace(
                   text_[blob_start + blob_length - trailing_length - 1]) &&
               layout_end == next_break) {
          ++trailing_length;
        }

        buffers.push_back(
            &builder.allocRunPos(paint, blob_length - trailing_length));

        // TODO(garyq): Implement RTL.
        // Each Glyph/Letter.
        bool whitespace_ended = true;
        for (size_t blob_index = 0; blob_index < blob_length - trailing_length;
             ++blob_index) {
          const size_t glyph_index = blob_start + blob_index;
          buffers.back()->glyphs[blob_index] = layout.getGlyphId(glyph_index);

          const size_t pos_index = 2 * blob_index;

          current_x_position = layout.getX(glyph_index);
          buffers.back()->pos[pos_index] = current_x_position;
          glyph_single_line_position_x.push_back(current_x_position +
                                                 previous_run_x_position);
          buffers.back()->pos[pos_index + 1] = layout.getY(glyph_index);

          // Check if the current Glyph is a whitespace and handle multiple
          // whitespaces in a row.
          if (whitespace_set_.count(layout.getGlyphId(glyph_index)) > 0) {
            // Only increment word_count if it is the first in a series of
            // whitespaces.
            if (whitespace_ended) {
              ++word_count;
            }
            whitespace_ended = false;
          } else {
            whitespace_ended = true;
          }

          prev_char_advance = layout.getCharAdvance(glyph_index);
        }
        blob_start += blob_length;
        previous_run_x_position += current_x_position + prev_char_advance;
      }

      // TODO(abarth): We could keep the same SkTextBlobBuilder as long as the
      // color stayed the same.
      SkPaint::FontMetrics metrics;
      paint.getFontMetrics(&metrics);
      // Apply additional word spacing if the text is justified.
      if (paragraph_style_.text_align == TextAlign::justify &&
          buffer_sizes.size() > 0) {
        JustifyLine(buffers, buffer_sizes, word_count, justify_spacing);
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

      temp_line_spacing = lines_ == 0 ? -metrics.fAscent * run.style.height
                                      : (-metrics.fAscent + metrics.fLeading) *
                                            run.style.height;
      if (max_line_spacing < temp_line_spacing) {
        max_line_spacing = temp_line_spacing;
        // Record the alphabetic_baseline_:
        if (lines_ == 0) {
          alphabetic_baseline_ = -metrics.fAscent * run.style.height;
          // TODO(garyq): Properly implement ideographic_baseline_.
          ideographic_baseline_ =
              (metrics.fUnderlinePosition - metrics.fAscent) * run.style.height;
        }
      }
      temp_line_spacing = metrics.fDescent * run.style.height;
      if (max_descent < temp_line_spacing)
        max_descent = temp_line_spacing;

      if (layout_end == next_break) {
        y += max_line_spacing + prev_max_descent;
        line_heights_.push_back(
            (line_heights_.empty() ? 0 : line_heights_.back()) +
            max_line_spacing + max_descent);
        glyph_single_line_position_x.push_back(
            glyph_single_line_position_x.back() + prev_char_advance);
        glyph_single_line_position_x.push_back(FLT_MAX);
        glyph_position_x_.push_back(glyph_single_line_position_x);
        prev_max_descent = max_descent;
        line_widths_.push_back(line_width);
        postprocess_line();

        // Reset Variables for next line.
        max_line_spacing = 0.0f;
        max_descent = 0.0f;
        x = 0.0f;
        prev_word_pos = 0;
        prev_char_advance = 0.0f;
        previous_run_x_position = 0.0f;
        line_width = 0.0f;
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
  // Handle last line tasks.
  y += max_line_spacing;
  height_ = y + max_descent;
  postprocess_line();
  if (line_width != 0)
    line_widths_.push_back(line_width);

  line_heights_.push_back(FLT_MAX);
  glyph_single_line_position_x.push_back(glyph_single_line_position_x.back() +
                                         prev_char_advance);
  glyph_single_line_position_x.push_back(FLT_MAX);
  glyph_position_x_.push_back(glyph_single_line_position_x);

  // Remove justification on the last line.
  if (paragraph_style_.text_align == TextAlign::justify &&
      buffer_sizes.size() > 0) {
    JustifyLine(buffers, buffer_sizes, word_count, justify_spacing, -1);
    // Remove decoration extra width if the last line.
    size_t i = records_.size() - 1;
    while (records_[i].line() == lines_ - 1) {
      records_[i].SetWidthModifier(0);
      --i;
    }
  }
  line_widths_ =
      std::vector<double>(breaker_.getWidths(), breaker_.getWidths() + lines_);
  CalculateIntrinsicWidths();
}

// Amends the buffers to incorporate justification.
void Paragraph::JustifyLine(
    std::vector<const SkTextBlobBuilder::RunBuffer*>& buffers,
    std::vector<size_t>& buffer_sizes,
    int word_count,
    double& justify_spacing,
    double multiplier) {
  // We will use the previous justification spacing when undoing justification.
  if (multiplier > 0) {
    justify_spacing =
        (width_ - breaker_.getWidths()[lines_]) / (word_count - 1);
  }
  word_count = 0;
  bool whitespace_ended = true;
  for (size_t i = 0; i < buffers.size(); ++i) {
    for (size_t glyph_index = 0; glyph_index < buffer_sizes[i]; ++glyph_index) {
      // Check if the current Glyph is a whitespace and handle multiple
      // whitespaces in a row.
      if (whitespace_set_.count(buffers[i]->glyphs[glyph_index]) > 0) {
        // Only increment word_count and add justification spacing to
        // whitespace if it is the first in a series of whitespaces.
        if (whitespace_ended) {
          ++word_count;
          buffers[i]->pos[glyph_index * 2] +=
              justify_spacing * multiplier * word_count;
        }
        whitespace_ended = false;
      } else {
        // Add justification spacing for all non-whitespace glyphs.
        buffers[i]->pos[glyph_index * 2] +=
            justify_spacing * multiplier * word_count;
        whitespace_ended = true;
      }
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

void Paragraph::CalculateIntrinsicWidths() {
  // TODO(garyq): Investigate correctness of the following implementation of max
  // intrinsic width. This is currently the sum of all the widths of each line
  // after layout.
  max_intrinsic_width_ = 0;
  for (size_t i = 0; i < line_widths_.size(); ++i) {
    max_intrinsic_width_ += line_widths_[i];
  }

  // TODO(garyq): Investigate correctness of the following implementation of max
  // intrinsic width. This is currently the longest line in the text after
  // layout.
  min_intrinsic_width_ = 0;
  for (size_t i = 0; i < line_widths_.size(); ++i) {
    min_intrinsic_width_ = std::max(min_intrinsic_width_, line_widths_[i]);
  }

  // Ensure that min < max widths.
  min_intrinsic_width_ = std::min(max_intrinsic_width_, min_intrinsic_width_);
  max_intrinsic_width_ = std::max(max_intrinsic_width_, min_intrinsic_width_);
}

double Paragraph::GetMaxIntrinsicWidth() const {
  return max_intrinsic_width_;
}

double Paragraph::GetMinIntrinsicWidth() const {
  return min_intrinsic_width_;
}

size_t Paragraph::TextSize() const {
  return text_.size();
}

double Paragraph::GetHeight() const {
  return line_heights_[line_heights_.size() - 2];
}

double Paragraph::GetLayoutWidth() const {
  double w = 0;
  for (size_t i = 0; i < line_widths_.size(); ++i) {
    w = std::max(w, line_widths_[i]);
  }
  return w;
}

double Paragraph::GetMaxWidth() const {
  return width_;
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
  SkAutoCanvasRestore canvas_restore(canvas, true);
  canvas->translate(x, y);
  for (size_t index = 0; index < records_.size(); ++index) {
    PaintRecord& record = records_[index];
    SkPaint paint;
    paint.setColor(record.style().color);
    SkPoint offset = record.offset();
    canvas->drawTextBlob(record.text(), offset.x(), offset.y(), paint);
    PaintDecorations(canvas, offset.x(), offset.y(), index);
  }
}

void Paragraph::PaintDecorations(SkCanvas* canvas,
                                 double x,
                                 double y,
                                 size_t record_index) {
  PaintRecord& record = records_[record_index];
  if (record.style().decoration != TextDecoration::kNone) {
    const SkPaint::FontMetrics& metrics = record.metrics();
    SkPaint paint;
    paint.setStyle(SkPaint::kStroke_Style);
    paint.setColor(record.style().decoration_color);
    paint.setAntiAlias(true);

    // This is set to 2 for the double line style
    int decoration_count = 1;

    // Filled when drawing wavy decorations.
    std::vector<WaveCoordinates> wave_coords;

    double width = 0;
    if (record_index == records_.size() - 1 ||
        record.line() < records_[record_index + 1].line()) {
      width = line_widths_[record.line()] - x;
    } else {
      width = record.text()->bounds().fRight + record.text()->bounds().fLeft;
    }

    width += record.GetWidthModifier();

    paint.setStrokeWidth(metrics.fUnderlineThickness *
                         record.style().decoration_thickness);

    // Setup the decorations.
    switch (record.style().decoration_style) {
      case TextDecorationStyle::kSolid: {
        break;
      }
      case TextDecorationStyle::kDouble: {
        decoration_count = 2;
        break;
      }
      // Note: the intervals are scaled by the thickness of the line, so it is
      // possible to change spacing by changing the decoration_thickness
      // property of TextStyle.
      case TextDecorationStyle::kDotted: {
        // Divide by 14pt as it is the default size.
        const float scale = record.style().font_size / 14.0f;
        const SkScalar intervals[] = {1.0f * scale, 2.0f * scale, 1.0f * scale,
                                      2.0f * scale};
        size_t count = sizeof(intervals) / sizeof(intervals[0]);
        paint.setPathEffect(SkPathEffect::MakeCompose(
            SkDashPathEffect::Make(intervals, count, 0.0f),
            SkDiscretePathEffect::Make(0, 0)));
        break;
      }
      // Note: the intervals are scaled by the thickness of the line, so it is
      // possible to change spacing by changing the decoration_thickness
      // property of TextStyle.
      case TextDecorationStyle::kDashed: {
        // Divide by 14pt as it is the default size.
        const float scale = record.style().font_size / 14.0f;
        const SkScalar intervals[] = {6.0f * scale, 3.0f * scale, 6.0f * scale,
                                      3.0f * scale};
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
        while (x_start + metrics.fUnderlineThickness * 2 < width) {
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

    // Draw the decorations.
    // Use a for loop for "kDouble" decoration style
    for (int i = 0; i < decoration_count; i++) {
      double y_offset =
          i * metrics.fUnderlineThickness * kDoubleDecorationSpacing;
      // Underline
      if (record.style().decoration & 0x1) {
        if (record.style().decoration_style != TextDecorationStyle::kWavy)
          canvas->drawLine(x, y + metrics.fUnderlinePosition + y_offset,
                           x + width, y + metrics.fUnderlinePosition + y_offset,
                           paint);
        else
          PaintWavyDecoration(canvas, wave_coords, paint, x, y,
                              metrics.fUnderlineThickness, width);
      }
      // Overline
      if (record.style().decoration & 0x2) {
        if (record.style().decoration_style != TextDecorationStyle::kWavy)
          canvas->drawLine(x, y + metrics.fAscent - y_offset, x + width,
                           y + metrics.fAscent - y_offset, paint);
        else
          PaintWavyDecoration(canvas, wave_coords, paint, x, y, metrics.fAscent,
                              width);
      }
      // Strikethrough
      if (record.style().decoration & 0x4) {
        // Make sure the double line is "centered" vertically.
        y_offset -= (decoration_count - 1.0) * metrics.fUnderlineThickness *
                    kDoubleDecorationSpacing / 2.0;
        if (record.style().decoration_style != TextDecorationStyle::kWavy)
          canvas->drawLine(x, y - metrics.fXHeight / 2.0 + y_offset, x + width,
                           y - metrics.fXHeight / 2.0 + y_offset, paint);
        else
          PaintWavyDecoration(canvas, wave_coords, paint, x, y,
                              -metrics.fXHeight / 2.0, width);
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
  FTL_DCHECK(end >= start && end >= 0 && start >= 0);
  std::vector<SkRect> rects;
  end = fmax(start, end);
  start = fmin(start, end);
  if (end == start)
    end = start + 1;
  end = fmin(end, text_.size());
  while (start < end) {
    SkIPoint word_bounds = GetWordBoundary(start);
    word_bounds.fX = fmax(start, word_bounds.fX);
    word_bounds.fY = fmin(end, word_bounds.fY);
    start = fmax(word_bounds.fY, start + 1);
    SkRect left_limits = GetCoordinatesForGlyphPosition(word_bounds.fX);
    SkRect right_limits = GetCoordinatesForGlyphPosition(word_bounds.fY - 1);
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
  remainder++;
  size_t line = 1;
  for (line = 1; line < line_heights_.size() - 1; ++line) {
    if (remainder > glyph_position_x_[line].size() - 3) {
      remainder -= glyph_position_x_[line].size() - 3;
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
      prev_count = glyph_position_x_[y_index].size() - 3;
    }
  }
  prev_count = 0;
  for (size_t x_index = 1; x_index < glyph_position_x_[y_index].size() - 1;
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
  // TODO(garyq): Consider punctuation as separate words.
  if (text_.size() == 0)
    return SkIPoint::Make(0, 0);
  return SkIPoint::Make(
      minikin::getPrevWordBreakForCache(text_.data(), offset + 1, text_.size()),
      minikin::getNextWordBreakForCache(text_.data(), offset, text_.size()));
}

int Paragraph::GetLineCount() const {
  return lines_;
}

bool Paragraph::DidExceedMaxLines() const {
  if (lines_ > paragraph_style_.max_lines)
    return true;
  return false;
}

void Paragraph::SetDirty(bool dirty) {
  needs_layout_ = dirty;
}

}  // namespace txt

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

#include "paragraph.h"

#include <hb.h>
#include <algorithm>
#include <limits>
#include <tuple>
#include <utility>
#include <vector>

#include <minikin/Layout.h>
#include "font_collection.h"
#include "font_skia.h"
#include "lib/ftl/logging.h"
#include "minikin/HbFontCache.h"
#include "minikin/LayoutUtils.h"
#include "minikin/LineBreaker.h"
#include "minikin/MinikinFont.h"
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
  paint->scaleX = 1.0f;
  // Prevent spacing rounding in Minikin. This causes jitter when switching
  // between same text content with different runs composing it, however, it
  // also produces more accurate layouts.
  paint->paintFlags |= minikin::LinearTextFlag;
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
}

void Paragraph::InitBreaker() {
  breaker_.setLocale(icu::Locale(), nullptr);
  breaker_.resize(text_.size());
  memcpy(breaker_.buffer(), text_.data(), text_.size() * sizeof(text_[0]));
  breaker_.setText();
}

bool Paragraph::AddRunsToLineBreaker(
    std::unordered_map<std::string, std::shared_ptr<minikin::FontCollection>>&
        collection_map /* TODO: Cache the font collection here. */) {
  minikin::FontStyle font;
  minikin::MinikinPaint paint;
  for (size_t i = 0; i < runs_.size(); ++i) {
    auto run = runs_.GetRun(i);
    GetFontAndMinikinPaint(run.style, &font, &paint);
    auto collection = font_collection_->GetMinikinFontCollectionForFamily(
        run.style.font_family);
    if (collection == nullptr) {
      FTL_LOG(INFO) << "Could not find font collection for family \""
                    << run.style.font_family << "\".";
      return false;
    }
    breaker_.addStyleRun(&paint, collection, font, run.start, run.end, false,
                         run.style.letter_spacing);
  }
  return true;
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
  if (!needs_layout_ && width == width_ && !force) {
    return;
  }
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

  // TODO: Maybe create a new breaker altogether.
  InitBreaker();

  if (!AddRunsToLineBreaker(collection_map)) {
    return;
  }

  breaker_.setJustified(paragraph_style_.text_align == TextAlign::justify);
  breaker_.setStrategy(paragraph_style_.break_strategy);
  size_t breaks_count = breaker_.computeBreaks();
  const int* breaks = breaker_.getBreaks();

  // Create a copy of text_ to use locally so that any changes made to the
  // vector (such as removing newline characters) is not permanent.
  std::vector<uint16_t> text(text_);

  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
  paint.setSubpixelText(true);

  minikin::FontStyle font;
  minikin::MinikinPaint minikin_paint;
  minikin::Layout layout;

  // Disable ligatures
  // TODO(garyq): Re-enable ligatures.
  minikin_paint.fontFeatureSettings += "-liga,-clig,";

  SkTextBlobBuilder builder;

  // Reset member variables so Layout still works when called more than once
  lines_ = 0;
  line_widths_ = std::vector<double>();
  line_heights_ = std::vector<double>();
  line_heights_.push_back(0);
  records_ = std::vector<PaintRecord>();

  // Set padding elements to have a minimum point.
  glyph_position_x_ = std::vector<std::vector<double>>();
  glyph_position_x_.push_back(std::vector<double>());
  std::vector<double> glyph_single_line_position_x;
  glyph_single_line_position_x.push_back(0);
  // Track the x of the previous run to maintain accurate xposition when
  // multiple SkTextBlobs make up a single line.
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
  double current_x_position = previous_run_x_position;

  std::vector<const SkTextBlobBuilder::RunBuffer*> buffers;
  std::vector<size_t> buffer_sizes;
  int word_count = 0;
  size_t max_lines = paragraph_style_.max_lines;

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
    bool is_newline = text_[run.start] == '\n' && run.end - run.start == 1;
    // Replace '\n' with a null character so that a 'missing glyph' box is not
    // drawn.
    if (is_newline)
      text[run.start] = '\0';

    GetFontAndMinikinPaint(run.style, &font, &minikin_paint);
    GetPaint(run.style, &paint);

    size_t layout_start = run.start;
    // Layout until the end of the run or too many lines.
    while (layout_start < run.end && lines_ < max_lines) {
      const size_t next_break = (break_index > breaks_count - 1)
                                    ? std::numeric_limits<size_t>::max()
                                    : breaks[break_index];
      const size_t layout_end = std::min(run.end, next_break);

      bool bidiFlags = paragraph_style_.rtl;
      std::shared_ptr<minikin::FontCollection> minikin_font_collection =
          font_collection_->GetMinikinFontCollectionForFamily(
              run.style.font_family);

      uint16_t* text_ptr = text.data() + layout_start;
      size_t text_count = layout_end - layout_start;
      std::vector<uint16_t> ellipsized_text;

      // Apply ellipsizing if the run was not completely laid out and this
      // is the last line (or lines are unlimited).
      const std::u16string& ellipsis = paragraph_style_.ellipsis;
      if (ellipsis.length() && !isinf(width_) && run.end != layout_end &&
          (lines_ == max_lines - 1 ||
           max_lines == std::numeric_limits<size_t>::max())) {
        float ellipsis_width = layout.measureText(
            reinterpret_cast<const uint16_t*>(ellipsis.data()),
            0, ellipsis.length(), ellipsis.length(), bidiFlags,
            font, minikin_paint, minikin_font_collection, nullptr);

        std::vector<float> text_advances(text_count);
        float text_width = layout.measureText(
            text.data() + layout_start, 0, text_count, text_count,
            bidiFlags, font, minikin_paint, minikin_font_collection,
            text_advances.data());

        // Truncate characters from the text until the ellipsis fits.
        size_t truncate_count = 0;
        while (truncate_count < text_count &&
               text_width + ellipsis_width > width_) {
          text_width -= text_advances[text_count - truncate_count - 1];
          truncate_count++;
        }

        ellipsized_text.reserve(text_count - truncate_count + ellipsis.length());
        ellipsized_text.insert(ellipsized_text.begin(),
                               text.begin() + layout_start,
                               text.begin() + layout_end - truncate_count);
        ellipsized_text.insert(ellipsized_text.end(),
                               ellipsis.begin(), ellipsis.end());
        text_ptr = ellipsized_text.data();
        text_count = ellipsized_text.size();

        // If there is no line limit, then skip all lines after the ellipsized
        // line.
        if (max_lines == std::numeric_limits<size_t>::max())
          max_lines = lines_ + 1;
      }

      // Minikin Layout doLayout() has an O(N^2) (according to
      // benchmarks) time complexity where N is the total number of characters.
      // However, this is not significant for reasonably sized paragraphs. It is
      // currently recommended to break up very long paragraphs (10k+
      // characters) to ensure speedy layout.
      layout.doLayout(text_ptr, 0, text_count, text_count,
                      bidiFlags, font, minikin_paint, minikin_font_collection);
      FillWhitespaceSet(layout_start, layout_end,
                        minikin::getHbFontLocked(layout.getFont(0)));

      const size_t glyph_count = layout.nGlyphs();
      size_t blob_start = 0;

      // Each blob.
      buffers = std::vector<const SkTextBlobBuilder::RunBuffer*>();
      buffer_sizes = std::vector<size_t>();
      word_count = 0;
      double temp_line_spacing = 0;
      current_x_position = 0;
      while (blob_start < glyph_count) {
        const size_t blob_length = GetBlobLength(layout, blob_start);
        buffer_sizes.push_back(blob_length);
        // TODO(abarth): Precompute when we can use allocRunPosH.
        paint.setTypeface(GetTypefaceForGlyph(layout, blob_start));

        // Check if we should remove trailing whitespace of blobs.
        size_t trailing_length = 0;
        while ((paragraph_style_.text_align == TextAlign::center ||
                paragraph_style_.text_align == TextAlign::right) &&
               whitespace_set_.count(layout.getGlyphId(
                   blob_start + blob_length - trailing_length - 1)) > 0 &&
               layout_end == next_break) {
          ++trailing_length;
        }

        buffers.push_back(
            &builder.allocRunPos(paint, blob_length - trailing_length));

        // TODO(garyq): Implement RTL.
        // Each Glyph/Letter.
        bool whitespace_ended = true;
        float letter_spacing = 0;
        for (size_t blob_index = 0; blob_index < blob_length - trailing_length;
             ++blob_index) {
          const size_t glyph_index = blob_start + blob_index;
          buffers.back()->glyphs[blob_index] = layout.getGlyphId(glyph_index);

          const size_t pos_index = 2 * blob_index;
          // Extract the letter spacing by itself out of the minikin layout.
          letter_spacing = run.style.letter_spacing == 0
                               ? 0
                               : layout.getX(glyph_index) - current_x_position;
          buffers.back()->pos[pos_index] = current_x_position + letter_spacing;
          glyph_single_line_position_x.push_back(
              current_x_position + previous_run_x_position + letter_spacing);
          buffers.back()->pos[pos_index + 1] = layout.getY(glyph_index);

          current_x_position += layout.getCharAdvance(glyph_index);
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
        previous_run_x_position += current_x_position + letter_spacing;
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
      records_.push_back(PaintRecord{run.style, builder.make(), metrics, lines_,
                                     layout.getAdvance()});
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
        // Record the alphabetic_baseline_ and idegraphic_baseline_:
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

      if (layout_end == next_break || is_newline) {
        y += roundf(max_line_spacing + prev_max_descent);
        line_heights_.push_back(
            (line_heights_.empty() ? 0 : line_heights_.back()) +
            roundf(max_line_spacing + max_descent));
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
        current_x_position = 0.0f;
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
  y += roundf(max_line_spacing + prev_max_descent);
  postprocess_line();
  if (line_width != 0)
    line_widths_.push_back(line_width);

  // Finalize measurements
  line_heights_.push_back((line_heights_.empty() ? 0 : line_heights_.back()) +
                          roundf(max_line_spacing + max_descent));
  glyph_single_line_position_x.push_back(glyph_single_line_position_x.back() +
                                         prev_char_advance);
  glyph_single_line_position_x.push_back(FLT_MAX);
  glyph_position_x_.push_back(glyph_single_line_position_x);

  // Remove justification on the last line.
  if (paragraph_style_.text_align == TextAlign::justify &&
      buffer_sizes.size() > 0) {
    JustifyLine(buffers, buffer_sizes, word_count, justify_spacing, -1);
  }
  line_widths_ =
      std::vector<double>(breaker_.getWidths(), breaker_.getWidths() + lines_);
  CalculateIntrinsicWidths();
  breaker_.finish();
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
  // Currently -fAscent
  return alphabetic_baseline_;
}

double Paragraph::GetIdeographicBaseline() const {
  // TODO(garyq): Currently -fAscent + fUnderlinePosition. Verify this.
  return ideographic_baseline_;
}

void Paragraph::CalculateIntrinsicWidths() {
  max_intrinsic_width_ = 0;
  for (size_t i = 0; i < line_widths_.size(); ++i) {
    max_intrinsic_width_ += line_widths_[i];
  }

  // TODO(garyq): Investigate correctness of the following implementation of min
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

void Paragraph::SetFontCollection(
    std::shared_ptr<FontCollection> font_collection) {
  font_collection_ = std::move(font_collection);
}

// The x,y coordinates will be the very top left corner of the rendered
// paragraph.
void Paragraph::Paint(SkCanvas* canvas, double x, double y) {
  SkAutoCanvasRestore canvas_restore(canvas, true);
  canvas->translate(x, y);
  SkPaint paint;
  for (size_t index = 0; index < records_.size(); ++index) {
    PaintRecord& record = records_[index];
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
  if (record.style().decoration == TextDecoration::kNone)
    return;

  const SkPaint::FontMetrics& metrics = record.metrics();
  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  if (record.style().decoration_color == SK_ColorTRANSPARENT) {
    paint.setColor(record.style().color);
  } else {
    paint.setColor(record.style().decoration_color);
  }
  paint.setAntiAlias(true);

  // This is set to 2 for the double line style
  int decoration_count = 1;

  // Filled when drawing wavy decorations.
  SkPath path;

  double width = 0;
  if (paragraph_style_.text_align == TextAlign::justify &&
      record.line() != lines_ - 1) {
    width = width_;
  } else {
    width = record.GetRunWidth();
  }

  paint.setStrokeWidth(
      (SkToBool(metrics.fFlags & SkPaint::FontMetrics::FontMetricsFlags::
                                     kUnderlineThicknessIsValid_Flag))
          ? metrics.fUnderlineThickness *
                record.style().decoration_thickness_multiplier
          // Backup value if the fUnderlineThickness metric is not available:
          // Divide by 14pt as it is the default size.
          : record.style().font_size / 14.0f *
                record.style().decoration_thickness_multiplier);

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
      const SkScalar intervals[] = {1.0f * scale, 1.5f * scale, 1.0f * scale,
                                    1.5f * scale};
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
      const SkScalar intervals[] = {4.0f * scale, 2.0f * scale, 4.0f * scale,
                                    2.0f * scale};
      size_t count = sizeof(intervals) / sizeof(intervals[0]);
      paint.setPathEffect(SkPathEffect::MakeCompose(
          SkDashPathEffect::Make(intervals, count, 0.0f),
          SkDiscretePathEffect::Make(0, 0)));
      break;
    }
    case TextDecorationStyle::kWavy: {
      int wave_count = 0;
      double x_start = 0;
      double wavelength = metrics.fUnderlineThickness *
                          record.style().decoration_thickness_multiplier;
      path.moveTo(x, y);
      while (x_start + wavelength * 2 < width) {
        path.rQuadTo(wavelength, wave_count % 2 != 0 ? wavelength : -wavelength,
                     wavelength * 2, 0);
        x_start += wavelength * 2;
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
    double y_offset_original = y_offset;
    // Underline
    if (record.style().decoration & 0x1) {
      y_offset +=
          (SkToBool(metrics.fFlags & SkPaint::FontMetrics::FontMetricsFlags::
                                         kUnderlinePositionIsValid_Flag))
              ? metrics.fUnderlinePosition
              : metrics.fUnderlineThickness;
      if (record.style().decoration_style != TextDecorationStyle::kWavy) {
        canvas->drawLine(x, y + y_offset, x + width, y + y_offset, paint);
      } else {
        SkPath offsetPath = path;
        offsetPath.offset(0, y_offset);
        canvas->drawPath(offsetPath, paint);
      }
      y_offset = y_offset_original;
    }
    // Overline
    if (record.style().decoration & 0x2) {
      // We subtract fAscent here because for double overlines, we want the
      // second line to be above, not below the first.
      y_offset -= metrics.fAscent;
      if (record.style().decoration_style != TextDecorationStyle::kWavy) {
        canvas->drawLine(x, y - y_offset, x + width, y - y_offset, paint);
      } else {
        SkPath offsetPath = path;
        offsetPath.offset(0, -y_offset);
        canvas->drawPath(offsetPath, paint);
      }
      y_offset = y_offset_original;
    }
    // Strikethrough
    if (record.style().decoration & 0x4) {
      if (SkToBool(metrics.fFlags & SkPaint::FontMetrics::FontMetricsFlags::
                                        kStrikeoutThicknessIsValid_Flag))
        paint.setStrokeWidth(metrics.fStrikeoutThickness *
                             record.style().decoration_thickness_multiplier);
      // Make sure the double line is "centered" vertically.
      y_offset += (decoration_count - 1.0) * metrics.fUnderlineThickness *
                  kDoubleDecorationSpacing / -2.0;
      y_offset +=
          (SkToBool(metrics.fFlags & SkPaint::FontMetrics::FontMetricsFlags::
                                         kStrikeoutThicknessIsValid_Flag))
              ? metrics.fStrikeoutPosition
              // Backup value if the strikeoutposition metric is not
              // available:
              : metrics.fXHeight / -2.0;
      if (record.style().decoration_style != TextDecorationStyle::kWavy) {
        canvas->drawLine(x, y + y_offset, x + width, y + y_offset, paint);
      } else {
        SkPath offsetPath = path;
        offsetPath.offset(0, y_offset);
        canvas->drawPath(offsetPath, paint);
      }
      y_offset = y_offset_original;
    }
  }
}

std::vector<SkRect> Paragraph::GetRectsForRange(size_t start,
                                                size_t end) const {
  std::vector<SkRect> rects;
  end = fmax(start, end);
  start = fmin(start, end);
  FTL_DCHECK(end >= start && end >= 0 && start >= 0);
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

size_t Paragraph::GetGlyphPositionAtCoordinate(
    double dx,
    double dy,
    bool using_glyph_center_as_boundary) const {
  size_t offset = 0;
  size_t y_index = 1;
  size_t prev_count = 0;
  for (y_index = 1; y_index < line_heights_.size() - 2; ++y_index) {
    if (dy < line_heights_[y_index]) {
      offset += prev_count;
      prev_count = glyph_position_x_[y_index - 1].size() - 3;
      break;
    } else {
      offset += prev_count;
      prev_count = glyph_position_x_[y_index].size() - 3;
    }
  }
  if (y_index == line_heights_.size() - 2)
    offset += prev_count;
  prev_count = 0;
  for (size_t x_index = 1; x_index < glyph_position_x_[y_index].size() - 1;
       ++x_index) {
    if (dx < glyph_position_x_[y_index][x_index] -
                 (using_glyph_center_as_boundary
                      ? (glyph_position_x_[y_index][x_index] -
                         glyph_position_x_[y_index][x_index - 1]) /
                            2.0f
                      : 0)) {
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

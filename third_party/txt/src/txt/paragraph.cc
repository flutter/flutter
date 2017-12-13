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
#include <map>
#include <numeric>
#include <utility>
#include <vector>

#include <minikin/Layout.h>
#include "font_collection.h"
#include "font_skia.h"
#include "lib/fxl/logging.h"
#include "minikin/HbFontCache.h"
#include "minikin/LayoutUtils.h"
#include "minikin/LineBreaker.h"
#include "minikin/MinikinFont.h"
#include "third_party/icu/source/common/unicode/ubidi.h"
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
    default:
      return -1;
  }
}

int GetWeight(const TextStyle& style) {
  return GetWeight(style.font_weight);
}

bool GetItalic(const TextStyle& style) {
  switch (style.font_style) {
    case FontStyle::italic:
      return true;
    case FontStyle::normal:
    default:
      return false;
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

void FindWords(const std::vector<uint16_t>& text,
               size_t start,
               size_t end,
               std::vector<Paragraph::Range<size_t>>* words) {
  bool in_word = false;
  size_t word_start;
  for (size_t i = start; i < end; ++i) {
    bool is_space = minikin::isWordSpace(text[i]);
    if (!in_word && !is_space) {
      word_start = i;
      in_word = true;
    } else if (in_word && is_space) {
      words->emplace_back(word_start, i);
      in_word = false;
    }
  }
  if (in_word)
    words->emplace_back(word_start, end);
}

}  // namespace

static const float kDoubleDecorationSpacing = 3.0f;

Paragraph::GlyphPosition::GlyphPosition(double x_start,
                                        double x_advance,
                                        size_t code_unit_index,
                                        size_t code_unit_width)
    : code_units(code_unit_index, code_unit_index + code_unit_width),
      x_pos(x_start, x_start + x_advance) {}

Paragraph::GlyphLine::GlyphLine(std::vector<GlyphPosition>&& p, size_t tcu)
    : positions(std::move(p)), total_code_units(tcu) {}

Paragraph::CodeUnitRun::CodeUnitRun(std::vector<GlyphPosition>&& p,
                                    Range<size_t> cu,
                                    Range<double> x,
                                    size_t line,
                                    const SkPaint::FontMetrics& metrics,
                                    TextDirection dir)
    : positions(std::move(p)),
      code_units(cu),
      x_pos(x),
      line_number(line),
      font_metrics(metrics),
      direction(dir) {}

Paragraph::Paragraph() {
  breaker_.setLocale(icu::Locale(), nullptr);
}

Paragraph::~Paragraph() = default;

void Paragraph::SetText(std::vector<uint16_t> text, StyledRuns runs) {
  needs_layout_ = true;
  if (text.size() == 0)
    return;
  text_ = std::move(text);
  runs_ = std::move(runs);
}

bool Paragraph::ComputeLineBreaks() {
  line_ranges_.clear();
  line_widths_.clear();

  std::vector<size_t> newline_positions;
  for (size_t i = 0; i < text_.size(); ++i) {
    ULineBreak ulb = static_cast<ULineBreak>(
        u_getIntPropertyValue(text_[i], UCHAR_LINE_BREAK));
    if (ulb == U_LB_LINE_FEED || ulb == U_LB_MANDATORY_BREAK)
      newline_positions.push_back(i);
  }
  newline_positions.push_back(text_.size());

  size_t run_index = 0;
  for (size_t newline_index = 0; newline_index < newline_positions.size();
       ++newline_index) {
    size_t block_start =
        (newline_index > 0) ? newline_positions[newline_index - 1] + 1 : 0;
    size_t block_end = newline_positions[newline_index];
    size_t block_size = block_end - block_start;

    if (block_size == 0) {
      line_ranges_.emplace_back(block_start, block_start, true);
      line_widths_.push_back(0);
      continue;
    }

    breaker_.setLineWidths(0.0f, 0, width_);
    breaker_.setJustified(paragraph_style_.text_align == TextAlign::justify);
    breaker_.setStrategy(paragraph_style_.break_strategy);
    breaker_.resize(block_size);
    memcpy(breaker_.buffer(), text_.data() + block_start,
           block_size * sizeof(text_[0]));
    breaker_.setText();

    // Add the runs that include this line to the LineBreaker.
    while (run_index < runs_.size()) {
      StyledRuns::Run run = runs_.GetRun(run_index);
      if (run.start >= block_end)
        break;

      minikin::FontStyle font;
      minikin::MinikinPaint paint;
      GetFontAndMinikinPaint(run.style, &font, &paint);
      std::shared_ptr<minikin::FontCollection> collection =
          font_collection_->GetMinikinFontCollectionForFamily(
              run.style.font_family);
      if (collection == nullptr) {
        FXL_LOG(INFO) << "Could not find font collection for family \""
                      << run.style.font_family << "\".";
        return false;
      }
      size_t run_start = std::max(run.start, block_start) - block_start;
      size_t run_end = std::min(run.end, block_end) - block_start;
      bool isRtl = (paragraph_style_.text_direction == TextDirection::rtl);
      breaker_.addStyleRun(&paint, collection, font, run_start, run_end, isRtl);

      if (run.end > block_end)
        break;
      run_index++;
    }

    size_t breaks_count = breaker_.computeBreaks();
    const int* breaks = breaker_.getBreaks();
    for (size_t i = 0; i < breaks_count; ++i) {
      size_t break_start = (i > 0) ? breaks[i - 1] : 0;
      line_ranges_.emplace_back(break_start + block_start,
                                breaks[i] + block_start, i == breaks_count - 1);
      line_widths_.push_back(breaker_.getWidths()[i]);
    }

    breaker_.finish();
  }

  return true;
}

bool Paragraph::ComputeBidiRuns() {
  bidi_runs_.clear();

  auto ubidi_closer = [](UBiDi* b) { ubidi_close(b); };
  std::unique_ptr<UBiDi, decltype(ubidi_closer)> bidi(ubidi_open(),
                                                      ubidi_closer);
  if (!bidi)
    return false;

  UBiDiLevel paraLevel = (paragraph_style_.text_direction == TextDirection::rtl)
                             ? UBIDI_DEFAULT_RTL
                             : UBIDI_DEFAULT_LTR;
  UErrorCode status = U_ZERO_ERROR;
  ubidi_setPara(bidi.get(), reinterpret_cast<const UChar*>(text_.data()),
                text_.size(), paraLevel, nullptr, &status);
  if (!U_SUCCESS(status))
    return false;

  int32_t bidi_run_count = ubidi_countRuns(bidi.get(), &status);
  if (!U_SUCCESS(status))
    return false;

  // Build a map of styled runs indexed by start position.
  std::map<size_t, StyledRuns::Run> styled_run_map;
  for (size_t i = 0; i < runs_.size(); ++i) {
    StyledRuns::Run run = runs_.GetRun(i);
    styled_run_map.emplace(std::make_pair(run.start, run));
  }

  for (int32_t bidi_run_index = 0; bidi_run_index < bidi_run_count;
       ++bidi_run_index) {
    int32_t bidi_run_start, bidi_run_length;
    UBiDiDirection direction = ubidi_getVisualRun(
        bidi.get(), bidi_run_index, &bidi_run_start, &bidi_run_length);
    if (!U_SUCCESS(status))
      return false;

    // Exclude the leading bidi control character if present.
    UChar32 first_char;
    U16_GET(text_.data(), 0, bidi_run_start, static_cast<int>(text_.size()),
            first_char);
    if (u_hasBinaryProperty(first_char, UCHAR_BIDI_CONTROL)) {
      bidi_run_start++;
      bidi_run_length--;
    }
    if (bidi_run_length == 0)
      continue;

    // Exclude the trailing bidi control character if present.
    UChar32 last_char;
    U16_GET(text_.data(), 0, bidi_run_start + bidi_run_length - 1,
            static_cast<int>(text_.size()), last_char);
    if (u_hasBinaryProperty(last_char, UCHAR_BIDI_CONTROL)) {
      bidi_run_length--;
    }
    if (bidi_run_length == 0)
      continue;

    size_t bidi_run_end = bidi_run_start + bidi_run_length;
    TextDirection text_direction =
        direction == UBIDI_RTL ? TextDirection::rtl : TextDirection::ltr;

    // Break this bidi run into chunks based on text style.
    size_t chunk_start = bidi_run_start;
    while (chunk_start < bidi_run_end) {
      auto styled_run_iter = styled_run_map.upper_bound(chunk_start);
      styled_run_iter--;
      const StyledRuns::Run& styled_run = styled_run_iter->second;
      size_t chunk_end = std::min(bidi_run_end, styled_run.end);
      bidi_runs_.emplace_back(chunk_start, chunk_end, text_direction,
                              styled_run.style);
      chunk_start = chunk_end;
    }
  }

  return true;
}

void Paragraph::Layout(double width, bool force) {
  // Do not allow calling layout multiple times without changing anything.
  if (!needs_layout_ && width == width_ && !force) {
    return;
  }
  needs_layout_ = false;

  width_ = width;

  if (!ComputeLineBreaks()) {
    return;
  }
  ComputeBidiRuns();

  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
  paint.setSubpixelText(true);
  paint.setHinting(SkPaint::kSlight_Hinting);

  records_.clear();
  line_heights_.clear();
  glyph_lines_.clear();
  code_unit_runs_.clear();

  minikin::Layout layout;
  SkTextBlobBuilder builder;
  double y_offset = 0;
  double prev_max_descent = 0;
  double max_word_width = 0;

  size_t line_limit = std::min(paragraph_style_.max_lines, line_ranges_.size());
  did_exceed_max_lines_ = (line_ranges_.size() > paragraph_style_.max_lines);

  for (size_t line_number = 0; line_number < line_limit; ++line_number) {
    const LineRange& line_range = line_ranges_[line_number];

    // Break the line into words if justification should be applied.
    std::vector<Range<size_t>> words;
    double word_gap_width = 0;
    size_t word_index = 0;
    bool justify_line = (paragraph_style_.text_align == TextAlign::justify &&
                         line_number != line_limit - 1 &&
                         !line_ranges_[line_number].hard_break);
    FindWords(text_, line_range.start, line_range.end, &words);
    if (justify_line) {
      if (words.size() > 1) {
        word_gap_width =
            (width_ - line_widths_[line_number]) / (words.size() - 1);
      }
    }

    // Find the runs comprising this line.
    std::vector<BidiRun> line_runs;
    for (const BidiRun& bidi_run : bidi_runs_) {
      if (bidi_run.start < line_range.end && bidi_run.end > line_range.start) {
        line_runs.emplace_back(std::max(bidi_run.start, line_range.start),
                               std::min(bidi_run.end, line_range.end),
                               bidi_run.direction, bidi_run.style);
      }
    }

    std::vector<GlyphPosition> line_glyph_positions;
    double run_x_offset = GetLineXOffset(line_number);
    double justify_x_offset = 0;
    std::vector<PaintRecord> paint_records;

    for (const BidiRun& run : line_runs) {
      minikin::FontStyle font;
      minikin::MinikinPaint minikin_paint;
      GetFontAndMinikinPaint(run.style, &font, &minikin_paint);
      GetPaint(run.style, &paint);

      std::shared_ptr<minikin::FontCollection> minikin_font_collection =
          font_collection_->GetMinikinFontCollectionForFamily(
              run.style.font_family);

      // Lay out this run.
      uint16_t* text_ptr = text_.data();
      size_t text_start = run.start;
      size_t text_count = run.end - run.start;
      int bidiFlags = (paragraph_style_.text_direction == TextDirection::rtl)
                          ? minikin::kBidi_RTL
                          : minikin::kBidi_LTR;

      // Apply ellipsizing if the run was not completely laid out and this
      // is the last line (or lines are unlimited).
      const std::u16string& ellipsis = paragraph_style_.ellipsis;
      std::vector<uint16_t> ellipsized_text;
      if (ellipsis.length() && !isinf(width_) && !line_range.hard_break &&
          (line_number == line_limit - 1 ||
           paragraph_style_.max_lines == std::numeric_limits<size_t>::max())) {
        float ellipsis_width = layout.measureText(
            reinterpret_cast<const uint16_t*>(ellipsis.data()), 0,
            ellipsis.length(), ellipsis.length(), bidiFlags, font,
            minikin_paint, minikin_font_collection, nullptr);

        std::vector<float> text_advances(text_count);
        float text_width = layout.measureText(
            text_ptr, text_start, text_count, text_.size(), bidiFlags, font,
            minikin_paint, minikin_font_collection, text_advances.data());

        // Truncate characters from the text until the ellipsis fits.
        size_t truncate_count = 0;
        while (truncate_count < text_count &&
               text_width + ellipsis_width > width_) {
          text_width -= text_advances[text_count - truncate_count - 1];
          truncate_count++;
        }

        ellipsized_text.reserve(text_count - truncate_count +
                                ellipsis.length());
        ellipsized_text.insert(ellipsized_text.begin(),
                               text_.begin() + run.start,
                               text_.begin() + run.end - truncate_count);
        ellipsized_text.insert(ellipsized_text.end(), ellipsis.begin(),
                               ellipsis.end());
        text_ptr = ellipsized_text.data();
        text_start = 0;
        text_count = ellipsized_text.size();

        // If there is no line limit, then skip all lines after the ellipsized
        // line.
        if (paragraph_style_.max_lines == std::numeric_limits<size_t>::max()) {
          line_limit = line_number + 1;
          did_exceed_max_lines_ = true;
        }
      }

      layout.doLayout(text_ptr, text_start, text_count, text_.size(), bidiFlags,
                      font, minikin_paint, minikin_font_collection);

      if (layout.nGlyphs() == 0) {
        // This run is empty, so insert a placeholder paint record that captures
        // the current font metrics.
        SkPaint::FontMetrics metrics;
        paint.getFontMetrics(&metrics);
        paint_records.emplace_back(run.style, SkPoint::Make(run_x_offset, 0),
                                   builder.make(), metrics, line_number,
                                   layout.getAdvance());
        continue;
      }

      // Break the layout into blobs that share the same SkPaint parameters.
      std::vector<Range<size_t>> glyph_blobs;
      for (size_t blob_start = 0; blob_start < layout.nGlyphs();) {
        size_t blob_len = GetBlobLength(layout, blob_start);
        glyph_blobs.emplace_back(blob_start, blob_start + blob_len);
        blob_start += blob_len;
      }

      size_t code_unit_index;
      if (run.is_rtl()) {
        code_unit_index = text_count;
        U16_BACK_1(text_ptr + text_start, 0, code_unit_index);
      } else {
        code_unit_index = 0;
      }
      double word_start_position = std::numeric_limits<double>::quiet_NaN();

      // Build a Skia text blob from each group of glyphs.
      for (const Range<size_t>& glyph_blob : glyph_blobs) {
        std::vector<GlyphPosition> glyph_positions;

        paint.setTypeface(GetTypefaceForGlyph(layout, glyph_blob.start));
        const SkTextBlobBuilder::RunBuffer& blob_buffer =
            builder.allocRunPos(paint, glyph_blob.end - glyph_blob.start);

        for (size_t glyph_index = glyph_blob.start;
             glyph_index < glyph_blob.end; ++glyph_index) {
          size_t blob_index = glyph_index - glyph_blob.start;
          blob_buffer.glyphs[blob_index] = layout.getGlyphId(glyph_index);

          size_t pos_index = blob_index * 2;
          double glyph_x_offset = layout.getX(glyph_index) + justify_x_offset;
          blob_buffer.pos[pos_index] = glyph_x_offset;
          blob_buffer.pos[pos_index + 1] = layout.getY(glyph_index);

          if (word_index < words.size() &&
              words[word_index].start == run.start + code_unit_index) {
            word_start_position = run_x_offset + glyph_x_offset;
          }

          float glyph_advance = layout.getCharAdvance(code_unit_index);

          // The glyph may be a ligature.  Determine how many input characters
          // are joined into this glyph.  Note that each character may be
          // encoded as multiple UTF-16 code units.
          std::vector<size_t> subglyph_code_unit_counts;
          size_t next_code_unit_index = code_unit_index;
          if (run.is_rtl()) {
            U16_BACK_1(text_ptr + text_start, 0, next_code_unit_index);
            subglyph_code_unit_counts.push_back(code_unit_index -
                                                next_code_unit_index);
          } else {
            U16_FWD_1(text_ptr + text_start, next_code_unit_index, text_count);
            subglyph_code_unit_counts.push_back(next_code_unit_index -
                                                code_unit_index);
            while (next_code_unit_index < text_count) {
              if (layout.getCharAdvance(next_code_unit_index) != 0)
                break;
              size_t cur_code_unit_index = next_code_unit_index;
              U16_FWD_1(text_ptr + text_start, next_code_unit_index,
                        text_count);
              subglyph_code_unit_counts.push_back(next_code_unit_index -
                                                  cur_code_unit_index);
            }
          }
          float subglyph_advance =
              glyph_advance / subglyph_code_unit_counts.size();

          glyph_positions.emplace_back(
              run_x_offset + glyph_x_offset, subglyph_advance,
              run.start + code_unit_index, subglyph_code_unit_counts[0]);

          // Compute positions for the additional characters in the ligature.
          for (size_t i = 1; i < subglyph_code_unit_counts.size(); ++i) {
            glyph_positions.emplace_back(
                glyph_positions.back().x_pos.end, subglyph_advance,
                glyph_positions.back().code_units.start +
                    subglyph_code_unit_counts[i - 1],
                subglyph_code_unit_counts[i]);
          }

          if (word_index < words.size() &&
              words[word_index].end == run.start + next_code_unit_index) {
            if (justify_line)
              justify_x_offset += word_gap_width;
            word_index++;

            if (!isnan(word_start_position)) {
              double word_width =
                  glyph_positions.back().x_pos.end - word_start_position;
              max_word_width = std::max(word_width, max_word_width);
              word_start_position = std::numeric_limits<double>::quiet_NaN();
            }
          }

          code_unit_index = next_code_unit_index;
        }

        SkPaint::FontMetrics metrics;
        paint.getFontMetrics(&metrics);
        paint_records.emplace_back(run.style, SkPoint::Make(run_x_offset, 0),
                                   builder.make(), metrics, line_number,
                                   layout.getAdvance());

        line_glyph_positions.insert(line_glyph_positions.end(),
                                    glyph_positions.begin(),
                                    glyph_positions.end());

        // Add a record of glyph positions sorted by code unit index.
        std::vector<GlyphPosition> code_unit_positions(glyph_positions);
        std::sort(code_unit_positions.begin(), code_unit_positions.end(),
                  [](const GlyphPosition& a, const GlyphPosition& b) {
                    return a.code_units.start < b.code_units.start;
                  });
        code_unit_runs_.emplace_back(
            std::move(code_unit_positions), Range<size_t>(run.start, run.end),
            Range<double>(glyph_positions.front().x_pos.start,
                          glyph_positions.back().x_pos.end),
            line_number, metrics, run.direction);
      }

      run_x_offset += layout.getAdvance();
    }

    double max_line_spacing = 0;
    double max_descent = 0;
    for (const PaintRecord& paint_record : paint_records) {
      const SkPaint::FontMetrics& metrics = paint_record.metrics();
      double style_height = paint_record.style().height;
      double line_spacing =
          (line_number == 0)
              ? -metrics.fAscent * style_height
              : (-metrics.fAscent + metrics.fLeading) * style_height;
      if (line_spacing > max_line_spacing) {
        max_line_spacing = line_spacing;
        if (line_number == 0) {
          alphabetic_baseline_ = line_spacing;
          // TODO(garyq): Properly implement ideographic_baseline_.
          ideographic_baseline_ =
              (metrics.fUnderlinePosition - metrics.fAscent) * style_height;
        }
      }
      max_line_spacing = std::max(line_spacing, max_line_spacing);

      double descent = metrics.fDescent * style_height;
      max_descent = std::max(descent, max_descent);
    }

    line_heights_.push_back((line_heights_.empty() ? 0 : line_heights_.back()) +
                            round(max_line_spacing + max_descent));
    line_baselines_.push_back(line_heights_.back() - max_descent);
    y_offset += round(max_line_spacing + prev_max_descent);
    prev_max_descent = max_descent;

    for (PaintRecord& paint_record : paint_records) {
      paint_record.SetOffset(
          SkPoint::Make(paint_record.offset().x(), y_offset));
      records_.emplace_back(std::move(paint_record));
    }

    size_t next_line_start = (line_number < line_ranges_.size() - 1)
                                 ? line_ranges_[line_number + 1].start
                                 : text_.size();
    glyph_lines_.emplace_back(std::move(line_glyph_positions),
                              next_line_start - line_range.start);
  }

  max_intrinsic_width_ = 0;
  for (double line_width : line_widths_) {
    max_intrinsic_width_ += line_width;
  }
  min_intrinsic_width_ = std::min(max_word_width, max_intrinsic_width_);

  std::sort(code_unit_runs_.begin(), code_unit_runs_.end(),
            [](const CodeUnitRun& a, const CodeUnitRun& b) {
              return a.code_units.start < b.code_units.start;
            });
}

double Paragraph::GetLineXOffset(size_t line) {
  if (line >= line_widths_.size() || isinf(width_))
    return 0;

  TextAlign align = paragraph_style_.text_align;
  TextDirection direction = paragraph_style_.text_direction;

  if (align == TextAlign::right ||
      (align == TextAlign::start && direction == TextDirection::rtl) ||
      (align == TextAlign::end && direction == TextDirection::ltr)) {
    return width_ - line_widths_[line];
  } else if (paragraph_style_.text_align == TextAlign::center) {
    return (width_ - line_widths_[line]) / 2;
  } else {
    return 0;
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
  return line_heights_.size() ? line_heights_.back() : 0;
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
      record.line() != GetLineCount() - 1) {
    width = width_;
  } else {
    width = record.GetRunWidth();
  }

  paint.setStrokeWidth(
      (metrics.fFlags &
       SkPaint::FontMetrics::FontMetricsFlags::kUnderlineThicknessIsValid_Flag)
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
      y_offset += (metrics.fFlags & SkPaint::FontMetrics::FontMetricsFlags::
                                        kUnderlinePositionIsValid_Flag)
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
      if (metrics.fFlags & SkPaint::FontMetrics::FontMetricsFlags::
                               kStrikeoutThicknessIsValid_Flag)
        paint.setStrokeWidth(metrics.fStrikeoutThickness *
                             record.style().decoration_thickness_multiplier);
      // Make sure the double line is "centered" vertically.
      y_offset += (decoration_count - 1.0) * metrics.fUnderlineThickness *
                  kDoubleDecorationSpacing / -2.0;
      y_offset += (metrics.fFlags & SkPaint::FontMetrics::FontMetricsFlags::
                                        kStrikeoutThicknessIsValid_Flag)
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

std::vector<Paragraph::TextBox> Paragraph::GetRectsForRange(size_t start,
                                                            size_t end) const {
  std::vector<TextBox> boxes;

  for (const CodeUnitRun& run : code_unit_runs_) {
    if (run.code_units.start >= end)
      break;
    if (run.code_units.end <= start)
      continue;

    double baseline = line_baselines_[run.line_number];
    SkScalar top = baseline + run.font_metrics.fAscent;
    SkScalar bottom = baseline + run.font_metrics.fDescent;

    SkScalar left, right;
    if (run.code_units.start >= start && run.code_units.end <= end) {
      left = run.x_pos.start;
      right = run.x_pos.end;
    } else {
      left = SK_ScalarMax;
      right = SK_ScalarMin;
      for (const GlyphPosition& gp : run.positions) {
        if (gp.code_units.start >= start && gp.code_units.end <= end) {
          left = std::min(left, static_cast<SkScalar>(gp.x_pos.start));
          right = std::max(right, static_cast<SkScalar>(gp.x_pos.end));
        }
      }
      if (left == SK_ScalarMax || right == SK_ScalarMin)
        continue;
    }
    boxes.emplace_back(SkRect::MakeLTRB(left, top, right, bottom),
                       run.direction);
  }

  return boxes;
}

Paragraph::PositionWithAffinity Paragraph::GetGlyphPositionAtCoordinate(
    double dx,
    double dy) const {
  if (line_heights_.empty() || dy < 0)
    return PositionWithAffinity(0, DOWNSTREAM);

  size_t y_index;
  for (y_index = 0; y_index < line_heights_.size() - 1; ++y_index) {
    if (dy < line_heights_[y_index])
      break;
  }

  const std::vector<GlyphPosition>& line_glyph_position =
      glyph_lines_[y_index].positions;
  if (line_glyph_position.empty()) {
    int line_start_index =
        std::accumulate(glyph_lines_.begin(), glyph_lines_.begin() + y_index, 0,
                        [](const int a, const GlyphLine& b) {
                          return a + static_cast<int>(b.total_code_units);
                        });
    return PositionWithAffinity(line_start_index, DOWNSTREAM);
  }

  size_t x_index;
  const GlyphPosition* gp = nullptr;
  for (x_index = 0; x_index < line_glyph_position.size(); ++x_index) {
    double glyph_end = (x_index < line_glyph_position.size() - 1)
                           ? line_glyph_position[x_index + 1].x_pos.start
                           : line_glyph_position[x_index].x_pos.end;
    if (dx < glyph_end) {
      gp = &line_glyph_position[x_index];
      break;
    }
  }

  if (gp == nullptr) {
    const GlyphPosition& last_glyph = line_glyph_position.back();
    return PositionWithAffinity(last_glyph.code_units.end, UPSTREAM);
  }

  // Find the direction of the run that contains this glyph.
  TextDirection direction = TextDirection::ltr;
  for (const CodeUnitRun& run : code_unit_runs_) {
    if (gp->code_units.start >= run.code_units.start &&
        gp->code_units.end <= run.code_units.end) {
      direction = run.direction;
      break;
    }
  }

  double glyph_center = (gp->x_pos.start + gp->x_pos.end) / 2;
  if ((direction == TextDirection::ltr && dx < glyph_center) ||
      (direction == TextDirection::rtl && dx >= glyph_center)) {
    return PositionWithAffinity(gp->code_units.start, DOWNSTREAM);
  } else {
    return PositionWithAffinity(gp->code_units.end, UPSTREAM);
  }
}

Paragraph::Range<size_t> Paragraph::GetWordBoundary(size_t offset) const {
  if (text_.size() == 0)
    return Range<size_t>(0, 0);

  if (!word_breaker_) {
    UErrorCode status = U_ZERO_ERROR;
    word_breaker_.reset(
        icu::BreakIterator::createWordInstance(icu::Locale(), status));
    if (!U_SUCCESS(status))
      return Range<size_t>(0, 0);
  }

  word_breaker_->setText(icu::UnicodeString(false, text_.data(), text_.size()));

  int32_t prev_boundary = word_breaker_->preceding(offset + 1);
  int32_t next_boundary = word_breaker_->next();
  if (prev_boundary == icu::BreakIterator::DONE)
    prev_boundary = offset;
  if (next_boundary == icu::BreakIterator::DONE)
    next_boundary = offset;
  return Range<size_t>(prev_boundary, next_boundary);
}

size_t Paragraph::GetLineCount() const {
  return line_heights_.size();
}

bool Paragraph::DidExceedMaxLines() const {
  return did_exceed_max_lines_;
}

void Paragraph::SetDirty(bool dirty) {
  needs_layout_ = dirty;
}

}  // namespace txt

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
#include <numeric>
#include <tuple>
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
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "third_party/skia/include/effects/SkDiscretePathEffect.h"

namespace txt {
namespace {

struct Range {
  Range(size_t s, size_t e) : start(s), end(e) {}
  size_t start, end;
};

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

void FindWords(const std::vector<uint16_t>& text,
               size_t start,
               size_t end,
               std::vector<Range>* words) {
  bool in_word = false;
  size_t word_start;
  for (size_t i = start; i < end; ++i) {
    bool is_space = minikin::isWordSpace(text[i]);
    if (!in_word && !is_space) {
      word_start = i;
      in_word = true;
    } else if (in_word && is_space) {
      words->emplace_back(word_start - start, i - start);
      in_word = false;
    }
  }
  if (in_word)
    words->emplace_back(word_start - start, end - start);
}

}  // namespace

static const float kDoubleDecorationSpacing = 3.0f;

Paragraph::GlyphLine::GlyphLine(std::vector<GlyphPosition>&& p)
    : positions(std::move(p)),
      total_code_units(std::accumulate(
          positions.begin(),
          positions.end(),
          0,
          [](size_t a, const auto& b) { return a + b.code_units; })) {}

const Paragraph::GlyphPosition& Paragraph::GlyphLine::GetGlyphPosition(
    size_t pos) const {
  FXL_DCHECK(pos < total_code_units);
  if (positions.size() == total_code_units)
    return positions[pos];

  size_t unit_count = 0;
  for (const Paragraph::GlyphPosition& gp : positions) {
    if (pos < unit_count + gp.code_units)
      return gp;
    unit_count += gp.code_units;
  }

  return positions.back();
}

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
      FXL_LOG(INFO) << "Could not find font collection for family \""
                    << run.style.font_family << "\".";
      return false;
    }
    breaker_.addStyleRun(&paint, collection, font, run.start, run.end, false,
                         run.style.letter_spacing);
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
  breaks_count_ = breaker_.computeBreaks();
  const int* breaks = breaker_.getBreaks();

  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
  paint.setSubpixelText(true);

  records_.clear();
  line_heights_.clear();
  glyph_position_x_.clear();

  minikin::Layout layout;
  SkTextBlobBuilder builder;
  size_t line_limit = std::min(paragraph_style_.max_lines, breaks_count_);
  size_t run_index = 0;
  double y_offset = 0;
  double prev_max_descent = 0;
  double max_word_width = 0;

  for (size_t line_number = 0; line_number < line_limit; ++line_number) {
    size_t line_start = (line_number > 0) ? breaks[line_number - 1] : 0;
    size_t line_end = breaks[line_number];

    // Break the line into words if justification should be applied.
    std::vector<Range> words;
    double word_gap_width = 0;
    size_t word_index = 0;
    bool justify_line =
        (paragraph_style_.text_align == TextAlign::justify &&
         line_number != line_limit - 1 && text_[line_end - 1] != '\n');
    FindWords(text_, line_start, line_end, &words);
    if (justify_line) {
      if (words.size() > 1) {
        word_gap_width =
            (width_ - breaker_.getWidths()[line_number]) / (words.size() - 1);
      }
    }

    // Find the runs comprising this line.
    std::vector<StyledRuns::Run> line_runs;
    while (run_index < runs_.size()) {
      StyledRuns::Run run = runs_.GetRun(run_index);
      if (run.start >= line_end)
        break;
      line_runs.push_back(run);
      if (run.end > line_end)
        break;
      run_index++;
    }

    std::vector<GlyphPosition> glyph_single_line_position_x;
    double run_x_offset = GetLineXOffset(line_number);
    std::vector<PaintRecord> paint_records;

    for (const StyledRuns::Run& run : line_runs) {
      minikin::FontStyle font;
      minikin::MinikinPaint minikin_paint;
      GetFontAndMinikinPaint(run.style, &font, &minikin_paint);
      GetPaint(run.style, &paint);

      std::shared_ptr<minikin::FontCollection> minikin_font_collection =
          font_collection_->GetMinikinFontCollectionForFamily(
              run.style.font_family);

      // Lay out this run.
      size_t line_run_start = std::max(run.start, line_start);
      size_t line_run_end = std::min(run.end, line_end);
      uint16_t* text_ptr = text_.data() + line_run_start;
      size_t text_count = line_run_end - line_run_start;
      int bidiFlags = (paragraph_style_.text_direction == TextDirection::rtl)
                          ? minikin::kBidi_RTL
                          : minikin::kBidi_LTR;

      if (text_count == 0)
        continue;
      if (text_ptr[text_count - 1] == '\n')
        text_count--;

      // Apply ellipsizing if the run was not completely laid out and this
      // is the last line (or lines are unlimited).
      const std::u16string& ellipsis = paragraph_style_.ellipsis;
      std::vector<uint16_t> ellipsized_text;
      if (ellipsis.length() && !isinf(width_) && run.end > line_end &&
          (line_number == line_limit - 1 ||
           paragraph_style_.max_lines == std::numeric_limits<size_t>::max())) {
        float ellipsis_width = layout.measureText(
            reinterpret_cast<const uint16_t*>(ellipsis.data()), 0,
            ellipsis.length(), ellipsis.length(), bidiFlags, font,
            minikin_paint, minikin_font_collection, nullptr);

        std::vector<float> text_advances(text_count);
        float text_width = layout.measureText(
            text_ptr, 0, text_count, text_count, bidiFlags, font, minikin_paint,
            minikin_font_collection, text_advances.data());

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
                               text_.begin() + line_run_start,
                               text_.begin() + line_run_end - truncate_count);
        ellipsized_text.insert(ellipsized_text.end(), ellipsis.begin(),
                               ellipsis.end());
        text_ptr = ellipsized_text.data();
        text_count = ellipsized_text.size();

        // If there is no line limit, then skip all lines after the ellipsized
        // line.
        if (paragraph_style_.max_lines == std::numeric_limits<size_t>::max())
          line_limit = line_number + 1;
      }

      layout.doLayout(text_ptr, 0, text_count, text_count, bidiFlags, font,
                      minikin_paint, minikin_font_collection);

      // Break the layout into blobs that share the same SkPaint parameters.
      std::vector<Range> glyph_blobs;
      for (size_t blob_start = 0; blob_start < layout.nGlyphs();) {
        size_t blob_len = GetBlobLength(layout, blob_start);
        glyph_blobs.emplace_back(blob_start, blob_start + blob_len);
        blob_start += blob_len;
      }

      double justify_x_offset = 0;
      size_t code_unit_index = 0;
      double word_start_position = std::numeric_limits<double>::quiet_NaN();

      for (const Range& glyph_blob : glyph_blobs) {
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
              code_unit_index == words[word_index].start) {
            word_start_position = run_x_offset + glyph_x_offset;
          }

          float glyph_advance = layout.getCharAdvance(code_unit_index);

          // The glyph may be a ligature.  Determine how many input characters
          // are joined into this glyph.  Note that each character may be
          // encoded as multiple UTF-16 code units.
          size_t prev_code_unit_index = code_unit_index;
          U16_FWD_1(text_ptr, code_unit_index, text_count);
          std::vector<size_t> subglyph_code_unit_counts{code_unit_index -
                                                        prev_code_unit_index};
          while (code_unit_index < text_count) {
            if (layout.getCharAdvance(code_unit_index) != 0)
              break;
            prev_code_unit_index = code_unit_index;
            U16_FWD_1(text_ptr, code_unit_index, text_count);
            subglyph_code_unit_counts.push_back(code_unit_index -
                                                prev_code_unit_index);
          }
          float subglyph_advance =
              glyph_advance / subglyph_code_unit_counts.size();
          glyph_single_line_position_x.emplace_back(
              run_x_offset + glyph_x_offset, subglyph_advance,
              subglyph_code_unit_counts[0]);

          // Compute positions for the additional characters in the ligature.
          for (size_t i = 1; i < subglyph_code_unit_counts.size(); ++i) {
            glyph_single_line_position_x.emplace_back(
                glyph_single_line_position_x.back().start + subglyph_advance,
                subglyph_advance, subglyph_code_unit_counts[i]);
          }

          if (word_index < words.size() &&
              code_unit_index == words[word_index].end) {
            if (justify_line)
              justify_x_offset += word_gap_width;
            word_index++;

            if (!isnan(word_start_position)) {
              double word_width =
                  glyph_single_line_position_x.back().glyph_end() -
                  word_start_position;
              max_word_width = std::max(word_width, max_word_width);
              word_start_position = std::numeric_limits<double>::quiet_NaN();
            }
          }
        }
      }

      SkPaint::FontMetrics metrics;
      paint.getFontMetrics(&metrics);
      paint_records.emplace_back(run.style, SkPoint::Make(run_x_offset, 0),
                                 builder.make(), metrics, line_number,
                                 layout.getAdvance());
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
                            roundf(max_line_spacing + max_descent));
    y_offset += roundf(max_line_spacing + prev_max_descent);
    prev_max_descent = max_descent;

    for (PaintRecord& paint_record : paint_records) {
      paint_record.SetOffset(
          SkPoint::Make(paint_record.offset().x(), y_offset));
      records_.emplace_back(std::move(paint_record));
    }

    glyph_position_x_.emplace_back(std::move(glyph_single_line_position_x));
  }

  max_intrinsic_width_ = 0;
  for (size_t i = 0; i < breaks_count_; ++i) {
    max_intrinsic_width_ += breaker_.getWidths()[i];
  }
  min_intrinsic_width_ = std::min(max_word_width, max_intrinsic_width_);

  breaker_.finish();
}

double Paragraph::GetLineXOffset(size_t line) {
  if (line >= breaks_count_ || isinf(width_))
    return 0;

  TextAlign align = paragraph_style_.text_align;
  TextDirection direction = paragraph_style_.text_direction;

  if (align == TextAlign::right ||
      (align == TextAlign::start && direction == TextDirection::rtl) ||
      (align == TextAlign::end && direction == TextDirection::ltr)) {
    return width_ - breaker_.getWidths()[line];
  } else if (paragraph_style_.text_align == TextAlign::center) {
    return (width_ - breaker_.getWidths()[line]) / 2;
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

  if (end <= start || start == end)
    return rects;

  size_t pos = 0;
  size_t line;
  for (line = 0; line < glyph_position_x_.size(); ++line) {
    if (start < pos + glyph_position_x_[line].total_code_units)
      break;
    pos += glyph_position_x_[line].total_code_units;
  }
  if (line == glyph_position_x_.size())
    return rects;

  if (end <= pos + glyph_position_x_[line].total_code_units) {
    rects.push_back(GetRectForLineRange(line, start - pos, end - pos));
    return rects;
  }

  rects.push_back(GetRectForLineRange(
      line, start - pos, glyph_position_x_[line].total_code_units));

  while (true) {
    pos += glyph_position_x_[line].total_code_units;
    line++;
    if (line == glyph_position_x_.size())
      break;

    if (end <= pos + glyph_position_x_[line].total_code_units) {
      rects.push_back(GetRectForLineRange(line, 0, end - pos));
      break;
    } else {
      rects.push_back(GetRectForLineRange(
          line, 0, glyph_position_x_[line].total_code_units));
    }
  }

  return rects;
}

SkRect Paragraph::GetRectForLineRange(size_t line,
                                      size_t start,
                                      size_t end) const {
  FXL_DCHECK(line < glyph_position_x_.size());
  const GlyphLine& glyph_line = glyph_position_x_[line];
  if (glyph_line.positions.empty())
    return SkRect::MakeEmpty();

  FXL_DCHECK(start < glyph_line.total_code_units);
  SkScalar left = glyph_line.GetGlyphPosition(start).start;
  end = std::min(end, glyph_line.total_code_units);
  SkScalar right = glyph_line.GetGlyphPosition(end - 1).glyph_end();
  SkScalar top = (line > 0) ? line_heights_[line - 1] : 0;
  SkScalar bottom = line_heights_[line];
  return SkRect::MakeLTRB(left, top, right, bottom);
}

Paragraph::PositionWithAffinity Paragraph::GetGlyphPositionAtCoordinate(
    double dx,
    double dy,
    bool using_glyph_center_as_boundary) const {
  if (line_heights_.empty())
    return PositionWithAffinity(0, DOWNSTREAM);

  size_t offset = 0;
  size_t y_index;
  for (y_index = 0; y_index < line_heights_.size() - 1; ++y_index) {
    if (dy < line_heights_[y_index])
      break;
    offset += glyph_position_x_[y_index].total_code_units;
  }

  const std::vector<GlyphPosition>& line_glyph_position =
      glyph_position_x_[y_index].positions;
  size_t x_index;
  for (x_index = 0; x_index < line_glyph_position.size(); ++x_index) {
    double glyph_end = (x_index < line_glyph_position.size() - 1)
                           ? line_glyph_position[x_index + 1].start
                           : line_glyph_position[x_index].glyph_end();
    double boundary;
    if (using_glyph_center_as_boundary) {
      boundary = (line_glyph_position[x_index].start + glyph_end) / 2.0f;
    } else {
      boundary = glyph_end;
    }

    if (dx < boundary)
      break;

    offset += line_glyph_position[x_index].code_units;
  }
  return PositionWithAffinity(offset, x_index > 0 ? UPSTREAM : DOWNSTREAM);
}

SkIPoint Paragraph::GetWordBoundary(size_t offset) const {
  // TODO(garyq): Consider punctuation as separate words.
  if (text_.size() == 0)
    return SkIPoint::Make(0, 0);
  return SkIPoint::Make(
      minikin::getPrevWordBreakForCache(text_.data(), offset + 1, text_.size()),
      minikin::getNextWordBreakForCache(text_.data(), offset, text_.size()));
}

size_t Paragraph::GetLineCount() const {
  return line_heights_.size();
}

bool Paragraph::DidExceedMaxLines() const {
  if (GetLineCount() > paragraph_style_.max_lines)
    return true;
  return false;
}

void Paragraph::SetDirty(bool dirty) {
  needs_layout_ = dirty;
}

}  // namespace txt

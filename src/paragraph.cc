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
#include <utility>
#include <vector>

#include <minikin/Layout.h>
#include <minikin/LineBreaker.h>

#include "lib/ftl/logging.h"

#include "lib/txt/src/font_collection.h"
#include "lib/txt/src/font_skia.h"
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

size_t GetBlobLength(const minikin::Layout& layout, size_t blob_start) {
  const size_t glyph_count = layout.nGlyphs();
  const sk_sp<SkTypeface>& typeface = GetTypefaceForGlyph(layout, blob_start);
  for (size_t blob_end = blob_start + 1; blob_end < glyph_count; ++blob_end) {
    if (GetTypefaceForGlyph(layout, blob_end).get() != typeface.get())
      return blob_end - blob_start;
  }
  return glyph_count - blob_start;
}

int GetWeight(const TextStyle& style) {
  switch (style.font_weight) {
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
        FontCollection::GetDefaultFontCollection()
            .GetMinikinFontCollectionForFamily(run.style.font_family, rootdir);
    GetFontAndMinikinPaint(run.style, &font, &paint);
    breaker_.addStyleRun(&paint, collection, font, run.start, run.end, false);
  }
}

void Paragraph::Layout(const ParagraphConstraints& constraints,
                       const std::string& rootdir) {
  breaker_.setLineWidths(0.0f, 0, constraints.width());
  AddRunsToLineBreaker(rootdir);
  size_t breaks_count = breaker_.computeBreaks();
  const int* breaks = breaker_.getBreaks();

  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);

  minikin::FontStyle font;
  minikin::MinikinPaint minikin_paint;

  SkTextBlobBuilder builder;

  minikin::Layout layout;
  SkScalar x = 0.0f;
  SkScalar y = 0.0f;
  size_t break_index = 0;
  for (size_t run_index = 0; run_index < runs_.size(); ++run_index) {
    auto run = runs_.GetRun(run_index);
    auto collection =
        FontCollection::GetDefaultFontCollection()
            .GetMinikinFontCollectionForFamily(run.style.font_family, rootdir);
    GetFontAndMinikinPaint(run.style, &font, &minikin_paint);
    GetPaint(run.style, &paint);

    size_t layout_start = run.start;
    while (layout_start < run.end) {
      const size_t next_break = (break_index > breaks_count - 1)
                                    ? std::numeric_limits<size_t>::max()
                                    : breaks[break_index];
      const size_t layout_end = std::min(run.end, next_break);

      int bidiFlags = 0;
      layout.doLayout(text_.data(), layout_start, layout_end - layout_start,
                      text_.size(), bidiFlags, font, minikin_paint, collection);

      const size_t glyph_count = layout.nGlyphs();
      size_t blob_start = 0;
      while (blob_start < glyph_count) {
        const size_t blob_length = GetBlobLength(layout, blob_start);
        // TODO(abarth): Precompute when we can use allocRunPosH.
        paint.setTypeface(GetTypefaceForGlyph(layout, blob_start));

        auto buffer = builder.allocRunPos(paint, blob_length);

        for (size_t blob_index = 0; blob_index < blob_length; ++blob_index) {
          const size_t glyph_index = blob_start + blob_index;
          buffer.glyphs[blob_index] = layout.getGlyphId(glyph_index);
          const size_t pos_index = 2 * blob_index;
          buffer.pos[pos_index] = layout.getX(glyph_index);
          buffer.pos[pos_index + 1] = layout.getY(glyph_index);
        }
        blob_start += blob_length;
      }

      // TODO(abarth): We could keep the same SkTextBlobBuilder as long as the
      // color stayed the same.
      records_.push_back(
          PaintRecord(run.style.color, SkPoint::Make(x, y), builder.make()));

      if (layout_end == next_break) {
        x = 0.0f;
        // TODO(abarth): Use the line height, which is something like the max
        // font_size for runs in this line times the paragraph's line height.
        y += run.style.font_size;
        break_index += 1;
      } else {
        x += layout.getAdvance();
      }

      layout_start = layout_end;
    }
  }
}

void Paragraph::Paint(SkCanvas* canvas, double x, double y) {
  SkPaint paint;
  for (const auto& record : records_) {
    paint.setColor(record.color());
    const SkPoint& offset = record.offset();
    canvas->drawTextBlob(record.text(), x + offset.x(), y + offset.y(), paint);
  }
}

}  // namespace txt

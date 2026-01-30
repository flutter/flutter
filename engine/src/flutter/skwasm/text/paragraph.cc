// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/skia/modules/skparagraph/include/Paragraph.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/text/text_types.h"
#include "third_party/skia/include/core/SkScalar.h"
#include "third_party/skia/modules/skparagraph/include/DartTypes.h"
#include "third_party/skia/modules/skparagraph/include/TextStyle.h"

SKWASM_EXPORT void paragraph_dispose(Skwasm::Paragraph* paragraph) {
  Skwasm::live_paragraph_count--;
  delete paragraph;
}

SKWASM_EXPORT SkScalar paragraph_getWidth(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->getMaxWidth();
}

SKWASM_EXPORT SkScalar paragraph_getHeight(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->getHeight();
}

SKWASM_EXPORT SkScalar paragraph_getLongestLine(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->getLongestLine();
}

SKWASM_EXPORT SkScalar
paragraph_getMinIntrinsicWidth(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->getMinIntrinsicWidth();
}

SKWASM_EXPORT SkScalar
paragraph_getMaxIntrinsicWidth(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->getMaxIntrinsicWidth();
}

SKWASM_EXPORT SkScalar
paragraph_getAlphabeticBaseline(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->getAlphabeticBaseline();
}

SKWASM_EXPORT SkScalar
paragraph_getIdeographicBaseline(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->getIdeographicBaseline();
}

SKWASM_EXPORT bool paragraph_getDidExceedMaxLines(
    Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->didExceedMaxLines();
}

SKWASM_EXPORT void paragraph_layout(Skwasm::Paragraph* paragraph,
                                    SkScalar width) {
  paragraph->skia_paragraph->layout(width);
}

SKWASM_EXPORT int32_t
paragraph_getPositionForOffset(Skwasm::Paragraph* paragraph,
                               SkScalar offset_x,
                               SkScalar offset_y,
                               skia::textlayout::Affinity* out_affinity) {
  auto position = paragraph->skia_paragraph->getGlyphPositionAtCoordinate(
      offset_x, offset_y);
  if (out_affinity) {
    *out_affinity = position.affinity;
  }
  return position.position;
}

SKWASM_EXPORT bool paragraph_getClosestGlyphInfoAtCoordinate(
    Skwasm::Paragraph* paragraph,
    SkScalar offset_x,
    SkScalar offset_y,
    // Out parameters:
    SkRect* grapheme_layout_bounds,    // 1 SkRect
    size_t* grapheme_code_unit_range,  // 2 size_ts: [start, end]
    bool* boolean_flags) {             // 1 boolean: isLTR
  skia::textlayout::Paragraph::GlyphInfo glyph_info;
  if (!paragraph->skia_paragraph->getClosestUTF16GlyphInfoAt(offset_x, offset_y,
                                                             &glyph_info)) {
    return false;
  }
  // This is more verbose than memcpying the whole struct but ideally we don't
  // want to depend on the exact memory layout of the struct.
  std::memcpy(grapheme_layout_bounds, &glyph_info.fGraphemeLayoutBounds,
              sizeof(SkRect));
  std::memcpy(grapheme_code_unit_range, &glyph_info.fGraphemeClusterTextRange,
              2 * sizeof(size_t));
  boolean_flags[0] =
      glyph_info.fDirection == skia::textlayout::TextDirection::kLtr;
  return true;
}

SKWASM_EXPORT bool paragraph_getGlyphInfoAt(
    Skwasm::Paragraph* paragraph,
    size_t index,
    // Out parameters:
    SkRect* grapheme_layout_bounds,    // 1 SkRect
    size_t* grapheme_code_unit_range,  // 2 size_ts: [start, end]
    bool* boolean_flags) {             // 1 boolean: isLTR
  skia::textlayout::Paragraph::GlyphInfo glyph_info;
  if (!paragraph->skia_paragraph->getGlyphInfoAtUTF16Offset(index,
                                                            &glyph_info)) {
    return false;
  }
  std::memcpy(grapheme_layout_bounds, &glyph_info.fGraphemeLayoutBounds,
              sizeof(SkRect));
  std::memcpy(grapheme_code_unit_range, &glyph_info.fGraphemeClusterTextRange,
              2 * sizeof(size_t));
  boolean_flags[0] =
      glyph_info.fDirection == skia::textlayout::TextDirection::kLtr;
  return true;
}

SKWASM_EXPORT void paragraph_getWordBoundary(
    Skwasm::Paragraph* paragraph,
    unsigned int position,
    int32_t* out_range  // Two `int32_t`s, start and end
) {
  auto range = paragraph->skia_paragraph->getWordBoundary(position);
  out_range[0] = range.start;
  out_range[1] = range.end;
}

SKWASM_EXPORT size_t paragraph_getLineCount(Skwasm::Paragraph* paragraph) {
  return paragraph->skia_paragraph->lineNumber();
}

SKWASM_EXPORT int paragraph_getLineNumberAt(Skwasm::Paragraph* paragraph,
                                            size_t character_index) {
  return paragraph->skia_paragraph->getLineNumberAtUTF16Offset(character_index);
}

SKWASM_EXPORT skia::textlayout::LineMetrics* paragraph_getLineMetricsAtIndex(
    Skwasm::Paragraph* paragraph,
    size_t line_number) {
  Skwasm::live_line_metrics_count++;
  auto metrics = new skia::textlayout::LineMetrics();
  if (paragraph->skia_paragraph->getLineMetricsAt(line_number, metrics)) {
    return metrics;
  } else {
    delete metrics;
    return nullptr;
  }
}

struct TextBoxList {
  std::vector<skia::textlayout::TextBox> boxes;
};

SKWASM_EXPORT void textBoxList_dispose(TextBoxList* list) {
  Skwasm::live_text_box_list_count--;
  delete list;
}

SKWASM_EXPORT size_t textBoxList_getLength(TextBoxList* list) {
  return list->boxes.size();
}

SKWASM_EXPORT skia::textlayout::TextDirection
textBoxList_getBoxAtIndex(TextBoxList* list, size_t index, SkRect* out_rect) {
  const auto& box = list->boxes[index];
  *out_rect = box.rect;
  return box.direction;
}

SKWASM_EXPORT TextBoxList* paragraph_getBoxesForRange(
    Skwasm::Paragraph* paragraph,
    int start,
    int end,
    skia::textlayout::RectHeightStyle height_style,
    skia::textlayout::RectWidthStyle width_style) {
  Skwasm::live_text_box_list_count++;
  return new TextBoxList{paragraph->skia_paragraph->getRectsForRange(
      start, end, height_style, width_style)};
}

SKWASM_EXPORT TextBoxList* paragraph_getBoxesForPlaceholders(
    Skwasm::Paragraph* paragraph) {
  Skwasm::live_text_box_list_count++;
  return new TextBoxList{paragraph->skia_paragraph->getRectsForPlaceholders()};
}

// Returns a list of the code points that were unable to be rendered with the
// selected fonts. The list is deduplicated, so each code point in the output
// is unique.
// If `nullptr` is passed in for `outCodePoints`, we simply return the count
// of the code points.
// Note: This must be called after the paragraph has been laid out at least
// once in order to get valid data.
SKWASM_EXPORT int paragraph_getUnresolvedCodePoints(
    Skwasm::Paragraph* paragraph,
    SkUnichar* out_code_points,
    int out_length) {
  if (!out_code_points) {
    return paragraph->skia_paragraph->unresolvedCodepoints().size();
  }
  int out_index = 0;
  for (SkUnichar character :
       paragraph->skia_paragraph->unresolvedCodepoints()) {
    if (out_index < out_length) {
      out_code_points[out_index] = character;
      out_index++;
    } else {
      break;
    }
  }
  return out_index;
}

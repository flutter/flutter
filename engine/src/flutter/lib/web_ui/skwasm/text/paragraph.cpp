// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "third_party/skia/modules/skparagraph/include/Paragraph.h"
#include "../export.h"
#include "../live_objects.h"
#include "DartTypes.h"
#include "TextStyle.h"
#include "include/core/SkScalar.h"
#include "text_types.h"

using namespace Skwasm;

SKWASM_EXPORT void paragraph_dispose(Paragraph* paragraph) {
  liveParagraphCount--;
  delete paragraph;
}

SKWASM_EXPORT SkScalar paragraph_getWidth(Paragraph* paragraph) {
  return paragraph->skiaParagraph->getMaxWidth();
}

SKWASM_EXPORT SkScalar paragraph_getHeight(Paragraph* paragraph) {
  return paragraph->skiaParagraph->getHeight();
}

SKWASM_EXPORT SkScalar paragraph_getLongestLine(Paragraph* paragraph) {
  return paragraph->skiaParagraph->getLongestLine();
}

SKWASM_EXPORT SkScalar paragraph_getMinIntrinsicWidth(Paragraph* paragraph) {
  return paragraph->skiaParagraph->getMinIntrinsicWidth();
}

SKWASM_EXPORT SkScalar paragraph_getMaxIntrinsicWidth(Paragraph* paragraph) {
  return paragraph->skiaParagraph->getMaxIntrinsicWidth();
}

SKWASM_EXPORT SkScalar paragraph_getAlphabeticBaseline(Paragraph* paragraph) {
  return paragraph->skiaParagraph->getAlphabeticBaseline();
}

SKWASM_EXPORT SkScalar paragraph_getIdeographicBaseline(Paragraph* paragraph) {
  return paragraph->skiaParagraph->getIdeographicBaseline();
}

SKWASM_EXPORT bool paragraph_getDidExceedMaxLines(Paragraph* paragraph) {
  return paragraph->skiaParagraph->didExceedMaxLines();
}

SKWASM_EXPORT void paragraph_layout(Paragraph* paragraph, SkScalar width) {
  paragraph->skiaParagraph->layout(width);
}

SKWASM_EXPORT int32_t
paragraph_getPositionForOffset(Paragraph* paragraph,
                               SkScalar offsetX,
                               SkScalar offsetY,
                               skia::textlayout::Affinity* outAffinity) {
  auto position =
      paragraph->skiaParagraph->getGlyphPositionAtCoordinate(offsetX, offsetY);
  if (outAffinity) {
    *outAffinity = position.affinity;
  }
  return position.position;
}

SKWASM_EXPORT bool paragraph_getClosestGlyphInfoAtCoordinate(
    Paragraph* paragraph,
    SkScalar offsetX,
    SkScalar offsetY,
    // Out parameters:
    SkRect* graphemeLayoutBounds,   // 1 SkRect
    size_t* graphemeCodeUnitRange,  // 2 size_ts: [start, end]
    bool* booleanFlags) {           // 1 boolean: isLTR
  skia::textlayout::Paragraph::GlyphInfo glyphInfo;
  if (!paragraph->skiaParagraph->getClosestUTF16GlyphInfoAt(offsetX, offsetY,
                                                            &glyphInfo)) {
    return false;
  }
  // This is more verbose than memcpying the whole struct but ideally we don't
  // want to depend on the exact memory layout of the struct.
  std::memcpy(graphemeLayoutBounds, &glyphInfo.fGraphemeLayoutBounds,
              sizeof(SkRect));
  std::memcpy(graphemeCodeUnitRange, &glyphInfo.fGraphemeClusterTextRange,
              2 * sizeof(size_t));
  booleanFlags[0] =
      glyphInfo.fDirection == skia::textlayout::TextDirection::kLtr;
  return true;
}

SKWASM_EXPORT bool paragraph_getGlyphInfoAt(
    Paragraph* paragraph,
    size_t index,
    // Out parameters:
    SkRect* graphemeLayoutBounds,   // 1 SkRect
    size_t* graphemeCodeUnitRange,  // 2 size_ts: [start, end]
    bool* booleanFlags) {           // 1 boolean: isLTR
  skia::textlayout::Paragraph::GlyphInfo glyphInfo;
  if (!paragraph->skiaParagraph->getGlyphInfoAtUTF16Offset(index, &glyphInfo)) {
    return false;
  }
  std::memcpy(graphemeLayoutBounds, &glyphInfo.fGraphemeLayoutBounds,
              sizeof(SkRect));
  std::memcpy(graphemeCodeUnitRange, &glyphInfo.fGraphemeClusterTextRange,
              2 * sizeof(size_t));
  booleanFlags[0] =
      glyphInfo.fDirection == skia::textlayout::TextDirection::kLtr;
  return true;
}

SKWASM_EXPORT void paragraph_getWordBoundary(
    Paragraph* paragraph,
    unsigned int position,
    int32_t* outRange  // Two `int32_t`s, start and end
) {
  auto range = paragraph->skiaParagraph->getWordBoundary(position);
  outRange[0] = range.start;
  outRange[1] = range.end;
}

SKWASM_EXPORT size_t paragraph_getLineCount(Paragraph* paragraph) {
  return paragraph->skiaParagraph->lineNumber();
}

SKWASM_EXPORT int paragraph_getLineNumberAt(Paragraph* paragraph,
                                            size_t characterIndex) {
  return paragraph->skiaParagraph->getLineNumberAtUTF16Offset(characterIndex);
}

SKWASM_EXPORT skia::textlayout::LineMetrics* paragraph_getLineMetricsAtIndex(
    Paragraph* paragraph,
    size_t lineNumber) {
  liveLineMetricsCount++;
  auto metrics = new skia::textlayout::LineMetrics();
  if (paragraph->skiaParagraph->getLineMetricsAt(lineNumber, metrics)) {
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
  liveTextBoxListCount--;
  delete list;
}

SKWASM_EXPORT size_t textBoxList_getLength(TextBoxList* list) {
  return list->boxes.size();
}

SKWASM_EXPORT skia::textlayout::TextDirection
textBoxList_getBoxAtIndex(TextBoxList* list, size_t index, SkRect* outRect) {
  const auto& box = list->boxes[index];
  *outRect = box.rect;
  return box.direction;
}

SKWASM_EXPORT TextBoxList* paragraph_getBoxesForRange(
    Paragraph* paragraph,
    int start,
    int end,
    skia::textlayout::RectHeightStyle heightStyle,
    skia::textlayout::RectWidthStyle widthStyle) {
  liveTextBoxListCount++;
  return new TextBoxList{paragraph->skiaParagraph->getRectsForRange(
      start, end, heightStyle, widthStyle)};
}

SKWASM_EXPORT TextBoxList* paragraph_getBoxesForPlaceholders(
    Paragraph* paragraph) {
  liveTextBoxListCount++;
  return new TextBoxList{paragraph->skiaParagraph->getRectsForPlaceholders()};
}

// Returns a list of the code points that were unable to be rendered with the
// selected fonts. The list is deduplicated, so each code point in the output
// is unique.
// If `nullptr` is passed in for `outCodePoints`, we simply return the count
// of the code points.
// Note: This must be called after the paragraph has been laid out at least
// once in order to get valid data.
SKWASM_EXPORT int paragraph_getUnresolvedCodePoints(Paragraph* paragraph,
                                                    SkUnichar* outCodePoints,
                                                    int outLength) {
  if (!outCodePoints) {
    return paragraph->skiaParagraph->unresolvedCodepoints().size();
  }
  int outIndex = 0;
  for (SkUnichar character : paragraph->skiaParagraph->unresolvedCodepoints()) {
    if (outIndex < outLength) {
      outCodePoints[outIndex] = character;
      outIndex++;
    } else {
      break;
    }
  }
  return outIndex;
}

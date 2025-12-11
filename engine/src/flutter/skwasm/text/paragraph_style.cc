// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/text/text_types.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

SKWASM_EXPORT Skwasm::ParagraphStyle* paragraphStyle_create() {
  auto style = new Skwasm::ParagraphStyle();

  // This is the default behavior in Flutter
  style->skia_paragraph_style.setReplaceTabCharacters(true);

  // Default text style has a black color
  style->text_style.skia_style.setColor(SK_ColorBLACK);

  return style;
}

SKWASM_EXPORT void paragraphStyle_dispose(Skwasm::ParagraphStyle* style) {
  delete style;
}

SKWASM_EXPORT void paragraphStyle_setTextAlign(
    Skwasm::ParagraphStyle* style,
    skia::textlayout::TextAlign align) {
  style->skia_paragraph_style.setTextAlign(align);
}

SKWASM_EXPORT void paragraphStyle_setTextDirection(
    Skwasm::ParagraphStyle* style,
    skia::textlayout::TextDirection direction) {
  style->skia_paragraph_style.setTextDirection(direction);
}

SKWASM_EXPORT void paragraphStyle_setMaxLines(Skwasm::ParagraphStyle* style,
                                              size_t max_lines) {
  style->skia_paragraph_style.setMaxLines(max_lines);
}

SKWASM_EXPORT void paragraphStyle_setHeight(Skwasm::ParagraphStyle* style,
                                            SkScalar height) {
  style->skia_paragraph_style.setHeight(height);
}

SKWASM_EXPORT void paragraphStyle_setTextHeightBehavior(
    Skwasm::ParagraphStyle* style,
    bool apply_height_to_first_ascent,
    bool apply_height_to_last_descent) {
  skia::textlayout::TextHeightBehavior behavior;
  if (!apply_height_to_first_ascent && !apply_height_to_last_descent) {
    behavior = skia::textlayout::kDisableAll;
  } else if (!apply_height_to_last_descent) {
    behavior = skia::textlayout::kDisableLastDescent;
  } else if (!apply_height_to_first_ascent) {
    behavior = skia::textlayout::kDisableFirstAscent;
  } else {
    behavior = skia::textlayout::kAll;
  }
  style->skia_paragraph_style.setTextHeightBehavior(behavior);
}

SKWASM_EXPORT void paragraphStyle_setEllipsis(Skwasm::ParagraphStyle* style,
                                              SkString* ellipsis) {
  style->skia_paragraph_style.setEllipsis(*ellipsis);
}

SKWASM_EXPORT void paragraphStyle_setStrutStyle(
    Skwasm::ParagraphStyle* style,
    skia::textlayout::StrutStyle* strut_style) {
  style->skia_paragraph_style.setStrutStyle(*strut_style);
}

SKWASM_EXPORT void paragraphStyle_setTextStyle(Skwasm::ParagraphStyle* style,
                                               Skwasm::TextStyle* text_style) {
  style->text_style = *text_style;
}

SKWASM_EXPORT void paragraphStyle_setApplyRoundingHack(
    Skwasm::ParagraphStyle* style,
    bool apply_rounding_hack) {
  style->skia_paragraph_style.setApplyRoundingHack(apply_rounding_hack);
}

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
  style->skiaParagraphStyle.setReplaceTabCharacters(true);

  // Default text style has a black color
  style->textStyle.skiaStyle.setColor(SK_ColorBLACK);

  return style;
}

SKWASM_EXPORT void paragraphStyle_dispose(Skwasm::ParagraphStyle* style) {
  delete style;
}

SKWASM_EXPORT void paragraphStyle_setTextAlign(
    Skwasm::ParagraphStyle* style,
    skia::textlayout::TextAlign align) {
  style->skiaParagraphStyle.setTextAlign(align);
}

SKWASM_EXPORT void paragraphStyle_setTextDirection(
    Skwasm::ParagraphStyle* style,
    skia::textlayout::TextDirection direction) {
  style->skiaParagraphStyle.setTextDirection(direction);
}

SKWASM_EXPORT void paragraphStyle_setMaxLines(Skwasm::ParagraphStyle* style,
                                              size_t maxLines) {
  style->skiaParagraphStyle.setMaxLines(maxLines);
}

SKWASM_EXPORT void paragraphStyle_setHeight(Skwasm::ParagraphStyle* style,
                                            SkScalar height) {
  style->skiaParagraphStyle.setHeight(height);
}

SKWASM_EXPORT void paragraphStyle_setTextHeightBehavior(
    Skwasm::ParagraphStyle* style,
    bool applyHeightToFirstAscent,
    bool applyHeightToLastDescent) {
  skia::textlayout::TextHeightBehavior behavior;
  if (!applyHeightToFirstAscent && !applyHeightToLastDescent) {
    behavior = skia::textlayout::kDisableAll;
  } else if (!applyHeightToLastDescent) {
    behavior = skia::textlayout::kDisableLastDescent;
  } else if (!applyHeightToFirstAscent) {
    behavior = skia::textlayout::kDisableFirstAscent;
  } else {
    behavior = skia::textlayout::kAll;
  }
  style->skiaParagraphStyle.setTextHeightBehavior(behavior);
}

SKWASM_EXPORT void paragraphStyle_setEllipsis(Skwasm::ParagraphStyle* style,
                                              SkString* ellipsis) {
  style->skiaParagraphStyle.setEllipsis(*ellipsis);
}

SKWASM_EXPORT void paragraphStyle_setStrutStyle(
    Skwasm::ParagraphStyle* style,
    skia::textlayout::StrutStyle* strutStyle) {
  style->skiaParagraphStyle.setStrutStyle(*strutStyle);
}

SKWASM_EXPORT void paragraphStyle_setTextStyle(Skwasm::ParagraphStyle* style,
                                               Skwasm::TextStyle* textStyle) {
  style->textStyle = *textStyle;
}

SKWASM_EXPORT void paragraphStyle_setApplyRoundingHack(
    Skwasm::ParagraphStyle* style,
    bool applyRoundingHack) {
  style->skiaParagraphStyle.setApplyRoundingHack(applyRoundingHack);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "../export.h"
#include "../live_objects.h"
#include "../wrappers.h"
#include "text_types.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

const double kTextHeightNone = 0.0;

using namespace Skwasm;

SKWASM_EXPORT TextStyle* textStyle_create() {
  liveTextStyleCount++;
  auto style = new TextStyle();

  // Default color in flutter is black.
  style->skiaStyle.setColor(SK_ColorBLACK);
  return style;
}

SKWASM_EXPORT TextStyle* textStyle_copy(TextStyle* style) {
  liveTextStyleCount++;
  return new TextStyle(*style);
}

SKWASM_EXPORT void textStyle_dispose(TextStyle* style) {
  liveTextStyleCount--;
  delete style;
}

SKWASM_EXPORT void textStyle_setColor(TextStyle* style, SkColor color) {
  style->skiaStyle.setColor(color);
}

SKWASM_EXPORT void textStyle_setDecoration(
    TextStyle* style,
    skia::textlayout::TextDecoration decoration) {
  style->skiaStyle.setDecoration(decoration);
}

SKWASM_EXPORT void textStyle_setDecorationColor(TextStyle* style,
                                                SkColor color) {
  style->skiaStyle.setDecorationColor(color);
}

SKWASM_EXPORT void textStyle_setDecorationStyle(
    TextStyle* style,
    skia::textlayout::TextDecorationStyle decorationStyle) {
  style->skiaStyle.setDecorationStyle(decorationStyle);
}

SKWASM_EXPORT void textStyle_setDecorationThickness(TextStyle* style,
                                                    SkScalar thickness) {
  style->skiaStyle.setDecorationThicknessMultiplier(thickness);
}

SKWASM_EXPORT void textStyle_setFontStyle(TextStyle* style,
                                          int weight,
                                          SkFontStyle::Slant slant) {
  style->skiaStyle.setFontStyle(
      SkFontStyle(weight, SkFontStyle::kNormal_Width, slant));
}

SKWASM_EXPORT void textStyle_setTextBaseline(
    TextStyle* style,
    skia::textlayout::TextBaseline baseline) {
  style->skiaStyle.setTextBaseline(baseline);
}

SKWASM_EXPORT void textStyle_clearFontFamilies(TextStyle* style) {
  style->skiaStyle.setFontFamilies({});
}

SKWASM_EXPORT void textStyle_addFontFamilies(TextStyle* style,
                                             SkString** fontFamilies,
                                             int count) {
  const std::vector<SkString>& currentFamilies =
      style->skiaStyle.getFontFamilies();
  std::vector<SkString> newFamilies;
  newFamilies.reserve(currentFamilies.size() + count);
  for (int i = 0; i < count; i++) {
    newFamilies.push_back(*fontFamilies[i]);
  }
  for (const auto& family : currentFamilies) {
    newFamilies.push_back(family);
  }
  style->skiaStyle.setFontFamilies(std::move(newFamilies));
}

SKWASM_EXPORT void textStyle_setFontSize(TextStyle* style, SkScalar size) {
  style->skiaStyle.setFontSize(size);
}

SKWASM_EXPORT void textStyle_setLetterSpacing(TextStyle* style,
                                              SkScalar letterSpacing) {
  style->skiaStyle.setLetterSpacing(letterSpacing);
}

SKWASM_EXPORT void textStyle_setWordSpacing(TextStyle* style,
                                            SkScalar wordSpacing) {
  style->skiaStyle.setWordSpacing(wordSpacing);
}

SKWASM_EXPORT void textStyle_setHeight(TextStyle* style, SkScalar height) {
  style->skiaStyle.setHeight(height);
  style->skiaStyle.setHeightOverride(height != kTextHeightNone);
}

SKWASM_EXPORT void textStyle_setHalfLeading(TextStyle* style,
                                            bool halfLeading) {
  style->skiaStyle.setHalfLeading(halfLeading);
}

SKWASM_EXPORT void textStyle_setLocale(TextStyle* style, SkString* locale) {
  style->skiaStyle.setLocale(*locale);
}

SKWASM_EXPORT void textStyle_setBackground(TextStyle* style,
                                           flutter::DlPaint* paint) {
  style->background = *paint;
}

SKWASM_EXPORT void textStyle_setForeground(TextStyle* style,
                                           flutter::DlPaint* paint) {
  style->foreground = *paint;
}

SKWASM_EXPORT void textStyle_addShadow(TextStyle* style,
                                       SkColor color,
                                       SkScalar offsetX,
                                       SkScalar offsetY,
                                       SkScalar blurSigma) {
  style->skiaStyle.addShadow(
      skia::textlayout::TextShadow(color, {offsetX, offsetY}, blurSigma));
}

SKWASM_EXPORT void textStyle_addFontFeature(TextStyle* style,
                                            SkString* featureName,
                                            int value) {
  style->skiaStyle.addFontFeature(*featureName, value);
}

SKWASM_EXPORT void textStyle_setFontVariations(TextStyle* style,
                                               SkFourByteTag* axes,
                                               float* values,
                                               int count) {
  std::vector<SkFontArguments::VariationPosition::Coordinate> coordinates;
  for (int i = 0; i < count; i++) {
    coordinates.push_back({axes[i], values[i]});
  }
  SkFontArguments::VariationPosition position = {
      coordinates.data(), static_cast<int>(coordinates.size())};
  style->skiaStyle.setFontArguments(
      SkFontArguments().setVariationDesignPosition(position));
}

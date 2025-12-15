// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "flutter/display_list/dl_paint.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/text/text_types.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

const double kTextHeightNone = 0.0;

SKWASM_EXPORT Skwasm::TextStyle* textStyle_create() {
  Skwasm::live_text_style_count++;
  auto style = new Skwasm::TextStyle();

  // Default color in flutter is black.
  style->skia_style.setColor(SK_ColorBLACK);
  return style;
}

SKWASM_EXPORT Skwasm::TextStyle* textStyle_copy(Skwasm::TextStyle* style) {
  Skwasm::live_text_style_count++;
  return new Skwasm::TextStyle(*style);
}

SKWASM_EXPORT void textStyle_dispose(Skwasm::TextStyle* style) {
  Skwasm::live_text_style_count--;
  delete style;
}

SKWASM_EXPORT void textStyle_setColor(Skwasm::TextStyle* style, SkColor color) {
  style->skia_style.setColor(color);
}

SKWASM_EXPORT void textStyle_setDecoration(
    Skwasm::TextStyle* style,
    skia::textlayout::TextDecoration decoration) {
  style->skia_style.setDecoration(decoration);
}

SKWASM_EXPORT void textStyle_setDecorationColor(Skwasm::TextStyle* style,
                                                SkColor color) {
  style->skia_style.setDecorationColor(color);
}

SKWASM_EXPORT void textStyle_setDecorationStyle(
    Skwasm::TextStyle* style,
    skia::textlayout::TextDecorationStyle decoration_style) {
  style->skia_style.setDecorationStyle(decoration_style);
}

SKWASM_EXPORT void textStyle_setDecorationThickness(Skwasm::TextStyle* style,
                                                    SkScalar thickness) {
  style->skia_style.setDecorationThicknessMultiplier(thickness);
}

SKWASM_EXPORT void textStyle_setFontStyle(Skwasm::TextStyle* style,
                                          int weight,
                                          SkFontStyle::Slant slant) {
  style->skia_style.setFontStyle(
      SkFontStyle(weight, SkFontStyle::kNormal_Width, slant));
}

SKWASM_EXPORT void textStyle_setTextBaseline(
    Skwasm::TextStyle* style,
    skia::textlayout::TextBaseline baseline) {
  style->skia_style.setTextBaseline(baseline);
}

SKWASM_EXPORT void textStyle_clearFontFamilies(Skwasm::TextStyle* style) {
  style->skia_style.setFontFamilies({});
}

SKWASM_EXPORT void textStyle_addFontFamilies(Skwasm::TextStyle* style,
                                             SkString** font_families,
                                             int count) {
  const std::vector<SkString>& current_families =
      style->skia_style.getFontFamilies();
  std::vector<SkString> new_families;
  new_families.reserve(current_families.size() + count);
  for (int i = 0; i < count; i++) {
    new_families.push_back(*font_families[i]);
  }
  for (const auto& family : current_families) {
    new_families.push_back(family);
  }
  style->skia_style.setFontFamilies(std::move(new_families));
}

SKWASM_EXPORT void textStyle_setFontSize(Skwasm::TextStyle* style,
                                         SkScalar size) {
  style->skia_style.setFontSize(size);
}

SKWASM_EXPORT void textStyle_setLetterSpacing(Skwasm::TextStyle* style,
                                              SkScalar letter_spacing) {
  style->skia_style.setLetterSpacing(letter_spacing);
}

SKWASM_EXPORT void textStyle_setWordSpacing(Skwasm::TextStyle* style,
                                            SkScalar word_spacing) {
  style->skia_style.setWordSpacing(word_spacing);
}

SKWASM_EXPORT void textStyle_setHeight(Skwasm::TextStyle* style,
                                       SkScalar height) {
  style->skia_style.setHeight(height);
  style->skia_style.setHeightOverride(height != kTextHeightNone);
}

SKWASM_EXPORT void textStyle_setHalfLeading(Skwasm::TextStyle* style,
                                            bool half_leading) {
  style->skia_style.setHalfLeading(half_leading);
}

SKWASM_EXPORT void textStyle_setLocale(Skwasm::TextStyle* style,
                                       SkString* locale) {
  style->skia_style.setLocale(*locale);
}

SKWASM_EXPORT void textStyle_setBackground(Skwasm::TextStyle* style,
                                           flutter::DlPaint* paint) {
  style->background = *paint;
}

SKWASM_EXPORT void textStyle_setForeground(Skwasm::TextStyle* style,
                                           flutter::DlPaint* paint) {
  style->foreground = *paint;
}

SKWASM_EXPORT void textStyle_addShadow(Skwasm::TextStyle* style,
                                       SkColor color,
                                       SkScalar offset_x,
                                       SkScalar offset_y,
                                       SkScalar blur_sigma) {
  style->skia_style.addShadow(
      skia::textlayout::TextShadow(color, {offset_x, offset_y}, blur_sigma));
}

SKWASM_EXPORT void textStyle_addFontFeature(Skwasm::TextStyle* style,
                                            SkString* feature_name,
                                            int value) {
  style->skia_style.addFontFeature(*feature_name, value);
}

SKWASM_EXPORT void textStyle_setFontVariations(Skwasm::TextStyle* style,
                                               SkFourByteTag* axes,
                                               float* values,
                                               int count) {
  std::vector<SkFontArguments::VariationPosition::Coordinate> coordinates;
  for (int i = 0; i < count; i++) {
    coordinates.push_back({axes[i], values[i]});
  }
  SkFontArguments::VariationPosition position = {
      coordinates.data(), static_cast<int>(coordinates.size())};
  style->skia_style.setFontArguments(
      SkFontArguments().setVariationDesignPosition(position));
}

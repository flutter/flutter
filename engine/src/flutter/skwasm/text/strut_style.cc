// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

SKWASM_EXPORT skia::textlayout::StrutStyle* strutStyle_create() {
  Skwasm::live_strut_style_count++;
  auto style = new skia::textlayout::StrutStyle();
  style->setStrutEnabled(true);
  return style;
}

SKWASM_EXPORT void strutStyle_dispose(skia::textlayout::StrutStyle* style) {
  Skwasm::live_strut_style_count--;
  delete style;
}

SKWASM_EXPORT void strutStyle_setFontFamilies(
    skia::textlayout::StrutStyle* style,
    SkString** font_families,
    int count) {
  std::vector<SkString> families;
  families.reserve(count);
  for (int i = 0; i < count; i++) {
    families.push_back(*font_families[i]);
  }
  style->setFontFamilies(std::move(families));
}

SKWASM_EXPORT void strutStyle_setFontSize(skia::textlayout::StrutStyle* style,
                                          SkScalar font_size) {
  style->setFontSize(font_size);
}

SKWASM_EXPORT void strutStyle_setHeight(skia::textlayout::StrutStyle* style,
                                        SkScalar height) {
  style->setHeight(height);
  style->setHeightOverride(true);
}

SKWASM_EXPORT void strutStyle_setHalfLeading(
    skia::textlayout::StrutStyle* style,
    bool half_leading) {
  style->setHalfLeading(half_leading);
}

SKWASM_EXPORT void strutStyle_setLeading(skia::textlayout::StrutStyle* style,
                                         SkScalar leading) {
  style->setLeading(leading);
}

SKWASM_EXPORT void strutStyle_setFontStyle(skia::textlayout::StrutStyle* style,
                                           int weight,
                                           SkFontStyle::Slant slant) {
  style->setFontStyle(SkFontStyle(weight, SkFontStyle::kNormal_Width, slant));
}

SKWASM_EXPORT void strutStyle_setForceStrutHeight(
    skia::textlayout::StrutStyle* style,
    bool force_strut_height) {
  style->setForceStrutHeight(force_strut_height);
}

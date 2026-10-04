// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/text/text_types.h"
#include "flutter/skwasm/wrappers.h"
#include "modules/skunicode/include/SkUnicode_icu.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"

SKWASM_EXPORT bool skwasm_isHeavy() {
  return true;
}

SKWASM_EXPORT Skwasm::ParagraphBuilder* paragraphBuilder_create(
    Skwasm::ParagraphStyle* style,
    Skwasm::FlutterFontCollection* collection) {
  Skwasm::live_paragraph_builder_count++;
  std::vector<flutter::DlPaint> paints;
  style->text_style.PopulatePaintIds(paints);
  style->skia_paragraph_style.setTextStyle(style->text_style.skia_style);
  return new Skwasm::ParagraphBuilder{
      skia::textlayout::ParagraphBuilder::make(style->skia_paragraph_style,
                                               collection->collection,
                                               SkUnicodes::ICU::Make()),
      std::move(paints)};
}

SKWASM_EXPORT Skwasm::Paragraph* paragraphBuilder_build(
    Skwasm::ParagraphBuilder* builder) {
  Skwasm::live_paragraph_count++;
  return new Skwasm::Paragraph{builder->skia_paragraph_builder->Build(),
                               std::move(builder->paints)};
}

SKWASM_EXPORT void paragraphBuilder_setGraphemeBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  emscripten_console_warn(
      "warning: setGraphemeBreaksUtf16 not implemented in skwasm_heavy\n");
}

SKWASM_EXPORT void paragraphBuilder_setWordBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  emscripten_console_warn(
      "warning: setWordBreaksUtf16 not implemented in skwasm_heavy\n");
}

SKWASM_EXPORT void paragraphBuilder_setLineBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::LineBreakBefore>* breaks) {
  emscripten_console_warn(
      "warning: setLineBreaksUtf16 not implemented in skwasm_heavy\n");
}

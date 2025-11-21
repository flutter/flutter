// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "../export.h"
#include "../live_objects.h"
#include "../wrappers.h"
#include "modules/skunicode/include/SkUnicode_icu.h"
#include "text_types.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"

using namespace Skwasm;

SKWASM_EXPORT bool skwasm_isHeavy() {
  return true;
}

SKWASM_EXPORT ParagraphBuilder* paragraphBuilder_create(
    ParagraphStyle* style,
    FlutterFontCollection* collection) {
  liveParagraphBuilderCount++;
  std::vector<flutter::DlPaint> paints;
  style->textStyle.populatePaintIds(paints);
  style->skiaParagraphStyle.setTextStyle(style->textStyle.skiaStyle);
  return new ParagraphBuilder{
      skia::textlayout::ParagraphBuilder::make(style->skiaParagraphStyle,
                                               collection->collection,
                                               SkUnicodes::ICU::Make()),
      std::move(paints)};
}

SKWASM_EXPORT Paragraph* paragraphBuilder_build(ParagraphBuilder* builder) {
  liveParagraphCount++;
  return new Paragraph{builder->skiaParagraphBuilder->Build(),
                       std::move(builder->paints)};
}

SKWASM_EXPORT void paragraphBuilder_setGraphemeBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  emscripten_console_warn(
      "warning: setGraphemeBreaksUtf16 not implemented in skwasm_heavy\n");
}

SKWASM_EXPORT void paragraphBuilder_setWordBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  emscripten_console_warn(
      "warning: setWordBreaksUtf16 not implemented in skwasm_heavy\n");
}

SKWASM_EXPORT void paragraphBuilder_setLineBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::LineBreakBefore>* breaks) {
  emscripten_console_warn(
      "warning: setLineBreaksUtf16 not implemented in skwasm_heavy\n");
}

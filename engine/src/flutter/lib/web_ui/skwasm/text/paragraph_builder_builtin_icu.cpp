// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "../export.h"
#include "../live_objects.h"
#include "../wrappers.h"
#include "modules/skunicode/include/SkUnicode_icu.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"

using namespace skia::textlayout;
using namespace Skwasm;

SKWASM_EXPORT bool skwasm_isHeavy() {
  return true;
}

SKWASM_EXPORT ParagraphBuilder* paragraphBuilder_create(
    ParagraphStyle* style,
    FlutterFontCollection* collection) {
  liveParagraphBuilderCount++;
  return ParagraphBuilder::make(*style, collection->collection,
                                SkUnicodes::ICU::Make())
      .release();
}

SKWASM_EXPORT Paragraph* paragraphBuilder_build(ParagraphBuilder* builder) {
  liveParagraphCount++;
  return builder->Build().release();
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

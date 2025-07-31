// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "../export.h"
#include "../live_objects.h"
#include "../wrappers.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"
#include "third_party/skia/modules/skunicode/include/SkUnicode_client.h"

using namespace skia::textlayout;
using namespace Skwasm;

SKWASM_EXPORT bool skwasm_isHeavy() {
  return false;
}

SKWASM_EXPORT ParagraphBuilder* paragraphBuilder_create(
    ParagraphStyle* style,
    FlutterFontCollection* collection) {
  liveParagraphBuilderCount++;
  return ParagraphBuilder::make(*style, collection->collection, nullptr)
      .release();
}

SKWASM_EXPORT Paragraph* paragraphBuilder_build(ParagraphBuilder* builder) {
  liveParagraphCount++;
  auto [words, graphemeBreaks, lineBreaks] = builder->getClientICUData();
  auto text = builder->getText();
  sk_sp<SkUnicode> clientICU =
      SkUnicodes::Client::Make(text, words, graphemeBreaks, lineBreaks);
  builder->SetUnicode(clientICU);
  return builder->Build().release();
}

SKWASM_EXPORT void paragraphBuilder_setGraphemeBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->setGraphemeBreaksUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setWordBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->setWordsUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setLineBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::LineBreakBefore>* breaks) {
  builder->setLineBreaksUtf16(std::move(*breaks));
}

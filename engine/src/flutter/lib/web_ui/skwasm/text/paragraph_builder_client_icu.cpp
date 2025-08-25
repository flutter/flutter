// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "../export.h"
#include "../live_objects.h"
#include "../wrappers.h"
#include "text_types.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"
#include "third_party/skia/modules/skunicode/include/SkUnicode_client.h"

using namespace Skwasm;

SKWASM_EXPORT bool skwasm_isHeavy() {
  return false;
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
                                               collection->collection, nullptr),
      std::move(paints),
  };
}

SKWASM_EXPORT Paragraph* paragraphBuilder_build(ParagraphBuilder* builder) {
  liveParagraphCount++;
  auto [words, graphemeBreaks, lineBreaks] =
      builder->skiaParagraphBuilder->getClientICUData();
  auto text = builder->skiaParagraphBuilder->getText();
  sk_sp<SkUnicode> clientICU =
      SkUnicodes::Client::Make(text, words, graphemeBreaks, lineBreaks);
  builder->skiaParagraphBuilder->SetUnicode(clientICU);
  return new Paragraph{
      builder->skiaParagraphBuilder->Build(),
      std::move(builder->paints),
  };
}

SKWASM_EXPORT void paragraphBuilder_setGraphemeBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->skiaParagraphBuilder->setGraphemeBreaksUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setWordBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->skiaParagraphBuilder->setWordsUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setLineBreaksUtf16(
    ParagraphBuilder* builder,
    std::vector<SkUnicode::LineBreakBefore>* breaks) {
  builder->skiaParagraphBuilder->setLineBreaksUtf16(std::move(*breaks));
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/text/text_types.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"
#include "third_party/skia/modules/skunicode/include/SkUnicode_client.h"

SKWASM_EXPORT bool skwasm_isHeavy() {
  return false;
}

SKWASM_EXPORT Skwasm::ParagraphBuilder* paragraphBuilder_create(
    Skwasm::ParagraphStyle* style,
    Skwasm::FlutterFontCollection* collection) {
  Skwasm::liveParagraphBuilderCount++;
  std::vector<flutter::DlPaint> paints;
  style->textStyle.populatePaintIds(paints);
  style->skiaParagraphStyle.setTextStyle(style->textStyle.skiaStyle);
  return new Skwasm::ParagraphBuilder{
      skia::textlayout::ParagraphBuilder::make(style->skiaParagraphStyle,
                                               collection->collection, nullptr),
      std::move(paints),
  };
}

SKWASM_EXPORT Skwasm::Paragraph* paragraphBuilder_build(
    Skwasm::ParagraphBuilder* builder) {
  Skwasm::liveParagraphCount++;
  auto [words, graphemeBreaks, lineBreaks] =
      builder->skiaParagraphBuilder->getClientICUData();
  auto text = builder->skiaParagraphBuilder->getText();
  sk_sp<SkUnicode> clientICU =
      SkUnicodes::Client::Make(text, words, graphemeBreaks, lineBreaks);
  builder->skiaParagraphBuilder->SetUnicode(clientICU);
  return new Skwasm::Paragraph{
      builder->skiaParagraphBuilder->Build(),
      std::move(builder->paints),
  };
}

SKWASM_EXPORT void paragraphBuilder_setGraphemeBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->skiaParagraphBuilder->setGraphemeBreaksUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setWordBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->skiaParagraphBuilder->setWordsUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setLineBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::LineBreakBefore>* breaks) {
  builder->skiaParagraphBuilder->setLineBreaksUtf16(std::move(*breaks));
}

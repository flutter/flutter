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
  Skwasm::live_paragraph_builder_count++;
  std::vector<flutter::DlPaint> paints;
  style->text_style.PopulatePaintIds(paints);
  style->skia_paragraph_style.setTextStyle(style->text_style.skia_style);
  return new Skwasm::ParagraphBuilder{
      skia::textlayout::ParagraphBuilder::make(style->skia_paragraph_style,
                                               collection->collection, nullptr),
      std::move(paints),
  };
}

SKWASM_EXPORT Skwasm::Paragraph* paragraphBuilder_build(
    Skwasm::ParagraphBuilder* builder) {
  Skwasm::live_paragraph_count++;
  auto [words, grapheme_breaks, line_breaks] =
      builder->skia_paragraph_builder->getClientICUData();
  auto text = builder->skia_paragraph_builder->getText();
  sk_sp<SkUnicode> client_icu =
      SkUnicodes::Client::Make(text, words, grapheme_breaks, line_breaks);
  builder->skia_paragraph_builder->SetUnicode(client_icu);
  return new Skwasm::Paragraph{
      builder->skia_paragraph_builder->Build(),
      std::move(builder->paints),
  };
}

SKWASM_EXPORT void paragraphBuilder_setGraphemeBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->skia_paragraph_builder->setGraphemeBreaksUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setWordBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::Position>* breaks) {
  builder->skia_paragraph_builder->setWordsUtf16(std::move(*breaks));
}

SKWASM_EXPORT void paragraphBuilder_setLineBreaksUtf16(
    Skwasm::ParagraphBuilder* builder,
    std::vector<SkUnicode::LineBreakBefore>* breaks) {
  builder->skia_paragraph_builder->setLineBreaksUtf16(std::move(*breaks));
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/text/text_types.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"
#include "third_party/skia/modules/skunicode/include/SkUnicode_client.h"

SKWASM_EXPORT void paragraphBuilder_dispose(Skwasm::ParagraphBuilder* builder) {
  Skwasm::liveParagraphBuilderCount--;
  delete builder;
}

SKWASM_EXPORT void paragraphBuilder_addPlaceholder(
    Skwasm::ParagraphBuilder* builder,
    SkScalar width,
    SkScalar height,
    skia::textlayout::PlaceholderAlignment alignment,
    SkScalar baselineOffset,
    skia::textlayout::TextBaseline baseline) {
  builder->skiaParagraphBuilder->addPlaceholder(
      skia::textlayout::PlaceholderStyle(width, height, alignment, baseline,
                                         baselineOffset));
}

SKWASM_EXPORT void paragraphBuilder_addText(Skwasm::ParagraphBuilder* builder,
                                            std::u16string* text) {
  builder->skiaParagraphBuilder->addText(*text);
}

SKWASM_EXPORT char* paragraphBuilder_getUtf8Text(
    Skwasm::ParagraphBuilder* builder,
    uint32_t* outLength) {
  auto span = builder->skiaParagraphBuilder->getText();
  *outLength = span.size();
  return span.data();
}

SKWASM_EXPORT void paragraphBuilder_pushStyle(Skwasm::ParagraphBuilder* builder,
                                              Skwasm::TextStyle* style) {
  style->populatePaintIds(builder->paints);
  builder->skiaParagraphBuilder->pushStyle(style->skiaStyle);
}

SKWASM_EXPORT void paragraphBuilder_pop(Skwasm::ParagraphBuilder* builder) {
  builder->skiaParagraphBuilder->pop();
}

SKWASM_EXPORT std::vector<SkUnicode::Position>* unicodePositionBuffer_create(
    size_t length) {
  Skwasm::liveUnicodePositionBufferCount++;
  return new std::vector<SkUnicode::Position>(length);
}

SKWASM_EXPORT SkUnicode::Position* unicodePositionBuffer_getDataPointer(
    std::vector<SkUnicode::Position>* buffer) {
  return buffer->data();
}

SKWASM_EXPORT void unicodePositionBuffer_free(
    std::vector<SkUnicode::Position>* buffer) {
  Skwasm::liveUnicodePositionBufferCount--;
  delete buffer;
}

SKWASM_EXPORT std::vector<SkUnicode::LineBreakBefore>* lineBreakBuffer_create(
    size_t length) {
  Skwasm::liveLineBreakBufferCount++;
  return new std::vector<SkUnicode::LineBreakBefore>(
      length, {0, SkUnicode::LineBreakType::kSoftLineBreak});
}

SKWASM_EXPORT SkUnicode::LineBreakBefore* lineBreakBuffer_getDataPointer(
    std::vector<SkUnicode::LineBreakBefore>* buffer) {
  return buffer->data();
}

SKWASM_EXPORT void lineBreakBuffer_free(
    std::vector<SkUnicode::LineBreakBefore>* buffer) {
  Skwasm::liveLineBreakBufferCount--;
  delete buffer;
}

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
  Skwasm::live_paragraph_builder_count--;
  delete builder;
}

SKWASM_EXPORT void paragraphBuilder_addPlaceholder(
    Skwasm::ParagraphBuilder* builder,
    SkScalar width,
    SkScalar height,
    skia::textlayout::PlaceholderAlignment alignment,
    SkScalar baseline_offset,
    skia::textlayout::TextBaseline baseline) {
  builder->skia_paragraph_builder->addPlaceholder(
      skia::textlayout::PlaceholderStyle(width, height, alignment, baseline,
                                         baseline_offset));
}

SKWASM_EXPORT void paragraphBuilder_addText(Skwasm::ParagraphBuilder* builder,
                                            std::u16string* text) {
  builder->skia_paragraph_builder->addText(*text);
}

SKWASM_EXPORT char* paragraphBuilder_getUtf8Text(
    Skwasm::ParagraphBuilder* builder,
    uint32_t* out_length) {
  auto span = builder->skia_paragraph_builder->getText();
  *out_length = span.size();
  return span.data();
}

SKWASM_EXPORT void paragraphBuilder_pushStyle(Skwasm::ParagraphBuilder* builder,
                                              Skwasm::TextStyle* style) {
  style->PopulatePaintIds(builder->paints);
  builder->skia_paragraph_builder->pushStyle(style->skia_style);
}

SKWASM_EXPORT void paragraphBuilder_pop(Skwasm::ParagraphBuilder* builder) {
  builder->skia_paragraph_builder->pop();
}

SKWASM_EXPORT std::vector<SkUnicode::Position>* unicodePositionBuffer_create(
    size_t length) {
  Skwasm::live_unicode_position_buffer_count++;
  return new std::vector<SkUnicode::Position>(length);
}

SKWASM_EXPORT SkUnicode::Position* unicodePositionBuffer_getDataPointer(
    std::vector<SkUnicode::Position>* buffer) {
  return buffer->data();
}

SKWASM_EXPORT void unicodePositionBuffer_free(
    std::vector<SkUnicode::Position>* buffer) {
  Skwasm::live_unicode_position_buffer_count--;
  delete buffer;
}

SKWASM_EXPORT std::vector<SkUnicode::LineBreakBefore>* lineBreakBuffer_create(
    size_t length) {
  Skwasm::live_line_break_buffer_count++;
  return new std::vector<SkUnicode::LineBreakBefore>(
      length, {0, SkUnicode::LineBreakType::kSoftLineBreak});
}

SKWASM_EXPORT SkUnicode::LineBreakBefore* lineBreakBuffer_getDataPointer(
    std::vector<SkUnicode::LineBreakBefore>* buffer) {
  return buffer->data();
}

SKWASM_EXPORT void lineBreakBuffer_free(
    std::vector<SkUnicode::LineBreakBefore>* buffer) {
  Skwasm::live_line_break_buffer_count--;
  delete buffer;
}

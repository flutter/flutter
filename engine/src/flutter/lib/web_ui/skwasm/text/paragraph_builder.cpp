// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "../export.h"
#include "../wrappers.h"
#include "third_party/skia/modules/skparagraph/include/ParagraphBuilder.h"

using namespace skia::textlayout;
using namespace Skwasm;

SKWASM_EXPORT ParagraphBuilder* paragraphBuilder_create(
    ParagraphStyle* style,
    FlutterFontCollection* collection) {
  return ParagraphBuilder::make(*style, collection->collection).release();
}

SKWASM_EXPORT void paragraphBuilder_dispose(ParagraphBuilder* builder) {
  delete builder;
}

SKWASM_EXPORT void paragraphBuilder_addPlaceholder(
    ParagraphBuilder* builder,
    SkScalar width,
    SkScalar height,
    PlaceholderAlignment alignment,
    SkScalar baselineOffset,
    TextBaseline baseline) {
  builder->addPlaceholder(
      PlaceholderStyle(width, height, alignment, baseline, baselineOffset));
}

SKWASM_EXPORT void paragraphBuilder_addText(ParagraphBuilder* builder,
                                            std::u16string* text) {
  builder->addText(*text);
}

SKWASM_EXPORT void paragraphBuilder_pushStyle(ParagraphBuilder* builder,
                                              TextStyle* style) {
  builder->pushStyle(*style);
}

SKWASM_EXPORT void paragraphBuilder_pop(ParagraphBuilder* builder) {
  builder->pop();
}

SKWASM_EXPORT Paragraph* paragraphBuilder_build(ParagraphBuilder* builder) {
  return builder->Build().release();
}

/*
 * Copyright 2017 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "flutter/fml/logging.h"
#include "flutter/third_party/txt/tests/txt_test_utils.h"
#include "third_party/benchmark/include/benchmark/benchmark.h"
#include "third_party/icu/source/common/unicode/unistr.h"
#include "third_party/skia/include/core/SkColor.h"
#include "txt/font_collection.h"
#include "txt/font_style.h"
#include "txt/font_weight.h"
#include "txt/paragraph.h"
#include "txt/paragraph_builder_txt.h"

namespace txt {

static void BM_ParagraphBuilderConstruction(benchmark::State& state) {
  txt::ParagraphStyle paragraph_style;
  auto font_collection = GetTestFontCollection();
  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
  }
}
BENCHMARK(BM_ParagraphBuilderConstruction);

static void BM_ParagraphBuilderPushStyle(benchmark::State& state) {
  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = GetTestFontCollection();
  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
    builder.PushStyle(text_style);
  }
}
BENCHMARK(BM_ParagraphBuilderPushStyle);

static void BM_ParagraphBuilderPushPop(benchmark::State& state) {
  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  while (state.KeepRunning()) {
    builder.PushStyle(text_style);
    builder.Pop();
  }
}
BENCHMARK(BM_ParagraphBuilderPushPop);

static void BM_ParagraphBuilderAddTextString(benchmark::State& state) {
  std::u16string text = u"Hello World";

  auto font_collection = GetTestFontCollection();

  txt::ParagraphStyle paragraph_style;

  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
    builder.AddText(text);
  }
}
BENCHMARK(BM_ParagraphBuilderAddTextString);

static void BM_ParagraphBuilderAddTextChar(benchmark::State& state) {
  std::u16string text = u"Hello World";

  txt::ParagraphStyle paragraph_style;
  auto font_collection = GetTestFontCollection();
  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
    builder.AddText(text);
  }
}
BENCHMARK(BM_ParagraphBuilderAddTextChar);

static void BM_ParagraphBuilderAddTextU16stringShort(benchmark::State& state) {
  const char* text = "H";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  auto font_collection = GetTestFontCollection();
  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
    builder.AddText(u16_text);
  }
}
BENCHMARK(BM_ParagraphBuilderAddTextU16stringShort);

static void BM_ParagraphBuilderAddTextU16stringLong(benchmark::State& state) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are necessary. Very short. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  auto font_collection = GetTestFontCollection();

  txt::ParagraphStyle paragraph_style;

  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
    builder.AddText(u16_text);
  }
}
BENCHMARK(BM_ParagraphBuilderAddTextU16stringLong);

static void BM_ParagraphBuilderShortParagraphConstruct(
    benchmark::State& state) {
  const char* text = "Hello World";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = GetTestFontCollection();
  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
    builder.PushStyle(text_style);
    builder.AddText(u16_text);
    builder.Pop();
    auto paragraph = builder.Build();
  }
}
BENCHMARK(BM_ParagraphBuilderShortParagraphConstruct);

static void BM_ParagraphBuilderLongParagraphConstruct(benchmark::State& state) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are necessary. Very short. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = GetTestFontCollection();
  while (state.KeepRunning()) {
    txt::ParagraphBuilderTxt builder(paragraph_style, font_collection);
    builder.PushStyle(text_style);
    builder.AddText(u16_text);
    builder.Pop();
    auto paragraph = builder.Build();
  }
}
BENCHMARK(BM_ParagraphBuilderLongParagraphConstruct);

}  // namespace txt

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

#include "third_party/benchmark/include/benchmark/benchmark_api.h"

#include <minikin/Layout.h>
#include "lib/ftl/command_line.h"
#include "lib/ftl/logging.h"
#include "lib/txt/libs/minikin/LayoutUtils.h"
#include "lib/txt/src/font_collection.h"
#include "lib/txt/src/font_skia.h"
#include "lib/txt/src/font_style.h"
#include "lib/txt/src/font_weight.h"
#include "lib/txt/src/paragraph.h"
#include "lib/txt/src/paragraph_builder.h"
#include "lib/txt/src/text_align.h"
#include "third_party/icu/source/common/unicode/unistr.h"
#include "third_party/skia/include/core/SkColor.h"
#include "utils.h"

namespace txt {

static void BM_ParagraphShortLayout(benchmark::State& state) {
  const char* text = "Hello World";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = FontCollection::GetFontCollection(txt::GetFontDir());
  txt::ParagraphBuilder builder(paragraph_style, &font_collection);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = builder.Build();
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300, true);
  }
}
BENCHMARK(BM_ParagraphShortLayout);

static void BM_ParagraphLongLayout(benchmark::State& state) {
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
  auto font_collection = FontCollection::GetFontCollection(txt::GetFontDir());
  txt::ParagraphBuilder builder(paragraph_style, &font_collection);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = builder.Build();
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300, true);
  }
}
BENCHMARK(BM_ParagraphLongLayout);

static void BM_ParagraphJustifyLayout(benchmark::State& state) {
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
  paragraph_style.text_align = TextAlign::justify;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = FontCollection::GetFontCollection(txt::GetFontDir());
  txt::ParagraphBuilder builder(paragraph_style, &font_collection);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = builder.Build();
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300, true);
  }
}
BENCHMARK(BM_ParagraphJustifyLayout);

static void BM_ParagraphManyStylesLayout(benchmark::State& state) {
  const char* text = "-";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = FontCollection::GetFontCollection(txt::GetFontDir());
  txt::ParagraphBuilder builder(paragraph_style, &font_collection);
  for (int i = 0; i < 1000; ++i) {
    builder.PushStyle(text_style);
    builder.AddText(u16_text);
  }
  auto paragraph = builder.Build();
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300, true);
  }
}
BENCHMARK(BM_ParagraphManyStylesLayout);

static void BM_ParagraphTextBigO(benchmark::State& state) {
  std::vector<uint16_t> text;
  for (uint16_t i = 0; i < state.range(0); ++i) {
    text.push_back(i % 5 == 0 ? ' ' : i);
  }
  std::u16string u16_text(text.data(), text.data() + text.size());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = FontCollection::GetFontCollection(txt::GetFontDir());

  txt::ParagraphBuilder builder(paragraph_style, &font_collection);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = builder.Build();
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300, true);
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK(BM_ParagraphTextBigO)
    ->RangeMultiplier(4)
    ->Range(1 << 6, 1 << 14)
    ->Complexity(benchmark::oN);

static void BM_ParagraphStylesBigO(benchmark::State& state) {
  const char* text = "vry shrt ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  auto font_collection = FontCollection::GetFontCollection(txt::GetFontDir());
  txt::ParagraphBuilder builder(paragraph_style, &font_collection);

  for (int i = 0; i < state.range(0); ++i) {
    builder.PushStyle(text_style);
    builder.AddText(u16_text);
  }
  auto paragraph = builder.Build();
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300, true);
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK(BM_ParagraphStylesBigO)
    ->RangeMultiplier(4)
    ->Range(1 << 3, 1 << 12)
    ->Complexity(benchmark::oN);

// -----------------------------------------------------------------------------
//
// The following benchmarks break down the layout function and attempts to time
// each of the components to more finely attribute latency.
//
// -----------------------------------------------------------------------------

static void BM_ParagraphMinikinDoLayout(benchmark::State& state) {
  std::vector<uint16_t> text;
  for (uint16_t i = 0; i < state.range(0) * 3; ++i) {
    text.push_back(i % 5 == 0 ? ' ' : i);
  }
  minikin::FontStyle font;
  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  minikin::MinikinPaint paint;

  font = minikin::FontStyle(4, false);
  paint.size = text_style.font_size;
  paint.letterSpacing = text_style.letter_spacing;
  paint.wordSpacing = text_style.word_spacing;

  auto collection =
      FontCollection::GetFontCollection(txt::GetFontDir())
          .GetMinikinFontCollectionForFamily(text_style.font_family);

  while (state.KeepRunning()) {
    minikin::Layout layout;
    layout.doLayout(text.data(), 0, state.range(0), text.size(), 0, font, paint,
                    collection);
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK(BM_ParagraphMinikinDoLayout)
    ->RangeMultiplier(4)
    ->Range(1 << 7, 1 << 14)
    ->Complexity(benchmark::oN);

static void BM_ParagraphSkTextBlobAlloc(benchmark::State& state) {
  SkPaint paint;
  paint.setAntiAlias(true);
  paint.setTextEncoding(SkPaint::kGlyphID_TextEncoding);
  paint.setTextSize(14);
  paint.setFakeBoldText(false);

  while (state.KeepRunning()) {
    SkTextBlobBuilder builder;
    builder.allocRunPos(paint, 100);
  }
}
BENCHMARK(BM_ParagraphSkTextBlobAlloc);

}  // namespace txt

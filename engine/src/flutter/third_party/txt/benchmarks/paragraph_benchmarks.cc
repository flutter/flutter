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
#include "flutter/fml/command_line.h"
#include "flutter/fml/logging.h"
#include "flutter/third_party/txt/tests/txt_test_utils.h"
#include "minikin/LayoutUtils.h"
#include "third_party/icu/source/common/unicode/unistr.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "txt/font_collection.h"
#include "txt/font_skia.h"
#include "txt/font_style.h"
#include "txt/font_weight.h"
#include "txt/paragraph.h"
#include "txt/paragraph_builder.h"

namespace txt {

static void BM_ParagraphShortLayout(benchmark::State& state) {
  const char* text = "Hello World";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

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
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

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
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

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
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());
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
  paragraph_style.font_family = "Roboto";

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

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
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

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

static void BM_ParagraphPaintSimple(benchmark::State& state) {
  const char* text = "Hello world! This is a simple sentence to test drawing.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());
  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  auto paragraph = builder.Build();
  paragraph->Layout(300, true);

  std::unique_ptr<SkBitmap> bitmap = std::make_unique<SkBitmap>();
  std::unique_ptr<SkCanvas> canvas = std::make_unique<SkCanvas>(*bitmap);
  bitmap->allocN32Pixels(1000, 1000);
  canvas->clear(SK_ColorWHITE);
  int offset = 0;
  while (state.KeepRunning()) {
    paragraph->Paint(canvas.get(), offset % 700, 10);
    offset++;
  }
}
BENCHMARK(BM_ParagraphPaintSimple);

static void BM_ParagraphPaintLarge(benchmark::State& state) {
  const char* text =
      "Hello world! This is a simple sentence to test drawing. Hello world! "
      "This is a simple sentence to test drawing. Hello world! This is a "
      "simple sentence to test drawing.Hello world! This is a simple sentence "
      "to test drawing. Hello world! "
      "This is a simple sentence to test drawing. Hello world! This is a "
      "simple sentence to test drawing.Hello world! This is a simple sentence "
      "to test drawing. Hello world! "
      "This is a simple sentence to test drawing. Hello world! This is a "
      "simple sentence to test drawing.Hello world! This is a simple sentence "
      "to test drawing. Hello world! "
      "This is a simple sentence to test drawing. Hello world! This is a "
      "simple sentence to test drawing.Hello world! This is a simple sentence "
      "to test drawing. Hello world! "
      "This is a simple sentence to test drawing. Hello world! This is a "
      "simple sentence to test drawing.Hello world! This is a simple sentence "
      "to test drawing. Hello world! "
      "This is a simple sentence to test drawing. Hello world! This is a "
      "simple sentence to test drawing.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());
  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  auto paragraph = builder.Build();
  paragraph->Layout(300, true);

  std::unique_ptr<SkBitmap> bitmap = std::make_unique<SkBitmap>();
  std::unique_ptr<SkCanvas> canvas = std::make_unique<SkCanvas>(*bitmap);
  bitmap->allocN32Pixels(1000, 1000);
  canvas->clear(SK_ColorWHITE);
  int offset = 0;
  while (state.KeepRunning()) {
    paragraph->Paint(canvas.get(), offset % 700, 10);
    offset++;
  }
}
BENCHMARK(BM_ParagraphPaintLarge);

static void BM_ParagraphPaintDecoration(benchmark::State& state) {
  const char* text =
      "Hello world! This is a simple sentence to test drawing. Hello world! "
      "This is a simple sentence to test drawing.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;
  text_style.decoration_style = TextDecorationStyle(kSolid);
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  text_style.decoration_style = TextDecorationStyle(kDotted);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  text_style.decoration_style = TextDecorationStyle(kWavy);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  auto paragraph = builder.Build();
  paragraph->Layout(300, true);

  std::unique_ptr<SkBitmap> bitmap = std::make_unique<SkBitmap>();
  std::unique_ptr<SkCanvas> canvas = std::make_unique<SkCanvas>(*bitmap);
  bitmap->allocN32Pixels(1000, 1000);
  canvas->clear(SK_ColorWHITE);
  int offset = 0;
  while (state.KeepRunning()) {
    paragraph->Paint(canvas.get(), offset % 700, 10);
    offset++;
  }
}
BENCHMARK(BM_ParagraphPaintDecoration);

// -----------------------------------------------------------------------------
//
// The following benchmarks break down the layout function and attempts to time
// each of the components to more finely attribute latency.
//
// -----------------------------------------------------------------------------

static void BM_ParagraphMinikinDoLayout(benchmark::State& state) {
  std::vector<uint16_t> text;
  for (uint16_t i = 0; i < 16000 * 2; ++i) {
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

  auto collection = GetTestFontCollection()->GetMinikinFontCollectionForFamily(
      text_style.font_family, "en-US");

  while (state.KeepRunning()) {
    minikin::Layout layout;
    layout.doLayout(text.data(), 0, state.range(0), state.range(0), 0, font,
                    paint, collection);
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK(BM_ParagraphMinikinDoLayout)
    ->RangeMultiplier(4)
    ->Range(1 << 7, 1 << 14)
    ->Complexity(benchmark::oN);

static void BM_ParagraphMinikinAddStyleRun(benchmark::State& state) {
  std::vector<uint16_t> text;
  for (uint16_t i = 0; i < 16000 * 2; ++i) {
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

  auto font_collection = GetTestFontCollection();

  minikin::LineBreaker breaker;
  breaker.setLocale(icu::Locale(), nullptr);
  breaker.resize(text.size());
  memcpy(breaker.buffer(), text.data(), text.size() * sizeof(text[0]));
  breaker.setText();

  while (state.KeepRunning()) {
    for (int i = 0; i < 20; ++i) {
      breaker.addStyleRun(
          &paint,
          font_collection->GetMinikinFontCollectionForFamily("Roboto", "en-US"),
          font, state.range(0) / 20 * i, state.range(0) / 20 * (i + 1), false);
    }
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK(BM_ParagraphMinikinAddStyleRun)
    ->RangeMultiplier(4)
    ->Range(1 << 7, 1 << 14)
    ->Complexity(benchmark::oN);

static void BM_ParagraphSkTextBlobAlloc(benchmark::State& state) {
  SkFont font;
  font.setEdging(SkFont::Edging::kAntiAlias);
  font.setSize(14);
  font.setEmbolden(false);

  while (state.KeepRunning()) {
    SkTextBlobBuilder builder;
    builder.allocRunPos(font, state.range(0));
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK(BM_ParagraphSkTextBlobAlloc)
    ->RangeMultiplier(4)
    ->Range(1 << 7, 1 << 14)
    ->Complexity(benchmark::oN);

}  // namespace txt

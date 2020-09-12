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

#include <minikin/Layout.h>

#include <cstring>

#include "flutter/fml/command_line.h"
#include "flutter/fml/logging.h"
#include "flutter/third_party/txt/tests/txt_test_utils.h"
#include "minikin/LayoutUtils.h"
#include "third_party/benchmark/include/benchmark/benchmark_api.h"
#include "third_party/icu/source/common/unicode/unistr.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "txt/font_collection.h"
#include "txt/font_skia.h"
#include "txt/font_style.h"
#include "txt/font_weight.h"
#include "txt/paragraph.h"
#include "txt/paragraph_builder_txt.h"

namespace txt {

class ParagraphFixture : public benchmark::Fixture {
 public:
  void SetUp(const benchmark::State& state) {
    font_collection_ = GetTestFontCollection();

    bitmap_ = std::make_unique<SkBitmap>();
    bitmap_->allocN32Pixels(1000, 1000);
    canvas_ = std::make_unique<SkCanvas>(*bitmap_);
    canvas_->clear(SK_ColorWHITE);
  }

  void TearDown(const benchmark::State& state) { font_collection_.reset(); }

 protected:
  std::shared_ptr<FontCollection> font_collection_;
  std::unique_ptr<SkCanvas> canvas_;
  std::unique_ptr<SkBitmap> bitmap_;
};

BENCHMARK_F(ParagraphFixture, ShortLayout)(benchmark::State& state) {
  const char* text = "Hello World";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = BuildParagraph(builder);
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300);
  }
}

BENCHMARK_F(ParagraphFixture, LongLayout)(benchmark::State& state) {
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
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = BuildParagraph(builder);
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300);
  }
}

BENCHMARK_F(ParagraphFixture, JustifyLayout)(benchmark::State& state) {
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
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = BuildParagraph(builder);
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300);
  }
}

BENCHMARK_F(ParagraphFixture, ManyStylesLayout)(benchmark::State& state) {
  const char* text = "-";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);
  for (int i = 0; i < 1000; ++i) {
    builder.PushStyle(text_style);
    builder.AddText(u16_text);
  }
  auto paragraph = BuildParagraph(builder);
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300);
  }
}

BENCHMARK_DEFINE_F(ParagraphFixture, TextBigO)(benchmark::State& state) {
  std::vector<uint16_t> text;
  for (uint16_t i = 0; i < state.range(0); ++i) {
    text.push_back(i % 5 == 0 ? ' ' : i);
  }
  std::u16string u16_text(text.data(), text.data() + text.size());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = BuildParagraph(builder);
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300);
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK_REGISTER_F(ParagraphFixture, TextBigO)
    ->RangeMultiplier(4)
    ->Range(1 << 6, 1 << 14)
    ->Complexity(benchmark::oN);

BENCHMARK_DEFINE_F(ParagraphFixture, StylesBigO)(benchmark::State& state) {
  const char* text = "vry shrt ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);

  for (int i = 0; i < state.range(0); ++i) {
    builder.PushStyle(text_style);
    builder.AddText(u16_text);
  }
  auto paragraph = BuildParagraph(builder);
  while (state.KeepRunning()) {
    paragraph->SetDirty();
    paragraph->Layout(300);
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK_REGISTER_F(ParagraphFixture, StylesBigO)
    ->RangeMultiplier(4)
    ->Range(1 << 3, 1 << 12)
    ->Complexity(benchmark::oN);

BENCHMARK_F(ParagraphFixture, PaintSimple)(benchmark::State& state) {
  const char* text = "Hello world! This is a simple sentence to test drawing.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(300);

  int offset = 0;
  while (state.KeepRunning()) {
    paragraph->Paint(canvas_.get(), offset % 700, 10);
    offset++;
  }
}

BENCHMARK_F(ParagraphFixture, PaintLarge)(benchmark::State& state) {
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
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(300);

  int offset = 0;
  while (state.KeepRunning()) {
    paragraph->Paint(canvas_.get(), offset % 700, 10);
    offset++;
  }
}

BENCHMARK_F(ParagraphFixture, PaintDecoration)(benchmark::State& state) {
  const char* text =
      "Hello world! This is a simple sentence to test drawing. Hello world! "
      "This is a simple sentence to test drawing.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;
  text_style.decoration_style = TextDecorationStyle(kSolid);
  text_style.color = SK_ColorBLACK;

  txt::ParagraphBuilderTxt builder(paragraph_style, font_collection_);

  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  text_style.decoration_style = TextDecorationStyle(kDotted);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  text_style.decoration_style = TextDecorationStyle(kWavy);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(300);

  int offset = 0;
  while (state.KeepRunning()) {
    paragraph->Paint(canvas_.get(), offset % 700, 10);
    offset++;
  }
}

// -----------------------------------------------------------------------------
//
// The following benchmarks break down the layout function and attempts to time
// each of the components to more finely attribute latency.
//
// -----------------------------------------------------------------------------

BENCHMARK_DEFINE_F(ParagraphFixture, MinikinDoLayout)(benchmark::State& state) {
  std::vector<uint16_t> text;
  for (uint16_t i = 0; i < 16000 * 2; ++i) {
    text.push_back(i % 5 == 0 ? ' ' : i);
  }
  minikin::FontStyle font;
  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  minikin::MinikinPaint paint;

  font = minikin::FontStyle(4, false);
  paint.size = text_style.font_size;
  paint.letterSpacing = text_style.letter_spacing;
  paint.wordSpacing = text_style.word_spacing;

  auto collection = font_collection_->GetMinikinFontCollectionForFamilies(
      text_style.font_families, "en-US");

  while (state.KeepRunning()) {
    minikin::Layout layout;
    layout.doLayout(text.data(), 0, state.range(0), state.range(0), 0, font,
                    paint, collection);
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK_REGISTER_F(ParagraphFixture, MinikinDoLayout)
    ->RangeMultiplier(4)
    ->Range(1 << 7, 1 << 14)
    ->Complexity(benchmark::oN);

BENCHMARK_DEFINE_F(ParagraphFixture, AddStyleRun)(benchmark::State& state) {
  std::vector<uint16_t> text;
  for (uint16_t i = 0; i < 16000 * 2; ++i) {
    text.push_back(i % 5 == 0 ? ' ' : i);
  }
  minikin::FontStyle font;
  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  minikin::MinikinPaint paint;

  font = minikin::FontStyle(4, false);
  paint.size = text_style.font_size;
  paint.letterSpacing = text_style.letter_spacing;
  paint.wordSpacing = text_style.word_spacing;

  minikin::LineBreaker breaker;
  breaker.setLocale(icu::Locale(), nullptr);
  breaker.resize(text.size());
  memcpy(breaker.buffer(), text.data(), text.size() * sizeof(text[0]));
  breaker.setText();

  while (state.KeepRunning()) {
    for (int i = 0; i < 20; ++i) {
      breaker.addStyleRun(&paint,
                          font_collection_->GetMinikinFontCollectionForFamilies(
                              std::vector<std::string>(1, "Roboto"), "en-US"),
                          font, state.range(0) / 20 * i,
                          state.range(0) / 20 * (i + 1), false);
    }
  }
  state.SetComplexityN(state.range(0));
}
BENCHMARK_REGISTER_F(ParagraphFixture, AddStyleRun)
    ->RangeMultiplier(4)
    ->Range(1 << 7, 1 << 14)
    ->Complexity(benchmark::oN);

BENCHMARK_DEFINE_F(ParagraphFixture, SkTextBlobAlloc)(benchmark::State& state) {
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
BENCHMARK_REGISTER_F(ParagraphFixture, SkTextBlobAlloc)
    ->RangeMultiplier(4)
    ->Range(1 << 7, 1 << 14)
    ->Complexity(benchmark::oN);

}  // namespace txt

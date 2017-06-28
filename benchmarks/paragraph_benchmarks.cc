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

#include "lib/ftl/command_line.h"
#include "lib/ftl/logging.h"
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

  while (state.KeepRunning()) {
    txt::ParagraphStyle paragraph_style;
    txt::ParagraphBuilder builder(paragraph_style);

    txt::TextStyle text_style;
    text_style.color = SK_ColorBLACK;

    builder.PushStyle(text_style);
    builder.AddText(u16_text);
    builder.Pop();
    auto paragraph = builder.Build();
    paragraph->Layout(300, txt::GetFontDir(), true);
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
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();
  auto paragraph = builder.Build();
  while (state.KeepRunning()) {
    paragraph->Layout(300, txt::GetFontDir(), true);
  }
}
BENCHMARK(BM_ParagraphLongLayout);

static void BM_ParagraphManyStylesLayout(benchmark::State& state) {
  const char* text = "A short sentence. ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  while (state.KeepRunning()) {
    txt::ParagraphStyle paragraph_style;
    txt::ParagraphBuilder builder(paragraph_style);

    txt::TextStyle text_style;
    text_style.color = SK_ColorBLACK;

    for (int i = 0; i < 100; ++i) {
      builder.PushStyle(text_style);
      builder.AddText(u16_text);
    }
    auto paragraph = builder.Build();
    paragraph->Layout(300, txt::GetFontDir(), true);
  }
}
BENCHMARK(BM_ParagraphManyStylesLayout);

}  // namespace txt

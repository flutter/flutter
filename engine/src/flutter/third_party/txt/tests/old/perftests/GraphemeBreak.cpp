/*
 * Copyright (C) 2016 The Android Open Source Project
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
#include <benchmark/benchmark.h>

#include <cutils/log.h>

#include "UnicodeUtils.h"
#include "minikin/GraphemeBreak.h"

namespace minikin {

const char* ASCII_TEST_STR = "'L' 'o' 'r' 'e' 'm' ' ' 'i' 'p' 's' 'u' 'm' '.'";
// U+261D: WHITE UP POINTING INDEX
// U+1F3FD: EMOJI MODIFIER FITZPATRICK TYPE-4
const char* EMOJI_TEST_STR =
    "U+261D U+1F3FD U+261D U+1F3FD U+261D U+1F3FD U+261D U+1F3FD";
// U+1F1FA: REGIONAL INDICATOR SYMBOL LETTER U
// U+1F1F8: REGIONAL INDICATOR SYMBOL LETTER S
const char* FLAGS_TEST_STR = "U+1F1FA U+1F1F8 U+1F1FA U+1F1F8 U+1F1FA U+1F1F8";

// TODO: Migrate BENCHMARK_CAPTURE for parameterizing.
static void BM_GraphemeBreak_Ascii(benchmark::State& state) {
  size_t result_size;
  uint16_t buffer[12];
  ParseUnicode(buffer, 12, ASCII_TEST_STR, &result_size, nullptr);
  LOG_ALWAYS_FATAL_IF(result_size != 12);
  const size_t testIndex = state.range(0);
  while (state.KeepRunning()) {
    GraphemeBreak::isGraphemeBreak(nullptr, buffer, 0, result_size, testIndex);
  }
}
BENCHMARK(BM_GraphemeBreak_Ascii)
    ->Arg(0)    // Beginning of the text.
    ->Arg(1)    // Middle of the text.
    ->Arg(12);  // End of the text.

static void BM_GraphemeBreak_Emoji(benchmark::State& state) {
  size_t result_size;
  uint16_t buffer[12];
  ParseUnicode(buffer, 12, EMOJI_TEST_STR, &result_size, nullptr);
  LOG_ALWAYS_FATAL_IF(result_size != 12);
  const size_t testIndex = state.range(0);
  while (state.KeepRunning()) {
    GraphemeBreak::isGraphemeBreak(nullptr, buffer, 0, result_size, testIndex);
  }
}
BENCHMARK(BM_GraphemeBreak_Emoji)
    ->Arg(1)   // Middle of emoji modifier sequence.
    ->Arg(2)   // Middle of the surrogate pairs.
    ->Arg(3);  // After emoji modifier sequence. Here is boundary of grapheme
               // cluster.

static void BM_GraphemeBreak_Emoji_Flags(benchmark::State& state) {
  size_t result_size;
  uint16_t buffer[12];
  ParseUnicode(buffer, 12, FLAGS_TEST_STR, &result_size, nullptr);
  LOG_ALWAYS_FATAL_IF(result_size != 12);
  const size_t testIndex = state.range(0);
  while (state.KeepRunning()) {
    GraphemeBreak::isGraphemeBreak(nullptr, buffer, 0, result_size, testIndex);
  }
}
BENCHMARK(BM_GraphemeBreak_Emoji_Flags)
    ->Arg(2)    // Middle of flag sequence.
    ->Arg(4)    // After flag sequence. Here is boundary of grapheme cluster.
    ->Arg(10);  // Middle of 3rd flag sequence.

}  // namespace minikin

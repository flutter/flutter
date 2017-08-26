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

#include <FileUtils.h>
#include <UnicodeUtils.h>
#include <minikin/Hyphenator.h>

namespace minikin {

const char* enUsHyph = "/system/usr/hyphen-data/hyph-en-us.hyb";
const int enUsMinPrefix = 2;
const int enUsMinSuffix = 3;
const icu::Locale& usLocale = icu::Locale::getUS();

static void BM_Hyphenator_short_word(benchmark::State& state) {
  Hyphenator* hyphenator = Hyphenator::loadBinary(
      readWholeFile(enUsHyph).data(), enUsMinPrefix, enUsMinSuffix);
  std::vector<uint16_t> word = utf8ToUtf16("hyphen");
  std::vector<HyphenationType> result;
  while (state.KeepRunning()) {
    hyphenator->hyphenate(&result, word.data(), word.size(), usLocale);
  }
  Hyphenator::loadBinary(nullptr, 2, 2);
}

// TODO: Use BENCHMARK_CAPTURE for parametrise.
BENCHMARK(BM_Hyphenator_short_word);

static void BM_Hyphenator_long_word(benchmark::State& state) {
  Hyphenator* hyphenator = Hyphenator::loadBinary(
      readWholeFile(enUsHyph).data(), enUsMinPrefix, enUsMinSuffix);
  std::vector<uint16_t> word =
      utf8ToUtf16("Pneumonoultramicroscopicsilicovolcanoconiosis");
  std::vector<HyphenationType> result;
  while (state.KeepRunning()) {
    hyphenator->hyphenate(&result, word.data(), word.size(), usLocale);
  }
  Hyphenator::loadBinary(nullptr, 2, 2);
}

// TODO: Use BENCHMARK_CAPTURE for parametrise.
BENCHMARK(BM_Hyphenator_long_word);

// TODO: Add more tests for other languages.

}  // namespace minikin

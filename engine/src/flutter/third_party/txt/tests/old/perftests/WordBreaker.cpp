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

#include "UnicodeUtils.h"
#include "minikin/WordBreaker.h"

namespace minikin {

static void BM_WordBreaker_English(benchmark::State& state) {
  const char* kLoremIpsum =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do "
      "eiusmod tempor incididunt ut labore et dolore magna aliqua.";

  WordBreaker wb;
  wb.setLocale(icu::Locale::getEnglish());
  std::vector<uint16_t> text = utf8ToUtf16(kLoremIpsum);
  while (state.KeepRunning()) {
    wb.setText(text.data(), text.size());
    while (wb.next() != -1) {
    }
  }
}
BENCHMARK(BM_WordBreaker_English);

// TODO: Add more tests for other languages.

}  // namespace minikin

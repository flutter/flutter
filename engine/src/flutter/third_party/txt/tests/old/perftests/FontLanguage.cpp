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

#include "FontLanguage.h"

namespace minikin {

static void BM_FontLanguage_en_US(benchmark::State& state) {
  while (state.KeepRunning()) {
    FontLanguage language("en-US", 5);
  }
}
BENCHMARK(BM_FontLanguage_en_US);

static void BM_FontLanguage_en_Latn_US(benchmark::State& state) {
  while (state.KeepRunning()) {
    FontLanguage language("en-Latn-US", 10);
  }
}
BENCHMARK(BM_FontLanguage_en_Latn_US);

static void BM_FontLanguage_en_Latn_US_u_em_emoji(benchmark::State& state) {
  while (state.KeepRunning()) {
    FontLanguage language("en-Latn-US-u-em-emoji", 21);
  }
}
BENCHMARK(BM_FontLanguage_en_Latn_US_u_em_emoji);

}  // namespace minikin

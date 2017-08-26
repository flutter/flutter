/*
 * Copyright (C) 2017 The Android Open Source Project
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

#include <minikin/FontFamily.h>
#include "../util/MinikinFontForTest.h"

namespace minikin {

static void BM_FontFamily_create(benchmark::State& state) {
  std::shared_ptr<MinikinFontForTest> minikinFont =
      std::make_shared<MinikinFontForTest>(
          "/system/fonts/NotoSansCJK-Regular.ttc", 0);

  while (state.KeepRunning()) {
    std::shared_ptr<FontFamily> family = std::make_shared<FontFamily>(
        std::vector<Font>({Font(minikinFont, FontStyle())}));
  }
}

BENCHMARK(BM_FontFamily_create);

}  // namespace minikin

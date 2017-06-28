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
#include "lib/txt/src/font_collection.h"
#include "utils.h"

namespace txt {

// Include this fake bench first because the first benchmark produces
// inconsistent times.
static void BM_FAKE_BENCHMARK(benchmark::State& state) {
  while (state.KeepRunning()) {
    continue;
  }
}
BENCHMARK(BM_FAKE_BENCHMARK);

static void BM_FontCollectionInit(benchmark::State& state) {
  while (state.KeepRunning()) {
    FontCollection::GetFontCollection(txt::GetFontDir());
  }
}
BENCHMARK(BM_FontCollectionInit);

static void BM_FontCollectionGetMinikinFontCollectionForFamily(
    benchmark::State& state) {
  while (state.KeepRunning()) {
    FontCollection::GetFontCollection(txt::GetFontDir())
        .GetMinikinFontCollectionForFamily("Roboto");
  }
}
BENCHMARK(BM_FontCollectionGetMinikinFontCollectionForFamily);

}  // namespace txt

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

#include "flutter/fml/command_line.h"
#include "flutter/fml/logging.h"
#include "flutter/third_party/txt/tests/txt_test_utils.h"
#include "third_party/benchmark/include/benchmark/benchmark_api.h"
#include "txt/paint_record.h"
#include "txt/text_style.h"

namespace txt {

static void BM_PaintRecordInit(benchmark::State& state) {
  TextStyle style;
  style.font_families = std::vector<std::string>(1, "Roboto");

  SkFont font;
  font.setEdging(SkFont::Edging::kAntiAlias);
  font.setSize(14);
  font.setEmbolden(false);

  SkTextBlobBuilder builder;
  builder.allocRunPos(font, 100);
  auto text_blob = builder.make();

  while (state.KeepRunning()) {
    PaintRecord PaintRecord(style, text_blob, SkFontMetrics(), 0, 0, 0, false);
  }
}
BENCHMARK(BM_PaintRecordInit);

}  // namespace txt

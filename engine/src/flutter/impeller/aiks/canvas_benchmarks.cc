// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/benchmarking/benchmarking.h"

#include "impeller/aiks/canvas.h"

namespace impeller {

namespace {

using CanvasCallback = size_t (*)(Canvas&);

size_t DrawRect(Canvas& canvas) {
  for (auto i = 0; i < 500; i++) {
    canvas.DrawRect(Rect::MakeLTRB(0, 0, 100, 100),
                    {.color = Color::DarkKhaki()});
  }
  return 500;
}

size_t DrawCircle(Canvas& canvas) {
  for (auto i = 0; i < 500; i++) {
    canvas.DrawCircle({100, 100}, 5, {.color = Color::DarkKhaki()});
  }
  return 500;
}

size_t DrawLine(Canvas& canvas) {
  for (auto i = 0; i < 500; i++) {
    canvas.DrawLine({0, 0}, {100, 100}, {.color = Color::DarkKhaki()});
  }
  return 500;
}
}  // namespace

// A set of benchmarks that measures the CPU cost of encoding canvas operations.
// These benchmarks do not measure the cost of conversion through the HAL, no
// do they measure the GPU side cost of executing the required shader programs.
template <class... Args>
static void BM_CanvasRecord(benchmark::State& state, Args&&... args) {
  auto args_tuple = std::make_tuple(std::move(args)...);
  auto test_proc = std::get<CanvasCallback>(args_tuple);

  size_t op_count = 0u;
  size_t canvas_count = 0u;
  while (state.KeepRunning()) {
    // A new canvas is allocated for each iteration to avoid the benchmark
    // becoming a measurement of only the entity vector re-allocation time.
    Canvas canvas;
    op_count += test_proc(canvas);
    canvas_count++;
  }
  state.counters["TotalOpCount"] = op_count;
  state.counters["TotalCanvasCount"] = canvas_count;
}

BENCHMARK_CAPTURE(BM_CanvasRecord, draw_rect, &DrawRect);
BENCHMARK_CAPTURE(BM_CanvasRecord, draw_circle, &DrawCircle);
BENCHMARK_CAPTURE(BM_CanvasRecord, draw_line, &DrawLine);

}  // namespace impeller

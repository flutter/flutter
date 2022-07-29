// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/benchmarking/benchmarking.h"
#include "flutter/display_list/display_list_test_utils.h"

namespace flutter {
namespace {

static std::vector<testing::DisplayListInvocationGroup> allRenderingOps =
    testing::CreateAllRenderingOps();

enum class DisplayListBuilderBenchmarkType {
  kDefault,
  kBounds,
  kRtree,
  kBoundsAndRtree,
};

static void InvokeAllRenderingOps(DisplayListBuilder& builder) {
  for (auto& group : allRenderingOps) {
    for (size_t i = 0; i < group.variants.size(); i++) {
      auto& invocation = group.variants[i];
      invocation.Invoke(builder);
    }
  }
}

static void Complete(DisplayListBuilder& builder,
                     DisplayListBuilderBenchmarkType type) {
  auto display_list = builder.Build();
  switch (type) {
    case DisplayListBuilderBenchmarkType::kBounds:
      display_list->bounds();
      break;
    case DisplayListBuilderBenchmarkType::kRtree:
      display_list->rtree();
      break;
    case DisplayListBuilderBenchmarkType::kBoundsAndRtree:
      display_list->bounds();
      display_list->rtree();
      break;
    case DisplayListBuilderBenchmarkType::kDefault:
      break;
  }
}

}  // namespace

static void BM_DisplayListBuiderDefault(benchmark::State& state,
                                        DisplayListBuilderBenchmarkType type) {
  while (state.KeepRunning()) {
    DisplayListBuilder builder;
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuiderWithScaleAndTranslate(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  while (state.KeepRunning()) {
    DisplayListBuilder builder;
    builder.scale(3.5, 3.5);
    builder.translate(10.3, 6.9);
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuiderWithPerspective(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  while (state.KeepRunning()) {
    DisplayListBuilder builder;
    builder.transformFullPerspective(0, 1, 0, 12, 1, 0, 0, 33, 3, 2, 5, 29, 0,
                                     0, 0, 12);
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuiderWithClipRect(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  SkRect clip_bounds = SkRect::MakeLTRB(6.5, 7.3, 90.2, 85.7);
  while (state.KeepRunning()) {
    DisplayListBuilder builder;
    builder.clipRect(clip_bounds, SkClipOp::kIntersect, true);
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuiderWithSaveLayer(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  while (state.KeepRunning()) {
    DisplayListBuilder builder;
    for (auto& group : allRenderingOps) {
      for (size_t i = 0; i < group.variants.size(); i++) {
        auto& invocation = group.variants[i];
        builder.saveLayer(nullptr, false);
        invocation.Invoke(builder);
        builder.restore();
      }
    }
    Complete(builder, type);
  }
}

static void BM_DisplayListBuiderWithSaveLayerAndImageFilter(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  DlPaint layer_paint;
  layer_paint.setImageFilter(&testing::kTestBlurImageFilter1);
  SkRect layer_bounds = SkRect::MakeLTRB(6.5, 7.3, 35.2, 42.7);
  while (state.KeepRunning()) {
    DisplayListBuilder builder;
    for (auto& group : allRenderingOps) {
      for (size_t i = 0; i < group.variants.size(); i++) {
        auto& invocation = group.variants[i];
        builder.saveLayer(&layer_bounds, &layer_paint);
        invocation.Invoke(builder);
        builder.restore();
      }
    }
    Complete(builder, type);
  }
}

BENCHMARK_CAPTURE(BM_DisplayListBuiderDefault,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderDefault,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderDefault,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderDefault,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMillisecond);

BENCHMARK_CAPTURE(BM_DisplayListBuiderWithScaleAndTranslate,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithScaleAndTranslate,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithScaleAndTranslate,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithScaleAndTranslate,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMillisecond);

BENCHMARK_CAPTURE(BM_DisplayListBuiderWithPerspective,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithPerspective,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithPerspective,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithPerspective,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMillisecond);

BENCHMARK_CAPTURE(BM_DisplayListBuiderWithClipRect,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithClipRect,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithClipRect,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithClipRect,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMillisecond);

BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayer,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayer,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayer,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayer,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMillisecond);

BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayerAndImageFilter,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayerAndImageFilter,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayerAndImageFilter,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMillisecond);
BENCHMARK_CAPTURE(BM_DisplayListBuiderWithSaveLayerAndImageFilter,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMillisecond);

}  // namespace flutter

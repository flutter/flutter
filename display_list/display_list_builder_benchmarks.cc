// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/benchmarking/benchmarking.h"
#include "flutter/display_list/testing/dl_test_snippets.h"

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

bool NeedPrepareRTree(DisplayListBuilderBenchmarkType type) {
  return type == DisplayListBuilderBenchmarkType::kRtree ||
         type == DisplayListBuilderBenchmarkType::kBoundsAndRtree;
}

}  // namespace

static void BM_DisplayListBuilderDefault(benchmark::State& state,
                                         DisplayListBuilderBenchmarkType type) {
  bool prepare_rtree = NeedPrepareRTree(type);
  while (state.KeepRunning()) {
    DisplayListBuilder builder(prepare_rtree);
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuilderWithScaleAndTranslate(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  bool prepare_rtree = NeedPrepareRTree(type);
  while (state.KeepRunning()) {
    DisplayListBuilder builder(prepare_rtree);
    builder.scale(3.5, 3.5);
    builder.translate(10.3, 6.9);
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuilderWithPerspective(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  bool prepare_rtree = NeedPrepareRTree(type);
  while (state.KeepRunning()) {
    DisplayListBuilder builder(prepare_rtree);
    builder.transformFullPerspective(0, 1, 0, 12, 1, 0, 0, 33, 3, 2, 5, 29, 0,
                                     0, 0, 12);
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuilderWithClipRect(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  SkRect clip_bounds = SkRect::MakeLTRB(6.5, 7.3, 90.2, 85.7);
  bool prepare_rtree = NeedPrepareRTree(type);
  while (state.KeepRunning()) {
    DisplayListBuilder builder(prepare_rtree);
    builder.clipRect(clip_bounds, DlCanvas::ClipOp::kIntersect, true);
    InvokeAllRenderingOps(builder);
    Complete(builder, type);
  }
}

static void BM_DisplayListBuilderWithSaveLayer(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  bool prepare_rtree = NeedPrepareRTree(type);
  while (state.KeepRunning()) {
    DisplayListBuilder builder(prepare_rtree);
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

static void BM_DisplayListBuilderWithSaveLayerAndImageFilter(
    benchmark::State& state,
    DisplayListBuilderBenchmarkType type) {
  DlPaint layer_paint;
  layer_paint.setImageFilter(&testing::kTestBlurImageFilter1);
  SkRect layer_bounds = SkRect::MakeLTRB(6.5, 7.3, 35.2, 42.7);
  bool prepare_rtree = NeedPrepareRTree(type);
  while (state.KeepRunning()) {
    DisplayListBuilder builder(prepare_rtree);
    for (auto& group : allRenderingOps) {
      for (size_t i = 0; i < group.variants.size(); i++) {
        auto& invocation = group.variants[i];
        builder.SaveLayer(&layer_bounds, &layer_paint);
        invocation.Invoke(builder);
        builder.Restore();
      }
    }
    Complete(builder, type);
  }
}

BENCHMARK_CAPTURE(BM_DisplayListBuilderDefault,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderDefault,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderDefault,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderDefault,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMicrosecond);

BENCHMARK_CAPTURE(BM_DisplayListBuilderWithScaleAndTranslate,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithScaleAndTranslate,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithScaleAndTranslate,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithScaleAndTranslate,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMicrosecond);

BENCHMARK_CAPTURE(BM_DisplayListBuilderWithPerspective,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithPerspective,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithPerspective,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithPerspective,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMicrosecond);

BENCHMARK_CAPTURE(BM_DisplayListBuilderWithClipRect,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithClipRect,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithClipRect,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithClipRect,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMicrosecond);

BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayer,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayer,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayer,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayer,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMicrosecond);

BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayerAndImageFilter,
                  kDefault,
                  DisplayListBuilderBenchmarkType::kDefault)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayerAndImageFilter,
                  kBounds,
                  DisplayListBuilderBenchmarkType::kBounds)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayerAndImageFilter,
                  kRtree,
                  DisplayListBuilderBenchmarkType::kRtree)
    ->Unit(benchmark::kMicrosecond);
BENCHMARK_CAPTURE(BM_DisplayListBuilderWithSaveLayerAndImageFilter,
                  kBoundsAndRtree,
                  DisplayListBuilderBenchmarkType::kBoundsAndRtree)
    ->Unit(benchmark::kMicrosecond);

}  // namespace flutter

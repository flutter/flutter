// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/benchmarking/dl_benchmarks.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_op_flags.h"
#include "flutter/display_list/dl_text_skia.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/display_list/skia/dl_sk_canvas.h"
#include "flutter/display_list/testing/dl_test_snippets.h"
#include "flutter/testing/display_list_testing.h"

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkTextBlob.h"

// This label can be defined to produce snapshots of what the benchmarks
// are drawing for debugging purposes. (Disabled here for production use.)
#undef WRITE_BENCHMARK_SNAPSHOTS

namespace flutter {
namespace testing {

namespace {

inline void SaveSnapshotIfNecessary(
    const std::unique_ptr<DlSurfaceProvider>& provider,
    const std::shared_ptr<DlSurfaceInstance>& surface,
    benchmark::State& state,
    const std::string& test_name) {
#ifdef WRITE_BENCHMARK_SNAPSHOTS
  auto filename = provider->GetBackendName() + "-" + test_name + "-" +
                  std::to_string(state.range(0)) + ".png";
  surface->SnapshotToFile(filename);
#endif  // WRITE_BENCHMARK_SNAPSHOTS
}

class RectAnimator {
 public:
  RectAnimator(DlRect rect, DlPoint animation_delta, DlISize animation_limit)
      : rect_(rect),
        rect_origin_(rect.GetOrigin()),
        animation_delta_(animation_delta),
        animation_limit_(animation_limit) {}

  RectAnimator(DlRect rect,
               DlPoint animation_delta,
               const std::shared_ptr<DlSurfaceInstance>& surface)
      : RectAnimator(rect, animation_delta, surface->GetSize()) {}

  void Animate() {
    rect_ = rect_.Shift(animation_delta_);
    if (rect_.GetRight() > animation_limit_.width) {
      rect_ = rect_.Shift(rect_origin_.x - rect_.GetLeft(), 0);
    }
    if (rect_.GetBottom() > animation_limit_.height) {
      rect_ = rect_.Shift(0, rect_origin_.y - rect_.GetTop());
    }
  }

  const DlRect& GetRect() const { return rect_; }
  const DlPoint GetPoint() const { return rect_.GetOrigin(); }
  const DlPoint GetCenter() const { return rect_.GetCenter(); }

 private:
  DlRect rect_;
  const DlPoint rect_origin_;

  const DlPoint animation_delta_;
  const DlSize animation_limit_;
};

class DlPathVerbCounter : public DlPathReceiver {
 public:
  void MoveTo(const DlPoint& p2, bool will_be_closed) override {
    verb_count_++;
  }
  void LineTo(const DlPoint& p2) override { verb_count_++; }
  void QuadTo(const DlPoint& cp, const DlPoint& p2) override { verb_count_++; }
  bool ConicTo(const DlPoint& cp, const DlPoint& p2, DlScalar weight) override {
    verb_count_++;
    return false;
  }
  void CubicTo(const DlPoint& cp1,
               const DlPoint& cp2,
               const DlPoint& p2) override {
    verb_count_++;
  }
  void Close() override { verb_count_++; }

  uint32_t GetVerbCount() const { return verb_count_; }

 private:
  uint32_t verb_count_ = 0u;
};

DlPaint GetPaintForRun(unsigned attributes) {
  DlPaint paint;

  if (attributes & kStrokedStyle && attributes & kFilledStyle) {
    // Not currently exposed by Flutter, but we can probably benchmark this in
    // the future
    paint.setDrawStyle(DlDrawStyle::kStrokeAndFill);
  } else if (attributes & kStrokedStyle) {
    paint.setDrawStyle(DlDrawStyle::kStroke);
  } else if (attributes & kFilledStyle) {
    paint.setDrawStyle(DlDrawStyle::kFill);
  }

  if (attributes & kHairlineStroke) {
    paint.setStrokeWidth(0.0f);
  } else if (attributes & kWideStroke10) {
    paint.setStrokeWidth(10.0f);
  } else {
    paint.setStrokeWidth(1.0f);
  }

  paint.setAntiAlias(attributes & kAntiAliasing);
  return paint;
}

void CheckAttributes(uint32_t attributes,
                     benchmark::State& state,
                     const DisplayListAttributeFlags flags) {
  if (flags.always_stroked() && attributes & kFilledStyle) {
    state.SkipWithError("Cannot fill an operation that is always stroked");
  }
  if (flags.applies_style()) {
    if ((attributes & kFilledStyle) == 0 && (attributes & kStrokedStyle) == 0) {
      state.SkipWithError("must specify stroked and/or filled style");
    }
    if ((attributes & kStrokedStyle) == 0) {
      if ((attributes & kHairlineStroke) || (attributes & kWideStroke10)) {
        state.SkipWithError("Cannot specify stroke style if op is not stroked");
      }
    }
  }
}

// Constants chosen to produce benchmark results in the region of 1-50ms
constexpr size_t kLinesToDraw = 10000;
constexpr size_t kRectsToDraw = 5000;
constexpr size_t kOvalsToDraw = 5000;
constexpr size_t kCirclesToDraw = 5000;
constexpr size_t kRRectsToDraw = 5000;
constexpr size_t kRSEsToDraw = 5000;
constexpr size_t kDRRectsToDraw = 2000;
constexpr size_t kArcSweepSetsToDraw = 1000;
constexpr size_t kImagesToDraw = 500;
constexpr size_t kFixedCanvasSize = 1024;

}  // namespace

// Perform just a surface sync on each iteration to determine how much
// overhead the "Flush and Sync" operation costs.
void BM_SyncOverhead(benchmark::State& state, BackendType backend_type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);

  size_t length = state.range(0);

  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  // We only want to time the surface Sync.
  for ([[maybe_unused]] auto _ : state) {
    surface->FlushSubmitCpuSync();
  }
}

// Render an empty DisplayList to check the overhead of just calling the
// DlSurfaceInstance::RenderDisplayList method even with no work to do.
void BM_EmptyDisplayList(benchmark::State& state, BackendType backend_type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);

  size_t length = state.range(0);

  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DisplayListBuilder builder;
  auto display_list = builder.Build();

  // We only want to time the surface Sync.
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    surface->FlushSubmitCpuSync();
  }
}

// Render a DisplayList with a single tiny 1x1 rect to check the overhead of
// processing a DisplayList with minimal non-empty contents.
void BM_SingleOpDisplayList(benchmark::State& state, BackendType backend_type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);

  size_t length = state.range(0);

  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DisplayListBuilder builder;
  builder.DrawRect(DlRect::MakeLTRB(0, 0, 1, 1), DlPaint());
  auto display_list = builder.Build();

  // We only want to time the surface Sync.
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    surface->FlushSubmitCpuSync();
  }
}

// Draw a series of diagonal lines across a square canvas of width/height of
// the length requested. The lines will start from the top left corner to the
// bottom right corner, and move from left to right (at the top) and from right
// to left (at the bottom) until 10,000 lines are drawn.
//
// The resulting image will be an hourglass shape.
void BM_DrawLine(benchmark::State& state,
                 BackendType backend_type,
                 unsigned attributes) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawLineFlags);

  size_t length = state.range(0);

  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  state.counters["DrawCallCount"] = kLinesToDraw;
  for (size_t i = 0; i < kLinesToDraw; i++) {
    builder.DrawLine(DlPoint(i % length, 0),
                     DlPoint(length - i % length, length), paint);
  }

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kLinesToDraw);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kLinesToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawLine");
}

// Draws a series of square rects of the requested width across
// the canvas and repeats until `kRectsToDraw` rects have been drawn.
//
// Half the drawn rects will not have an integral offset.
void BM_DrawRect(benchmark::State& state,
                 BackendType backend_type,
                 unsigned attributes) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawRectFlags);

  size_t length = state.range(0);
  surface_provider->InitializeSurface(length * 2, length * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  // As rects have DlScalar dimensions, we want to ensure that we also
  // draw rects with non-integer position and size
  const DlPoint delta(0.5f, 0.5f);
  RectAnimator animator(DlRect::MakeWH(length, length), delta, surface);

  state.counters["DrawCallCount"] = kRectsToDraw;
  for (size_t i = 0; i < kRectsToDraw; i++) {
    builder.DrawRect(animator.GetRect(), paint);
    animator.Animate();
  }

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kRectsToDraw);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kRectsToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawRect");
}

// Draws a series of ovals of the requested height with aspect ratio 3:2 across
// the canvas and repeats until `kOvalsToDraw` ovals have been drawn.
//
// Half the drawn ovals will not have an integral offset.
void BM_DrawOval(benchmark::State& state,
                 BackendType backend_type,
                 unsigned attributes) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawOvalFlags);

  size_t length = state.range(0);
  surface_provider->InitializeSurface(length * 2, length * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  const DlPoint delta(0.5f, 0.5f);
  DlSize size(length * 1.5f, length);
  RectAnimator animator(DlRect::MakeSize(size), delta, surface);

  state.counters["DrawCallCount"] = kOvalsToDraw;
  for (size_t i = 0; i < kOvalsToDraw; i++) {
    builder.DrawOval(animator.GetRect(), paint);
    animator.Animate();
  }
  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kOvalsToDraw);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kOvalsToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawOval");
}

// Draws a series of circles of the requested radius across
// the canvas and repeats until `kCirclesToDraw` circles have been drawn.
//
// Half the drawn circles will not have an integral center point.
void BM_DrawCircle(benchmark::State& state,
                   BackendType backend_type,
                   unsigned attributes) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawCircleFlags);

  size_t length = state.range(0);
  surface_provider->InitializeSurface(length * 2, length * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlScalar radius = length / 2.0f;
  const DlPoint delta(0.5f, 0.5f);
  RectAnimator animator(DlRect::MakeWH(length, length), delta, surface);

  state.counters["DrawCallCount"] = kCirclesToDraw;
  for (size_t i = 0; i < kCirclesToDraw; i++) {
    builder.DrawCircle(animator.GetCenter(), radius, paint);
    animator.Animate();
  }
  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kCirclesToDraw);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kCirclesToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawCircle");
}

// Draws a series of rounded rects of the requested width across
// the canvas and repeats until `kRRectsToDraw` rects have been drawn.
//
// Half the drawn rounded rects will not have an integral offset.
void BM_DrawRRect(benchmark::State& state,
                  BackendType backend_type,
                  unsigned attributes,
                  RRectType type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawRRectFlags);

  size_t length = state.range(0);
  surface_provider->InitializeSurface(length * 2, length * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlRoundingRadii radii;
  // Keep all radii under 8 so that they won't overflow the rrect
  // bounds which are 16 units wide at the smallest.
  switch (type) {
    case RRectType::kSimple:
      radii.top_left = DlSize(5.0f, 5.0f);
      radii.top_right = DlSize(5.0f, 5.0f);
      radii.bottom_right = DlSize(5.0f, 5.0f);
      radii.bottom_left = DlSize(5.0f, 5.0f);
      break;
    case RRectType::kNinePatch:
      radii.top_left = DlSize(5.0f, 2.0f);
      radii.top_right = DlSize(3.0f, 2.0f);
      radii.bottom_right = DlSize(3.0f, 4.0f);
      radii.bottom_left = DlSize(5.0f, 4.0f);
      break;
    case RRectType::kComplex:
      radii.top_left = DlSize(5.0f, 4.0f);
      radii.top_right = DlSize(4.0f, 5.0f);
      radii.bottom_right = DlSize(3.0f, 6.0f);
      radii.bottom_left = DlSize(2.0f, 7.0f);
      break;
    default:
      FML_UNREACHABLE();
  }

  const DlPoint delta = DlPoint(0.5f, 0.5f);
  const DlScalar multiplier = length / 16.0f;
  RectAnimator animator(DlRect::MakeWH(length, length), delta, surface);

  radii = radii * multiplier;

  state.counters["DrawCallCount"] = kRRectsToDraw;
  for (size_t i = 0; i < kRRectsToDraw; i++) {
    DlRoundRect rrect = DlRoundRect::MakeRectRadii(animator.GetRect(), radii);
    builder.DrawRoundRect(rrect, paint);
    animator.Animate();
  }
  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kRRectsToDraw);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kRRectsToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawRRect");
}

void BM_DrawSimpleRRect(benchmark::State& state,
                        BackendType backend_type,
                        unsigned attributes) {
  BM_DrawRRect(state, backend_type, attributes, RRectType::kSimple);
}

void BM_DrawNinePatchRRect(benchmark::State& state,
                           BackendType backend_type,
                           unsigned attributes) {
  BM_DrawRRect(state, backend_type, attributes, RRectType::kNinePatch);
}

void BM_DrawComplexRRect(benchmark::State& state,
                         BackendType backend_type,
                         unsigned attributes) {
  BM_DrawRRect(state, backend_type, attributes, RRectType::kComplex);
}

// Draws a series of rounded superellipses of the requested width across
// the canvas and repeats until `kRSEsToDraw` rects have been drawn.
//
// Half the drawn rounded rects will not have an integral offset.
void BM_DrawRSE(benchmark::State& state,
                BackendType backend_type,
                unsigned attributes,
                RRectType type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state,
                  DisplayListOpFlags::kDrawRSuperellipseFlags);

  size_t length = state.range(0);
  surface_provider->InitializeSurface(length * 2, length * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlRoundingRadii radii;
  // Keep all radii under 8 so that they won't overflow the rrect
  // bounds which are 16 units wide at the smallest.
  switch (type) {
    case RRectType::kSimple:
      radii.top_left = DlSize(5.0f, 5.0f);
      radii.top_right = DlSize(5.0f, 5.0f);
      radii.bottom_right = DlSize(5.0f, 5.0f);
      radii.bottom_left = DlSize(5.0f, 5.0f);
      break;
    case RRectType::kNinePatch:
      radii.top_left = DlSize(5.0f, 2.0f);
      radii.top_right = DlSize(3.0f, 2.0f);
      radii.bottom_right = DlSize(3.0f, 4.0f);
      radii.bottom_left = DlSize(5.0f, 4.0f);
      break;
    case RRectType::kComplex:
      radii.top_left = DlSize(5.0f, 4.0f);
      radii.top_right = DlSize(4.0f, 5.0f);
      radii.bottom_right = DlSize(3.0f, 6.0f);
      radii.bottom_left = DlSize(2.0f, 7.0f);
      break;
    default:
      FML_UNREACHABLE();
  }

  const DlPoint delta = DlPoint(0.5f, 0.5f);
  const DlScalar multiplier = length / 16.0f;
  RectAnimator animator(DlRect::MakeWH(length, length), delta, surface);

  radii = radii * multiplier;

  state.counters["DrawCallCount"] = kRSEsToDraw;
  for (size_t i = 0; i < kRSEsToDraw; i++) {
    DlRoundSuperellipse rse =
        DlRoundSuperellipse::MakeRectRadii(animator.GetRect(), radii);
    builder.DrawRoundSuperellipse(rse, paint);
    animator.Animate();
  }
  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kRSEsToDraw);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kRSEsToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawRSE");
}

void BM_DrawSimpleRSE(benchmark::State& state,
                      BackendType backend_type,
                      unsigned attributes) {
  BM_DrawRSE(state, backend_type, attributes, RRectType::kSimple);
}

void BM_DrawNinePatchRSE(benchmark::State& state,
                         BackendType backend_type,
                         unsigned attributes) {
  BM_DrawRSE(state, backend_type, attributes, RRectType::kNinePatch);
}

void BM_DrawComplexRSE(benchmark::State& state,
                       BackendType backend_type,
                       unsigned attributes) {
  BM_DrawRSE(state, backend_type, attributes, RRectType::kComplex);
}

// Draws a series of "DR" rects of the requested width across
// the canvas and repeats until `kRRectsToDraw` rects have been drawn.
//
// A "DR" rect is a shape consisting of the difference between two
// rounded rects.
//
// Half the drawn DR rects will not have an integral offset.
void BM_DrawDRRect(benchmark::State& state,
                   BackendType backend_type,
                   unsigned attributes,
                   RRectType type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawDRRectFlags);

  size_t length = state.range(0);
  surface_provider->InitializeSurface(length * 2, length * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlRoundingRadii radii;
  // Keep all radii under 6 so that they won't underflow on the inner rect
  // which is 16 - 2 * 0.1 * 16 == 12.8 units wide and tall at the smallest.
  switch (type) {
    case RRectType::kSimple:
      radii.top_left = DlSize(5.0f, 5.0f);
      radii.top_right = DlSize(5.0f, 5.0f);
      radii.bottom_right = DlSize(5.0f, 5.0f);
      radii.bottom_left = DlSize(5.0f, 5.0f);
      break;
    case RRectType::kNinePatch:
      radii.top_left = DlSize(5.0f, 6.0f);
      radii.top_right = DlSize(3.0f, 6.0f);
      radii.bottom_right = DlSize(3.0f, 4.0f);
      radii.bottom_left = DlSize(5.0f, 4.0f);
      break;
    case RRectType::kComplex:
      radii.top_left = DlSize(5.0f, 4.0f);
      radii.top_right = DlSize(4.0f, 5.0f);
      radii.bottom_right = DlSize(3.0f, 6.0f);
      radii.bottom_left = DlSize(6.0f, 3.0f);
      break;
    default:
      FML_UNREACHABLE();
  }

  const DlPoint delta(0.5f, 0.5f);
  const DlScalar inner_scale = -0.1f * length;
  const DlScalar multiplier = length / 16.0f;
  DlRoundingRadii scaled_radii = radii * multiplier;

  RectAnimator animator(DlRect::MakeWH(length, length), delta, surface);

  state.counters["DrawCallCount"] = kDRRectsToDraw;
  for (size_t i = 0; i < kDRRectsToDraw; i++) {
    const DlRect outer_rect = animator.GetRect();
    const DlRect inner_rect = outer_rect.Expand(inner_scale);
    DlRoundRect outer = DlRoundRect::MakeRectRadii(outer_rect, scaled_radii);
    DlRoundRect inner = DlRoundRect::MakeRectRadii(inner_rect, scaled_radii);
    builder.DrawDiffRoundRect(outer, inner, paint);
    animator.Animate();
  }
  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kDRRectsToDraw);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kDRRectsToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawDRRect");
}

void BM_DrawArc(benchmark::State& state,
                BackendType backend_type,
                unsigned attributes) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawArcNoCenterFlags);

  size_t length = state.range(0);
  surface_provider->InitializeSurface(length * 2, length * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlScalar starting_angle = 0.0f;
  DlPoint delta(0.5f, 0.5f);

  // Just some random sweeps that will mostly circumnavigate the circle
  std::vector<DlScalar> segment_sweeps = {5.5f,  -10.0f, 42.0f, 71.7f, 90.0f,
                                          37.5f, 17.9f,  32.0f, 379.4f};

  DlSize size(length, length);
  RectAnimator animator(DlRect::MakeSize(size), delta, surface);

  size_t total_call_count = kArcSweepSetsToDraw * segment_sweeps.size();
  state.counters["DrawCallCount"] = total_call_count;
  for (size_t i = 0; i < kArcSweepSetsToDraw; i++) {
    for (DlScalar sweep : segment_sweeps) {
      builder.DrawArc(animator.GetRect(), starting_angle, sweep, false, paint);
      starting_angle += sweep + 5.0f;
    }
    animator.Animate();
  }

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= total_call_count);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += total_call_count;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state, "DrawArc");
}

// Returns a list of DlPoints that represent `n` points equally spaced out
// along the circumference of a circle with radius `r` and centered on `center`.
std::vector<DlPoint> GetPolygonPoints(size_t n, DlPoint center, DlScalar r) {
  std::vector<DlPoint> points;
  DlScalar x, y;
  float angle;
  float full_circle = 2.0f * M_PI;
  for (size_t i = 0; i < n; i++) {
    angle = (full_circle / static_cast<float>(n)) * static_cast<float>(i);
    x = center.x + r * std::cosf(angle);
    y = center.y + r * std::sinf(angle);
    points.emplace_back(x, y);
  }
  return points;
}

// Creates a path that represents a regular polygon with `sides` sides,
// centered on `center` with a radius of `radius`. The control points are
// equally spaced out along the circumference of the circle described by
// `radius` and `center`.
//
// The path segment connecting each control point is a line segment.
void GetLinesPath(DlPathBuilder& path_builder,
                  size_t sides,
                  DlPoint center,
                  float radius) {
  std::vector<DlPoint> points = GetPolygonPoints(sides, center, radius);
  path_builder.MoveTo(points[0]);
  for (size_t i = 1; i < sides; i++) {
    path_builder.LineTo(points[i]);
  }
  path_builder.LineTo(points[0]);
  path_builder.Close();
}

// Creates a path that represents a regular polygon with `sides` sides,
// centered on `center` with a radius of `radius`. The control points are
// equally spaced out along the circumference of the circle described by
// `radius` and `center`.
//
// The path segment connecting each control point is a quad bezier, with the
// bezier control point being on a circle with 80% of `radius` and with the
// control point angle half way between the start and end point angles for the
// polygon segment.
void GetQuadsPath(DlPathBuilder& path_builder,
                  size_t sides,
                  DlPoint center,
                  float radius) {
  std::vector<DlPoint> points = GetPolygonPoints(sides, center, radius);
  std::vector<DlPoint> control_points =
      GetPolygonPoints(sides * 2, center, radius * 0.8f);

  path_builder.MoveTo(points[0]);
  for (size_t i = 1; i < sides; i++) {
    path_builder.QuadraticCurveTo(control_points[2 * i - 1], points[i]);
  }
  path_builder.QuadraticCurveTo(control_points[2 * sides - 1], points[0]);
  path_builder.Close();
}

// Creates a path that represents a regular polygon with `sides` sides,
// centered on `center` with a radius of `radius`. The control points are
// equally spaced out along the circumference of the circle described by
// `radius` and `center`.
//
// The path segment connecting each control point is a conic, with the
// control point being on a circle with 80% of `radius` and with the
// control point angle half way between the start and end point angles for the
// polygon segment, and the conic weight set to 3.7f.
void GetConicsPath(DlPathBuilder& path_builder,
                   size_t sides,
                   DlPoint center,
                   float radius) {
  std::vector<DlPoint> points = GetPolygonPoints(sides, center, radius);
  std::vector<DlPoint> control_points =
      GetPolygonPoints(sides * 2, center, radius * 0.8f);

  path_builder.MoveTo(points[0]);
  for (size_t i = 1; i < sides; i++) {
    path_builder.ConicCurveTo(control_points[2 * i - 1], points[i], 3.7f);
  }
  path_builder.ConicCurveTo(control_points[2 * sides - 1], points[0], 3.7f);
  path_builder.Close();
}

// Creates a path that represents a regular polygon with `sides` sides,
// centered on `center` with a radius of `radius`. The control points are
// equally spaced out along the circumference of the circle described by
// `radius` and `center`.
//
// The path segment connecting each control point is a cubic, with the first
// control point being on a circle with 80% of `radius` and with the second
// control point being on a circle with 120% of `radius`. The first
// control point is 1/3, and the second control point is 2/3, of the angle
// between the start and end point angles for the polygon segment.
void GetCubicsPath(DlPathBuilder& path_builder,
                   size_t sides,
                   DlPoint center,
                   float radius) {
  std::vector<DlPoint> points = GetPolygonPoints(sides, center, radius);
  std::vector<DlPoint> inner_control_points =
      GetPolygonPoints(sides * 3, center, radius * 0.8f);
  std::vector<DlPoint> outer_control_points =
      GetPolygonPoints(sides * 3, center, radius * 1.2f);

  path_builder.MoveTo(points[0]);
  for (size_t i = 1; i < sides; i++) {
    path_builder.CubicCurveTo(inner_control_points[3 * i - 2],
                              outer_control_points[3 * i - 1], points[i]);
  }
  path_builder.CubicCurveTo(inner_control_points[3 * sides - 2],
                            outer_control_points[3 * sides - 1], points[0]);
  path_builder.Close();
}

// Returns a path generated by one of the above path generators
// which is multiplied `number` times centered on each of the `number` control
// points along the circumference of a circle centered on `center` with radius
// `radius`.
//
// Each of the polygons will have `sides` sides, and the resulting path will be
// bounded by a circle with radius of 150% of `radius` (or another 20% on top of
// that for cubics)
void MultiplyPath(DlPathBuilder& path_builder,
                  PathVerb type,
                  DlPoint center,
                  size_t sides,
                  size_t number,
                  float radius) {
  std::vector<DlPoint> center_points =
      GetPolygonPoints(number, center, radius / 2.0f);

  for (DlPoint p : center_points) {
    switch (type) {
      case PathVerb::kLine:
        GetLinesPath(path_builder, sides, p, radius);
        break;
      case PathVerb::kQuad:
        GetQuadsPath(path_builder, sides, p, radius);
        break;
      case PathVerb::kConic:
        GetConicsPath(path_builder, sides, p, radius);
        break;
      case PathVerb::kCubic:
        GetCubicsPath(path_builder, sides, p, radius);
        break;
      default:
        break;
    }
  }
}

std::string VerbToString(PathVerb type) {
  switch (type) {
    case PathVerb::kLine:
      return "Lines";
    case PathVerb::kQuad:
      return "Quads";
    case PathVerb::kConic:
      return "Conics";
    case PathVerb::kCubic:
      return "Cubics";
    default:
      return "Unknown";
  }
}

// Draws a series of overlapping 20-sided polygons where the path segment
// between each point is one of the verb types defined in PathVerb.
//
// The number of polygons drawn will be varied to get an overall path
// with approximately 20*N verbs, so we can get an idea of the fixed
// cost of using drawPath as well as an idea of how the cost varies according
// to the verb count.
void BM_DrawPath(benchmark::State& state,
                 BackendType backend_type,
                 unsigned attributes,
                 PathVerb type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawPathFlags);

  size_t length = kFixedCanvasSize;
  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlPathBuilder path_builder;

  std::string label = VerbToString(type);
  DlPoint center = DlPoint(length / 2.0f, length / 2.0f);
  float radius = length * 0.25f;
  state.SetComplexityN(state.range(0));

  MultiplyPath(path_builder, type, center, 20, state.range(0), radius);
  DlPath path = path_builder.TakePath();

  DlPathVerbCounter counter;
  path.Dispatch(counter);
  state.counters["VerbCount"] = counter.GetVerbCount();
  state.counters["DrawCallCount"] = 1;

  builder.DrawPath(path, paint);
  auto display_list = builder.Build();

  // Prime any path conversions
  surface->RenderDisplayList(display_list);
  surface->FlushSubmitCpuSync();

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += counter.GetVerbCount();
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state,
                          "DrawPath-" + label);
}

// Returns a set of vertices that describe a circle that has a
// radius of `radius` and outer vertex count of approximately
// `vertex_count`. The final number of vertices will differ as we
// need to ensure the correct usage of vertices to ensure we do not
// request degenerate triangles be drawn. This final count is output
// through `final_vertex_count`.
//
// The resulting vertices will describe a disc consisting of a series
// of triangles with two vertices on the circumference of the disc,
// and the final vertex being the center point of the disc.
//
// Each vertex colour will alternate through Red, Green, Blue and Cyan.
std::shared_ptr<DlVertices> GetTestVertices(DlPoint center,
                                            float radius,
                                            size_t vertex_count,
                                            DlVertexMode mode,
                                            size_t& final_vertex_count) {
  size_t outer_vertex_count = vertex_count / 2;
  std::vector<DlPoint> outer_points =
      GetPolygonPoints(outer_vertex_count, center, radius);

  std::vector<DlPoint> vertices;
  std::vector<DlColor> colors;

  switch (mode) {
    case DlVertexMode::kTriangleFan:
      // Calling the points on the outer circle O_0, O_1, O_2, ..., and
      // the center point C, this should create a triangle fan with vertices
      // C, O_0, O_1, O_2, O_3, ...
      vertices.push_back(center);
      colors.push_back(DlColor(SK_ColorCYAN));
      for (size_t i = 0; i <= outer_points.size(); i++) {
        vertices.push_back(outer_points[i % outer_points.size()]);
        if (i % 3 == 0) {
          colors.push_back(DlColor(SK_ColorRED));
        } else if (i % 3 == 1) {
          colors.push_back(DlColor(SK_ColorGREEN));
        } else {
          colors.push_back(DlColor(SK_ColorBLUE));
        }
      }
      break;
    case DlVertexMode::kTriangles:
      // Calling the points on the outer circle O_0, O_1, O_2, ..., and
      // the center point C, this should create a series of triangles with
      // vertices O_0, O_1, C, O_1, O_2, C, O_2, O_3, C, ...
      for (size_t i = 0; i < outer_vertex_count; i++) {
        vertices.push_back(outer_points[i % outer_points.size()]);
        colors.push_back(DlColor(SK_ColorRED));
        vertices.push_back(outer_points[(i + 1) % outer_points.size()]);
        colors.push_back(DlColor(SK_ColorGREEN));
        vertices.push_back(center);
        colors.push_back(DlColor(SK_ColorBLUE));
      }
      break;
    case DlVertexMode::kTriangleStrip:
      // Calling the points on the outer circle O_0, O_1, O_2, ..., and
      // the center point C, this should create a strip with vertices
      // O_0, O_1, C, O_2, O_3, C, O_4, O_5, C, ...
      for (size_t i = 0; i <= outer_vertex_count; i++) {
        vertices.push_back(outer_points[i % outer_points.size()]);
        colors.push_back(i % 2 ? DlColor(SK_ColorRED) : DlColor(SK_ColorGREEN));
        if (i % 2 == 1) {
          vertices.push_back(center);
          colors.push_back(DlColor(SK_ColorBLUE));
        }
      }
      break;
    default:
      break;
  }

  final_vertex_count = vertices.size();
  return DlVertices::Make(mode, vertices.size(), vertices.data(), nullptr,
                          colors.data());
}

std::string VertexModeToString(DlVertexMode mode) {
  switch (mode) {
    case DlVertexMode::kTriangleStrip:
      return "TriangleStrip";
    case DlVertexMode::kTriangleFan:
      return "TriangleFan";
    case DlVertexMode::kTriangles:
      return "Triangles";
  }
  return "Unknown";
}

// Draws a series of discs generated by `GetTestVertices()` with
// 50 vertices in each disc. The number of discs drawn will vary according
// to the benchmark input, and the benchmark will automatically calculate
// the Big-O complexity of `DrawVertices` with N being the number of vertices
// being drawn.
//
// The discs drawn will be centered on points along a circle with radius of 25%
// of the canvas width/height, with each point being equally spaced out.
void BM_DrawVertices(benchmark::State& state,
                     BackendType backend_type,
                     unsigned attributes,
                     DlVertexMode mode) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawVerticesFlags);

  size_t length = kFixedCanvasSize;
  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlPoint center = DlPoint(length / 2.0f, length / 2.0f);

  float radius = length / 4.0f;

  size_t vertex_count, total_vertex_count = 0;
  size_t disc_count = state.range(0);

  std::vector<DlPoint> center_points =
      GetPolygonPoints(disc_count, center, radius / 4.0f);

  state.counters["DrawCallCount"] = center_points.size();
  for (DlPoint p : center_points) {
    std::shared_ptr<DlVertices> vertices =
        GetTestVertices(p, radius, 50, mode, vertex_count);
    total_vertex_count += vertex_count;
    builder.DrawVertices(vertices, DlBlendMode::kSrc, paint);
  }

  state.counters["VertexCount"] = total_vertex_count;
  state.SetComplexityN(total_vertex_count);

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= center_points.size());

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += total_vertex_count;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state,
                          "DrawVertices-" + std::to_string(disc_count) + "-" +
                              VertexModeToString(mode));
}

// Generate `count` test points.
//
// The points are distributed using some fixed constant offsets that were
// chosen to appear somewhat random.
//
// The points generated will wrap in x and y for the bounds of `canvas_size`.
std::vector<DlPoint> GetTestPoints(size_t count, DlISize canvas_size) {
  std::vector<DlPoint> points;

  // Some arbitrary offsets to use when building the list of points
  std::vector<DlScalar> delta_x = {10.0f, 6.3f, 15.0f, 3.5f, 22.6f, 4.7f};
  std::vector<DlScalar> delta_y = {9.3f, -5.4f, 8.5f, -12.0f, 19.2f, -19.6f};

  DlPoint current;
  for (size_t i = 0; i < count; i++) {
    points.push_back(current);
    current +=
        DlPoint(delta_x[i % delta_x.size()], delta_y[i % delta_y.size()]);
    if (current.x > canvas_size.width) {
      current += DlPoint(-canvas_size.width, 25.0f);
    }
    if (current.y > canvas_size.height) {
      current += DlPoint(0.0f, -canvas_size.height);
    }
  }

  return points;
}

std::string PointModeToString(DlPointMode mode) {
  switch (mode) {
    case DlPointMode::kLines:
      return "Lines";
    case DlPointMode::kPolygon:
      return "Polygon";
    case DlPointMode::kPoints:
    default:
      return "Points";
  }
}

// Draws a series of points generated by `GetTestPoints()` above to
// a fixed-size canvas. The benchmark will vary the number of points drawn,
// and they can be drawn in one of three modes - Lines, Polygon or Points mode.
//
// This benchmark will automatically calculate the Big-O complexity of
// `DrawPoints` with N being the number of points being drawn.
void BM_DrawPoints(benchmark::State& state,
                   BackendType backend_type,
                   unsigned attributes,
                   DlPointMode mode) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  switch (mode) {
    case DlPointMode::kPoints:
      CheckAttributes(attributes, state,
                      DisplayListOpFlags::kDrawPointsAsPointsFlags);
      break;
    case DlPointMode::kLines:
      CheckAttributes(attributes, state,
                      DisplayListOpFlags::kDrawPointsAsLinesFlags);
      break;
    case DlPointMode::kPolygon:
      CheckAttributes(attributes, state,
                      DisplayListOpFlags::kDrawPointsAsPolygonFlags);
      break;
  }

  size_t length = kFixedCanvasSize;
  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  size_t point_count = state.range(0);
  state.SetComplexityN(point_count);
  state.counters["PointCount"] = point_count;
  state.counters["DrawCallCount"] = 1;

  std::vector<DlPoint> points = GetTestPoints(point_count, surface->GetSize());
  builder.DrawPoints(mode, points.size(), points.data(), paint);

  auto display_list = builder.Build();

  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += point_count;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state,
                          "DrawPoints-" + PointModeToString(mode) + "-" +
                              std::to_string(point_count));
}

sk_sp<SkImage> ImageFromBitmapWithNewID(const SkBitmap& bitmap) {
  // If we create an SkPixmap with a ref to the SkBitmap's pixel data,
  // then create an SkImage from that, we always get a new generation ID,
  // so we will avoid hitting the cache.
  SkPixmap pixmap;
  bitmap.peekPixels(&pixmap);
  return SkImages::RasterFromPixmap(pixmap, nullptr, nullptr);
}

// Draws `kImagesToDraw` bitmaps to a canvas, either with texture-backed
// bitmaps or bitmaps that need to be uploaded to the GPU first.
void BM_DrawImage(benchmark::State& state,
                  BackendType backend_type,
                  unsigned attributes,
                  DlImageSampling options,
                  bool upload_bitmap) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state,
                  DisplayListOpFlags::kDrawImageWithPaintFlags);

  size_t bitmap_size = state.range(0);
  surface_provider->InitializeSurface(bitmap_size * 2, bitmap_size * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  sk_sp<DlImage> image;
  SkBitmap bitmap;

  if (upload_bitmap) {
    SkImageInfo info = SkImageInfo::Make(bitmap_size, bitmap_size,
                                         SkColorType::kRGBA_8888_SkColorType,
                                         SkAlphaType::kPremul_SkAlphaType);
    bitmap.allocPixels(info, 0);
    bitmap.eraseColor(SK_ColorBLUE);
  } else {
    image = MakeTestImage(bitmap_size, bitmap_size, DlColor::kRed());
  }

  const DlPoint delta(0.5f, 0.5f);
  const DlSize size(bitmap_size, bitmap_size);
  RectAnimator animator(DlRect::MakeSize(size), delta, surface);

  state.counters["DrawCallCount"] = kImagesToDraw;
  for (size_t i = 0; i < kImagesToDraw; i++) {
    if (upload_bitmap) {
      auto sk_image = ImageFromBitmapWithNewID(bitmap);
      image = DlImageSkia::Make(sk_image);
    }
    builder.DrawImage(image, animator.GetPoint(), options, &paint);
    animator.Animate();
  }

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kImagesToDraw);

  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kImagesToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  std::string image_type = (upload_bitmap ? "Upload-" : "Texture-");
  SaveSnapshotIfNecessary(
      surface_provider, surface, state,
      "DrawImage-" + image_type + std::to_string(bitmap_size));
}

std::string ConstraintToString(DlSrcRectConstraint constraint) {
  switch (constraint) {
    case DlSrcRectConstraint::kStrict:
      return "Strict";
    case DlSrcRectConstraint::kFast:
      return "Fast";
    default:
      return "Unknown";
  }
}

// Draws `kImagesToDraw` bitmaps to a canvas, either with texture-backed
// bitmaps or bitmaps that need to be uploaded to the GPU first.
//
// The bitmaps are shrunk down to 75% of their size when rendered to the canvas.
void BM_DrawImageRect(benchmark::State& state,
                      BackendType backend_type,
                      unsigned attributes,
                      DlImageSampling options,
                      DlSrcRectConstraint constraint,
                      bool upload_bitmap) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state,
                  DisplayListOpFlags::kDrawImageRectWithPaintFlags);

  size_t bitmap_size = state.range(0);
  surface_provider->InitializeSurface(bitmap_size * 2, bitmap_size * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  sk_sp<DlImage> image;
  SkBitmap bitmap;

  if (upload_bitmap) {
    SkImageInfo info = SkImageInfo::Make(bitmap_size, bitmap_size,
                                         SkColorType::kRGBA_8888_SkColorType,
                                         SkAlphaType::kPremul_SkAlphaType);
    bitmap.allocPixels(info, 0);
    bitmap.eraseColor(SK_ColorBLUE);
  } else {
    image = MakeTestImage(bitmap_size, bitmap_size, DlColor::kRed());
  }

  const DlPoint delta(0.5f, 0.5f);
  DlRect src = DlRect::MakeXYWH(bitmap_size / 4.0f, bitmap_size / 4.0f,
                                bitmap_size / 2.0f, bitmap_size / 2.0f);
  DlSize size(bitmap_size * 0.75f, bitmap_size * 0.75f);
  RectAnimator animator(DlRect::MakeSize(size), delta, surface);

  state.counters["DrawCallCount"] = kImagesToDraw;
  for (size_t i = 0; i < kImagesToDraw; i++) {
    if (upload_bitmap) {
      auto sk_image = ImageFromBitmapWithNewID(bitmap);
      image = DlImageSkia::Make(sk_image);
    }
    builder.DrawImageRect(image, src, animator.GetRect(), options, &paint,
                          constraint);
    animator.Animate();
  }

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kImagesToDraw);

  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kImagesToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  std::string image_type = (upload_bitmap ? "Upload-" : "Texture-");
  SaveSnapshotIfNecessary(surface_provider, surface, state,
                          "DrawImageRect-" + image_type +
                              ConstraintToString(constraint) + "-" +
                              std::to_string(bitmap_size));
}

std::string FilterModeToString(const DlFilterMode mode) {
  switch (mode) {
    case DlFilterMode::kNearest:
      return "Nearest";
    case DlFilterMode::kLinear:
      return "Linear";
    default:
      return "Unknown";
  }
}

// Draws `kImagesToDraw` bitmaps to a canvas, either with texture-backed
// bitmaps or bitmaps that need to be uploaded to the GPU first.
//
// The image is split into 9 sub-rects and stretched proportionally for final
// rendering.
void BM_DrawImageNine(benchmark::State& state,
                      BackendType backend_type,
                      unsigned attributes,
                      const DlFilterMode filter,
                      bool upload_bitmap) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state,
                  DisplayListOpFlags::kDrawImageNineWithPaintFlags);

  size_t bitmap_size = state.range(0);
  surface_provider->InitializeSurface(bitmap_size * 2, bitmap_size * 2);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlIRect center = DlIRect::MakeXYWH(bitmap_size / 4, bitmap_size / 4,
                                     bitmap_size / 2, bitmap_size / 2);

  sk_sp<DlImage> image;
  SkBitmap bitmap;

  if (upload_bitmap) {
    SkImageInfo info = SkImageInfo::Make(bitmap_size, bitmap_size,
                                         SkColorType::kRGBA_8888_SkColorType,
                                         SkAlphaType::kPremul_SkAlphaType);
    bitmap.allocPixels(info, 0);
    bitmap.eraseColor(SK_ColorBLUE);
  } else {
    image = MakeTestImage(bitmap_size, bitmap_size, DlColor::kRed());
  }

  const DlPoint delta(0.5f, 0.5f);
  DlSize size(bitmap_size * 0.75f, bitmap_size * 0.75f);
  RectAnimator animator(DlRect::MakeSize(size), delta, surface);

  state.counters["DrawCallCount"] = kImagesToDraw;
  for (size_t i = 0; i < kImagesToDraw; i++) {
    if (upload_bitmap) {
      auto sk_image = ImageFromBitmapWithNewID(bitmap);
      image = DlImageSkia::Make(sk_image);
    }
    builder.DrawImageNine(image, center, animator.GetRect(), filter, &paint);
    animator.Animate();
  }

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= kImagesToDraw);

  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += kImagesToDraw;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  std::string image_type = (upload_bitmap ? "Upload-" : "Texture-");
  SaveSnapshotIfNecessary(surface_provider, surface, state,
                          "DrawImageNine-" + image_type +
                              FilterModeToString(filter) + "-" +
                              std::to_string(bitmap_size));
}

// Draws a series of glyph runs with 32 glyphs in each run. The number of runs
// may vary according to the benchmark parameters. The text will start in the
// upper left corner of the canvas and advance from left to right and wrap at
// the canvas boundaries in both x and y.
//
// This benchmark will automatically calculate the Big-O complexity of
// `DrawTextBlob` with N being the number of glyphs being drawn.
void BM_DrawTextBlob(benchmark::State& state,
                     BackendType backend_type,
                     unsigned attributes) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawTextFlags);

  size_t draw_calls = state.range(0);
  surface_provider->InitializeSurface(kFixedCanvasSize, kFixedCanvasSize);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  state.SetComplexityN(draw_calls);
  state.counters["DrawCallCount_Varies"] = draw_calls;
  state.counters["GlyphCount"] = draw_calls;
  char character[2] = {'A', '\0'};

  for (size_t i = 0; i < draw_calls; i++) {
    character[0] = 'A' + (i % 26);
    auto blob = SkTextBlob::MakeFromString(character, CreateTestFontOfSize(20));
    builder.DrawText(DlTextSkia::Make(blob), 50.0f, 50.0f, paint);
  }

  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= draw_calls);

  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += draw_calls;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state,
                          "DrawTextBlob-" + std::to_string(draw_calls));
}

// Draw the shadow for a 10-sided regular polygon where the polygon's
// sides are denoted by one of a Line, Quad, Conic or Cubic path segment.
//
// The elevation of the light source will vary according to the benchmark
// paremeters.
//
// The benchmark can be run with either a transparent occluder or an opaque
// occluder.
void BM_DrawShadow(benchmark::State& state,
                   BackendType backend_type,
                   unsigned attributes,
                   bool transparent_occluder,
                   PathVerb type) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kDrawShadowFlags);

  size_t length = kFixedCanvasSize;
  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  DlPathBuilder path_builder;

  DlPoint center = DlPoint(length / 2.0f, length / 2.0f);
  float radius = length * 0.25f;

  switch (type) {
    case PathVerb::kLine:
      GetLinesPath(path_builder, 10, center, radius);
      break;
    case PathVerb::kQuad:
      GetQuadsPath(path_builder, 10, center, radius);
      break;
    case PathVerb::kConic:
      GetConicsPath(path_builder, 10, center, radius);
      break;
    case PathVerb::kCubic:
      GetCubicsPath(path_builder, 10, center, radius);
      break;
    default:
      break;
  }

  float elevation = state.range(0);
  state.counters["DrawCallCount"] = 1;

  DlPath path = path_builder.TakePath();

  // We can hardcode dpr to 1.0f as we're varying elevation, and dpr is only
  // ever used in conjunction with elevation.
  builder.DrawShadow(path, DlColor(SK_ColorBLUE), elevation,
                     transparent_occluder, 1.0f);
  auto display_list = builder.Build();

  // Prime the path conversion.
  surface->RenderDisplayList(display_list);
  surface->FlushSubmitCpuSync();

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += 1;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(
      surface_provider, surface, state,
      "DrawShadow-" + VerbToString(type) + "-" +
          (transparent_occluder ? "Transparent-" : "Opaque-") +
          std::to_string(elevation));
}

// Calls saveLayer N times from the root canvas layer, and optionally calls
// saveLayer a further M times nested inside that top saveLayer call.
//
// The total number of saveLayer calls will be N * (M+1).
//
// In each saveLayer call, simply draw the colour red with no clip rect.
void BM_SaveLayer(benchmark::State& state,
                  BackendType backend_type,
                  unsigned attributes,
                  size_t save_depth) {
  auto surface_provider = DlSurfaceProvider::Create(backend_type);
  DisplayListBuilder builder;
  DlPaint paint = GetPaintForRun(attributes);

  CheckAttributes(attributes, state, DisplayListOpFlags::kSaveLayerFlags);

  size_t length = kFixedCanvasSize;
  surface_provider->InitializeSurface(length, length);
  auto surface = surface_provider->GetPrimarySurface();
  surface->Clear(DlColor::kTransparent());
  surface->FlushSubmitCpuSync();

  size_t save_layer_calls = state.range(0);

  // Ensure we draw two overlapping rects to avoid any peephole optimisations
  DlRect rect1 = DlRect::MakeLTRB(0, 0, 0.75f * length, 0.75f * length);
  DlRect rect2 =
      DlRect::MakeLTRB(0.25f * length, 0.25f * length, length, length);

  size_t total_save_calls = save_layer_calls * save_depth;
  state.counters["DrawCallCount_Varies"] = total_save_calls;
  for (size_t i = 0; i < save_layer_calls; i++) {
    for (size_t j = 0; j < save_depth; j++) {
      builder.SaveLayer(std::nullopt, nullptr);
      builder.DrawRect(rect1, paint);
      builder.DrawRect(rect2, paint);
    }
    for (size_t j = 0; j < save_depth; j++) {
      builder.Restore();
    }
  }
  auto display_list = builder.Build();
  FML_CHECK(display_list->GetRecordCount() >= total_save_calls);

  // We only want to time the actual rasterization.
  size_t items_processed = 0;
  for ([[maybe_unused]] auto _ : state) {
    surface->RenderDisplayList(display_list);
    items_processed += total_save_calls;
    surface->FlushSubmitCpuSync();
  }
  state.SetItemsProcessed(items_processed);

  SaveSnapshotIfNecessary(surface_provider, surface, state,
                          "SaveLayer-" + std::to_string(save_depth) + "x" +
                              std::to_string(save_layer_calls));
}

#ifdef DISPLAY_LIST_BENCHMARK_ALL_OPS

#ifdef ENABLE_SOFTWARE_BENCHMARKS
RUN_DISPLAYLIST_BENCHMARKS(SkiaSoftware)
#endif

#ifdef ENABLE_OPENGL_BENCHMARKS
RUN_DISPLAYLIST_BENCHMARKS(SkiaOpenGL)
#endif

#ifdef ENABLE_METAL_BENCHMARKS
RUN_DISPLAYLIST_BENCHMARKS(SkiaMetal)
RUN_DISPLAYLIST_BENCHMARKS(ImpellerMetal)
RUN_DISPLAYLIST_BENCHMARKS(ImpellerMetalSDF)
#endif

#else  // DISPLAY_LIST_BENCHMARK_ALL_OPS

// clang-format off

constexpr int kAAFilledPrimitive =
    kAntiAliasing | kFilledStyle;
constexpr int kAAHairlinePrimitive =
    kAntiAliasing | kStrokedStyle | kHairlineStroke;
constexpr int kAAStroke10Primitive =
    kAntiAliasing | kStrokedStyle | kWideStroke10;

#define BENCHMARK_PRIMITIVE_SYNC_OVERHEAD(BACKEND)                           \
  BENCHMARK_CAPTURE(BM_SyncOverhead, BACKEND, BackendType::k##BACKEND)       \
      ->RangeMultiplier(4)                                                   \
      ->Range(16, 1024)                                                      \
      ->UseRealTime()                                                        \
      ->Unit(benchmark::kNanosecond);

#define BENCHMARK_PRIMITIVE_EMPTY_DISPLAY_LIST_OVERHEAD(BACKEND)             \
  BENCHMARK_CAPTURE(BM_EmptyDisplayList, BACKEND, BackendType::k##BACKEND)   \
      ->RangeMultiplier(4)                                                   \
      ->Range(16, 1024)                                                      \
      ->UseRealTime()                                                        \
      ->Unit(benchmark::kNanosecond);

#define BENCHMARK_PRIMITIVE_SINGLE_OP_DISPLAY_LIST_OVERHEAD(BACKEND)         \
  BENCHMARK_CAPTURE(BM_SingleOpDisplayList, BACKEND,                         \
                    BackendType::k##BACKEND)                                 \
      ->RangeMultiplier(4)                                                   \
      ->Range(16, 1024)                                                      \
      ->UseRealTime()                                                        \
      ->Unit(benchmark::kNanosecond);

#define DRAW_BENCHMARK_PRIMITIVES(BACKEND, TYPE, ATTRIBUTES)                 \
  BENCHMARK_CAPTURE(BM_Draw##TYPE, ATTRIBUTES/BACKEND,                       \
                    BackendType::k##BACKEND,                                 \
                    k##ATTRIBUTES##Primitive)                                \
      ->RangeMultiplier(4)                                                   \
      ->Range(16, 1024)                                                      \
      ->UseRealTime()                                                        \
      ->Unit(benchmark::kMillisecond);

#define DRAW_BENCHMARK_PRIMITIVES_LINE(BACKEND)                              \
  DRAW_BENCHMARK_PRIMITIVES(BACKEND, Line, AAHairline)                       \
  DRAW_BENCHMARK_PRIMITIVES(BACKEND, Line, AAStroke10)

#define DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, TYPE)                        \
  DRAW_BENCHMARK_PRIMITIVES(BACKEND, TYPE, AAFilled)                         \
  DRAW_BENCHMARK_PRIMITIVES(BACKEND, TYPE, AAHairline)                       \
  DRAW_BENCHMARK_PRIMITIVES(BACKEND, TYPE, AAStroke10)                       \

#define DRAW_BENCHMARK_PRIMITIVE_SUITE(BACKEND)                              \
  BENCHMARK_PRIMITIVE_SYNC_OVERHEAD(BACKEND)                                 \
  BENCHMARK_PRIMITIVE_EMPTY_DISPLAY_LIST_OVERHEAD(BACKEND)                   \
  BENCHMARK_PRIMITIVE_SINGLE_OP_DISPLAY_LIST_OVERHEAD(BACKEND)               \
  DRAW_BENCHMARK_PRIMITIVES_LINE(BACKEND)                                    \
  DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, Rect)                              \
  DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, Oval)                              \
  DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, Circle)                            \
  DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, SimpleRRect)                       \
  DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, ComplexRRect)                      \
  DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, SimpleRSE)                         \
  DRAW_BENCHMARK_PRIMITIVES_TYPE(BACKEND, ComplexRSE)

// clang-format on

#ifdef ENABLE_SOFTWARE_BENCHMARKS
DRAW_BENCHMARK_PRIMITIVE_SUITE(SkiaSoftware)
#endif

#ifdef ENABLE_OPENGL_BENCHMARKS
DRAW_BENCHMARK_PRIMITIVE_SUITE(SkiaOpenGL)
#endif

#ifdef ENABLE_METAL_BENCHMARKS
DRAW_BENCHMARK_PRIMITIVE_SUITE(SkiaMetal)
DRAW_BENCHMARK_PRIMITIVE_SUITE(ImpellerMetal)
DRAW_BENCHMARK_PRIMITIVE_SUITE(ImpellerMetalSDF)
#endif

#endif  // DISPLAY_LIST_BENCHMARK_ALL_OPS

}  // namespace testing
}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_raster_cache.h"

namespace flutter {
namespace testing {

MockRasterCacheResult::MockRasterCacheResult(SkRect device_rect)
    : RasterCacheResult(nullptr, SkRect::MakeEmpty(), "RasterCacheFlow::test"),
      device_rect_(device_rect) {}

std::unique_ptr<RasterCacheResult> MockRasterCache::RasterizeDisplayList(
    DisplayList* display_list,
    GrDirectContext* context,
    const SkMatrix& ctm,
    SkColorSpace* dst_color_space,
    bool checkerboard) const {
  SkRect logical_rect = display_list->bounds();
  SkRect cache_rect = RasterCache::GetDeviceBounds(logical_rect, ctm);

  return std::make_unique<MockRasterCacheResult>(cache_rect);
}

std::unique_ptr<RasterCacheResult> MockRasterCache::RasterizeLayer(
    PrerollContext* context,
    Layer* layer,
    RasterCacheLayerStrategy strategy,
    const SkMatrix& ctm,
    bool checkerboard) const {
  SkRect logical_rect = layer->paint_bounds();
  SkRect cache_rect = RasterCache::GetDeviceBounds(logical_rect, ctm);

  return std::make_unique<MockRasterCacheResult>(cache_rect);
}

void MockRasterCache::AddMockLayer(int width, int height) {
  SkMatrix ctm = SkMatrix::I();
  SkPath path;
  path.addRect(100, 100, 100 + width, 100 + height);
  MockLayer layer = MockLayer(path);
  layer.Preroll(&preroll_context_, ctm);
  Prepare(&preroll_context_, &layer, ctm);
}

void MockRasterCache::AddMockPicture(int width, int height) {
  FML_DCHECK(access_threshold() > 0);
  SkMatrix ctm = SkMatrix::I();
  DisplayListCanvasRecorder recorder(
      SkRect::MakeLTRB(0, 0, 200 + width, 200 + height));
  SkPath path;
  path.addRect(100, 100, 100 + width, 100 + height);
  recorder.drawPath(path, SkPaint());
  sk_sp<DisplayList> display_list = recorder.Build();
  PrerollContextHolder holder = GetSamplePrerollContextHolder();
  holder.preroll_context.dst_color_space = color_space_;
  for (int i = 0; i < access_threshold(); i++) {
    Prepare(&holder.preroll_context, display_list.get(), true, false, ctm);
    Draw(*display_list, mock_canvas_);
  }
  Prepare(&holder.preroll_context, display_list.get(), true, false, ctm);
}

PrerollContextHolder GetSamplePrerollContextHolder() {
  FixedRefreshRateStopwatch raster_time;
  FixedRefreshRateStopwatch ui_time;
  MutatorsStack mutators_stack;
  TextureRegistry texture_registry;
  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  PrerollContextHolder holder = {
      {
          nullptr,                    /* raster_cache */
          nullptr,                    /* gr_context */
          nullptr,                    /* external_view_embedder */
          mutators_stack, srgb.get(), /* color_space */
          kGiantRect,                 /* cull_rect */
          false,                      /* layer reads from surface */
          raster_time, ui_time, texture_registry,
          false, /* checkerboard_offscreen_layers */
          1.0f,  /* frame_device_pixel_ratio */
          false, /* has_platform_view */
      },
      srgb};

  return holder;
}

}  // namespace testing
}  // namespace flutter

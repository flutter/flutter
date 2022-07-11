// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_raster_cache.h"

#include "flutter/flow/layers/display_list_raster_cache_item.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/raster_cache_item.h"
#include "include/core/SkCanvas.h"
#include "include/core/SkMatrix.h"
#include "include/core/SkPoint.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flutter {
namespace testing {

MockRasterCacheResult::MockRasterCacheResult(SkRect device_rect)
    : RasterCacheResult(nullptr, SkRect::MakeEmpty(), "RasterCacheFlow::test"),
      device_rect_(device_rect) {}

void MockRasterCache::AddMockLayer(int width, int height) {
  SkMatrix ctm = SkMatrix::I();
  SkPath path;
  path.addRect(100, 100, 100 + width, 100 + height);
  MockCacheableLayer layer = MockCacheableLayer(path);
  layer.Preroll(&preroll_context_, ctm);
  layer.raster_cache_item()->TryToPrepareRasterCache(paint_context_);
  RasterCache::Context r_context = {
      // clang-format off
      .gr_context         = preroll_context_.gr_context,
      .dst_color_space    = preroll_context_.dst_color_space,
      .matrix             = ctm,
      .logical_rect       = layer.paint_bounds(),
      .checkerboard       = preroll_context_.checkerboard_offscreen_layers,
      // clang-format on
  };
  UpdateCacheEntry(
      RasterCacheKeyID(layer.unique_id(), RasterCacheKeyType::kLayer),
      r_context, [&](SkCanvas* canvas) {
        SkRect cache_rect = RasterCacheUtil::GetDeviceBounds(
            r_context.logical_rect, r_context.matrix);
        return std::make_unique<MockRasterCacheResult>(cache_rect);
      });
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

  PaintContextHolder holder = GetSamplePaintContextHolder(this);
  holder.paint_context.dst_color_space = color_space_;

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);
  for (int i = 0; i < access_threshold(); i++) {
    MarkSeen(display_list_item.GetId().value(), ctm, true);
    Draw(display_list_item.GetId().value(), mock_canvas_, nullptr);
  }
  MarkSeen(display_list_item.GetId().value(), ctm, true);
  RasterCache::Context r_context = {
      // clang-format off
      .gr_context         = preroll_context_.gr_context,
      .dst_color_space    = preroll_context_.dst_color_space,
      .matrix             = ctm,
      .logical_rect       = display_list->bounds(),
      .checkerboard       = preroll_context_.checkerboard_offscreen_layers,
      // clang-format on
  };
  UpdateCacheEntry(RasterCacheKeyID(display_list->unique_id(),
                                    RasterCacheKeyType::kDisplayList),
                   r_context, [&](SkCanvas* canvas) {
                     SkRect cache_rect = RasterCacheUtil::GetDeviceBounds(
                         r_context.logical_rect, r_context.matrix);
                     return std::make_unique<MockRasterCacheResult>(cache_rect);
                   });
}

static std::vector<RasterCacheItem*> raster_cache_items_;
PrerollContextHolder GetSamplePrerollContextHolder(RasterCache* raster_cache) {
  FixedRefreshRateStopwatch raster_time;
  FixedRefreshRateStopwatch ui_time;
  MutatorsStack mutators_stack;
  TextureRegistry texture_registry;
  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();

  PrerollContextHolder holder = {
      {
          // clang-format off
          .raster_cache                  = raster_cache,
          .gr_context                    =  nullptr,
          .view_embedder                 =  nullptr,
          .mutators_stack                = mutators_stack,
          .dst_color_space               =  srgb.get(),
          .cull_rect                     =  kGiantRect,
          .surface_needs_readback        = false,
          .raster_time                   = raster_time,
          .ui_time                       = ui_time,
          .texture_registry              = texture_registry,
          .checkerboard_offscreen_layers =  false,
          .frame_device_pixel_ratio      =  1.0f,
          .has_platform_view             =  false,
          .has_texture_layer             = false,
          .raster_cached_entries         =  &raster_cache_items_,
          // clang-format on
      },
      srgb};

  return holder;
}

PaintContextHolder GetSamplePaintContextHolder(RasterCache* raster_cache) {
  FixedRefreshRateStopwatch raster_time;
  FixedRefreshRateStopwatch ui_time;
  MutatorsStack mutators_stack;
  TextureRegistry texture_registry;
  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  PaintContextHolder holder = {// clang-format off
    {
          .internal_nodes_canvas         = nullptr,
          .leaf_nodes_canvas             = nullptr,
          .gr_context                    = nullptr,
          .dst_color_space               = srgb.get(),
          .view_embedder                 = nullptr,
          .raster_time                   = raster_time,
          .ui_time                       = ui_time,
          .texture_registry              = texture_registry,
          .raster_cache                  = raster_cache,
          .checkerboard_offscreen_layers = false,
          .frame_device_pixel_ratio      = 1.0f,
          .inherited_opacity             = SK_Scalar1,
    },
                               // clang-format on
                               srgb};

  return holder;
}

bool DisplayListRasterCacheItemTryToRasterCache(
    DisplayListRasterCacheItem& display_list_item,
    PrerollContext& context,
    PaintContext& paint_context,
    const SkMatrix& matrix) {
  display_list_item.PrerollSetup(&context, matrix);
  display_list_item.PrerollFinalize(&context, matrix);
  if (display_list_item.cache_state() ==
      RasterCacheItem::CacheState::kCurrent) {
    return display_list_item.TryToPrepareRasterCache(paint_context);
  }
  return false;
}

}  // namespace testing
}  // namespace flutter

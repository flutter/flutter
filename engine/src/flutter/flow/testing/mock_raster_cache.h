// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_MOCK_RASTER_CACHE_H_
#define FLOW_TESTING_MOCK_RASTER_CACHE_H_

#include <vector>
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/raster_cache_item.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/testing/mock_canvas.h"
#include "include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace flutter {
namespace testing {

/**
 * @brief A RasterCacheResult implementation that represents a cached Layer or
 * SkPicture without the overhead of storage.
 *
 * This implementation is used by MockRasterCache only for testing proper usage
 * of the RasterCache in layer unit tests.
 */
class MockRasterCacheResult : public RasterCacheResult {
 public:
  explicit MockRasterCacheResult(SkRect device_rect);

  void draw(SkCanvas& canvas, const SkPaint* paint = nullptr) const override{};

  SkISize image_dimensions() const override {
    return SkSize::Make(device_rect_.width(), device_rect_.height()).toCeil();
  };

  int64_t image_bytes() const override {
    return image_dimensions().area() *
           SkColorTypeBytesPerPixel(kBGRA_8888_SkColorType);
  }

 private:
  SkRect device_rect_;
};

/**
 * @brief A RasterCache implementation that simulates the act of rendering a
 * Layer or SkPicture without the overhead of rasterization or pixel storage.
 * This implementation is used only for testing proper usage of the RasterCache
 * in layer unit tests.
 */
class MockRasterCache : public RasterCache {
 public:
  explicit MockRasterCache(
      size_t access_threshold = 3,
      size_t picture_and_display_list_cache_limit_per_frame =
          RasterCacheUtil::kDefaultPictureAndDispLayListCacheLimitPerFrame)
      : RasterCache(access_threshold,
                    picture_and_display_list_cache_limit_per_frame) {}

  void AddMockLayer(int width, int height);
  void AddMockPicture(int width, int height);

 private:
  MockCanvas mock_canvas_;
  SkColorSpace* color_space_ = mock_canvas_.imageInfo().colorSpace();
  MutatorsStack mutators_stack_;
  FixedRefreshRateStopwatch raster_time_;
  FixedRefreshRateStopwatch ui_time_;
  TextureRegistry texture_registry_;
  PrerollContext preroll_context_ = {
      // clang-format off
      .raster_cache                  = nullptr,
      .gr_context                    = nullptr,
      .view_embedder                 = nullptr,
      .mutators_stack                = mutators_stack_,
      .dst_color_space               = color_space_,
      .cull_rect                     = kGiantRect,
      .surface_needs_readback        = false,
      .raster_time                   = raster_time_,
      .ui_time                       = ui_time_,
      .texture_registry              = texture_registry_,
      .checkerboard_offscreen_layers = false,
      .frame_device_pixel_ratio      = 1.0f,
      .has_platform_view             = false,
      .has_texture_layer             = false,
      // clang-format on
  };

  PaintContext paint_context_ = {
      // clang-format off
          .internal_nodes_canvas         = nullptr,
          .leaf_nodes_canvas             = nullptr,
          .gr_context                    = nullptr,
          .dst_color_space               = color_space_,
          .view_embedder                 = nullptr,
          .raster_time                   = raster_time_,
          .ui_time                       = ui_time_,
          .texture_registry              = texture_registry_,
          .raster_cache                  = nullptr,
          .checkerboard_offscreen_layers = false,
          .frame_device_pixel_ratio      = 1.0f,
          .inherited_opacity             = SK_Scalar1,
      // clang-format on
  };
};

struct PrerollContextHolder {
  PrerollContext preroll_context;
  sk_sp<SkColorSpace> srgb;
};

struct PaintContextHolder {
  PaintContext paint_context;
  sk_sp<SkColorSpace> srgb;
};

PrerollContextHolder GetSamplePrerollContextHolder(
    RasterCache* raster_cache = nullptr);

PaintContextHolder GetSamplePaintContextHolder(
    RasterCache* raster_cache = nullptr);

bool DisplayListRasterCacheItemTryToRasterCache(
    DisplayListRasterCacheItem& display_list_item,
    PrerollContext& context,
    PaintContext& paint_context,
    const SkMatrix& matrix);

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_MOCK_RASTER_CACHE_H_

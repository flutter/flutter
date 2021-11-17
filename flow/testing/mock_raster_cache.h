// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_MOCK_RASTER_CACHE_H_
#define FLOW_TESTING_MOCK_RASTER_CACHE_H_

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/testing/mock_canvas.h"
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
  explicit MockRasterCacheResult(SkIRect device_rect);

  void draw(SkCanvas& canvas, const SkPaint* paint = nullptr) const override{};

  SkISize image_dimensions() const override { return device_rect_.size(); };

  int64_t image_bytes() const override {
    return image_dimensions().area() *
           SkColorTypeBytesPerPixel(kBGRA_8888_SkColorType);
  }

 private:
  SkIRect device_rect_;
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
          kDefaultPictureAndDispLayListCacheLimitPerFrame)
      : RasterCache(access_threshold,
                    picture_and_display_list_cache_limit_per_frame) {}

  std::unique_ptr<RasterCacheResult> RasterizePicture(
      SkPicture* picture,
      GrDirectContext* context,
      const SkMatrix& ctm,
      SkColorSpace* dst_color_space,
      bool checkerboard) const override;

  std::unique_ptr<RasterCacheResult> RasterizeLayer(
      PrerollContext* context,
      Layer* layer,
      const SkMatrix& ctm,
      bool checkerboard) const override;

  void AddMockLayer(int width, int height);
  void AddMockPicture(int width, int height);

 private:
  MockCanvas mock_canvas_;
  SkColorSpace* color_space_ = mock_canvas_.imageInfo().colorSpace();
  MutatorsStack mutators_stack_;
  Stopwatch raster_time_;
  Stopwatch ui_time_;
  TextureRegistry texture_registry_;
  PrerollContext preroll_context_ = {
      nullptr,           /* raster_cache */
      nullptr,           /* gr_context */
      nullptr,           /* external_view_embedder */
      mutators_stack_,   /* mutators_stack */
      color_space_,      /* color_space */
      kGiantRect,        /* cull_rect */
      false,             /* layer reads from surface */
      raster_time_,      /* raster stopwatch */
      ui_time_,          /* frame build stopwatch */
      texture_registry_, /* texture_registry */
      false,             /* checkerboard_offscreen_layers */
      1.0f,              /* frame_device_pixel_ratio */
      false,             /* has_platform_view */
      false,             /* has_texture_layer */
  };
};

struct PrerollContextHolder {
  PrerollContext preroll_context;
  sk_sp<SkColorSpace> srgb;
};

PrerollContextHolder GetSamplePrerollContextHolder();

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_MOCK_RASTER_CACHE_H_

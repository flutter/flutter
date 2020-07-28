// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLOW_TESTING_MOCK_RASTER_CACHE_H_
#define FLOW_TESTING_MOCK_RASTER_CACHE_H_

#include "flutter/flow/raster_cache.h"
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
  MockRasterCacheResult(SkIRect device_rect);

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
};

}  // namespace testing
}  // namespace flutter

#endif  // FLOW_TESTING_MOCK_RASTER_CACHE_H_

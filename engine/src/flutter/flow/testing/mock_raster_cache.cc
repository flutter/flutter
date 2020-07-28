// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_raster_cache.h"

#include "flutter/flow/layers/layer.h"

namespace flutter {
namespace testing {

MockRasterCacheResult::MockRasterCacheResult(SkIRect device_rect)
    : RasterCacheResult(nullptr, SkRect::MakeEmpty()),
      device_rect_(device_rect) {}

std::unique_ptr<RasterCacheResult> MockRasterCache::RasterizePicture(
    SkPicture* picture,
    GrDirectContext* context,
    const SkMatrix& ctm,
    SkColorSpace* dst_color_space,
    bool checkerboard) const {
  SkRect logical_rect = picture->cullRect();
  SkIRect cache_rect = RasterCache::GetDeviceBounds(logical_rect, ctm);

  return std::make_unique<MockRasterCacheResult>(cache_rect);
}

std::unique_ptr<RasterCacheResult> MockRasterCache::RasterizeLayer(
    PrerollContext* context,
    Layer* layer,
    const SkMatrix& ctm,
    bool checkerboard) const {
  SkRect logical_rect = layer->paint_bounds();
  SkIRect cache_rect = RasterCache::GetDeviceBounds(logical_rect, ctm);

  return std::make_unique<MockRasterCacheResult>(cache_rect);
}

}  // namespace testing
}  // namespace flutter

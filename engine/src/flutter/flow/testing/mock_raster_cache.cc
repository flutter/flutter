// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_raster_cache.h"

#include "flutter/flow/layers/layer.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

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
  SkPictureRecorder skp_recorder;
  SkRTreeFactory rtree_factory;
  SkPath path;
  path.addRect(100, 100, 100 + width, 100 + height);
  SkCanvas* recorder_canvas = skp_recorder.beginRecording(
      SkRect::MakeLTRB(0, 0, 200 + width, 200 + height), &rtree_factory);
  recorder_canvas->drawPath(path, SkPaint());
  sk_sp<SkPicture> picture = skp_recorder.finishRecordingAsPicture();
  for (int i = 0; i < access_threshold(); i++) {
    Prepare(nullptr, picture.get(), ctm, color_space_, true, false);
    Draw(*picture, mock_canvas_);
  }
  Prepare(nullptr, picture.get(), ctm, color_space_, true, false);
}

}  // namespace testing
}  // namespace flutter

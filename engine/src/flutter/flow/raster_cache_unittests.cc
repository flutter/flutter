// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache.h"

#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flutter {
namespace testing {
namespace {

sk_sp<SkPicture> GetSamplePicture() {
  SkPictureRecorder recorder;
  recorder.beginRecording(SkRect::MakeWH(150, 100));
  SkPaint paint;
  paint.setColor(SK_ColorRED);
  recorder.getRecordingCanvas()->drawRect(SkRect::MakeXYWH(10, 10, 80, 80),
                                          paint);
  return recorder.finishRecordingAsPicture();
}

}  // namespace

TEST(RasterCache, SimpleInitialization) {
  flutter::RasterCache cache;
  ASSERT_TRUE(true);
}

TEST(RasterCache, ThresholdIsRespected) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  SkCanvas dummy_canvas;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));
  // 1st access.
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.SweepAfterFrame();

  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));

  // 2nd access.
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.SweepAfterFrame();

  // Now Prepare should cache it.
  ASSERT_TRUE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));
  ASSERT_TRUE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, AccessThresholdOfZeroDisablesCaching) {
  size_t threshold = 0;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  SkCanvas dummy_canvas;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));

  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, PictureCacheLimitPerFrameIsRespectedWhenZero) {
  size_t picture_cache_limit_per_frame = 0;
  flutter::RasterCache cache(3, picture_cache_limit_per_frame);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  SkCanvas dummy_canvas;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));

  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, SweepsRemoveUnusedFrames) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  SkCanvas dummy_canvas;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true,
                             false));  // 1
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.SweepAfterFrame();

  ASSERT_TRUE(cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true,
                            false));  // 2
  ASSERT_TRUE(cache.Draw(*picture, dummy_canvas));

  cache.SweepAfterFrame();
  cache.SweepAfterFrame();  // Extra frame without a Get image access.

  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));
}

// Construct a cache result whose device target rectangle rounds out to be one
// pixel wider than the cached image.  Verify that it can be drawn without
// triggering any assertions.
TEST(RasterCache, DeviceRectRoundOut) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkPictureRecorder recorder;
  SkRect logical_rect = SkRect::MakeLTRB(28, 0, 354.56731, 310.288);
  recorder.beginRecording(logical_rect);
  SkPaint paint;
  paint.setColor(SK_ColorRED);
  recorder.getRecordingCanvas()->drawRect(logical_rect, paint);
  sk_sp<SkPicture> picture = recorder.finishRecordingAsPicture();

  SkMatrix ctm = SkMatrix::MakeAll(1.3312, 0, 233, 0, 1.3312, 206, 0, 0, 1);

  SkCanvas canvas(100, 100, nullptr);
  canvas.setMatrix(ctm);

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), ctm, srgb.get(), true, false));
  ASSERT_FALSE(cache.Draw(*picture, canvas));
  cache.SweepAfterFrame();
  ASSERT_TRUE(cache.Prepare(NULL, picture.get(), ctm, srgb.get(), true, false));
  ASSERT_TRUE(cache.Draw(*picture, canvas));

  canvas.translate(248, 0);
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
  canvas.setMatrix(RasterCache::GetIntegralTransCTM(canvas.getTotalMatrix()));
#endif
  ASSERT_TRUE(cache.Draw(*picture, canvas));
}

}  // namespace testing
}  // namespace flutter

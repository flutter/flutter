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

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));
  // 1st access.
  ASSERT_FALSE(cache.Get(*picture, matrix).is_valid());

  cache.SweepAfterFrame();

  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));

  // 2st access.
  ASSERT_FALSE(cache.Get(*picture, matrix).is_valid());

  cache.SweepAfterFrame();

  // Now Prepare should cache it.
  ASSERT_TRUE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));
  ASSERT_TRUE(cache.Get(*picture, matrix).is_valid());
}

TEST(RasterCache, AccessThresholdOfZeroDisablesCaching) {
  size_t threshold = 0;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));

  ASSERT_FALSE(cache.Get(*picture, matrix).is_valid());
}

TEST(RasterCache, PictureCacheLimitPerFrameIsRespectedWhenZero) {
  size_t picture_cache_limit_per_frame = 0;
  flutter::RasterCache cache(3, picture_cache_limit_per_frame);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(
      cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true, false));

  ASSERT_FALSE(cache.Get(*picture, matrix).is_valid());
}

TEST(RasterCache, SweepsRemoveUnusedFrames) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true,
                             false));  // 1
  ASSERT_FALSE(cache.Get(*picture, matrix).is_valid());

  cache.SweepAfterFrame();

  ASSERT_TRUE(cache.Prepare(NULL, picture.get(), matrix, srgb.get(), true,
                            false));  // 2
  ASSERT_TRUE(cache.Get(*picture, matrix).is_valid());

  cache.SweepAfterFrame();
  cache.SweepAfterFrame();  // Extra frame without a Get image access.

  ASSERT_FALSE(cache.Get(*picture, matrix).is_valid());
}

}  // namespace testing
}  // namespace flutter

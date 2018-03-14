// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

sk_sp<SkPicture> GetSamplePicture() {
  SkPictureRecorder recorder;
  recorder.beginRecording(SkRect::MakeWH(150, 100));
  SkPaint paint;
  paint.setColor(SK_ColorRED);
  recorder.getRecordingCanvas()->drawRect(SkRect::MakeXYWH(10, 10, 80, 80),
                                          paint);
  return recorder.finishRecordingAsPicture();
}

TEST(RasterCache, SimpleInitialization) {
  flow::RasterCache cache;
  ASSERT_TRUE(true);
}

TEST(RasterCache, ThresholdIsRespected) {
  size_t threshold = 3;
  flow::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 1
  cache.SweepAfterFrame();
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 2
  cache.SweepAfterFrame();
  ASSERT_TRUE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                      true, false));  // 3
  cache.SweepAfterFrame();
}

TEST(RasterCache, ThresholdIsRespectedWhenZero) {
  size_t threshold = 0;
  flow::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 1
  cache.SweepAfterFrame();
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 2
  cache.SweepAfterFrame();
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 3
  cache.SweepAfterFrame();
}

TEST(RasterCache, SweepsRemoveUnusedFrames) {
  size_t threshold = 3;
  flow::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  sk_sp<SkImage> image;

  sk_sp<SkColorSpace> srgb = SkColorSpace::MakeSRGB();
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 1
  cache.SweepAfterFrame();
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 2
  cache.SweepAfterFrame();
  ASSERT_TRUE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                      true, false));  // 3
  cache.SweepAfterFrame();
  ASSERT_TRUE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                      true, false));  // 4
  cache.SweepAfterFrame();
  cache.SweepAfterFrame();  // Extra frame without a preroll image access.
  ASSERT_FALSE(cache.GetPrerolledImage(NULL, picture.get(), matrix, srgb.get(),
                                       true, false));  // 5
}

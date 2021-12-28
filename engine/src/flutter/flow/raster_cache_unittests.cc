// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/testing/mock_raster_cache.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPaint.h"
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

sk_sp<DisplayList> GetSampleDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  builder.setColor(SK_ColorRED);
  builder.drawRect(SkRect::MakeXYWH(10, 10, 80, 80));
  return builder.Build();
}

sk_sp<SkPicture> GetSampleNestedPicture() {
  SkPictureRecorder recorder;
  recorder.beginRecording(SkRect::MakeWH(150, 100));
  SkCanvas* canvas = recorder.getRecordingCanvas();
  SkPaint paint;
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      paint.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      canvas->drawRect(SkRect::MakeXYWH(x, y, 80, 80), paint);
    }
  }
  SkPictureRecorder outer_recorder;
  outer_recorder.beginRecording(SkRect::MakeWH(150, 100));
  canvas = outer_recorder.getRecordingCanvas();
  canvas->drawPicture(recorder.finishRecordingAsPicture());
  return outer_recorder.finishRecordingAsPicture();
}

sk_sp<DisplayList> GetSampleNestedDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      builder.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      builder.drawRect(SkRect::MakeXYWH(x, y, 80, 80));
    }
  }
  DisplayListBuilder outer_builder(SkRect::MakeWH(150, 100));
  outer_builder.drawDisplayList(builder.Build());
  return outer_builder.Build();
}

}  // namespace

TEST(RasterCache, SimpleInitialization) {
  flutter::RasterCache cache;
  ASSERT_TRUE(true);
}

TEST(RasterCache, ThresholdIsRespectedForSkPicture) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, matrix));
  // 1st access.
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, matrix));

  // 2nd access.
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  // Now Prepare should cache it.
  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            picture.get(), true, false, matrix));
  ASSERT_TRUE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, MetricsOmitUnpopulatedEntries) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, matrix));
  // 1st access.
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();
  ASSERT_EQ(cache.picture_metrics().total_count(), 0u);
  ASSERT_EQ(cache.picture_metrics().total_bytes(), 0u);
  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, matrix));

  // 2nd access.
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();
  ASSERT_EQ(cache.picture_metrics().total_count(), 0u);
  ASSERT_EQ(cache.picture_metrics().total_bytes(), 0u);
  cache.PrepareNewFrame();

  // Now Prepare should cache it.
  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            picture.get(), true, false, matrix));
  ASSERT_TRUE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();
  ASSERT_EQ(cache.picture_metrics().total_count(), 1u);
  // 150w * 100h * 4bpp
  ASSERT_EQ(cache.picture_metrics().total_bytes(), 60000u);
}

TEST(RasterCache, ThresholdIsRespectedForDisplayList) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             display_list.get(), true, false, matrix));
  // 1st access.
  ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             display_list.get(), true, false, matrix));

  // 2nd access.
  ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  // Now Prepare should cache it.
  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            display_list.get(), true, false, matrix));
  ASSERT_TRUE(cache.Draw(*display_list, dummy_canvas));
}

TEST(RasterCache, AccessThresholdOfZeroDisablesCachingForSkPicture) {
  size_t threshold = 0;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, matrix));

  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, AccessThresholdOfZeroDisablesCachingForDisplayList) {
  size_t threshold = 0;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             display_list.get(), true, false, matrix));

  ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));
}

TEST(RasterCache, PictureCacheLimitPerFrameIsRespectedWhenZeroForSkPicture) {
  size_t picture_cache_limit_per_frame = 0;
  flutter::RasterCache cache(3, picture_cache_limit_per_frame);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, matrix));

  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, PictureCacheLimitPerFrameIsRespectedWhenZeroForDisplayList) {
  size_t picture_cache_limit_per_frame = 0;
  flutter::RasterCache cache(3, picture_cache_limit_per_frame);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             display_list.get(), true, false, matrix));

  ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));
}

TEST(RasterCache, SweepsRemoveUnusedSkPictures) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSamplePicture();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, matrix));  // 1
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            picture.get(), true, false, matrix));  // 2
  ASSERT_TRUE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();

  cache.PrepareNewFrame();
  cache.CleanupAfterFrame();  // Extra frame without a Get image access.

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, SweepsRemoveUnusedDisplayLists) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             display_list.get(), true, false, matrix));  // 1
  ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            display_list.get(), true, false, matrix));  // 2
  ASSERT_TRUE(cache.Draw(*display_list, dummy_canvas));

  cache.CleanupAfterFrame();

  cache.PrepareNewFrame();
  cache.CleanupAfterFrame();  // Extra frame without a Get image access.

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));
}

// Construct a cache result whose device target rectangle rounds out to be one
// pixel wider than the cached image.  Verify that it can be drawn without
// triggering any assertions.
TEST(RasterCache, DeviceRectRoundOutForSkPicture) {
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

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), true, false, ctm));
  ASSERT_FALSE(cache.Draw(*picture, canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            picture.get(), true, false, ctm));
  ASSERT_TRUE(cache.Draw(*picture, canvas));

  canvas.translate(248, 0);
  ASSERT_TRUE(cache.Draw(*picture, canvas));
}

// Construct a cache result whose device target rectangle rounds out to be one
// pixel wider than the cached image.  Verify that it can be drawn without
// triggering any assertions.
TEST(RasterCache, DeviceRectRoundOutForDisplayList) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkRect logical_rect = SkRect::MakeLTRB(28, 0, 354.56731, 310.288);
  DisplayListBuilder builder(logical_rect);
  builder.setColor(SK_ColorRED);
  builder.drawRect(logical_rect);
  sk_sp<DisplayList> display_list = builder.Build();

  SkMatrix ctm = SkMatrix::MakeAll(1.3312, 0, 233, 0, 1.3312, 206, 0, 0, 1);

  SkCanvas canvas(100, 100, nullptr);
  canvas.setMatrix(ctm);

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             display_list.get(), true, false, ctm));
  ASSERT_FALSE(cache.Draw(*display_list, canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            display_list.get(), true, false, ctm));
  ASSERT_TRUE(cache.Draw(*display_list, canvas));

  canvas.translate(248, 0);
  ASSERT_TRUE(cache.Draw(*display_list, canvas));
}

TEST(RasterCache, NestedOpCountMetricUsedForSkPicture) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto picture = GetSampleNestedPicture();
  ASSERT_EQ(picture->approximateOpCount(), 1);
  ASSERT_EQ(picture->approximateOpCount(true), 36);

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             picture.get(), false, false, matrix));
  ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            picture.get(), false, false, matrix));
  ASSERT_TRUE(cache.Draw(*picture, dummy_canvas));
}

TEST(RasterCache, NestedOpCountMetricUsedForDisplayList) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleNestedDisplayList();
  ASSERT_EQ(display_list->op_count(), 1);
  ASSERT_EQ(display_list->op_count(true), 36);

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                             display_list.get(), false, false, matrix));
  ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(cache.Prepare(&preroll_context_holder.preroll_context,
                            display_list.get(), false, false, matrix));
  ASSERT_TRUE(cache.Draw(*display_list, dummy_canvas));
}

TEST(RasterCache, SkPictureWithSingularMatrixIsNotCached) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrices[] = {
      SkMatrix::Scale(0, 1),
      SkMatrix::Scale(1, 0),
      SkMatrix::Skew(1, 1),
  };
  int matrixCount = sizeof(matrices) / sizeof(matrices[0]);

  auto picture = GetSamplePicture();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  for (int i = 0; i < 10; i++) {
    cache.PrepareNewFrame();

    for (int j = 0; j < matrixCount; j++) {
      ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                                 picture.get(), true, false, matrices[j]));
    }

    for (int j = 0; j < matrixCount; j++) {
      dummy_canvas.setMatrix(matrices[j]);
      ASSERT_FALSE(cache.Draw(*picture, dummy_canvas));
    }

    cache.CleanupAfterFrame();
  }
}

TEST(RasterCache, DisplayListWithSingularMatrixIsNotCached) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrices[] = {
      SkMatrix::Scale(0, 1),
      SkMatrix::Scale(1, 0),
      SkMatrix::Skew(1, 1),
  };
  int matrixCount = sizeof(matrices) / sizeof(matrices[0]);

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;

  PrerollContextHolder preroll_context_holder = GetSamplePrerollContextHolder();

  for (int i = 0; i < 10; i++) {
    cache.PrepareNewFrame();

    for (int j = 0; j < matrixCount; j++) {
      ASSERT_FALSE(cache.Prepare(&preroll_context_holder.preroll_context,
                                 display_list.get(), true, false, matrices[j]));
    }

    for (int j = 0; j < matrixCount; j++) {
      dummy_canvas.setMatrix(matrices[j]);
      ASSERT_FALSE(cache.Draw(*display_list, dummy_canvas));
    }

    cache.CleanupAfterFrame();
  }
}

}  // namespace testing

}  // namespace flutter

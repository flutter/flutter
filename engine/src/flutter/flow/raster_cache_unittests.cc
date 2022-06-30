// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_test_utils.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/raster_cache_item.h"
#include "flutter/flow/testing/mock_raster_cache.h"
#include "gtest/gtest.h"
#include "include/core/SkMatrix.h"
#include "include/core/SkPoint.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flutter {
namespace testing {

TEST(RasterCache, SimpleInitialization) {
  flutter::RasterCache cache;
  ASSERT_TRUE(true);
}

TEST(RasterCache, MetricsOmitUnpopulatedEntries) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();
  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);

  // 1st access.
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  ASSERT_EQ(cache.picture_metrics().total_count(), 0u);
  ASSERT_EQ(cache.picture_metrics().total_bytes(), 0u);
  cache.PrepareNewFrame();

  // 2nd access.
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  ASSERT_EQ(cache.picture_metrics().total_count(), 0u);
  ASSERT_EQ(cache.picture_metrics().total_bytes(), 0u);
  cache.PrepareNewFrame();

  // Now Prepare should cache it.
  ASSERT_TRUE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_TRUE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  ASSERT_EQ(cache.picture_metrics().total_count(), 1u);
  // 150w * 100h * 4bpp
  ASSERT_EQ(cache.picture_metrics().total_bytes(), 25600u);
}

TEST(RasterCache, ThresholdIsRespectedForDisplayList) {
  size_t threshold = 2;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);

  // 1st access.
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  // 2nd access.
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  // Now Prepare should cache it.
  ASSERT_TRUE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_TRUE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, AccessThresholdOfZeroDisablesCachingForSkPicture) {
  size_t threshold = 0;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();
  ;

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();
  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, AccessThresholdOfZeroDisablesCachingForDisplayList) {
  size_t threshold = 0;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, PictureCacheLimitPerFrameIsRespectedWhenZeroForSkPicture) {
  size_t picture_cache_limit_per_frame = 0;
  flutter::RasterCache cache(3, picture_cache_limit_per_frame);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();
  ;

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, PictureCacheLimitPerFrameIsRespectedWhenZeroForDisplayList) {
  size_t picture_cache_limit_per_frame = 0;
  flutter::RasterCache cache(3, picture_cache_limit_per_frame);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);
  // 1st access.
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
  // 2nd access.
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
  // the picture_cache_limit_per_frame = 0, so don't cache it
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, SweepsRemoveUnusedSkPictures) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();
  ;

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  DisplayListRasterCacheItem display_item(display_list.get(), SkPoint(), true,
                                          false);
  // 1.
  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();
  // 2.
  ASSERT_TRUE(DisplayListRasterCacheItemTryToRasterCache(
      display_item, preroll_context, paint_context, matrix));
  ASSERT_TRUE(display_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();

  cache.PrepareNewFrame();
  cache.CleanupAfterFrame();  // Extra frame without a Get image access.

  cache.PrepareNewFrame();

  ASSERT_FALSE(cache.Draw(display_item.GetId().value(), dummy_canvas, &paint));
  ASSERT_FALSE(display_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, SweepsRemoveUnusedDisplayLists) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleDisplayList();

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);

  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_TRUE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();

  cache.PrepareNewFrame();
  cache.CleanupAfterFrame();  // Extra frame without a Get image access.

  cache.PrepareNewFrame();
  ASSERT_FALSE(
      cache.Draw(display_list_item.GetId().value(), dummy_canvas, &paint));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, ComputeDeviceRectBasedOnFractionalTranslation) {
  SkRect logical_rect = SkRect::MakeLTRB(0, 0, 300.2, 300.3);
  SkMatrix ctm = SkMatrix::MakeAll(2.0, 0, 0, 0, 2.0, 0, 0, 0, 1);
  auto result = RasterCacheUtil::GetDeviceBounds(logical_rect, ctm);
  ASSERT_EQ(result, SkRect::MakeLTRB(0.0, 0.0, 600.4, 600.6));
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
  SkPaint paint;

  SkCanvas canvas(100, 100, nullptr);
  canvas.setMatrix(ctm);

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();
  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);

  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, ctm));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, ctm));
  ASSERT_TRUE(display_list_item.Draw(paint_context, &canvas, &paint));

  canvas.translate(248, 0);
  ASSERT_TRUE(cache.Draw(display_list_item.GetId().value(), canvas, &paint));
  ASSERT_TRUE(display_list_item.Draw(paint_context, &canvas, &paint));
}

TEST(RasterCache, NestedOpCountMetricUsedForDisplayList) {
  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  auto display_list = GetSampleNestedDisplayList();
  ASSERT_EQ(display_list->op_count(), 1u);
  ASSERT_EQ(display_list->op_count(true), 36u);

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               false, false);

  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_TRUE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));
}

TEST(RasterCache, NaiveComplexityScoringDisplayList) {
  DisplayListComplexityCalculator* calculator =
      DisplayListNaiveComplexityCalculator::GetInstance();

  size_t threshold = 1;
  flutter::RasterCache cache(threshold);

  SkMatrix matrix = SkMatrix::I();

  // Five raster ops will not be cached
  auto display_list = GetSampleDisplayList(5);
  unsigned int complexity_score = calculator->Compute(display_list.get());

  ASSERT_EQ(complexity_score, 5u);
  ASSERT_EQ(display_list->op_count(), 5u);
  ASSERT_FALSE(calculator->ShouldBeCached(complexity_score));

  SkCanvas dummy_canvas;
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  cache.PrepareNewFrame();

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               false, false);

  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item.Draw(paint_context, &dummy_canvas, &paint));

  // Six raster ops should be cached
  display_list = GetSampleDisplayList(6);
  complexity_score = calculator->Compute(display_list.get());

  ASSERT_EQ(complexity_score, 6u);
  ASSERT_EQ(display_list->op_count(), 6u);
  ASSERT_TRUE(calculator->ShouldBeCached(complexity_score));

  DisplayListRasterCacheItem display_list_item_2 =
      DisplayListRasterCacheItem(display_list.get(), SkPoint(), false, false);
  cache.PrepareNewFrame();

  ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item_2, preroll_context, paint_context, matrix));
  ASSERT_FALSE(display_list_item_2.Draw(paint_context, &dummy_canvas, &paint));

  cache.CleanupAfterFrame();
  cache.PrepareNewFrame();

  ASSERT_TRUE(DisplayListRasterCacheItemTryToRasterCache(
      display_list_item_2, preroll_context, paint_context, matrix));
  ASSERT_TRUE(display_list_item_2.Draw(paint_context, &dummy_canvas, &paint));
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
  SkPaint paint;

  PrerollContextHolder preroll_context_holder =
      GetSamplePrerollContextHolder(&cache);
  PaintContextHolder paint_context_holder = GetSamplePaintContextHolder(&cache);
  auto& preroll_context = preroll_context_holder.preroll_context;
  auto& paint_context = paint_context_holder.paint_context;

  DisplayListRasterCacheItem display_list_item(display_list.get(), SkPoint(),
                                               true, false);

  for (int i = 0; i < 10; i++) {
    cache.PrepareNewFrame();

    for (int j = 0; j < matrixCount; j++) {
      display_list_item.set_matrix(matrices[j]);
      ASSERT_FALSE(DisplayListRasterCacheItemTryToRasterCache(
          display_list_item, preroll_context, paint_context, matrices[j]));
    }

    for (int j = 0; j < matrixCount; j++) {
      dummy_canvas.setMatrix(matrices[j]);
      ASSERT_FALSE(
          display_list_item.Draw(paint_context, &dummy_canvas, &paint));
    }

    cache.CleanupAfterFrame();
  }
}

TEST(RasterCache, RasterCacheKeyHashFunction) {
  RasterCacheKey::Map<int> map;
  auto hash_function = map.hash_function();
  SkMatrix matrix = SkMatrix::I();
  uint64_t id = 5;
  RasterCacheKey layer_key(id, RasterCacheKeyType::kLayer, matrix);
  RasterCacheKey display_list_key(id, RasterCacheKeyType::kDisplayList, matrix);
  RasterCacheKey layer_children_key(id, RasterCacheKeyType::kLayerChildren,
                                    matrix);

  auto layer_cache_key_id = RasterCacheKeyID(id, RasterCacheKeyType::kLayer);
  auto layer_hash_code = hash_function(layer_key);
  ASSERT_EQ(layer_hash_code, layer_cache_key_id.GetHash());

  auto display_list_cache_key_id =
      RasterCacheKeyID(id, RasterCacheKeyType::kDisplayList);
  auto display_list_hash_code = hash_function(display_list_key);
  ASSERT_EQ(display_list_hash_code, display_list_cache_key_id.GetHash());

  auto layer_children_cache_key_id =
      RasterCacheKeyID(id, RasterCacheKeyType::kLayerChildren);
  auto layer_children_hash_code = hash_function(layer_children_key);
  ASSERT_EQ(layer_children_hash_code, layer_children_cache_key_id.GetHash());
}

TEST(RasterCache, RasterCacheKeySameID) {
  RasterCacheKey::Map<int> map;
  SkMatrix matrix = SkMatrix::I();
  uint64_t id = 5;
  RasterCacheKey layer_key(id, RasterCacheKeyType::kLayer, matrix);
  RasterCacheKey display_list_key(id, RasterCacheKeyType::kDisplayList, matrix);
  RasterCacheKey layer_children_key(id, RasterCacheKeyType::kLayerChildren,
                                    matrix);
  map[layer_key] = 100;
  map[display_list_key] = 300;
  map[layer_children_key] = 400;

  ASSERT_EQ(map[layer_key], 100);
  ASSERT_EQ(map[display_list_key], 300);
  ASSERT_EQ(map[layer_children_key], 400);
}

TEST(RasterCache, RasterCacheKeySameType) {
  RasterCacheKey::Map<int> map;
  SkMatrix matrix = SkMatrix::I();

  RasterCacheKeyType type = RasterCacheKeyType::kLayer;
  RasterCacheKey layer_first_key(5, type, matrix);
  RasterCacheKey layer_second_key(10, type, matrix);
  RasterCacheKey layer_third_key(15, type, matrix);
  map[layer_first_key] = 50;
  map[layer_second_key] = 100;
  map[layer_third_key] = 150;
  ASSERT_EQ(map[layer_first_key], 50);
  ASSERT_EQ(map[layer_second_key], 100);
  ASSERT_EQ(map[layer_third_key], 150);

  type = RasterCacheKeyType::kDisplayList;
  RasterCacheKey picture_first_key(20, type, matrix);
  RasterCacheKey picture_second_key(25, type, matrix);
  RasterCacheKey picture_third_key(30, type, matrix);
  map[picture_first_key] = 200;
  map[picture_second_key] = 250;
  map[picture_third_key] = 300;
  ASSERT_EQ(map[picture_first_key], 200);
  ASSERT_EQ(map[picture_second_key], 250);
  ASSERT_EQ(map[picture_third_key], 300);

  type = RasterCacheKeyType::kDisplayList;
  RasterCacheKey display_list_first_key(35, type, matrix);
  RasterCacheKey display_list_second_key(40, type, matrix);
  RasterCacheKey display_list_third_key(45, type, matrix);
  map[display_list_first_key] = 350;
  map[display_list_second_key] = 400;
  map[display_list_third_key] = 450;
  ASSERT_EQ(map[display_list_first_key], 350);
  ASSERT_EQ(map[display_list_second_key], 400);
  ASSERT_EQ(map[display_list_third_key], 450);

  type = RasterCacheKeyType::kLayerChildren;
  RasterCacheKey layer_children_first_key(RasterCacheKeyID({1, 2, 3}, type),
                                          matrix);
  RasterCacheKey layer_children_second_key(RasterCacheKeyID({2, 3, 1}, type),
                                           matrix);
  RasterCacheKey layer_children_third_key(RasterCacheKeyID({3, 2, 1}, type),
                                          matrix);
  map[layer_children_first_key] = 100;
  map[layer_children_second_key] = 200;
  map[layer_children_third_key] = 300;
  ASSERT_EQ(map[layer_children_first_key], 100);
  ASSERT_EQ(map[layer_children_second_key], 200);
  ASSERT_EQ(map[layer_children_third_key], 300);
}

TEST(RasterCache, RasterCacheKeyID_Equal) {
  RasterCacheKeyID first = RasterCacheKeyID(1, RasterCacheKeyType::kLayer);
  RasterCacheKeyID second =
      RasterCacheKeyID(1, RasterCacheKeyType::kLayerChildren);
  RasterCacheKeyID third = RasterCacheKeyID(2, RasterCacheKeyType::kLayer);
  ASSERT_NE(first, second);
  ASSERT_NE(first, third);
  ASSERT_NE(second, third);

  RasterCacheKeyID fourth =
      RasterCacheKeyID({1, 2}, RasterCacheKeyType::kLayer);
  RasterCacheKeyID fifth =
      RasterCacheKeyID({1, 2}, RasterCacheKeyType::kLayerChildren);
  RasterCacheKeyID sixth =
      RasterCacheKeyID({2, 1}, RasterCacheKeyType::kLayerChildren);
  ASSERT_NE(fourth, fifth);
  ASSERT_NE(fifth, sixth);
}

size_t HashIds(std::vector<uint64_t> ids, RasterCacheKeyType type) {
  std::size_t seed = fml::HashCombine();
  for (auto id : ids) {
    fml::HashCombineSeed(seed, id);
  }
  return fml::HashCombine(seed, type);
}

TEST(RasterCache, RasterCacheKeyID_HashCode) {
  uint64_t foo = 1;
  uint64_t bar = 2;
  RasterCacheKeyID first = RasterCacheKeyID(foo, RasterCacheKeyType::kLayer);
  RasterCacheKeyID second =
      RasterCacheKeyID({foo, bar}, RasterCacheKeyType::kLayerChildren);
  RasterCacheKeyID third =
      RasterCacheKeyID({bar, foo}, RasterCacheKeyType::kLayerChildren);

  ASSERT_EQ(first.GetHash(), HashIds({foo}, RasterCacheKeyType::kLayer));
  ASSERT_EQ(second.GetHash(),
            HashIds({foo, bar}, RasterCacheKeyType::kLayerChildren));
  ASSERT_EQ(third.GetHash(),
            HashIds({bar, foo}, RasterCacheKeyType::kLayerChildren));
}

}  // namespace testing
}  // namespace flutter

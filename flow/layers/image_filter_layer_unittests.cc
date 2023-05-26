// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/flow/layers/image_filter_layer.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/flow/testing/diff_context_test.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "gtest/gtest.h"
#include "include/core/SkPath.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace flutter {
namespace testing {

using ImageFilterLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(ImageFilterLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<ImageFilterLayer>(nullptr);

  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ImageFilterLayerTest, PaintBeforePrerollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ImageFilterLayer>(nullptr);
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->child_paint_bounds(), kEmptyRect);
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(ImageFilterLayerTest, EmptyFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(nullptr);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ImageFilter)layer::Paint */ {
    expected_builder.Save();
    /* mock_layer1::Paint */ {
      expected_builder.DrawPath(child_path, child_paint);
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ImageFilterLayerTest, SimpleFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter);
  layer->Add(mock_layer);

  const SkRect child_rounded_bounds =
      SkRect::MakeLTRB(5.0f, 6.0f, 21.0f, 22.0f);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), child_rounded_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  DisplayListBuilder expected_builder;
  /* ImageFilterLayer::Paint() */ {
    DlPaint dl_paint;
    dl_paint.setImageFilter(dl_image_filter.get());
    expected_builder.SaveLayer(&child_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.DrawPath(child_path, DlPaint(DlColor::kYellow()));
      }
    }
  }
  expected_builder.Restore();
  auto expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(ImageFilterLayerTest, SimpleFilterWithOffset) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect initial_cull_rect = SkRect::MakeLTRB(0, 0, 100, 100);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  const SkPoint layer_offset = SkPoint::Make(5.5, 6.5);
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer =
      std::make_shared<ImageFilterLayer>(dl_image_filter, layer_offset);
  layer->Add(mock_layer);

  SkMatrix child_matrix = initial_transform;
  child_matrix.preTranslate(layer_offset.fX, layer_offset.fY);
  const SkRect child_rounded_bounds =
      SkRect::MakeLTRB(10.5f, 12.5f, 26.5f, 28.5f);

  preroll_context()->state_stack.set_preroll_delegate(initial_cull_rect,
                                                      initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), child_rounded_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), child_matrix);
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(),
            initial_cull_rect);

  DisplayListBuilder expected_builder;
  /* ImageFilterLayer::Paint() */ {
    expected_builder.Save();
    {
      expected_builder.Translate(layer_offset.fX, layer_offset.fY);
      DlPaint dl_paint;
      dl_paint.setImageFilter(dl_image_filter.get());
      expected_builder.SaveLayer(&child_bounds, &dl_paint);
      {
        /* MockLayer::Paint() */ {
          expected_builder.DrawPath(child_path, DlPaint(DlColor::kYellow()));
        }
      }
      expected_builder.Restore();
    }
    expected_builder.Restore();
  }
  auto expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(ImageFilterLayerTest, SimpleFilterBounds) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  const SkMatrix filter_transform = SkMatrix::Scale(2.0, 2.0);

  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      filter_transform, DlImageSampling::kMipmapLinear);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter);
  layer->Add(mock_layer);

  const SkRect filter_bounds = SkRect::MakeLTRB(10.0f, 12.0f, 42.0f, 44.0f);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), filter_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  DisplayListBuilder expected_builder;
  /* ImageFilterLayer::Paint() */ {
    DlPaint dl_paint;
    dl_paint.setImageFilter(dl_image_filter.get());
    expected_builder.SaveLayer(&child_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.DrawPath(child_path, DlPaint(DlColor::kYellow()));
      }
    }
  }
  expected_builder.Restore();
  auto expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(ImageFilterLayerTest, MultipleChildren) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const DlPaint child_paint1 = DlPaint(DlColor::kYellow());
  const DlPaint child_paint2 = DlPaint(DlColor::kCyan());
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  SkRect children_rounded_bounds = SkRect::Make(children_bounds.roundOut());

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), children_rounded_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), children_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  DisplayListBuilder expected_builder;
  /* ImageFilterLayer::Paint() */ {
    DlPaint dl_paint;
    dl_paint.setImageFilter(dl_image_filter.get());
    expected_builder.SaveLayer(&children_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.DrawPath(child_path1, DlPaint(DlColor::kYellow()));
      }
      /* MockLayer::Paint() */ {
        expected_builder.DrawPath(child_path2, DlPaint(DlColor::kCyan()));
      }
    }
  }
  expected_builder.Restore();
  auto expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(ImageFilterLayerTest, Nested) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const DlPaint child_paint1 = DlPaint(DlColor::kYellow());
  const DlPaint child_paint2 = DlPaint(DlColor::kCyan());
  auto dl_image_filter1 = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);
  auto dl_image_filter2 = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer1 = std::make_shared<ImageFilterLayer>(dl_image_filter1);
  auto layer2 = std::make_shared<ImageFilterLayer>(dl_image_filter2);
  layer2->Add(mock_layer2);
  layer1->Add(mock_layer1);
  layer1->Add(layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(SkRect::Make(child_path2.getBounds().roundOut()));
  const SkRect children_rounded_bounds =
      SkRect::Make(children_bounds.roundOut());
  const SkRect mock_layer2_rounded_bounds =
      SkRect::Make(child_path2.getBounds().roundOut());

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer1->Preroll(preroll_context());
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer1->paint_bounds(), children_rounded_bounds);
  EXPECT_EQ(layer1->child_paint_bounds(), children_bounds);
  EXPECT_EQ(layer2->paint_bounds(), mock_layer2_rounded_bounds);
  EXPECT_EQ(layer2->child_paint_bounds(), child_path2.getBounds());
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer1->needs_painting(paint_context()));
  EXPECT_TRUE(layer2->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  DisplayListBuilder expected_builder;
  /* ImageFilterLayer::Paint() */ {
    DlPaint dl_paint;
    dl_paint.setImageFilter(dl_image_filter1.get());
    expected_builder.SaveLayer(&children_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.DrawPath(child_path1, DlPaint(DlColor::kYellow()));
      }
      /* ImageFilterLayer::Paint() */ {
        DlPaint child_paint;
        child_paint.setImageFilter(dl_image_filter2.get());
        expected_builder.SaveLayer(&child_path2.getBounds(), &child_paint);
        /* MockLayer::Paint() */ {
          expected_builder.DrawPath(child_path2, DlPaint(DlColor::kCyan()));
        }
        expected_builder.Restore();
      }
    }
  }
  expected_builder.Restore();
  auto expected_display_list = expected_builder.Build();

  layer1->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(ImageFilterLayerTest, Readback) {
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kLinear);

  // ImageFilterLayer does not read from surface
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context());
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // ImageFilterLayer blocks child with readback
  auto mock_layer = std::make_shared<MockLayer>(SkPath(), DlPaint());
  mock_layer->set_fake_reads_surface(true);
  layer->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context());
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

TEST_F(ImageFilterLayerTest, CacheChild) {
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter);
  layer->Add(mock_layer);

  SkMatrix cache_ctm = initial_transform;
  DisplayListBuilder cache_canvas;
  cache_canvas.Transform(cache_ctm);
  DisplayListBuilder other_canvas;
  other_canvas.Transform(other_transform);
  DlPaint paint;

  use_mock_raster_cache();
  const auto* cacheable_image_filter_item = layer->raster_cache_item();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  // ImageFilterLayer default cache itself.
  EXPECT_EQ(cacheable_image_filter_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_image_filter_item->Draw(paint_context(), &paint));

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);
  // The layer_cache_item's strategy is Children, mean we will must cache
  // his children
  EXPECT_EQ(cacheable_image_filter_item->cache_state(),
            RasterCacheItem::CacheState::kChildren);
  EXPECT_TRUE(raster_cache()->Draw(cacheable_image_filter_item->GetId().value(),
                                   cache_canvas, &paint));
  EXPECT_FALSE(raster_cache()->Draw(
      cacheable_image_filter_item->GetId().value(), other_canvas, &paint));
}

TEST_F(ImageFilterLayerTest, CacheChildren) {
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  DlPaint paint;
  const SkPath child_path1 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  const SkPath child_path2 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2);
  auto offset = SkPoint::Make(54, 24);
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter, offset);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkMatrix cache_ctm = initial_transform;
  DisplayListBuilder cache_canvas;
  cache_canvas.Transform(cache_ctm);
  DisplayListBuilder other_canvas;
  other_canvas.Transform(other_transform);

  use_mock_raster_cache();

  const auto* cacheable_image_filter_item = layer->raster_cache_item();
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);

  // ImageFilterLayer default cache itself.
  EXPECT_EQ(cacheable_image_filter_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_image_filter_item->Draw(paint_context(), &paint));

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);

  // The layer_cache_item's strategy is Children, mean we will must cache his
  // children
  EXPECT_EQ(cacheable_image_filter_item->cache_state(),
            RasterCacheItem::CacheState::kChildren);
  EXPECT_TRUE(raster_cache()->Draw(cacheable_image_filter_item->GetId().value(),
                                   cache_canvas, &paint));
  EXPECT_FALSE(raster_cache()->Draw(
      cacheable_image_filter_item->GetId().value(), other_canvas, &paint));

  layer->Preroll(preroll_context());

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  SkMatrix snapped_matrix = SkMatrix::MakeAll(  //
      1, 0, SkScalarRoundToScalar(offset.fX),   //
      0, 1, SkScalarRoundToScalar(offset.fY),   //
      0, 0, 1);
  SkMatrix cache_matrix = initial_transform;
  cache_matrix.preConcat(snapped_matrix);
  auto transformed_filter = dl_image_filter->makeWithLocalMatrix(cache_matrix);

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ImageFilter)layer::Paint() */ {
    expected_builder.Save();
    {
      expected_builder.Translate(offset.fX, offset.fY);
      // snap translation components to pixels due to using raster cache
      expected_builder.TransformReset();
      expected_builder.Transform(snapped_matrix);
      DlPaint dl_paint;
      dl_paint.setImageFilter(transformed_filter.get());
      raster_cache()->Draw(cacheable_image_filter_item->GetId().value(),
                           expected_builder, &dl_paint);
    }
    expected_builder.Restore();
  }
  expected_builder.Restore();
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ImageFilterLayerTest, CacheImageFilterLayerSelf) {
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);

  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  auto child_rect = SkRect::MakeWH(5.0f, 5.0f);
  const SkPath child_path = SkPath().addRect(child_rect);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto offset = SkPoint::Make(53.8, 24.4);
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter, offset);
  layer->Add(mock_layer);

  SkMatrix cache_ctm = initial_transform;
  DisplayListBuilder cache_canvas;
  cache_canvas.Transform(cache_ctm);
  DisplayListBuilder other_canvas;
  other_canvas.Transform(other_transform);
  DlPaint paint;

  SkMatrix snapped_matrix = SkMatrix::MakeAll(  //
      1, 0, SkScalarRoundToScalar(offset.fX),   //
      0, 1, SkScalarRoundToScalar(offset.fY),   //
      0, 0, 1);

  use_mock_raster_cache();
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  const auto* cacheable_image_filter_item = layer->raster_cache_item();
  // frame 1.
  layer->Preroll(preroll_context());

  layer->Paint(display_list_paint_context());
  {
    DisplayListBuilder expected_builder;
    /* (ImageFilter)layer::Paint */ {
      expected_builder.Save();
      {
        expected_builder.Translate(offset.fX, offset.fY);
        // Snap to pixel translation due to use of raster cache
        expected_builder.TransformReset();
        expected_builder.Transform(snapped_matrix);
        DlPaint save_paint = DlPaint().setImageFilter(dl_image_filter);
        expected_builder.SaveLayer(&child_rect, &save_paint);
        {
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(child_path, DlPaint());
          }
        }
        expected_builder.Restore();
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(
        DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
  }

  // frame 2.
  layer->Preroll(preroll_context());
  layer->Paint(display_list_paint_context());
  // frame 3.
  layer->Preroll(preroll_context());
  layer->Paint(display_list_paint_context());

  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  // frame1,2 cache the ImageFilter's children layer, frame3 cache the
  // ImageFilterLayer
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)2);

  // ImageFilterLayer default cache itself.
  EXPECT_EQ(cacheable_image_filter_item->cache_state(),
            RasterCacheItem::CacheState::kCurrent);
  EXPECT_EQ(cacheable_image_filter_item->GetId(),
            RasterCacheKeyID(layer->unique_id(), RasterCacheKeyType::kLayer));
  EXPECT_TRUE(raster_cache()->Draw(cacheable_image_filter_item->GetId().value(),
                                   cache_canvas, &paint));
  EXPECT_FALSE(raster_cache()->Draw(
      cacheable_image_filter_item->GetId().value(), other_canvas, &paint));

  layer->Preroll(preroll_context());

  reset_display_list();
  layer->Paint(display_list_paint_context());
  {
    DisplayListBuilder expected_builder;
    /* (ImageFilter)layer::Paint */ {
      expected_builder.Save();
      {
        EXPECT_TRUE(
            raster_cache()->Draw(cacheable_image_filter_item->GetId().value(),
                                 expected_builder, nullptr));
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(
        DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
  }
}

TEST_F(ImageFilterLayerTest, OpacityInheritance) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto dl_image_filter = std::make_shared<DlMatrixImageFilter>(
      SkMatrix(), DlImageSampling::kMipmapLinear);

  // The mock_layer child will not be compatible with opacity
  auto mock_layer = MockLayer::Make(child_path, child_paint);
  auto image_filter_layer = std::make_shared<ImageFilterLayer>(dl_image_filter);
  image_filter_layer->Add(mock_layer);

  PrerollContext* context = preroll_context();
  context->state_stack.set_preroll_delegate(initial_transform);
  image_filter_layer->Preroll(preroll_context());
  // ImageFilterLayers can always inherit opacity whether or not their
  // children are compatible.
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity |
                LayerStateStack::kCallerCanApplyColorFilter);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(image_filter_layer);
  context->state_stack.set_preroll_delegate(SkMatrix::I());
  opacity_layer->Preroll(context);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder expected_builder;
  /* OpacityLayer::Paint() */ {
    expected_builder.Save();
    {
      expected_builder.Translate(offset.fX, offset.fY);
      /* ImageFilterLayer::Paint() */ {
        DlPaint image_filter_paint;
        image_filter_paint.setColor(opacity_alpha << 24);
        image_filter_paint.setImageFilter(dl_image_filter.get());
        expected_builder.SaveLayer(&child_path.getBounds(),
                                   &image_filter_paint);
        /* MockLayer::Paint() */ {
          expected_builder.DrawPath(child_path,
                                    DlPaint(child_paint.getColor()));
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(expected_builder.Build(), display_list()));
}

using ImageFilterLayerDiffTest = DiffContextTest;

TEST_F(ImageFilterLayerDiffTest, ImageFilterLayer) {
  auto dl_blur_filter =
      std::make_shared<DlBlurImageFilter>(10, 10, DlTileMode::kClamp);
  {
    // tests later assume 30px paint area, fail early if that's not the case
    SkIRect input_bounds;
    dl_blur_filter->get_input_device_bounds(SkIRect::MakeWH(10, 10),
                                            SkMatrix::I(), input_bounds);
    EXPECT_EQ(input_bounds, SkIRect::MakeLTRB(-30, -30, 40, 40));
  }

  MockLayerTree l1;
  auto filter_layer = std::make_shared<ImageFilterLayer>(dl_blur_filter);
  auto path = SkPath().addRect(SkRect::MakeLTRB(100, 100, 110, 110));
  filter_layer->Add(std::make_shared<MockLayer>(path));
  l1.root()->Add(filter_layer);

  auto damage = DiffLayerTree(l1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(70, 70, 140, 140));

  MockLayerTree l2;
  auto scale = std::make_shared<TransformLayer>(SkMatrix::Scale(2.0, 2.0));
  scale->Add(filter_layer);
  l2.root()->Add(scale);

  damage = DiffLayerTree(l2, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(140, 140, 280, 280));

  MockLayerTree l3;
  l3.root()->Add(scale);

  // path outside of ImageFilterLayer
  auto path1 = SkPath().addRect(SkRect::MakeLTRB(130, 130, 140, 140));
  l3.root()->Add(std::make_shared<MockLayer>(path1));
  damage = DiffLayerTree(l3, l2);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(130, 130, 140, 140));

  // path intersecting ImageFilterLayer, shouldn't trigger entire
  // ImageFilterLayer repaint
  MockLayerTree l4;
  l4.root()->Add(scale);
  auto path2 = SkPath().addRect(SkRect::MakeLTRB(130, 130, 141, 141));
  l4.root()->Add(std::make_shared<MockLayer>(path2));
  damage = DiffLayerTree(l4, l3);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(130, 130, 141, 141));
}

TEST_F(ImageFilterLayerDiffTest, ImageFilterLayerInflatestChildSize) {
  auto dl_blur_filter =
      std::make_shared<DlBlurImageFilter>(10, 10, DlTileMode::kClamp);

  {
    // tests later assume 30px paint area, fail early if that's not the case
    SkIRect input_bounds;
    dl_blur_filter->get_input_device_bounds(SkIRect::MakeWH(10, 10),
                                            SkMatrix::I(), input_bounds);
    EXPECT_EQ(input_bounds, SkIRect::MakeLTRB(-30, -30, 40, 40));
  }

  MockLayerTree l1;

  // Use nested filter layers to check if both contribute to child bounds
  auto filter_layer_1_1 = std::make_shared<ImageFilterLayer>(dl_blur_filter);
  auto filter_layer_1_2 = std::make_shared<ImageFilterLayer>(dl_blur_filter);
  filter_layer_1_1->Add(filter_layer_1_2);
  auto path = SkPath().addRect(SkRect::MakeLTRB(100, 100, 110, 110));
  filter_layer_1_2->Add(
      std::make_shared<MockLayer>(path, DlPaint(DlColor::kYellow())));
  l1.root()->Add(filter_layer_1_1);

  // second layer tree with identical filter layers but different child layer
  MockLayerTree l2;
  auto filter_layer2_1 = std::make_shared<ImageFilterLayer>(dl_blur_filter);
  filter_layer2_1->AssignOldLayer(filter_layer_1_1.get());
  auto filter_layer2_2 = std::make_shared<ImageFilterLayer>(dl_blur_filter);
  filter_layer2_2->AssignOldLayer(filter_layer_1_2.get());
  filter_layer2_1->Add(filter_layer2_2);
  filter_layer2_2->Add(
      std::make_shared<MockLayer>(path, DlPaint(DlColor::kRed())));
  l2.root()->Add(filter_layer2_1);

  DiffLayerTree(l1, MockLayerTree());
  auto damage = DiffLayerTree(l2, l1);

  // ensure that filter properly inflated child size
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(40, 40, 170, 170));
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(bugprone-unchecked-optional-access)

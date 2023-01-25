// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_tile_mode.h"
#include "flutter/flow/layers/image_filter_layer.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/flow/testing/diff_context_test.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"
#include "gtest/gtest.h"
#include "include/core/SkPaint.h"
#include "include/core/SkPath.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

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
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(nullptr);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  SkPaint filter_paint;
  filter_paint.setImageFilter(nullptr);
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({
                MockCanvas::DrawCall{
                    0, MockCanvas::DrawPathData{child_path, child_paint}},
            }));
}

TEST_F(ImageFilterLayerTest, SimpleFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
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
    expected_builder.saveLayer(&child_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.drawPath(child_path,
                                  DlPaint().setColor(DlColor::kYellow()));
      }
    }
  }
  expected_builder.restore();
  auto expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(ImageFilterLayerTest, SimpleFilterWithOffset) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect initial_cull_rect = SkRect::MakeLTRB(0, 0, 100, 100);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
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
    expected_builder.save();
    {
      expected_builder.translate(layer_offset.fX, layer_offset.fY);
      DlPaint dl_paint;
      dl_paint.setImageFilter(dl_image_filter.get());
      expected_builder.saveLayer(&child_bounds, &dl_paint);
      {
        /* MockLayer::Paint() */ {
          expected_builder.drawPath(child_path,
                                    DlPaint().setColor(DlColor::kYellow()));
        }
      }
      expected_builder.restore();
    }
    expected_builder.restore();
  }
  auto expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(ImageFilterLayerTest, SimpleFilterBounds) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
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
    expected_builder.saveLayer(&child_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.drawPath(child_path,
                                  DlPaint().setColor(DlColor::kYellow()));
      }
    }
  }
  expected_builder.restore();
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
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
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
    expected_builder.saveLayer(&children_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.drawPath(child_path1,
                                  DlPaint().setColor(DlColor::kYellow()));
      }
      /* MockLayer::Paint() */ {
        expected_builder.drawPath(child_path2,
                                  DlPaint().setColor(DlColor::kCyan()));
      }
    }
  }
  expected_builder.restore();
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
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
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
    expected_builder.saveLayer(&children_bounds, &dl_paint);
    {
      /* MockLayer::Paint() */ {
        expected_builder.drawPath(child_path1,
                                  DlPaint().setColor(DlColor::kYellow()));
      }
      /* ImageFilterLayer::Paint() */ {
        DlPaint child_paint;
        child_paint.setImageFilter(dl_image_filter2.get());
        expected_builder.saveLayer(&child_path2.getBounds(), &child_paint);
        /* MockLayer::Paint() */ {
          expected_builder.drawPath(child_path2,
                                    DlPaint().setColor(DlColor::kCyan()));
        }
        expected_builder.restore();
      }
    }
  }
  expected_builder.restore();
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
  auto mock_layer = std::make_shared<MockLayer>(SkPath(), SkPaint());
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
  SkCanvas cache_canvas;
  cache_canvas.setMatrix(cache_ctm);
  SkCanvas other_canvas;
  other_canvas.setMatrix(other_transform);
  SkPaint paint = SkPaint();

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
  SkPaint paint = SkPaint();
  const SkPath child_path1 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  const SkPath child_path2 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2);
  auto offset = SkPoint::Make(54, 24);
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter, offset);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkMatrix cache_ctm = initial_transform;
  SkCanvas cache_canvas;
  cache_canvas.setMatrix(cache_ctm);
  SkCanvas other_canvas;
  other_canvas.setMatrix(other_transform);

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

  mock_canvas().reset_draw_calls();
  layer->Preroll(preroll_context());
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls().size(), 8UL);
  auto call0 = MockCanvas::DrawCall{0, MockCanvas::SaveData{1}};
  EXPECT_EQ(mock_canvas().draw_calls()[0], call0);
  auto call1 = MockCanvas::DrawCall{
      1, MockCanvas::ConcatMatrixData{SkM44(SkMatrix::Translate(offset))}};
  EXPECT_EQ(mock_canvas().draw_calls()[1], call1);
  auto call2 = MockCanvas::DrawCall{
      1, MockCanvas::SetMatrixData{SkM44(SkMatrix::Translate(offset))}};
  EXPECT_EQ(mock_canvas().draw_calls()[2], call2);
  auto call3 = MockCanvas::DrawCall{1, MockCanvas::SaveData{2}};
  EXPECT_EQ(mock_canvas().draw_calls()[3], call3);
  auto call4 = MockCanvas::DrawCall{
      2, MockCanvas::SetMatrixData{SkM44(SkMatrix::Translate(0.0, 0.0))}};
  EXPECT_EQ(mock_canvas().draw_calls()[4], call4);
  EXPECT_EQ(mock_canvas().draw_calls()[5].layer, 2);
  EXPECT_TRUE(std::holds_alternative<MockCanvas::DrawImageData>(
      mock_canvas().draw_calls()[5].data));
  auto call5_data =
      std::get<MockCanvas::DrawImageData>(mock_canvas().draw_calls()[5].data);
  EXPECT_EQ(call5_data.x, offset.fX);
  EXPECT_EQ(call5_data.y, offset.fY);
  auto call6 = MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}};
  EXPECT_EQ(mock_canvas().draw_calls()[6], call6);
  auto call7 = MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}};
  EXPECT_EQ(mock_canvas().draw_calls()[7], call7);
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
  auto offset_rounded =
      SkPoint::Make(std::round(offset.x()), std::round(offset.y()));
  auto offset_rounded_out =
      SkPoint::Make(std::floor(offset.x()), std::floor(offset.y()));
  auto layer = std::make_shared<ImageFilterLayer>(dl_image_filter, offset);
  layer->Add(mock_layer);

  SkMatrix cache_ctm = initial_transform;
  SkCanvas cache_canvas;
  cache_canvas.setMatrix(cache_ctm);
  SkCanvas other_canvas;
  other_canvas.setMatrix(other_transform);
  SkPaint paint = SkPaint();

  use_mock_raster_cache();
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  const auto* cacheable_image_filter_item = layer->raster_cache_item();
  // frame 1.
  layer->Preroll(preroll_context());
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls().size(), 7UL);
  auto uncached_call0 = MockCanvas::DrawCall{0, MockCanvas::SaveData{1}};
  EXPECT_EQ(mock_canvas().draw_calls()[0], uncached_call0);
  auto uncached_call1 = MockCanvas::DrawCall{
      1, MockCanvas::ConcatMatrixData{SkM44(SkMatrix::Translate(offset))}};
  EXPECT_EQ(mock_canvas().draw_calls()[1], uncached_call1);
  auto uncached_call2 = MockCanvas::DrawCall{
      1, MockCanvas::SetMatrixData{SkM44(SkMatrix::Translate(offset_rounded))}};
  EXPECT_EQ(mock_canvas().draw_calls()[2], uncached_call2);
  EXPECT_EQ(mock_canvas().draw_calls()[3].layer, 1);
  auto uncached_call3_data =
      std::get<MockCanvas::SaveLayerData>(mock_canvas().draw_calls()[3].data);
  EXPECT_EQ(uncached_call3_data.save_bounds, child_rect);
  EXPECT_EQ(uncached_call3_data.save_to_layer, 2);
  auto uncached_call4 =
      MockCanvas::DrawCall{2, MockCanvas::DrawPathData{child_path, SkPaint()}};
  EXPECT_EQ(mock_canvas().draw_calls()[4], uncached_call4);
  auto uncached_call5 = MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}};
  EXPECT_EQ(mock_canvas().draw_calls()[5], uncached_call5);
  auto uncached_call6 = MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}};
  EXPECT_EQ(mock_canvas().draw_calls()[6], uncached_call6);
  // frame 2.
  layer->Preroll(preroll_context());
  layer->Paint(paint_context());
  // frame 3.
  layer->Preroll(preroll_context());
  layer->Paint(paint_context());

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

  mock_canvas().reset_draw_calls();
  layer->Preroll(preroll_context());
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls().size(), 4UL);
  auto cached_call0 = MockCanvas::DrawCall{0, MockCanvas::SaveData{1}};
  EXPECT_EQ(mock_canvas().draw_calls()[0], cached_call0);
  auto cached_call1 = MockCanvas::DrawCall{
      1, MockCanvas::SetMatrixData{SkM44(SkMatrix::Translate(0.0, 0.0))}};
  EXPECT_EQ(mock_canvas().draw_calls()[1], cached_call1);
  EXPECT_EQ(mock_canvas().draw_calls()[2].layer, 1);
  EXPECT_TRUE(std::holds_alternative<MockCanvas::DrawImageDataNoPaint>(
      mock_canvas().draw_calls()[2].data));
  auto cached_call2_data = std::get<MockCanvas::DrawImageDataNoPaint>(
      mock_canvas().draw_calls()[2].data);
  EXPECT_EQ(cached_call2_data.x, offset_rounded_out.fX);
  EXPECT_EQ(cached_call2_data.y, offset_rounded_out.fY);
  auto cached_call3 = MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}};
  EXPECT_EQ(mock_canvas().draw_calls()[3], cached_call3);
}

TEST_F(ImageFilterLayerTest, OpacityInheritance) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
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
    expected_builder.save();
    {
      expected_builder.translate(offset.fX, offset.fY);
      /* ImageFilterLayer::Paint() */ {
        DlPaint image_filter_paint;
        image_filter_paint.setColor(opacity_alpha << 24);
        image_filter_paint.setImageFilter(dl_image_filter.get());
        expected_builder.saveLayer(&child_path.getBounds(),
                                   &image_filter_paint);
        /* MockLayer::Paint() */ {
          expected_builder.drawPath(child_path,
                                    DlPaint().setColor(child_paint.getColor()));
        }
        expected_builder.restore();
      }
    }
    expected_builder.restore();
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
      std::make_shared<MockLayer>(path, SkPaint(SkColors::kYellow)));
  l1.root()->Add(filter_layer_1_1);

  // second layer tree with identical filter layers but different child layer
  MockLayerTree l2;
  auto filter_layer2_1 = std::make_shared<ImageFilterLayer>(dl_blur_filter);
  filter_layer2_1->AssignOldLayer(filter_layer_1_1.get());
  auto filter_layer2_2 = std::make_shared<ImageFilterLayer>(dl_blur_filter);
  filter_layer2_2->AssignOldLayer(filter_layer_1_2.get());
  filter_layer2_1->Add(filter_layer2_2);
  filter_layer2_2->Add(
      std::make_shared<MockLayer>(path, SkPaint(SkColors::kRed)));
  l2.root()->Add(filter_layer2_1);

  DiffLayerTree(l1, MockLayerTree());
  auto damage = DiffLayerTree(l2, l1);

  // ensure that filter properly inflated child size
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(40, 40, 170, 170));
}

}  // namespace testing
}  // namespace flutter

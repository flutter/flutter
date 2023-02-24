// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/flow/layers/display_list_layer.h"

#include "flutter/display_list/display_list_builder.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/testing/diff_context_test.h"
#include "flutter/flow/testing/skia_gpu_object_layer_test.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

using DisplayListLayerTest = SkiaGPUObjectLayerTest;

#ifndef NDEBUG
TEST_F(DisplayListLayerTest, PaintBeforePrerollInvalidDisplayListDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject<DisplayList>(), false, false);

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "display_list_\\.skia_object\\(\\)");
}

TEST_F(DisplayListLayerTest, PaintBeforePrerollDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  DisplayListBuilder builder;
  builder.drawRect(picture_bounds);
  auto display_list = builder.Build();
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject<DisplayList>(display_list, unref_queue()),
      false, false);

  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(DisplayListLayerTest, PaintingEmptyLayerDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  const SkRect picture_bounds = SkRect::MakeEmpty();
  DisplayListBuilder builder;
  builder.drawRect(picture_bounds);
  auto display_list = builder.Build();
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject<DisplayList>(display_list, unref_queue()),
      false, false);

  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(DisplayListLayerTest, InvalidDisplayListDies) {
  const SkPoint layer_offset = SkPoint::Make(0.0f, 0.0f);
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject<DisplayList>(), false, false);

  // Crashes reading a nullptr.
  EXPECT_DEATH_IF_SUPPORTED(layer->Preroll(preroll_context()), "");
}
#endif

TEST_F(DisplayListLayerTest, SimpleDisplayList) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkMatrix layer_offset_matrix =
      SkMatrix::Translate(layer_offset.fX, layer_offset.fY);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  DisplayListBuilder builder;
  builder.drawRect(picture_bounds);
  auto display_list = builder.Build();
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), false, false);

  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(),
            picture_bounds.makeOffset(layer_offset.fX, layer_offset.fY));
  EXPECT_EQ(layer->display_list(), display_list.get());
  EXPECT_TRUE(layer->needs_painting(paint_context()));

  layer->Paint(paint_context());
  auto expected_draw_calls = std::vector(
      {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
       MockCanvas::DrawCall{
           1, MockCanvas::ConcatMatrixData{SkM44(layer_offset_matrix)}},
       MockCanvas::DrawCall{1,
                            MockCanvas::DrawDisplayListData{display_list, 1}},
       MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}});
  EXPECT_EQ(mock_canvas().draw_calls(), expected_draw_calls);
}

TEST_F(DisplayListLayerTest, CachingDoesNotChangeCullRect) {
  const SkPoint layer_offset = SkPoint::Make(10, 10);
  DisplayListBuilder builder;
  builder.drawRect({10, 10, 20, 20});
  auto display_list = builder.Build();
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), true, false);

  SkRect original_cull_rect = preroll_context()->state_stack.device_cull_rect();
  use_mock_raster_cache();
  layer->Preroll(preroll_context());
  ASSERT_EQ(preroll_context()->state_stack.device_cull_rect(),
            original_cull_rect);
}

TEST_F(DisplayListLayerTest, SimpleDisplayListOpacityInheritance) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  DisplayListBuilder builder;
  builder.drawRect(picture_bounds);
  auto display_list = builder.Build();
  auto display_list_layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), false, false);
  EXPECT_TRUE(display_list->can_apply_group_opacity());

  auto context = preroll_context();
  display_list_layer->Preroll(preroll_context());
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);

  int opacity_alpha = 0x7F;
  SkPoint opacity_offset = SkPoint::Make(10, 10);
  auto opacity_layer =
      std::make_shared<OpacityLayer>(opacity_alpha, opacity_offset);
  opacity_layer->Add(display_list_layer);
  opacity_layer->Preroll(context);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder child_builder;
  child_builder.drawRect(picture_bounds);
  auto child_display_list = child_builder.Build();

  DisplayListBuilder expected_builder;
  /* opacity_layer::Paint() */ {
    expected_builder.save();
    {
      expected_builder.translate(opacity_offset.fX, opacity_offset.fY);
      /* display_list_layer::Paint() */ {
        expected_builder.save();
        {
          expected_builder.translate(layer_offset.fX, layer_offset.fY);
          expected_builder.setColor(opacity_alpha << 24);
          expected_builder.saveLayer(&picture_bounds, true);
          /* display_list contents */ {  //
            expected_builder.drawDisplayList(child_display_list);
          }
          expected_builder.restore();
          expected_builder.setColor(DlColor::kBlack());
        }
        expected_builder.restore();
      }
    }
    expected_builder.restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(
      DisplayListsEQ_Verbose(this->display_list(), expected_builder.Build()));
}

TEST_F(DisplayListLayerTest, IncompatibleDisplayListOpacityInheritance) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkRect picture1_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect picture2_bounds = SkRect::MakeLTRB(10.0f, 15.0f, 30.0f, 35.0f);
  DisplayListBuilder builder;
  builder.drawRect(picture1_bounds);
  builder.drawRect(picture2_bounds);
  auto display_list = builder.Build();
  auto display_list_layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), false, false);
  EXPECT_FALSE(display_list->can_apply_group_opacity());

  auto context = preroll_context();
  display_list_layer->Preroll(preroll_context());
  EXPECT_EQ(context->renderable_state_flags, 0);

  int opacity_alpha = 0x7F;
  SkPoint opacity_offset = SkPoint::Make(10, 10);
  auto opacity_layer =
      std::make_shared<OpacityLayer>(opacity_alpha, opacity_offset);
  opacity_layer->Add(display_list_layer);
  opacity_layer->Preroll(context);
  EXPECT_FALSE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder child_builder;
  child_builder.drawRect(picture1_bounds);
  child_builder.drawRect(picture2_bounds);
  auto child_display_list = child_builder.Build();

  auto display_list_bounds = picture1_bounds;
  display_list_bounds.join(picture2_bounds);
  auto save_layer_bounds =
      display_list_bounds.makeOffset(layer_offset.fX, layer_offset.fY);
  DisplayListBuilder expected_builder;
  /* opacity_layer::Paint() */ {
    expected_builder.save();
    {
      expected_builder.translate(opacity_offset.fX, opacity_offset.fY);
      expected_builder.setColor(opacity_alpha << 24);
      expected_builder.saveLayer(&save_layer_bounds, true);
      {
        /* display_list_layer::Paint() */ {
          expected_builder.save();
          {
            expected_builder.translate(layer_offset.fX, layer_offset.fY);
            expected_builder.drawDisplayList(child_display_list);
          }
          expected_builder.restore();
        }
      }
      expected_builder.restore();
    }
    expected_builder.restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(
      DisplayListsEQ_Verbose(this->display_list(), expected_builder.Build()));
}

TEST_F(DisplayListLayerTest, CachedIncompatibleDisplayListOpacityInheritance) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkRect picture1_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect picture2_bounds = SkRect::MakeLTRB(10.0f, 15.0f, 30.0f, 35.0f);
  DisplayListBuilder builder;
  builder.drawRect(picture1_bounds);
  builder.drawRect(picture2_bounds);
  auto display_list = builder.Build();
  auto display_list_layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), true, false);
  EXPECT_FALSE(display_list->can_apply_group_opacity());

  use_skia_raster_cache();

  auto context = preroll_context();
  display_list_layer->Preroll(preroll_context());
  EXPECT_EQ(context->renderable_state_flags, 0);

  // Pump the DisplayListLayer until it is ready to cache its DL
  display_list_layer->Preroll(preroll_context());
  display_list_layer->Preroll(preroll_context());
  display_list_layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(*preroll_context()->raster_cached_entries,
                              &paint_context(), false);

  int opacity_alpha = 0x7F;
  SkPoint opacity_offset = SkPoint::Make(10, 10);
  auto opacity_layer =
      std::make_shared<OpacityLayer>(opacity_alpha, opacity_offset);
  opacity_layer->Add(display_list_layer);
  opacity_layer->Preroll(context);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  // The following would be a great test of the painting of the above
  // setup, but for the fact that the raster cache stores raw pointers
  // to sk_sp<SkImage> and the canvas recorder then wraps each of those
  // in a unique DlImage - which means the DisplayList objects will not
  // compare with the Equals method since the addresses of the two
  // DlImage objects will not be equal even if they point to the same
  // SkImage on each frame.
  // See https://github.com/flutter/flutter/issues/102331
  //   auto display_list_bounds = picture1_bounds;
  //   display_list_bounds.join(picture2_bounds);
  //   auto save_layer_bounds =
  //       display_list_bounds.makeOffset(layer_offset.fX, layer_offset.fY);
  //   save_layer_bounds.roundOut(&save_layer_bounds);
  //   auto opacity_integral_matrix =
  //       RasterCacheUtil::GetIntegralTransCTM(SkMatrix::Translate(opacity_offset));
  //   SkMatrix layer_offset_matrix = opacity_integral_matrix;
  //   layer_offset_matrix.postTranslate(layer_offset.fX, layer_offset.fY);
  //   auto layer_offset_integral_matrix =
  //       RasterCacheUtil::GetIntegralTransCTM(layer_offset_matrix);
  //   // Using a recorder instead of a DisplayListBuilder so we can hand it
  //   // off to the RasterCache::Draw() method
  //   DisplayListCanvasRecorder recorder(SkRect::MakeWH(1000, 1000));
  //   /* opacity_layer::Paint() */ {
  //     recorder.save();
  //     {
  //       recorder.translate(opacity_offset.fX, opacity_offset.fY);
  //       /* display_list_layer::Paint() */ {
  //         recorder.save();
  //         {
  //           recorder.translate(layer_offset.fX, layer_offset.fY);
  //           SkPaint p;
  //           p.setAlpha(opacity_alpha);
  //           context->raster_cache->Draw(*display_list, recorder, &p);
  //         }
  //         recorder.restore();
  //       }
  //     }
  //     recorder.restore();
  //   }

  //   opacity_layer->Paint(display_list_paint_context());
  //   EXPECT_TRUE(
  //       DisplayListsEQ_Verbose(recorder.Build(), this->display_list()));
}

using DisplayListLayerDiffTest = DiffContextTest;

TEST_F(DisplayListLayerDiffTest, SimpleDisplayList) {
  auto display_list = CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60), 1);

  MockLayerTree tree1;
  tree1.root()->Add(CreateDisplayListLayer(display_list));

  auto damage = DiffLayerTree(tree1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(10, 10, 60, 60));

  MockLayerTree tree2;
  tree2.root()->Add(CreateDisplayListLayer(display_list));

  damage = DiffLayerTree(tree2, tree1);
  EXPECT_TRUE(damage.frame_damage.isEmpty());

  MockLayerTree tree3;
  damage = DiffLayerTree(tree3, tree2);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(10, 10, 60, 60));
}

TEST_F(DisplayListLayerDiffTest, FractionalTranslation) {
  auto display_list = CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60), 1);

  MockLayerTree tree1;
  tree1.root()->Add(
      CreateDisplayListLayer(display_list, SkPoint::Make(0.5, 0.5)));

  auto damage =
      DiffLayerTree(tree1, MockLayerTree(), SkIRect::MakeEmpty(), 0, 0,
                    /*use_raster_cache=*/false);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(10, 10, 61, 61));
}

TEST_F(DisplayListLayerDiffTest, FractionalTranslationWithRasterCache) {
  auto display_list = CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60), 1);

  MockLayerTree tree1;
  tree1.root()->Add(
      CreateDisplayListLayer(display_list, SkPoint::Make(0.5, 0.5)));

  auto damage =
      DiffLayerTree(tree1, MockLayerTree(), SkIRect::MakeEmpty(), 0, 0,
                    /*use_raster_cache=*/true);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(11, 11, 61, 61));
}

TEST_F(DisplayListLayerDiffTest, DisplayListCompare) {
  MockLayerTree tree1;
  auto display_list1 = CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60), 1);
  tree1.root()->Add(CreateDisplayListLayer(display_list1));

  auto damage = DiffLayerTree(tree1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(10, 10, 60, 60));

  MockLayerTree tree2;
  auto display_list2 = CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60), 1);
  tree2.root()->Add(CreateDisplayListLayer(display_list2));

  damage = DiffLayerTree(tree2, tree1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeEmpty());

  MockLayerTree tree3;
  auto display_list3 = CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60), 1);
  // add offset
  tree3.root()->Add(
      CreateDisplayListLayer(display_list3, SkPoint::Make(10, 10)));

  damage = DiffLayerTree(tree3, tree2);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(10, 10, 70, 70));

  MockLayerTree tree4;
  // different color
  auto display_list4 = CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60), 2);
  tree4.root()->Add(
      CreateDisplayListLayer(display_list4, SkPoint::Make(10, 10)));

  damage = DiffLayerTree(tree4, tree3);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(20, 20, 70, 70));
}

TEST_F(DisplayListLayerTest, LayerTreeSnapshotsWhenEnabled) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  DisplayListBuilder builder;
  builder.drawRect(picture_bounds);
  auto display_list = builder.Build();
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), false, false);

  layer->Preroll(preroll_context());

  enable_leaf_layer_tracing();
  layer->Paint(paint_context());
  disable_leaf_layer_tracing();

  auto& snapshot_store = layer_snapshot_store();
  EXPECT_EQ(1u, snapshot_store.Size());
}

TEST_F(DisplayListLayerTest, NoLayerTreeSnapshotsWhenDisabledByDefault) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  DisplayListBuilder builder;
  builder.drawRect(picture_bounds);
  auto display_list = builder.Build();
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), false, false);

  layer->Preroll(preroll_context());
  layer->Paint(paint_context());

  auto& snapshot_store = layer_snapshot_store();
  EXPECT_EQ(0u, snapshot_store.Size());
}

TEST_F(DisplayListLayerTest, DisplayListAccessCountDependsOnVisibility) {
  const SkPoint layer_offset = SkPoint::Make(1.5f, -0.5f);
  const SkRect picture_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect missed_cull_rect = SkRect::MakeLTRB(100, 100, 200, 200);
  const SkRect hit_cull_rect = SkRect::MakeLTRB(0, 0, 200, 200);
  DisplayListBuilder builder;
  builder.drawRect(picture_bounds);
  auto display_list = builder.Build();
  auto layer = std::make_shared<DisplayListLayer>(
      layer_offset, SkiaGPUObject(display_list, unref_queue()), true, false);

  auto raster_cache_item = layer->raster_cache_item();
  use_mock_raster_cache();

  // First Preroll the DisplayListLayer a few times where it does not intersect
  // the cull rect. No caching progress should occur during this time, the
  // access_count should remain 0 because the DisplayList was never "visible".
  ASSERT_TRUE(preroll_context()->state_stack.is_empty());
  preroll_context()->state_stack.set_preroll_delegate(missed_cull_rect);
  for (int i = 0; i < 10; i++) {
    preroll_context()->raster_cached_entries->clear();
    layer->Preroll(preroll_context());
    ASSERT_EQ(raster_cache_item->cache_state(), RasterCacheItem::kNone);
    ASSERT_TRUE(raster_cache_item->GetId().has_value());
    ASSERT_EQ(preroll_context()->raster_cache->GetAccessCount(
                  raster_cache_item->GetId().value(), SkMatrix::I()),
              0);
    ASSERT_EQ(preroll_context()->raster_cached_entries->size(), size_t(1));
    ASSERT_EQ(preroll_context()->raster_cache->EstimatePictureCacheByteSize(),
              size_t(0));
    ASSERT_FALSE(raster_cache_item->TryToPrepareRasterCache(paint_context()));
    ASSERT_FALSE(raster_cache_item->Draw(paint_context(), nullptr));
  }

  // Next Preroll the DisplayListLayer once where it does intersect
  // the cull rect. No caching progress should occur during this time
  // since this is the first frame in which it was visible, but the
  // count should start incrementing.
  ASSERT_TRUE(preroll_context()->state_stack.is_empty());
  preroll_context()->state_stack.set_preroll_delegate(hit_cull_rect);
  preroll_context()->raster_cached_entries->clear();
  layer->Preroll(preroll_context());
  ASSERT_EQ(raster_cache_item->cache_state(), RasterCacheItem::kNone);
  ASSERT_TRUE(raster_cache_item->GetId().has_value());
  ASSERT_EQ(preroll_context()->raster_cache->GetAccessCount(
                raster_cache_item->GetId().value(), SkMatrix::I()),
            1);
  ASSERT_EQ(preroll_context()->raster_cached_entries->size(), size_t(1));
  ASSERT_EQ(preroll_context()->raster_cache->EstimatePictureCacheByteSize(),
            size_t(0));
  ASSERT_FALSE(raster_cache_item->TryToPrepareRasterCache(paint_context()));
  ASSERT_FALSE(raster_cache_item->Draw(paint_context(), nullptr));

  // Now we can Preroll the DisplayListLayer again with a cull rect that
  // it does not intersect and it should continue to count these operations
  // even though it is not visible. No actual caching should occur yet,
  // even though we will surpass its threshold.
  ASSERT_TRUE(preroll_context()->state_stack.is_empty());
  preroll_context()->state_stack.set_preroll_delegate(missed_cull_rect);
  for (int i = 0; i < 10; i++) {
    preroll_context()->raster_cached_entries->clear();
    layer->Preroll(preroll_context());
    ASSERT_EQ(raster_cache_item->cache_state(), RasterCacheItem::kNone);
    ASSERT_TRUE(raster_cache_item->GetId().has_value());
    ASSERT_EQ(preroll_context()->raster_cache->GetAccessCount(
                  raster_cache_item->GetId().value(), SkMatrix::I()),
              i + 2);
    ASSERT_EQ(preroll_context()->raster_cached_entries->size(), size_t(1));
    ASSERT_EQ(preroll_context()->raster_cache->EstimatePictureCacheByteSize(),
              size_t(0));
    ASSERT_FALSE(raster_cache_item->TryToPrepareRasterCache(paint_context()));
    ASSERT_FALSE(raster_cache_item->Draw(paint_context(), nullptr));
  }

  // Finally Preroll the DisplayListLayer again where it does intersect
  // the cull rect. Since we should have exhausted our access count
  // threshold in the loop above, these operations should result in the
  // DisplayList being cached.
  ASSERT_TRUE(preroll_context()->state_stack.is_empty());
  preroll_context()->state_stack.set_preroll_delegate(hit_cull_rect);
  preroll_context()->raster_cached_entries->clear();
  layer->Preroll(preroll_context());
  ASSERT_EQ(raster_cache_item->cache_state(), RasterCacheItem::kCurrent);
  ASSERT_TRUE(raster_cache_item->GetId().has_value());
  ASSERT_EQ(preroll_context()->raster_cache->GetAccessCount(
                raster_cache_item->GetId().value(), SkMatrix::I()),
            12);
  ASSERT_EQ(preroll_context()->raster_cached_entries->size(), size_t(1));
  ASSERT_EQ(preroll_context()->raster_cache->EstimatePictureCacheByteSize(),
            size_t(0));
  ASSERT_TRUE(raster_cache_item->TryToPrepareRasterCache(paint_context()));
  ASSERT_GT(preroll_context()->raster_cache->EstimatePictureCacheByteSize(),
            size_t(0));
  ASSERT_TRUE(raster_cache_item->Draw(paint_context(), nullptr));
}

TEST_F(DisplayListLayerTest, OverflowCachedDisplayListOpacityInheritance) {
  use_mock_raster_cache();
  PrerollContext* context = preroll_context();
  int per_frame =
      RasterCacheUtil::kDefaultPictureAndDispLayListCacheLimitPerFrame;
  int layer_count = per_frame + 1;
  SkPoint opacity_offset = {10, 10};
  auto opacity_layer = std::make_shared<OpacityLayer>(0.5f, opacity_offset);
  std::shared_ptr<DisplayListLayer> layers[layer_count];
  for (int i = 0; i < layer_count; i++) {
    DisplayListBuilder builder(false);
    builder.drawRect({0, 0, 100, 100});
    builder.drawRect({50, 50, 100, 100});
    auto display_list = builder.Build();
    ASSERT_FALSE(display_list->can_apply_group_opacity());
    SkPoint offset = {i * 200.0f, 0};

    layers[i] = std::make_shared<DisplayListLayer>(
        offset, SkiaGPUObject(display_list, unref_queue()), true, false);
    opacity_layer->Add(layers[i]);
  }
  for (size_t j = 0; j < context->raster_cache->access_threshold(); j++) {
    context->raster_cache->BeginFrame();
    for (int i = 0; i < layer_count; i++) {
      context->renderable_state_flags = 0;
      layers[i]->Preroll(context);
      ASSERT_EQ(context->renderable_state_flags, 0) << "pass " << (j + 1);
    }
  }
  opacity_layer->Preroll(context);
  ASSERT_FALSE(opacity_layer->children_can_accept_opacity());
  LayerTree::TryToRasterCache(*context->raster_cached_entries, &paint_context(),
                              false);
  context->raster_cached_entries->clear();
  context->raster_cache->BeginFrame();
  for (int i = 0; i < per_frame; i++) {
    context->renderable_state_flags = 0;
    layers[i]->Preroll(context);
    ASSERT_EQ(context->renderable_state_flags,
              LayerStateStack::kCallerCanApplyOpacity)
        << "layer " << (i + 1);
  }
  for (int i = per_frame; i < layer_count; i++) {
    context->renderable_state_flags = 0;
    layers[i]->Preroll(context);
    ASSERT_EQ(context->renderable_state_flags, 0) << "layer " << (i + 1);
  }
  opacity_layer->Preroll(context);
  ASSERT_FALSE(opacity_layer->children_can_accept_opacity());
  LayerTree::TryToRasterCache(*context->raster_cached_entries, &paint_context(),
                              false);
  context->raster_cached_entries->clear();
  context->raster_cache->BeginFrame();
  for (int i = 0; i < layer_count; i++) {
    context->renderable_state_flags = 0;
    layers[i]->Preroll(context);
    ASSERT_EQ(context->renderable_state_flags,
              LayerStateStack::kCallerCanApplyOpacity)
        << "layer " << (i + 1);
  }
  opacity_layer->Preroll(context);
  ASSERT_TRUE(opacity_layer->children_can_accept_opacity());
}

}  // namespace testing
}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/opacity_layer.h"
#include "flutter/flow/layers/platform_view_layer.h"
#include "flutter/flow/raster_cache_item.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_embedder.h"
#include "flutter/flow/testing/mock_layer.h"
#include "gtest/gtest.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace flutter {
namespace testing {

using ClipPathLayerTest = LayerTest;

using ClipOp = DlCanvas::ClipOp;

#ifndef NDEBUG
TEST_F(ClipPathLayerTest, ClipNoneBehaviorDies) {
  EXPECT_DEATH_IF_SUPPORTED(
      auto clip = std::make_shared<ClipPathLayer>(SkPath(), Clip::none),
      "clip_behavior != Clip::none");
}

TEST_F(ClipPathLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<ClipPathLayer>(SkPath(), Clip::hardEdge);

  layer->Preroll(preroll_context());

  // Untouched
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(), kGiantRect);
  EXPECT_TRUE(preroll_context()->state_stack.is_empty());

  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->child_paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ClipPathLayerTest, PaintBeforePrerollDies) {
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, Clip::hardEdge);
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->child_paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ClipPathLayerTest, PaintingCulledLayerDies) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkRect distant_bounds = SkRect::MakeXYWH(100.0, 100.0, 10.0, 10.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, Clip::hardEdge);
  layer->Add(mock_layer);

  // Cull these children
  preroll_context()->state_stack.set_preroll_delegate(distant_bounds,
                                                      initial_matrix);
  layer->Preroll(preroll_context());

  // Untouched
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(), distant_bounds);
  EXPECT_TRUE(preroll_context()->state_stack.is_empty());

  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), kEmptyRect);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_path)}));

  auto mutator = paint_context().state_stack.save();
  mutator.clipRect(distant_bounds, false);
  EXPECT_FALSE(mock_layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_painting(paint_context()));
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(ClipPathLayerTest, ChildOutsideBounds) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect local_cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 2.0, 4.0);
  const SkRect device_cull_bounds = initial_matrix.mapRect(local_cull_bounds);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect clip_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath clip_path = SkPath().addRect(clip_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipPathLayer>(clip_path, Clip::hardEdge);
  layer->Add(mock_layer);

  SkRect clip_cull_rect = local_cull_bounds;
  ASSERT_TRUE(clip_cull_rect.intersect(clip_bounds));
  SkRect clip_layer_bounds = child_bounds;
  ASSERT_TRUE(clip_layer_bounds.intersect(clip_bounds));

  // Set up both contexts to cull clipped child
  preroll_context()->state_stack.set_preroll_delegate(device_cull_bounds,
                                                      initial_matrix);
  paint_context().canvas->ClipRect(device_cull_bounds);
  paint_context().canvas->Transform(initial_matrix);

  layer->Preroll(preroll_context());
  // Untouched
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(),
            device_cull_bounds);
  EXPECT_EQ(preroll_context()->state_stack.local_cull_rect(),
            local_cull_bounds);
  EXPECT_TRUE(preroll_context()->state_stack.is_empty());

  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), clip_layer_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_EQ(mock_layer->parent_cull_rect(), clip_cull_rect);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(clip_path)}));

  EXPECT_FALSE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(mock_layer->needs_painting(paint_context()));
  // Top level layer not visible so calling layer->Paint()
  // would trip an FML_DCHECK
}

TEST_F(ClipPathLayerTest, FullyContainedChild) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path =
      SkPath().addRect(child_bounds).addOval(child_bounds.makeInset(0.1, 0.1));
  const SkPath layer_path =
      SkPath().addRect(layer_bounds).addOval(layer_bounds.makeInset(0.1, 0.1));
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, Clip::hardEdge);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_matrix);
  layer->Preroll(preroll_context());

  // Untouched
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(), kGiantRect);
  EXPECT_TRUE(preroll_context()->state_stack.is_empty());

  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), layer_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_path)}));

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ClipPath)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.ClipPath(layer_path);
      /* mock_layer::Paint */ {
        expected_builder.DrawPath(child_path, child_paint);
      }
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ClipPathLayerTest, PartiallyContainedChild) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect local_cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 4.0, 5.5);
  const SkRect device_cull_bounds = initial_matrix.mapRect(local_cull_bounds);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect clip_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path =
      SkPath().addRect(child_bounds).addOval(child_bounds.makeInset(0.1, 0.1));
  const SkPath clip_path =
      SkPath().addRect(clip_bounds).addOval(clip_bounds.makeInset(0.1, 0.1));
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipPathLayer>(clip_path, Clip::hardEdge);
  layer->Add(mock_layer);

  SkRect clip_cull_rect = local_cull_bounds;
  ASSERT_TRUE(clip_cull_rect.intersect(clip_bounds));
  SkRect clip_layer_bounds = child_bounds;
  ASSERT_TRUE(clip_layer_bounds.intersect(clip_bounds));

  // Cull child
  preroll_context()->state_stack.set_preroll_delegate(device_cull_bounds,
                                                      initial_matrix);
  layer->Preroll(preroll_context());

  // Untouched
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(),
            device_cull_bounds);
  EXPECT_EQ(preroll_context()->state_stack.local_cull_rect(),
            local_cull_bounds);
  EXPECT_TRUE(preroll_context()->state_stack.is_empty());

  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), clip_layer_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), clip_cull_rect);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(clip_path)}));

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ClipPath)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.ClipPath(clip_path);
      /* mock_layer::Paint */ {
        expected_builder.DrawPath(child_path, child_paint);
      }
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

static bool ReadbackResult(PrerollContext* context,
                           Clip clip_behavior,
                           const std::shared_ptr<Layer>& child,
                           bool before) {
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, clip_behavior);
  if (child != nullptr) {
    layer->Add(child);
  }
  context->surface_needs_readback = before;
  layer->Preroll(context);
  return context->surface_needs_readback;
}

TEST_F(ClipPathLayerTest, Readback) {
  PrerollContext* context = preroll_context();
  SkPath path;
  DlPaint paint;

  const Clip hard = Clip::hardEdge;
  const Clip soft = Clip::antiAlias;
  const Clip save_layer = Clip::antiAliasWithSaveLayer;

  std::shared_ptr<MockLayer> nochild;
  auto reader = std::make_shared<MockLayer>(path, paint);
  reader->set_fake_reads_surface(true);
  auto nonreader = std::make_shared<MockLayer>(path, paint);

  // No children, no prior readback -> no readback after
  EXPECT_FALSE(ReadbackResult(context, hard, nochild, false));
  EXPECT_FALSE(ReadbackResult(context, soft, nochild, false));
  EXPECT_FALSE(ReadbackResult(context, save_layer, nochild, false));

  // No children, prior readback -> readback after
  EXPECT_TRUE(ReadbackResult(context, hard, nochild, true));
  EXPECT_TRUE(ReadbackResult(context, soft, nochild, true));
  EXPECT_TRUE(ReadbackResult(context, save_layer, nochild, true));

  // Non readback child, no prior readback -> no readback after
  EXPECT_FALSE(ReadbackResult(context, hard, nonreader, false));
  EXPECT_FALSE(ReadbackResult(context, soft, nonreader, false));
  EXPECT_FALSE(ReadbackResult(context, save_layer, nonreader, false));

  // Non readback child, prior readback -> readback after
  EXPECT_TRUE(ReadbackResult(context, hard, nonreader, true));
  EXPECT_TRUE(ReadbackResult(context, soft, nonreader, true));
  EXPECT_TRUE(ReadbackResult(context, save_layer, nonreader, true));

  // Readback child, no prior readback -> readback after unless SaveLayer
  EXPECT_TRUE(ReadbackResult(context, hard, reader, false));
  EXPECT_TRUE(ReadbackResult(context, soft, reader, false));
  EXPECT_FALSE(ReadbackResult(context, save_layer, reader, false));

  // Readback child, prior readback -> readback after
  EXPECT_TRUE(ReadbackResult(context, hard, reader, true));
  EXPECT_TRUE(ReadbackResult(context, soft, reader, true));
  EXPECT_TRUE(ReadbackResult(context, save_layer, reader, true));
}

TEST_F(ClipPathLayerTest, OpacityInheritance) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  auto layer_clip = SkPath()
                        .addRect(SkRect::MakeLTRB(5, 5, 25, 25))
                        .addOval(SkRect::MakeLTRB(20, 20, 40, 50));
  auto clip_path_layer =
      std::make_shared<ClipPathLayer>(layer_clip, Clip::hardEdge);
  clip_path_layer->Add(mock1);

  // ClipRectLayer will pass through compatibility from a compatible child
  PrerollContext* context = preroll_context();
  clip_path_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);

  auto path2 = SkPath().addRect({40, 40, 50, 50});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  clip_path_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  clip_path_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);

  auto path3 = SkPath().addRect({20, 20, 40, 40});
  auto mock3 = MockLayer::MakeOpacityCompatible(path3);
  clip_path_layer->Add(mock3);

  // ClipRectLayer will not pass through compatibility from multiple
  // overlapping children even if they are individually compatible
  clip_path_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags, 0);

  {
    // ClipRectLayer(aa with saveLayer) will always be compatible
    auto clip_path_savelayer = std::make_shared<ClipPathLayer>(
        layer_clip, Clip::antiAliasWithSaveLayer);
    clip_path_savelayer->Add(mock1);
    clip_path_savelayer->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    clip_path_savelayer->Preroll(context);
    EXPECT_EQ(context->renderable_state_flags, Layer::kSaveLayerRenderFlags);

    // Now add the overlapping child and test again, should still be compatible
    clip_path_savelayer->Add(mock3);
    clip_path_savelayer->Preroll(context);
    EXPECT_EQ(context->renderable_state_flags, Layer::kSaveLayerRenderFlags);
  }

  // An incompatible, but non-overlapping child for the following tests
  auto path4 = SkPath().addRect({60, 60, 70, 70});
  auto mock4 = MockLayer::Make(path4);

  {
    // ClipRectLayer with incompatible child will not be compatible
    auto clip_path_bad_child =
        std::make_shared<ClipPathLayer>(layer_clip, Clip::hardEdge);
    clip_path_bad_child->Add(mock1);
    clip_path_bad_child->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    clip_path_bad_child->Preroll(context);
    EXPECT_EQ(context->renderable_state_flags,
              LayerStateStack::kCallerCanApplyOpacity);

    clip_path_bad_child->Add(mock4);

    // The third child is non-overlapping, but not compatible so the
    // TransformLayer should end up incompatible
    clip_path_bad_child->Preroll(context);
    EXPECT_EQ(context->renderable_state_flags, 0);
  }

  {
    // ClipRectLayer(aa with saveLayer) will always be compatible
    auto clip_path_savelayer_bad_child = std::make_shared<ClipPathLayer>(
        layer_clip, Clip::antiAliasWithSaveLayer);
    clip_path_savelayer_bad_child->Add(mock1);
    clip_path_savelayer_bad_child->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    clip_path_savelayer_bad_child->Preroll(context);
    EXPECT_EQ(context->renderable_state_flags, Layer::kSaveLayerRenderFlags);

    // Now add the incompatible child and test again, should still be compatible
    clip_path_savelayer_bad_child->Add(mock4);
    clip_path_savelayer_bad_child->Preroll(context);
    EXPECT_EQ(context->renderable_state_flags, Layer::kSaveLayerRenderFlags);
  }
}

TEST_F(ClipPathLayerTest, OpacityInheritancePainting) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  auto path2 = SkPath().addRect({40, 40, 50, 50});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  auto layer_clip = SkPath()
                        .addRect(SkRect::MakeLTRB(5, 5, 25, 25))
                        .addOval(SkRect::MakeLTRB(45, 45, 55, 55));
  auto clip_path_layer =
      std::make_shared<ClipPathLayer>(layer_clip, Clip::antiAlias);
  clip_path_layer->Add(mock1);
  clip_path_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  PrerollContext* context = preroll_context();
  clip_path_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(clip_path_layer);
  opacity_layer->Preroll(context);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder expected_builder;
  /* OpacityLayer::Paint() */ {
    expected_builder.Save();
    {
      expected_builder.Translate(offset.fX, offset.fY);
      /* ClipRectLayer::Paint() */ {
        expected_builder.Save();
        expected_builder.ClipPath(layer_clip, ClipOp::kIntersect, true);
        /* child layer1 paint */ {
          expected_builder.DrawPath(path1, DlPaint().setAlpha(opacity_alpha));
        }
        /* child layer2 paint */ {
          expected_builder.DrawPath(path2, DlPaint().setAlpha(opacity_alpha));
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ClipPathLayerTest, OpacityInheritanceSaveLayerPainting) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  auto path2 = SkPath().addRect({20, 20, 40, 40});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  auto children_bounds = path1.getBounds();
  children_bounds.join(path2.getBounds());
  auto layer_clip = SkPath()
                        .addRect(SkRect::MakeLTRB(5, 5, 25, 25))
                        .addOval(SkRect::MakeLTRB(20, 20, 40, 50));
  auto clip_path_layer =
      std::make_shared<ClipPathLayer>(layer_clip, Clip::antiAliasWithSaveLayer);
  clip_path_layer->Add(mock1);
  clip_path_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  PrerollContext* context = preroll_context();
  clip_path_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags, Layer::kSaveLayerRenderFlags);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(clip_path_layer);
  opacity_layer->Preroll(context);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder expected_builder;
  /* OpacityLayer::Paint() */ {
    expected_builder.Save();
    {
      expected_builder.Translate(offset.fX, offset.fY);
      /* ClipRectLayer::Paint() */ {
        expected_builder.Save();
        expected_builder.ClipPath(layer_clip, ClipOp::kIntersect, true);
        expected_builder.SaveLayer(&children_bounds,
                                   &DlPaint().setAlpha(opacity_alpha));
        /* child layer1 paint */ {
          expected_builder.DrawPath(path1, DlPaint());
        }
        /* child layer2 paint */ {  //
          expected_builder.DrawPath(path2, DlPaint());
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(expected_builder.Build(), display_list()));
}

TEST_F(ClipPathLayerTest, LayerCached) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  auto layer_clip = SkPath()
                        .addRect(SkRect::MakeLTRB(5, 5, 25, 25))
                        .addOval(SkRect::MakeLTRB(20, 20, 40, 50));
  auto layer =
      std::make_shared<ClipPathLayer>(layer_clip, Clip::antiAliasWithSaveLayer);
  layer->Add(mock1);

  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  SkMatrix cache_ctm = initial_transform;
  DisplayListBuilder cache_canvas;
  cache_canvas.Transform(cache_ctm);

  use_mock_raster_cache();
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);

  const auto* clip_cache_item = layer->raster_cache_item();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);

  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(clip_cache_item->cache_state(), RasterCacheItem::CacheState::kNone);

  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(clip_cache_item->cache_state(), RasterCacheItem::CacheState::kNone);

  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);
  EXPECT_EQ(clip_cache_item->cache_state(),
            RasterCacheItem::CacheState::kCurrent);
  DlPaint paint;
  EXPECT_TRUE(raster_cache()->Draw(clip_cache_item->GetId().value(),
                                   cache_canvas, &paint));
}

TEST_F(ClipPathLayerTest, EmptyClipDoesNotCullPlatformView) {
  const SkPoint view_offset = SkPoint::Make(0.0f, 0.0f);
  const SkSize view_size = SkSize::Make(8.0f, 8.0f);
  const int64_t view_id = 42;
  auto platform_view =
      std::make_shared<PlatformViewLayer>(view_offset, view_size, view_id);

  auto layer_clip = SkPath().addRect(kEmptyRect);
  auto clip =
      std::make_shared<ClipPathLayer>(layer_clip, Clip::antiAliasWithSaveLayer);
  clip->Add(platform_view);

  auto embedder = MockViewEmbedder();
  DisplayListBuilder fake_overlay_builder;
  embedder.AddCanvas(&fake_overlay_builder);
  preroll_context()->view_embedder = &embedder;
  paint_context().view_embedder = &embedder;

  clip->Preroll(preroll_context());
  EXPECT_EQ(embedder.prerolled_views(), std::vector<int64_t>({view_id}));

  clip->Paint(paint_context());
  EXPECT_EQ(embedder.painted_views(), std::vector<int64_t>({view_id}));
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(bugprone-unchecked-optional-access)

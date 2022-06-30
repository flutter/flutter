// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_rrect_layer.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/opacity_layer.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

using ClipRRectLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(ClipRRectLayerTest, ClipNoneBehaviorDies) {
  const SkRRect layer_rrect = SkRRect::MakeEmpty();
  EXPECT_DEATH_IF_SUPPORTED(
      auto clip = std::make_shared<ClipRRectLayer>(layer_rrect, Clip::none),
      "clip_behavior != Clip::none");
}

TEST_F(ClipRRectLayerTest, PaintingEmptyLayerDies) {
  const SkRRect layer_rrect = SkRRect::MakeEmpty();
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect, Clip::hardEdge);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(preroll_context()->cull_rect, kGiantRect);        // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->child_paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ClipRRectLayerTest, PaintBeforePrerollDies) {
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect, Clip::hardEdge);
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->child_paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ClipRRectLayerTest, PaintingCulledLayerDies) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkRect distant_bounds = SkRect::MakeXYWH(100.0, 100.0, 10.0, 10.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect, Clip::hardEdge);
  layer->Add(mock_layer);

  preroll_context()->cull_rect = distant_bounds;  // Cull these children

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, distant_bounds);    // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), kEmptyRect);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_rrect)}));

  paint_context().internal_nodes_canvas->clipRect(distant_bounds, false);
  EXPECT_FALSE(mock_layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_painting(paint_context()));
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(ClipRRectLayerTest, ChildOutsideBounds) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 2.0, 4.0);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect, Clip::hardEdge);
  layer->Add(mock_layer);

  SkRect intersect_bounds = layer_bounds;
  SkRect child_intersect_bounds = layer_bounds;
  intersect_bounds.intersect(cull_bounds);
  child_intersect_bounds.intersect(child_bounds);
  preroll_context()->cull_rect = cull_bounds;  // Cull child

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, cull_bounds);       // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), child_intersect_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), intersect_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_rrect)}));

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kHard_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(ClipRRectLayerTest, FullyContainedChild) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect, Clip::hardEdge);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, kGiantRect);        // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), layer_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_rrect)}));

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kHard_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(ClipRRectLayerTest, PartiallyContainedChild) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 4.0, 5.5);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect, Clip::hardEdge);
  layer->Add(mock_layer);

  SkRect intersect_bounds = layer_bounds;
  SkRect child_intersect_bounds = layer_bounds;
  intersect_bounds.intersect(cull_bounds);
  child_intersect_bounds.intersect(child_bounds);
  preroll_context()->cull_rect = cull_bounds;  // Cull child

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, cull_bounds);       // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), child_intersect_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), intersect_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_rrect)}));

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kHard_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

static bool ReadbackResult(PrerollContext* context,
                           Clip clip_behavior,
                           std::shared_ptr<Layer> child,
                           bool before) {
  const SkMatrix initial_matrix = SkMatrix();
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect, clip_behavior);
  if (child != nullptr) {
    layer->Add(child);
  }
  context->surface_needs_readback = before;
  layer->Preroll(context, initial_matrix);
  return context->surface_needs_readback;
}

TEST_F(ClipRRectLayerTest, Readback) {
  PrerollContext* context = preroll_context();
  SkPath path;
  SkPaint paint;

  const Clip hard = Clip::hardEdge;
  const Clip soft = Clip::antiAlias;
  const Clip save_layer = Clip::antiAliasWithSaveLayer;

  std::shared_ptr<MockLayer> nochild;
  auto reader = std::make_shared<MockLayer>(path, paint, false, true);
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

TEST_F(ClipRRectLayerTest, OpacityInheritance) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  SkRect clip_rect = SkRect::MakeWH(500, 500);
  SkRRect clip_r_rect = SkRRect::MakeRectXY(clip_rect, 20, 20);
  auto clip_r_rect_layer =
      std::make_shared<ClipRRectLayer>(clip_r_rect, Clip::hardEdge);
  clip_r_rect_layer->Add(mock1);

  // ClipRectLayer will pass through compatibility from a compatible child
  PrerollContext* context = preroll_context();
  context->subtree_can_inherit_opacity = false;
  clip_r_rect_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  auto path2 = SkPath().addRect({40, 40, 50, 50});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  clip_r_rect_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  context->subtree_can_inherit_opacity = false;
  clip_r_rect_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  auto path3 = SkPath().addRect({20, 20, 40, 40});
  auto mock3 = MockLayer::MakeOpacityCompatible(path3);
  clip_r_rect_layer->Add(mock3);

  // ClipRectLayer will not pass through compatibility from multiple
  // overlapping children even if they are individually compatible
  context->subtree_can_inherit_opacity = false;
  clip_r_rect_layer->Preroll(context, SkMatrix::I());
  EXPECT_FALSE(context->subtree_can_inherit_opacity);

  {
    // ClipRectLayer(aa with saveLayer) will always be compatible
    auto clip_r_rect_saveLayer = std::make_shared<ClipRRectLayer>(
        clip_r_rect, Clip::antiAliasWithSaveLayer);
    clip_r_rect_saveLayer->Add(mock1);
    clip_r_rect_saveLayer->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    context->subtree_can_inherit_opacity = false;
    clip_r_rect_saveLayer->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);

    // Now add the overlapping child and test again, should still be compatible
    clip_r_rect_saveLayer->Add(mock3);
    context->subtree_can_inherit_opacity = false;
    clip_r_rect_saveLayer->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);
  }

  // An incompatible, but non-overlapping child for the following tests
  auto path4 = SkPath().addRect({60, 60, 70, 70});
  auto mock4 = MockLayer::Make(path4);

  {
    // ClipRectLayer with incompatible child will not be compatible
    auto clip_r_rect_bad_child =
        std::make_shared<ClipRRectLayer>(clip_r_rect, Clip::hardEdge);
    clip_r_rect_bad_child->Add(mock1);
    clip_r_rect_bad_child->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    context->subtree_can_inherit_opacity = false;
    clip_r_rect_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);

    clip_r_rect_bad_child->Add(mock4);

    // The third child is non-overlapping, but not compatible so the
    // TransformLayer should end up incompatible
    context->subtree_can_inherit_opacity = false;
    clip_r_rect_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_FALSE(context->subtree_can_inherit_opacity);
  }

  {
    // ClipRectLayer(aa with saveLayer) will always be compatible
    auto clip_r_rect_saveLayer_bad_child = std::make_shared<ClipRRectLayer>(
        clip_r_rect, Clip::antiAliasWithSaveLayer);
    clip_r_rect_saveLayer_bad_child->Add(mock1);
    clip_r_rect_saveLayer_bad_child->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    context->subtree_can_inherit_opacity = false;
    clip_r_rect_saveLayer_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);

    // Now add the incompatible child and test again, should still be compatible
    clip_r_rect_saveLayer_bad_child->Add(mock4);
    context->subtree_can_inherit_opacity = false;
    clip_r_rect_saveLayer_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);
  }
}

TEST_F(ClipRRectLayerTest, OpacityInheritancePainting) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  auto path2 = SkPath().addRect({40, 40, 50, 50});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  SkRect clip_rect = SkRect::MakeWH(500, 500);
  SkRRect clip_r_rect = SkRRect::MakeRectXY(clip_rect, 20, 20);
  auto clip_rect_layer =
      std::make_shared<ClipRRectLayer>(clip_r_rect, Clip::antiAlias);
  clip_rect_layer->Add(mock1);
  clip_rect_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  PrerollContext* context = preroll_context();
  context->subtree_can_inherit_opacity = false;
  clip_rect_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(clip_rect_layer);
  context->subtree_can_inherit_opacity = false;
  opacity_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder expected_builder;
  /* OpacityLayer::Paint() */ {
    expected_builder.save();
    {
      expected_builder.translate(offset.fX, offset.fY);
      /* ClipRectLayer::Paint() */ {
        expected_builder.save();
        expected_builder.clipRRect(clip_r_rect, SkClipOp::kIntersect, true);
        /* child layer1 paint */ {
          expected_builder.setColor(opacity_alpha << 24);
          expected_builder.saveLayer(&path1.getBounds(), true);
          {
            expected_builder.setColor(0xFF000000);
            expected_builder.drawPath(path1);
          }
          expected_builder.restore();
        }
        /* child layer2 paint */ {
          expected_builder.setColor(opacity_alpha << 24);
          expected_builder.saveLayer(&path2.getBounds(), true);
          {
            expected_builder.setColor(0xFF000000);
            expected_builder.drawPath(path2);
          }
          expected_builder.restore();
        }
        expected_builder.restore();
      }
    }
    expected_builder.restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(expected_builder.Build(), display_list()));
}

TEST_F(ClipRRectLayerTest, OpacityInheritanceSaveLayerPainting) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  auto path2 = SkPath().addRect({20, 20, 40, 40});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  auto children_bounds = path1.getBounds();
  children_bounds.join(path2.getBounds());
  SkRect clip_rect = SkRect::MakeWH(500, 500);
  SkRRect clip_r_rect = SkRRect::MakeRectXY(clip_rect, 20, 20);
  auto clip_r_rect_layer = std::make_shared<ClipRRectLayer>(
      clip_r_rect, Clip::antiAliasWithSaveLayer);
  clip_r_rect_layer->Add(mock1);
  clip_r_rect_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  PrerollContext* context = preroll_context();
  context->subtree_can_inherit_opacity = false;
  clip_r_rect_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(clip_r_rect_layer);
  context->subtree_can_inherit_opacity = false;
  opacity_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder expected_builder;
  /* OpacityLayer::Paint() */ {
    expected_builder.save();
    {
      expected_builder.translate(offset.fX, offset.fY);
      /* ClipRectLayer::Paint() */ {
        expected_builder.save();
        expected_builder.clipRRect(clip_r_rect, SkClipOp::kIntersect, true);
        expected_builder.setColor(opacity_alpha << 24);
        expected_builder.saveLayer(&children_bounds, true);
        /* child layer1 paint */ {
          expected_builder.setColor(0xFF000000);
          expected_builder.drawPath(path1);
        }
        /* child layer2 paint */ {  //
          expected_builder.drawPath(path2);
        }
        expected_builder.restore();
      }
    }
    expected_builder.restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(expected_builder.Build(), display_list()));
}

TEST_F(ClipRRectLayerTest, LayerCached) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  SkPaint paint = SkPaint();
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  SkRect clip_rect = SkRect::MakeWH(500, 500);
  SkRRect clip_r_rect = SkRRect::MakeRectXY(clip_rect, 20, 20);
  auto layer = std::make_shared<ClipRRectLayer>(clip_r_rect,
                                                Clip::antiAliasWithSaveLayer);
  layer->Add(mock1);

  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  SkMatrix cache_ctm = initial_transform;
  SkCanvas cache_canvas;
  cache_canvas.setMatrix(cache_ctm);

  use_mock_raster_cache();

  const auto* clip_cache_item = layer->raster_cache_item();

  layer->Preroll(preroll_context(), initial_transform);
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(clip_cache_item->cache_state(), RasterCacheItem::CacheState::kNone);

  layer->Preroll(preroll_context(), initial_transform);
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(clip_cache_item->cache_state(), RasterCacheItem::CacheState::kNone);

  layer->Preroll(preroll_context(), initial_transform);
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);
  EXPECT_EQ(clip_cache_item->cache_state(),
            RasterCacheItem::CacheState::kCurrent);
  EXPECT_TRUE(raster_cache()->Draw(clip_cache_item->GetId().value(),
                                   cache_canvas, &paint));
}

TEST_F(ClipRRectLayerTest, NoSaveLayerShouldNotCache) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});

  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  SkRect clip_rect = SkRect::MakeWH(500, 500);
  SkRRect clip_r_rect = SkRRect::MakeRectXY(clip_rect, 20, 20);
  auto layer = std::make_shared<ClipRRectLayer>(clip_r_rect, Clip::antiAlias);
  layer->Add(mock1);

  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  SkMatrix cache_ctm = initial_transform;
  SkCanvas cache_canvas;
  cache_canvas.setMatrix(cache_ctm);

  use_mock_raster_cache();

  const auto* clip_cache_item = layer->raster_cache_item();

  layer->Preroll(preroll_context(), initial_transform);
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(clip_cache_item->cache_state(), RasterCacheItem::CacheState::kNone);

  layer->Preroll(preroll_context(), initial_transform);
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(clip_cache_item->cache_state(), RasterCacheItem::CacheState::kNone);

  layer->Preroll(preroll_context(), initial_transform);
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(clip_cache_item->cache_state(), RasterCacheItem::CacheState::kNone);
}

}  // namespace testing
}  // namespace flutter

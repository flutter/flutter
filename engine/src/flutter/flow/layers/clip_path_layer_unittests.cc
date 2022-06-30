// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/opacity_layer.h"
#include "flutter/flow/raster_cache_item.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"
#include "gtest/gtest.h"
#include "include/core/SkPaint.h"

namespace flutter {
namespace testing {

using ClipPathLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(ClipPathLayerTest, ClipNoneBehaviorDies) {
  EXPECT_DEATH_IF_SUPPORTED(
      auto clip = std::make_shared<ClipPathLayer>(SkPath(), Clip::none),
      "clip_behavior != Clip::none");
}

TEST_F(ClipPathLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<ClipPathLayer>(SkPath(), Clip::hardEdge);

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(preroll_context()->cull_rect, kGiantRect);        // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
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
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_path)}));

  paint_context().internal_nodes_canvas->clipRect(distant_bounds, false);
  EXPECT_FALSE(mock_layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_painting(paint_context()));
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(ClipPathLayerTest, ChildOutsideBounds) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 2.0, 4.0);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, Clip::hardEdge);
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
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_path)}));

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

TEST_F(ClipPathLayerTest, FullyContainedChild) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, Clip::hardEdge);
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
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_path)}));

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

TEST_F(ClipPathLayerTest, PartiallyContainedChild) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 4.0, 5.5);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, Clip::hardEdge);
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
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_path)}));

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
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, clip_behavior);
  if (child != nullptr) {
    layer->Add(child);
  }
  context->surface_needs_readback = before;
  layer->Preroll(context, initial_matrix);
  return context->surface_needs_readback;
}

TEST_F(ClipPathLayerTest, Readback) {
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
  context->subtree_can_inherit_opacity = false;
  clip_path_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  auto path2 = SkPath().addRect({40, 40, 50, 50});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  clip_path_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  context->subtree_can_inherit_opacity = false;
  clip_path_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  auto path3 = SkPath().addRect({20, 20, 40, 40});
  auto mock3 = MockLayer::MakeOpacityCompatible(path3);
  clip_path_layer->Add(mock3);

  // ClipRectLayer will not pass through compatibility from multiple
  // overlapping children even if they are individually compatible
  context->subtree_can_inherit_opacity = false;
  clip_path_layer->Preroll(context, SkMatrix::I());
  EXPECT_FALSE(context->subtree_can_inherit_opacity);

  {
    // ClipRectLayer(aa with saveLayer) will always be compatible
    auto clip_path_saveLayer = std::make_shared<ClipPathLayer>(
        layer_clip, Clip::antiAliasWithSaveLayer);
    clip_path_saveLayer->Add(mock1);
    clip_path_saveLayer->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    context->subtree_can_inherit_opacity = false;
    clip_path_saveLayer->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);

    // Now add the overlapping child and test again, should still be compatible
    clip_path_saveLayer->Add(mock3);
    context->subtree_can_inherit_opacity = false;
    clip_path_saveLayer->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);
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
    context->subtree_can_inherit_opacity = false;
    clip_path_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);

    clip_path_bad_child->Add(mock4);

    // The third child is non-overlapping, but not compatible so the
    // TransformLayer should end up incompatible
    context->subtree_can_inherit_opacity = false;
    clip_path_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_FALSE(context->subtree_can_inherit_opacity);
  }

  {
    // ClipRectLayer(aa with saveLayer) will always be compatible
    auto clip_path_saveLayer_bad_child = std::make_shared<ClipPathLayer>(
        layer_clip, Clip::antiAliasWithSaveLayer);
    clip_path_saveLayer_bad_child->Add(mock1);
    clip_path_saveLayer_bad_child->Add(mock2);

    // Double check first two children are compatible and non-overlapping
    context->subtree_can_inherit_opacity = false;
    clip_path_saveLayer_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);

    // Now add the incompatible child and test again, should still be compatible
    clip_path_saveLayer_bad_child->Add(mock4);
    context->subtree_can_inherit_opacity = false;
    clip_path_saveLayer_bad_child->Preroll(context, SkMatrix::I());
    EXPECT_TRUE(context->subtree_can_inherit_opacity);
  }
}

TEST_F(ClipPathLayerTest, OpacityInheritancePainting) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  auto mock1 = MockLayer::MakeOpacityCompatible(path1);
  auto path2 = SkPath().addRect({40, 40, 50, 50});
  auto mock2 = MockLayer::MakeOpacityCompatible(path2);
  auto layer_clip = SkPath()
                        .addRect(SkRect::MakeLTRB(5, 5, 25, 25))
                        .addOval(SkRect::MakeLTRB(20, 20, 40, 50));
  auto clip_path_layer =
      std::make_shared<ClipPathLayer>(layer_clip, Clip::antiAlias);
  clip_path_layer->Add(mock1);
  clip_path_layer->Add(mock2);

  // ClipRectLayer will pass through compatibility from multiple
  // non-overlapping compatible children
  PrerollContext* context = preroll_context();
  context->subtree_can_inherit_opacity = false;
  clip_path_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(clip_path_layer);
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
        expected_builder.clipPath(layer_clip, SkClipOp::kIntersect, true);
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
  context->subtree_can_inherit_opacity = false;
  clip_path_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(clip_path_layer);
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
        expected_builder.clipPath(layer_clip, SkClipOp::kIntersect, true);
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
  SkCanvas cache_canvas;
  cache_canvas.setMatrix(cache_ctm);

  use_mock_raster_cache();

  const auto* clip_cache_item = layer->raster_cache_item();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);

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
  SkPaint paint;
  EXPECT_TRUE(raster_cache()->Draw(clip_cache_item->GetId().value(),
                                   cache_canvas, &paint));
}

}  // namespace testing
}  // namespace flutter

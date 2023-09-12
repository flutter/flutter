// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/opacity_layer.h"

#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/layers/image_filter_layer.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/platform_view_layer.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/flow/raster_cache_util.h"
#include "flutter/flow/testing/diff_context_test.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_embedder.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/display_list_testing.h"
#include "gtest/gtest.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace flutter {
namespace testing {

using OpacityLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(OpacityLayerTest, LeafLayer) {
  auto layer =
      std::make_shared<OpacityLayer>(SK_AlphaOPAQUE, SkPoint::Make(0.0f, 0.0f));

  EXPECT_DEATH_IF_SUPPORTED(layer->Preroll(preroll_context()),
                            "\\!layers\\(\\)\\.empty\\(\\)");
}

TEST_F(OpacityLayerTest, PaintingEmptyLayerDies) {
  auto mock_layer = std::make_shared<MockLayer>(SkPath());
  auto layer =
      std::make_shared<OpacityLayer>(SK_AlphaOPAQUE, SkPoint::Make(0.0f, 0.0f));
  layer->Add(mock_layer);

  layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer->paint_bounds(), SkPath().getBounds());
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
  EXPECT_EQ(layer->child_paint_bounds(), mock_layer->paint_bounds());
  EXPECT_FALSE(mock_layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(OpacityLayerTest, PaintBeforePrerollDies) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer =
      std::make_shared<OpacityLayer>(SK_AlphaOPAQUE, SkPoint::Make(0.0f, 0.0f));
  layer->Add(mock_layer);

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(OpacityLayerTest, TranslateChildren) {
  SkPath child_path1;
  child_path1.addRect(10.0f, 10.0f, 20.0f, 20.f);
  DlPaint child_paint1 = DlPaint(DlColor::kMidGrey());
  auto layer = std::make_shared<OpacityLayer>(0.5, SkPoint::Make(10, 10));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  layer->Add(mock_layer1);

  auto initial_transform = SkMatrix::Scale(2.0, 2.0);
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());

  SkRect layer_bounds = mock_layer1->paint_bounds();
  mock_layer1->parent_matrix().mapRect(&layer_bounds);

  EXPECT_EQ(layer_bounds, SkRect::MakeXYWH(40, 40, 20, 20));
}

TEST_F(OpacityLayerTest, CacheChild) {
  const SkAlpha alpha_half = 255 / 2;
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer =
      std::make_shared<OpacityLayer>(alpha_half, SkPoint::Make(0.0f, 0.0f));
  layer->Add(mock_layer);
  DlPaint paint;

  SkMatrix cache_ctm = initial_transform;
  DisplayListBuilder cache_canvas;
  cache_canvas.Transform(cache_ctm);
  DisplayListBuilder other_canvas;
  other_canvas.Transform(other_transform);

  use_mock_raster_cache();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);

  const auto* cacheable_opacity_item = layer->raster_cache_item();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(cacheable_opacity_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_opacity_item->GetId().has_value());

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);

  EXPECT_EQ(cacheable_opacity_item->cache_state(),
            RasterCacheItem::CacheState::kChildren);
  EXPECT_EQ(
      cacheable_opacity_item->GetId().value(),
      RasterCacheKeyID(RasterCacheKeyID::LayerChildrenIds(layer.get()).value(),
                       RasterCacheKeyType::kLayerChildren));
  EXPECT_FALSE(raster_cache()->Draw(cacheable_opacity_item->GetId().value(),
                                    other_canvas, &paint));
  EXPECT_TRUE(raster_cache()->Draw(cacheable_opacity_item->GetId().value(),
                                   cache_canvas, &paint));
}

TEST_F(OpacityLayerTest, CacheChildren) {
  const SkAlpha alpha_half = 255 / 2;
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  const SkPath child_path1 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  const SkPath child_path2 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  DlPaint paint;
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2);
  auto layer =
      std::make_shared<OpacityLayer>(alpha_half, SkPoint::Make(0.0f, 0.0f));
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkMatrix cache_ctm = initial_transform;
  DisplayListBuilder cache_canvas;
  cache_canvas.Transform(cache_ctm);
  DisplayListBuilder other_canvas;
  other_canvas.Transform(other_transform);

  use_mock_raster_cache();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);

  const auto* cacheable_opacity_item = layer->raster_cache_item();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(cacheable_opacity_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_opacity_item->GetId().has_value());

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);

  EXPECT_EQ(cacheable_opacity_item->cache_state(),
            RasterCacheItem::CacheState::kChildren);
  EXPECT_EQ(
      cacheable_opacity_item->GetId().value(),
      RasterCacheKeyID(RasterCacheKeyID::LayerChildrenIds(layer.get()).value(),
                       RasterCacheKeyType::kLayerChildren));
  EXPECT_FALSE(raster_cache()->Draw(cacheable_opacity_item->GetId().value(),
                                    other_canvas, &paint));
  EXPECT_TRUE(raster_cache()->Draw(cacheable_opacity_item->GetId().value(),
                                   cache_canvas, &paint));
}

TEST_F(OpacityLayerTest, ShouldNotCacheChildren) {
  DlPaint paint;
  auto opacity_layer =
      std::make_shared<OpacityLayer>(128, SkPoint::Make(20, 20));
  auto mock_layer = MockLayer::MakeOpacityCompatible(SkPath());
  opacity_layer->Add(mock_layer);

  PrerollContext* context = preroll_context();

  use_mock_raster_cache();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);

  const auto* cacheable_opacity_item = opacity_layer->raster_cache_item();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(cacheable_opacity_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_opacity_item->GetId().has_value());

  opacity_layer->Preroll(preroll_context());

  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(cacheable_opacity_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_opacity_item->Draw(paint_context(), &paint));
}

TEST_F(OpacityLayerTest, FullyOpaque) {
  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  const SkPoint layer_offset = SkPoint::Make(0.5f, 1.5f);
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 0.5f);
  const SkMatrix layer_transform =
      SkMatrix::Translate(layer_offset.fX, layer_offset.fY);
  const DlPaint child_paint = DlPaint(DlColor::kGreen());
  const SkRect expected_layer_bounds =
      layer_transform.mapRect(child_path.getBounds());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<OpacityLayer>(SK_AlphaOPAQUE, layer_offset);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer->paint_bounds(), child_path.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_layer_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_path.getBounds());
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(),
            SkMatrix::Concat(initial_transform, layer_transform));
  EXPECT_EQ(mock_layer->parent_mutators(),
            std::vector({Mutator(layer_transform)}));

  DisplayListBuilder expected_builder;
  /* (Opacity)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.Translate(layer_offset.fX, layer_offset.fY);
      // Opaque alpha needs no SaveLayer, just recurse into painting mock_layer
      /* mock_layer::Paint */ {
        expected_builder.DrawPath(child_path, child_paint);
      }
    }
    expected_builder.Restore();
  }
  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(OpacityLayerTest, FullyTransparent) {
  const SkRect child_bounds = SkRect::MakeWH(5.0f, 5.0f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPoint layer_offset = SkPoint::Make(0.5f, 1.5f);
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 0.5f);
  const SkMatrix layer_transform =
      SkMatrix::Translate(layer_offset.fX, layer_offset.fY);
  const DlPaint child_paint = DlPaint(DlColor::kGreen());
  const SkRect expected_layer_bounds =
      layer_transform.mapRect(child_path.getBounds());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer =
      std::make_shared<OpacityLayer>(SK_AlphaTRANSPARENT, layer_offset);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer->paint_bounds(), child_path.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_layer_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_path.getBounds());
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(),
            SkMatrix::Concat(initial_transform, layer_transform));
  EXPECT_EQ(
      mock_layer->parent_mutators(),
      std::vector({Mutator(layer_transform), Mutator(SK_AlphaTRANSPARENT)}));

  DisplayListBuilder expected_builder;
  /* (Opacity)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.Translate(layer_offset.fX, layer_offset.fY);
      /* (Opacity)layer::PaintChildren */ {
        DlPaint save_paint(DlPaint().setOpacity(layer->opacity()));
        expected_builder.SaveLayer(&child_bounds, &save_paint);
        /* mock_layer::Paint */ {
          expected_builder.DrawPath(child_path, child_paint);
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }
  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(OpacityLayerTest, HalfTransparent) {
  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  const SkPoint layer_offset = SkPoint::Make(0.5f, 1.5f);
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 0.5f);
  const SkMatrix layer_transform =
      SkMatrix::Translate(layer_offset.fX, layer_offset.fY);
  const DlPaint child_paint = DlPaint(DlColor::kGreen());
  const SkRect expected_layer_bounds =
      layer_transform.mapRect(child_path.getBounds());
  const SkAlpha alpha_half = 255 / 2;
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<OpacityLayer>(alpha_half, layer_offset);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer->paint_bounds(), child_path.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_layer_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_path.getBounds());
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(),
            SkMatrix::Concat(initial_transform, layer_transform));
  EXPECT_EQ(mock_layer->parent_mutators(),
            std::vector({Mutator(layer_transform), Mutator(alpha_half)}));

  SkRect opacity_bounds;
  expected_layer_bounds.makeOffset(-layer_offset.fX, -layer_offset.fY)
      .roundOut(&opacity_bounds);
  DlPaint save_paint = DlPaint().setAlpha(alpha_half);
  DlPaint child_dl_paint = DlPaint(DlColor::kGreen());

  auto expected_builder = DisplayListBuilder();
  /* (Opacity)layer::Paint */ {
    expected_builder.Save();
    expected_builder.Translate(layer_offset.fX, layer_offset.fY);
    /* (Opacity)layer::PaintChildren */ {
      expected_builder.SaveLayer(&opacity_bounds, &save_paint);
      /* mock_layer::Paint */ {
        expected_builder.DrawPath(child_path, child_dl_paint);
      }
      expected_builder.Restore();
    }
    expected_builder.Restore();
  }
  sk_sp<DisplayList> expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(OpacityLayerTest, Nested) {
  const SkPath child1_path = SkPath().addRect(SkRect::MakeWH(5.0f, 6.0f));
  const SkPath child2_path = SkPath().addRect(SkRect::MakeWH(2.0f, 7.0f));
  const SkPath child3_path = SkPath().addRect(SkRect::MakeWH(6.0f, 6.0f));
  const SkPoint layer1_offset = SkPoint::Make(0.5f, 1.5f);
  const SkPoint layer2_offset = SkPoint::Make(2.5f, 0.5f);
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 0.5f);
  const SkMatrix layer1_transform =
      SkMatrix::Translate(layer1_offset.fX, layer1_offset.fY);
  const SkMatrix layer2_transform =
      SkMatrix::Translate(layer2_offset.fX, layer2_offset.fY);
  const DlPaint child1_paint = DlPaint(DlColor::kRed());
  const DlPaint child2_paint = DlPaint(DlColor::kBlue());
  const DlPaint child3_paint = DlPaint(DlColor::kGreen());
  const SkAlpha alpha1 = 155;
  const SkAlpha alpha2 = 224;
  auto mock_layer1 = std::make_shared<MockLayer>(child1_path, child1_paint);
  auto mock_layer2 = std::make_shared<MockLayer>(child2_path, child2_paint);
  auto mock_layer3 = std::make_shared<MockLayer>(child3_path, child3_paint);
  auto layer1 = std::make_shared<OpacityLayer>(alpha1, layer1_offset);
  auto layer2 = std::make_shared<OpacityLayer>(alpha2, layer2_offset);
  layer2->Add(mock_layer2);
  layer1->Add(mock_layer1);
  layer1->Add(layer2);
  layer1->Add(mock_layer3);  // Ensure something is processed after recursion

  const SkRect expected_layer2_bounds =
      layer2_transform.mapRect(child2_path.getBounds());
  SkRect layer1_child_bounds = expected_layer2_bounds;
  layer1_child_bounds.join(child1_path.getBounds());
  layer1_child_bounds.join(child3_path.getBounds());
  SkRect expected_layer1_bounds = layer1_transform.mapRect(layer1_child_bounds);
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer1->Preroll(preroll_context());
  EXPECT_EQ(mock_layer1->paint_bounds(), child1_path.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child2_path.getBounds());
  EXPECT_EQ(mock_layer3->paint_bounds(), child3_path.getBounds());
  EXPECT_EQ(layer1->paint_bounds(), expected_layer1_bounds);
  EXPECT_EQ(layer1->child_paint_bounds(), layer1_child_bounds);
  EXPECT_EQ(layer2->paint_bounds(), expected_layer2_bounds);
  EXPECT_EQ(layer2->child_paint_bounds(), child2_path.getBounds());
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer3->needs_painting(paint_context()));
  EXPECT_TRUE(layer1->needs_painting(paint_context()));
  EXPECT_TRUE(layer2->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(),
            SkMatrix::Concat(initial_transform, layer1_transform));
  EXPECT_EQ(mock_layer1->parent_mutators(),
            std::vector({Mutator(layer1_transform), Mutator(alpha1)}));
  EXPECT_EQ(
      mock_layer2->parent_matrix(),
      SkMatrix::Concat(SkMatrix::Concat(initial_transform, layer1_transform),
                       layer2_transform));
  EXPECT_EQ(mock_layer2->parent_mutators(),
            std::vector({Mutator(layer1_transform), Mutator(alpha1),
                         Mutator(layer2_transform), Mutator(alpha2)}));
  EXPECT_EQ(mock_layer3->parent_matrix(),
            SkMatrix::Concat(initial_transform, layer1_transform));
  EXPECT_EQ(mock_layer3->parent_mutators(),
            std::vector({Mutator(layer1_transform), Mutator(alpha1)}));

  SkRect opacity1_bounds =
      expected_layer1_bounds.makeOffset(-layer1_offset.fX, -layer1_offset.fY);
  SkRect opacity2_bounds =
      expected_layer2_bounds.makeOffset(-layer2_offset.fX, -layer2_offset.fY);
  DlPaint opacity1_paint;
  opacity1_paint.setOpacity(alpha1 * (1.0 / SK_AlphaOPAQUE));
  DlPaint opacity2_paint;
  opacity2_paint.setOpacity(alpha2 * (1.0 / SK_AlphaOPAQUE));

  DisplayListBuilder expected_builder;
  /* (Opacity)layer1::Paint */ {
    expected_builder.Save();
    {
      expected_builder.Translate(layer1_offset.fX, layer1_offset.fY);
      /* (Opacity)layer1::PaintChildren */ {
        expected_builder.SaveLayer(&opacity1_bounds, &opacity1_paint);
        /* mock_layer1::Paint */ {
          expected_builder.DrawPath(child1_path, child1_paint);
        }
        /* (Opacity)layer2::Paint */ {
          expected_builder.Save();
          {
            expected_builder.Translate(layer2_offset.fX, layer2_offset.fY);
            /* (Opacity)layer2::PaintChidren */ {
              expected_builder.SaveLayer(&opacity2_bounds, &opacity2_paint);
              {
                /* mock_layer2::Paint */ {
                  expected_builder.DrawPath(child2_path, child2_paint);
                }
              }
              expected_builder.Restore();
            }
          }
          expected_builder.Restore();
        }
        /* mock_layer3::Paint */ {
          expected_builder.DrawPath(child3_path, child3_paint);
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }
  layer1->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(OpacityLayerTest, Readback) {
  auto layer = std::make_shared<OpacityLayer>(kOpaque_SkAlphaType, SkPoint());
  layer->Add(std::make_shared<MockLayer>(SkPath()));

  // OpacityLayer does not read from surface
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context());
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // OpacityLayer blocks child with readback
  auto mock_layer = std::make_shared<MockLayer>(SkPath(), DlPaint());
  mock_layer->set_fake_reads_surface(true);
  layer->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context());
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

TEST_F(OpacityLayerTest, CullRectIsTransformed) {
  auto clip_rect_layer = std::make_shared<ClipRectLayer>(
      SkRect::MakeLTRB(0, 0, 10, 10), flutter::hardEdge);
  auto opacity_layer =
      std::make_shared<OpacityLayer>(128, SkPoint::Make(20, 20));
  auto mock_layer = std::make_shared<MockLayer>(SkPath());
  clip_rect_layer->Add(opacity_layer);
  opacity_layer->Add(mock_layer);
  clip_rect_layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer->parent_cull_rect().fLeft, -20);
  EXPECT_EQ(mock_layer->parent_cull_rect().fTop, -20);
}

TEST_F(OpacityLayerTest, OpacityInheritanceCompatibleChild) {
  auto opacity_layer =
      std::make_shared<OpacityLayer>(128, SkPoint::Make(20, 20));
  auto mock_layer = MockLayer::MakeOpacityCompatible(SkPath());
  opacity_layer->Add(mock_layer);

  PrerollContext* context = preroll_context();
  opacity_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());
}

TEST_F(OpacityLayerTest, OpacityInheritanceIncompatibleChild) {
  auto opacity_layer =
      std::make_shared<OpacityLayer>(128, SkPoint::Make(20, 20));
  auto mock_layer = MockLayer::Make(SkPath());
  opacity_layer->Add(mock_layer);

  PrerollContext* context = preroll_context();
  opacity_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_FALSE(opacity_layer->children_can_accept_opacity());
}

TEST_F(OpacityLayerTest, OpacityInheritanceThroughContainer) {
  auto opacity_layer =
      std::make_shared<OpacityLayer>(128, SkPoint::Make(20, 20));
  auto container_layer = std::make_shared<ContainerLayer>();
  auto mock_layer = MockLayer::MakeOpacityCompatible(SkPath());
  container_layer->Add(mock_layer);
  opacity_layer->Add(container_layer);

  PrerollContext* context = preroll_context();
  opacity_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());
}

TEST_F(OpacityLayerTest, OpacityInheritanceThroughTransform) {
  auto opacity_layer =
      std::make_shared<OpacityLayer>(128, SkPoint::Make(20, 20));
  auto transformLayer = std::make_shared<TransformLayer>(SkMatrix::Scale(2, 2));
  auto mock_layer = MockLayer::MakeOpacityCompatible(SkPath());
  transformLayer->Add(mock_layer);
  opacity_layer->Add(transformLayer);

  PrerollContext* context = preroll_context();
  opacity_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());
}

TEST_F(OpacityLayerTest, OpacityInheritanceThroughImageFilter) {
  auto opacity_layer =
      std::make_shared<OpacityLayer>(128, SkPoint::Make(20, 20));
  auto filter_layer = std::make_shared<ImageFilterLayer>(
      std::make_shared<DlBlurImageFilter>(5.0, 5.0, DlTileMode::kClamp));
  auto mock_layer = MockLayer::MakeOpacityCompatible(SkPath());
  filter_layer->Add(mock_layer);
  opacity_layer->Add(filter_layer);

  PrerollContext* context = preroll_context();
  opacity_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());
}

TEST_F(OpacityLayerTest, OpacityInheritanceNestedWithCompatibleChild) {
  SkPoint offset1 = SkPoint::Make(10, 20);
  SkPoint offset2 = SkPoint::Make(20, 10);
  SkPath mock_path = SkPath::Rect({10, 10, 20, 20});
  auto opacity_layer_1 = std::make_shared<OpacityLayer>(128, offset1);
  auto opacity_layer_2 = std::make_shared<OpacityLayer>(64, offset2);
  auto mock_layer = MockLayer::MakeOpacityCompatible(mock_path);
  opacity_layer_2->Add(mock_layer);
  opacity_layer_1->Add(opacity_layer_2);

  PrerollContext* context = preroll_context();
  opacity_layer_1->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_TRUE(opacity_layer_1->children_can_accept_opacity());
  EXPECT_TRUE(opacity_layer_2->children_can_accept_opacity());

  DlPaint savelayer_paint;
  SkScalar inherited_opacity = 128 * 1.0 / SK_AlphaOPAQUE;
  inherited_opacity *= 64 * 1.0 / SK_AlphaOPAQUE;
  savelayer_paint.setOpacity(inherited_opacity);

  DisplayListBuilder expected_builder;
  /* opacity_layer_1::Paint */ {
    expected_builder.Save();
    {
      expected_builder.Translate(offset1.fX, offset1.fY);
      /* opacity_layer_2::Paint */ {
        expected_builder.Save();
        {
          expected_builder.Translate(offset2.fX, offset2.fY);
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(mock_path,
                                      DlPaint().setOpacity(inherited_opacity));
          }
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }

  opacity_layer_1->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(expected_builder.Build(), display_list()));
}

TEST_F(OpacityLayerTest, OpacityInheritanceNestedWithIncompatibleChild) {
  SkPoint offset1 = SkPoint::Make(10, 20);
  SkPoint offset2 = SkPoint::Make(20, 10);
  SkPath mock_path = SkPath::Rect({10, 10, 20, 20});
  auto opacity_layer_1 = std::make_shared<OpacityLayer>(128, offset1);
  auto opacity_layer_2 = std::make_shared<OpacityLayer>(64, offset2);
  auto mock_layer = MockLayer::Make(mock_path);
  opacity_layer_2->Add(mock_layer);
  opacity_layer_1->Add(opacity_layer_2);

  PrerollContext* context = preroll_context();
  opacity_layer_1->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
  EXPECT_TRUE(opacity_layer_1->children_can_accept_opacity());
  EXPECT_FALSE(opacity_layer_2->children_can_accept_opacity());

  DlPaint savelayer_paint;
  SkScalar inherited_opacity = 128 * 1.0 / SK_AlphaOPAQUE;
  inherited_opacity *= 64 * 1.0 / SK_AlphaOPAQUE;
  savelayer_paint.setOpacity(inherited_opacity);

  DisplayListBuilder expected_builder;
  /* opacity_layer_1::Paint */ {
    expected_builder.Save();
    {
      expected_builder.Translate(offset1.fX, offset1.fY);
      /* opacity_layer_2::Paint */ {
        expected_builder.Save();
        {
          expected_builder.Translate(offset2.fX, offset2.fY);
          expected_builder.SaveLayer(&mock_layer->paint_bounds(),
                                     &savelayer_paint);
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(mock_path, DlPaint());
          }
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }

  opacity_layer_1->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(expected_builder.Build(), display_list()));
}

using OpacityLayerDiffTest = DiffContextTest;

TEST_F(OpacityLayerDiffTest, FractionalTranslation) {
  auto picture = CreateDisplayListLayer(
      CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60)));
  auto layer = CreateOpacityLater({picture}, 128, SkPoint::Make(0.5, 0.5));

  MockLayerTree tree1;
  tree1.root()->Add(layer);

  auto damage = DiffLayerTree(tree1, MockLayerTree(), SkIRect::MakeEmpty(), 0,
                              0, /*use_raster_cache=*/false);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(10, 10, 61, 61));
}

TEST_F(OpacityLayerDiffTest, FractionalTranslationWithRasterCache) {
  auto picture = CreateDisplayListLayer(
      CreateDisplayList(SkRect::MakeLTRB(10, 10, 60, 60)));
  auto layer = CreateOpacityLater({picture}, 128, SkPoint::Make(0.5, 0.5));

  MockLayerTree tree1;
  tree1.root()->Add(layer);

  auto damage = DiffLayerTree(tree1, MockLayerTree(), SkIRect::MakeEmpty(), 0,
                              0, /*use_raster_cache=*/true);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(11, 11, 61, 61));
}

TEST_F(OpacityLayerTest, FullyOpaqueWithFractionalValues) {
  use_mock_raster_cache();  // Ensure pixel-snapped alignment.

  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  const SkPoint layer_offset = SkPoint::Make(0.5f, 1.5f);
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 0.5f);
  const DlPaint child_paint = DlPaint(DlColor::kGreen());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<OpacityLayer>(SK_AlphaOPAQUE, layer_offset);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());

  auto expected_builder = DisplayListBuilder();
  /* (Opacity)layer::Paint */ {
    expected_builder.Save();
    expected_builder.Translate(layer_offset.fX, layer_offset.fY);
    // Opaque alpha needs no SaveLayer, just recurse into painting mock_layer
    // but since we use the mock raster cache we pixel snap the transform
    expected_builder.TransformReset();
    expected_builder.Transform2DAffine(
        1, 0, SkScalarRoundToScalar(layer_offset.fX),  //
        0, 1, SkScalarRoundToScalar(layer_offset.fY));
    /* mock_layer::Paint */ {
      expected_builder.DrawPath(child_path, child_paint);
    }
    expected_builder.Restore();
  }
  sk_sp<DisplayList> expected_display_list = expected_builder.Build();

  layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_display_list));
}

TEST_F(OpacityLayerTest, FullyTransparentDoesNotCullPlatformView) {
  const SkPoint opacity_offset = SkPoint::Make(0.5f, 1.5f);
  const SkPoint view_offset = SkPoint::Make(0.0f, 0.0f);
  const SkSize view_size = SkSize::Make(8.0f, 8.0f);
  const int64_t view_id = 42;
  auto platform_view =
      std::make_shared<PlatformViewLayer>(view_offset, view_size, view_id);

  auto opacity =
      std::make_shared<OpacityLayer>(SK_AlphaTRANSPARENT, opacity_offset);
  opacity->Add(platform_view);

  auto embedder = MockViewEmbedder();
  DisplayListBuilder fake_overlay_builder;
  embedder.AddCanvas(&fake_overlay_builder);
  preroll_context()->view_embedder = &embedder;
  paint_context().view_embedder = &embedder;

  opacity->Preroll(preroll_context());
  EXPECT_EQ(embedder.prerolled_views(), std::vector<int64_t>({view_id}));

  opacity->Paint(paint_context());
  EXPECT_EQ(embedder.painted_views(), std::vector<int64_t>({view_id}));
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(bugprone-unchecked-optional-access)

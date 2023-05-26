// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/shader_mask_layer.h"

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/opacity_layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/raster_cache_util.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "gtest/gtest.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace flutter {
namespace testing {

using ShaderMaskLayerTest = LayerTest;

static std::shared_ptr<DlColorSource> MakeFilter(DlColor color) {
  DlColor colors[] = {
      color.withAlpha(0x7f),
      color,
  };
  float stops[] = {
      0,
      1,
  };
  return DlColorSource::MakeLinear(SkPoint::Make(0, 0), SkPoint::Make(10, 10),
                                   2, colors, stops, DlTileMode::kRepeat);
}

#ifndef NDEBUG
TEST_F(ShaderMaskLayerTest, PaintingEmptyLayerDies) {
  auto layer =
      std::make_shared<ShaderMaskLayer>(nullptr, kEmptyRect, DlBlendMode::kSrc);

  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->child_paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ShaderMaskLayerTest, PaintBeforePrerollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer =
      std::make_shared<ShaderMaskLayer>(nullptr, kEmptyRect, DlBlendMode::kSrc);
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->child_paint_bounds(), kEmptyRect);
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(ShaderMaskLayerTest, EmptyFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 6.5f, 6.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ShaderMaskLayer>(nullptr, layer_bounds,
                                                 DlBlendMode::kSrc);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  DlPaint filter_paint;
  filter_paint.setBlendMode(DlBlendMode::kSrc);
  filter_paint.setColorSource(nullptr);

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ShaderMask)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.SaveLayer(&child_bounds);
      {
        /* mock_layer::Paint */ {
          expected_builder.DrawPath(child_path, child_paint);
        }
        expected_builder.Translate(layer_bounds.fLeft, layer_bounds.fTop);
        expected_builder.DrawRect(
            SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
            filter_paint);
      }
      expected_builder.Restore();
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ShaderMaskLayerTest, SimpleFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 6.5f, 6.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto dl_filter = MakeFilter(DlColor::kBlue());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ShaderMaskLayer>(dl_filter, layer_bounds,
                                                 DlBlendMode::kSrc);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  DlPaint filter_paint;
  filter_paint.setBlendMode(DlBlendMode::kSrc);
  filter_paint.setColorSource(dl_filter);

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ShaderMask)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.SaveLayer(&child_bounds);
      {
        /* mock_layer::Paint */ {
          expected_builder.DrawPath(child_path, child_paint);
        }
        expected_builder.Translate(layer_bounds.fLeft, layer_bounds.fTop);
        expected_builder.DrawRect(
            SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
            filter_paint);
      }
      expected_builder.Restore();
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ShaderMaskLayerTest, MultipleChildren) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 6.5f, 6.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const DlPaint child_paint1 = DlPaint(DlColor::kYellow());
  const DlPaint child_paint2 = DlPaint(DlColor::kCyan());
  auto dl_filter = MakeFilter(DlColor::kBlue());
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ShaderMaskLayer>(dl_filter, layer_bounds,
                                                 DlBlendMode::kSrc);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), children_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), children_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  DlPaint filter_paint;
  filter_paint.setBlendMode(DlBlendMode::kSrc);
  filter_paint.setColorSource(dl_filter);

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ShaderMask)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.SaveLayer(&children_bounds);
      {
        /* mock_layer1::Paint */ {
          expected_builder.DrawPath(child_path1, child_paint1);
        }
        /* mock_layer2::Paint */ {
          expected_builder.DrawPath(child_path2, child_paint2);
        }
        expected_builder.Translate(layer_bounds.fLeft, layer_bounds.fTop);
        expected_builder.DrawRect(
            SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
            filter_paint);
      }
      expected_builder.Restore();
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ShaderMaskLayerTest, Nested) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 7.5f, 8.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 20.5f, 20.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const DlPaint child_paint1 = DlPaint(DlColor::kYellow());
  const DlPaint child_paint2 = DlPaint(DlColor::kCyan());
  auto dl_filter1 = MakeFilter(DlColor::kGreen());
  auto dl_filter2 = MakeFilter(DlColor::kMagenta());
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer1 = std::make_shared<ShaderMaskLayer>(dl_filter1, layer_bounds,
                                                  DlBlendMode::kSrc);
  auto layer2 = std::make_shared<ShaderMaskLayer>(dl_filter2, layer_bounds,
                                                  DlBlendMode::kSrc);
  layer2->Add(mock_layer2);
  layer1->Add(mock_layer1);
  layer1->Add(layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer1->Preroll(preroll_context());
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer1->paint_bounds(), children_bounds);
  EXPECT_EQ(layer1->child_paint_bounds(), children_bounds);
  EXPECT_EQ(layer2->paint_bounds(), mock_layer2->paint_bounds());
  EXPECT_EQ(layer2->child_paint_bounds(), mock_layer2->paint_bounds());
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer1->needs_painting(paint_context()));
  EXPECT_TRUE(layer2->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  DlPaint filter_paint1, filter_paint2;
  filter_paint1.setBlendMode(DlBlendMode::kSrc);
  filter_paint2.setBlendMode(DlBlendMode::kSrc);
  filter_paint1.setColorSource(dl_filter1);
  filter_paint2.setColorSource(dl_filter2);

  layer1->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ShaderMask)layer1::Paint */ {
    expected_builder.Save();
    {
      expected_builder.SaveLayer(&children_bounds);
      {
        /* mock_layer1::Paint */ {
          expected_builder.DrawPath(child_path1, child_paint1);
        }
        /* (ShaderMask)layer2::Paint */ {
          expected_builder.Save();
          {
            expected_builder.SaveLayer(&child_path2.getBounds());
            {
              /* mock_layer2::Paint */ {
                expected_builder.DrawPath(child_path2, child_paint2);
              }
              expected_builder.Translate(layer_bounds.fLeft, layer_bounds.fTop);
              expected_builder.DrawRect(
                  SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
                  filter_paint2);
            }
            expected_builder.Restore();
          }
          expected_builder.Restore();
        }
        expected_builder.Translate(layer_bounds.fLeft, layer_bounds.fTop);
        expected_builder.DrawRect(
            SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
            filter_paint1);
      }
      expected_builder.Restore();
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(ShaderMaskLayerTest, Readback) {
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 20.5f, 20.5f);
  auto dl_filter = MakeFilter(DlColor::kBlue());
  auto layer = std::make_shared<ShaderMaskLayer>(dl_filter, layer_bounds,
                                                 DlBlendMode::kSrc);

  // ShaderMaskLayer does not read from surface
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context());
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // ShaderMaskLayer blocks child with readback
  auto mock_layer = std::make_shared<MockLayer>(SkPath(), DlPaint());
  mock_layer->set_fake_reads_surface(true);
  layer->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context());
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

TEST_F(ShaderMaskLayerTest, LayerCached) {
  auto dl_filter = MakeFilter(DlColor::kBlue());
  DlPaint paint;
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 20.5f, 20.5f);
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ShaderMaskLayer>(dl_filter, layer_bounds,
                                                 DlBlendMode::kSrc);
  layer->Add(mock_layer);

  SkMatrix cache_ctm = initial_transform;
  DisplayListBuilder cache_canvas;
  cache_canvas.Transform(cache_ctm);

  use_mock_raster_cache();
  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  const auto* cacheable_shader_masker_item = layer->raster_cache_item();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(cacheable_shader_masker_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_shader_masker_item->GetId().has_value());

  // frame 1.
  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(cacheable_shader_masker_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_shader_masker_item->GetId().has_value());

  // frame 2.
  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_EQ(cacheable_shader_masker_item->cache_state(),
            RasterCacheItem::CacheState::kNone);
  EXPECT_FALSE(cacheable_shader_masker_item->GetId().has_value());

  // frame 3.
  layer->Preroll(preroll_context());
  LayerTree::TryToRasterCache(cacheable_items(), &paint_context());
  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);
  EXPECT_EQ(cacheable_shader_masker_item->cache_state(),
            RasterCacheItem::CacheState::kCurrent);

  EXPECT_TRUE(raster_cache()->Draw(
      cacheable_shader_masker_item->GetId().value(), cache_canvas, &paint));
}

TEST_F(ShaderMaskLayerTest, OpacityInheritance) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  auto mock_layer = MockLayer::Make(child_path);
  const SkRect mask_rect = SkRect::MakeLTRB(10, 10, 20, 20);
  auto shader_mask_layer =
      std::make_shared<ShaderMaskLayer>(nullptr, mask_rect, DlBlendMode::kSrc);
  shader_mask_layer->Add(mock_layer);

  // ShaderMaskLayers can always support opacity despite incompatible children
  PrerollContext* context = preroll_context();
  shader_mask_layer->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags, Layer::kSaveLayerRenderFlags);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(shader_mask_layer);
  opacity_layer->Preroll(context);
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  DisplayListBuilder expected_builder;
  /* OpacityLayer::Paint() */ {
    expected_builder.Save();
    {
      expected_builder.Translate(offset.fX, offset.fY);
      /* ShaderMaskLayer::Paint() */ {
        DlPaint sl_paint = DlPaint(opacity_alpha << 24);
        expected_builder.SaveLayer(&child_path.getBounds(), &sl_paint);
        {
          /* child layer paint */ {
            expected_builder.DrawPath(child_path, DlPaint());
          }
          expected_builder.Translate(mask_rect.fLeft, mask_rect.fTop);
          expected_builder.DrawRect(
              SkRect::MakeWH(mask_rect.width(), mask_rect.height()),
              DlPaint().setBlendMode(DlBlendMode::kSrc));
        }
        expected_builder.Restore();
      }
    }
    expected_builder.Restore();
  }

  opacity_layer->Paint(display_list_paint_context());
  EXPECT_TRUE(DisplayListsEQ_Verbose(expected_builder.Build(), display_list()));
}

TEST_F(ShaderMaskLayerTest, SimpleFilterWithRasterCacheLayerNotCached) {
  use_mock_raster_cache();  // Ensure non-fractional alignment.

  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkRect layer_bounds = SkRect::MakeLTRB(2.0f, 4.0f, 6.5f, 6.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto dl_filter = MakeFilter(DlColor::kBlue());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ShaderMaskLayer>(dl_filter, layer_bounds,
                                                 DlBlendMode::kSrc);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());

  DlPaint filter_paint;
  filter_paint.setBlendMode(DlBlendMode::kSrc);
  filter_paint.setColorSource(dl_filter);

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (ShaderMask)layer::Paint */ {
    expected_builder.Save();
    {
      expected_builder.TransformReset();
      // The layer will perform this Identity transform operation by default,
      // but it should be ignored both here and in the layer paint
      expected_builder.Transform(SkMatrix());
      expected_builder.SaveLayer(&child_bounds);
      {
        /* mock_layer::Paint */ {
          expected_builder.DrawPath(child_path, child_paint);
        }
        expected_builder.Translate(layer_bounds.fLeft, layer_bounds.fTop);
        expected_builder.DrawRect(
            SkRect::MakeWH(layer_bounds.width(), layer_bounds.height()),
            filter_paint);
      }
      expected_builder.Restore();
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(bugprone-unchecked-optional-access)

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  auto layer = std::make_shared<ImageFilterLayer>(sk_sp<SkImageFilter>());

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ImageFilterLayerTest, PaintBeforePrerollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ImageFilterLayer>(sk_sp<SkImageFilter>());
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

  layer->Preroll(preroll_context(), initial_transform);
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
                    0, MockCanvas::SaveLayerData{child_bounds, filter_paint,
                                                 nullptr, 1}},
                MockCanvas::DrawCall{
                    1, MockCanvas::DrawPathData{child_path, child_paint}},
                MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}},
            }));
}

TEST_F(ImageFilterLayerTest, SimpleFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto layer_filter = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  layer->Add(mock_layer);

  const SkRect child_rounded_bounds =
      SkRect::MakeLTRB(5.0f, 6.0f, 21.0f, 22.0f);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_rounded_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  SkPaint filter_paint;
  filter_paint.setImageFilter(layer_filter);
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({
                MockCanvas::DrawCall{
                    0, MockCanvas::SaveLayerData{child_bounds, filter_paint,
                                                 nullptr, 1}},
                MockCanvas::DrawCall{
                    1, MockCanvas::DrawPathData{child_path, child_paint}},
                MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}},
            }));
}

TEST_F(ImageFilterLayerTest, SimpleFilterBounds) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  const SkMatrix filter_transform = SkMatrix::Scale(2.0, 2.0);
  auto layer_filter = SkImageFilters::MatrixTransform(
      filter_transform,
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  layer->Add(mock_layer);

  const SkRect filter_bounds = SkRect::MakeLTRB(10.0f, 12.0f, 42.0f, 44.0f);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), filter_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  SkPaint filter_paint;
  filter_paint.setImageFilter(layer_filter);
  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({
                MockCanvas::DrawCall{
                    0, MockCanvas::SaveLayerData{child_bounds, filter_paint,
                                                 nullptr, 1}},
                MockCanvas::DrawCall{
                    1, MockCanvas::DrawPathData{child_path, child_paint}},
                MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}},
            }));
}

TEST_F(ImageFilterLayerTest, MultipleChildren) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  auto layer_filter = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  SkRect children_rounded_bounds = SkRect::Make(children_bounds.roundOut());

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), children_rounded_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), children_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  SkPaint filter_paint;
  filter_paint.setImageFilter(layer_filter);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{children_bounds,
                                                    filter_paint, nullptr, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path2, child_paint2}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(ImageFilterLayerTest, Nested) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  auto layer_filter1 = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto layer_filter2 = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer1 = std::make_shared<ImageFilterLayer>(layer_filter1);
  auto layer2 = std::make_shared<ImageFilterLayer>(layer_filter2);
  layer2->Add(mock_layer2);
  layer1->Add(mock_layer1);
  layer1->Add(layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(SkRect::Make(child_path2.getBounds().roundOut()));
  const SkRect children_rounded_bounds =
      SkRect::Make(children_bounds.roundOut());
  const SkRect mock_layer2_rounded_bounds =
      SkRect::Make(child_path2.getBounds().roundOut());

  layer1->Preroll(preroll_context(), initial_transform);
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

  SkPaint filter_paint1, filter_paint2;
  filter_paint1.setImageFilter(layer_filter1);
  filter_paint2.setImageFilter(layer_filter2);
  layer1->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({
                MockCanvas::DrawCall{
                    0, MockCanvas::SaveLayerData{children_bounds, filter_paint1,
                                                 nullptr, 1}},
                MockCanvas::DrawCall{
                    1, MockCanvas::DrawPathData{child_path1, child_paint1}},
                MockCanvas::DrawCall{
                    1, MockCanvas::SaveLayerData{child_path2.getBounds(),
                                                 filter_paint2, nullptr, 2}},
                MockCanvas::DrawCall{
                    2, MockCanvas::DrawPathData{child_path2, child_paint2}},
                MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
                MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}},
            }));
}

TEST_F(ImageFilterLayerTest, Readback) {
  auto layer_filter = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto initial_transform = SkMatrix();

  // ImageFilterLayer does not read from surface
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // ImageFilterLayer blocks child with readback
  auto mock_layer =
      std::make_shared<MockLayer>(SkPath(), SkPaint(), false, true);
  layer->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

TEST_F(ImageFilterLayerTest, CacheChild) {
  auto layer_filter = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
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

  layer->Preroll(preroll_context(), initial_transform);
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
  auto layer_filter = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  SkPaint paint = SkPaint();
  const SkPath child_path1 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  const SkPath child_path2 = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
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

  layer->Preroll(preroll_context(), initial_transform);
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
}

TEST_F(ImageFilterLayerTest, CacheImageFilterLayerSelf) {
  auto layer_filter = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
  const SkPath child_path = SkPath().addRect(SkRect::MakeWH(5.0f, 5.0f));
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  layer->Add(mock_layer);

  SkMatrix cache_ctm = initial_transform;
  SkCanvas cache_canvas;
  cache_canvas.setMatrix(cache_ctm);
  SkCanvas other_canvas;
  other_canvas.setMatrix(other_transform);
  SkPaint paint = SkPaint();

  use_mock_raster_cache();
  const auto* cacheable_image_filter_item = layer->raster_cache_item();
  // frame 1.
  layer->Preroll(preroll_context(), initial_transform);
  layer->Paint(paint_context());
  // frame 2.
  layer->Preroll(preroll_context(), initial_transform);
  layer->Paint(paint_context());
  // frame 3.
  layer->Preroll(preroll_context(), initial_transform);
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
}

TEST_F(ImageFilterLayerTest, OpacityInheritance) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto layer_filter = SkImageFilters::MatrixTransform(
      SkMatrix(),
      SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear), nullptr);
  // The mock_layer child will not be compatible with opacity
  auto mock_layer = MockLayer::Make(child_path, child_paint);
  auto image_filter_layer = std::make_shared<ImageFilterLayer>(layer_filter);
  image_filter_layer->Add(mock_layer);

  PrerollContext* context = preroll_context();
  context->subtree_can_inherit_opacity = false;
  image_filter_layer->Preroll(preroll_context(), initial_transform);
  // ImageFilterLayers can always inherit opacity whether or not their
  // children are compatible.
  EXPECT_TRUE(context->subtree_can_inherit_opacity);

  int opacity_alpha = 0x7F;
  SkPoint offset = SkPoint::Make(10, 10);
  auto opacity_layer = std::make_shared<OpacityLayer>(opacity_alpha, offset);
  opacity_layer->Add(image_filter_layer);
  context->subtree_can_inherit_opacity = false;
  opacity_layer->Preroll(context, SkMatrix::I());
  EXPECT_TRUE(opacity_layer->children_can_accept_opacity());

  auto dl_image_filter = DlImageFilter::From(layer_filter);
  DisplayListBuilder expected_builder;
  /* OpacityLayer::Paint() */ {
    expected_builder.save();
    {
      expected_builder.translate(offset.fX, offset.fY);
      /* ImageFilterLayer::Paint() */ {
        expected_builder.setColor(opacity_alpha << 24);
        expected_builder.setImageFilter(dl_image_filter.get());
        expected_builder.saveLayer(&child_path.getBounds(), true);
        /* MockLayer::Paint() */ {
          expected_builder.setColor(child_paint.getColor());
          expected_builder.setImageFilter(nullptr);
          expected_builder.drawPath(child_path);
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
  auto filter = SkImageFilters::Blur(10, 10, SkTileMode::kClamp, nullptr);

  {
    // tests later assume 30px paint area, fail early if that's not the case
    auto paint_rect =
        filter->filterBounds(SkIRect::MakeWH(10, 10), SkMatrix::I(),
                             SkImageFilter::kForward_MapDirection);
    EXPECT_EQ(paint_rect, SkIRect::MakeLTRB(-30, -30, 40, 40));
  }

  MockLayerTree l1;
  auto filter_layer = std::make_shared<ImageFilterLayer>(filter);
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
  auto filter = SkImageFilters::Blur(10, 10, SkTileMode::kClamp, nullptr);

  {
    // tests later assume 30px paint area, fail early if that's not the case
    auto paint_rect =
        filter->filterBounds(SkIRect::MakeWH(10, 10), SkMatrix::I(),
                             SkImageFilter::kForward_MapDirection);
    EXPECT_EQ(paint_rect, SkIRect::MakeLTRB(-30, -30, 40, 40));
  }

  MockLayerTree l1;

  // Use nested filter layers to check if both contribute to child bounds
  auto filter_layer_1_1 = std::make_shared<ImageFilterLayer>(filter);
  auto filter_layer_1_2 = std::make_shared<ImageFilterLayer>(filter);
  filter_layer_1_1->Add(filter_layer_1_2);
  auto path = SkPath().addRect(SkRect::MakeLTRB(100, 100, 110, 110));
  filter_layer_1_2->Add(
      std::make_shared<MockLayer>(path, SkPaint(SkColors::kYellow)));
  l1.root()->Add(filter_layer_1_1);

  // second layer tree with identical filter layers but different child layer
  MockLayerTree l2;
  auto filter_layer2_1 = std::make_shared<ImageFilterLayer>(filter);
  filter_layer2_1->AssignOldLayer(filter_layer_1_1.get());
  auto filter_layer2_2 = std::make_shared<ImageFilterLayer>(filter);
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

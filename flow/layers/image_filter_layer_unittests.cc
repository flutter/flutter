// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/image_filter_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"
#include "third_party/skia/include/core/SkImageFilter.h"

namespace flutter {
namespace testing {

using ImageFilterLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(ImageFilterLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<ImageFilterLayer>(sk_sp<SkImageFilter>());

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_system_composite());

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
  auto layer_filter = SkImageFilter::MakeMatrixFilter(
      SkMatrix(), SkFilterQuality::kMedium_SkFilterQuality, nullptr);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  layer->Add(mock_layer);

  const SkRect child_rounded_bounds =
      SkRect::MakeLTRB(5.0f, 6.0f, 21.0f, 22.0f);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_rounded_bounds);
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
  auto layer_filter = SkImageFilter::MakeMatrixFilter(
      filter_transform, SkFilterQuality::kMedium_SkFilterQuality, nullptr);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  layer->Add(mock_layer);

  const SkRect filter_bounds = SkRect::MakeLTRB(10.0f, 12.0f, 42.0f, 44.0f);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), filter_bounds);
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
  auto layer_filter = SkImageFilter::MakeMatrixFilter(
      SkMatrix(), SkFilterQuality::kMedium_SkFilterQuality, nullptr);
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
  auto layer_filter1 = SkImageFilter::MakeMatrixFilter(
      SkMatrix(), SkFilterQuality::kMedium_SkFilterQuality, nullptr);
  auto layer_filter2 = SkImageFilter::MakeMatrixFilter(
      SkMatrix(), SkFilterQuality::kMedium_SkFilterQuality, nullptr);
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
  EXPECT_EQ(layer2->paint_bounds(), mock_layer2_rounded_bounds);
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
  auto layer_filter = SkImageFilter::MakeMatrixFilter(
      SkMatrix(), SkFilterQuality::kMedium_SkFilterQuality, nullptr);
  auto initial_transform = SkMatrix();

  // ImageFilterLayer does not read from surface
  auto layer = std::make_shared<ImageFilterLayer>(layer_filter);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // ImageFilterLayer blocks child with readback
  auto mock_layer =
      std::make_shared<MockLayer>(SkPath(), SkPaint(), false, false, true);
  layer->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

TEST_F(ImageFilterLayerTest, ChildIsCached) {
  auto layer_filter = SkImageFilter::MakeMatrixFilter(
      SkMatrix(), SkFilterQuality::kMedium_SkFilterQuality, nullptr);
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

  use_mock_raster_cache();

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_FALSE(raster_cache()->Draw(mock_layer.get(), other_canvas));
  EXPECT_FALSE(raster_cache()->Draw(mock_layer.get(), cache_canvas));

  layer->Preroll(preroll_context(), initial_transform);

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);
  EXPECT_FALSE(raster_cache()->Draw(mock_layer.get(), other_canvas));
  EXPECT_TRUE(raster_cache()->Draw(mock_layer.get(), cache_canvas));
}

TEST_F(ImageFilterLayerTest, ChildrenNotCached) {
  auto layer_filter = SkImageFilter::MakeMatrixFilter(
      SkMatrix(), SkFilterQuality::kMedium_SkFilterQuality, nullptr);
  auto initial_transform = SkMatrix::Translate(50.0, 25.5);
  auto other_transform = SkMatrix::Scale(1.0, 2.0);
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

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)0);
  EXPECT_FALSE(raster_cache()->Draw(mock_layer1.get(), other_canvas));
  EXPECT_FALSE(raster_cache()->Draw(mock_layer1.get(), cache_canvas));
  EXPECT_FALSE(raster_cache()->Draw(mock_layer2.get(), other_canvas));
  EXPECT_FALSE(raster_cache()->Draw(mock_layer2.get(), cache_canvas));

  layer->Preroll(preroll_context(), initial_transform);

  EXPECT_EQ(raster_cache()->GetLayerCachedEntriesCount(), (size_t)1);
  EXPECT_FALSE(raster_cache()->Draw(mock_layer1.get(), other_canvas));
  EXPECT_FALSE(raster_cache()->Draw(mock_layer1.get(), cache_canvas));
  EXPECT_FALSE(raster_cache()->Draw(mock_layer2.get(), other_canvas));
  EXPECT_FALSE(raster_cache()->Draw(mock_layer2.get(), cache_canvas));
}

}  // namespace testing
}  // namespace flutter

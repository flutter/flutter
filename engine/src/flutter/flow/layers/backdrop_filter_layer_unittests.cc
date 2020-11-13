// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/backdrop_filter_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/effects/SkImageFilters.h"

namespace flutter {
namespace testing {

using BackdropFilterLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(BackdropFilterLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<BackdropFilterLayer>(sk_sp<SkImageFilter>());

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_FALSE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_system_composite());

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(BackdropFilterLayerTest, PaintBeforePrerollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<BackdropFilterLayer>(sk_sp<SkImageFilter>());
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(BackdropFilterLayerTest, EmptyFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<BackdropFilterLayer>(nullptr);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{child_bounds, SkPaint(),
                                                    nullptr, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path, child_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, SimpleFilter) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  auto layer_filter = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<BackdropFilterLayer>(layer_filter);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{child_bounds, SkPaint(),
                                                    layer_filter, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path, child_paint}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, MultipleChildren) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  auto layer_filter = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<BackdropFilterLayer>(layer_filter);
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), children_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::SaveLayerData{children_bounds, SkPaint(),
                                                    layer_filter, 1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{
                       1, MockCanvas::DrawPathData{child_path2, child_paint2}},
                   MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, Nested) {
  const SkMatrix initial_transform = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 2.5f, 3.5f);
  const SkPath child_path1 = SkPath().addRect(child_bounds);
  const SkPath child_path2 =
      SkPath().addRect(child_bounds.makeOffset(3.0f, 0.0f));
  const SkPaint child_paint1 = SkPaint(SkColors::kYellow);
  const SkPaint child_paint2 = SkPaint(SkColors::kCyan);
  auto layer_filter1 = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto layer_filter2 = SkImageFilters::Paint(SkPaint(SkColors::kDkGray));
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer1 = std::make_shared<BackdropFilterLayer>(layer_filter1);
  auto layer2 = std::make_shared<BackdropFilterLayer>(layer_filter2);
  layer2->Add(mock_layer2);
  layer1->Add(mock_layer1);
  layer1->Add(layer2);

  SkRect children_bounds = child_path1.getBounds();
  children_bounds.join(child_path2.getBounds());
  layer1->Preroll(preroll_context(), initial_transform);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer1->paint_bounds(), children_bounds);
  EXPECT_EQ(layer2->paint_bounds(), mock_layer2->paint_bounds());
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer1->needs_painting(paint_context()));
  EXPECT_TRUE(layer2->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);

  layer1->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector(
                {MockCanvas::DrawCall{
                     0, MockCanvas::SaveLayerData{children_bounds, SkPaint(),
                                                  layer_filter1, 1}},
                 MockCanvas::DrawCall{
                     1, MockCanvas::DrawPathData{child_path1, child_paint1}},
                 MockCanvas::DrawCall{
                     1, MockCanvas::SaveLayerData{child_path2.getBounds(),
                                                  SkPaint(), layer_filter2, 2}},
                 MockCanvas::DrawCall{
                     2, MockCanvas::DrawPathData{child_path2, child_paint2}},
                 MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
                 MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(BackdropFilterLayerTest, Readback) {
  sk_sp<SkImageFilter> no_filter;
  auto layer_filter = SkImageFilters::Paint(SkPaint(SkColors::kMagenta));
  auto initial_transform = SkMatrix();

  // BDF with filter always reads from surface
  auto layer1 = std::make_shared<BackdropFilterLayer>(layer_filter);
  preroll_context()->surface_needs_readback = false;
  layer1->Preroll(preroll_context(), initial_transform);
  EXPECT_TRUE(preroll_context()->surface_needs_readback);

  // BDF with no filter does not read from surface itself
  auto layer2 = std::make_shared<BackdropFilterLayer>(no_filter);
  preroll_context()->surface_needs_readback = false;
  layer2->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);

  // BDF with no filter does not block prior readback value
  preroll_context()->surface_needs_readback = true;
  layer2->Preroll(preroll_context(), initial_transform);
  EXPECT_TRUE(preroll_context()->surface_needs_readback);

  // BDF with no filter blocks child with readback
  auto mock_layer =
      std::make_shared<MockLayer>(SkPath(), SkPaint(), false, false, true);
  layer2->Add(mock_layer);
  preroll_context()->surface_needs_readback = false;
  layer2->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->surface_needs_readback);
}

}  // namespace testing
}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/container_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

using ContainerLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(ContainerLayerTest, LayerWithParentHasPlatformView) {
  auto layer = std::make_shared<ContainerLayer>();

  preroll_context()->has_platform_view = true;
  EXPECT_DEATH_IF_SUPPORTED(layer->Preroll(preroll_context(), SkMatrix()),
                            "!context->has_platform_view");
}

TEST_F(ContainerLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<ContainerLayer>();

  layer->Preroll(preroll_context(), SkMatrix());
  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_FALSE(layer->needs_painting());
  EXPECT_FALSE(layer->needs_system_composite());

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(\\)");
}

TEST_F(ContainerLayerTest, PaintBeforePreollDies) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(\\)");
}
#endif

TEST_F(ContainerLayerTest, Simple) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPaint child_paint(SkColors::kGreen);
  SkMatrix initial_transform = SkMatrix::MakeTrans(-0.5f, -0.5f);

  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->has_platform_view);
  EXPECT_EQ(mock_layer->paint_bounds(), child_path.getBounds());
  EXPECT_EQ(layer->paint_bounds(), child_path.getBounds());
  EXPECT_TRUE(mock_layer->needs_painting());
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_FALSE(mock_layer->needs_system_composite());
  EXPECT_FALSE(layer->needs_system_composite());
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer->parent_cull_rect(), kGiantRect);

  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{child_path, child_paint}}}));
}

TEST_F(ContainerLayerTest, Multiple) {
  SkPath child_path1;
  child_path1.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPath child_path2;
  child_path2.addRect(8.0f, 2.0f, 16.5f, 14.5f);
  SkPaint child_paint1(SkColors::kGray);
  SkPaint child_paint2(SkColors::kGreen);
  SkMatrix initial_transform = SkMatrix::MakeTrans(-0.5f, -0.5f);

  auto mock_layer1 = std::make_shared<MockLayer>(
      child_path1, child_paint1, true /* fake_has_platform_view */);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect expected_total_bounds = child_path1.getBounds();
  expected_total_bounds.join(child_path2.getBounds());
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_TRUE(preroll_context()->has_platform_view);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_total_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting());
  EXPECT_TRUE(mock_layer2->needs_painting());
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_FALSE(mock_layer1->needs_system_composite());
  EXPECT_FALSE(mock_layer2->needs_system_composite());
  EXPECT_FALSE(layer->needs_system_composite());
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer1->parent_cull_rect(), kGiantRect);
  EXPECT_EQ(mock_layer2->parent_cull_rect(),
            kGiantRect);  // Siblings are independent

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{0, MockCanvas::DrawPathData{
                                               child_path2, child_paint2}}}));
}

TEST_F(ContainerLayerTest, MultipleWithEmpty) {
  SkPath child_path1;
  child_path1.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPaint child_paint1(SkColors::kGray);
  SkPaint child_paint2(SkColors::kGreen);
  SkMatrix initial_transform = SkMatrix::MakeTrans(-0.5f, -0.5f);

  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(SkPath(), child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->has_platform_view);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), SkPath().getBounds());
  EXPECT_EQ(layer->paint_bounds(), child_path1.getBounds());
  EXPECT_TRUE(mock_layer1->needs_painting());
  EXPECT_FALSE(mock_layer2->needs_painting());
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_FALSE(mock_layer1->needs_system_composite());
  EXPECT_FALSE(mock_layer2->needs_system_composite());
  EXPECT_FALSE(layer->needs_system_composite());
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer1->parent_cull_rect(), kGiantRect);
  EXPECT_EQ(mock_layer2->parent_cull_rect(), kGiantRect);

  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{child_path1, child_paint1}}}));
}

TEST_F(ContainerLayerTest, NeedsSystemComposite) {
  SkPath child_path1;
  child_path1.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPath child_path2;
  child_path2.addRect(8.0f, 2.0f, 16.5f, 14.5f);
  SkPaint child_paint1(SkColors::kGray);
  SkPaint child_paint2(SkColors::kGreen);
  SkMatrix initial_transform = SkMatrix::MakeTrans(-0.5f, -0.5f);

  auto mock_layer1 = std::make_shared<MockLayer>(
      child_path1, child_paint1, false /* fake_has_platform_view */,
      true /* fake_needs_system_composite */);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect expected_total_bounds = child_path1.getBounds();
  expected_total_bounds.join(child_path2.getBounds());
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->has_platform_view);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_total_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting());
  EXPECT_TRUE(mock_layer2->needs_painting());
  EXPECT_TRUE(layer->needs_painting());
  EXPECT_TRUE(mock_layer1->needs_system_composite());
  EXPECT_FALSE(mock_layer2->needs_system_composite());
  EXPECT_TRUE(layer->needs_system_composite());
  EXPECT_EQ(mock_layer1->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer2->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer1->parent_cull_rect(), kGiantRect);
  EXPECT_EQ(mock_layer2->parent_cull_rect(), kGiantRect);

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{0, MockCanvas::DrawPathData{
                                               child_path2, child_paint2}}}));
}

}  // namespace testing
}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/container_layer.h"

#include "flutter/flow/testing/diff_context_test.h"
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
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ContainerLayerTest, PaintBeforePrerollDies) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(ContainerLayerTest, Simple) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPaint child_paint(SkColors::kGreen);
  SkMatrix initial_transform = SkMatrix::Translate(-0.5f, -0.5f);

  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->has_platform_view);
  EXPECT_EQ(mock_layer->paint_bounds(), child_path.getBounds());
  EXPECT_EQ(layer->paint_bounds(), child_path.getBounds());
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
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
  SkMatrix initial_transform = SkMatrix::Translate(-0.5f, -0.5f);

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
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
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
  SkMatrix initial_transform = SkMatrix::Translate(-0.5f, -0.5f);

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
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_FALSE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
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
  SkMatrix initial_transform = SkMatrix::Translate(-0.5f, -0.5f);

  auto mock_layer1 = std::make_shared<MockLayer>(
      child_path1, child_paint1, false /* fake_has_platform_view */);
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
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
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

TEST_F(ContainerLayerTest, MergedOneChild) {
  SkPath child_path;
  child_path.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPaint child_paint(SkColors::kGreen);
  SkMatrix initial_transform = SkMatrix::Translate(-0.5f, -0.5f);

  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<MergedContainerLayer>();
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->has_platform_view);
  EXPECT_EQ(mock_layer->paint_bounds(), child_path.getBounds());
  EXPECT_EQ(layer->paint_bounds(), child_path.getBounds());
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);
  EXPECT_EQ(mock_layer->parent_cull_rect(), kGiantRect);

  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{child_path, child_paint}}}));
}

TEST_F(ContainerLayerTest, MergedMultipleChildren) {
  SkPath child_path1;
  child_path1.addRect(5.0f, 6.0f, 20.5f, 21.5f);
  SkPath child_path2;
  child_path2.addRect(58.0f, 2.0f, 16.5f, 14.5f);
  SkPaint child_paint1(SkColors::kGray);
  SkPaint child_paint2(SkColors::kGreen);
  SkMatrix initial_transform = SkMatrix::Translate(-0.5f, -0.5f);

  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<MergedContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect expected_total_bounds = child_path1.getBounds();
  expected_total_bounds.join(child_path2.getBounds());
  layer->Preroll(preroll_context(), initial_transform);
  EXPECT_FALSE(preroll_context()->has_platform_view);
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_total_bounds);
  EXPECT_TRUE(mock_layer1->needs_painting(paint_context()));
  EXPECT_TRUE(mock_layer2->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
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

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

using ContainerLayerDiffTest = DiffContextTest;

// Insert PictureLayer amongst container layers
TEST_F(ContainerLayerDiffTest, PictureLayerInsertion) {
  auto pic1 = CreatePicture(SkRect::MakeLTRB(0, 0, 50, 50), 1);
  auto pic2 = CreatePicture(SkRect::MakeLTRB(100, 0, 150, 50), 1);
  auto pic3 = CreatePicture(SkRect::MakeLTRB(200, 0, 250, 50), 1);

  MockLayerTree t1;

  auto t1_c1 = CreateContainerLayer(CreatePictureLayer(pic1));
  t1.root()->Add(t1_c1);

  auto t1_c2 = CreateContainerLayer(CreatePictureLayer(pic2));
  t1.root()->Add(t1_c2);

  auto damage = DiffLayerTree(t1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 150, 50));

  // Add in the middle

  MockLayerTree t2;
  auto t2_c1 = CreateContainerLayer(CreatePictureLayer(pic1));
  t2_c1->AssignOldLayer(t1_c1.get());
  t2.root()->Add(t2_c1);

  t2.root()->Add(CreatePictureLayer(pic3));

  auto t2_c2 = CreateContainerLayer(CreatePictureLayer(pic2));
  t2_c2->AssignOldLayer(t1_c2.get());
  t2.root()->Add(t2_c2);

  damage = DiffLayerTree(t2, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 50));

  // Add in the beginning

  t2 = MockLayerTree();
  t2.root()->Add(CreatePictureLayer(pic3));
  t2.root()->Add(t2_c1);
  t2.root()->Add(t2_c2);
  damage = DiffLayerTree(t2, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 50));

  // Add at the end

  t2 = MockLayerTree();
  t2.root()->Add(t2_c1);
  t2.root()->Add(t2_c2);
  t2.root()->Add(CreatePictureLayer(pic3));
  damage = DiffLayerTree(t2, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 50));
}

// Insert picture layer amongst other picture layers
TEST_F(ContainerLayerDiffTest, PictureInsertion) {
  auto pic1 = CreatePicture(SkRect::MakeLTRB(0, 0, 50, 50), 1);
  auto pic2 = CreatePicture(SkRect::MakeLTRB(100, 0, 150, 50), 1);
  auto pic3 = CreatePicture(SkRect::MakeLTRB(200, 0, 250, 50), 1);

  MockLayerTree t1;
  t1.root()->Add(CreatePictureLayer(pic1));
  t1.root()->Add(CreatePictureLayer(pic2));

  auto damage = DiffLayerTree(t1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 150, 50));

  MockLayerTree t2;
  t2.root()->Add(CreatePictureLayer(pic3));
  t2.root()->Add(CreatePictureLayer(pic1));
  t2.root()->Add(CreatePictureLayer(pic2));

  damage = DiffLayerTree(t2, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 50));

  MockLayerTree t3;
  t3.root()->Add(CreatePictureLayer(pic1));
  t3.root()->Add(CreatePictureLayer(pic3));
  t3.root()->Add(CreatePictureLayer(pic2));

  damage = DiffLayerTree(t3, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 50));

  MockLayerTree t4;
  t4.root()->Add(CreatePictureLayer(pic1));
  t4.root()->Add(CreatePictureLayer(pic2));
  t4.root()->Add(CreatePictureLayer(pic3));

  damage = DiffLayerTree(t4, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 50));
}

TEST_F(ContainerLayerDiffTest, LayerDeletion) {
  auto path1 = SkPath().addRect(SkRect::MakeLTRB(0, 0, 50, 50));
  auto path2 = SkPath().addRect(SkRect::MakeLTRB(100, 0, 150, 50));
  auto path3 = SkPath().addRect(SkRect::MakeLTRB(200, 0, 250, 50));

  auto c1 = CreateContainerLayer(std::make_shared<MockLayer>(path1));
  auto c2 = CreateContainerLayer(std::make_shared<MockLayer>(path2));
  auto c3 = CreateContainerLayer(std::make_shared<MockLayer>(path3));

  MockLayerTree t1;
  t1.root()->Add(c1);
  t1.root()->Add(c2);
  t1.root()->Add(c3);

  auto damage = DiffLayerTree(t1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 250, 50));

  MockLayerTree t2;
  t2.root()->Add(c2);
  t2.root()->Add(c3);

  damage = DiffLayerTree(t2, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 50, 50));

  MockLayerTree t3;
  t3.root()->Add(c1);
  t3.root()->Add(c3);

  damage = DiffLayerTree(t3, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(100, 0, 150, 50));

  MockLayerTree t4;
  t4.root()->Add(c1);
  t4.root()->Add(c2);

  damage = DiffLayerTree(t4, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 50));

  MockLayerTree t5;
  t5.root()->Add(c1);

  damage = DiffLayerTree(t5, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(100, 0, 250, 50));

  MockLayerTree t6;
  t6.root()->Add(c2);

  damage = DiffLayerTree(t6, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 250, 50));

  MockLayerTree t7;
  t7.root()->Add(c3);

  damage = DiffLayerTree(t7, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 150, 50));
}

TEST_F(ContainerLayerDiffTest, ReplaceLayer) {
  auto path1 = SkPath().addRect(SkRect::MakeLTRB(0, 0, 50, 50));
  auto path2 = SkPath().addRect(SkRect::MakeLTRB(100, 0, 150, 50));
  auto path3 = SkPath().addRect(SkRect::MakeLTRB(200, 0, 250, 50));

  auto path1a = SkPath().addRect(SkRect::MakeLTRB(0, 100, 50, 150));
  auto path2a = SkPath().addRect(SkRect::MakeLTRB(100, 100, 150, 150));
  auto path3a = SkPath().addRect(SkRect::MakeLTRB(200, 100, 250, 150));

  auto c1 = CreateContainerLayer(std::make_shared<MockLayer>(path1));
  auto c2 = CreateContainerLayer(std::make_shared<MockLayer>(path2));
  auto c3 = CreateContainerLayer(std::make_shared<MockLayer>(path3));

  MockLayerTree t1;
  t1.root()->Add(c1);
  t1.root()->Add(c2);
  t1.root()->Add(c3);

  auto damage = DiffLayerTree(t1, MockLayerTree());
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 250, 50));

  MockLayerTree t2;
  t2.root()->Add(c1);
  t2.root()->Add(c2);
  t2.root()->Add(c3);

  damage = DiffLayerTree(t2, t1);
  EXPECT_TRUE(damage.frame_damage.isEmpty());

  MockLayerTree t3;
  t3.root()->Add(CreateContainerLayer({std::make_shared<MockLayer>(path1a)}));
  t3.root()->Add(c2);
  t3.root()->Add(c3);

  damage = DiffLayerTree(t3, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(0, 0, 50, 150));

  MockLayerTree t4;
  t4.root()->Add(c1);
  t4.root()->Add(CreateContainerLayer(std::make_shared<MockLayer>(path2a)));
  t4.root()->Add(c3);

  damage = DiffLayerTree(t4, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(100, 0, 150, 150));

  MockLayerTree t5;
  t5.root()->Add(c1);
  t5.root()->Add(c2);
  t5.root()->Add(CreateContainerLayer(std::make_shared<MockLayer>(path3a)));

  damage = DiffLayerTree(t5, t1);
  EXPECT_EQ(damage.frame_damage, SkIRect::MakeLTRB(200, 0, 250, 150));
}

#endif

}  // namespace testing
}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/flow/layers/clip_path_layer.h"
#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/layers/clip_rrect_layer.h"
#include "flutter/flow/layers/physical_shape_layer.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

using CheckerBoardLayerTest = LayerTest;

using ClipOp = DlCanvas::ClipOp;

#ifndef NDEBUG
TEST_F(CheckerBoardLayerTest, ClipRectSaveLayerCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRectLayer>(layer_bounds,
                                               Clip::antiAliasWithSaveLayer);
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
  EXPECT_EQ(mock_layer->parent_mutators(),
            std::vector({Mutator(layer_bounds)}));

  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, ClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, DlPaint(), nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));

  mock_canvas().reset_draw_calls();

  layer->Paint(checkerboard_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, ClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, DlPaint(), nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           // start DrawCheckerboard calls
           MockCanvas::DrawCall{
               2, MockCanvas::DrawRectData{child_bounds, checkerboard_paint()}},
           // end DrawCheckerboard calls
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, ClipPathSaveLayerCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath layer_path =
      SkPath().addRect(layer_bounds).addRect(layer_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  const DlPaint clip_paint;
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer =
      std::make_shared<ClipPathLayer>(layer_path, Clip::antiAliasWithSaveLayer);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_matrix);
  layer->Preroll(preroll_context());

  // Untouched
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(), kGiantRect);
  EXPECT_TRUE(preroll_context()->state_stack.is_empty());

  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
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
               1, MockCanvas::ClipPathData{layer_path, ClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));

  mock_canvas().reset_draw_calls();

  layer->Paint(checkerboard_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipPathData{layer_path, ClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           // start DrawCheckerboard calls
           MockCanvas::DrawCall{
               2, MockCanvas::DrawRectData{child_bounds, checkerboard_paint()}},
           // end DrawCheckerboard calls
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, ClipRRectSaveLayerCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkRRect layer_rrect = SkRRect::MakeRectXY(layer_bounds, .1, .1);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  const DlPaint clip_paint;
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect,
                                                Clip::antiAliasWithSaveLayer);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_matrix);
  layer->Preroll(preroll_context());

  // Untouched
  EXPECT_EQ(preroll_context()->state_stack.device_cull_rect(), kGiantRect);
  EXPECT_TRUE(preroll_context()->state_stack.is_empty());

  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
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
               1, MockCanvas::ClipRRectData{layer_rrect, ClipOp::kIntersect,
                                            MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));

  mock_canvas().reset_draw_calls();

  layer->Paint(checkerboard_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRRectData{layer_rrect, ClipOp::kIntersect,
                                            MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           // start DrawCheckerboard calls
           MockCanvas::DrawCall{
               2, MockCanvas::DrawRectData{child_bounds, checkerboard_paint()}},
           // end DrawCheckerboard calls
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, PhysicalSaveLayerCheckBoard) {
  constexpr float initial_elevation = 20.0f;
  const SkRect paint_bounds = SkRect::MakeXYWH(0, 0, 8, 8);
  SkPath layer_path =
      SkPath().addRect(paint_bounds).addOval(paint_bounds.makeInset(0.1, 0.1));
  auto layer = std::make_shared<PhysicalShapeLayer>(
      SK_ColorGREEN, SK_ColorBLACK, initial_elevation, layer_path,
      Clip::antiAliasWithSaveLayer);

  layer->Preroll(preroll_context());
  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not do any painting there.
  EXPECT_EQ(layer->paint_bounds(),
            DisplayListCanvasDispatcher::ComputeShadowBounds(
                layer_path, initial_elevation, 1.0f, SkMatrix()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(layer->elevation(), initial_elevation);

  const DlPaint clip_paint;
  DlPaint layer_paint;
  layer_paint.setColor(SK_ColorGREEN);
  layer_paint.setAntiAlias(true);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{
               0, MockCanvas::DrawShadowData{layer_path, DlColor::kBlack(),
                                             initial_elevation, false, 1}},
           MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipPathData{layer_path, ClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1, MockCanvas::SaveLayerData{layer->paint_bounds(), clip_paint,
                                            nullptr, 2}},
           MockCanvas::DrawCall{2, MockCanvas::DrawPaintData{layer_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));

  mock_canvas().reset_draw_calls();

  layer->Paint(checkerboard_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{
               0, MockCanvas::DrawShadowData{layer_path, DlColor::kBlack(),
                                             initial_elevation, false, 1}},
           MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipPathData{layer_path, ClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1, MockCanvas::SaveLayerData{layer->paint_bounds(), clip_paint,
                                            nullptr, 2}},
           MockCanvas::DrawCall{2, MockCanvas::DrawPaintData{layer_paint}},
           // start DrawCheckerboard calls
           MockCanvas::DrawCall{2,
                                MockCanvas::DrawRectData{layer->paint_bounds(),
                                                         checkerboard_paint()}},
           // end DrawCheckerboard calls
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

#endif
}  // namespace testing
}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

#ifndef NDEBUG
TEST_F(CheckerBoardLayerTest, ClipRectSaveLayerNotCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::MakeTrans(0.5f, 1.0f);
  const SkRect cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 2.0, 4.0);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  const SkPaint clip_paint;

  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRectLayer>(layer_bounds,
                                               Clip::antiAliasWithSaveLayer);
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
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), intersect_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(),
            std::vector({Mutator(layer_bounds)}));

  layer->Paint(paint_context());

  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{layer_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, ClipRectSaveLayerCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::MakeTrans(0.5f, 1.0f);
  const SkRect cull_bounds = SkRect::MakeXYWH(0.0, 0.0, 2.0, 4.0);
  const SkRect child_bounds = SkRect::MakeXYWH(2.5, 5.0, 4.5, 4.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  const SkPaint clip_paint;

  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRectLayer>(layer_bounds,
                                               Clip::antiAliasWithSaveLayer);
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
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), intersect_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(),
            std::vector({Mutator(layer_bounds)}));

  layer->Paint(check_board_context());

  EXPECT_NE(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{layer_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, ClipPathSaveLayerNotCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  const SkPaint clip_paint;
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer =
      std::make_shared<ClipPathLayer>(layer_path, Clip::antiAliasWithSaveLayer);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, kGiantRect);        // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
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
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, ClipPathSaveLayerCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  const SkPaint clip_paint;
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer =
      std::make_shared<ClipPathLayer>(layer_path, Clip::antiAliasWithSaveLayer);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, kGiantRect);        // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), layer_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_path)}));

  layer->Paint(check_board_context());
  EXPECT_NE(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, ClipRRectSaveLayerNotCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  const SkPaint clip_paint;
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect,
                                                Clip::antiAliasWithSaveLayer);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, kGiantRect);        // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
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
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, ClipRRectSaveLayerCheckBoard) {
  const SkMatrix initial_matrix = SkMatrix::Translate(0.5f, 1.0f);
  const SkRect child_bounds = SkRect::MakeXYWH(1.0, 2.0, 2.0, 2.0);
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkRRect layer_rrect = SkRRect::MakeRect(layer_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kYellow);
  const SkPaint clip_paint;
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ClipRRectLayer>(layer_rrect,
                                                Clip::antiAliasWithSaveLayer);
  layer->Add(mock_layer);

  layer->Preroll(preroll_context(), initial_matrix);
  EXPECT_EQ(preroll_context()->cull_rect, kGiantRect);        // Untouched
  EXPECT_TRUE(preroll_context()->mutators_stack.is_empty());  // Untouched
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), layer_bounds);
  EXPECT_EQ(mock_layer->parent_matrix(), initial_matrix);
  EXPECT_EQ(mock_layer->parent_mutators(), std::vector({Mutator(layer_rrect)}));

  layer->Paint(check_board_context());
  EXPECT_NE(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{layer_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1,
               MockCanvas::SaveLayerData{child_bounds, clip_paint, nullptr, 2}},
           MockCanvas::DrawCall{
               2, MockCanvas::DrawPathData{child_path, child_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
}

TEST_F(CheckerBoardLayerTest, PhysicalSaveLayerNotCheckBoard) {
  constexpr float initial_elevation = 20.0f;
  SkPath layer_path;
  layer_path.addRect(0, 0, 8, 8).close();
  auto layer = std::make_shared<PhysicalShapeLayer>(
      SK_ColorGREEN, SK_ColorBLACK, initial_elevation, layer_path,
      Clip::antiAliasWithSaveLayer);

  layer->Preroll(preroll_context(), SkMatrix());
  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not do any painting there.
  EXPECT_EQ(layer->paint_bounds(),
            PhysicalShapeLayer::ComputeShadowBounds(layer_path.getBounds(),
                                                    initial_elevation, 1.0f));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_system_composite());
  EXPECT_EQ(layer->elevation(), initial_elevation);

  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not use the direct |Paint()| path there.
#if !defined(LEGACY_FUCHSIA_EMBEDDER)
  const SkRect paint_bounds = SkRect::MakeXYWH(0, 0, 8, 8);
  const SkPaint clip_paint;
  SkPaint layer_paint;
  layer_paint.setColor(SK_ColorGREEN);
  layer_paint.setAntiAlias(true);
  layer->Paint(paint_context());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::DrawShadowData{layer_path}},
           MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{paint_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1, MockCanvas::SaveLayerData{layer->paint_bounds(), clip_paint,
                                            nullptr, 2}},
           MockCanvas::DrawCall{2, MockCanvas::DrawPaint{layer_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
#endif
}

TEST_F(CheckerBoardLayerTest, PhysicalSaveLayerCheckBoard) {
  constexpr float initial_elevation = 20.0f;
  SkPath layer_path;
  layer_path.addRect(0, 0, 8, 8).close();
  auto layer = std::make_shared<PhysicalShapeLayer>(
      SK_ColorGREEN, SK_ColorBLACK, initial_elevation, layer_path,
      Clip::antiAliasWithSaveLayer);

  layer->Preroll(preroll_context(), SkMatrix());
  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not do any painting there.
  EXPECT_EQ(layer->paint_bounds(),
            PhysicalShapeLayer::ComputeShadowBounds(layer_path.getBounds(),
                                                    initial_elevation, 1.0f));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_FALSE(layer->needs_system_composite());
  EXPECT_EQ(layer->elevation(), initial_elevation);

  // The Fuchsia system compositor handles all elevated PhysicalShapeLayers and
  // their shadows , so we do not use the direct |Paint()| path there.
#if !defined(LEGACY_FUCHSIA_EMBEDDER)
  const SkRect paint_bounds = SkRect::MakeXYWH(0, 0, 8, 8);
  const SkPaint clip_paint;
  SkPaint layer_paint;
  layer_paint.setColor(SK_ColorGREEN);
  layer_paint.setAntiAlias(true);
  layer->Paint(check_board_context());
  EXPECT_NE(
      mock_canvas().draw_calls(),
      std::vector(
          {MockCanvas::DrawCall{0, MockCanvas::DrawShadowData{layer_path}},
           MockCanvas::DrawCall{0, MockCanvas::SaveData{1}},
           MockCanvas::DrawCall{
               1, MockCanvas::ClipRectData{paint_bounds, SkClipOp::kIntersect,
                                           MockCanvas::kSoft_ClipEdgeStyle}},
           MockCanvas::DrawCall{
               1, MockCanvas::SaveLayerData{layer->paint_bounds(), clip_paint,
                                            nullptr, 2}},
           MockCanvas::DrawCall{2, MockCanvas::DrawPaint{layer_paint}},
           MockCanvas::DrawCall{2, MockCanvas::RestoreData{1}},
           MockCanvas::DrawCall{1, MockCanvas::RestoreData{0}}}));
#endif
}

#endif
}  // namespace testing
}  // namespace flutter

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

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
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(ClipPathLayerTest, PaintBeforePrerollDies) {
  const SkRect layer_bounds = SkRect::MakeXYWH(0.5, 1.0, 5.0, 6.0);
  const SkPath layer_path = SkPath().addRect(layer_bounds);
  auto layer = std::make_shared<ClipPathLayer>(layer_path, Clip::hardEdge);
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
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
  EXPECT_TRUE(mock_layer->needs_painting(paint_context()));
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_cull_rect(), distant_bounds);
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
  auto reader = std::make_shared<MockLayer>(path, paint, false, false, true);
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

}  // namespace testing
}  // namespace flutter

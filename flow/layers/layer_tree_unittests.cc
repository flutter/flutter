// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stddef.h>
#include "flutter/flow/layers/layer_tree.h"

#include "flutter/flow/compositor_context.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/canvas_test.h"
#include "flutter/testing/mock_canvas.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {
class LayerTreeTest : public CanvasTest {
 public:
  LayerTreeTest()
      : layer_tree_(SkISize::Make(64, 64), 1.0f),
        root_transform_(SkMatrix::Translate(1.0f, 1.0f)),
        scoped_frame_(compositor_context_.AcquireFrame(nullptr,
                                                       &mock_canvas(),
                                                       nullptr,
                                                       root_transform_,
                                                       false,
                                                       true,
                                                       nullptr,
                                                       nullptr)) {}

  LayerTree& layer_tree() { return layer_tree_; }
  CompositorContext::ScopedFrame& frame() { return *scoped_frame_.get(); }
  const SkMatrix& root_transform() { return root_transform_; }

 private:
  LayerTree layer_tree_;
  CompositorContext compositor_context_;
  SkMatrix root_transform_;
  std::unique_ptr<CompositorContext::ScopedFrame> scoped_frame_;
};

TEST_F(LayerTreeTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<ContainerLayer>();

  layer_tree().set_root_layer(layer);
  layer_tree().Preroll(frame());
  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_TRUE(layer->is_empty());

  layer_tree().Paint(frame());
}

TEST_F(LayerTreeTest, PaintBeforePrerollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  SkPath child_path;
  child_path.addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  layer_tree().set_root_layer(layer);
  EXPECT_EQ(mock_layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_TRUE(mock_layer->is_empty());
  EXPECT_TRUE(layer->is_empty());

  layer_tree().Paint(frame());
  EXPECT_EQ(mock_canvas().draw_calls(), std::vector<MockCanvas::DrawCall>());
}

TEST_F(LayerTreeTest, Simple) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const SkPaint child_paint = SkPaint(SkColors::kCyan);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  layer_tree().set_root_layer(layer);
  layer_tree().Preroll(frame());
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
  EXPECT_FALSE(mock_layer->is_empty());
  EXPECT_FALSE(layer->is_empty());
  EXPECT_EQ(mock_layer->parent_matrix(), root_transform());

  layer_tree().Paint(frame());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{child_path, child_paint}}}));
}

TEST_F(LayerTreeTest, Multiple) {
  const SkPath child_path1 = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path2 = SkPath().addRect(8.0f, 2.0f, 16.5f, 14.5f);
  const SkPaint child_paint1(SkColors::kGray);
  const SkPaint child_paint2(SkColors::kGreen);
  auto mock_layer1 = std::make_shared<MockLayer>(
      child_path1, child_paint1, true /* fake_has_platform_view */);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect expected_total_bounds = child_path1.getBounds();
  expected_total_bounds.join(child_path2.getBounds());
  layer_tree().set_root_layer(layer);
  layer_tree().Preroll(frame());
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_total_bounds);
  EXPECT_FALSE(mock_layer1->is_empty());
  EXPECT_FALSE(mock_layer2->is_empty());
  EXPECT_FALSE(layer->is_empty());
  EXPECT_EQ(mock_layer1->parent_matrix(), root_transform());
  EXPECT_EQ(mock_layer2->parent_matrix(), root_transform());
  EXPECT_EQ(mock_layer1->parent_cull_rect(), kGiantRect);
  EXPECT_EQ(mock_layer2->parent_cull_rect(),
            kGiantRect);  // Siblings are independent

  layer_tree().Paint(frame());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{0, MockCanvas::DrawPathData{
                                               child_path2, child_paint2}}}));
}

TEST_F(LayerTreeTest, MultipleWithEmpty) {
  const SkPath child_path1 = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPaint child_paint1(SkColors::kGray);
  const SkPaint child_paint2(SkColors::kGreen);
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(SkPath(), child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  layer_tree().set_root_layer(layer);
  layer_tree().Preroll(frame());
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), SkPath().getBounds());
  EXPECT_EQ(layer->paint_bounds(), child_path1.getBounds());
  EXPECT_FALSE(mock_layer1->is_empty());
  EXPECT_TRUE(mock_layer2->is_empty());
  EXPECT_FALSE(layer->is_empty());
  EXPECT_EQ(mock_layer1->parent_matrix(), root_transform());
  EXPECT_EQ(mock_layer2->parent_matrix(), root_transform());
  EXPECT_EQ(mock_layer1->parent_cull_rect(), kGiantRect);
  EXPECT_EQ(mock_layer2->parent_cull_rect(), kGiantRect);

  layer_tree().Paint(frame());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{child_path1, child_paint1}}}));
}

TEST_F(LayerTreeTest, NeedsSystemComposite) {
  const SkPath child_path1 = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path2 = SkPath().addRect(8.0f, 2.0f, 16.5f, 14.5f);
  const SkPaint child_paint1(SkColors::kGray);
  const SkPaint child_paint2(SkColors::kGreen);
  auto mock_layer1 = std::make_shared<MockLayer>(
      child_path1, child_paint1, false /* fake_has_platform_view */);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect expected_total_bounds = child_path1.getBounds();
  expected_total_bounds.join(child_path2.getBounds());
  layer_tree().set_root_layer(layer);
  layer_tree().Preroll(frame());
  EXPECT_EQ(mock_layer1->paint_bounds(), child_path1.getBounds());
  EXPECT_EQ(mock_layer2->paint_bounds(), child_path2.getBounds());
  EXPECT_EQ(layer->paint_bounds(), expected_total_bounds);
  EXPECT_FALSE(mock_layer1->is_empty());
  EXPECT_FALSE(mock_layer2->is_empty());
  EXPECT_FALSE(layer->is_empty());
  EXPECT_EQ(mock_layer1->parent_matrix(), root_transform());
  EXPECT_EQ(mock_layer2->parent_matrix(), root_transform());
  EXPECT_EQ(mock_layer1->parent_cull_rect(), kGiantRect);
  EXPECT_EQ(mock_layer2->parent_cull_rect(), kGiantRect);

  layer_tree().Paint(frame());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{0, MockCanvas::DrawPathData{
                                               child_path2, child_paint2}}}));
}

TEST_F(LayerTreeTest, PrerollContextInitialization) {
  // This EXPECT macro will ensure that if any fields get added to the
  // PrerollContext that this test must be revisited and updated.
  // If any fields get removed or replaced, then the expect_defaults closure
  // will fail to compile, again bringing attention to updating this test.
  EXPECT_EQ(sizeof(PrerollContext), size_t(112));

  MutatorsStack mock_mutators;
  FixedRefreshRateStopwatch mock_raster_time;
  FixedRefreshRateStopwatch mock_ui_time;
  TextureRegistry mock_registry;

  auto expect_defaults = [&mock_mutators, &mock_raster_time, &mock_ui_time,
                          &mock_registry](const PrerollContext& context) {
    EXPECT_EQ(context.raster_cache, nullptr);
    EXPECT_EQ(context.gr_context, nullptr);
    EXPECT_EQ(context.view_embedder, nullptr);
    EXPECT_EQ(&context.mutators_stack, &mock_mutators);
    EXPECT_EQ(context.dst_color_space, nullptr);
    EXPECT_EQ(context.cull_rect, SkRect::MakeEmpty());
    EXPECT_EQ(context.surface_needs_readback, false);

    EXPECT_EQ(&context.raster_time, &mock_raster_time);
    EXPECT_EQ(&context.ui_time, &mock_ui_time);
    EXPECT_EQ(&context.texture_registry, &mock_registry);
    EXPECT_EQ(context.checkerboard_offscreen_layers, false);
    EXPECT_EQ(context.frame_device_pixel_ratio, 1.0f);

    EXPECT_EQ(context.has_platform_view, false);
    EXPECT_EQ(context.has_texture_layer, false);

    EXPECT_EQ(context.subtree_can_inherit_opacity, false);
    EXPECT_EQ(context.raster_cached_entries, nullptr);
  };

  // These 4 initializers are required because they are handled by reference
  PrerollContext context{
      .mutators_stack = mock_mutators,
      .raster_time = mock_raster_time,
      .ui_time = mock_ui_time,
      .texture_registry = mock_registry,
  };
  expect_defaults(context);
}

TEST_F(LayerTreeTest, PaintContextInitialization) {
  // This EXPECT macro will ensure that if any fields get added to the
  // PaintContext that this test must be revisited and updated.
  // If any fields get removed or replaced, then the expect_defaults closure
  // will fail to compile, again bringing attention to updating this test.
  EXPECT_EQ(sizeof(PaintContext), size_t(104));

  FixedRefreshRateStopwatch mock_raster_time;
  FixedRefreshRateStopwatch mock_ui_time;
  TextureRegistry mock_registry;

  auto expect_defaults = [&mock_raster_time, &mock_ui_time,
                          &mock_registry](const PaintContext& context) {
    EXPECT_EQ(context.internal_nodes_canvas, nullptr);
    EXPECT_EQ(context.leaf_nodes_canvas, nullptr);
    EXPECT_EQ(context.gr_context, nullptr);
    EXPECT_EQ(context.view_embedder, nullptr);
    EXPECT_EQ(&context.raster_time, &mock_raster_time);
    EXPECT_EQ(&context.ui_time, &mock_ui_time);
    EXPECT_EQ(&context.texture_registry, &mock_registry);
    EXPECT_EQ(context.raster_cache, nullptr);
    EXPECT_EQ(context.checkerboard_offscreen_layers, false);
    EXPECT_EQ(context.frame_device_pixel_ratio, 1.0f);

    EXPECT_EQ(context.enable_leaf_layer_tracing, false);
    EXPECT_EQ(context.layer_snapshot_store, nullptr);

    EXPECT_EQ(context.inherited_opacity, SK_Scalar1);
    EXPECT_EQ(context.leaf_nodes_builder, nullptr);
  };

  // These 4 initializers are required because they are handled by reference
  PaintContext context{
      .raster_time = mock_raster_time,
      .ui_time = mock_ui_time,
      .texture_registry = mock_registry,
  };
  expect_defaults(context);
}

}  // namespace testing
}  // namespace flutter

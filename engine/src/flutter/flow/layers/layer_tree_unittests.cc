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
      : root_transform_(SkMatrix::Translate(1.0f, 1.0f)),
        scoped_frame_(compositor_context_.AcquireFrame(nullptr,
                                                       &mock_canvas(),
                                                       nullptr,
                                                       root_transform_,
                                                       false,
                                                       true,
                                                       nullptr,
                                                       nullptr)) {}

  CompositorContext::ScopedFrame& frame() { return *scoped_frame_.get(); }
  const SkMatrix& root_transform() { return root_transform_; }

  std::unique_ptr<LayerTree> BuildLayerTree(const LayerTree::Config& config) {
    return std::make_unique<LayerTree>(config, SkISize::Make(64, 64));
  }

 private:
  CompositorContext compositor_context_;
  SkMatrix root_transform_;
  std::unique_ptr<CompositorContext::ScopedFrame> scoped_frame_;
};

TEST_F(LayerTreeTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<ContainerLayer>();

  auto layer_tree = BuildLayerTree(LayerTree::Config{
      .root_layer = layer,
  });
  layer_tree->Preroll(frame());
  EXPECT_EQ(layer->paint_bounds(), SkRect::MakeEmpty());
  EXPECT_TRUE(layer->is_empty());

  layer_tree->Paint(frame());
}

TEST_F(LayerTreeTest, PaintBeforePrerollDies) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  SkPath child_path;
  child_path.addRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  auto layer_tree = BuildLayerTree(LayerTree::Config{
      .root_layer = layer,
  });
  EXPECT_EQ(mock_layer->paint_bounds(), kEmptyRect);
  EXPECT_EQ(layer->paint_bounds(), kEmptyRect);
  EXPECT_TRUE(mock_layer->is_empty());
  EXPECT_TRUE(layer->is_empty());

  layer_tree->Paint(frame());
  EXPECT_EQ(mock_canvas().draw_calls(), std::vector<MockCanvas::DrawCall>());
}

TEST_F(LayerTreeTest, Simple) {
  const SkRect child_bounds = SkRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path = SkPath().addRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kCyan());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer);

  auto layer_tree = BuildLayerTree(LayerTree::Config{
      .root_layer = layer,
  });
  layer_tree->Preroll(frame());
  EXPECT_EQ(mock_layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->paint_bounds(), mock_layer->paint_bounds());
  EXPECT_FALSE(mock_layer->is_empty());
  EXPECT_FALSE(layer->is_empty());
  EXPECT_EQ(mock_layer->parent_matrix(), root_transform());

  layer_tree->Paint(frame());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{child_path, child_paint}}}));
}

TEST_F(LayerTreeTest, Multiple) {
  const SkPath child_path1 = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path2 = SkPath().addRect(8.0f, 2.0f, 16.5f, 14.5f);
  const DlPaint child_paint1 = DlPaint(DlColor::kMidGrey());
  const DlPaint child_paint2 = DlPaint(DlColor::kGreen());
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  mock_layer1->set_fake_has_platform_view(true);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect expected_total_bounds = child_path1.getBounds();
  expected_total_bounds.join(child_path2.getBounds());
  auto layer_tree = BuildLayerTree(LayerTree::Config{
      .root_layer = layer,
  });
  layer_tree->Preroll(frame());
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

  layer_tree->Paint(frame());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{0, MockCanvas::DrawPathData{
                                               child_path2, child_paint2}}}));
}

TEST_F(LayerTreeTest, MultipleWithEmpty) {
  const SkPath child_path1 = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  const DlPaint child_paint1 = DlPaint(DlColor::kMidGrey());
  const DlPaint child_paint2 = DlPaint(DlColor::kGreen());
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(SkPath(), child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  auto layer_tree = BuildLayerTree(LayerTree::Config{
      .root_layer = layer,
  });
  layer_tree->Preroll(frame());
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

  layer_tree->Paint(frame());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{child_path1, child_paint1}}}));
}

TEST_F(LayerTreeTest, NeedsSystemComposite) {
  const SkPath child_path1 = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  const SkPath child_path2 = SkPath().addRect(8.0f, 2.0f, 16.5f, 14.5f);
  const DlPaint child_paint1 = DlPaint(DlColor::kMidGrey());
  const DlPaint child_paint2 = DlPaint(DlColor::kGreen());
  auto mock_layer1 = std::make_shared<MockLayer>(child_path1, child_paint1);
  auto mock_layer2 = std::make_shared<MockLayer>(child_path2, child_paint2);
  auto layer = std::make_shared<ContainerLayer>();
  layer->Add(mock_layer1);
  layer->Add(mock_layer2);

  SkRect expected_total_bounds = child_path1.getBounds();
  expected_total_bounds.join(child_path2.getBounds());
  auto layer_tree = BuildLayerTree(LayerTree::Config{
      .root_layer = layer,
  });
  layer_tree->Preroll(frame());
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

  layer_tree->Paint(frame());
  EXPECT_EQ(
      mock_canvas().draw_calls(),
      std::vector({MockCanvas::DrawCall{
                       0, MockCanvas::DrawPathData{child_path1, child_paint1}},
                   MockCanvas::DrawCall{0, MockCanvas::DrawPathData{
                                               child_path2, child_paint2}}}));
}

TEST_F(LayerTreeTest, PrerollContextInitialization) {
  LayerStateStack state_stack;
  state_stack.set_preroll_delegate(kGiantRect, SkMatrix::I());
  FixedRefreshRateStopwatch mock_raster_time;
  FixedRefreshRateStopwatch mock_ui_time;
  std::shared_ptr<TextureRegistry> mock_registry;

  auto expect_defaults = [&state_stack, &mock_raster_time, &mock_ui_time,
                          &mock_registry](const PrerollContext& context) {
    EXPECT_EQ(context.raster_cache, nullptr);
    EXPECT_EQ(context.gr_context, nullptr);
    EXPECT_EQ(context.view_embedder, nullptr);
    EXPECT_EQ(&context.state_stack, &state_stack);
    EXPECT_EQ(context.dst_color_space, nullptr);
    EXPECT_EQ(context.state_stack.device_cull_rect(), kGiantRect);
    EXPECT_EQ(context.state_stack.transform_3x3(), SkMatrix::I());
    EXPECT_EQ(context.state_stack.transform_4x4(), SkM44());
    EXPECT_EQ(context.surface_needs_readback, false);

    EXPECT_EQ(&context.raster_time, &mock_raster_time);
    EXPECT_EQ(&context.ui_time, &mock_ui_time);
    EXPECT_EQ(context.texture_registry.get(), mock_registry.get());

    EXPECT_EQ(context.has_platform_view, false);
    EXPECT_EQ(context.has_texture_layer, false);

    EXPECT_EQ(context.renderable_state_flags, 0);
    EXPECT_EQ(context.raster_cached_entries, nullptr);
  };

  // These 4 initializers are required because they are handled by reference
  PrerollContext context{
      .state_stack = state_stack,
      .raster_time = mock_raster_time,
      .ui_time = mock_ui_time,
      .texture_registry = mock_registry,
  };
  expect_defaults(context);
}

TEST_F(LayerTreeTest, PaintContextInitialization) {
  LayerStateStack state_stack;
  FixedRefreshRateStopwatch mock_raster_time;
  FixedRefreshRateStopwatch mock_ui_time;
  std::shared_ptr<TextureRegistry> mock_registry;

  auto expect_defaults = [&state_stack, &mock_raster_time, &mock_ui_time,
                          &mock_registry](const PaintContext& context) {
    EXPECT_EQ(&context.state_stack, &state_stack);
    EXPECT_EQ(context.canvas, nullptr);
    EXPECT_EQ(context.gr_context, nullptr);
    EXPECT_EQ(context.view_embedder, nullptr);
    EXPECT_EQ(&context.raster_time, &mock_raster_time);
    EXPECT_EQ(&context.ui_time, &mock_ui_time);
    EXPECT_EQ(context.texture_registry.get(), mock_registry.get());
    EXPECT_EQ(context.raster_cache, nullptr);
    EXPECT_EQ(context.state_stack.checkerboard_func(), nullptr);

    EXPECT_EQ(context.enable_leaf_layer_tracing, false);
    EXPECT_EQ(context.layer_snapshot_store, nullptr);
  };

  // These 4 initializers are required because they are handled by reference
  PaintContext context{
      .state_stack = state_stack,
      .raster_time = mock_raster_time,
      .ui_time = mock_ui_time,
      .texture_registry = mock_registry,
  };
  expect_defaults(context);
}

}  // namespace testing
}  // namespace flutter

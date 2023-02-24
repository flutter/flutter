// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/testing/mock_layer.h"

#include "flutter/flow/testing/layer_test.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/mock_canvas.h"

namespace flutter {
namespace testing {

using MockLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(MockLayerTest, PaintBeforePrerollDies) {
  SkPath path = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  auto layer = std::make_shared<MockLayer>(path, DlPaint());

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(MockLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<MockLayer>(SkPath(), DlPaint());

  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), SkPath().getBounds());

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(MockLayerTest, SimpleParams) {
  const SkPath path = SkPath().addRect(5.0f, 6.0f, 20.5f, 21.5f);
  const DlPaint paint = DlPaint(DlColor::kBlue());
  const SkMatrix start_matrix = SkMatrix::Translate(1.0f, 2.0f);
  const SkMatrix scale_matrix = SkMatrix::Scale(0.5f, 0.5f);
  const SkMatrix combined_matrix = SkMatrix::Concat(start_matrix, scale_matrix);
  const SkRect local_cull_rect = SkRect::MakeWH(5.0f, 5.0f);
  const SkRect device_cull_rect = combined_matrix.mapRect(local_cull_rect);
  const bool parent_has_platform_view = true;
  auto layer = std::make_shared<MockLayer>(path, paint);

  preroll_context()->state_stack.set_preroll_delegate(device_cull_rect,
                                                      start_matrix);
  auto mutator = preroll_context()->state_stack.save();
  mutator.transform(scale_matrix);
  preroll_context()->has_platform_view = parent_has_platform_view;
  layer->Preroll(preroll_context());
  EXPECT_EQ(preroll_context()->has_platform_view, false);
  EXPECT_EQ(layer->paint_bounds(), path.getBounds());
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(layer->parent_mutators(), std::vector{Mutator(scale_matrix)});
  EXPECT_EQ(layer->parent_matrix(), combined_matrix);
  EXPECT_EQ(layer->parent_cull_rect(), local_cull_rect);
  EXPECT_EQ(layer->parent_has_platform_view(), parent_has_platform_view);

  layer->Paint(paint_context());
  EXPECT_EQ(mock_canvas().draw_calls(),
            std::vector({MockCanvas::DrawCall{
                0, MockCanvas::DrawPathData{path, paint}}}));
}

TEST_F(MockLayerTest, FakePlatformView) {
  auto layer = std::make_shared<MockLayer>(SkPath(), DlPaint());
  layer->set_fake_has_platform_view(true);
  EXPECT_EQ(preroll_context()->has_platform_view, false);

  layer->Preroll(preroll_context());
  EXPECT_EQ(preroll_context()->has_platform_view, true);
}

TEST_F(MockLayerTest, SaveLayerOnLeafNodesCanvas) {
  auto layer = std::make_shared<MockLayer>(SkPath(), DlPaint());
  layer->set_fake_has_platform_view(true);
  EXPECT_EQ(preroll_context()->has_platform_view, false);

  layer->Preroll(preroll_context());
  EXPECT_EQ(preroll_context()->has_platform_view, true);
}

TEST_F(MockLayerTest, OpacityInheritance) {
  auto path1 = SkPath().addRect({10, 10, 30, 30});
  PrerollContext* context = preroll_context();

  auto mock1 = std::make_shared<MockLayer>(path1);
  mock1->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags, 0);

  auto mock2 = MockLayer::MakeOpacityCompatible(path1);
  mock2->Preroll(context);
  EXPECT_EQ(context->renderable_state_flags,
            LayerStateStack::kCallerCanApplyOpacity);
}

TEST_F(MockLayerTest, FlagGetSet) {
  auto mock_layer = std::make_shared<MockLayer>(SkPath());

  EXPECT_EQ(mock_layer->parent_has_platform_view(), false);
  mock_layer->set_parent_has_platform_view(true);
  EXPECT_EQ(mock_layer->parent_has_platform_view(), true);

  EXPECT_EQ(mock_layer->parent_has_texture_layer(), false);
  mock_layer->set_parent_has_texture_layer(true);
  EXPECT_EQ(mock_layer->parent_has_texture_layer(), true);

  EXPECT_EQ(mock_layer->fake_has_platform_view(), false);
  mock_layer->set_fake_has_platform_view(true);
  EXPECT_EQ(mock_layer->fake_has_platform_view(), true);

  EXPECT_EQ(mock_layer->fake_reads_surface(), false);
  mock_layer->set_fake_reads_surface(true);
  EXPECT_EQ(mock_layer->fake_reads_surface(), true);

  EXPECT_EQ(mock_layer->fake_opacity_compatible(), false);
  mock_layer->set_fake_opacity_compatible(true);
  EXPECT_EQ(mock_layer->fake_opacity_compatible(), true);

  EXPECT_EQ(mock_layer->fake_has_texture_layer(), false);
  mock_layer->set_fake_has_texture_layer(true);
  EXPECT_EQ(mock_layer->fake_has_texture_layer(), true);
}

}  // namespace testing
}  // namespace flutter

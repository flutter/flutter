// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/overscroll_stretch_layer.h"

#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/platform_view_layer.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/flow/testing/diff_context_test.h"
#include "flutter/flow/testing/layer_test.h"
#include "flutter/flow/testing/mock_embedder.h"
#include "flutter/flow/testing/mock_layer.h"
#include "flutter/fml/macros.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using OverscrollStretchLayerTest = LayerTest;

#ifndef NDEBUG
TEST_F(OverscrollStretchLayerTest, PaintingEmptyLayerDies) {
  auto layer = std::make_shared<OverscrollStretchLayer>(nullptr, 0.0f, 0.0f,
                                                        1.0f, 0.7f);

  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), DlRect());
  EXPECT_FALSE(layer->needs_painting(paint_context()));

  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}

TEST_F(OverscrollStretchLayerTest, PaintBeforePrerollDies) {
  const DlRect child_bounds = DlRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const DlPath child_path = DlPath::MakeRect(child_bounds);
  auto mock_layer = std::make_shared<MockLayer>(child_path);
  auto layer = std::make_shared<OverscrollStretchLayer>(nullptr, 0.0f, 0.0f,
                                                        1.0f, 0.7f);
  layer->Add(mock_layer);

  EXPECT_EQ(layer->paint_bounds(), DlRect());
  EXPECT_EQ(layer->child_paint_bounds(), DlRect());
  EXPECT_DEATH_IF_SUPPORTED(layer->Paint(paint_context()),
                            "needs_painting\\(context\\)");
}
#endif

TEST_F(OverscrollStretchLayerTest, Getters) {
  auto dl_image_filter = DlImageFilter::MakeMatrix(
      DlMatrix::MakeTranslation({1.0, 2.0}), DlImageSampling::kMipmapLinear);
  auto layer = std::make_shared<OverscrollStretchLayer>(
      dl_image_filter, 0.3f, 0.6f, 1.2f, 0.8f);

  EXPECT_FLOAT_EQ(layer->overscroll_x(), 0.3f);
  EXPECT_FLOAT_EQ(layer->overscroll_y(), 0.6f);
  EXPECT_FLOAT_EQ(layer->max_stretch_intensity(), 1.2f);
  EXPECT_FLOAT_EQ(layer->interpolation_strength(), 0.8f);
}

TEST_F(OverscrollStretchLayerTest, EmptyFilter) {
  const DlMatrix initial_transform = DlMatrix::MakeTranslation({0.5f, 1.0f});
  const DlRect child_bounds = DlRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const DlPath child_path = DlPath::MakeRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<OverscrollStretchLayer>(nullptr, 0.0f, 0.0f,
                                                        1.0f, 0.7f);
  layer->Add(mock_layer);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), child_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);

  layer->Paint(display_list_paint_context());
  DisplayListBuilder expected_builder;
  /* (OverscrollStretch)layer::Paint */ {
    expected_builder.Save();
    /* mock_layer1::Paint */ {
      expected_builder.DrawPath(child_path, child_paint);
    }
    expected_builder.Restore();
  }
  EXPECT_TRUE(DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
}

TEST_F(OverscrollStretchLayerTest, SimpleFilter) {
  const DlMatrix initial_transform = DlMatrix::MakeTranslation({0.5f, 1.0f});
  const DlRect child_bounds = DlRect::MakeLTRB(5.0f, 6.0f, 20.5f, 21.5f);
  const DlPath child_path = DlPath::MakeRect(child_bounds);
  const DlPaint child_paint = DlPaint(DlColor::kYellow());
  auto dl_image_filter = DlImageFilter::MakeMatrix(
      DlMatrix::MakeTranslation({1.0, 2.0}), DlImageSampling::kMipmapLinear);
  auto mock_layer = std::make_shared<MockLayer>(child_path, child_paint);
  auto layer = std::make_shared<OverscrollStretchLayer>(
      dl_image_filter, 0.1f, 0.2f, 1.0f, 0.7f);
  layer->Add(mock_layer);

  const DlRect child_rounded_bounds =
      DlRect::MakeLTRB(6.0f, 8.0f, 22.0f, 24.0f);

  preroll_context()->state_stack.set_preroll_delegate(initial_transform);
  layer->Preroll(preroll_context());
  EXPECT_EQ(layer->paint_bounds(), child_rounded_bounds);
  EXPECT_EQ(layer->child_paint_bounds(), child_bounds);
  EXPECT_TRUE(layer->needs_painting(paint_context()));
  EXPECT_EQ(mock_layer->parent_matrix(), initial_transform);
}

namespace {
class StretchMockViewEmbedder : public MockViewEmbedder {
 public:
  void PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<EmbeddedViewParams> params) override {
    MockViewEmbedder::PrerollCompositeEmbeddedView(view_id, nullptr);
    view_params_.emplace_back(std::move(params));
  }

  const std::vector<std::unique_ptr<EmbeddedViewParams>>& view_params() const {
    return view_params_;
  }

 private:
  std::vector<std::unique_ptr<EmbeddedViewParams>> view_params_;
};
}  // namespace

TEST_F(OverscrollStretchLayerTest, PlatformViewMutatorStack) {
  const DlPoint layer_offset = DlPoint(10.0f, 20.0f);
  const DlSize layer_size = DlSize(100.0f, 200.0f);
  const int64_t view_id = 42;
  auto platform_view_layer =
      std::make_shared<PlatformViewLayer>(layer_offset, layer_size, view_id);

  auto dl_image_filter = DlImageFilter::MakeMatrix(
      DlMatrix::MakeTranslation({1.0, 2.0}), DlImageSampling::kMipmapLinear);
  auto stretch_layer = std::make_shared<OverscrollStretchLayer>(
      dl_image_filter, 0.25f, 0.5f, 1.0f, 0.75f);
  stretch_layer->Add(platform_view_layer);

  StretchMockViewEmbedder embedder;
  preroll_context()->view_embedder = &embedder;

  stretch_layer->Preroll(preroll_context());
  EXPECT_TRUE(preroll_context()->has_platform_view);
  EXPECT_TRUE(stretch_layer->subtree_has_platform_view());

  ASSERT_EQ(embedder.prerolled_views().size(), 1u);
  EXPECT_EQ(embedder.prerolled_views()[0], view_id);

  ASSERT_EQ(embedder.view_params().size(), 1u);
  const auto& params = embedder.view_params()[0];
  ASSERT_NE(params, nullptr);

  const MutatorsStack& mutators = params->mutatorsStack();
  auto iter = mutators.Begin();
  ASSERT_NE(iter, mutators.End());
  EXPECT_EQ((*iter)->GetType(), MutatorType::kOverscrollStretch);
  const OverscrollStretchMutation& mutation = (*iter)->GetOverscrollStretch();
  EXPECT_FLOAT_EQ(mutation.overscroll_x, 0.25f);
  EXPECT_FLOAT_EQ(mutation.overscroll_y, 0.5f);
  EXPECT_FLOAT_EQ(mutation.max_stretch_intensity, 1.0f);
  EXPECT_FLOAT_EQ(mutation.interpolation_strength, 0.75f);
}

using OverscrollStretchLayerDiffTest = DiffContextTest;

TEST_F(OverscrollStretchLayerDiffTest, DiffWhenOverscrollChanges) {
  auto dl_blur_filter = DlImageFilter::MakeBlur(10, 10, DlTileMode::kClamp);

  MockLayerTree l1;
  auto layer1 = std::make_shared<OverscrollStretchLayer>(
      dl_blur_filter, 0.1f, 0.2f, 1.0f, 0.7f);
  auto path = DlPath::MakeRectLTRB(100, 100, 110, 110);
  layer1->Add(std::make_shared<MockLayer>(path));
  l1.root()->Add(layer1);

  auto damage1 = DiffLayerTree(l1, MockLayerTree());
  EXPECT_EQ(damage1.frame_damage, DlIRect::MakeLTRB(70, 70, 140, 140));

  MockLayerTree l2;
  auto layer2 = std::make_shared<OverscrollStretchLayer>(
      dl_blur_filter, 0.3f, 0.4f, 1.0f, 0.7f);
  layer2->Add(std::make_shared<MockLayer>(path));
  l2.root()->Add(layer2);

  auto damage2 = DiffLayerTree(l2, l1);
  EXPECT_EQ(damage2.frame_damage, DlIRect::MakeLTRB(70, 70, 140, 140));
}

}  // namespace testing
}  // namespace flutter

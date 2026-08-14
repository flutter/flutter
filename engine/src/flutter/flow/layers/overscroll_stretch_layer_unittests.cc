// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/overscroll_stretch_layer.h"

#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/transform_layer.h"
#include "flutter/flow/testing/diff_context_test.h"
#include "flutter/flow/testing/layer_test.h"
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

}  // namespace testing
}  // namespace flutter

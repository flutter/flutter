// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"
#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/layers/clip_rrect_layer.h"
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

  layer->Paint(display_list_paint_context());
  {
    DisplayListBuilder expected_builder;
    /* (ClipRect)layer::Paint */ {
      expected_builder.Save();
      {
        expected_builder.ClipRect(layer_bounds, DlCanvas::ClipOp::kIntersect,
                                  true);
        expected_builder.SaveLayer(&child_bounds);
        {
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(child_path, child_paint);
          }
        }
        expected_builder.Restore();
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(
        DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
  }

  layer->Paint(checkerboard_context());
  {
    DisplayListBuilder expected_builder;
    /* (ClipRect)layer::Paint */ {
      expected_builder.Save();
      {
        expected_builder.ClipRect(layer_bounds, DlCanvas::ClipOp::kIntersect,
                                  true);
        expected_builder.SaveLayer(&child_bounds);
        {
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(child_path, child_paint);
          }
          expected_builder.DrawRect(child_path.getBounds(),
                                    checkerboard_paint());
        }
        expected_builder.Restore();
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(DisplayListsEQ_Verbose(checkerboard_display_list(),
                                       expected_builder.Build()));
  }
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

  layer->Paint(display_list_paint_context());
  {
    DisplayListBuilder expected_builder;
    /* (ClipRect)layer::Paint */ {
      expected_builder.Save();
      {
        expected_builder.ClipPath(layer_path, DlCanvas::ClipOp::kIntersect,
                                  true);
        expected_builder.SaveLayer(&child_bounds);
        {
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(child_path, child_paint);
          }
        }
        expected_builder.Restore();
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(
        DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
  }

  layer->Paint(checkerboard_context());
  {
    DisplayListBuilder expected_builder;
    /* (ClipRect)layer::Paint */ {
      expected_builder.Save();
      {
        expected_builder.ClipPath(layer_path, DlCanvas::ClipOp::kIntersect,
                                  true);
        expected_builder.SaveLayer(&child_bounds);
        {
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(child_path, child_paint);
          }
          expected_builder.DrawRect(child_path.getBounds(),
                                    checkerboard_paint());
        }
        expected_builder.Restore();
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(DisplayListsEQ_Verbose(checkerboard_display_list(),
                                       expected_builder.Build()));
  }
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

  layer->Paint(display_list_paint_context());
  {
    DisplayListBuilder expected_builder;
    /* (ClipRect)layer::Paint */ {
      expected_builder.Save();
      {
        expected_builder.ClipRRect(layer_rrect, DlCanvas::ClipOp::kIntersect,
                                   true);
        expected_builder.SaveLayer(&child_bounds);
        {
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(child_path, child_paint);
          }
        }
        expected_builder.Restore();
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(
        DisplayListsEQ_Verbose(display_list(), expected_builder.Build()));
  }

  layer->Paint(checkerboard_context());
  {
    DisplayListBuilder expected_builder;
    /* (ClipRect)layer::Paint */ {
      expected_builder.Save();
      {
        expected_builder.ClipRRect(layer_rrect, DlCanvas::ClipOp::kIntersect,
                                   true);
        expected_builder.SaveLayer(&child_bounds);
        {
          /* mock_layer::Paint */ {
            expected_builder.DrawPath(child_path, child_paint);
          }
          expected_builder.DrawRect(child_path.getBounds(),
                                    checkerboard_paint());
        }
        expected_builder.Restore();
      }
      expected_builder.Restore();
    }
    EXPECT_TRUE(DisplayListsEQ_Verbose(checkerboard_display_list(),
                                       expected_builder.Build()));
  }
}

#endif
}  // namespace testing
}  // namespace flutter

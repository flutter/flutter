// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/display_list/aiks_unittests.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {

using namespace flutter;

TEST_P(AiksTest, CanRenderNestedClips) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kFuchsia());

  builder.Save();
  builder.ClipPath(DlPath::MakeCircle(DlPoint(200, 400), 300));
  builder.Restore();
  builder.ClipPath(DlPath::MakeCircle(DlPoint(600, 400), 300));
  builder.ClipPath(DlPath::MakeCircle(DlPoint(400, 600), 300));
  builder.DrawRect(DlRect::MakeXYWH(200, 200, 400, 400), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderDifferenceClips) {
  DisplayListBuilder builder;
  builder.Translate(400, 400);

  // Limit drawing to face circle with a clip.
  builder.ClipPath(DlPath::MakeCircle(DlPoint(0, 0), 200));
  builder.Save();

  // Cut away eyes/mouth using difference clips.
  builder.ClipPath(DlPath::MakeCircle(DlPoint(-100, -50), 30),
                   DlClipOp::kDifference);
  builder.ClipPath(DlPath::MakeCircle(DlPoint(100, -50), 30),
                   DlClipOp::kDifference);

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(-100, 50));
  path_builder.QuadraticCurveTo(DlPoint(0, 150), DlPoint(100, 50));
  builder.ClipPath(path_builder.TakePath(), DlClipOp::kDifference);

  // Draw a huge yellow rectangle to prove the clipping works.
  DlPaint paint;
  paint.setColor(DlColor::kYellow());
  builder.DrawRect(DlRect::MakeCircleBounds({0, 0}, 1000), paint);

  // Remove the difference clips and draw hair that partially covers the eyes.
  builder.Restore();
  paint.setColor(DlColor::kMaroon());
  DlPathBuilder path_builder_2;
  path_builder_2.MoveTo(DlPoint(200, -200));
  path_builder_2.LineTo(DlPoint(-200, -200));
  path_builder_2.LineTo(DlPoint(-200, -40));
  path_builder_2.CubicCurveTo(DlPoint(0, -40), DlPoint(0, -80),
                              DlPoint(200, -80));

  builder.DrawPath(path_builder_2.TakePath(), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderWithContiguousClipRestores) {
  DisplayListBuilder builder;

  // Cover the whole canvas with red.
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  builder.DrawPaint(paint);

  builder.Save();

  // Append two clips, the second resulting in empty coverage.
  builder.ClipRect(DlRect::MakeXYWH(100, 100, 100, 100));
  builder.ClipRect(DlRect::MakeXYWH(300, 300, 100, 100));

  // Restore to no clips.
  builder.Restore();

  // Replace the whole canvas with green.
  paint.setColor(DlColor::kGreen());
  builder.DrawPaint(paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, ClipsUseCurrentTransform) {
  std::array<DlColor, 5> colors = {DlColor::kWhite(), DlColor::kBlack(),
                                   DlColor::kSkyBlue(), DlColor::kRed(),
                                   DlColor::kYellow()};
  DisplayListBuilder builder;
  DlPaint paint;

  builder.Translate(300, 300);
  for (int i = 0; i < 15; i++) {
    builder.Scale(0.8, 0.8);

    paint.setColor(colors[i % colors.size()]);
    builder.ClipPath(DlPath::MakeCircle(DlPoint(0, 0), 300));
    builder.DrawRect(DlRect::MakeCircleBounds({0, 0}, 300), paint);
  }
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

/// If correct, this test should draw a green circle. If any red is visible,
/// there is a depth bug.
TEST_P(AiksTest, FramebufferBlendsRespectClips) {
  DisplayListBuilder builder;

  // Clear the whole canvas with white.
  DlPaint paint;
  paint.setColor(DlColor::kWhite());
  builder.DrawPaint(paint);

  builder.ClipPath(DlPath::MakeCircle(DlPoint(150, 150), 50),
                   DlClipOp::kIntersect);

  // Draw a red rectangle that should not show through the circle clip.
  paint.setColor(DlColor::kRed());
  paint.setBlendMode(DlBlendMode::kMultiply);
  builder.DrawRect(DlRect::MakeXYWH(100, 100, 100, 100), paint);

  // Draw a green circle that shows through the clip.
  paint.setColor(DlColor::kGreen());
  paint.setBlendMode(DlBlendMode::kSrcOver);
  builder.DrawCircle(DlPoint(150, 150), 50, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderClippedBackdropFilterWithSuperellipse) {
  DisplayListBuilder root_builder;

  root_builder.Scale(GetContentScale().x, GetContentScale().y);

  // 1. Draw a dark background on the root pass.
  DlPaint bg_paint;
  bg_paint.setColor(DlColor::kBlack());
  root_builder.DrawPaint(bg_paint);

  // 2. Wrap in TransformLayer (matching CupertinoSheetTransition scale +
  // slide).
  root_builder.Save();
  root_builder.Scale(0.9f, 0.9f);
  root_builder.Translate(33.4f, 3.5f);

  // 3. Apply ClipRoundSuperellipse with top-only rounded corners (matching
  // CupertinoSheet).
  DlRect sheet_rect = DlRect::MakeXYWH(0, 42, 400, 500);
  DlRoundingRadii top_radii = {
      .top_left = {12, 12},
      .top_right = {12, 12},
      .bottom_left = {0, 0},
      .bottom_right = {0, 0},
  };
  DlRoundSuperellipse clip_rse =
      DlRoundSuperellipse::MakeRectRadii(sheet_rect, top_radii);
  root_builder.ClipRoundSuperellipse(clip_rse, DlClipOp::kIntersect);

  // 4. Wrap in OpacityLayer offset (matching CupertinoSheetRoute offset: (0,
  // 42)).
  root_builder.Save();
  root_builder.Translate(0.0f, 42.0f);

  // 5. Layer 1: DisplayListLayer for sheet body with Ink features.
  for (int i = 0; i < 5; i++) {
    DisplayListBuilder item_builder;
    DlPaint ink_paint;
    ink_paint.setColor(DlColor::RGBA(0.0f, 0.0f, 0.0f, 0.07f));
    item_builder.DrawRect(DlRect::MakeXYWH(0, i * 50, 400, 45), ink_paint);
    root_builder.DrawDisplayList(item_builder.Build());
  }

  // 6. Layer 2: BackdropFilterLayer (_glassBar).
  root_builder.Save();
  DlRect glass_rect = DlRect::MakeXYWH(20, 350, 360, 60);
  DlRoundRect glass_rrect = DlRoundRect::MakeRectXY(glass_rect, 14, 14);
  root_builder.ClipRoundRect(glass_rrect, DlClipOp::kIntersect);

  DlPaint save_paint;
  auto backdrop_filter =
      DlImageFilter::MakeBlur(12.0f, 12.0f, DlTileMode::kClamp);
  root_builder.SaveLayer(glass_rect, &save_paint, backdrop_filter.get());
  DisplayListBuilder glass_builder;
  DlPaint orange_paint;
  orange_paint.setColor(DlColor::RGBA(1.0f, 0.6f, 0.0f, 0.6f));
  glass_builder.DrawRect(glass_rect, orange_paint);
  root_builder.DrawDisplayList(glass_builder.Build());
  root_builder.Restore();  // Restore SaveLayer
  root_builder.Restore();  // Restore glass clip

  // 7. Layer 3: DisplayListLayer for Scaffold AppBar / header drawn AFTER
  // backdrop filter.
  DisplayListBuilder appbar_builder;
  DlPaint white_paint;
  white_paint.setColor(DlColor::kWhite());
  appbar_builder.DrawRect(DlRect::MakeXYWH(0, 0, 400, 80), white_paint);
  root_builder.DrawDisplayList(appbar_builder.Build());

  root_builder.Restore();  // Restore OpacityLayer offset
  root_builder.Restore();  // Restore TransformLayer

  ASSERT_TRUE(OpenPlaygroundHere(root_builder.Build()));
}

}  // namespace testing
}  // namespace impeller

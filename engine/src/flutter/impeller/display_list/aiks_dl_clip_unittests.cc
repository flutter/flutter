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

TEST_P(AiksTest, DilatedContentOutsideClip) {
  SetWindowSize(impeller::ISize(160, 100));
  DisplayListBuilder builder;
  builder.DrawColor(DlColor::kBlack(), DlBlendMode::kSrc);
  builder.ClipRect(DlRect::MakeXYWH(20, 20, 100, 60));

  DlPaint layer_paint;
  layer_paint.setImageFilter(DlImageFilter::MakeDilate(10, 10));
  builder.SaveLayer(DlRect::MakeXYWH(0, 0, 160, 100), &layer_paint);
  // The rectangle is outside the clip, but its dilated right edge is inside.
  builder.DrawRect(DlRect::MakeXYWH(15, 45, 4, 10),
                   DlPaint().setColor(DlColor::kWhite()));
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderClippedBackdropFilterWithSuperellipse) {
  SetWindowSize({400, 400});
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  builder.DrawPaint(DlPaint(DlColor::kBlack()));

  // Clip to a centered superellipse with large rounded corners.
  DlRect rect = DlRect::MakeXYWH(50, 50, 300, 300);
  builder.ClipRoundSuperellipse(DlRoundSuperellipse::MakeRectXY(rect, 80, 80));

  // Draw backdrop content inside a child DisplayList with a containing
  // ClipRect; restoring its scope must preserve the parent superellipse clip.
  DisplayListBuilder child_builder;
  child_builder.ClipRect(DlRect::MakeXYWH(0, 0, 400, 400));
  child_builder.DrawRect(DlRect::MakeXYWH(50, 50, 150, 300),
                         DlPaint(DlColor::kCornflowerBlue()));
  child_builder.DrawRect(DlRect::MakeXYWH(200, 50, 150, 300),
                         DlPaint(DlColor::kOrange()));
  builder.DrawDisplayList(child_builder.Build());

  // Apply a BackdropFilter with a translucent white fill across the full rect.
  // Its corners remain rounded only if the superellipse clip is replayed.
  auto filter = DlImageFilter::MakeBlur(20.0f, 20.0f, DlTileMode::kClamp);
  builder.SaveLayer(rect, nullptr, filter.get());
  builder.DrawPaint(DlPaint(DlColor::kWhite().withAlpha(160)));
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller

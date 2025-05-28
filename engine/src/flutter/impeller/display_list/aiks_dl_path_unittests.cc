// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/dl_sampling_options.h"
#include "display_list/dl_tile_mode.h"
#include "display_list/effects/dl_color_source.h"
#include "display_list/effects/dl_mask_filter.h"
#include "flutter/impeller/display_list/aiks_unittests.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/testing/testing.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/playground/widgets.h"
#include "impeller/tessellator/path_tessellator.h"

namespace impeller {
namespace testing {

using namespace flutter;

TEST_P(AiksTest, RotateColorFilteredPath) {
  DisplayListBuilder builder;
  builder.Transform(DlMatrix::MakeTranslation(DlPoint(300, 300)) *
                    DlMatrix::MakeRotationZ(DlDegrees(90)));

  DlPathBuilder arrow_stem;
  DlPathBuilder arrow_head;

  arrow_stem.MoveTo(DlPoint(120, 190)).LineTo(DlPoint(120, 50));
  arrow_head.MoveTo(DlPoint(50, 120))
      .LineTo(DlPoint(120, 190))
      .LineTo(DlPoint(190, 120));

  auto filter =
      DlColorFilter::MakeBlend(DlColor::kAliceBlue(), DlBlendMode::kSrcIn);

  DlPaint paint;
  paint.setStrokeWidth(15.0);
  paint.setStrokeCap(DlStrokeCap::kRound);
  paint.setStrokeJoin(DlStrokeJoin::kRound);
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setColorFilter(filter);
  paint.setColor(DlColor::kBlack());

  builder.DrawPath(arrow_stem.TakePath(), paint);
  builder.DrawPath(arrow_head.TakePath(), paint);

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

TEST_P(AiksTest, CanRenderStrokes) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(20);
  paint.setDrawStyle(DlDrawStyle::kStroke);

  builder.DrawPath(DlPath::MakeLine(DlPoint(200, 100), DlPoint(800, 100)),
                   paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderCurvedStrokes) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(25);
  paint.setDrawStyle(DlDrawStyle::kStroke);

  builder.DrawPath(DlPath::MakeCircle(DlPoint(500, 500), 250), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderThickCurvedStrokes) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(100);
  paint.setDrawStyle(DlDrawStyle::kStroke);

  builder.DrawPath(DlPath::MakeCircle(DlPoint(100, 100), 50), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderThinCurvedStrokes) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(0.01);
  paint.setDrawStyle(DlDrawStyle::kStroke);

  builder.DrawPath(DlPath::MakeCircle(DlPoint(100, 100), 50), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderStrokePathThatEndsAtSharpTurn) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(200);
  paint.setDrawStyle(DlDrawStyle::kStroke);

  DlPath path = DlPath::MakeArc(DlRect::MakeXYWH(100, 100, 200, 200),  //
                                DlDegrees(0), DlDegrees(90), false);

  builder.DrawPath(path, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderStrokePathWithCubicLine) {
  DisplayListBuilder builder;

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(20);
  paint.setDrawStyle(DlDrawStyle::kStroke);

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(0, 200));
  path_builder.CubicCurveTo(DlPoint(50, 400), DlPoint(350, 0),
                            DlPoint(400, 200));

  builder.DrawPath(path_builder.TakePath(), paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderQuadraticStrokeWithInstantTurn) {
  DisplayListBuilder builder;

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(50);
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeCap(DlStrokeCap::kRound);

  // Should draw a diagonal pill shape. If flat on either end, the stroke is
  // rendering wrong.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(250, 250));
  path_builder.QuadraticCurveTo(DlPoint(100, 100), DlPoint(250, 250));

  builder.DrawPath(path_builder.TakePath(), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderFilledConicPaths) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setDrawStyle(DlDrawStyle::kFill);

  DlPaint reference_paint;
  reference_paint.setColor(DlColor::kGreen());
  reference_paint.setDrawStyle(DlDrawStyle::kFill);

  DlPathBuilder path_builder;
  DlPathBuilder reference_builder;

  // weight of 1.0 is just a quadratic bezier
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.ConicCurveTo(DlPoint(150, 150), DlPoint(200, 100), 1.0f);
  reference_builder.MoveTo(DlPoint(300, 100));
  reference_builder.QuadraticCurveTo(DlPoint(350, 150), DlPoint(400, 100));

  // weight of sqrt(2)/2 is a circular section
  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.ConicCurveTo(DlPoint(150, 250), DlPoint(200, 200), kSqrt2Over2);
  reference_builder.MoveTo(DlPoint(300, 200));
  auto magic = DlPathBuilder::kArcApproximationMagic;
  reference_builder.CubicCurveTo(DlPoint(300, 200) + DlPoint(50, 50) * magic,
                                 DlPoint(400, 200) + DlPoint(-50, 50) * magic,
                                 DlPoint(400, 200));

  // weight of .01 is nearly a straight line
  path_builder.MoveTo(DlPoint(100, 300));
  path_builder.ConicCurveTo(DlPoint(150, 350), DlPoint(200, 300), 0.01f);
  reference_builder.MoveTo(DlPoint(300, 300));
  reference_builder.LineTo(DlPoint(350, 300.5));
  reference_builder.LineTo(DlPoint(400, 300));

  // weight of 100.0 is nearly a triangle
  path_builder.MoveTo(DlPoint(100, 400));
  path_builder.ConicCurveTo(DlPoint(150, 450), DlPoint(200, 400), 100.0f);
  reference_builder.MoveTo(DlPoint(300, 400));
  reference_builder.LineTo(DlPoint(350, 450));
  reference_builder.LineTo(DlPoint(400, 400));

  builder.DrawPath(path_builder.TakePath(), paint);
  builder.DrawPath(reference_builder.TakePath(), reference_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderStrokedConicPaths) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setStrokeWidth(10);
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeCap(DlStrokeCap::kRound);
  paint.setStrokeJoin(DlStrokeJoin::kRound);

  DlPaint reference_paint;
  reference_paint.setColor(DlColor::kGreen());
  reference_paint.setStrokeWidth(10);
  reference_paint.setDrawStyle(DlDrawStyle::kStroke);
  reference_paint.setStrokeCap(DlStrokeCap::kRound);
  reference_paint.setStrokeJoin(DlStrokeJoin::kRound);

  DlPathBuilder path_builder;
  DlPathBuilder reference_builder;

  // weight of 1.0 is just a quadratic bezier
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.ConicCurveTo(DlPoint(150, 150), DlPoint(200, 100), 1.0f);
  reference_builder.MoveTo(DlPoint(300, 100));
  reference_builder.QuadraticCurveTo(DlPoint(350, 150), DlPoint(400, 100));

  // weight of sqrt(2)/2 is a circular section
  path_builder.MoveTo(DlPoint(100, 200));
  path_builder.ConicCurveTo(DlPoint(150, 250), DlPoint(200, 200), kSqrt2Over2);
  reference_builder.MoveTo(DlPoint(300, 200));
  auto magic = DlPathBuilder::kArcApproximationMagic;
  reference_builder.CubicCurveTo(DlPoint(300, 200) + DlPoint(50, 50) * magic,
                                 DlPoint(400, 200) + DlPoint(-50, 50) * magic,
                                 DlPoint(400, 200));

  // weight of .0 is a straight line
  path_builder.MoveTo(DlPoint(100, 300));
  path_builder.ConicCurveTo(DlPoint(150, 350), DlPoint(200, 300), 0.0f);
  reference_builder.MoveTo(DlPoint(300, 300));
  reference_builder.LineTo(DlPoint(400, 300));

  // weight of 100.0 is nearly a triangle
  path_builder.MoveTo(DlPoint(100, 400));
  path_builder.ConicCurveTo(DlPoint(150, 450), DlPoint(200, 400), 100.0f);
  reference_builder.MoveTo(DlPoint(300, 400));
  reference_builder.LineTo(DlPoint(350, 450));
  reference_builder.LineTo(DlPoint(400, 400));

  builder.DrawPath(path_builder.TakePath(), paint);
  builder.DrawPath(reference_builder.TakePath(), reference_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, HairlinePath) {
  Scalar scale = 1.f;
  Scalar rotation = 0.f;
  Scalar offset = 0.f;
  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Scale", &scale, 0, 6);
      ImGui::SliderFloat("Rotate", &rotation, 0, 90);
      ImGui::SliderFloat("Offset", &offset, 0, 2);
      ImGui::End();
    }

    DisplayListBuilder builder;
    builder.Scale(GetContentScale().x, GetContentScale().y);
    builder.DrawPaint(DlPaint(DlColor(0xff111111)));

    DlPaint paint;
    paint.setStrokeWidth(0.f);
    paint.setColor(DlColor::kWhite());
    paint.setStrokeCap(DlStrokeCap::kRound);
    paint.setStrokeJoin(DlStrokeJoin::kRound);
    paint.setDrawStyle(DlDrawStyle::kStroke);

    builder.Translate(512, 384);
    builder.Scale(scale, scale);
    builder.Rotate(rotation);
    builder.Translate(-512, -384 + offset);

    for (int i = 0; i < 5; ++i) {
      Scalar yoffset = i * 25.25f + 300.f;
      DlPathBuilder path_builder;

      path_builder.MoveTo(DlPoint(100, yoffset));
      path_builder.LineTo(DlPoint(924, yoffset));
      builder.DrawPath(path_builder.TakePath(), paint);
    }

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, HairlineDrawLine) {
  Scalar scale = 1.f;
  Scalar rotation = 0.f;
  Scalar offset = 0.f;
  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Scale", &scale, 0, 6);
      ImGui::SliderFloat("Rotate", &rotation, 0, 90);
      ImGui::SliderFloat("Offset", &offset, 0, 2);
      ImGui::End();
    }

    DisplayListBuilder builder;
    builder.Scale(GetContentScale().x, GetContentScale().y);
    builder.DrawPaint(DlPaint(DlColor(0xff111111)));

    DlPaint paint;
    paint.setStrokeWidth(0.f);
    paint.setColor(DlColor::kWhite());

    builder.Translate(512, 384);
    builder.Scale(scale, scale);
    builder.Rotate(rotation);
    builder.Translate(-512, -384 + offset);

    for (int i = 0; i < 5; ++i) {
      Scalar yoffset = i * 25.25f + 300.f;

      builder.DrawLine(DlPoint(100, yoffset), DlPoint(924, yoffset), paint);
    }

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderTightConicPath) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setDrawStyle(DlDrawStyle::kFill);

  DlPaint reference_paint;
  reference_paint.setColor(DlColor::kGreen());
  reference_paint.setDrawStyle(DlDrawStyle::kFill);

  DlPathBuilder path_builder;

  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.ConicCurveTo(DlPoint(150, 450), DlPoint(200, 100), 5.0f);

  DlPathBuilder reference_builder;
  PathTessellator::Conic component{DlPoint(300, 100),  //
                                   DlPoint(350, 450),  //
                                   DlPoint(400, 100),  //
                                   5.0f};
  reference_builder.MoveTo(component.p1);
  constexpr int N = 100;
  for (int i = 1; i < N; i++) {
    reference_builder.LineTo(component.Solve(static_cast<Scalar>(i) / N));
  }
  reference_builder.LineTo(component.p2);

  DlPaint line_paint;
  line_paint.setColor(DlColor::kYellow());
  line_paint.setDrawStyle(DlDrawStyle::kStroke);
  line_paint.setStrokeWidth(1.0f);

  // Draw some lines to provide a spacial reference for the curvature of
  // the tips of the direct rendering and the manually tessellated versions.
  builder.DrawLine(DlPoint(145, 100), DlPoint(145, 450), line_paint);
  builder.DrawLine(DlPoint(155, 100), DlPoint(155, 450), line_paint);
  builder.DrawLine(DlPoint(345, 100), DlPoint(345, 450), line_paint);
  builder.DrawLine(DlPoint(355, 100), DlPoint(355, 450), line_paint);
  builder.DrawLine(DlPoint(100, 392.5f), DlPoint(400, 392.5f), line_paint);

  // Draw the two paths (direct and manually tessellated) on top of the lines.
  builder.DrawPath(path_builder.TakePath(), paint);
  builder.DrawPath(reference_builder.TakePath(), reference_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderDifferencePaths) {
  DisplayListBuilder builder;

  DlPaint paint;
  paint.setColor(DlColor::kRed());

  RoundingRadii radii = {
      .top_left = {50, 25},
      .top_right = {25, 50},
      .bottom_left = {25, 50},
      .bottom_right = {50, 25},
  };
  DlPathBuilder path_builder;
  DlRoundRect rrect =
      DlRoundRect::MakeRectRadii(DlRect::MakeXYWH(100, 100, 200, 200), radii);
  // We use the factory method to convert the rrect and circle to a path so
  // that they use the legacy conics for legacy golden output.
  path_builder.AddPath(DlPath::MakeRoundRect(rrect));
  path_builder.AddPath(DlPath::MakeCircle(DlPoint(200, 200), 50));
  path_builder.SetFillType(DlPathFillType::kOdd);
  DlPath path = path_builder.TakePath();

  builder.DrawImage(
      DlImageImpeller::Make(CreateTextureForFixture("boston.jpg")),
      DlPoint{10, 10}, {});
  builder.DrawPath(path, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

// Regression test for https://github.com/flutter/flutter/issues/134816.
//
// It should be possible to draw 3 lines, and not have an implicit close path.
TEST_P(AiksTest, CanDrawAnOpenPath) {
  DisplayListBuilder builder;

  // Starting at (50, 50), draw lines from:
  // 1. (50, height)
  // 2. (width, height)
  // 3. (width, 50)
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(50, 50));
  path_builder.LineTo(DlPoint(50, 100));
  path_builder.LineTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(100, 50));

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(10);

  builder.DrawPath(path_builder.TakePath(), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanDrawAnOpenPathThatIsntARect) {
  DisplayListBuilder builder;

  // Draw a stroked path that is explicitly closed to verify
  // It doesn't become a rectangle.
  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(50, 50));
  path_builder.LineTo(DlPoint(520, 120));
  path_builder.LineTo(DlPoint(300, 310));
  path_builder.LineTo(DlPoint(100, 50));
  path_builder.Close();

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(10);

  builder.DrawPath(path_builder.TakePath(), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, SolidStrokesRenderCorrectly) {
  // Compare with https://fiddle.skia.org/c/027392122bec8ac2b5d5de00a4b9bbe2
  auto callback = [&]() -> sk_sp<DisplayList> {
    static Color color = Color::Black().WithAlpha(0.5);
    static float scale = 3;
    static bool add_circle_clip = true;

    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::ColorEdit4("Color", reinterpret_cast<float*>(&color));
      ImGui::SliderFloat("Scale", &scale, 0, 6);
      ImGui::Checkbox("Circle clip", &add_circle_clip);
      ImGui::End();
    }

    DisplayListBuilder builder;
    builder.Scale(GetContentScale().x, GetContentScale().y);
    DlPaint paint;

    paint.setColor(DlColor::kWhite());
    builder.DrawPaint(paint);

    paint.setColor(
        DlColor::ARGB(color.alpha, color.red, color.green, color.blue));
    paint.setDrawStyle(DlDrawStyle::kStroke);
    paint.setStrokeWidth(10);

    DlPathBuilder path_builder;
    path_builder.MoveTo(DlPoint(20, 20));
    path_builder.QuadraticCurveTo(DlPoint(60, 20), DlPoint(60, 60));
    path_builder.Close();
    path_builder.MoveTo(DlPoint(60, 20));
    path_builder.QuadraticCurveTo(DlPoint(60, 60), DlPoint(20, 60));
    DlPath path = path_builder.TakePath();

    builder.Scale(scale, scale);

    if (add_circle_clip) {
      static PlaygroundPoint circle_clip_point_a(Point(60, 300), 20,
                                                 Color::Red());
      static PlaygroundPoint circle_clip_point_b(Point(600, 300), 20,
                                                 Color::Red());
      auto [handle_a, handle_b] =
          DrawPlaygroundLine(circle_clip_point_a, circle_clip_point_b);

      Matrix screen_to_canvas = builder.GetMatrix();
      if (!screen_to_canvas.IsInvertible()) {
        return nullptr;
      }
      screen_to_canvas = screen_to_canvas.Invert();

      Point point_a = screen_to_canvas * handle_a;
      Point point_b = screen_to_canvas * handle_b;

      Point middle = point_a + point_b;
      middle *= GetContentScale().x / 2;

      auto radius = point_a.GetDistance(middle);

      builder.ClipPath(DlPath::MakeCircle(middle, radius));
    }

    for (auto join :
         {DlStrokeJoin::kBevel, DlStrokeJoin::kRound, DlStrokeJoin::kMiter}) {
      paint.setStrokeJoin(join);
      for (auto cap :
           {DlStrokeCap::kButt, DlStrokeCap::kSquare, DlStrokeCap::kRound}) {
        paint.setStrokeCap(cap);
        builder.DrawPath(path, paint);
        builder.Translate(80, 0);
      }
      builder.Translate(-240, 60);
    }

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, DrawLinesRenderCorrectly) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);

  DlPaint paint;
  paint.setColor(DlColor::kBlue());
  paint.setStrokeWidth(10);

  auto draw = [&builder](DlPaint& paint) {
    for (auto cap :
         {DlStrokeCap::kButt, DlStrokeCap::kSquare, DlStrokeCap::kRound}) {
      paint.setStrokeCap(cap);
      DlPoint origin = {100, 100};
      builder.DrawLine(DlPoint(150, 100), DlPoint(250, 100), paint);
      for (int d = 15; d < 90; d += 15) {
        Matrix m = Matrix::MakeRotationZ(Degrees(d));
        Point origin = {100, 100};
        Point p0 = {50, 0};
        Point p1 = {150, 0};
        auto a = origin + m * p0;
        auto b = origin + m * p1;

        builder.DrawLine(a, b, paint);
      }
      builder.DrawLine(DlPoint(100, 150), DlPoint(100, 250), paint);
      builder.DrawCircle(origin, 35, paint);

      builder.DrawLine(DlPoint(250, 250), DlPoint(250, 250), paint);

      builder.Translate(250, 0);
    }
    builder.Translate(-750, 250);
  };

  std::vector<DlColor> colors = {
      DlColor::ARGB(1, 0x1f / 255.0, 0.0, 0x5c / 255.0),
      DlColor::ARGB(1, 0x5b / 255.0, 0.0, 0x60 / 255.0),
      DlColor::ARGB(1, 0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0),
      DlColor::ARGB(1, 0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0),
      DlColor::ARGB(1, 0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0),
      DlColor::ARGB(1, 0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0),
      DlColor::ARGB(1, 0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0)};
  std::vector<Scalar> stops = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };

  auto texture = DlImageImpeller::Make(
      CreateTextureForFixture("airplane.jpg",
                              /*enable_mipmapping=*/true));

  draw(paint);

  paint.setColorSource(DlColorSource::MakeRadial({100, 100}, 200, stops.size(),
                                                 colors.data(), stops.data(),
                                                 DlTileMode::kMirror));
  draw(paint);

  DlMatrix matrix = DlMatrix::MakeTranslation({-150, 75});
  paint.setColorSource(DlColorSource::MakeImage(
      texture, DlTileMode::kRepeat, DlTileMode::kRepeat,
      DlImageSampling::kMipmapLinear, &matrix));
  draw(paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

// The goal of this test is to show that scaling the lines doesn't also scale
// the antialiasing. The amount of blurring should be the same for both
// horizontal lines.
TEST_P(AiksTest, ScaleExperimentAntialiasLines) {
  Scalar scale = 5.0;
  Scalar line_width = 10.f;
  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Scale", &scale, 0.001, 5);
      ImGui::SliderFloat("Width", &line_width, 1, 20);

      ImGui::End();
    }
    DisplayListBuilder builder;
    builder.Scale(GetContentScale().x, GetContentScale().y);

    builder.DrawPaint(DlPaint(DlColor(0xff111111)));

    {
      DlPaint paint;
      paint.setColor(DlColor::kGreenYellow());
      paint.setStrokeWidth(line_width);

      builder.DrawLine(DlPoint(100, 100), DlPoint(350, 100), paint);
      builder.DrawLine(DlPoint(100, 100), DlPoint(350, 150), paint);

      builder.Save();
      builder.Translate(100, 300);
      builder.Scale(scale, scale);
      builder.Translate(-100, -300);
      builder.DrawLine(DlPoint(100, 300), DlPoint(350, 300), paint);
      builder.DrawLine(DlPoint(100, 300), DlPoint(350, 450), paint);
      builder.Restore();
    }

    {
      DlPaint paint;
      paint.setColor(DlColor::kGreenYellow());
      paint.setStrokeWidth(2.0);

      builder.Save();
      builder.Translate(100, 500);
      builder.Scale(0.2, 0.2);
      builder.Translate(-100, -500);
      builder.DrawLine(DlPoint(100, 500), DlPoint(350, 500), paint);
      builder.DrawLine(DlPoint(100, 500), DlPoint(350, 650), paint);
      builder.Restore();
    }

    return builder.Build();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, HexagonExperimentAntialiasLines) {
  float scale = 5.0f;
  float line_width = 10.f;
  float rotation = 0.f;

  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      // Use ImGui::SliderFloat for consistency
      ImGui::SliderFloat("Scale", &scale, 0.001f, 5.0f);
      ImGui::SliderFloat("Width", &line_width, 1.0f, 20.0f);
      ImGui::SliderFloat("Rotation", &rotation, 0.0f, 180.0f);

      ImGui::End();
    }
    DisplayListBuilder builder;
    builder.Scale(static_cast<float>(GetContentScale().x),
                  static_cast<float>(GetContentScale().y));

    builder.DrawPaint(DlPaint(DlColor(0xff111111)));  // Background

    {
      DlPaint hex_paint;
      hex_paint.setColor(
          DlColor::kGreen());  // Changed color to Red for visibility
      hex_paint.setStrokeWidth(line_width);  // Use the interactive width

      float cx = 512.0f;  // Center X
      float cy = 384.0f;  // Center Y
      float r = 80.0f;    // Radius (distance from center to vertex)

      float r_sin60 = r * std::sqrt(3.0f) / 2.0f;
      float r_cos60 = r / 2.0f;

      DlPoint v0 = DlPoint(cx + r, cy);                  // Right vertex
      DlPoint v1 = DlPoint(cx + r_cos60, cy - r_sin60);  // Top-right vertex
      DlPoint v2 = DlPoint(
          cx - r_cos60,
          cy - r_sin60);  // Top-left vertex (v1-v2 is top horizontal side)
      DlPoint v3 = DlPoint(cx - r, cy);                  // Left vertex
      DlPoint v4 = DlPoint(cx - r_cos60, cy + r_sin60);  // Bottom-left vertex
      DlPoint v5 =
          DlPoint(cx + r_cos60, cy + r_sin60);  // Bottom-right vertex (v4-v5 is
                                                // bottom horizontal side)

      builder.Translate(cx, cy);
      builder.Scale(scale, scale);
      builder.Rotate(rotation);
      builder.Translate(-cx, -cy);

      builder.DrawLine(v0, v1, hex_paint);
      builder.DrawLine(v1, v2, hex_paint);  // Top side
      builder.DrawLine(v2, v3, hex_paint);
      builder.DrawLine(v3, v4, hex_paint);
      builder.DrawLine(v4, v5, hex_paint);  // Bottom side
      builder.DrawLine(v5, v0, hex_paint);  // Close the hexagon
    }

    return builder.Build();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, SimpleExperimentAntialiasLines) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);

  builder.DrawPaint(DlPaint(DlColor(0xff111111)));

  DlPaint paint;
  paint.setColor(DlColor::kGreenYellow());
  paint.setStrokeWidth(10);

  auto draw = [&builder](DlPaint& paint) {
    for (auto cap :
         {DlStrokeCap::kButt, DlStrokeCap::kSquare, DlStrokeCap::kRound}) {
      paint.setStrokeCap(cap);
      DlPoint origin = {100, 100};
      builder.DrawLine(DlPoint(150, 100), DlPoint(250, 100), paint);
      for (int d = 15; d < 90; d += 15) {
        Matrix m = Matrix::MakeRotationZ(Degrees(d));
        Point origin = {100, 100};
        Point p0 = {50, 0};
        Point p1 = {150, 0};
        auto a = origin + m * p0;
        auto b = origin + m * p1;

        builder.DrawLine(a, b, paint);
      }
      builder.DrawLine(DlPoint(100, 150), DlPoint(100, 250), paint);
      builder.DrawCircle(origin, 35, paint);

      builder.DrawLine(DlPoint(250, 250), DlPoint(250, 250), paint);

      builder.Translate(250, 0);
    }
    builder.Translate(-750, 250);
  };

  draw(paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawRectStrokesRenderCorrectly) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(10);

  builder.Translate(100, 100);
  builder.DrawPath(DlPath::MakeRect(DlRect::MakeSize(DlSize(100, 100))), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawRectStrokesWithBevelJoinRenderCorrectly) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(10);
  paint.setStrokeJoin(DlStrokeJoin::kBevel);

  builder.Translate(100, 100);
  builder.DrawPath(DlPath::MakeRect(DlRect::MakeSize(DlSize(100, 100))), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanDrawMultiContourConvexPath) {
  DlPathBuilder path_builder;
  for (auto i = 0; i < 10; i++) {
    if (i % 2 == 0) {
      // We use the factory method to convert the circle to a path so that it
      // uses the legacy conics for legacy golden output.
      DlPath circle =
          DlPath::MakeCircle(DlPoint(100 + 50 * i, 100 + 50 * i), 100);
      path_builder.AddPath(circle);
      path_builder.Close();
    } else {
      path_builder.MoveTo(DlPoint(100.f + 50.f * i - 100, 100.f + 50.f * i));
      path_builder.LineTo(DlPoint(100.f + 50.f * i, 100.f + 50.f * i - 100));
      path_builder.LineTo(DlPoint(100.f + 50.f * i - 100,  //
                                  100.f + 50.f * i - 100));
      path_builder.Close();
    }
  }
  DlPath path = path_builder.TakePath();

  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed().withAlpha(102));
  builder.DrawPath(path, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, ArcWithZeroSweepAndBlur) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);

  DlPaint paint;
  paint.setColor(DlColor::kRed());

  std::vector<DlColor> colors = {DlColor::RGBA(1.0, 0.0, 0.0, 1.0),
                                 DlColor::RGBA(0.0, 0.0, 0.0, 1.0)};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.setColorSource(
      DlColorSource::MakeSweep({100, 100}, 45, 135, stops.size(), colors.data(),
                               stops.data(), DlTileMode::kMirror));
  paint.setMaskFilter(DlBlurMaskFilter::Make(DlBlurStyle::kNormal, 20));

  DlPathBuilder path_builder;
  path_builder.AddArc(DlRect::MakeXYWH(10, 10, 100, 100),  //
                      DlDegrees(0), DlDegrees(0));
  builder.DrawPath(path_builder.TakePath(), paint);

  // Check that this empty picture can be created without crashing.
  builder.Build();
}

TEST_P(AiksTest, CanRenderClips) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kFuchsia());

  builder.ClipPath(DlPath::MakeRect(DlRect::MakeXYWH(0, 0, 500, 500)));
  builder.DrawPath(DlPath::MakeCircle(DlPoint(500, 500), 250), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, FatStrokeArc) {
  DlScalar stroke_width = 300;
  DlScalar aspect = 1.0;
  DlScalar start_angle = 0;
  DlScalar end_angle = 90;
  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Stroke Width", &stroke_width, 1, 300);
      ImGui::SliderFloat("Aspect", &aspect, 0.5, 2.0);
      ImGui::SliderFloat("Start Angle", &start_angle, 0, 360);
      ImGui::SliderFloat("End Angle", &end_angle, 0, 360);
      ImGui::End();
    }

    DisplayListBuilder builder;
    DlPaint grey_paint;
    grey_paint.setColor(DlColor(0xff111111));
    builder.DrawPaint(grey_paint);

    DlPaint white_paint;
    white_paint.setColor(DlColor::kWhite());
    white_paint.setStrokeWidth(stroke_width);
    white_paint.setDrawStyle(DlDrawStyle::kStroke);
    DlPaint red_paint;
    red_paint.setColor(DlColor::kRed());

    Rect rect = Rect::MakeXYWH(100, 100, 100, aspect * 100);
    builder.DrawRect(rect, red_paint);
    builder.DrawArc(rect, start_angle, end_angle,
                    /*useCenter=*/false, white_paint);
    DlScalar frontier = rect.GetRight() + stroke_width / 2.0;
    builder.DrawLine(Point(frontier, 0), Point(frontier, 150), red_paint);

    return builder.Build();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderOverlappingMultiContourPath) {
  DisplayListBuilder builder;

  DlPaint paint;
  paint.setColor(DlColor::kRed());

  RoundingRadii radii = {
      .top_left = DlSize(50, 50),
      .top_right = DlSize(50, 50),
      .bottom_left = DlSize(50, 50),
      .bottom_right = DlSize(50, 50),
  };

  const Scalar kTriangleHeight = 100;
  DlRoundRect rrect = DlRoundRect::MakeRectRadii(
      DlRect::MakeXYWH(-kTriangleHeight / 2.0f, -kTriangleHeight / 2.0f,
                       kTriangleHeight, kTriangleHeight),
      radii  //
  );
  // We use the factory method to convert the rrect to a path so that it
  // uses the legacy conics for legacy golden output.
  DlPath rrect_path = DlPath::MakeRoundRect(rrect);

  builder.Translate(200, 200);
  // Form a path similar to the Material drop slider value indicator. Both
  // shapes should render identically side-by-side.
  {
    DlPathBuilder path_builder;
    path_builder.MoveTo(DlPoint(0, kTriangleHeight));
    path_builder.LineTo(DlPoint(-kTriangleHeight / 2.0f, 0));
    path_builder.LineTo(DlPoint(kTriangleHeight / 2.0f, 0));
    path_builder.Close();
    path_builder.AddPath(rrect_path);

    builder.DrawPath(path_builder.TakePath(), paint);
  }
  builder.Translate(100, 0);

  {
    DlPathBuilder path_builder;
    path_builder.MoveTo(DlPoint(0, kTriangleHeight));
    path_builder.LineTo(DlPoint(-kTriangleHeight / 2.0f, 0));
    path_builder.LineTo(DlPoint(0, -10));
    path_builder.LineTo(DlPoint(kTriangleHeight / 2.0f, 0));
    path_builder.Close();
    path_builder.AddPath(rrect_path);

    builder.DrawPath(path_builder.TakePath(), paint);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TwoContourPathWithSinglePointContour) {
  DisplayListBuilder builder;

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(15.0);
  paint.setStrokeCap(DlStrokeCap::kRound);

  DlPathBuilder path_builder;
  path_builder.MoveTo(DlPoint(100, 100));
  path_builder.LineTo(DlPoint(150, 150));
  path_builder.MoveTo(DlPoint(200, 200));
  path_builder.LineTo(DlPoint(200, 200));

  builder.DrawPath(path_builder.TakePath(), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, StrokeCapsAndJoins) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);

  builder.Translate(100, 0);

  builder.Save();
  for (auto cap : std::vector<DlStrokeCap>{
           DlStrokeCap::kButt, DlStrokeCap::kRound, DlStrokeCap::kSquare}) {
    DlPathBuilder path_builder;
    path_builder.MoveTo({20, 50});
    path_builder.LineTo({50, 50});
    path_builder.MoveTo({120, 50});
    path_builder.LineTo({120, 80});
    path_builder.MoveTo({180, 50});
    path_builder.LineTo({180, 50});
    DlPath path = path_builder.TakePath();

    DlPaint paint;
    paint.setColor(DlColor::kRed());
    paint.setDrawStyle(DlDrawStyle::kStroke);
    paint.setStrokeWidth(20.0f);
    paint.setStrokeCap(cap);
    paint.setStrokeJoin(DlStrokeJoin::kBevel);

    builder.DrawPath(path, paint);

    paint.setColor(DlColor::kYellow());
    paint.setStrokeWidth(1.0f);
    paint.setStrokeCap(DlStrokeCap::kButt);

    builder.DrawPath(path, paint);

    builder.Translate(250, 0);
  }
  builder.Restore();

  builder.Translate(0, 100);

  builder.Save();
  for (auto join : std::vector<DlStrokeJoin>{
           DlStrokeJoin::kBevel, DlStrokeJoin::kRound, DlStrokeJoin::kMiter}) {
    DlPathBuilder path_builder;
    path_builder.MoveTo({20, 50});  // 0 degree right turn
    path_builder.LineTo({50, 50});
    path_builder.LineTo({80, 50});
    path_builder.MoveTo({20, 150});  // 90 degree right turn
    path_builder.LineTo({50, 150});
    path_builder.LineTo({50, 180});
    path_builder.MoveTo({20, 250});  // 45 degree right turn
    path_builder.LineTo({50, 250});
    path_builder.LineTo({70, 270});
    path_builder.MoveTo({20, 350});  // 135 degree right turn
    path_builder.LineTo({50, 350});
    path_builder.LineTo({30, 370});
    path_builder.MoveTo({20, 450});  // 180 degree right turn
    path_builder.LineTo({50, 450});
    path_builder.LineTo({20, 450});
    path_builder.MoveTo({120, 80});  // 0 degree left turn
    path_builder.LineTo({150, 80});
    path_builder.LineTo({180, 80});
    path_builder.MoveTo({120, 180});  // 90 degree left turn
    path_builder.LineTo({150, 180});
    path_builder.LineTo({150, 150});
    path_builder.MoveTo({120, 280});  // 45 degree left turn
    path_builder.LineTo({150, 280});
    path_builder.LineTo({170, 260});
    path_builder.MoveTo({120, 380});  // 135 degree left turn
    path_builder.LineTo({150, 380});
    path_builder.LineTo({130, 360});
    path_builder.MoveTo({120, 480});  // 180 degree left turn
    path_builder.LineTo({150, 480});
    path_builder.LineTo({120, 480});
    DlPath path = path_builder.TakePath();

    DlPaint paint;

    paint.setColor(DlColor::kRed());
    paint.setDrawStyle(DlDrawStyle::kStroke);
    paint.setStrokeWidth(20.0f);
    paint.setStrokeCap(DlStrokeCap::kSquare);
    paint.setStrokeJoin(join);
    builder.DrawPath(path, paint);

    paint.setColor(DlColor::kYellow());
    paint.setStrokeWidth(1.0f);
    paint.setStrokeCap(DlStrokeCap::kButt);
    builder.DrawPath(path, paint);

    builder.Translate(250, 0);
  }
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, BlurredCircleWithStrokeWidth) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kGreen());
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(30);
  paint.setMaskFilter(DlBlurMaskFilter::Make(DlBlurStyle::kNormal, 5));

  builder.DrawCircle(DlPoint(200, 200), 100, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/display_list_blend_mode.h"
#include "display_list/display_list_color.h"
#include "display_list/display_list_color_filter.h"
#include "display_list/display_list_image_filter.h"
#include "display_list/display_list_paint.h"
#include "display_list/display_list_tile_mode.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_mask_filter.h"
#include "flutter/display_list/types.h"
#include "flutter/testing/testing.h"
#include "impeller/display_list/display_list_image_impeller.h"
#include "impeller/display_list/display_list_playground.h"
#include "impeller/geometry/point.h"
#include "impeller/playground/widgets.h"
#include "third_party/imgui/imgui.h"
#include "third_party/skia/include/core/SkClipOp.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkPathBuilder.h"

namespace impeller {
namespace testing {

using DisplayListTest = DisplayListPlayground;
INSTANTIATE_PLAYGROUND_SUITE(DisplayListTest);

TEST_P(DisplayListTest, CanDrawRect) {
  flutter::DisplayListBuilder builder;
  builder.setColor(SK_ColorBLUE);
  builder.drawRect(SkRect::MakeXYWH(10, 10, 100, 100));
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawTextBlob) {
  flutter::DisplayListBuilder builder;
  builder.setColor(SK_ColorBLUE);
  builder.drawTextBlob(SkTextBlob::MakeFromString("Hello", CreateTestFont()),
                       100, 100);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawImage) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  builder.drawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor, true);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawCapsAndJoins) {
  flutter::DisplayListBuilder builder;

  builder.setStyle(flutter::DlDrawStyle::kStroke);
  builder.setStrokeWidth(30);
  builder.setColor(SK_ColorRED);

  auto path =
      SkPathBuilder{}.moveTo(-50, 0).lineTo(0, -50).lineTo(50, 0).snapshot();

  builder.translate(100, 100);
  {
    builder.setStrokeCap(flutter::DlStrokeCap::kButt);
    builder.setStrokeJoin(flutter::DlStrokeJoin::kMiter);
    builder.setStrokeMiter(4);
    builder.drawPath(path);
  }

  {
    builder.save();
    builder.translate(0, 100);
    // The joint in the path is 45 degrees. A miter length of 1 convert to a
    // bevel in this case.
    builder.setStrokeMiter(1);
    builder.drawPath(path);
    builder.restore();
  }

  builder.translate(150, 0);
  {
    builder.setStrokeCap(flutter::DlStrokeCap::kSquare);
    builder.setStrokeJoin(flutter::DlStrokeJoin::kBevel);
    builder.drawPath(path);
  }

  builder.translate(150, 0);
  {
    builder.setStrokeCap(flutter::DlStrokeCap::kRound);
    builder.setStrokeJoin(flutter::DlStrokeJoin::kRound);
    builder.drawPath(path);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawArc) {
  bool first_frame = true;
  auto callback = [&]() {
    if (first_frame) {
      first_frame = false;
      ImGui::SetNextWindowSize({400, 100});
      ImGui::SetNextWindowPos({300, 550});
    }

    static float start_angle = 45;
    static float sweep_angle = 270;
    static bool use_center = true;

    ImGui::Begin("Controls");
    ImGui::SliderFloat("Start angle", &start_angle, -360, 360);
    ImGui::SliderFloat("Sweep angle", &sweep_angle, -360, 360);
    ImGui::Checkbox("Use center", &use_center);
    ImGui::End();

    auto [p1, p2] = IMPELLER_PLAYGROUND_LINE(
        Point(200, 200), Point(400, 400), 20, Color::White(), Color::White());

    flutter::DisplayListBuilder builder;

    Vector2 scale = GetContentScale();
    builder.scale(scale.x, scale.y);
    builder.setStyle(flutter::DlDrawStyle::kStroke);
    builder.setStrokeCap(flutter::DlStrokeCap::kRound);
    builder.setStrokeJoin(flutter::DlStrokeJoin::kMiter);
    builder.setStrokeMiter(10);
    auto rect = SkRect::MakeLTRB(p1.x, p1.y, p2.x, p2.y);
    builder.setColor(SK_ColorGREEN);
    builder.setStrokeWidth(2);
    builder.drawRect(rect);
    builder.setColor(SK_ColorRED);
    builder.setStrokeWidth(10);
    builder.drawArc(rect, start_angle, sweep_angle, use_center);

    return builder.Build();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, StrokedPathsDrawCorrectly) {
  flutter::DisplayListBuilder builder;
  builder.setColor(SK_ColorRED);
  builder.setStyle(flutter::DlDrawStyle::kStroke);
  builder.setStrokeWidth(10);

  // Rectangle
  builder.translate(100, 100);
  builder.drawRect(SkRect::MakeSize({100, 100}));

  // Rounded rectangle
  builder.translate(150, 0);
  builder.drawRRect(SkRRect::MakeRectXY(SkRect::MakeSize({100, 50}), 10, 10));

  // Double rounded rectangle
  builder.translate(150, 0);
  builder.drawDRRect(
      SkRRect::MakeRectXY(SkRect::MakeSize({100, 50}), 10, 10),
      SkRRect::MakeRectXY(SkRect::MakeXYWH(10, 10, 80, 30), 10, 10));

  // Contour with duplicate join points
  {
    builder.translate(150, 0);
    SkPath path;
    path.lineTo({100, 0});
    path.lineTo({100, 0});
    path.lineTo({100, 100});
    builder.drawPath(path);
  }

  // Contour with duplicate end points
  {
    builder.setStrokeCap(flutter::DlStrokeCap::kRound);
    builder.translate(150, 0);
    SkPath path;
    path.moveTo(0, 0);
    path.lineTo({0, 0});
    path.lineTo({50, 50});
    path.lineTo({100, 0});
    path.lineTo({100, 0});
    builder.drawPath(path);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithOddPathWinding) {
  flutter::DisplayListBuilder builder;
  builder.setColor(SK_ColorRED);
  builder.setStyle(flutter::DlDrawStyle::kFill);

  builder.translate(300, 300);
  SkPath path;
  path.setFillType(SkPathFillType::kEvenOdd);
  path.addCircle(0, 0, 100);
  path.addCircle(0, 0, 50);
  builder.drawPath(path);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithMaskBlur) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;

  // Mask blurred image.
  {
    auto filter = flutter::DlBlurMaskFilter(kNormal_SkBlurStyle, 10.0f);
    builder.setMaskFilter(&filter);
    builder.drawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                      flutter::DlImageSampling::kNearestNeighbor, true);
  }

  // Mask blurred filled path.
  {
    builder.setColor(SK_ColorYELLOW);
    auto filter = flutter::DlBlurMaskFilter(kOuter_SkBlurStyle, 10.0f);
    builder.setMaskFilter(&filter);
    builder.drawArc(SkRect::MakeXYWH(410, 110, 100, 100), 45, 270, true);
  }

  // Mask blurred text.
  {
    auto filter = flutter::DlBlurMaskFilter(kSolid_SkBlurStyle, 10.0f);
    builder.setMaskFilter(&filter);
    builder.drawTextBlob(
        SkTextBlob::MakeFromString("Testing", CreateTestFont()), 220, 170);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithBlendColorFilter) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;

  // Pipeline blended image.
  {
    auto filter = flutter::DlBlendColorFilter(SK_ColorYELLOW,
                                              flutter::DlBlendMode::kModulate);
    builder.setColorFilter(&filter);
    builder.drawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                      flutter::DlImageSampling::kNearestNeighbor, true);
  }

  // Advanced blended image.
  {
    auto filter =
        flutter::DlBlendColorFilter(SK_ColorRED, flutter::DlBlendMode::kScreen);
    builder.setColorFilter(&filter);
    builder.drawImage(DlImageImpeller::Make(texture), SkPoint::Make(250, 250),
                      flutter::DlImageSampling::kNearestNeighbor, true);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithImageBlurFilter) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");

  bool first_frame = true;
  auto callback = [&]() {
    if (first_frame) {
      first_frame = false;
      ImGui::SetNextWindowSize({400, 100});
      ImGui::SetNextWindowPos({300, 550});
    }

    static float sigma[] = {10, 10};

    ImGui::Begin("Controls");
    ImGui::SliderFloat2("Sigma", sigma, 0, 100);
    ImGui::End();

    flutter::DisplayListBuilder builder;

    auto filter = flutter::DlBlurImageFilter(sigma[0], sigma[1],
                                             flutter::DlTileMode::kClamp);
    builder.setImageFilter(&filter);
    builder.drawImage(DlImageImpeller::Make(texture), SkPoint::Make(200, 200),
                      flutter::DlImageSampling::kNearestNeighbor, true);

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, CanDrawBackdropFilter) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");

  bool first_frame = true;
  auto callback = [&]() {
    if (first_frame) {
      first_frame = false;
      ImGui::SetNextWindowPos({10, 10});
    }

    static float sigma[] = {10, 10};
    static float ctm_scale = 1;
    static bool use_bounds = true;
    static bool draw_circle = true;
    static bool add_clip = true;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat2("Sigma", sigma, 0, 100);
    ImGui::SliderFloat("Scale", &ctm_scale, 0, 10);
    ImGui::NewLine();
    ImGui::TextWrapped(
        "If everything is working correctly, none of the options below should "
        "impact the filter's appearance.");
    ImGui::Checkbox("Use SaveLayer bounds", &use_bounds);
    ImGui::Checkbox("Draw child element", &draw_circle);
    ImGui::Checkbox("Add pre-clip", &add_clip);
    ImGui::End();

    flutter::DisplayListBuilder builder;

    Vector2 scale = ctm_scale * GetContentScale();
    builder.scale(scale.x, scale.y);

    auto filter = flutter::DlBlurImageFilter(sigma[0], sigma[1],
                                             flutter::DlTileMode::kClamp);

    std::optional<SkRect> bounds;
    if (use_bounds) {
      auto [p1, p2] = IMPELLER_PLAYGROUND_LINE(
          Point(350, 150), Point(800, 600), 20, Color::White(), Color::White());
      bounds = SkRect::MakeLTRB(p1.x, p1.y, p2.x, p2.y);
    }

    // Insert a clip to test that the backdrop filter handles stencil depths > 0
    // correctly.
    if (add_clip) {
      builder.clipRect(SkRect::MakeLTRB(0, 0, 99999, 99999),
                       SkClipOp::kIntersect, true);
    }

    builder.drawImage(DlImageImpeller::Make(texture), SkPoint::Make(200, 200),
                      flutter::DlImageSampling::kNearestNeighbor, true);
    builder.saveLayer(bounds.has_value() ? &bounds.value() : nullptr, nullptr,
                      &filter);

    if (draw_circle) {
      auto circle_center =
          IMPELLER_PLAYGROUND_POINT(Point(500, 400), 20, Color::Red());

      builder.setStyle(flutter::DlDrawStyle::kStroke);
      builder.setStrokeCap(flutter::DlStrokeCap::kButt);
      builder.setStrokeJoin(flutter::DlStrokeJoin::kBevel);
      builder.setStrokeWidth(10);
      builder.setColor(flutter::DlColor::kRed().withAlpha(100));
      builder.drawCircle({circle_center.x, circle_center.y}, 100);
    }

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, CanDrawNinePatchImage) {
  // Image is drawn with corners to scale and center pieces stretched to fit.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.drawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width * 2, size.height * 2),
      flutter::DlFilterMode::kNearest, true);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCenterWidthBiggerThanDest) {
  // Edge case, the width of the corners does not leave any room for the
  // center slice. The center (across the vertical axis) is folded out of the
  // resulting image.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.drawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width / 2, size.height),
      flutter::DlFilterMode::kNearest, true);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCenterHeightBiggerThanDest) {
  // Edge case, the height of the corners does not leave any room for the
  // center slice. The center (across the horizontal axis) is folded out of the
  // resulting image.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.drawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width, size.height / 2),
      flutter::DlFilterMode::kNearest, true);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCenterBiggerThanDest) {
  // Edge case, the width and height of the corners does not leave any
  // room for the center slices. Only the corners are displayed.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.drawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width / 2, size.height / 2),
      flutter::DlFilterMode::kNearest, true);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCornersScaledDown) {
  // Edge case, there is not enough room for the corners to be drawn
  // without scaling them down.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.drawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width / 4, size.height / 4),
      flutter::DlFilterMode::kNearest, true);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawPoints) {
  flutter::DisplayListBuilder builder;
  SkPoint points[7] = {
      {0, 0},      //
      {100, 100},  //
      {100, 0},    //
      {0, 100},    //
      {0, 0},      //
      {48, 48},    //
      {52, 52},    //
  };
  std::vector<flutter::DlStrokeCap> caps = {
      flutter::DlStrokeCap::kButt,
      flutter::DlStrokeCap::kRound,
      flutter::DlStrokeCap::kSquare,
  };
  flutter::DlPaint paint =
      flutter::DlPaint()                                         //
          .setColor(flutter::DlColor::kYellow().withAlpha(127))  //
          .setStrokeWidth(20);
  builder.translate(50, 50);
  for (auto cap : caps) {
    paint.setStrokeCap(cap);
    builder.save();
    builder.drawPoints(SkCanvas::kPoints_PointMode, 7, points, paint);
    builder.translate(150, 0);
    builder.drawPoints(SkCanvas::kLines_PointMode, 5, points, paint);
    builder.translate(150, 0);
    builder.drawPoints(SkCanvas::kPolygon_PointMode, 5, points, paint);
    builder.restore();
    builder.translate(0, 150);
  }
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawZeroLengthLine) {
  flutter::DisplayListBuilder builder;
  std::vector<flutter::DlStrokeCap> caps = {
      flutter::DlStrokeCap::kButt,
      flutter::DlStrokeCap::kRound,
      flutter::DlStrokeCap::kSquare,
  };
  flutter::DlPaint paint =
      flutter::DlPaint()                                         //
          .setColor(flutter::DlColor::kYellow().withAlpha(127))  //
          .setDrawStyle(flutter::DlDrawStyle::kStroke)           //
          .setStrokeCap(flutter::DlStrokeCap::kButt)             //
          .setStrokeWidth(20);
  SkPath path = SkPath().addPoly({{150, 50}, {150, 50}}, false);
  for (auto cap : caps) {
    paint.setStrokeCap(cap);
    builder.drawLine({50, 50}, {50, 50}, paint);
    builder.drawPath(path, paint);
    builder.translate(0, 150);
  }
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller

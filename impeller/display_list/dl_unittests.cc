// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <cmath>
#include <memory>
#include <vector>

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/effects/dl_mask_filter.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/display_list/dl_playground.h"
#include "impeller/entity/contents/solid_rrect_blur_contents.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"
#include "impeller/playground/widgets.h"
#include "impeller/scene/node.h"
#include "third_party/imgui/imgui.h"
#include "third_party/skia/include/core/SkBlurTypes.h"
#include "third_party/skia/include/core/SkClipOp.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkPathBuilder.h"
#include "third_party/skia/include/core/SkRRect.h"

namespace impeller {
namespace testing {

flutter::DlColor toColor(const float* components) {
  return flutter::DlColor(Color::ToIColor(
      Color(components[0], components[1], components[2], components[3])));
}

using DisplayListTest = DlPlayground;
INSTANTIATE_PLAYGROUND_SUITE(DisplayListTest);

TEST_P(DisplayListTest, CanDrawRect) {
  flutter::DisplayListBuilder builder;
  builder.DrawRect(SkRect::MakeXYWH(10, 10, 100, 100),
                   flutter::DlPaint(flutter::DlColor::kBlue()));
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawTextBlob) {
  flutter::DisplayListBuilder builder;
  builder.DrawTextBlob(SkTextBlob::MakeFromString("Hello", CreateTestFont()),
                       100, 100, flutter::DlPaint(flutter::DlColor::kBlue()));
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawTextBlobWithGradient) {
  flutter::DisplayListBuilder builder;

  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  const float stops[2] = {0.0, 1.0};

  auto linear = flutter::DlColorSource::MakeLinear({0.0, 0.0}, {300.0, 300.0},
                                                   2, colors.data(), stops,
                                                   flutter::DlTileMode::kClamp);
  flutter::DlPaint paint;
  paint.setColorSource(linear);

  builder.DrawTextBlob(
      SkTextBlob::MakeFromString("Hello World", CreateTestFont()), 100, 100,
      paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawTextWithSaveLayer) {
  flutter::DisplayListBuilder builder;
  builder.DrawTextBlob(SkTextBlob::MakeFromString("Hello", CreateTestFont()),
                       100, 100, flutter::DlPaint(flutter::DlColor::kRed()));

  flutter::DlPaint save_paint;
  float alpha = 0.5;
  save_paint.setAlpha(static_cast<uint8_t>(255 * alpha));
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawTextBlob(SkTextBlob::MakeFromString("Hello with half alpha",
                                                  CreateTestFontOfSize(100)),
                       100, 300, flutter::DlPaint(flutter::DlColor::kRed()));
  builder.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawImage) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor, nullptr);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawCapsAndJoins) {
  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setDrawStyle(flutter::DlDrawStyle::kStroke);
  paint.setStrokeWidth(30);
  paint.setColor(SK_ColorRED);

  auto path =
      SkPathBuilder{}.moveTo(-50, 0).lineTo(0, -50).lineTo(50, 0).snapshot();

  builder.Translate(100, 100);
  {
    paint.setStrokeCap(flutter::DlStrokeCap::kButt);
    paint.setStrokeJoin(flutter::DlStrokeJoin::kMiter);
    paint.setStrokeMiter(4);
    builder.DrawPath(path, paint);
  }

  {
    builder.Save();
    builder.Translate(0, 100);
    // The joint in the path is 45 degrees. A miter length of 1 convert to a
    // bevel in this case.
    paint.setStrokeMiter(1);
    builder.DrawPath(path, paint);
    builder.Restore();
  }

  builder.Translate(150, 0);
  {
    paint.setStrokeCap(flutter::DlStrokeCap::kSquare);
    paint.setStrokeJoin(flutter::DlStrokeJoin::kBevel);
    builder.DrawPath(path, paint);
  }

  builder.Translate(150, 0);
  {
    paint.setStrokeCap(flutter::DlStrokeCap::kRound);
    paint.setStrokeJoin(flutter::DlStrokeJoin::kRound);
    builder.DrawPath(path, paint);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawArc) {
  auto callback = [&]() {
    static float start_angle = 45;
    static float sweep_angle = 270;
    static float stroke_width = 10;
    static bool use_center = true;

    static int selected_cap = 0;
    const char* cap_names[] = {"Butt", "Round", "Square"};
    flutter::DlStrokeCap cap;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Start angle", &start_angle, -360, 360);
    ImGui::SliderFloat("Sweep angle", &sweep_angle, -360, 360);
    ImGui::SliderFloat("Stroke width", &stroke_width, 0, 300);
    ImGui::Combo("Cap", &selected_cap, cap_names,
                 sizeof(cap_names) / sizeof(char*));
    ImGui::Checkbox("Use center", &use_center);
    ImGui::End();

    switch (selected_cap) {
      case 0:
        cap = flutter::DlStrokeCap::kButt;
        break;
      case 1:
        cap = flutter::DlStrokeCap::kRound;
        break;
      case 2:
        cap = flutter::DlStrokeCap::kSquare;
        break;
      default:
        cap = flutter::DlStrokeCap::kButt;
        break;
    }

    auto [p1, p2] = IMPELLER_PLAYGROUND_LINE(
        Point(200, 200), Point(400, 400), 20, Color::White(), Color::White());

    flutter::DisplayListBuilder builder;
    flutter::DlPaint paint;

    Vector2 scale = GetContentScale();
    builder.Scale(scale.x, scale.y);
    paint.setDrawStyle(flutter::DlDrawStyle::kStroke);
    paint.setStrokeCap(cap);
    paint.setStrokeJoin(flutter::DlStrokeJoin::kMiter);
    paint.setStrokeMiter(10);
    auto rect = SkRect::MakeLTRB(p1.x, p1.y, p2.x, p2.y);
    paint.setColor(SK_ColorGREEN);
    paint.setStrokeWidth(2);
    builder.DrawRect(rect, paint);
    paint.setColor(SK_ColorRED);
    paint.setStrokeWidth(stroke_width);
    builder.DrawArc(rect, start_angle, sweep_angle, use_center, paint);

    return builder.Build();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, StrokedPathsDrawCorrectly) {
  auto callback = [&]() {
    flutter::DisplayListBuilder builder;
    flutter::DlPaint paint;

    paint.setColor(SK_ColorRED);
    paint.setDrawStyle(flutter::DlDrawStyle::kStroke);

    static float stroke_width = 10.0f;
    static int selected_stroke_type = 0;
    static int selected_join_type = 0;
    const char* stroke_types[] = {"Butte", "Round", "Square"};
    const char* join_type[] = {"kMiter", "Round", "kBevel"};

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Cap", &selected_stroke_type, stroke_types,
                 sizeof(stroke_types) / sizeof(char*));
    ImGui::Combo("Join", &selected_join_type, join_type,
                 sizeof(join_type) / sizeof(char*));
    ImGui::SliderFloat("Stroke Width", &stroke_width, 10.0f, 50.0f);
    ImGui::End();

    flutter::DlStrokeCap cap;
    flutter::DlStrokeJoin join;
    switch (selected_stroke_type) {
      case 0:
        cap = flutter::DlStrokeCap::kButt;
        break;
      case 1:
        cap = flutter::DlStrokeCap::kRound;
        break;
      case 2:
        cap = flutter::DlStrokeCap::kSquare;
        break;
      default:
        cap = flutter::DlStrokeCap::kButt;
        break;
    }
    switch (selected_join_type) {
      case 0:
        join = flutter::DlStrokeJoin::kMiter;
        break;
      case 1:
        join = flutter::DlStrokeJoin::kRound;
        break;
      case 2:
        join = flutter::DlStrokeJoin::kBevel;
        break;
      default:
        join = flutter::DlStrokeJoin::kMiter;
        break;
    }
    paint.setStrokeCap(cap);
    paint.setStrokeJoin(join);
    paint.setStrokeWidth(stroke_width);

    // Make rendering better to watch.
    builder.Scale(1.5f, 1.5f);

    // Rectangle
    builder.Translate(100, 100);
    builder.DrawRect(SkRect::MakeSize({100, 100}), paint);

    // Rounded rectangle
    builder.Translate(150, 0);
    builder.DrawRRect(SkRRect::MakeRectXY(SkRect::MakeSize({100, 50}), 10, 10),
                      paint);

    // Double rounded rectangle
    builder.Translate(150, 0);
    builder.DrawDRRect(
        SkRRect::MakeRectXY(SkRect::MakeSize({100, 50}), 10, 10),
        SkRRect::MakeRectXY(SkRect::MakeXYWH(10, 10, 80, 30), 10, 10), paint);

    // Contour with duplicate join points
    {
      builder.Translate(150, 0);
      SkPath path;
      path.moveTo(0, 0);
      path.lineTo(0, 0);
      path.lineTo({100, 0});
      path.lineTo({100, 0});
      path.lineTo({100, 100});
      builder.DrawPath(path, paint);
    }

    // Contour with duplicate start and end points

    // Line.
    builder.Translate(200, 0);
    {
      builder.Save();

      SkPath line_path;
      line_path.moveTo(0, 0);
      line_path.moveTo(0, 0);
      line_path.lineTo({0, 0});
      line_path.lineTo({0, 0});
      line_path.lineTo({50, 50});
      line_path.lineTo({50, 50});
      line_path.lineTo({100, 0});
      line_path.lineTo({100, 0});
      builder.DrawPath(line_path, paint);

      builder.Translate(0, 100);
      builder.DrawPath(line_path, paint);

      builder.Translate(0, 100);
      SkPath line_path2;
      line_path2.moveTo(0, 0);
      line_path2.lineTo(0, 0);
      line_path2.lineTo(0, 0);
      builder.DrawPath(line_path2, paint);

      builder.Restore();
    }

    // Cubic.
    builder.Translate(150, 0);
    {
      builder.Save();

      SkPath cubic_path;
      cubic_path.moveTo({0, 0});
      cubic_path.cubicTo(0, 0, 140.0, 100.0, 140, 20);
      builder.DrawPath(cubic_path, paint);

      builder.Translate(0, 100);
      SkPath cubic_path2;
      cubic_path2.moveTo({0, 0});
      cubic_path2.cubicTo(0, 0, 0, 0, 150, 150);
      builder.DrawPath(cubic_path2, paint);

      builder.Translate(0, 100);
      SkPath cubic_path3;
      cubic_path3.moveTo({0, 0});
      cubic_path3.cubicTo(0, 0, 0, 0, 0, 0);
      builder.DrawPath(cubic_path3, paint);

      builder.Restore();
    }

    // Quad.
    builder.Translate(200, 0);
    {
      builder.Save();

      SkPath quad_path;
      quad_path.moveTo(0, 0);
      quad_path.moveTo(0, 0);
      quad_path.quadTo({100, 40}, {50, 80});
      builder.DrawPath(quad_path, paint);

      builder.Translate(0, 150);
      SkPath quad_path2;
      quad_path2.moveTo(0, 0);
      quad_path2.moveTo(0, 0);
      quad_path2.quadTo({0, 0}, {100, 100});
      builder.DrawPath(quad_path2, paint);

      builder.Translate(0, 100);
      SkPath quad_path3;
      quad_path3.moveTo(0, 0);
      quad_path3.quadTo({0, 0}, {0, 0});
      builder.DrawPath(quad_path3, paint);

      builder.Restore();
    }
    return builder.Build();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, CanDrawWithOddPathWinding) {
  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColor(SK_ColorRED);
  paint.setDrawStyle(flutter::DlDrawStyle::kFill);

  builder.Translate(300, 300);
  SkPath path;
  path.setFillType(SkPathFillType::kEvenOdd);
  path.addCircle(0, 0, 100);
  path.addCircle(0, 0, 50);
  builder.DrawPath(path, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithMaskBlur) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  // Mask blurred image.
  {
    auto filter =
        flutter::DlBlurMaskFilter(flutter::DlBlurStyle::kNormal, 10.0f);
    paint.setMaskFilter(&filter);
    builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                      flutter::DlImageSampling::kNearestNeighbor, &paint);
  }

  // Mask blurred filled path.
  {
    paint.setColor(SK_ColorYELLOW);
    auto filter =
        flutter::DlBlurMaskFilter(flutter::DlBlurStyle::kOuter, 10.0f);
    paint.setMaskFilter(&filter);
    builder.DrawArc(SkRect::MakeXYWH(410, 110, 100, 100), 45, 270, true, paint);
  }

  // Mask blurred text.
  {
    auto filter =
        flutter::DlBlurMaskFilter(flutter::DlBlurStyle::kSolid, 10.0f);
    paint.setMaskFilter(&filter);
    builder.DrawTextBlob(
        SkTextBlob::MakeFromString("Testing", CreateTestFont()), 220, 170,
        paint);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, IgnoreMaskFilterWhenSavingLayer) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto filter = flutter::DlBlurMaskFilter(flutter::DlBlurStyle::kNormal, 10.0f);
  flutter::DlPaint paint;
  paint.setMaskFilter(&filter);
  builder.SaveLayer(nullptr, &paint);
  builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor);
  builder.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithBlendColorFilter) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  // Pipeline blended image.
  {
    auto filter = flutter::DlBlendColorFilter(SK_ColorYELLOW,
                                              flutter::DlBlendMode::kModulate);
    paint.setColorFilter(&filter);
    builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                      flutter::DlImageSampling::kNearestNeighbor, &paint);
  }

  // Advanced blended image.
  {
    auto filter =
        flutter::DlBlendColorFilter(SK_ColorRED, flutter::DlBlendMode::kScreen);
    paint.setColorFilter(&filter);
    builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(250, 250),
                      flutter::DlImageSampling::kNearestNeighbor, &paint);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithColorFilterImageFilter) {
  const float invert_color_matrix[20] = {
      -1, 0,  0,  0, 1,  //
      0,  -1, 0,  0, 1,  //
      0,  0,  -1, 0, 1,  //
      0,  0,  0,  1, 0,  //
  };
  auto texture = CreateTextureForFixture("boston.jpg");
  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  auto color_filter =
      std::make_shared<flutter::DlMatrixColorFilter>(invert_color_matrix);
  auto image_filter =
      std::make_shared<flutter::DlColorFilterImageFilter>(color_filter);

  paint.setImageFilter(image_filter.get());
  builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor, &paint);

  builder.Translate(0, 700);
  paint.setColorFilter(color_filter.get());
  builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor, &paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithImageBlurFilter) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");

  auto callback = [&]() {
    static float sigma[] = {10, 10};

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat2("Sigma", sigma, 0, 100);
    ImGui::End();

    flutter::DisplayListBuilder builder;
    flutter::DlPaint paint;

    auto filter = flutter::DlBlurImageFilter(sigma[0], sigma[1],
                                             flutter::DlTileMode::kClamp);
    paint.setImageFilter(&filter);
    builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(200, 200),
                      flutter::DlImageSampling::kNearestNeighbor, &paint);

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, CanDrawWithComposeImageFilter) {
  auto texture = CreateTextureForFixture("boston.jpg");
  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  auto dilate = std::make_shared<flutter::DlDilateImageFilter>(10.0, 10.0);
  auto erode = std::make_shared<flutter::DlErodeImageFilter>(10.0, 10.0);
  auto open = std::make_shared<flutter::DlComposeImageFilter>(dilate, erode);
  auto close = std::make_shared<flutter::DlComposeImageFilter>(erode, dilate);

  paint.setImageFilter(open.get());
  builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor, &paint);
  builder.Translate(0, 700);
  paint.setImageFilter(close.get());
  builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor, &paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanClampTheResultingColorOfColorMatrixFilter) {
  auto texture = CreateTextureForFixture("boston.jpg");
  const float inner_color_matrix[20] = {
      1, 0, 0, 0, 0,  //
      0, 1, 0, 0, 0,  //
      0, 0, 1, 0, 0,  //
      0, 0, 0, 2, 0,  //
  };
  const float outer_color_matrix[20] = {
      1, 0, 0, 0,   0,  //
      0, 1, 0, 0,   0,  //
      0, 0, 1, 0,   0,  //
      0, 0, 0, 0.5, 0,  //
  };
  auto inner_color_filter =
      std::make_shared<flutter::DlMatrixColorFilter>(inner_color_matrix);
  auto outer_color_filter =
      std::make_shared<flutter::DlMatrixColorFilter>(outer_color_matrix);
  auto inner =
      std::make_shared<flutter::DlColorFilterImageFilter>(inner_color_filter);
  auto outer =
      std::make_shared<flutter::DlColorFilterImageFilter>(outer_color_filter);
  auto compose = std::make_shared<flutter::DlComposeImageFilter>(outer, inner);

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;
  paint.setImageFilter(compose.get());
  builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(100, 100),
                    flutter::DlImageSampling::kNearestNeighbor, &paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawBackdropFilter) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");

  auto callback = [&]() {
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
    builder.Scale(scale.x, scale.y);

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
      builder.ClipRect(SkRect::MakeLTRB(0, 0, 99999, 99999),
                       flutter::DlCanvas::ClipOp::kIntersect, true);
    }

    builder.DrawImage(DlImageImpeller::Make(texture), SkPoint::Make(200, 200),
                      flutter::DlImageSampling::kNearestNeighbor, nullptr);
    builder.SaveLayer(bounds.has_value() ? &bounds.value() : nullptr, nullptr,
                      &filter);

    if (draw_circle) {
      auto circle_center =
          IMPELLER_PLAYGROUND_POINT(Point(500, 400), 20, Color::Red());

      flutter::DlPaint paint;
      paint.setDrawStyle(flutter::DlDrawStyle::kStroke);
      paint.setStrokeCap(flutter::DlStrokeCap::kButt);
      paint.setStrokeJoin(flutter::DlStrokeJoin::kBevel);
      paint.setStrokeWidth(10);
      paint.setColor(flutter::DlColor::kRed().withAlpha(100));
      builder.DrawCircle({circle_center.x, circle_center.y}, 100, paint);
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
  builder.DrawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width * 2, size.height * 2),
      flutter::DlFilterMode::kNearest, nullptr);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCenterWidthBiggerThanDest) {
  // Edge case, the width of the corners does not leave any room for the
  // center slice. The center (across the vertical axis) is folded out of the
  // resulting image.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.DrawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width / 2, size.height),
      flutter::DlFilterMode::kNearest, nullptr);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCenterHeightBiggerThanDest) {
  // Edge case, the height of the corners does not leave any room for the
  // center slice. The center (across the horizontal axis) is folded out of the
  // resulting image.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.DrawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width, size.height / 2),
      flutter::DlFilterMode::kNearest, nullptr);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCenterBiggerThanDest) {
  // Edge case, the width and height of the corners does not leave any
  // room for the center slices. Only the corners are displayed.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.DrawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width / 2, size.height / 2),
      flutter::DlFilterMode::kNearest, nullptr);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawNinePatchImageCornersScaledDown) {
  // Edge case, there is not enough room for the corners to be drawn
  // without scaling them down.
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  flutter::DisplayListBuilder builder;
  auto size = texture->GetSize();
  builder.DrawImageNine(
      DlImageImpeller::Make(texture),
      SkIRect::MakeLTRB(size.width / 4, size.height / 4, size.width * 3 / 4,
                        size.height * 3 / 4),
      SkRect::MakeLTRB(0, 0, size.width / 4, size.height / 4),
      flutter::DlFilterMode::kNearest, nullptr);
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
  builder.Translate(50, 50);
  for (auto cap : caps) {
    paint.setStrokeCap(cap);
    builder.Save();
    builder.DrawPoints(flutter::DlCanvas::PointMode::kPoints, 7, points, paint);
    builder.Translate(150, 0);
    builder.DrawPoints(flutter::DlCanvas::PointMode::kLines, 5, points, paint);
    builder.Translate(150, 0);
    builder.DrawPoints(flutter::DlCanvas::PointMode::kPolygon, 5, points,
                       paint);
    builder.Restore();
    builder.Translate(0, 150);
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
    builder.DrawLine({50, 50}, {50, 50}, paint);
    builder.DrawPath(path, paint);
    builder.Translate(0, 150);
  }
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawShadow) {
  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  auto content_scale = GetContentScale() * 0.8;
  builder.Scale(content_scale.x, content_scale.y);

  constexpr size_t star_spikes = 5;
  constexpr SkScalar half_spike_rotation = kPi / star_spikes;
  constexpr SkScalar radius = 40;
  constexpr SkScalar spike_size = 10;
  constexpr SkScalar outer_radius = radius + spike_size;
  constexpr SkScalar inner_radius = radius - spike_size;
  std::array<SkPoint, star_spikes * 2> star;
  for (size_t i = 0; i < star_spikes; i++) {
    const SkScalar rotation = half_spike_rotation * i * 2;
    star[i * 2] = SkPoint::Make(50 + std::sin(rotation) * outer_radius,
                                50 - std::cos(rotation) * outer_radius);
    star[i * 2 + 1] = SkPoint::Make(
        50 + std::sin(rotation + half_spike_rotation) * inner_radius,
        50 - std::cos(rotation + half_spike_rotation) * inner_radius);
  }

  std::array<SkPath, 4> paths = {
      SkPath{}.addRect(SkRect::MakeXYWH(0, 0, 200, 100)),
      SkPath{}.addRRect(
          SkRRect::MakeRectXY(SkRect::MakeXYWH(20, 0, 200, 100), 30, 30)),
      SkPath{}.addCircle(100, 50, 50),
      SkPath{}.addPoly(star.data(), star.size(), true),
  };
  paint.setColor(flutter::DlColor::kWhite());
  builder.DrawPaint(paint);
  paint.setColor(flutter::DlColor::kCyan());
  builder.Translate(100, 50);
  for (size_t x = 0; x < paths.size(); x++) {
    builder.Save();
    for (size_t y = 0; y < 6; y++) {
      builder.DrawShadow(paths[x], flutter::DlColor::kBlack(), 3 + y * 8, false,
                         1);
      builder.DrawPath(paths[x], paint);
      builder.Translate(0, 150);
    }
    builder.Restore();
    builder.Translate(250, 0);
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, TransparentShadowProducesCorrectColor) {
  flutter::DisplayListBuilder builder;
  {
    builder.Save();
    builder.Scale(1.618, 1.618);
    builder.DrawShadow(SkPath{}.addRect(SkRect::MakeXYWH(0, 0, 200, 100)),
                       SK_ColorTRANSPARENT, 15, false, 1);
    builder.Restore();
  }
  auto dl = builder.Build();

  DlDispatcher dispatcher;
  dispatcher.drawDisplayList(dl, 1);
  auto picture = dispatcher.EndRecordingAsPicture();

  std::shared_ptr<SolidRRectBlurContents> rrect_blur;
  picture.pass->IterateAllEntities([&rrect_blur](Entity& entity) {
    if (ScalarNearlyEqual(entity.GetTransformation().GetScale().x, 1.618f)) {
      rrect_blur = std::static_pointer_cast<SolidRRectBlurContents>(
          entity.GetContents());
      return false;
    }
    return true;
  });

  ASSERT_NE(rrect_blur, nullptr);
  ASSERT_EQ(rrect_blur->GetColor().red, 0);
  ASSERT_EQ(rrect_blur->GetColor().green, 0);
  ASSERT_EQ(rrect_blur->GetColor().blue, 0);
  ASSERT_EQ(rrect_blur->GetColor().alpha, 0);
}

// Draw a hexagon using triangle fan
TEST_P(DisplayListTest, CanConvertTriangleFanToTriangles) {
  constexpr Scalar hexagon_radius = 125;
  auto hex_start = Point(200.0, -hexagon_radius + 200.0);
  auto center_to_flat = 1.73 / 2 * hexagon_radius;

  // clang-format off
  std::vector<SkPoint> vertices = {
    SkPoint::Make(hex_start.x, hex_start.y),
    SkPoint::Make(hex_start.x + center_to_flat, hex_start.y + 0.5 * hexagon_radius),
    SkPoint::Make(hex_start.x + center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x + center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x, hex_start.y + 2 * hexagon_radius),
    SkPoint::Make(hex_start.x, hex_start.y + 2 * hexagon_radius),
    SkPoint::Make(hex_start.x - center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x - center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x - center_to_flat, hex_start.y + 0.5 * hexagon_radius)
  };
  // clang-format on
  auto paint = flutter::DlPaint(flutter::DlColor::kDarkGrey());
  auto dl_vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangleFan, vertices.size(), vertices.data(),
      nullptr, nullptr);
  flutter::DisplayListBuilder builder;
  builder.DrawVertices(dl_vertices, flutter::DlBlendMode::kSrcOver, paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawZeroWidthLine) {
  flutter::DisplayListBuilder builder;
  std::vector<flutter::DlStrokeCap> caps = {
      flutter::DlStrokeCap::kButt,
      flutter::DlStrokeCap::kRound,
      flutter::DlStrokeCap::kSquare,
  };
  flutter::DlPaint paint =                              //
      flutter::DlPaint()                                //
          .setColor(flutter::DlColor::kWhite())         //
          .setDrawStyle(flutter::DlDrawStyle::kStroke)  //
          .setStrokeWidth(0);
  flutter::DlPaint outline_paint =                      //
      flutter::DlPaint()                                //
          .setColor(flutter::DlColor::kYellow())        //
          .setDrawStyle(flutter::DlDrawStyle::kStroke)  //
          .setStrokeCap(flutter::DlStrokeCap::kSquare)  //
          .setStrokeWidth(1);
  SkPath path = SkPath().addPoly({{150, 50}, {160, 50}}, false);
  for (auto cap : caps) {
    paint.setStrokeCap(cap);
    builder.DrawLine({50, 50}, {60, 50}, paint);
    builder.DrawRect({45, 45, 65, 55}, outline_paint);
    builder.DrawLine({100, 50}, {100, 50}, paint);
    if (cap != flutter::DlStrokeCap::kButt) {
      builder.DrawRect({95, 45, 105, 55}, outline_paint);
    }
    builder.DrawPath(path, paint);
    builder.DrawRect(path.getBounds().makeOutset(5, 5), outline_paint);
    builder.Translate(0, 150);
  }
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawWithMatrixFilter) {
  auto boston = CreateTextureForFixture("boston.jpg");

  auto callback = [&]() {
    static int selected_matrix_type = 0;
    const char* matrix_type_names[] = {"Matrix", "Local Matrix"};

    static float ctm_translation[2] = {200, 200};
    static float ctm_scale[2] = {0.65, 0.65};
    static float ctm_skew[2] = {0, 0};

    static bool enable = true;
    static float translation[2] = {100, 100};
    static float scale[2] = {0.8, 0.8};
    static float skew[2] = {0.2, 0.2};

    static bool enable_savelayer = true;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      ImGui::Combo("Filter type", &selected_matrix_type, matrix_type_names,
                   sizeof(matrix_type_names) / sizeof(char*));

      ImGui::TextWrapped("Current Transform");
      ImGui::SliderFloat2("CTM Translation", ctm_translation, 0, 1000);
      ImGui::SliderFloat2("CTM Scale", ctm_scale, 0, 3);
      ImGui::SliderFloat2("CTM Skew", ctm_skew, -3, 3);

      ImGui::TextWrapped(
          "MatrixFilter and LocalMatrixFilter modify the CTM in the same way. "
          "The only difference is that MatrixFilter doesn't affect the effect "
          "transform, whereas LocalMatrixFilter does.");
      // Note: See this behavior in:
      //       https://fiddle.skia.org/c/6cbb551ab36d06f163db8693972be954
      ImGui::Checkbox("Enable", &enable);
      ImGui::SliderFloat2("Filter Translation", translation, 0, 1000);
      ImGui::SliderFloat2("Filter Scale", scale, 0, 3);
      ImGui::SliderFloat2("Filter Skew", skew, -3, 3);

      ImGui::TextWrapped(
          "Rendering the filtered image within a layer can expose bounds "
          "issues. If the rendered image gets cut off when this setting is "
          "enabled, there's a coverage bug in the filter.");
      ImGui::Checkbox("Render in layer", &enable_savelayer);
    }
    ImGui::End();

    flutter::DisplayListBuilder builder;
    flutter::DlPaint paint;

    if (enable_savelayer) {
      builder.SaveLayer(nullptr, nullptr);
    }
    {
      auto content_scale = GetContentScale();
      builder.Scale(content_scale.x, content_scale.y);

      // Set the current transform
      auto ctm_matrix =
          SkMatrix::MakeAll(ctm_scale[0], ctm_skew[0], ctm_translation[0],  //
                            ctm_skew[1], ctm_scale[1], ctm_translation[1],  //
                            0, 0, 1);
      builder.Transform(ctm_matrix);

      // Set the matrix filter
      auto filter_matrix =
          SkMatrix::MakeAll(scale[0], skew[0], translation[0],  //
                            skew[1], scale[1], translation[1],  //
                            0, 0, 1);

      if (enable) {
        switch (selected_matrix_type) {
          case 0: {
            auto filter = flutter::DlMatrixImageFilter(
                filter_matrix, flutter::DlImageSampling::kLinear);
            paint.setImageFilter(&filter);
            break;
          }
          case 1: {
            auto internal_filter =
                flutter::DlBlurImageFilter(10, 10, flutter::DlTileMode::kDecal)
                    .shared();
            auto filter = flutter::DlLocalMatrixImageFilter(filter_matrix,
                                                            internal_filter);
            paint.setImageFilter(&filter);
            break;
          }
        }
      }

      builder.DrawImage(DlImageImpeller::Make(boston), {},
                        flutter::DlImageSampling::kLinear, &paint);
    }
    if (enable_savelayer) {
      builder.Restore();
    }

    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, CanDrawWithMatrixFilterWhenSavingLayer) {
  auto callback = [&]() {
    static float translation[2] = {0, 0};
    static bool enable_save_layer = true;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat2("Translation", translation, -130, 130);
    ImGui::Checkbox("Enable save layer", &enable_save_layer);
    ImGui::End();

    flutter::DisplayListBuilder builder;
    builder.Save();
    builder.Scale(2.0, 2.0);
    flutter::DlPaint paint;
    paint.setColor(flutter::DlColor::kYellow());
    builder.DrawRect(SkRect::MakeWH(300, 300), paint);
    paint.setStrokeWidth(1.0);
    paint.setDrawStyle(flutter::DlDrawStyle::kStroke);
    paint.setColor(flutter::DlColor::kBlack().withAlpha(0x80));
    builder.DrawLine(SkPoint::Make(150, 0), SkPoint::Make(150, 300), paint);
    builder.DrawLine(SkPoint::Make(0, 150), SkPoint::Make(300, 150), paint);

    flutter::DlPaint save_paint;
    SkRect bounds = SkRect::MakeXYWH(100, 100, 100, 100);
    SkMatrix translate_matrix =
        SkMatrix::Translate(translation[0], translation[1]);
    if (enable_save_layer) {
      auto filter = flutter::DlMatrixImageFilter(
          translate_matrix, flutter::DlImageSampling::kNearestNeighbor);
      save_paint.setImageFilter(filter.shared());
      builder.SaveLayer(&bounds, &save_paint);
    } else {
      builder.Save();
      builder.Transform(translate_matrix);
    }

    SkMatrix filter_matrix = SkMatrix::I();
    filter_matrix.postTranslate(-150, -150);
    filter_matrix.postScale(0.2f, 0.2f);
    filter_matrix.postTranslate(150, 150);
    auto filter = flutter::DlMatrixImageFilter(
        filter_matrix, flutter::DlImageSampling::kNearestNeighbor);

    save_paint.setImageFilter(filter.shared());

    builder.SaveLayer(&bounds, &save_paint);
    flutter::DlPaint paint2;
    paint2.setColor(flutter::DlColor::kBlue());
    builder.DrawRect(bounds, paint2);
    builder.Restore();
    builder.Restore();
    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(DisplayListTest, CanDrawRectWithLinearToSrgbColorFilter) {
  flutter::DlPaint paint;
  paint.setColor(flutter::DlColor(0xFF2196F3).withAlpha(128));
  flutter::DisplayListBuilder builder;
  paint.setColorFilter(flutter::DlLinearToSrgbGammaColorFilter::instance.get());
  builder.DrawRect(SkRect::MakeXYWH(0, 0, 200, 200), paint);
  builder.Translate(0, 200);

  paint.setColorFilter(flutter::DlSrgbToLinearGammaColorFilter::instance.get());
  builder.DrawRect(SkRect::MakeXYWH(0, 0, 200, 200), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawPaintWithColorSource) {
  const flutter::DlColor colors[2] = {
      flutter::DlColor(0xFFF44336),
      flutter::DlColor(0xFF2196F3),
  };
  const float stops[2] = {0.0, 1.0};
  flutter::DlPaint paint;
  flutter::DisplayListBuilder builder;
  auto clip_bounds = SkRect::MakeWH(300.0, 300.0);
  builder.Save();
  builder.Translate(100, 100);
  builder.ClipRect(clip_bounds, flutter::DlCanvas::ClipOp::kIntersect, false);
  auto linear =
      flutter::DlColorSource::MakeLinear({0.0, 0.0}, {100.0, 100.0}, 2, colors,
                                         stops, flutter::DlTileMode::kRepeat);
  paint.setColorSource(linear);
  builder.DrawPaint(paint);
  builder.Restore();

  builder.Save();
  builder.Translate(500, 100);
  builder.ClipRect(clip_bounds, flutter::DlCanvas::ClipOp::kIntersect, false);
  auto radial = flutter::DlColorSource::MakeRadial(
      {100.0, 100.0}, 100.0, 2, colors, stops, flutter::DlTileMode::kRepeat);
  paint.setColorSource(radial);
  builder.DrawPaint(paint);
  builder.Restore();

  builder.Save();
  builder.Translate(100, 500);
  builder.ClipRect(clip_bounds, flutter::DlCanvas::ClipOp::kIntersect, false);
  auto sweep =
      flutter::DlColorSource::MakeSweep({100.0, 100.0}, 180.0, 270.0, 2, colors,
                                        stops, flutter::DlTileMode::kRepeat);
  paint.setColorSource(sweep);
  builder.DrawPaint(paint);
  builder.Restore();

  builder.Save();
  builder.Translate(500, 500);
  builder.ClipRect(clip_bounds, flutter::DlCanvas::ClipOp::kIntersect, false);
  auto texture = CreateTextureForFixture("table_mountain_nx.png");
  auto image = std::make_shared<flutter::DlImageColorSource>(
      DlImageImpeller::Make(texture), flutter::DlTileMode::kRepeat,
      flutter::DlTileMode::kRepeat);
  paint.setColorSource(image);
  builder.DrawPaint(paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanBlendDstOverAndDstCorrectly) {
  flutter::DisplayListBuilder builder;

  {
    builder.SaveLayer(nullptr, nullptr);
    builder.Translate(100, 100);
    flutter::DlPaint paint;
    paint.setColor(flutter::DlColor::kRed());
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    paint.setColor(flutter::DlColor::kBlue().withAlpha(127));
    paint.setBlendMode(flutter::DlBlendMode::kSrcOver);
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    builder.Restore();
  }
  {
    builder.SaveLayer(nullptr, nullptr);
    builder.Translate(300, 100);
    flutter::DlPaint paint;
    paint.setColor(flutter::DlColor::kBlue().withAlpha(127));
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    paint.setColor(flutter::DlColor::kRed());
    paint.setBlendMode(flutter::DlBlendMode::kDstOver);
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    builder.Restore();
  }
  {
    builder.SaveLayer(nullptr, nullptr);
    builder.Translate(100, 300);
    flutter::DlPaint paint;
    paint.setColor(flutter::DlColor::kRed());
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    paint.setColor(flutter::DlColor::kBlue().withAlpha(127));
    paint.setBlendMode(flutter::DlBlendMode::kSrc);
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    builder.Restore();
  }
  {
    builder.SaveLayer(nullptr, nullptr);
    builder.Translate(300, 300);
    flutter::DlPaint paint;
    paint.setColor(flutter::DlColor::kBlue().withAlpha(127));
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    paint.setColor(flutter::DlColor::kRed());
    paint.setBlendMode(flutter::DlBlendMode::kDst);
    builder.DrawRect(SkRect::MakeSize({200, 200}), paint);
    builder.Restore();
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, CanDrawCorrectlyWithColorFilterAndImageFilter) {
  flutter::DisplayListBuilder builder;
  const float green_color_matrix[20] = {
      0, 0, 0, 0, 0,  //
      0, 0, 0, 0, 1,  //
      0, 0, 0, 0, 0,  //
      0, 0, 0, 1, 0,  //
  };
  const float blue_color_matrix[20] = {
      0, 0, 0, 0, 0,  //
      0, 0, 0, 0, 0,  //
      0, 0, 0, 0, 1,  //
      0, 0, 0, 1, 0,  //
  };
  auto green_color_filter =
      std::make_shared<flutter::DlMatrixColorFilter>(green_color_matrix);
  auto blue_color_filter =
      std::make_shared<flutter::DlMatrixColorFilter>(blue_color_matrix);
  auto blue_image_filter =
      std::make_shared<flutter::DlColorFilterImageFilter>(blue_color_filter);

  flutter::DlPaint paint;
  paint.setColor(flutter::DlColor::kRed());
  paint.setColorFilter(green_color_filter);
  paint.setImageFilter(blue_image_filter);
  builder.DrawRect(SkRect::MakeLTRB(100, 100, 500, 500), paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, MaskBlursApplyCorrectlyToColorSources) {
  auto blur_filter = std::make_shared<flutter::DlBlurMaskFilter>(
      flutter::DlBlurStyle::kNormal, 10);

  flutter::DisplayListBuilder builder;

  std::array<flutter::DlColor, 2> colors = {flutter::DlColor::kBlue(),
                                            flutter::DlColor::kGreen()};
  std::array<float, 2> stops = {0, 1};
  std::array<std::shared_ptr<flutter::DlColorSource>, 2> color_sources = {
      std::make_shared<flutter::DlColorColorSource>(flutter::DlColor::kWhite()),
      flutter::DlColorSource::MakeLinear(
          SkPoint::Make(0, 0), SkPoint::Make(100, 50), 2, colors.data(),
          stops.data(), flutter::DlTileMode::kClamp)};

  int offset = 100;
  for (auto color_source : color_sources) {
    flutter::DlPaint paint;
    paint.setColorSource(color_source);
    paint.setMaskFilter(blur_filter);

    paint.setDrawStyle(flutter::DlDrawStyle::kFill);
    builder.DrawRRect(
        SkRRect::MakeRectXY(SkRect::MakeXYWH(100, offset, 100, 50), 30, 30),
        paint);
    paint.setDrawStyle(flutter::DlDrawStyle::kStroke);
    paint.setStrokeWidth(10);
    builder.DrawRRect(
        SkRRect::MakeRectXY(SkRect::MakeXYWH(300, offset, 100, 50), 30, 30),
        paint);

    offset += 100;
  }

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, DrawVerticesSolidColorTrianglesWithoutIndices) {
  // Use negative coordinates and then scale the transform by -1, -1 to make
  // sure coverage is taking the transform into account.
  std::vector<SkPoint> positions = {SkPoint::Make(-100, -300),
                                    SkPoint::Make(-200, -100),
                                    SkPoint::Make(-300, -300)};
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kWhite(),
                                          flutter::DlColor::kGreen(),
                                          flutter::DlColor::kWhite()};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      /*texture_coorindates=*/nullptr, colors.data());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColor(flutter::DlColor::kRed().modulateOpacity(0.5));
  builder.Scale(-1, -1);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, DrawVerticesLinearGradientWithoutIndices) {
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      /*texture_coorindates=*/nullptr, /*colors=*/nullptr);

  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  const float stops[2] = {0.0, 1.0};

  auto linear = flutter::DlColorSource::MakeLinear(
      {100.0, 100.0}, {300.0, 300.0}, 2, colors.data(), stops,
      flutter::DlTileMode::kRepeat);

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColorSource(linear);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, DrawVerticesLinearGradientWithTextureCoordinates) {
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};
  std::vector<SkPoint> texture_coordinates = {SkPoint::Make(300, 100),
                                              SkPoint::Make(100, 200),
                                              SkPoint::Make(300, 300)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      texture_coordinates.data(), /*colors=*/nullptr);

  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  const float stops[2] = {0.0, 1.0};

  auto linear = flutter::DlColorSource::MakeLinear(
      {100.0, 100.0}, {300.0, 300.0}, 2, colors.data(), stops,
      flutter::DlTileMode::kRepeat);

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColorSource(linear);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, DrawVerticesImageSourceWithTextureCoordinates) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  auto dl_image = DlImageImpeller::Make(texture);
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};
  std::vector<SkPoint> texture_coordinates = {
      SkPoint::Make(0, 0), SkPoint::Make(100, 200), SkPoint::Make(200, 100)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      texture_coordinates.data(), /*colors=*/nullptr);

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  auto image_source = flutter::DlImageColorSource(
      dl_image, flutter::DlTileMode::kRepeat, flutter::DlTileMode::kRepeat);

  paint.setColorSource(&image_source);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest,
       DrawVerticesImageSourceWithTextureCoordinatesAndColorBlending) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  auto dl_image = DlImageImpeller::Make(texture);
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kWhite(),
                                          flutter::DlColor::kGreen(),
                                          flutter::DlColor::kWhite()};
  std::vector<SkPoint> texture_coordinates = {
      SkPoint::Make(0, 0), SkPoint::Make(100, 200), SkPoint::Make(200, 100)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      texture_coordinates.data(), colors.data());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  auto image_source = flutter::DlImageColorSource(
      dl_image, flutter::DlTileMode::kRepeat, flutter::DlTileMode::kRepeat);

  paint.setColorSource(&image_source);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kModulate, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, DrawVerticesSolidColorTrianglesWithIndices) {
  std::vector<SkPoint> positions = {
      SkPoint::Make(100, 300), SkPoint::Make(200, 100), SkPoint::Make(300, 300),
      SkPoint::Make(200, 500)};
  std::vector<uint16_t> indices = {0, 1, 2, 0, 2, 3};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 6, positions.data(),
      /*texture_coorindates=*/nullptr, /*colors=*/nullptr, 6, indices.data());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColor(flutter::DlColor::kWhite());
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, DrawShapes) {
  flutter::DisplayListBuilder builder;
  std::vector<flutter::DlStrokeJoin> joins = {
      flutter::DlStrokeJoin::kBevel,
      flutter::DlStrokeJoin::kRound,
      flutter::DlStrokeJoin::kMiter,
  };
  flutter::DlPaint paint =                            //
      flutter::DlPaint()                              //
          .setColor(flutter::DlColor::kWhite())       //
          .setDrawStyle(flutter::DlDrawStyle::kFill)  //
          .setStrokeWidth(10);
  flutter::DlPaint stroke_paint =                       //
      flutter::DlPaint()                                //
          .setColor(flutter::DlColor::kWhite())         //
          .setDrawStyle(flutter::DlDrawStyle::kStroke)  //
          .setStrokeWidth(10);
  SkPath path = SkPath().addPoly({{150, 50}, {160, 50}}, false);

  builder.Translate(300, 50);
  builder.Scale(0.8, 0.8);
  for (auto join : joins) {
    paint.setStrokeJoin(join);
    stroke_paint.setStrokeJoin(join);
    builder.DrawRect(SkRect::MakeXYWH(0, 0, 100, 100), paint);
    builder.DrawRect(SkRect::MakeXYWH(0, 150, 100, 100), stroke_paint);
    builder.DrawRRect(
        SkRRect::MakeRectXY(SkRect::MakeXYWH(150, 0, 100, 100), 30, 30), paint);
    builder.DrawRRect(
        SkRRect::MakeRectXY(SkRect::MakeXYWH(150, 150, 100, 100), 30, 30),
        stroke_paint);
    builder.DrawCircle({350, 50}, 50, paint);
    builder.DrawCircle({350, 200}, 50, stroke_paint);
    builder.Translate(0, 300);
  }
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(DisplayListTest, DrawVerticesBlendModes) {
  std::vector<const char*> blend_mode_names;
  std::vector<flutter::DlBlendMode> blend_mode_values;
  {
    const std::vector<std::tuple<const char*, flutter::DlBlendMode>> blends = {
        // Pipeline blends (Porter-Duff alpha compositing)
        {"Clear", flutter::DlBlendMode::kClear},
        {"Source", flutter::DlBlendMode::kSrc},
        {"Destination", flutter::DlBlendMode::kDst},
        {"SourceOver", flutter::DlBlendMode::kSrcOver},
        {"DestinationOver", flutter::DlBlendMode::kDstOver},
        {"SourceIn", flutter::DlBlendMode::kSrcIn},
        {"DestinationIn", flutter::DlBlendMode::kDstIn},
        {"SourceOut", flutter::DlBlendMode::kSrcOut},
        {"DestinationOut", flutter::DlBlendMode::kDstOut},
        {"SourceATop", flutter::DlBlendMode::kSrcATop},
        {"DestinationATop", flutter::DlBlendMode::kDstATop},
        {"Xor", flutter::DlBlendMode::kXor},
        {"Plus", flutter::DlBlendMode::kPlus},
        {"Modulate", flutter::DlBlendMode::kModulate},
        // Advanced blends (color component blends)
        {"Screen", flutter::DlBlendMode::kScreen},
        {"Overlay", flutter::DlBlendMode::kOverlay},
        {"Darken", flutter::DlBlendMode::kDarken},
        {"Lighten", flutter::DlBlendMode::kLighten},
        {"ColorDodge", flutter::DlBlendMode::kColorDodge},
        {"ColorBurn", flutter::DlBlendMode::kColorBurn},
        {"HardLight", flutter::DlBlendMode::kHardLight},
        {"SoftLight", flutter::DlBlendMode::kSoftLight},
        {"Difference", flutter::DlBlendMode::kDifference},
        {"Exclusion", flutter::DlBlendMode::kExclusion},
        {"Multiply", flutter::DlBlendMode::kMultiply},
        {"Hue", flutter::DlBlendMode::kHue},
        {"Saturation", flutter::DlBlendMode::kSaturation},
        {"Color", flutter::DlBlendMode::kColor},
        {"Luminosity", flutter::DlBlendMode::kLuminosity},
    };
    assert(blends.size() ==
           static_cast<size_t>(flutter::DlBlendMode::kLastMode) + 1);
    for (const auto& [name, mode] : blends) {
      blend_mode_names.push_back(name);
      blend_mode_values.push_back(mode);
    }
  }

  auto callback = [&]() {
    static int current_blend_index = 3;
    static float dst_alpha = 1;
    static float src_alpha = 1;
    static float color0[4] = {1.0f, 0.0f, 0.0f, 1.0f};
    static float color1[4] = {0.0f, 1.0f, 0.0f, 1.0f};
    static float color2[4] = {0.0f, 0.0f, 1.0f, 1.0f};
    static float src_color[4] = {1.0f, 1.0f, 1.0f, 1.0f};

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      ImGui::ListBox("Blending mode", &current_blend_index,
                     blend_mode_names.data(), blend_mode_names.size());
      ImGui::SliderFloat("Source alpha", &src_alpha, 0, 1);
      ImGui::ColorEdit4("Color A", color0);
      ImGui::ColorEdit4("Color B", color1);
      ImGui::ColorEdit4("Color C", color2);
      ImGui::ColorEdit4("Source Color", src_color);
      ImGui::SliderFloat("Destination alpha", &dst_alpha, 0, 1);
    }
    ImGui::End();

    std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                      SkPoint::Make(200, 100),
                                      SkPoint::Make(300, 300)};
    std::vector<flutter::DlColor> colors = {
        toColor(color0).modulateOpacity(dst_alpha),
        toColor(color1).modulateOpacity(dst_alpha),
        toColor(color2).modulateOpacity(dst_alpha)};

    auto vertices = flutter::DlVertices::Make(
        flutter::DlVertexMode::kTriangles, 3, positions.data(),
        /*texture_coorindates=*/nullptr, colors.data());

    flutter::DisplayListBuilder builder;
    flutter::DlPaint paint;

    paint.setColor(toColor(src_color).modulateOpacity(src_alpha));
    builder.DrawVertices(vertices, blend_mode_values[current_blend_index],
                         paint);
    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

#ifdef IMPELLER_ENABLE_3D
TEST_P(DisplayListTest, SceneColorSource) {
  // Load up the scene.
  auto mapping =
      flutter::testing::OpenFixtureAsMapping("flutter_logo_baked.glb.ipscene");
  ASSERT_NE(mapping, nullptr);

  std::shared_ptr<scene::Node> gltf_scene =
      impeller::scene::Node::MakeFromFlatbuffer(
          *mapping, *GetContext()->GetResourceAllocator());
  ASSERT_NE(gltf_scene, nullptr);

  flutter::DisplayListBuilder builder;

  auto color_source = std::make_shared<flutter::DlSceneColorSource>(
      gltf_scene,
      Matrix::MakePerspective(Degrees(45), GetWindowSize(), 0.1, 1000) *
          Matrix::MakeLookAt({3, 2, -5}, {0, 0, 0}, {0, 1, 0}));

  flutter::DlPaint paint = flutter::DlPaint().setColorSource(color_source);

  builder.DrawPaint(paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}
#endif

}  // namespace testing
}  // namespace impeller

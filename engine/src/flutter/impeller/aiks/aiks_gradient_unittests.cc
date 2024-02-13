// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/aiks_unittests.h"

#include "impeller/aiks/canvas.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/playground/widgets.h"
#include "third_party/imgui/imgui.h"

////////////////////////////////////////////////////////////////////////////////
// This is for tests of Canvas that are interested the results of rendering
// gradients.
////////////////////////////////////////////////////////////////////////////////

namespace impeller {
namespace testing {

namespace {
void CanRenderLinearGradient(AiksTest* aiks_test, Entity::TileMode tile_mode) {
  Canvas canvas;
  canvas.Scale(aiks_test->GetContentScale());
  Paint paint;
  canvas.Translate({100.0f, 0, 0});

  std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                               Color{0.1294, 0.5882, 0.9529, 0.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {200, 200}, std::move(colors), std::move(stops), tile_mode, {});

  paint.color = Color(1.0, 1.0, 1.0, 1.0);
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}
}  // namespace

TEST_P(AiksTest, CanRenderLinearGradientClamp) {
  CanRenderLinearGradient(this, Entity::TileMode::kClamp);
}
TEST_P(AiksTest, CanRenderLinearGradientRepeat) {
  CanRenderLinearGradient(this, Entity::TileMode::kRepeat);
}
TEST_P(AiksTest, CanRenderLinearGradientMirror) {
  CanRenderLinearGradient(this, Entity::TileMode::kMirror);
}
TEST_P(AiksTest, CanRenderLinearGradientDecal) {
  CanRenderLinearGradient(this, Entity::TileMode::kDecal);
}

TEST_P(AiksTest, CanRenderLinearGradientDecalWithColorFilter) {
  Canvas canvas;
  canvas.Scale(GetContentScale());
  Paint paint;
  canvas.Translate({100.0f, 0, 0});

  std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                               Color{0.1294, 0.5882, 0.9529, 0.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {200, 200}, std::move(colors), std::move(stops),
      Entity::TileMode::kDecal, {});
  // Overlay the gradient with 25% green. This should appear as the entire
  // rectangle being drawn with 25% green, including the border area outside the
  // decal gradient.
  paint.color_filter = ColorFilter::MakeBlend(BlendMode::kSourceOver,
                                              Color::Green().WithAlpha(0.25));

  paint.color = Color(1.0, 1.0, 1.0, 1.0);
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

static void CanRenderLinearGradientWithDithering(AiksTest* aiks_test,
                                                 bool use_dithering) {
  Canvas canvas;
  Paint paint;
  canvas.Translate({100.0, 100.0, 0});

  // 0xffcccccc --> 0xff333333, taken from
  // https://github.com/flutter/flutter/issues/118073#issue-1521699748
  std::vector<Color> colors = {Color{0.8, 0.8, 0.8, 1.0},
                               Color{0.2, 0.2, 0.2, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {800, 500}, std::move(colors), std::move(stops),
      Entity::TileMode::kClamp, {});
  paint.dither = use_dithering;
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 800, 500), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderLinearGradientWithDitheringDisabled) {
  CanRenderLinearGradientWithDithering(this, false);
}

TEST_P(AiksTest, CanRenderLinearGradientWithDitheringEnabled) {
  CanRenderLinearGradientWithDithering(this, true);
}  // namespace

static void CanRenderRadialGradientWithDithering(AiksTest* aiks_test,
                                                 bool use_dithering) {
  Canvas canvas;
  Paint paint;
  canvas.Translate({100.0, 100.0, 0});

  // #FFF -> #000
  std::vector<Color> colors = {Color{1.0, 1.0, 1.0, 1.0},
                               Color{0.0, 0.0, 0.0, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.color_source = ColorSource::MakeRadialGradient(
      {600, 600}, 600, std::move(colors), std::move(stops),
      Entity::TileMode::kClamp, {});
  paint.dither = use_dithering;
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 1200, 1200), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderRadialGradientWithDitheringDisabled) {
  CanRenderRadialGradientWithDithering(this, false);
}

TEST_P(AiksTest, CanRenderRadialGradientWithDitheringEnabled) {
  CanRenderRadialGradientWithDithering(this, true);
}

static void CanRenderSweepGradientWithDithering(AiksTest* aiks_test,
                                                bool use_dithering) {
  Canvas canvas;
  canvas.Scale(aiks_test->GetContentScale());
  Paint paint;
  canvas.Translate({100.0, 100.0, 0});

  // #FFF -> #000
  std::vector<Color> colors = {Color{1.0, 1.0, 1.0, 1.0},
                               Color{0.0, 0.0, 0.0, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.color_source = ColorSource::MakeSweepGradient(
      {100, 100}, Degrees(45), Degrees(135), std::move(colors),
      std::move(stops), Entity::TileMode::kMirror, {});
  paint.dither = use_dithering;

  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderSweepGradientWithDitheringDisabled) {
  CanRenderSweepGradientWithDithering(this, false);
}

TEST_P(AiksTest, CanRenderSweepGradientWithDitheringEnabled) {
  CanRenderSweepGradientWithDithering(this, true);
}

static void CanRenderConicalGradientWithDithering(AiksTest* aiks_test,
                                                  bool use_dithering) {
  Canvas canvas;
  canvas.Scale(aiks_test->GetContentScale());
  Paint paint;
  canvas.Translate({100.0, 100.0, 0});

  // #FFF -> #000
  std::vector<Color> colors = {Color{1.0, 1.0, 1.0, 1.0},
                               Color{0.0, 0.0, 0.0, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.color_source = ColorSource::MakeConicalGradient(
      {100, 100}, 100, std::move(colors), std::move(stops), {0, 1}, 0,
      Entity::TileMode::kMirror, {});
  paint.dither = use_dithering;

  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderConicalGradientWithDitheringDisabled) {
  CanRenderConicalGradientWithDithering(this, false);
}

TEST_P(AiksTest, CanRenderConicalGradientWithDitheringEnabled) {
  CanRenderConicalGradientWithDithering(this, true);
}

namespace {
void CanRenderLinearGradientWithOverlappingStops(AiksTest* aiks_test,
                                                 Entity::TileMode tile_mode) {
  Canvas canvas;
  Paint paint;
  canvas.Translate({100.0, 100.0, 0});

  std::vector<Color> colors = {
      Color{0.9568, 0.2627, 0.2118, 1.0}, Color{0.9568, 0.2627, 0.2118, 1.0},
      Color{0.1294, 0.5882, 0.9529, 1.0}, Color{0.1294, 0.5882, 0.9529, 1.0}};
  std::vector<Scalar> stops = {0.0, 0.5, 0.5, 1.0};

  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {500, 500}, std::move(colors), std::move(stops), tile_mode, {});

  paint.color = Color(1.0, 1.0, 1.0, 1.0);
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 500, 500), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}
}  // namespace

// Only clamp is necessary. All tile modes are the same output.
TEST_P(AiksTest, CanRenderLinearGradientWithOverlappingStopsClamp) {
  CanRenderLinearGradientWithOverlappingStops(this, Entity::TileMode::kClamp);
}

namespace {
void CanRenderLinearGradientManyColors(AiksTest* aiks_test,
                                       Entity::TileMode tile_mode) {
  Canvas canvas;
  canvas.Scale(aiks_test->GetContentScale());
  Paint paint;
  canvas.Translate({100, 100, 0});

  std::vector<Color> colors = {
      Color{0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0},
      Color{0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0},
      Color{0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0},
      Color{0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0},
      Color{0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0},
      Color{0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0},
      Color{0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0}};
  std::vector<Scalar> stops = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };

  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {200, 200}, std::move(colors), std::move(stops), tile_mode, {});

  paint.color = Color(1.0, 1.0, 1.0, 1.0);
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  canvas.Restore();
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}
}  // namespace

TEST_P(AiksTest, CanRenderLinearGradientManyColorsClamp) {
  CanRenderLinearGradientManyColors(this, Entity::TileMode::kClamp);
}
TEST_P(AiksTest, CanRenderLinearGradientManyColorsRepeat) {
  CanRenderLinearGradientManyColors(this, Entity::TileMode::kRepeat);
}
TEST_P(AiksTest, CanRenderLinearGradientManyColorsMirror) {
  CanRenderLinearGradientManyColors(this, Entity::TileMode::kMirror);
}
TEST_P(AiksTest, CanRenderLinearGradientManyColorsDecal) {
  CanRenderLinearGradientManyColors(this, Entity::TileMode::kDecal);
}

namespace {
void CanRenderLinearGradientWayManyColors(AiksTest* aiks_test,
                                          Entity::TileMode tile_mode) {
  Canvas canvas;
  Paint paint;
  canvas.Translate({100.0, 100.0, 0});
  auto color = Color{0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0};
  std::vector<Color> colors;
  std::vector<Scalar> stops;
  auto current_stop = 0.0;
  for (int i = 0; i < 2000; i++) {
    colors.push_back(color);
    stops.push_back(current_stop);
    current_stop += 1 / 2000.0;
  }
  stops[2000 - 1] = 1.0;

  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {200, 200}, std::move(colors), std::move(stops), tile_mode, {});

  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}
}  // namespace

// Only test clamp on purpose since they all look the same.
TEST_P(AiksTest, CanRenderLinearGradientWayManyColorsClamp) {
  CanRenderLinearGradientWayManyColors(this, Entity::TileMode::kClamp);
}

TEST_P(AiksTest, CanRenderLinearGradientManyColorsUnevenStops) {
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                   sizeof(tile_mode_names) / sizeof(char*));
      std::string label = "##1";
      for (int i = 0; i < 4; i++) {
        ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float,
                            &(matrix.vec[i]), 4, NULL, NULL, "%.2f", 0);
        label[2]++;
      }
      ImGui::End();
    }

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];

    std::vector<Color> colors = {
        Color{0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0},
        Color{0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0},
        Color{0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0},
        Color{0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0},
        Color{0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0},
        Color{0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0},
        Color{0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0}};
    std::vector<Scalar> stops = {
        0.0, 2.0 / 62.0, 4.0 / 62.0, 8.0 / 62.0, 16.0 / 62.0, 32.0 / 62.0, 1.0,
    };

    paint.color_source = ColorSource::MakeLinearGradient(
        {0, 0}, {200, 200}, std::move(colors), std::move(stops), tile_mode, {});

    canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderLinearGradientMaskBlur) {
  Canvas canvas;

  Paint paint = {
      .color = Color::White(),
      .color_source = ColorSource::MakeLinearGradient(
          {200, 200}, {400, 400},
          {Color::Red(), Color::White(), Color::Red(), Color::White(),
           Color::Red(), Color::White(), Color::Red(), Color::White(),
           Color::Red(), Color::White(), Color::Red()},
          {0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0},
          Entity::TileMode::kClamp, {}),
      .mask_blur_descriptor =
          Paint::MaskBlurDescriptor{
              .style = FilterContents::BlurStyle::kNormal,
              .sigma = Sigma(20),
          },
  };

  canvas.DrawCircle({300, 300}, 200, paint);
  canvas.DrawRect(Rect::MakeLTRB(100, 300, 500, 600), paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderRadialGradient) {
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                   sizeof(tile_mode_names) / sizeof(char*));
      std::string label = "##1";
      for (int i = 0; i < 4; i++) {
        ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float,
                            &(matrix.vec[i]), 4, NULL, NULL, "%.2f", 0);
        label[2]++;
      }
      ImGui::End();
    }

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];

    std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                 Color{0.1294, 0.5882, 0.9529, 1.0}};
    std::vector<Scalar> stops = {0.0, 1.0};

    paint.color_source = ColorSource::MakeRadialGradient(
        {100, 100}, 100, std::move(colors), std::move(stops), tile_mode, {});

    canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderRadialGradientManyColors) {
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                   sizeof(tile_mode_names) / sizeof(char*));
      std::string label = "##1";
      for (int i = 0; i < 4; i++) {
        ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float,
                            &(matrix.vec[i]), 4, NULL, NULL, "%.2f", 0);
        label[2]++;
      }
      ImGui::End();
    }

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];

    std::vector<Color> colors = {
        Color{0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0},
        Color{0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0},
        Color{0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0},
        Color{0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0},
        Color{0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0},
        Color{0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0},
        Color{0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0}};
    std::vector<Scalar> stops = {
        0.0,
        (1.0 / 6.0) * 1,
        (1.0 / 6.0) * 2,
        (1.0 / 6.0) * 3,
        (1.0 / 6.0) * 4,
        (1.0 / 6.0) * 5,
        1.0,
    };

    paint.color_source = ColorSource::MakeRadialGradient(
        {100, 100}, 100, std::move(colors), std::move(stops), tile_mode, {});

    canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

namespace {
void CanRenderSweepGradient(AiksTest* aiks_test, Entity::TileMode tile_mode) {
  Canvas canvas;
  canvas.Scale(aiks_test->GetContentScale());
  Paint paint;
  canvas.Translate({100, 100, 0});

  std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                               Color{0.1294, 0.5882, 0.9529, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  paint.color_source = ColorSource::MakeSweepGradient(
      {100, 100}, Degrees(45), Degrees(135), std::move(colors),
      std::move(stops), tile_mode, {});

  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}
}  // namespace

TEST_P(AiksTest, CanRenderSweepGradientClamp) {
  CanRenderSweepGradient(this, Entity::TileMode::kClamp);
}
TEST_P(AiksTest, CanRenderSweepGradientRepeat) {
  CanRenderSweepGradient(this, Entity::TileMode::kRepeat);
}
TEST_P(AiksTest, CanRenderSweepGradientMirror) {
  CanRenderSweepGradient(this, Entity::TileMode::kMirror);
}
TEST_P(AiksTest, CanRenderSweepGradientDecal) {
  CanRenderSweepGradient(this, Entity::TileMode::kDecal);
}

namespace {
void CanRenderSweepGradientManyColors(AiksTest* aiks_test,
                                      Entity::TileMode tile_mode) {
  Canvas canvas;
  Paint paint;
  canvas.Translate({100.0, 100.0, 0});

  std::vector<Color> colors = {
      Color{0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0},
      Color{0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0},
      Color{0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0},
      Color{0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0},
      Color{0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0},
      Color{0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0},
      Color{0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0}};
  std::vector<Scalar> stops = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };

  paint.color_source = ColorSource::MakeSweepGradient(
      {100, 100}, Degrees(45), Degrees(135), std::move(colors),
      std::move(stops), tile_mode, {});

  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);
  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}
}  // namespace

TEST_P(AiksTest, CanRenderSweepGradientManyColorsClamp) {
  CanRenderSweepGradientManyColors(this, Entity::TileMode::kClamp);
}
TEST_P(AiksTest, CanRenderSweepGradientManyColorsRepeat) {
  CanRenderSweepGradientManyColors(this, Entity::TileMode::kRepeat);
}
TEST_P(AiksTest, CanRenderSweepGradientManyColorsMirror) {
  CanRenderSweepGradientManyColors(this, Entity::TileMode::kMirror);
}
TEST_P(AiksTest, CanRenderSweepGradientManyColorsDecal) {
  CanRenderSweepGradientManyColors(this, Entity::TileMode::kDecal);
}

TEST_P(AiksTest, CanRenderConicalGradient) {
  Scalar size = 256;
  Canvas canvas;
  Paint paint;
  paint.color = Color::White();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, size * 3, size * 3), paint);
  std::vector<Color> colors = {Color::MakeRGBA8(0xF4, 0x43, 0x36, 0xFF),
                               Color::MakeRGBA8(0xFF, 0xEB, 0x3B, 0xFF),
                               Color::MakeRGBA8(0x4c, 0xAF, 0x50, 0xFF),
                               Color::MakeRGBA8(0x21, 0x96, 0xF3, 0xFF)};
  std::vector<Scalar> stops = {0.0, 1.f / 3.f, 2.f / 3.f, 1.0};
  std::array<std::tuple<Point, float, Point, float>, 8> array{
      std::make_tuple(Point{size / 2.f, size / 2.f}, 0.f,
                      Point{size / 2.f, size / 2.f}, size / 2.f),
      std::make_tuple(Point{size / 2.f, size / 2.f}, size / 4.f,
                      Point{size / 2.f, size / 2.f}, size / 2.f),
      std::make_tuple(Point{size / 4.f, size / 4.f}, 0.f,
                      Point{size / 2.f, size / 2.f}, size / 2.f),
      std::make_tuple(Point{size / 4.f, size / 4.f}, size / 2.f,
                      Point{size / 2.f, size / 2.f}, 0),
      std::make_tuple(Point{size / 4.f, size / 4.f}, size / 4.f,
                      Point{size / 2.f, size / 2.f}, size / 2.f),
      std::make_tuple(Point{size / 4.f, size / 4.f}, size / 16.f,
                      Point{size / 2.f, size / 2.f}, size / 8.f),
      std::make_tuple(Point{size / 4.f, size / 4.f}, size / 8.f,
                      Point{size / 2.f, size / 2.f}, size / 16.f),
      std::make_tuple(Point{size / 8.f, size / 8.f}, size / 8.f,
                      Point{size / 2.f, size / 2.f}, size / 8.f),
  };
  for (int i = 0; i < 8; i++) {
    canvas.Save();
    canvas.Translate({(i % 3) * size, i / 3 * size, 0});
    paint.color_source = ColorSource::MakeConicalGradient(
        std::get<0>(array[i]), std::get<1>(array[i]), colors, stops,
        std::get<2>(array[i]), std::get<3>(array[i]), Entity::TileMode::kClamp,
        {});
    canvas.DrawRect(Rect::MakeXYWH(0, 0, size, size), paint);
    canvas.Restore();
  }
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderGradientDecalWithBackground) {
  std::vector<Color> colors = {Color::MakeRGBA8(0xF4, 0x43, 0x36, 0xFF),
                               Color::MakeRGBA8(0xFF, 0xEB, 0x3B, 0xFF),
                               Color::MakeRGBA8(0x4c, 0xAF, 0x50, 0xFF),
                               Color::MakeRGBA8(0x21, 0x96, 0xF3, 0xFF)};
  std::vector<Scalar> stops = {0.0, 1.f / 3.f, 2.f / 3.f, 1.0};

  std::array<ColorSource, 3> color_sources = {
      ColorSource::MakeLinearGradient({0, 0}, {100, 100}, colors, stops,
                                      Entity::TileMode::kDecal, {}),
      ColorSource::MakeRadialGradient({100, 100}, 100, colors, stops,
                                      Entity::TileMode::kDecal, {}),
      ColorSource::MakeSweepGradient({100, 100}, Degrees(45), Degrees(135),
                                     colors, stops, Entity::TileMode::kDecal,
                                     {}),
  };

  Canvas canvas;
  Paint paint;
  paint.color = Color::White();
  canvas.DrawRect(Rect::MakeLTRB(0, 0, 605, 205), paint);
  for (int i = 0; i < 3; i++) {
    canvas.Save();
    canvas.Translate({i * 200.0f, 0, 0});
    paint.color_source = color_sources[i];
    canvas.DrawRect(Rect::MakeLTRB(0, 0, 200, 200), paint);
    canvas.Restore();
  }
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

#define APPLY_COLOR_FILTER_GRADIENT_TEST(name)                                 \
  TEST_P(AiksTest, name##GradientApplyColorFilter) {                           \
    auto contents = name##GradientContents();                                  \
    contents.SetColors({Color::CornflowerBlue().WithAlpha(0.75)});             \
    auto result = contents.ApplyColorFilter([](const Color& color) {           \
      return color.Blend(Color::LimeGreen().WithAlpha(0.75),                   \
                         BlendMode::kScreen);                                  \
    });                                                                        \
    ASSERT_TRUE(result);                                                       \
                                                                               \
    std::vector<Color> expected = {Color(0.433247, 0.879523, 0.825324, 0.75)}; \
    ASSERT_COLORS_NEAR(contents.GetColors(), expected);                        \
  }

APPLY_COLOR_FILTER_GRADIENT_TEST(Linear);
APPLY_COLOR_FILTER_GRADIENT_TEST(Radial);
APPLY_COLOR_FILTER_GRADIENT_TEST(Conical);
APPLY_COLOR_FILTER_GRADIENT_TEST(Sweep);

TEST_P(AiksTest, GradientStrokesRenderCorrectly) {
  // Compare with https://fiddle.skia.org/c/027392122bec8ac2b5d5de00a4b9bbe2
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    static float scale = 3;
    static bool add_circle_clip = true;
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};
    static int selected_tile_mode = 0;
    static float alpha = 1;

    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Scale", &scale, 0, 6);
      ImGui::Checkbox("Circle clip", &add_circle_clip);
      ImGui::SliderFloat("Alpha", &alpha, 0, 1);
      ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                   sizeof(tile_mode_names) / sizeof(char*));
      ImGui::End();
    }

    Canvas canvas;
    canvas.Scale(GetContentScale());
    Paint paint;
    paint.color = Color::White();
    canvas.DrawPaint(paint);

    paint.style = Paint::Style::kStroke;
    paint.color = Color(1.0, 1.0, 1.0, alpha);
    paint.stroke_width = 10;
    auto tile_mode = tile_modes[selected_tile_mode];

    std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                 Color{0.1294, 0.5882, 0.9529, 1.0}};
    std::vector<Scalar> stops = {0.0, 1.0};

    paint.color_source = ColorSource::MakeLinearGradient(
        {0, 0}, {50, 50}, std::move(colors), std::move(stops), tile_mode, {});

    Path path = PathBuilder{}
                    .MoveTo({20, 20})
                    .QuadraticCurveTo({60, 20}, {60, 60})
                    .Close()
                    .MoveTo({60, 20})
                    .QuadraticCurveTo({60, 60}, {20, 60})
                    .TakePath();

    canvas.Scale(Vector2(scale, scale));

    if (add_circle_clip) {
      static PlaygroundPoint circle_clip_point_a(Point(60, 300), 20,
                                                 Color::Red());
      static PlaygroundPoint circle_clip_point_b(Point(600, 300), 20,
                                                 Color::Red());
      auto [handle_a, handle_b] =
          DrawPlaygroundLine(circle_clip_point_a, circle_clip_point_b);

      auto screen_to_canvas = canvas.GetCurrentTransform().Invert();
      Point point_a = screen_to_canvas * handle_a * GetContentScale();
      Point point_b = screen_to_canvas * handle_b * GetContentScale();

      Point middle = (point_a + point_b) / 2;
      auto radius = point_a.GetDistance(middle);
      canvas.ClipPath(PathBuilder{}.AddCircle(middle, radius).TakePath());
    }

    for (auto join : {Join::kBevel, Join::kRound, Join::kMiter}) {
      paint.stroke_join = join;
      for (auto cap : {Cap::kButt, Cap::kSquare, Cap::kRound}) {
        paint.stroke_cap = cap;
        canvas.DrawPath(path, paint);
        canvas.Translate({80, 0});
      }
      canvas.Translate({-240, 60});
    }

    return canvas.EndRecordingAsPicture();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

}  // namespace testing
}  // namespace impeller

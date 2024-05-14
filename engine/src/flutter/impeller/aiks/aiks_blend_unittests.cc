// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/aiks_unittests.h"

#include "flutter/testing/testing.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/color_filter.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/scalar.h"

////////////////////////////////////////////////////////////////////////////////
// This is for tests of Canvas that are interested the results of rendering
// blends.
////////////////////////////////////////////////////////////////////////////////

namespace impeller {
namespace testing {

TEST_P(AiksTest, CanRenderAdvancedBlendColorFilterWithSaveLayer) {
  Canvas canvas;

  Rect layer_rect = Rect::MakeXYWH(0, 0, 500, 500);
  canvas.ClipRect(layer_rect);

  canvas.SaveLayer(
      {
          .color_filter = ColorFilter::MakeBlend(BlendMode::kDifference,
                                                 Color(0, 1, 0, 0.5)),
      },
      layer_rect);

  Paint paint;
  canvas.DrawPaint({.color = Color::Black()});
  canvas.DrawRect(Rect::MakeXYWH(100, 100, 300, 300),
                  {.color = Color::White()});
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, BlendModeShouldCoverWholeScreen) {
  Canvas canvas;
  Paint paint;

  paint.color = Color::Red();
  canvas.DrawPaint(paint);

  paint.blend_mode = BlendMode::kSourceOver;
  canvas.SaveLayer(paint);

  paint.color = Color::White();
  canvas.DrawRect(Rect::MakeXYWH(100, 100, 400, 400), paint);

  paint.blend_mode = BlendMode::kSource;
  canvas.SaveLayer(paint);

  paint.color = Color::Blue();
  canvas.DrawRect(Rect::MakeXYWH(200, 200, 200, 200), paint);

  canvas.Restore();
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanDrawPaintWithAdvancedBlend) {
  Canvas canvas;
  canvas.Scale(Vector2(0.2, 0.2));
  canvas.DrawPaint({.color = Color::MediumTurquoise()});
  canvas.DrawPaint({.color = Color::Color::OrangeRed().WithAlpha(0.5),
                    .blend_mode = BlendMode::kHue});
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, DrawPaintWithAdvancedBlendOverFilter) {
  Paint filtered = {
      .color = Color::Black(),
      .mask_blur_descriptor =
          Paint::MaskBlurDescriptor{
              .style = FilterContents::BlurStyle::kNormal,
              .sigma = Sigma(60),
          },
  };

  Canvas canvas;
  canvas.DrawPaint({.color = Color::White()});
  canvas.DrawCircle({300, 300}, 200, filtered);
  canvas.DrawPaint({.color = Color::Green(), .blend_mode = BlendMode::kScreen});
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, DrawAdvancedBlendPartlyOffscreen) {
  std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                               Color{0.1294, 0.5882, 0.9529, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  Paint paint = {
      .color_source = ColorSource::MakeLinearGradient(
          {0, 0}, {100, 100}, std::move(colors), std::move(stops),
          Entity::TileMode::kRepeat, Matrix::MakeScale(Vector3(0.3, 0.3, 0.3))),
      .blend_mode = BlendMode::kLighten,
  };

  Canvas canvas;
  canvas.DrawPaint({.color = Color::Blue()});
  canvas.Scale(Vector2(2, 2));
  canvas.ClipRect(Rect::MakeLTRB(0, 0, 200, 200));
  canvas.DrawCircle({100, 100}, 100, paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, PaintBlendModeIsRespected) {
  Paint paint;
  Canvas canvas;
  // Default is kSourceOver.
  paint.color = Color(1, 0, 0, 0.5);
  canvas.DrawCircle(Point(150, 200), 100, paint);
  paint.color = Color(0, 1, 0, 0.5);
  canvas.DrawCircle(Point(250, 200), 100, paint);

  paint.blend_mode = BlendMode::kPlus;
  paint.color = Color::Red();
  canvas.DrawCircle(Point(450, 250), 100, paint);
  paint.color = Color::Green();
  canvas.DrawCircle(Point(550, 250), 100, paint);
  paint.color = Color::Blue();
  canvas.DrawCircle(Point(500, 150), 100, paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

// Bug: https://github.com/flutter/flutter/issues/142549
TEST_P(AiksTest, BlendModePlusAlphaWideGamut) {
  EXPECT_EQ(GetContext()->GetCapabilities()->GetDefaultColorFormat(),
            PixelFormat::kB10G10R10A10XR);
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);

  Canvas canvas;
  canvas.Scale(GetContentScale());
  canvas.DrawPaint({.color = Color(0.9, 1.0, 0.9, 1.0)});
  canvas.SaveLayer({});
  Paint paint;
  paint.blend_mode = BlendMode::kPlus;
  paint.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(100, 100, 400, 400), paint);
  paint.color = Color::White();
  canvas.DrawImageRect(
      std::make_shared<Image>(texture), Rect::MakeSize(texture->GetSize()),
      Rect::MakeXYWH(100, 100, 400, 400).Expand(-100, -100), paint);
  canvas.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

// Bug: https://github.com/flutter/flutter/issues/142549
TEST_P(AiksTest, BlendModePlusAlphaColorFilterWideGamut) {
  EXPECT_EQ(GetContext()->GetCapabilities()->GetDefaultColorFormat(),
            PixelFormat::kB10G10R10A10XR);
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);

  Canvas canvas;
  canvas.Scale(GetContentScale());
  canvas.DrawPaint({.color = Color(0.1, 0.2, 0.1, 1.0)});
  canvas.SaveLayer({
      .color_filter =
          ColorFilter::MakeBlend(BlendMode::kPlus, Color(Vector4{1, 0, 0, 1})),
  });
  Paint paint;
  paint.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(100, 100, 400, 400), paint);
  paint.color = Color::White();
  canvas.DrawImageRect(
      std::make_shared<Image>(texture), Rect::MakeSize(texture->GetSize()),
      Rect::MakeXYWH(100, 100, 400, 400).Expand(-100, -100), paint);
  canvas.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

#define BLEND_MODE_TUPLE(blend_mode) {#blend_mode, BlendMode::k##blend_mode},

struct BlendModeSelection {
  std::vector<const char*> blend_mode_names;
  std::vector<BlendMode> blend_mode_values;
};

static BlendModeSelection GetBlendModeSelection() {
  std::vector<const char*> blend_mode_names;
  std::vector<BlendMode> blend_mode_values;
  {
    const std::vector<std::tuple<const char*, BlendMode>> blends = {
        IMPELLER_FOR_EACH_BLEND_MODE(BLEND_MODE_TUPLE)};
    assert(blends.size() ==
           static_cast<size_t>(Entity::kLastAdvancedBlendMode) + 1);
    for (const auto& [name, mode] : blends) {
      blend_mode_names.push_back(name);
      blend_mode_values.push_back(mode);
    }
  }

  return {blend_mode_names, blend_mode_values};
}

TEST_P(AiksTest, ColorWheel) {
  // Compare with https://fiddle.skia.org/c/@BlendModes

  BlendModeSelection blend_modes = GetBlendModeSelection();

  auto draw_color_wheel = [](Canvas& canvas) {
    /// color_wheel_sampler: r=0 -> fuchsia, r=2pi/3 -> yellow, r=4pi/3 ->
    /// cyan domain: r >= 0 (because modulo used is non euclidean)
    auto color_wheel_sampler = [](Radians r) {
      Scalar x = r.radians / k2Pi + 1;

      // https://www.desmos.com/calculator/6nhjelyoaj
      auto color_cycle = [](Scalar x) {
        Scalar cycle = std::fmod(x, 6.0f);
        return std::max(0.0f, std::min(1.0f, 2 - std::abs(2 - cycle)));
      };
      return Color(color_cycle(6 * x + 1),  //
                   color_cycle(6 * x - 1),  //
                   color_cycle(6 * x - 3),  //
                   1);
    };

    Paint paint;
    paint.blend_mode = BlendMode::kSourceOver;

    // Draw a fancy color wheel for the backdrop.
    // https://www.desmos.com/calculator/xw7kafthwd
    const int max_dist = 900;
    for (int i = 0; i <= 900; i++) {
      Radians r(kPhi / k2Pi * i);
      Scalar distance = r.radians / std::powf(4.12, 0.0026 * r.radians);
      Scalar normalized_distance = static_cast<Scalar>(i) / max_dist;

      paint.color =
          color_wheel_sampler(r).WithAlpha(1.0f - normalized_distance);
      Point position(distance * std::sin(r.radians),
                     -distance * std::cos(r.radians));

      canvas.DrawCircle(position, 9 + normalized_distance * 3, paint);
    }
  };

  std::shared_ptr<Image> color_wheel_image;
  Matrix color_wheel_transform;

  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    // UI state.
    static bool cache_the_wheel = true;
    static int current_blend_index = 3;
    static float dst_alpha = 1;
    static float src_alpha = 1;
    static Color color0 = Color::Red();
    static Color color1 = Color::Green();
    static Color color2 = Color::Blue();

    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::Checkbox("Cache the wheel", &cache_the_wheel);
      ImGui::ListBox("Blending mode", &current_blend_index,
                     blend_modes.blend_mode_names.data(),
                     blend_modes.blend_mode_names.size());
      ImGui::SliderFloat("Source alpha", &src_alpha, 0, 1);
      ImGui::ColorEdit4("Color A", reinterpret_cast<float*>(&color0));
      ImGui::ColorEdit4("Color B", reinterpret_cast<float*>(&color1));
      ImGui::ColorEdit4("Color C", reinterpret_cast<float*>(&color2));
      ImGui::SliderFloat("Destination alpha", &dst_alpha, 0, 1);
      ImGui::End();
    }

    static Point content_scale;
    Point new_content_scale = GetContentScale();

    if (!cache_the_wheel || new_content_scale != content_scale) {
      content_scale = new_content_scale;

      // Render the color wheel to an image.

      Canvas canvas;
      canvas.Scale(content_scale);

      canvas.Translate(Vector2(500, 400));
      canvas.Scale(Vector2(3, 3));

      draw_color_wheel(canvas);
      auto color_wheel_picture = canvas.EndRecordingAsPicture();
      auto snapshot = color_wheel_picture.Snapshot(renderer);
      if (!snapshot.has_value() || !snapshot->texture) {
        return std::nullopt;
      }
      color_wheel_image = std::make_shared<Image>(snapshot->texture);
      color_wheel_transform = snapshot->transform;
    }

    Canvas canvas;

    // Blit the color wheel backdrop to the screen with managed alpha.
    canvas.SaveLayer({.color = Color::White().WithAlpha(dst_alpha),
                      .blend_mode = BlendMode::kSource});
    {
      canvas.DrawPaint({.color = Color::White()});

      canvas.Save();
      canvas.Transform(color_wheel_transform);
      canvas.DrawImage(color_wheel_image, Point(), Paint());
      canvas.Restore();
    }
    canvas.Restore();

    canvas.Scale(content_scale);
    canvas.Translate(Vector2(500, 400));
    canvas.Scale(Vector2(3, 3));

    // Draw 3 circles to a subpass and blend it in.
    canvas.SaveLayer(
        {.color = Color::White().WithAlpha(src_alpha),
         .blend_mode = blend_modes.blend_mode_values[current_blend_index]});
    {
      Paint paint;
      paint.blend_mode = BlendMode::kPlus;
      const Scalar x = std::sin(k2Pi / 3);
      const Scalar y = -std::cos(k2Pi / 3);
      paint.color = color0;
      canvas.DrawCircle(Point(-x, y) * 45, 65, paint);
      paint.color = color1;
      canvas.DrawCircle(Point(0, -1) * 45, 65, paint);
      paint.color = color2;
      canvas.DrawCircle(Point(x, y) * 45, 65, paint);
    }
    canvas.Restore();

    return canvas.EndRecordingAsPicture();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ForegroundBlendSubpassCollapseOptimization) {
  Canvas canvas;

  canvas.SaveLayer({
      .color_filter =
          ColorFilter::MakeBlend(BlendMode::kColorDodge, Color::Red()),
  });

  canvas.Translate({500, 300, 0});
  canvas.Rotate(Radians(2 * kPi / 3));
  canvas.DrawRect(Rect::MakeXYWH(100, 100, 200, 200), {.color = Color::Blue()});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, ClearBlend) {
  Canvas canvas;
  Paint white;
  white.color = Color::Blue();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600.0, 600.0), white);

  Paint clear;
  clear.blend_mode = BlendMode::kClear;

  canvas.DrawCircle(Point::MakeXY(300.0, 300.0), 200.0, clear);
}

static Picture BlendModeTest(Vector2 content_scale,
                             BlendMode blend_mode,
                             const std::shared_ptr<Image>& src_image,
                             const std::shared_ptr<Image>& dst_image,
                             Scalar src_alpha) {
  if (AiksTest::ImGuiBegin("Controls", nullptr,
                           ImGuiWindowFlags_AlwaysAutoResize)) {
    ImGui::SliderFloat("Source alpha", &src_alpha, 0, 1);
    ImGui::End();
  }

  Color destination_color = Color::CornflowerBlue().WithAlpha(0.75);
  auto source_colors = std::vector<Color>({Color::White().WithAlpha(0.75),
                                           Color::LimeGreen().WithAlpha(0.75),
                                           Color::Black().WithAlpha(0.75)});

  Canvas canvas;
  canvas.DrawPaint({.color = Color::Black()});
  // TODO(bdero): Why does this cause the left image to double scale on high DPI
  //              displays.
  // canvas.Scale(content_scale);

  //----------------------------------------------------------------------------
  /// 1. Save layer blending (top squares).
  ///

  canvas.Save();
  for (const auto& color : source_colors) {
    canvas.Save();
    {
      canvas.ClipRect(Rect::MakeXYWH(25, 25, 100, 100));
      // Perform the blend in a SaveLayer so that the initial backdrop color is
      // fully transparent black. SourceOver blend the result onto the parent
      // pass.
      canvas.SaveLayer({});
      {
        canvas.DrawPaint({.color = destination_color});
        // Draw the source color in an offscreen pass and blend it to the parent
        // pass.
        canvas.SaveLayer({.blend_mode = blend_mode});
        {  //
          canvas.DrawRect(Rect::MakeXYWH(25, 25, 100, 100), {.color = color});
        }
        canvas.Restore();
      }
      canvas.Restore();
    }
    canvas.Restore();
    canvas.Translate(Vector2(100, 0));
  }
  canvas.RestoreToCount(0);

  //----------------------------------------------------------------------------
  /// 2. CPU blend modes (bottom squares).
  ///

  canvas.Save();
  canvas.Translate({0, 100});
  // Perform the blend in a SaveLayer so that the initial backdrop color is
  // fully transparent black. SourceOver blend the result onto the parent pass.
  canvas.SaveLayer({});
  for (const auto& color : source_colors) {
    // Simply write the CPU blended color to the pass.
    canvas.DrawRect(Rect::MakeXYWH(25, 25, 100, 100),
                    {.color = destination_color.Blend(color, blend_mode),
                     .blend_mode = BlendMode::kSourceOver});
    canvas.Translate(Vector2(100, 0));
  }
  canvas.Restore();
  canvas.Restore();

  //----------------------------------------------------------------------------
  /// 3. Image blending (bottom images).
  ///
  /// Compare these results with the images in the Flutter blend mode
  /// documentation: https://api.flutter.dev/flutter/dart-ui/BlendMode.html
  ///

  canvas.Translate({0, 250});

  // Draw grid behind the images.
  canvas.DrawRect(Rect::MakeLTRB(0, 0, 800, 400),
                  {.color = Color::MakeRGBA8(41, 41, 41, 255)});
  Paint square_paint = {.color = Color::MakeRGBA8(15, 15, 15, 255)};
  for (int y = 0; y < 400 / 8; y++) {
    for (int x = 0; x < 800 / 16; x++) {
      canvas.DrawRect(Rect::MakeXYWH(x * 16 + (y % 2) * 8, y * 8, 8, 8),
                      square_paint);
    }
  }

  // Uploaded image source (left image).
  canvas.Save();
  canvas.SaveLayer({.blend_mode = BlendMode::kSourceOver});
  {
    canvas.DrawImage(dst_image, {0, 0},
                     {
                         .blend_mode = BlendMode::kSourceOver,
                     });
    canvas.DrawImage(src_image, {0, 0},
                     {
                         .color = Color::White().WithAlpha(src_alpha),
                         .blend_mode = blend_mode,
                     });
  }
  canvas.Restore();
  canvas.Restore();

  // Rendered image source (right image).
  canvas.Save();
  canvas.SaveLayer({.blend_mode = BlendMode::kSourceOver});
  {
    canvas.DrawImage(dst_image, {400, 0},
                     {.blend_mode = BlendMode::kSourceOver});
    canvas.SaveLayer({.color = Color::White().WithAlpha(src_alpha),
                      .blend_mode = blend_mode});
    {
      canvas.DrawImage(src_image, {400, 0},
                       {.blend_mode = BlendMode::kSourceOver});
    }
    canvas.Restore();
  }
  canvas.Restore();
  canvas.Restore();

  return canvas.EndRecordingAsPicture();
}

#define BLEND_MODE_TEST(blend_mode)                                        \
  TEST_P(AiksTest, BlendMode##blend_mode) {                                \
    auto src_image = std::make_shared<Image>(                              \
        CreateTextureForFixture("blend_mode_src.png"));                    \
    auto dst_image = std::make_shared<Image>(                              \
        CreateTextureForFixture("blend_mode_dst.png"));                    \
    auto callback = [&](AiksContext& renderer) -> std::optional<Picture> { \
      return BlendModeTest(GetContentScale(), BlendMode::k##blend_mode,    \
                           src_image, dst_image, /*src_alpha=*/1.0);       \
    };                                                                     \
    OpenPlaygroundHere(callback);                                          \
  }
IMPELLER_FOR_EACH_BLEND_MODE(BLEND_MODE_TEST)

#define BLEND_MODE_SRC_ALPHA_TEST(blend_mode)                              \
  TEST_P(AiksTest, BlendModeSrcAlpha##blend_mode) {                        \
    auto src_image = std::make_shared<Image>(                              \
        CreateTextureForFixture("blend_mode_src.png"));                    \
    auto dst_image = std::make_shared<Image>(                              \
        CreateTextureForFixture("blend_mode_dst.png"));                    \
    auto callback = [&](AiksContext& renderer) -> std::optional<Picture> { \
      return BlendModeTest(GetContentScale(), BlendMode::k##blend_mode,    \
                           src_image, dst_image, /*src_alpha=*/0.5);       \
    };                                                                     \
    OpenPlaygroundHere(callback);                                          \
  }
IMPELLER_FOR_EACH_BLEND_MODE(BLEND_MODE_SRC_ALPHA_TEST)

TEST_P(AiksTest, CanDrawPaintMultipleTimesInteractive) {
  auto modes = GetBlendModeSelection();

  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    static Color background = Color::MediumTurquoise();
    static Color foreground = Color::Color::OrangeRed().WithAlpha(0.5);
    static int current_blend_index = 3;

    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::ColorEdit4("Background", reinterpret_cast<float*>(&background));
      ImGui::ColorEdit4("Foreground", reinterpret_cast<float*>(&foreground));
      ImGui::ListBox("Blend mode", &current_blend_index,
                     modes.blend_mode_names.data(),
                     modes.blend_mode_names.size());
      ImGui::End();
    }

    Canvas canvas;
    canvas.Scale(Vector2(0.2, 0.2));
    canvas.DrawPaint({.color = background});
    canvas.DrawPaint(
        {.color = foreground,
         .blend_mode = static_cast<BlendMode>(current_blend_index)});
    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ForegroundPipelineBlendAppliesTransformCorrectly) {
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);

  Canvas canvas;
  canvas.Rotate(Degrees(30));
  canvas.DrawImage(std::make_shared<Image>(texture), {200, 200},
                   {.color_filter = ColorFilter::MakeBlend(BlendMode::kSourceIn,
                                                           Color::Orange())});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, ForegroundAdvancedBlendAppliesTransformCorrectly) {
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);

  Canvas canvas;
  canvas.Rotate(Degrees(30));
  canvas.DrawImage(std::make_shared<Image>(texture), {200, 200},
                   {.color_filter = ColorFilter::MakeBlend(
                        BlendMode::kColorDodge, Color::Orange())});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, FramebufferAdvancedBlendCoverage) {
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);

  // Draw with an advanced blend that can use FramebufferBlendContents and
  // verify that the scale transform is correctly applied to the image.
  Canvas canvas;
  canvas.DrawPaint({.color = Color::DarkGray()});
  canvas.Scale(Vector2(0.4, 0.4));
  canvas.DrawImage(std::make_shared<Image>(texture), {20, 20},
                   {.blend_mode = BlendMode::kMultiply});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

}  // namespace testing
}  // namespace impeller

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

  std::shared_ptr<Texture> color_wheel_image;
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
      auto image = color_wheel_picture.ToImage(
          renderer, ISize{GetWindowSize().width, GetWindowSize().height});
      if (!image) {
        return std::nullopt;
      }
      color_wheel_image = image;
      color_wheel_transform = Matrix();
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

}  // namespace testing
}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <cmath>
#include <iostream>
#include <memory>
#include <tuple>
#include <utility>

#include "flutter/testing/testing.h"
#include "impeller/aiks/aiks_playground.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/image.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/scene_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/geometry_unittests.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/playground/widgets.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/snapshot.h"
#include "impeller/scene/material.h"
#include "impeller/scene/node.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/text_render_context_skia.h"
#include "third_party/skia/include/core/SkData.h"

namespace impeller {
namespace testing {

using AiksTest = AiksPlayground;
INSTANTIATE_PLAYGROUND_SUITE(AiksTest);

TEST_P(AiksTest, CanvasCTMCanBeUpdated) {
  Canvas canvas;
  Matrix identity;
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransformation(), identity);
  canvas.Translate(Size{100, 100});
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransformation(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, CanvasCanPushPopCTM) {
  Canvas canvas;
  ASSERT_EQ(canvas.GetSaveCount(), 1u);
  ASSERT_EQ(canvas.Restore(), false);

  canvas.Translate(Size{100, 100});
  canvas.Save();
  ASSERT_EQ(canvas.GetSaveCount(), 2u);
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransformation(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
  ASSERT_TRUE(canvas.Restore());
  ASSERT_EQ(canvas.GetSaveCount(), 1u);
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransformation(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, CanRenderColoredRect) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Blue();
  canvas.DrawPath(PathBuilder{}
                      .AddRect(Rect::MakeXYWH(100.0, 100.0, 100.0, 100.0))
                      .TakePath(),
                  paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderImage) {
  Canvas canvas;
  Paint paint;
  auto image = std::make_shared<Image>(CreateTextureForFixture("kalimba.jpg"));
  paint.color = Color::Red();
  canvas.DrawImage(image, Point::MakeXY(100.0, 100.0), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

bool GenerateMipmap(const std::shared_ptr<Context>& context,
                    std::shared_ptr<Texture> texture,
                    std::string label) {
  auto buffer = context->CreateCommandBuffer();
  if (!buffer) {
    return false;
  }
  auto pass = buffer->CreateBlitPass();
  if (!pass) {
    return false;
  }
  pass->GenerateMipmap(std::move(texture), std::move(label));
  pass->EncodeCommands(context->GetResourceAllocator());
  return true;
}

TEST_P(AiksTest, CanRenderTiledTexture) {
  auto context = GetContext();
  ASSERT_TRUE(context);
  bool first_frame = true;
  auto texture = CreateTextureForFixture("table_mountain_nx.png",
                                         /*enable_mipmapping=*/true);
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    if (first_frame) {
      first_frame = false;
      GenerateMipmap(context, texture, "table_mountain_nx");
    }

    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};
    const char* mip_filter_names[] = {"None", "Nearest", "Linear"};
    const MipFilter mip_filters[] = {MipFilter::kNone, MipFilter::kNearest,
                                     MipFilter::kLinear};
    const char* min_mag_filter_names[] = {"Nearest", "Linear"};
    const MinMagFilter min_mag_filters[] = {MinMagFilter::kNearest,
                                            MinMagFilter::kLinear};
    static int selected_x_tile_mode = 0;
    static int selected_y_tile_mode = 0;
    static int selected_mip_filter = 0;
    static int selected_min_mag_filter = 0;
    static float alpha = 1.0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Alpha", &alpha, 0.0, 1.0);
    ImGui::Combo("X tile mode", &selected_x_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    ImGui::Combo("Y tile mode", &selected_y_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    ImGui::Combo("Mip filter", &selected_mip_filter, mip_filter_names,
                 sizeof(mip_filter_names) / sizeof(char*));
    ImGui::Combo("Min Mag filter", &selected_min_mag_filter,
                 min_mag_filter_names,
                 sizeof(min_mag_filter_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto x_tile_mode = tile_modes[selected_x_tile_mode];
    auto y_tile_mode = tile_modes[selected_y_tile_mode];
    SamplerDescriptor descriptor;
    descriptor.mip_filter = mip_filters[selected_mip_filter];
    descriptor.min_filter = min_mag_filters[selected_min_mag_filter];
    descriptor.mag_filter = min_mag_filters[selected_min_mag_filter];
    paint.color_source = [texture, x_tile_mode, y_tile_mode, descriptor]() {
      auto contents = std::make_shared<TiledTextureContents>();
      contents->SetTexture(texture);
      contents->SetTileModes(x_tile_mode, y_tile_mode);
      contents->SetSamplerDescriptor(descriptor);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    paint.color = Color(1, 1, 1, alpha);
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderImageRect) {
  Canvas canvas;
  Paint paint;
  auto image = std::make_shared<Image>(CreateTextureForFixture("kalimba.jpg"));
  auto source_rect = Rect::MakeSize(Size(image->GetSize()));

  // Render the bottom right quarter of the source image in a stretched rect.
  source_rect.size.width /= 2;
  source_rect.size.height /= 2;
  source_rect.origin.x += source_rect.size.width;
  source_rect.origin.y += source_rect.size.height;
  canvas.DrawImageRect(image, source_rect, Rect::MakeXYWH(100, 100, 600, 600),
                       paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderStrokes) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Red();
  paint.stroke_width = 20.0;
  paint.style = Paint::Style::kStroke;
  canvas.DrawPath(PathBuilder{}.AddLine({200, 100}, {800, 100}).TakePath(),
                  paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderCurvedStrokes) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Red();
  paint.stroke_width = 25.0;
  paint.style = Paint::Style::kStroke;
  canvas.DrawPath(PathBuilder{}.AddCircle({500, 500}, 250).TakePath(), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderClips) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Fuchsia();
  canvas.ClipPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(0, 0, 500, 500)).TakePath());
  canvas.DrawPath(PathBuilder{}.AddCircle({500, 500}, 250).TakePath(), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderNestedClips) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Fuchsia();
  canvas.Save();
  canvas.ClipPath(PathBuilder{}.AddCircle({200, 400}, 300).TakePath());
  canvas.Restore();
  canvas.ClipPath(PathBuilder{}.AddCircle({600, 400}, 300).TakePath());
  canvas.ClipPath(PathBuilder{}.AddCircle({400, 600}, 300).TakePath());
  canvas.DrawRect(Rect::MakeXYWH(200, 200, 400, 400), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderDifferenceClips) {
  Paint paint;
  Canvas canvas;
  canvas.Translate({400, 400});

  // Limit drawing to face circle with a clip.
  canvas.ClipPath(PathBuilder{}.AddCircle(Point(), 200).TakePath());
  canvas.Save();

  // Cut away eyes/mouth using difference clips.
  canvas.ClipPath(PathBuilder{}.AddCircle({-100, -50}, 30).TakePath(),
                  Entity::ClipOperation::kDifference);
  canvas.ClipPath(PathBuilder{}.AddCircle({100, -50}, 30).TakePath(),
                  Entity::ClipOperation::kDifference);
  canvas.ClipPath(PathBuilder{}
                      .AddQuadraticCurve({-100, 50}, {0, 150}, {100, 50})
                      .TakePath(),
                  Entity::ClipOperation::kDifference);

  // Draw a huge yellow rectangle to prove the clipping works.
  paint.color = Color::Yellow();
  canvas.DrawRect(Rect::MakeXYWH(-1000, -1000, 2000, 2000), paint);

  // Remove the difference clips and draw hair that partially covers the eyes.
  canvas.Restore();
  paint.color = Color::Maroon();
  canvas.DrawPath(PathBuilder{}
                      .MoveTo({200, -200})
                      .HorizontalLineTo(-200)
                      .VerticalLineTo(-40)
                      .CubicCurveTo({0, -40}, {0, -80}, {200, -80})
                      .TakePath(),
                  paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderWithContiguousClipRestores) {
  Canvas canvas;

  // Cover the whole canvas with red.
  canvas.DrawPaint({.color = Color::Red()});

  canvas.Save();

  // Append two clips, the second resulting in empty coverage.
  canvas.ClipPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(100, 100, 100, 100)).TakePath());
  canvas.ClipPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(300, 300, 100, 100)).TakePath());

  // Restore to no clips.
  canvas.Restore();

  // Replace the whole canvas with green.
  canvas.DrawPaint({.color = Color::Green()});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, ClipsUseCurrentTransform) {
  std::array<Color, 5> colors = {Color::White(), Color::Black(),
                                 Color::SkyBlue(), Color::Red(),
                                 Color::Yellow()};
  Canvas canvas;
  Paint paint;

  canvas.Translate(Vector3(300, 300));
  for (int i = 0; i < 15; i++) {
    canvas.Scale(Vector3(0.8, 0.8));

    paint.color = colors[i % colors.size()];
    canvas.ClipPath(PathBuilder{}.AddCircle({0, 0}, 300).TakePath());
    canvas.DrawRect(Rect(-300, -300, 600, 600), paint);
  }
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanSaveLayerStandalone) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();

  Paint alpha;
  alpha.color = Color::Red().WithAlpha(0.5);

  canvas.SaveLayer(alpha);

  canvas.DrawCircle({125, 125}, 125, red);

  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderLinearGradient) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    static float alpha = 1;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Alpha", &alpha, 0, 1);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
      std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                   Color{0.1294, 0.5882, 0.9529, 0.0}};
      std::vector<Scalar> stops = {0.0, 1.0};

      auto contents = std::make_shared<LinearGradientContents>();
      contents->SetEndPoints({0, 0}, {200, 200});
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    paint.color = Color(1.0, 1.0, 1.0, alpha);
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderLinearGradientWithOverlappingStops) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    static float alpha = 1;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Alpha", &alpha, 0, 1);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
      std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                   Color{0.9568, 0.2627, 0.2118, 1.0},
                                   Color{0.1294, 0.5882, 0.9529, 1.0},
                                   Color{0.1294, 0.5882, 0.9529, 1.0}};
      std::vector<Scalar> stops = {0.0, 0.5, 0.5, 1.0};

      auto contents = std::make_shared<LinearGradientContents>();
      contents->SetEndPoints({0, 0}, {500, 500});
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    paint.color = Color(1.0, 1.0, 1.0, alpha);
    canvas.DrawRect({0, 0, 500, 500}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderLinearGradientManyColors) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    static float alpha = 1;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Alpha", &alpha, 0, 1);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
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

      auto contents = std::make_shared<LinearGradientContents>();
      contents->SetEndPoints({0, 0}, {200, 200});
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    paint.color = Color(1.0, 1.0, 1.0, alpha);
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderLinearGradientWayManyColors) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
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
    paint.color_source = [tile_mode, stops = std::move(stops),
                          colors = std::move(colors)]() {
      auto contents = std::make_shared<LinearGradientContents>();
      contents->SetEndPoints({0, 0}, {200, 200});
      contents->SetColors(colors);
      contents->SetStops(stops);
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderLinearGradientManyColorsUnevenStops) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
      std::vector<Color> colors = {
          Color{0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0},
          Color{0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0},
          Color{0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0},
          Color{0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0},
          Color{0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0},
          Color{0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0},
          Color{0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0}};
      std::vector<Scalar> stops = {
          0.0,         2.0 / 62.0,  4.0 / 62.0, 8.0 / 62.0,
          16.0 / 62.0, 32.0 / 62.0, 1.0,
      };

      auto contents = std::make_shared<LinearGradientContents>();
      contents->SetEndPoints({0, 0}, {200, 200});
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderRadialGradient) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
      std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                   Color{0.1294, 0.5882, 0.9529, 1.0}};
      std::vector<Scalar> stops = {0.0, 1.0};

      auto contents = std::make_shared<RadialGradientContents>();
      contents->SetCenterAndRadius({100, 100}, 100);
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderRadialGradientManyColors) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
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

      auto contents = std::make_shared<RadialGradientContents>();
      contents->SetCenterAndRadius({100, 100}, 100);
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderSweepGradient) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
      auto contents = std::make_shared<SweepGradientContents>();
      contents->SetCenterAndAngles({100, 100}, Degrees(45), Degrees(135));
      std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                   Color{0.1294, 0.5882, 0.9529, 1.0}};
      std::vector<Scalar> stops = {0.0, 1.0};
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderSweepGradientManyColors) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static int selected_tile_mode = 0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    static Matrix matrix = {
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 0, 1   //
    };
    std::string label = "##1";
    for (int i = 0; i < 4; i++) {
      ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float, &(matrix.vec[i]),
                          4, NULL, NULL, "%.2f", 0);
      label[2]++;
    }
    ImGui::End();

    Canvas canvas;
    Paint paint;
    canvas.Translate({100.0, 100.0, 0});
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
      auto contents = std::make_shared<SweepGradientContents>();
      contents->SetCenterAndAngles({100, 100}, Degrees(45), Degrees(135));
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

      contents->SetStops(std::move(stops));
      contents->SetColors(std::move(colors));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };
    canvas.DrawRect({0, 0, 600, 600}, paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderDifferentShapesWithSameColorSource) {
  Canvas canvas;
  Paint paint;
  paint.color_source = []() {
    auto contents = std::make_shared<LinearGradientContents>();
    contents->SetEndPoints({0, 0}, {100, 100});
    std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                 Color{0.1294, 0.5882, 0.9529, 1.0}};
    std::vector<Scalar> stops = {
        0.0,
        1.0,
    };
    contents->SetColors(std::move(colors));
    contents->SetStops(std::move(stops));
    contents->SetTileMode(Entity::TileMode::kRepeat);
    return contents;
  };
  canvas.Save();
  canvas.Translate({100, 100, 0});
  canvas.DrawRect({0, 0, 200, 200}, paint);
  canvas.Restore();

  canvas.Save();
  canvas.Translate({100, 400, 0});
  canvas.DrawCircle({100, 100}, 100, paint);
  canvas.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanPictureConvertToImage) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    static int size[2] = {1000, 1000};
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderInt2("Size", size, 0, 1000);
    ImGui::End();

    Canvas recorder_canvas;
    Paint paint;
    paint.color = Color{0.9568, 0.2627, 0.2118, 1.0};
    recorder_canvas.DrawRect({100.0, 100.0, 600, 600}, paint);
    paint.color = Color{0.1294, 0.5882, 0.9529, 1.0};
    recorder_canvas.DrawRect({200.0, 200.0, 600, 600}, paint);

    Canvas canvas;
    paint.color = Color::BlackTransparent();
    canvas.DrawPaint(paint);
    Picture picture = recorder_canvas.EndRecordingAsPicture();
    auto image = picture.ToImage(renderer, ISize{size[0], size[1]});
    if (image) {
      canvas.DrawImage(image, Point(), Paint());
      paint.color = Color{0.1, 0.1, 0.1, 0.2};
      canvas.DrawRect(Rect::MakeSize(ISize{size[0], size[1]}), paint);
    }

    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, BlendModeShouldCoverWholeScreen) {
  Canvas canvas;
  Paint paint;

  paint.color = Color::Red();
  canvas.DrawPaint(paint);

  paint.blend_mode = BlendMode::kSourceOver;
  canvas.SaveLayer(paint);

  paint.color = Color::White();
  canvas.DrawRect({100, 100, 400, 400}, paint);

  paint.blend_mode = BlendMode::kSource;
  canvas.SaveLayer(paint);

  paint.color = Color::Blue();
  canvas.DrawRect({200, 200, 200, 200}, paint);

  canvas.Restore();
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderGroupOpacity) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();
  Paint green;
  green.color = Color::Green().WithAlpha(0.5);
  Paint blue;
  blue.color = Color::Blue();

  Paint alpha;
  alpha.color = Color::Red().WithAlpha(0.5);

  canvas.SaveLayer(alpha);

  canvas.DrawRect({000, 000, 100, 100}, red);
  canvas.DrawRect({020, 020, 100, 100}, green);
  canvas.DrawRect({040, 040, 100, 100}, blue);

  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CoordinateConversionsAreCorrect) {
  Canvas canvas;

  // Render a texture directly.
  {
    Paint paint;
    auto image =
        std::make_shared<Image>(CreateTextureForFixture("kalimba.jpg"));
    paint.color = Color::Red();

    canvas.Save();
    canvas.Translate({100, 200, 0});
    canvas.Scale(Vector2{0.5, 0.5});
    canvas.DrawImage(image, Point::MakeXY(100.0, 100.0), paint);
    canvas.Restore();
  }

  // Render an offscreen rendered texture.
  {
    Paint red;
    red.color = Color::Red();
    Paint green;
    green.color = Color::Green();
    Paint blue;
    blue.color = Color::Blue();

    Paint alpha;
    alpha.color = Color::Red().WithAlpha(0.5);

    canvas.SaveLayer(alpha);

    canvas.DrawRect({000, 000, 100, 100}, red);
    canvas.DrawRect({020, 020, 100, 100}, green);
    canvas.DrawRect({040, 040, 100, 100}, blue);

    canvas.Restore();
  }

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanPerformFullScreenMSAA) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();

  canvas.DrawCircle({250, 250}, 125, red);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanPerformSkew) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();

  canvas.Skew(2, 5);
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 100, 100), red);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanPerformSaveLayerWithBounds) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();

  Paint green;
  green.color = Color::Green();

  Paint blue;
  blue.color = Color::Blue();

  Paint save;
  save.color = Color::Black();

  canvas.SaveLayer(save, Rect{0, 0, 50, 50});

  canvas.DrawRect({0, 0, 100, 100}, red);
  canvas.DrawRect({10, 10, 100, 100}, green);
  canvas.DrawRect({20, 20, 100, 100}, blue);

  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest,
       CanPerformSaveLayerWithBoundsAndLargerIntermediateIsNotAllocated) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();

  Paint green;
  green.color = Color::Green();

  Paint blue;
  blue.color = Color::Blue();

  Paint save;
  save.color = Color::Black().WithAlpha(0.5);

  canvas.SaveLayer(save, Rect{0, 0, 100000, 100000});

  canvas.DrawRect({0, 0, 100, 100}, red);
  canvas.DrawRect({10, 10, 100, 100}, green);
  canvas.DrawRect({20, 20, 100, 100}, blue);

  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderRoundedRectWithNonUniformRadii) {
  Canvas canvas;

  Paint paint;
  paint.color = Color::Red();

  PathBuilder::RoundingRadii radii;
  radii.top_left = {50, 25};
  radii.top_right = {25, 50};
  radii.bottom_right = {50, 25};
  radii.bottom_left = {25, 50};

  auto path =
      PathBuilder{}.AddRoundedRect(Rect{100, 100, 500, 500}, radii).TakePath();

  canvas.DrawPath(path, paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderDifferencePaths) {
  Canvas canvas;

  Paint paint;
  paint.color = Color::Red();

  PathBuilder builder;

  PathBuilder::RoundingRadii radii;
  radii.top_left = {50, 25};
  radii.top_right = {25, 50};
  radii.bottom_right = {50, 25};
  radii.bottom_left = {25, 50};

  builder.AddRoundedRect({100, 100, 200, 200}, radii);
  builder.AddCircle({200, 200}, 50);
  auto path = builder.TakePath(FillType::kOdd);

  canvas.DrawImage(
      std::make_shared<Image>(CreateTextureForFixture("boston.jpg")), {10, 10},
      Paint{});
  canvas.DrawPath(path, paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

static sk_sp<SkData> OpenFixtureAsSkData(const char* fixture_name) {
  auto mapping = flutter::testing::OpenFixtureAsMapping(fixture_name);
  if (!mapping) {
    return nullptr;
  }
  auto data = SkData::MakeWithProc(
      mapping->GetMapping(), mapping->GetSize(),
      [](const void* ptr, void* context) {
        delete reinterpret_cast<fml::Mapping*>(context);
      },
      mapping.get());
  mapping.release();
  return data;
}

bool RenderTextInCanvas(const std::shared_ptr<Context>& context,
                        Canvas& canvas,
                        const std::string& text,
                        const std::string& font_fixture,
                        Scalar font_size = 50.0,
                        Scalar alpha = 1.0) {
  Scalar baseline = 200.0;
  Point text_position = {100, baseline};

  // Draw the baseline.
  canvas.DrawRect({50, baseline, 900, 10},
                  Paint{.color = Color::Aqua().WithAlpha(0.25)});

  // Mark the point at which the text is drawn.
  canvas.DrawCircle(text_position, 5.0,
                    Paint{.color = Color::Red().WithAlpha(0.25)});

  // Construct the text blob.
  auto mapping = OpenFixtureAsSkData(font_fixture.c_str());
  if (!mapping) {
    return false;
  }
  SkFont sk_font(SkTypeface::MakeFromData(mapping), 50.0);
  auto blob = SkTextBlob::MakeFromString(text.c_str(), sk_font);
  if (!blob) {
    return false;
  }

  // Create the Impeller text frame and draw it at the designated baseline.
  auto frame = TextFrameFromTextBlob(blob);

  Paint text_paint;
  text_paint.color = Color::Yellow().WithAlpha(alpha);
  canvas.DrawTextFrame(frame, text_position, text_paint);
  return true;
}

TEST_P(AiksTest, CanRenderTextFrame) {
  Canvas canvas;
  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas, "the quick brown fox jumped over the lazy dog!.?",
      "Roboto-Regular.ttf"));
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderItalicizedText) {
  Canvas canvas;
  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas, "the quick brown fox jumped over the lazy dog!.?",
      "HomemadeApple.ttf"));
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderEmojiTextFrame) {
  Canvas canvas;
  ASSERT_TRUE(RenderTextInCanvas(GetContext(), canvas,
                                 "😀 😃 😄 😁 😆 😅 😂 🤣 🥲 😊",
#if FML_OS_MACOSX
                                 "Apple Color Emoji.ttc"));
#else
                                 "NotoColorEmoji.ttf"));
#endif
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderEmojiTextFrameWithAlpha) {
  Canvas canvas;
  ASSERT_TRUE(RenderTextInCanvas(GetContext(), canvas,
                                 "😀 😃 😄 😁 😆 😅 😂 🤣 🥲 😊",
#if FML_OS_MACOSX
                                 "Apple Color Emoji.ttc", 50, 0.5));
#else
                                 "NotoColorEmoji.ttf", 50, 0.5));
#endif
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderTextInSaveLayer) {
  Canvas canvas;
  canvas.DrawPaint({.color = Color::White()});
  canvas.Translate({100, 100});
  canvas.Scale(Vector2{0.5, 0.5});

  // Blend the layer with the parent pass using kClear to expose the coverage.
  canvas.SaveLayer({.blend_mode = BlendMode::kClear});
  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas, "the quick brown fox jumped over the lazy dog!.?",
      "Roboto-Regular.ttf"));
  canvas.Restore();

  // Render the text again over the cleared coverage rect.
  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas, "the quick brown fox jumped over the lazy dog!.?",
      "Roboto-Regular.ttf"));

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderTextOutsideBoundaries) {
  Canvas canvas;
  canvas.Translate({200, 150});

  // Construct the text blob.
  auto mapping = OpenFixtureAsSkData("wtf.otf");
  ASSERT_NE(mapping, nullptr);

  Scalar font_size = 80;
  SkFont sk_font(SkTypeface::MakeFromData(mapping), font_size);

  Paint text_paint;
  text_paint.color = Color::White().WithAlpha(0.8);

  struct {
    Point position;
    const char* text;
  } text[] = {{Point(0, 0), "0F0F0F0"},
              {Point(1, 2), "789"},
              {Point(1, 3), "456"},
              {Point(1, 4), "123"},
              {Point(0, 6), "0F0F0F0"}};
  for (auto& t : text) {
    canvas.Save();
    canvas.Translate(t.position * Point(font_size * 2, font_size * 1.1));
    {
      auto blob = SkTextBlob::MakeFromString(t.text, sk_font);
      ASSERT_NE(blob, nullptr);
      auto frame = TextFrameFromTextBlob(blob);
      canvas.DrawTextFrame(frame, Point(), text_paint);
    }
    canvas.Restore();
  }

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, TextRotated) {
  Canvas canvas;
  canvas.Transform(Matrix(0.5, -0.3, 0, -0.002,  //
                          0, 1, 0, 0,            //
                          0, 0, 0.3, 0,          //
                          100, 100, 0, 1.3));

  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas, "the quick brown fox jumped over the lazy dog!.?",
      "Roboto-Regular.ttf"));

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanDrawPaint) {
  Paint paint;
  paint.color = Color::MediumTurquoise();
  Canvas canvas;
  canvas.Scale(Vector2(0.2, 0.2));
  canvas.DrawPaint(paint);
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

TEST_P(AiksTest, ColorWheel) {
  // Compare with https://fiddle.skia.org/c/@BlendModes

  std::vector<const char*> blend_mode_names;
  std::vector<BlendMode> blend_mode_values;
  {
    const std::vector<std::tuple<const char*, BlendMode>> blends = {
        // Pipeline blends (Porter-Duff alpha compositing)
        {"Clear", BlendMode::kClear},
        {"Source", BlendMode::kSource},
        {"Destination", BlendMode::kDestination},
        {"SourceOver", BlendMode::kSourceOver},
        {"DestinationOver", BlendMode::kDestinationOver},
        {"SourceIn", BlendMode::kSourceIn},
        {"DestinationIn", BlendMode::kDestinationIn},
        {"SourceOut", BlendMode::kSourceOut},
        {"DestinationOut", BlendMode::kDestinationOut},
        {"SourceATop", BlendMode::kSourceATop},
        {"DestinationATop", BlendMode::kDestinationATop},
        {"Xor", BlendMode::kXor},
        {"Plus", BlendMode::kPlus},
        {"Modulate", BlendMode::kModulate},
        // Advanced blends (color component blends)
        {"Screen", BlendMode::kScreen},
        {"Overlay", BlendMode::kOverlay},
        {"Darken", BlendMode::kDarken},
        {"Lighten", BlendMode::kLighten},
        {"ColorDodge", BlendMode::kColorDodge},
        {"ColorBurn", BlendMode::kColorBurn},
        {"HardLight", BlendMode::kHardLight},
        {"SoftLight", BlendMode::kSoftLight},
        {"Difference", BlendMode::kDifference},
        {"Exclusion", BlendMode::kExclusion},
        {"Multiply", BlendMode::kMultiply},
        {"Hue", BlendMode::kHue},
        {"Saturation", BlendMode::kSaturation},
        {"Color", BlendMode::kColor},
        {"Luminosity", BlendMode::kLuminosity},
    };
    assert(blends.size() ==
           static_cast<size_t>(Entity::kLastAdvancedBlendMode) + 1);
    for (const auto& [name, mode] : blends) {
      blend_mode_names.push_back(name);
      blend_mode_values.push_back(mode);
    }
  }

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

  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    // UI state.
    static int current_blend_index = 3;
    static float dst_alpha = 1;
    static float src_alpha = 1;
    static Color color0 = Color::Red();
    static Color color1 = Color::Green();
    static Color color2 = Color::Blue();

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      ImGui::ListBox("Blending mode", &current_blend_index,
                     blend_mode_names.data(), blend_mode_names.size());
      ImGui::SliderFloat("Source alpha", &src_alpha, 0, 1);
      ImGui::ColorEdit4("Color A", reinterpret_cast<float*>(&color0));
      ImGui::ColorEdit4("Color B", reinterpret_cast<float*>(&color1));
      ImGui::ColorEdit4("Color C", reinterpret_cast<float*>(&color2));
      ImGui::SliderFloat("Destination alpha", &dst_alpha, 0, 1);
    }
    ImGui::End();

    static Point content_scale;
    Point new_content_scale = GetContentScale();

    if (new_content_scale != content_scale) {
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
        return false;
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
    canvas.SaveLayer({.color = Color::White().WithAlpha(src_alpha),
                      .blend_mode = blend_mode_values[current_blend_index]});
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

    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, TransformMultipliesCorrectly) {
  Canvas canvas;
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransformation(), Matrix());

  // clang-format off
  canvas.Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransformation(),
    Matrix(  1,   0,   0,   0,
             0,   1,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas.Rotate(Radians(kPiOver2));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransformation(),
    Matrix(  0,   1,   0,   0,
            -1,   0,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas.Scale(Vector3(2, 3));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransformation(),
    Matrix(  0,   2,   0,   0,
            -3,   0,   0,   0,
             0,   0,   0,   0,
           100, 200,   0,   1));

  canvas.Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransformation(),
    Matrix(   0,   2,   0,   0,
             -3,   0,   0,   0,
              0,   0,   0,   0,
           -500, 400,   0,   1));
  // clang-format on
}

TEST_P(AiksTest, SolidStrokesRenderCorrectly) {
  // Compare with https://fiddle.skia.org/c/027392122bec8ac2b5d5de00a4b9bbe2
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    static Color color = Color::Black().WithAlpha(0.5);
    static float scale = 3;
    static bool add_circle_clip = true;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::ColorEdit4("Color", reinterpret_cast<float*>(&color));
    ImGui::SliderFloat("Scale", &scale, 0, 6);
    ImGui::Checkbox("Circle clip", &add_circle_clip);
    ImGui::End();

    Canvas canvas;
    canvas.Scale(GetContentScale());
    Paint paint;

    paint.color = Color::White();
    canvas.DrawPaint(paint);

    paint.color = color;
    paint.style = Paint::Style::kStroke;
    paint.stroke_width = 10;

    Path path = PathBuilder{}
                    .MoveTo({20, 20})
                    .QuadraticCurveTo({60, 20}, {60, 60})
                    .Close()
                    .MoveTo({60, 20})
                    .QuadraticCurveTo({60, 60}, {20, 60})
                    .TakePath();

    canvas.Scale(Vector2(scale, scale));

    if (add_circle_clip) {
      auto [handle_a, handle_b] = IMPELLER_PLAYGROUND_LINE(
          Point(60, 300), Point(600, 300), 20, Color::Red(), Color::Red());

      auto screen_to_canvas = canvas.GetCurrentTransformation().Invert();
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

    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, GradientStrokesRenderCorrectly) {
  // Compare with https://fiddle.skia.org/c/027392122bec8ac2b5d5de00a4b9bbe2
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    static float scale = 3;
    static bool add_circle_clip = true;
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};
    static int selected_tile_mode = 0;
    static float alpha = 1;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Scale", &scale, 0, 6);
    ImGui::Checkbox("Circle clip", &add_circle_clip);
    ImGui::SliderFloat("Alpha", &alpha, 0, 1);
    ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                 sizeof(tile_mode_names) / sizeof(char*));
    ImGui::End();

    Canvas canvas;
    canvas.Scale(GetContentScale());
    Paint paint;
    paint.color = Color::White();
    canvas.DrawPaint(paint);

    paint.style = Paint::Style::kStroke;
    paint.color = Color(1.0, 1.0, 1.0, alpha);
    paint.stroke_width = 10;
    auto tile_mode = tile_modes[selected_tile_mode];
    paint.color_source = [tile_mode]() {
      std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                                   Color{0.1294, 0.5882, 0.9529, 1.0}};
      std::vector<Scalar> stops = {0.0, 1.0};
      Matrix matrix = {
          1, 0, 0, 0,  //
          0, 1, 0, 0,  //
          0, 0, 1, 0,  //
          0, 0, 0, 1   //
      };
      auto contents = std::make_shared<LinearGradientContents>();
      contents->SetEndPoints({0, 0}, {50, 50});
      contents->SetColors(std::move(colors));
      contents->SetStops(std::move(stops));
      contents->SetTileMode(tile_mode);
      contents->SetEffectTransform(matrix);
      return contents;
    };

    Path path = PathBuilder{}
                    .MoveTo({20, 20})
                    .QuadraticCurveTo({60, 20}, {60, 60})
                    .Close()
                    .MoveTo({60, 20})
                    .QuadraticCurveTo({60, 60}, {20, 60})
                    .TakePath();

    canvas.Scale(Vector2(scale, scale));

    if (add_circle_clip) {
      auto [handle_a, handle_b] = IMPELLER_PLAYGROUND_LINE(
          Point(60, 300), Point(600, 300), 20, Color::Red(), Color::Red());

      auto screen_to_canvas = canvas.GetCurrentTransformation().Invert();
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

    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CoverageOriginShouldBeAccountedForInSubpasses) {
  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    Canvas canvas;
    canvas.Scale(GetContentScale());

    Paint alpha;
    alpha.color = Color::Red().WithAlpha(0.5);

    auto current = Point{25, 25};
    const auto offset = Point{25, 25};
    const auto size = Size(100, 100);

    auto [b0, b1] = IMPELLER_PLAYGROUND_LINE(Point(40, 40), Point(160, 160), 10,
                                             Color::White(), Color::White());
    auto bounds = Rect::MakeLTRB(b0.x, b0.y, b1.x, b1.y);

    canvas.DrawRect(bounds, Paint{.color = Color::Yellow(),
                                  .stroke_width = 5.0f,
                                  .style = Paint::Style::kStroke});

    canvas.SaveLayer(alpha, bounds);

    canvas.DrawRect({current, size}, Paint{.color = Color::Red()});
    canvas.DrawRect({current += offset, size}, Paint{.color = Color::Green()});
    canvas.DrawRect({current += offset, size}, Paint{.color = Color::Blue()});

    canvas.Restore();

    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, DrawRectStrokesRenderCorrectly) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Red();
  paint.style = Paint::Style::kStroke;
  paint.stroke_width = 10;

  canvas.Translate({100, 100});
  canvas.DrawPath(
      PathBuilder{}.AddRect(Rect::MakeSize(Size{100, 100})).TakePath(),
      {paint});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, SaveLayerDrawsBehindSubsequentEntities) {
  // Compare with https://fiddle.skia.org/c/9e03de8567ffb49e7e83f53b64bcf636
  Canvas canvas;
  Paint paint;

  paint.color = Color::Black();
  Rect rect(25, 25, 25, 25);
  canvas.DrawRect(rect, paint);

  canvas.Translate({10, 10});
  canvas.SaveLayer({});

  paint.color = Color::Green();
  canvas.DrawRect(rect, paint);

  canvas.Restore();

  canvas.Translate({10, 10});
  paint.color = Color::Red();
  canvas.DrawRect(rect, paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, SiblingSaveLayerBoundsAreRespected) {
  Canvas canvas;
  Paint paint;
  Rect rect(0, 0, 1000, 1000);

  // Black, green, and red squares offset by [10, 10].
  {
    canvas.SaveLayer({}, Rect::MakeXYWH(25, 25, 25, 25));
    paint.color = Color::Black();
    canvas.DrawRect(rect, paint);
    canvas.Restore();
  }

  {
    canvas.SaveLayer({}, Rect::MakeXYWH(35, 35, 25, 25));
    paint.color = Color::Green();
    canvas.DrawRect(rect, paint);
    canvas.Restore();
  }

  {
    canvas.SaveLayer({}, Rect::MakeXYWH(45, 45, 25, 25));
    paint.color = Color::Red();
    canvas.DrawRect(rect, paint);
    canvas.Restore();
  }

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderClippedLayers) {
  Canvas canvas;

  canvas.DrawPaint({.color = Color::White()});

  // Draw a green circle on the screen.
  {
    // Increase the clip depth for the savelayer to contend with.
    canvas.ClipPath(PathBuilder{}.AddCircle({100, 100}, 50).TakePath());

    canvas.SaveLayer({}, Rect::MakeXYWH(50, 50, 100, 100));

    // Fill the layer with white.
    canvas.DrawRect(Rect::MakeSize(Size{400, 400}), {.color = Color::White()});
    // Fill the layer with green, but do so with a color blend that can't be
    // collapsed into the parent pass.
    canvas.DrawRect(
        Rect::MakeSize(Size{400, 400}),
        {.color = Color::Green(), .blend_mode = BlendMode::kColorBurn});
  }

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, SaveLayerFiltersScaleWithTransform) {
  Canvas canvas;
  canvas.Scale(GetContentScale());
  canvas.Translate(Vector2(100, 100));

  auto texture = std::make_shared<Image>(CreateTextureForFixture("boston.jpg"));
  auto draw_image_layer = [&canvas, &texture](const Paint& paint) {
    canvas.SaveLayer(paint);
    canvas.DrawImage(texture, {}, Paint{});
    canvas.Restore();
  };

  Paint effect_paint;
  effect_paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kNormal,
      .sigma = Sigma{6},
  };
  draw_image_layer(effect_paint);

  canvas.Translate(Vector2(300, 300));
  canvas.Scale(Vector2(3, 3));
  draw_image_layer(effect_paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, SceneColorSource) {
  // Load up the scene.
  auto mapping =
      flutter::testing::OpenFixtureAsMapping("flutter_logo_baked.glb.ipscene");
  ASSERT_NE(mapping, nullptr);

  std::shared_ptr<scene::Node> gltf_scene = scene::Node::MakeFromFlatbuffer(
      *mapping, *GetContext()->GetResourceAllocator());
  ASSERT_NE(gltf_scene, nullptr);

  auto callback = [&](AiksContext& renderer, RenderTarget& render_target) {
    Paint paint;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    static Scalar distance = 2;
    ImGui::SliderFloat("Distance", &distance, 0, 4);
    static Scalar y_pos = 0;
    ImGui::SliderFloat("Y", &y_pos, -3, 3);
    static Scalar fov = 45;
    ImGui::SliderFloat("FOV", &fov, 1, 180);
    ImGui::End();

    paint.color_source_type = Paint::ColorSourceType::kScene;
    paint.color_source = [&]() {
      Scalar angle = GetSecondsElapsed();
      auto camera_position = Vector3(distance * std::sin(angle), y_pos,
                                     -distance * std::cos(angle));
      auto contents = std::make_shared<SceneContents>();
      contents->SetNode(gltf_scene);
      contents->SetCameraTransform(
          Matrix::MakePerspective(Degrees(fov), GetWindowSize(), 0.1, 1000) *
          Matrix::MakeLookAt(camera_position, {0, 0, 0}, {0, 1, 0}));
      return contents;
    };

    Canvas canvas;
    canvas.DrawPaint(Paint{.color = Color::MakeRGBA8(0xf9, 0xf9, 0xf9, 0xff)});
    canvas.Scale(GetContentScale());
    canvas.DrawPaint(paint);
    return renderer.Render(canvas.EndRecordingAsPicture(), render_target);
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, PaintWithFilters) {
  // validate that a paint with a color filter "HasFilters", no other filters
  // impact this setting.
  Paint paint;

  ASSERT_FALSE(paint.HasColorFilter());

  paint.color_filter = [](FilterInput::Ref input) {
    return ColorFilterContents::MakeBlend(BlendMode::kSourceOver,
                                          {std::move(input)}, Color::Blue());
  };

  ASSERT_TRUE(paint.HasColorFilter());

  paint.image_filter = [](const FilterInput::Ref& input,
                          const Matrix& effect_transform) {
    return FilterContents::MakeGaussianBlur(
        input, Sigma(1.0), Sigma(1.0), FilterContents::BlurStyle::kNormal,
        Entity::TileMode::kClamp, effect_transform);
  };

  ASSERT_TRUE(paint.HasColorFilter());

  paint.mask_blur_descriptor = {};

  ASSERT_TRUE(paint.HasColorFilter());

  paint.color_filter = std::nullopt;

  ASSERT_FALSE(paint.HasColorFilter());
}

}  // namespace testing
}  // namespace impeller

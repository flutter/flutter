// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/aiks_unittests.h"

#include <array>
#include <cmath>
#include <cstdlib>
#include <memory>
#include <tuple>
#include <utility>
#include <vector>

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/color_filter.h"
#include "impeller/aiks/image.h"
#include "impeller/aiks/image_filter.h"
#include "impeller/aiks/testing/context_spy.h"
#include "impeller/core/device_buffer.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/size.h"
#include "impeller/playground/widgets.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/snapshot.h"
#include "third_party/imgui/imgui.h"

namespace impeller {
namespace testing {

INSTANTIATE_PLAYGROUND_SUITE(AiksTest);

TEST_P(AiksTest, CanvasCTMCanBeUpdated) {
  Canvas canvas;
  Matrix identity;
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransform(), identity);
  canvas.Translate(Size{100, 100});
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, CanvasCanPushPopCTM) {
  Canvas canvas;
  ASSERT_EQ(canvas.GetSaveCount(), 1u);
  ASSERT_EQ(canvas.Restore(), false);

  canvas.Translate(Size{100, 100});
  canvas.Save();
  ASSERT_EQ(canvas.GetSaveCount(), 2u);
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
  ASSERT_TRUE(canvas.Restore());
  ASSERT_EQ(canvas.GetSaveCount(), 1u);
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransform(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_P(AiksTest, CanPictureConvertToImage) {
  Canvas recorder_canvas;
  Paint paint;
  paint.color = Color{0.9568, 0.2627, 0.2118, 1.0};
  recorder_canvas.DrawRect(Rect::MakeXYWH(100.0, 100.0, 600, 600), paint);
  paint.color = Color{0.1294, 0.5882, 0.9529, 1.0};
  recorder_canvas.DrawRect(Rect::MakeXYWH(200.0, 200.0, 600, 600), paint);

  Canvas canvas;
  AiksContext renderer(GetContext(), nullptr);
  paint.color = Color::BlackTransparent();
  canvas.DrawPaint(paint);
  Picture picture = recorder_canvas.EndRecordingAsPicture();
  auto image = picture.ToImage(renderer, ISize{1000, 1000});
  if (image) {
    canvas.DrawImage(image, Point(), Paint());
    paint.color = Color{0.1, 0.1, 0.1, 0.2};
    canvas.DrawRect(Rect::MakeSize(ISize{1000, 1000}), paint);
  }

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

// Regression test for https://github.com/flutter/flutter/issues/142358 .
// Without a change to force render pass construction the image is left in an
// undefined layout and triggers a validation error.
TEST_P(AiksTest, CanEmptyPictureConvertToImage) {
  Canvas recorder_canvas;

  Canvas canvas;
  AiksContext renderer(GetContext(), nullptr);
  Paint paint;
  paint.color = Color::BlackTransparent();
  canvas.DrawPaint(paint);
  Picture picture = recorder_canvas.EndRecordingAsPicture();
  auto image = picture.ToImage(renderer, ISize{1000, 1000});
  if (image) {
    canvas.DrawImage(image, Point(), Paint());
    paint.color = Color{0.1, 0.1, 0.1, 0.2};
    canvas.DrawRect(Rect::MakeSize(ISize{1000, 1000}), paint);
  }

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, TransformMultipliesCorrectly) {
  Canvas canvas;
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransform(), Matrix());

  // clang-format off
  canvas.Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransform(),
    Matrix(  1,   0,   0,   0,
             0,   1,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas.Rotate(Radians(kPiOver2));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransform(),
    Matrix(  0,   1,   0,   0,
            -1,   0,   0,   0,
             0,   0,   1,   0,
           100, 200,   0,   1));

  canvas.Scale(Vector3(2, 3));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransform(),
    Matrix(  0,   2,   0,   0,
            -3,   0,   0,   0,
             0,   0,   0,   0,
           100, 200,   0,   1));

  canvas.Translate(Vector3(100, 200));
  ASSERT_MATRIX_NEAR(
    canvas.GetCurrentTransform(),
    Matrix(   0,   2,   0,   0,
             -3,   0,   0,   0,
              0,   0,   0,   0,
           -500, 400,   0,   1));
  // clang-format on
}

#if IMPELLER_ENABLE_3D
TEST_P(AiksTest, SceneColorSource) {
  // Load up the scene.
  auto mapping =
      flutter::testing::OpenFixtureAsMapping("flutter_logo_baked.glb.ipscene");
  ASSERT_NE(mapping, nullptr);

  std::shared_ptr<scene::Node> gltf_scene = scene::Node::MakeFromFlatbuffer(
      *mapping, *GetContext()->GetResourceAllocator());
  ASSERT_NE(gltf_scene, nullptr);

  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    Paint paint;

    static Scalar distance = 2;
    static Scalar y_pos = 0;
    static Scalar fov = 45;
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Distance", &distance, 0, 4);
      ImGui::SliderFloat("Y", &y_pos, -3, 3);
      ImGui::SliderFloat("FOV", &fov, 1, 180);
      ImGui::End();
    }

    Scalar angle = GetSecondsElapsed();
    auto camera_position =
        Vector3(distance * std::sin(angle), y_pos, -distance * std::cos(angle));

    paint.color_source = ColorSource::MakeScene(
        gltf_scene,
        Matrix::MakePerspective(Degrees(fov), GetWindowSize(), 0.1, 1000) *
            Matrix::MakeLookAt(camera_position, {0, 0, 0}, {0, 1, 0}));

    Canvas canvas;
    canvas.DrawPaint(Paint{.color = Color::MakeRGBA8(0xf9, 0xf9, 0xf9, 0xff)});
    canvas.Scale(GetContentScale());
    canvas.DrawPaint(paint);
    return canvas.EndRecordingAsPicture();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}
#endif  // IMPELLER_ENABLE_3D

TEST_P(AiksTest, PaintWithFilters) {
  // validate that a paint with a color filter "HasFilters", no other filters
  // impact this setting.
  Paint paint;

  ASSERT_FALSE(paint.HasColorFilter());

  paint.color_filter =
      ColorFilter::MakeBlend(BlendMode::kSourceOver, Color::Blue());

  ASSERT_TRUE(paint.HasColorFilter());

  paint.image_filter = ImageFilter::MakeBlur(Sigma(1.0), Sigma(1.0),
                                             FilterContents::BlurStyle::kNormal,
                                             Entity::TileMode::kClamp);

  ASSERT_TRUE(paint.HasColorFilter());

  paint.mask_blur_descriptor = {};

  ASSERT_TRUE(paint.HasColorFilter());

  paint.color_filter = nullptr;

  ASSERT_FALSE(paint.HasColorFilter());
}

TEST_P(AiksTest, DrawPaintAbsorbsClears) {
  Canvas canvas;
  canvas.DrawPaint({.color = Color::Red(), .blend_mode = BlendMode::kSource});
  canvas.DrawPaint({.color = Color::CornflowerBlue().WithAlpha(0.75),
                    .blend_mode = BlendMode::kSourceOver});

  Picture picture = canvas.EndRecordingAsPicture();
  auto expected = Color::Red().Blend(Color::CornflowerBlue().WithAlpha(0.75),
                                     BlendMode::kSourceOver);
  ASSERT_EQ(picture.pass->GetClearColor(), expected);

  std::shared_ptr<ContextSpy> spy = ContextSpy::Make();
  std::shared_ptr<Context> real_context = GetContext();
  std::shared_ptr<ContextMock> mock_context = spy->MakeContext(real_context);
  AiksContext renderer(mock_context, nullptr);
  std::shared_ptr<Image> image = picture.ToImage(renderer, {300, 300});

  ASSERT_EQ(spy->render_passes_.size(), 1llu);
  std::shared_ptr<RenderPass> render_pass = spy->render_passes_[0];
  ASSERT_EQ(render_pass->GetCommands().size(), 0llu);
}

// This is important to enforce with texture reuse, since cached textures need
// to be cleared before reuse.
TEST_P(AiksTest,
       ParentSaveLayerCreatesRenderPassWhenChildBackdropFilterIsPresent) {
  Canvas canvas;
  canvas.SaveLayer({}, std::nullopt, ImageFilter::MakeMatrix(Matrix(), {}));
  canvas.DrawPaint({.color = Color::Red(), .blend_mode = BlendMode::kSource});
  canvas.DrawPaint({.color = Color::CornflowerBlue().WithAlpha(0.75),
                    .blend_mode = BlendMode::kSourceOver});
  canvas.Restore();

  Picture picture = canvas.EndRecordingAsPicture();

  std::shared_ptr<ContextSpy> spy = ContextSpy::Make();
  std::shared_ptr<Context> real_context = GetContext();
  std::shared_ptr<ContextMock> mock_context = spy->MakeContext(real_context);
  AiksContext renderer(mock_context, nullptr);
  std::shared_ptr<Image> image = picture.ToImage(renderer, {300, 300});

  ASSERT_EQ(spy->render_passes_.size(),
            GetBackend() == PlaygroundBackend::kOpenGLES ? 4llu : 3llu);
  std::shared_ptr<RenderPass> render_pass = spy->render_passes_[0];
  ASSERT_EQ(render_pass->GetCommands().size(), 0llu);
}

TEST_P(AiksTest, DrawRectAbsorbsClears) {
  Canvas canvas;
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 300, 300),
                  {.color = Color::Red(), .blend_mode = BlendMode::kSource});
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 300, 300),
                  {.color = Color::CornflowerBlue().WithAlpha(0.75),
                   .blend_mode = BlendMode::kSourceOver});

  std::shared_ptr<ContextSpy> spy = ContextSpy::Make();
  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<Context> real_context = GetContext();
  std::shared_ptr<ContextMock> mock_context = spy->MakeContext(real_context);
  AiksContext renderer(mock_context, nullptr);
  std::shared_ptr<Image> image = picture.ToImage(renderer, {300, 300});

  ASSERT_EQ(spy->render_passes_.size(), 1llu);
  std::shared_ptr<RenderPass> render_pass = spy->render_passes_[0];
  ASSERT_EQ(render_pass->GetCommands().size(), 0llu);
}

TEST_P(AiksTest, DrawRectAbsorbsClearsNegativeRRect) {
  Canvas canvas;
  canvas.DrawRRect(Rect::MakeXYWH(0, 0, 300, 300), {5.0, 5.0},
                   {.color = Color::Red(), .blend_mode = BlendMode::kSource});
  canvas.DrawRRect(Rect::MakeXYWH(0, 0, 300, 300), {5.0, 5.0},
                   {.color = Color::CornflowerBlue().WithAlpha(0.75),
                    .blend_mode = BlendMode::kSourceOver});

  std::shared_ptr<ContextSpy> spy = ContextSpy::Make();
  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<Context> real_context = GetContext();
  std::shared_ptr<ContextMock> mock_context = spy->MakeContext(real_context);
  AiksContext renderer(mock_context, nullptr);
  std::shared_ptr<Image> image = picture.ToImage(renderer, {300, 300});

  ASSERT_EQ(spy->render_passes_.size(), 1llu);
  std::shared_ptr<RenderPass> render_pass = spy->render_passes_[0];
  ASSERT_EQ(render_pass->GetCommands().size(), 2llu);
}

TEST_P(AiksTest, DrawRectAbsorbsClearsNegativeRotation) {
  Canvas canvas;
  canvas.Translate(Vector3(150.0, 150.0, 0.0));
  canvas.Rotate(Degrees(45.0));
  canvas.Translate(Vector3(-150.0, -150.0, 0.0));
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 300, 300),
                  {.color = Color::Red(), .blend_mode = BlendMode::kSource});

  std::shared_ptr<ContextSpy> spy = ContextSpy::Make();
  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<Context> real_context = GetContext();
  std::shared_ptr<ContextMock> mock_context = spy->MakeContext(real_context);
  AiksContext renderer(mock_context, nullptr);
  std::shared_ptr<Image> image = picture.ToImage(renderer, {300, 300});

  ASSERT_EQ(spy->render_passes_.size(), 1llu);
  std::shared_ptr<RenderPass> render_pass = spy->render_passes_[0];
  ASSERT_EQ(render_pass->GetCommands().size(), 1llu);
}

TEST_P(AiksTest, DrawRectAbsorbsClearsNegative) {
  Canvas canvas;
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 300, 300),
                  {.color = Color::Red(), .blend_mode = BlendMode::kSource});
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 300, 300),
                  {.color = Color::CornflowerBlue().WithAlpha(0.75),
                   .blend_mode = BlendMode::kSourceOver});

  std::shared_ptr<ContextSpy> spy = ContextSpy::Make();
  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<Context> real_context = GetContext();
  std::shared_ptr<ContextMock> mock_context = spy->MakeContext(real_context);
  AiksContext renderer(mock_context, nullptr);
  std::shared_ptr<Image> image = picture.ToImage(renderer, {301, 301});

  ASSERT_EQ(spy->render_passes_.size(), 1llu);
  std::shared_ptr<RenderPass> render_pass = spy->render_passes_[0];
  ASSERT_EQ(render_pass->GetCommands().size(), 2llu);
}

TEST_P(AiksTest, ClipRectElidesNoOpClips) {
  Canvas canvas(Rect::MakeXYWH(0, 0, 100, 100));
  canvas.ClipRect(Rect::MakeXYWH(0, 0, 100, 100));
  canvas.ClipRect(Rect::MakeXYWH(-100, -100, 300, 300));
  canvas.DrawPaint({.color = Color::Red(), .blend_mode = BlendMode::kSource});
  canvas.DrawPaint({.color = Color::CornflowerBlue().WithAlpha(0.75),
                    .blend_mode = BlendMode::kSourceOver});

  Picture picture = canvas.EndRecordingAsPicture();
  auto expected = Color::Red().Blend(Color::CornflowerBlue().WithAlpha(0.75),
                                     BlendMode::kSourceOver);
  ASSERT_EQ(picture.pass->GetClearColor(), expected);

  std::shared_ptr<ContextSpy> spy = ContextSpy::Make();
  std::shared_ptr<Context> real_context = GetContext();
  std::shared_ptr<ContextMock> mock_context = spy->MakeContext(real_context);
  AiksContext renderer(mock_context, nullptr);
  std::shared_ptr<Image> image = picture.ToImage(renderer, {300, 300});

  ASSERT_EQ(spy->render_passes_.size(), 1llu);
  std::shared_ptr<RenderPass> render_pass = spy->render_passes_[0];
  ASSERT_EQ(render_pass->GetCommands().size(), 0llu);
}

TEST_P(AiksTest, ClearColorOptimizationDoesNotApplyForBackdropFilters) {
  Canvas canvas;
  canvas.SaveLayer({}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(3), Sigma(3),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.DrawPaint({.color = Color::Red(), .blend_mode = BlendMode::kSource});
  canvas.DrawPaint({.color = Color::CornflowerBlue().WithAlpha(0.75),
                    .blend_mode = BlendMode::kSourceOver});
  canvas.Restore();

  Picture picture = canvas.EndRecordingAsPicture();

  std::optional<Color> actual_color;
  bool found_subpass = false;
  picture.pass->IterateAllElements([&](EntityPass::Element& element) -> bool {
    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      actual_color = subpass->get()->GetClearColor();
      found_subpass = true;
    }
    // Fail if the first element isn't a subpass.
    return true;
  });

  EXPECT_TRUE(found_subpass);
  EXPECT_FALSE(actual_color.has_value());
}

TEST_P(AiksTest, ImageFilteredSaveLayerWithUnboundedContents) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  auto test = [&canvas](const std::shared_ptr<ImageFilter>& filter) {
    auto DrawLine = [&canvas](const Point& p0, const Point& p1,
                              const Paint& p) {
      auto path = PathBuilder{}
                      .AddLine(p0, p1)
                      .SetConvexity(Convexity::kConvex)
                      .TakePath();
      Paint paint = p;
      paint.style = Paint::Style::kStroke;
      canvas.DrawPath(path, paint);
    };
    // Registration marks for the edge of the SaveLayer
    DrawLine(Point(75, 100), Point(225, 100), {.color = Color::White()});
    DrawLine(Point(75, 200), Point(225, 200), {.color = Color::White()});
    DrawLine(Point(100, 75), Point(100, 225), {.color = Color::White()});
    DrawLine(Point(200, 75), Point(200, 225), {.color = Color::White()});

    canvas.SaveLayer({.image_filter = filter},
                     Rect::MakeLTRB(100, 100, 200, 200));
    {
      // DrawPaint to verify correct behavior when the contents are unbounded.
      canvas.DrawPaint({.color = Color::Yellow()});

      // Contrasting rectangle to see interior blurring
      canvas.DrawRect(Rect::MakeLTRB(125, 125, 175, 175),
                      {.color = Color::Blue()});
    }
    canvas.Restore();
  };

  test(ImageFilter::MakeBlur(Sigma{10.0}, Sigma{10.0},
                             FilterContents::BlurStyle::kNormal,
                             Entity::TileMode::kDecal));

  canvas.Translate({200.0, 0.0});

  test(ImageFilter::MakeDilate(Radius{10.0}, Radius{10.0}));

  canvas.Translate({200.0, 0.0});

  test(ImageFilter::MakeErode(Radius{10.0}, Radius{10.0}));

  canvas.Translate({-400.0, 200.0});

  auto rotate_filter =
      ImageFilter::MakeMatrix(Matrix::MakeTranslation({150, 150}) *
                                  Matrix::MakeRotationZ(Degrees{10.0}) *
                                  Matrix::MakeTranslation({-150, -150}),
                              SamplerDescriptor{});
  test(rotate_filter);

  canvas.Translate({200.0, 0.0});

  auto rgb_swap_filter = ImageFilter::MakeFromColorFilter(
      *ColorFilter::MakeMatrix({.array = {
                                    0, 1, 0, 0, 0,  //
                                    0, 0, 1, 0, 0,  //
                                    1, 0, 0, 0, 0,  //
                                    0, 0, 0, 1, 0   //
                                }}));
  test(rgb_swap_filter);

  canvas.Translate({200.0, 0.0});

  test(ImageFilter::MakeCompose(*rotate_filter, *rgb_swap_filter));

  canvas.Translate({-400.0, 200.0});

  test(ImageFilter::MakeLocalMatrix(Matrix::MakeTranslation({25.0, 25.0}),
                                    *rotate_filter));

  canvas.Translate({200.0, 0.0});

  test(ImageFilter::MakeLocalMatrix(Matrix::MakeTranslation({25.0, 25.0}),
                                    *rgb_swap_filter));

  canvas.Translate({200.0, 0.0});

  test(ImageFilter::MakeLocalMatrix(
      Matrix::MakeTranslation({25.0, 25.0}),
      *ImageFilter::MakeCompose(*rotate_filter, *rgb_swap_filter)));

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, OpaqueEntitiesGetCoercedToSource) {
  Canvas canvas;
  canvas.Scale(Vector2(1.618, 1.618));
  canvas.DrawCircle(Point(), 10,
                    {
                        .color = Color::CornflowerBlue(),
                        .blend_mode = BlendMode::kSourceOver,
                    });
  Picture picture = canvas.EndRecordingAsPicture();

  // Extract the SolidColorSource.
  // Entity entity;
  std::vector<Entity> entity;
  std::shared_ptr<SolidColorContents> contents;
  picture.pass->IterateAllEntities([e = &entity, &contents](Entity& entity) {
    if (ScalarNearlyEqual(entity.GetTransform().GetScale().x, 1.618f)) {
      contents =
          std::static_pointer_cast<SolidColorContents>(entity.GetContents());
      e->emplace_back(entity.Clone());
      return false;
    }
    return true;
  });

  ASSERT_TRUE(entity.size() >= 1);
  ASSERT_TRUE(contents->IsOpaque());
  ASSERT_EQ(entity[0].GetBlendMode(), BlendMode::kSource);
}

TEST_P(AiksTest, MatrixSaveLayerFilter) {
  Canvas canvas;
  canvas.DrawPaint({.color = Color::Black()});
  canvas.SaveLayer({}, std::nullopt);
  {
    canvas.DrawCircle(Point(200, 200), 100,
                      {.color = Color::Green().WithAlpha(0.5),
                       .blend_mode = BlendMode::kPlus});
    // Should render a second circle, centered on the bottom-right-most edge of
    // the circle.
    canvas.SaveLayer({.image_filter = ImageFilter::MakeMatrix(
                          Matrix::MakeTranslation(Vector2(1, 1) *
                                                  (200 + 100 * k1OverSqrt2)) *
                              Matrix::MakeScale(Vector2(1, 1) * 0.5) *
                              Matrix::MakeTranslation(Vector2(-200, -200)),
                          SamplerDescriptor{})},
                     std::nullopt);
    canvas.DrawCircle(Point(200, 200), 100,
                      {.color = Color::Green().WithAlpha(0.5),
                       .blend_mode = BlendMode::kPlus});
    canvas.Restore();
  }
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, MatrixBackdropFilter) {
  Canvas canvas;
  canvas.DrawPaint({.color = Color::Black()});
  canvas.SaveLayer({}, std::nullopt);
  {
    canvas.DrawCircle(Point(200, 200), 100,
                      {.color = Color::Green().WithAlpha(0.5),
                       .blend_mode = BlendMode::kPlus});
    // Should render a second circle, centered on the bottom-right-most edge of
    // the circle.
    canvas.SaveLayer(
        {}, std::nullopt,
        ImageFilter::MakeMatrix(
            Matrix::MakeTranslation(Vector2(1, 1) * (100 + 100 * k1OverSqrt2)) *
                Matrix::MakeScale(Vector2(1, 1) * 0.5) *
                Matrix::MakeTranslation(Vector2(-100, -100)),
            SamplerDescriptor{}));
    canvas.Restore();
  }
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, SolidColorApplyColorFilter) {
  auto contents = SolidColorContents();
  contents.SetColor(Color::CornflowerBlue().WithAlpha(0.75));
  auto result = contents.ApplyColorFilter([](const Color& color) {
    return color.Blend(Color::LimeGreen().WithAlpha(0.75), BlendMode::kScreen);
  });
  ASSERT_TRUE(result);
  ASSERT_COLOR_NEAR(contents.GetColor(),
                    Color(0.424452, 0.828743, 0.79105, 0.9375));
}

// Regression test for https://github.com/flutter/flutter/issues/134678.
TEST_P(AiksTest, ReleasesTextureOnTeardown) {
  auto context = MakeContext();
  std::weak_ptr<Texture> weak_texture;

  {
    auto texture = CreateTextureForFixture("table_mountain_nx.png");

    Canvas canvas;
    canvas.Scale(GetContentScale());
    canvas.Translate({100.0f, 100.0f, 0});

    Paint paint;
    paint.color_source = ColorSource::MakeImage(
        texture, Entity::TileMode::kClamp, Entity::TileMode::kClamp, {}, {});
    canvas.DrawRect(Rect::MakeXYWH(0, 0, 600, 600), paint);

    ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
  }

  // See https://github.com/flutter/flutter/issues/134751.
  //
  // If the fence waiter was working this may not be released by the end of the
  // scope above. Adding a manual shutdown so that future changes to the fence
  // waiter will not flake this test.
  context->Shutdown();

  // The texture should be released by now.
  ASSERT_TRUE(weak_texture.expired()) << "When the texture is no longer in use "
                                         "by the backend, it should be "
                                         "released.";
}

TEST_P(AiksTest, MatrixImageFilterMagnify) {
  Scalar scale = 2.0;
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Scale", &scale, 1, 2);
      ImGui::End();
    }
    Canvas canvas;
    canvas.Scale(GetContentScale());
    auto image =
        std::make_shared<Image>(CreateTextureForFixture("airplane.jpg"));
    canvas.Translate({600, -200});
    canvas.SaveLayer({
        .image_filter = std::make_shared<MatrixImageFilter>(
            Matrix::MakeScale({scale, scale, 1}), SamplerDescriptor{}),
    });
    canvas.DrawImage(image, {0, 0},
                     Paint{.color = Color::White().WithAlpha(0.5)});
    canvas.Restore();
    return canvas.EndRecordingAsPicture();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CorrectClipDepthAssignedToEntities) {
  Canvas canvas;  // Depth 1 (base pass)
  canvas.DrawRRect(Rect::MakeLTRB(0, 0, 100, 100), {10, 10}, {});  // Depth 2
  canvas.Save();
  {
    canvas.ClipRRect(Rect::MakeLTRB(0, 0, 50, 50), {10, 10}, {});  // Depth 4
    canvas.SaveLayer({});                                          // Depth 4
    {
      canvas.DrawRRect(Rect::MakeLTRB(0, 0, 50, 50), {10, 10}, {});  // Depth 3
    }
    canvas.Restore();  // Restore the savelayer.
  }
  canvas.Restore();  // Depth 5 -- this will no longer append a restore entity
                     //            once we switch to the clip depth approach.

  auto picture = canvas.EndRecordingAsPicture();

  std::vector<uint32_t> expected = {
      2,  // DrawRRect
      4,  // ClipRRect -- Has a depth value equal to the max depth of all the
          //              content it affect. In this case, the SaveLayer and all
          //              its contents are affected.
      4,  // SaveLayer -- The SaveLayer is drawn to the parent pass after its
          //              contents are rendered, so it should have a depth value
          //              greater than all its contents.
      3,  // DrawRRect
      5,  // Restore (no longer necessary when clipping on the depth buffer)
  };

  std::vector<uint32_t> actual;

  picture.pass->IterateAllElements([&](EntityPass::Element& element) -> bool {
    if (auto* subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      actual.push_back(subpass->get()->GetClipDepth());
    }
    if (Entity* entity = std::get_if<Entity>(&element)) {
      actual.push_back(entity->GetClipDepth());
    }
    return true;
  });

  ASSERT_EQ(actual.size(), expected.size());
  for (size_t i = 0; i < expected.size(); i++) {
    EXPECT_EQ(expected[i], actual[i]) << "Index: " << i;
  }
}

TEST_P(AiksTest, MipmapGenerationWorksCorrectly) {
  TextureDescriptor texture_descriptor;
  texture_descriptor.size = ISize{1024, 1024};
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.storage_mode = StorageMode::kHostVisible;
  texture_descriptor.mip_count = texture_descriptor.size.MipCount();

  std::vector<uint8_t> bytes(4194304);
  bool alternate = false;
  for (auto i = 0u; i < 4194304; i += 4) {
    if (alternate) {
      bytes[i] = 255;
      bytes[i + 1] = 0;
      bytes[i + 2] = 0;
      bytes[i + 3] = 255;
    } else {
      bytes[i] = 0;
      bytes[i + 1] = 255;
      bytes[i + 2] = 0;
      bytes[i + 3] = 255;
    }
    alternate = !alternate;
  }

  ASSERT_EQ(texture_descriptor.GetByteSizeOfBaseMipLevel(), bytes.size());
  auto mapping = std::make_shared<fml::NonOwnedMapping>(
      bytes.data(),                                   // data
      texture_descriptor.GetByteSizeOfBaseMipLevel()  // size
  );
  auto texture =
      GetContext()->GetResourceAllocator()->CreateTexture(texture_descriptor);

  auto device_buffer =
      GetContext()->GetResourceAllocator()->CreateBufferWithCopy(*mapping);
  auto command_buffer = GetContext()->CreateCommandBuffer();
  auto blit_pass = command_buffer->CreateBlitPass();

  blit_pass->AddCopy(DeviceBuffer::AsBufferView(std::move(device_buffer)),
                     texture);
  blit_pass->GenerateMipmap(texture);
  EXPECT_TRUE(blit_pass->EncodeCommands(GetContext()->GetResourceAllocator()));
  EXPECT_TRUE(GetContext()->GetCommandQueue()->Submit({command_buffer}).ok());

  auto image = std::make_shared<Image>(texture);

  Canvas canvas;
  canvas.DrawImageRect(image, Rect::MakeSize(texture->GetSize()),
                       Rect::MakeLTRB(0, 0, 100, 100), {});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

// https://github.com/flutter/flutter/issues/146648
TEST_P(AiksTest, StrokedPathWithMoveToThenCloseDrawnCorrectly) {
  Path path = PathBuilder{}
                  .MoveTo({0, 400})
                  .LineTo({0, 0})
                  .LineTo({400, 0})
                  // MoveTo implicitly adds a contour, ensure that close doesn't
                  // add another nearly-empty contour.
                  .MoveTo({0, 400})
                  .Close()
                  .TakePath();

  Canvas canvas;
  canvas.Translate({50, 50, 0});
  canvas.DrawPath(path, {
                            .color = Color::Blue(),
                            .stroke_width = 10,
                            .stroke_cap = Cap::kRound,
                            .style = Paint::Style::kStroke,
                        });
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, SetContentsWithRegion) {
  auto bridge = CreateTextureForFixture("bay_bridge.jpg");

  // Replace part of the texture with a red rectangle.
  std::vector<uint8_t> bytes(100 * 100 * 4);
  for (auto i = 0u; i < bytes.size(); i += 4) {
    bytes[i] = 255;
    bytes[i + 1] = 0;
    bytes[i + 2] = 0;
    bytes[i + 3] = 255;
  }
  auto mapping =
      std::make_shared<fml::NonOwnedMapping>(bytes.data(), bytes.size());
  auto device_buffer =
      GetContext()->GetResourceAllocator()->CreateBufferWithCopy(*mapping);
  auto cmd_buffer = GetContext()->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->AddCopy(DeviceBuffer::AsBufferView(device_buffer), bridge,
                     IRect::MakeLTRB(50, 50, 150, 150));

  auto did_submit =
      blit_pass->EncodeCommands(GetContext()->GetResourceAllocator()) &&
      GetContext()->GetCommandQueue()->Submit({std::move(cmd_buffer)}).ok();
  ASSERT_TRUE(did_submit);

  auto image = std::make_shared<Image>(bridge);

  Canvas canvas;
  canvas.DrawImage(image, {0, 0}, {});

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

}  // namespace testing
}  // namespace impeller

// █████████████████████████████████████████████████████████████████████████████
// █ NOTICE: Before adding new tests to this file consider adding it to one of
// █         the subdivisions of AiksTest to avoid having one massive file.
// █
// █ Subdivisions:
// █ - aiks_blend_unittests.cc
// █ - aiks_blur_unittests.cc
// █ - aiks_gradient_unittests.cc
// █████████████████████████████████████████████████████████████████████████████

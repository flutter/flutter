// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/aiks_unittests.h"

#include "impeller/aiks/canvas.h"
#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"
#include "impeller/entity/render_target_cache.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/playground/widgets.h"
#include "impeller/renderer/testing/mocks.h"
#include "third_party/imgui/imgui.h"

////////////////////////////////////////////////////////////////////////////////
// This is for tests of Canvas that are interested the results of rendering
// blurs.
////////////////////////////////////////////////////////////////////////////////

namespace impeller {
namespace testing {

TEST_P(AiksTest, CanRenderMaskBlurHugeSigma) {
  Canvas canvas;
  canvas.DrawCircle({400, 400}, 300,
                    {.color = Color::Green(),
                     .mask_blur_descriptor = Paint::MaskBlurDescriptor{
                         .style = FilterContents::BlurStyle::kNormal,
                         .sigma = Sigma(99999),
                     }});
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderForegroundBlendWithMaskBlur) {
  // This case triggers the ForegroundPorterDuffBlend path. The color filter
  // should apply to the color only, and respect the alpha mask.
  Canvas canvas;
  canvas.ClipRect(Rect::MakeXYWH(100, 150, 400, 400));
  canvas.DrawCircle({400, 400}, 200,
                    {
                        .color = Color::White(),
                        .color_filter = ColorFilter::MakeBlend(
                            BlendMode::kSource, Color::Green()),
                        .mask_blur_descriptor =
                            Paint::MaskBlurDescriptor{
                                .style = FilterContents::BlurStyle::kNormal,
                                .sigma = Radius(20),
                            },
                    });
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderForegroundAdvancedBlendWithMaskBlur) {
  // This case triggers the ForegroundAdvancedBlend path. The color filter
  // should apply to the color only, and respect the alpha mask.
  Canvas canvas;
  canvas.ClipRect(Rect::MakeXYWH(100, 150, 400, 400));
  canvas.DrawCircle({400, 400}, 200,
                    {
                        .color = Color::Grey(),
                        .color_filter = ColorFilter::MakeBlend(
                            BlendMode::kColor, Color::Green()),
                        .mask_blur_descriptor =
                            Paint::MaskBlurDescriptor{
                                .style = FilterContents::BlurStyle::kNormal,
                                .sigma = Radius(20),
                            },
                    });
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderBackdropBlurInteractive) {
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    static PlaygroundPoint point_a(Point(50, 50), 30, Color::White());
    static PlaygroundPoint point_b(Point(300, 200), 30, Color::White());
    auto [a, b] = DrawPlaygroundLine(point_a, point_b);

    Canvas canvas;
    canvas.DrawCircle({100, 100}, 50, {.color = Color::CornflowerBlue()});
    canvas.DrawCircle({300, 200}, 100, {.color = Color::GreenYellow()});
    canvas.DrawCircle({140, 170}, 75, {.color = Color::DarkMagenta()});
    canvas.DrawCircle({180, 120}, 100, {.color = Color::OrangeRed()});
    canvas.ClipRRect(Rect::MakeLTRB(a.x, a.y, b.x, b.y), {20, 20});
    canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                     ImageFilter::MakeBlur(Sigma(20.0), Sigma(20.0),
                                           FilterContents::BlurStyle::kNormal,
                                           Entity::TileMode::kClamp));
    canvas.Restore();

    return canvas.EndRecordingAsPicture();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderBackdropBlur) {
  Canvas canvas;
  canvas.DrawCircle({100, 100}, 50, {.color = Color::CornflowerBlue()});
  canvas.DrawCircle({300, 200}, 100, {.color = Color::GreenYellow()});
  canvas.DrawCircle({140, 170}, 75, {.color = Color::DarkMagenta()});
  canvas.DrawCircle({180, 120}, 100, {.color = Color::OrangeRed()});
  canvas.ClipRRect(Rect::MakeLTRB(75, 50, 375, 275), {20, 20});
  canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(30.0), Sigma(30.0),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderBackdropBlurHugeSigma) {
  Canvas canvas;
  canvas.DrawCircle({400, 400}, 300, {.color = Color::Green()});
  canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(999999), Sigma(999999),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, CanRenderClippedBlur) {
  Canvas canvas;
  canvas.ClipRect(Rect::MakeXYWH(100, 150, 400, 400));
  canvas.DrawCircle(
      {400, 400}, 200,
      {
          .color = Color::Green(),
          .image_filter = ImageFilter::MakeBlur(
              Sigma(20.0), Sigma(20.0), FilterContents::BlurStyle::kNormal,
              Entity::TileMode::kDecal),
      });
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, ClippedBlurFilterRendersCorrectlyInteractive) {
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    static PlaygroundPoint playground_point(Point(400, 400), 20,
                                            Color::Green());
    auto point = DrawPlaygroundPoint(playground_point);

    Canvas canvas;
    canvas.Translate(point - Point(400, 400));
    Paint paint;
    paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
        .style = FilterContents::BlurStyle::kNormal,
        .sigma = Radius{120 * 3},
    };
    paint.color = Color::Red();
    PathBuilder builder{};
    builder.AddRect(Rect::MakeLTRB(0, 0, 800, 800));
    canvas.DrawPath(builder.TakePath(), paint);
    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, ClippedBlurFilterRendersCorrectly) {
  Canvas canvas;
  canvas.Translate(Point(0, -400));
  Paint paint;
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kNormal,
      .sigma = Radius{120 * 3},
  };
  paint.color = Color::Red();
  PathBuilder builder{};
  builder.AddRect(Rect::MakeLTRB(0, 0, 800, 800));
  canvas.DrawPath(builder.TakePath(), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, ClearBlendWithBlur) {
  Canvas canvas;
  Paint white;
  white.color = Color::Blue();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 600.0, 600.0), white);

  Paint clear;
  clear.blend_mode = BlendMode::kClear;
  clear.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kNormal,
      .sigma = Sigma(20),
  };

  canvas.DrawCircle(Point::MakeXY(300.0, 300.0), 200.0, clear);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, BlurHasNoEdge) {
  Canvas canvas;
  canvas.Scale(GetContentScale());
  canvas.DrawPaint({});
  Paint blur = {
      .color = Color::Green(),
      .mask_blur_descriptor =
          Paint::MaskBlurDescriptor{
              .style = FilterContents::BlurStyle::kNormal,
              .sigma = Sigma(47.6),
          },
  };
  canvas.DrawRect(Rect::MakeXYWH(300, 300, 200, 200), blur);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, BlurredRectangleWithShader) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  auto paint_lines = [&canvas](Scalar dx, Scalar dy, Paint paint) {
    auto draw_line = [&canvas, &paint](Point a, Point b) {
      canvas.DrawPath(PathBuilder{}.AddLine(a, b).TakePath(), paint);
    };
    paint.stroke_width = 5;
    paint.style = Paint::Style::kStroke;
    draw_line(Point(dx + 100, dy + 100), Point(dx + 200, dy + 200));
    draw_line(Point(dx + 100, dy + 200), Point(dx + 200, dy + 100));
    draw_line(Point(dx + 150, dy + 100), Point(dx + 200, dy + 150));
    draw_line(Point(dx + 100, dy + 150), Point(dx + 150, dy + 200));
  };

  AiksContext renderer(GetContext(), nullptr);
  Canvas recorder_canvas;
  for (int x = 0; x < 5; ++x) {
    for (int y = 0; y < 5; ++y) {
      Rect rect = Rect::MakeXYWH(x * 20, y * 20, 20, 20);
      Paint paint{.color =
                      ((x + y) & 1) == 0 ? Color::Yellow() : Color::Blue()};
      recorder_canvas.DrawRect(rect, paint);
    }
  }
  Picture picture = recorder_canvas.EndRecordingAsPicture();
  std::shared_ptr<Texture> texture =
      picture.ToImage(renderer, ISize{100, 100})->GetTexture();

  ColorSource image_source = ColorSource::MakeImage(
      texture, Entity::TileMode::kRepeat, Entity::TileMode::kRepeat, {}, {});
  std::shared_ptr<ImageFilter> blur_filter = ImageFilter::MakeBlur(
      Sigma(5), Sigma(5), FilterContents::BlurStyle::kNormal,
      Entity::TileMode::kDecal);
  canvas.DrawRect(Rect::MakeLTRB(0, 0, 300, 600),
                  Paint{.color = Color::DarkGreen()});
  canvas.DrawRect(Rect::MakeLTRB(100, 100, 200, 200),
                  Paint{.color_source = image_source});
  canvas.DrawRect(Rect::MakeLTRB(300, 0, 600, 600),
                  Paint{.color = Color::Red()});
  canvas.DrawRect(
      Rect::MakeLTRB(400, 100, 500, 200),
      Paint{.color_source = image_source, .image_filter = blur_filter});
  paint_lines(0, 300, Paint{.color_source = image_source});
  paint_lines(300, 300,
              Paint{.color_source = image_source, .image_filter = blur_filter});
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, MaskBlurWithZeroSigmaIsSkipped) {
  Canvas canvas;

  Paint paint = {
      .color = Color::Blue(),
      .mask_blur_descriptor =
          Paint::MaskBlurDescriptor{
              .style = FilterContents::BlurStyle::kNormal,
              .sigma = Sigma(0),
          },
  };

  canvas.DrawCircle({300, 300}, 200, paint);
  canvas.DrawRect(Rect::MakeLTRB(100, 300, 500, 600), paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

struct MaskBlurTestConfig {
  FilterContents::BlurStyle style = FilterContents::BlurStyle::kNormal;
  Scalar sigma = 1.0f;
  Scalar alpha = 1.0f;
  std::shared_ptr<ImageFilter> image_filter;
  bool invert_colors = false;
  BlendMode blend_mode = BlendMode::kSourceOver;
};

static Picture MaskBlurVariantTest(const AiksTest& test_context,
                                   const MaskBlurTestConfig& config) {
  Canvas canvas;
  canvas.Scale(test_context.GetContentScale());
  canvas.Scale(Vector2{0.8f, 0.8f});
  Paint paint;
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kNormal,
      .sigma = Sigma{1},
  };

  canvas.DrawPaint({.color = Color::AntiqueWhite()});

  paint.mask_blur_descriptor->style = config.style;
  paint.mask_blur_descriptor->sigma = Sigma{config.sigma};
  paint.image_filter = config.image_filter;
  paint.invert_colors = config.invert_colors;
  paint.blend_mode = config.blend_mode;

  const Scalar x = 50;
  const Scalar radius = 20.0f;
  const Scalar y_spacing = 100.0f;

  Scalar y = 50;
  paint.color = Color::Crimson().WithAlpha(config.alpha);
  canvas.DrawRect(Rect::MakeXYWH(x + 25 - radius / 2, y + radius / 2,  //
                                 radius, 60.0f - radius),
                  paint);

  y += y_spacing;
  paint.color = Color::Blue().WithAlpha(config.alpha);
  canvas.DrawCircle({x + 25, y + 25}, radius, paint);

  y += y_spacing;
  paint.color = Color::Green().WithAlpha(config.alpha);
  canvas.DrawOval(Rect::MakeXYWH(x + 25 - radius / 2, y + radius / 2,  //
                                 radius, 60.0f - radius),
                  paint);

  y += y_spacing;
  paint.color = Color::Purple().WithAlpha(config.alpha);
  canvas.DrawRRect(Rect::MakeXYWH(x, y, 60.0f, 60.0f),  //
                   {radius, radius},                    //
                   paint);

  y += y_spacing;
  paint.color = Color::Orange().WithAlpha(config.alpha);
  canvas.DrawRRect(Rect::MakeXYWH(x, y, 60.0f, 60.0f),  //
                   {radius, 5.0f}, paint);

  y += y_spacing;
  paint.color = Color::Maroon().WithAlpha(config.alpha);
  canvas.DrawPath(PathBuilder{}
                      .MoveTo({x + 0, y + 60})
                      .LineTo({x + 30, y + 0})
                      .LineTo({x + 60, y + 60})
                      .Close()
                      .TakePath(),
                  paint);

  y += y_spacing;
  paint.color = Color::Maroon().WithAlpha(config.alpha);
  canvas.DrawPath(PathBuilder{}
                      .AddArc(Rect::MakeXYWH(x + 5, y, 50, 50),
                              Radians{kPi / 2}, Radians{kPi})
                      .AddArc(Rect::MakeXYWH(x + 25, y, 50, 50),
                              Radians{kPi / 2}, Radians{kPi})
                      .Close()
                      .TakePath(),
                  paint);

  return canvas.EndRecordingAsPicture();
}

static const std::map<std::string, MaskBlurTestConfig> kPaintVariations = {
    // 1. Normal style, translucent, zero sigma.
    {"NormalTranslucentZeroSigma",
     {.style = FilterContents::BlurStyle::kNormal,
      .sigma = 0.0f,
      .alpha = 0.5f}},
    // 2. Normal style, translucent.
    {"NormalTranslucent",
     {.style = FilterContents::BlurStyle::kNormal,
      .sigma = 8.0f,
      .alpha = 0.5f}},
    // 3. Solid style, translucent.
    {"SolidTranslucent",
     {.style = FilterContents::BlurStyle::kSolid,
      .sigma = 8.0f,
      .alpha = 0.5f}},
    // 4. Solid style, opaque.
    {"SolidOpaque",
     {.style = FilterContents::BlurStyle::kSolid, .sigma = 8.0f}},
    // 5. Solid style, translucent, color & image filtered.
    {"SolidTranslucentWithFilters",
     {.style = FilterContents::BlurStyle::kSolid,
      .sigma = 8.0f,
      .alpha = 0.5f,
      .image_filter = ImageFilter::MakeBlur(Sigma{3},
                                            Sigma{3},
                                            FilterContents::BlurStyle::kNormal,
                                            Entity::TileMode::kClamp),
      .invert_colors = true}},
    // 6. Solid style, translucent, exclusion blended.
    {"SolidTranslucentExclusionBlend",
     {.style = FilterContents::BlurStyle::kSolid,
      .sigma = 8.0f,
      .alpha = 0.5f,
      .blend_mode = BlendMode::kExclusion}},
    // 7. Inner style, translucent.
    {"InnerTranslucent",
     {.style = FilterContents::BlurStyle::kInner,
      .sigma = 8.0f,
      .alpha = 0.5f}},
    // 8. Inner style, translucent, blurred.
    {"InnerTranslucentWithBlurImageFilter",
     {.style = FilterContents::BlurStyle::kInner,
      .sigma = 8.0f,
      .alpha = 0.5f,
      .image_filter = ImageFilter::MakeBlur(Sigma{3},
                                            Sigma{3},
                                            FilterContents::BlurStyle::kNormal,
                                            Entity::TileMode::kClamp)}},
    // 9. Outer style, translucent.
    {"OuterTranslucent",
     {.style = FilterContents::BlurStyle::kOuter,
      .sigma = 8.0f,
      .alpha = 0.5f}},
    // 10. Outer style, opaque, image filtered.
    {"OuterOpaqueWithBlurImageFilter",
     {.style = FilterContents::BlurStyle::kOuter,
      .sigma = 8.0f,
      .image_filter = ImageFilter::MakeBlur(Sigma{3},
                                            Sigma{3},
                                            FilterContents::BlurStyle::kNormal,
                                            Entity::TileMode::kClamp)}},
};

#define MASK_BLUR_VARIANT_TEST(config)                              \
  TEST_P(AiksTest, MaskBlurVariantTest##config) {                   \
    ASSERT_TRUE(OpenPlaygroundHere(                                 \
        MaskBlurVariantTest(*this, kPaintVariations.at(#config)))); \
  }

MASK_BLUR_VARIANT_TEST(NormalTranslucentZeroSigma)
MASK_BLUR_VARIANT_TEST(NormalTranslucent)
MASK_BLUR_VARIANT_TEST(SolidTranslucent)
MASK_BLUR_VARIANT_TEST(SolidOpaque)
MASK_BLUR_VARIANT_TEST(SolidTranslucentWithFilters)
MASK_BLUR_VARIANT_TEST(SolidTranslucentExclusionBlend)
MASK_BLUR_VARIANT_TEST(InnerTranslucent)
MASK_BLUR_VARIANT_TEST(InnerTranslucentWithBlurImageFilter)
MASK_BLUR_VARIANT_TEST(OuterTranslucent)
MASK_BLUR_VARIANT_TEST(OuterOpaqueWithBlurImageFilter)

#undef MASK_BLUR_VARIANT_TEST

TEST_P(AiksTest, GaussianBlurAtPeripheryVertical) {
  Canvas canvas;

  canvas.Scale(GetContentScale());
  canvas.DrawRRect(Rect::MakeLTRB(0, 0, GetWindowSize().width, 100),
                   Size(10, 10), Paint{.color = Color::LimeGreen()});
  canvas.DrawRRect(Rect::MakeLTRB(0, 110, GetWindowSize().width, 210),
                   Size(10, 10), Paint{.color = Color::Magenta()});
  canvas.ClipRect(Rect::MakeLTRB(100, 0, 200, GetWindowSize().height));
  canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(20.0), Sigma(20.0),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurAtPeripheryHorizontal) {
  Canvas canvas;

  canvas.Scale(GetContentScale());
  std::shared_ptr<Texture> boston = CreateTextureForFixture("boston.jpg");
  canvas.DrawImageRect(
      std::make_shared<Image>(boston),
      Rect::MakeXYWH(0, 0, boston->GetSize().width, boston->GetSize().height),
      Rect::MakeLTRB(0, 0, GetWindowSize().width, 100), Paint{});
  canvas.DrawRRect(Rect::MakeLTRB(0, 110, GetWindowSize().width, 210),
                   Size(10, 10), Paint{.color = Color::Magenta()});
  canvas.ClipRect(Rect::MakeLTRB(0, 50, GetWindowSize().width, 150));
  canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(20.0), Sigma(20.0),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

#define FLT_FORWARD(mock, real, method) \
  EXPECT_CALL(*mock, method())          \
      .WillRepeatedly(::testing::Return(real->method()));

TEST_P(AiksTest, GaussianBlurWithoutDecalSupport) {
  if (GetParam() != PlaygroundBackend::kMetal) {
    GTEST_SKIP_(
        "This backend doesn't yet support setting device capabilities.");
  }
  if (!WillRenderSomething()) {
    // Sometimes these tests are run without playgrounds enabled which is
    // pointless for this test since we are asserting that
    // `SupportsDecalSamplerAddressMode` is called.
    GTEST_SKIP_("This test requires playgrounds.");
  }

  std::shared_ptr<const Capabilities> old_capabilities =
      GetContext()->GetCapabilities();
  auto mock_capabilities = std::make_shared<MockCapabilities>();
  EXPECT_CALL(*mock_capabilities, SupportsDecalSamplerAddressMode())
      .Times(::testing::AtLeast(1))
      .WillRepeatedly(::testing::Return(false));
  FLT_FORWARD(mock_capabilities, old_capabilities, GetDefaultColorFormat);
  FLT_FORWARD(mock_capabilities, old_capabilities, GetDefaultStencilFormat);
  FLT_FORWARD(mock_capabilities, old_capabilities,
              GetDefaultDepthStencilFormat);
  FLT_FORWARD(mock_capabilities, old_capabilities, SupportsOffscreenMSAA);
  FLT_FORWARD(mock_capabilities, old_capabilities,
              SupportsImplicitResolvingMSAA);
  FLT_FORWARD(mock_capabilities, old_capabilities, SupportsReadFromResolve);
  FLT_FORWARD(mock_capabilities, old_capabilities, SupportsFramebufferFetch);
  FLT_FORWARD(mock_capabilities, old_capabilities, SupportsSSBO);
  FLT_FORWARD(mock_capabilities, old_capabilities, SupportsCompute);
  FLT_FORWARD(mock_capabilities, old_capabilities,
              SupportsTextureToTextureBlits);
  FLT_FORWARD(mock_capabilities, old_capabilities, GetDefaultGlyphAtlasFormat);
  ASSERT_TRUE(SetCapabilities(mock_capabilities).ok());

  auto texture = std::make_shared<Image>(CreateTextureForFixture("boston.jpg"));
  Canvas canvas;
  canvas.Scale(GetContentScale() * 0.5);
  canvas.DrawPaint({.color = Color::Black()});
  canvas.DrawImage(
      texture, Point(200, 200),
      {
          .image_filter = ImageFilter::MakeBlur(
              Sigma(20.0), Sigma(20.0), FilterContents::BlurStyle::kNormal,
              Entity::TileMode::kDecal),
      });
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurOneDimension) {
  Canvas canvas;

  canvas.Scale(GetContentScale());
  canvas.Scale({0.5, 0.5, 1.0});
  std::shared_ptr<Texture> boston = CreateTextureForFixture("boston.jpg");
  canvas.DrawImage(std::make_shared<Image>(boston), Point(100, 100), Paint{});
  canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(50.0), Sigma(0.0),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

// Smoketest to catch issues with the coverage hint.
// Draws a rotated blurred image within a rectangle clip. The center of the clip
// rectangle is the center of the rotated image. The entire area of the clip
// rectangle should be filled with opaque colors output by the blur.
TEST_P(AiksTest, GaussianBlurRotatedAndClipped) {
  Canvas canvas;
  std::shared_ptr<Texture> boston = CreateTextureForFixture("boston.jpg");
  Rect bounds =
      Rect::MakeXYWH(0, 0, boston->GetSize().width, boston->GetSize().height);
  Vector2 image_center = Vector2(bounds.GetSize() / 2);
  Paint paint = {.image_filter =
                     ImageFilter::MakeBlur(Sigma(20.0), Sigma(20.0),
                                           FilterContents::BlurStyle::kNormal,
                                           Entity::TileMode::kDecal)};
  Vector2 clip_size = {150, 75};
  Vector2 center = Vector2(1024, 768) / 2;
  canvas.Scale(GetContentScale());
  canvas.ClipRect(
      Rect::MakeLTRB(center.x, center.y, center.x, center.y).Expand(clip_size));
  canvas.Translate({center.x, center.y, 0});
  canvas.Scale({0.6, 0.6, 1});
  canvas.Rotate(Degrees(25));

  canvas.DrawImageRect(std::make_shared<Image>(boston), /*source=*/bounds,
                       /*dest=*/bounds.Shift(-image_center), paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurScaledAndClipped) {
  Canvas canvas;
  std::shared_ptr<Texture> boston = CreateTextureForFixture("boston.jpg");
  Rect bounds =
      Rect::MakeXYWH(0, 0, boston->GetSize().width, boston->GetSize().height);
  Vector2 image_center = Vector2(bounds.GetSize() / 2);
  Paint paint = {.image_filter =
                     ImageFilter::MakeBlur(Sigma(20.0), Sigma(20.0),
                                           FilterContents::BlurStyle::kNormal,
                                           Entity::TileMode::kDecal)};
  Vector2 clip_size = {150, 75};
  Vector2 center = Vector2(1024, 768) / 2;
  canvas.Scale(GetContentScale());
  canvas.ClipRect(
      Rect::MakeLTRB(center.x, center.y, center.x, center.y).Expand(clip_size));
  canvas.Translate({center.x, center.y, 0});
  canvas.Scale({0.6, 0.6, 1});

  canvas.DrawImageRect(std::make_shared<Image>(boston), /*source=*/bounds,
                       /*dest=*/bounds.Shift(-image_center), paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurRotatedAndClippedInteractive) {
  std::shared_ptr<Texture> boston = CreateTextureForFixture("boston.jpg");

  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    static float rotation = 0;
    static float scale = 0.6;
    static int selected_tile_mode = 3;

    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Rotation (degrees)", &rotation, -180, 180);
      ImGui::SliderFloat("Scale", &scale, 0, 2.0);
      ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                   sizeof(tile_mode_names) / sizeof(char*));
      ImGui::End();
    }

    Canvas canvas;
    Rect bounds =
        Rect::MakeXYWH(0, 0, boston->GetSize().width, boston->GetSize().height);
    Vector2 image_center = Vector2(bounds.GetSize() / 2);
    Paint paint = {.image_filter =
                       ImageFilter::MakeBlur(Sigma(20.0), Sigma(20.0),
                                             FilterContents::BlurStyle::kNormal,
                                             tile_modes[selected_tile_mode])};
    static PlaygroundPoint point_a(Point(362, 309), 20, Color::Red());
    static PlaygroundPoint point_b(Point(662, 459), 20, Color::Red());
    auto [handle_a, handle_b] = DrawPlaygroundLine(point_a, point_b);
    Vector2 center = Vector2(1024, 768) / 2;
    canvas.Scale(GetContentScale());
    canvas.ClipRect(
        Rect::MakeLTRB(handle_a.x, handle_a.y, handle_b.x, handle_b.y));
    canvas.Translate({center.x, center.y, 0});
    canvas.Scale({scale, scale, 1});
    canvas.Rotate(Degrees(rotation));

    canvas.DrawImageRect(std::make_shared<Image>(boston), /*source=*/bounds,
                         /*dest=*/bounds.Shift(-image_center), paint);
    return canvas.EndRecordingAsPicture();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

// This addresses a bug where tiny blurs could result in mip maps that beyond
// the limits for the textures used for blurring.
// See also: b/323402168
TEST_P(AiksTest, GaussianBlurSolidColorTinyMipMap) {
  for (int32_t i = 1; i < 5; ++i) {
    Canvas canvas;
    Scalar fi = i;
    canvas.DrawPath(
        PathBuilder{}
            .MoveTo({100, 100})
            .LineTo({100.f + fi, 100.f + fi})
            .TakePath(),
        {.color = Color::Chartreuse(),
         .image_filter = ImageFilter::MakeBlur(
             Sigma(0.1), Sigma(0.1), FilterContents::BlurStyle::kNormal,
             Entity::TileMode::kClamp)});

    Picture picture = canvas.EndRecordingAsPicture();
    std::shared_ptr<RenderTargetCache> cache =
        std::make_shared<RenderTargetCache>(
            GetContext()->GetResourceAllocator());
    AiksContext aiks_context(GetContext(), nullptr, cache);
    std::shared_ptr<Image> image = picture.ToImage(aiks_context, {1024, 768});
    EXPECT_TRUE(image) << " length " << i;
  }
}

// This addresses a bug where tiny blurs could result in mip maps that beyond
// the limits for the textures used for blurring.
// See also: b/323402168
TEST_P(AiksTest, GaussianBlurBackdropTinyMipMap) {
  for (int32_t i = 0; i < 5; ++i) {
    Canvas canvas;
    ISize clip_size = ISize(i, i);
    canvas.ClipRect(
        Rect::MakeXYWH(400, 400, clip_size.width, clip_size.height));
    canvas.DrawCircle(
        {400, 400}, 200,
        {
            .color = Color::Green(),
            .image_filter = ImageFilter::MakeBlur(
                Sigma(0.1), Sigma(0.1), FilterContents::BlurStyle::kNormal,
                Entity::TileMode::kDecal),
        });
    canvas.Restore();

    Picture picture = canvas.EndRecordingAsPicture();
    std::shared_ptr<RenderTargetCache> cache =
        std::make_shared<RenderTargetCache>(
            GetContext()->GetResourceAllocator());
    AiksContext aiks_context(GetContext(), nullptr, cache);
    std::shared_ptr<Image> image = picture.ToImage(aiks_context, {1024, 768});
    EXPECT_TRUE(image) << " clip rect " << i;
  }
}

TEST_P(AiksTest, GaussianBlurAnimatedBackdrop) {
  // This test is for checking out how stable rendering is when content is
  // translated underneath a blur.  Animating under a blur can cause
  // *shimmering* to happen as a result of pixel alignment.
  // See also: https://github.com/flutter/flutter/issues/140193
  auto boston = std::make_shared<Image>(
      CreateTextureForFixture("boston.jpg", /*enable_mipmapping=*/true));
  ASSERT_TRUE(boston);
  int64_t count = 0;
  Scalar sigma = 20.0;
  Scalar freq = 0.1;
  Scalar amp = 50.0;
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Sigma", &sigma, 0, 200);
      ImGui::SliderFloat("Frequency", &freq, 0.01, 2.0);
      ImGui::SliderFloat("Amplitude", &amp, 1, 100);
      ImGui::End();
    }

    Canvas canvas;
    canvas.Scale(GetContentScale());
    Scalar y = amp * sin(freq * 2.0 * M_PI * count / 60);
    canvas.DrawImage(boston,
                     Point(1024 / 2 - boston->GetSize().width / 2,
                           (768 / 2 - boston->GetSize().height / 2) + y),
                     {});
    static PlaygroundPoint point_a(Point(100, 100), 20, Color::Red());
    static PlaygroundPoint point_b(Point(900, 700), 20, Color::Red());
    auto [handle_a, handle_b] = DrawPlaygroundLine(point_a, point_b);
    canvas.ClipRect(
        Rect::MakeLTRB(handle_a.x, handle_a.y, handle_b.x, handle_b.y));
    canvas.ClipRect(Rect::MakeLTRB(100, 100, 900, 700));
    canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                     ImageFilter::MakeBlur(Sigma(sigma), Sigma(sigma),
                                           FilterContents::BlurStyle::kNormal,
                                           Entity::TileMode::kClamp));
    count += 1;
    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, GaussianBlurStyleInnerGradient) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  canvas.DrawPaint({.color = Color(0.1, 0.1, 0.1, 1.0)});

  std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                               Color{0.7568, 0.2627, 0.2118, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  Paint paint;
  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {200, 200}, std::move(colors), std::move(stops),
      Entity::TileMode::kMirror, {});
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kInner,
      .sigma = Sigma(30),
  };
  canvas.DrawPath(PathBuilder()
                      .MoveTo({200, 200})
                      .LineTo({300, 400})
                      .LineTo({100, 400})
                      .Close()
                      .TakePath(),
                  paint);

  // Draw another thing to make sure the clip area is reset.
  Paint red;
  red.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 200, 200), red);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurStyleSolidGradient) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  canvas.DrawPaint({.color = Color(0.1, 0.1, 0.1, 1.0)});

  std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                               Color{0.7568, 0.2627, 0.2118, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  Paint paint;
  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {200, 200}, std::move(colors), std::move(stops),
      Entity::TileMode::kMirror, {});
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kSolid,
      .sigma = Sigma(30),
  };
  canvas.DrawPath(PathBuilder()
                      .MoveTo({200, 200})
                      .LineTo({300, 400})
                      .LineTo({100, 400})
                      .Close()
                      .TakePath(),
                  paint);

  // Draw another thing to make sure the clip area is reset.
  Paint red;
  red.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 200, 200), red);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurStyleOuterGradient) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  canvas.DrawPaint({.color = Color(0.1, 0.1, 0.1, 1.0)});

  std::vector<Color> colors = {Color{0.9568, 0.2627, 0.2118, 1.0},
                               Color{0.7568, 0.2627, 0.2118, 1.0}};
  std::vector<Scalar> stops = {0.0, 1.0};

  Paint paint;
  paint.color_source = ColorSource::MakeLinearGradient(
      {0, 0}, {200, 200}, std::move(colors), std::move(stops),
      Entity::TileMode::kMirror, {});
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kOuter,
      .sigma = Sigma(30),
  };
  canvas.DrawPath(PathBuilder()
                      .MoveTo({200, 200})
                      .LineTo({300, 400})
                      .LineTo({100, 400})
                      .Close()
                      .TakePath(),
                  paint);

  // Draw another thing to make sure the clip area is reset.
  Paint red;
  red.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 200, 200), red);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurStyleInner) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  canvas.DrawPaint({.color = Color(0.1, 0.1, 0.1, 1.0)});

  Paint paint;
  paint.color = Color::Green();
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kInner,
      .sigma = Sigma(30),
  };
  canvas.DrawPath(PathBuilder()
                      .MoveTo({200, 200})
                      .LineTo({300, 400})
                      .LineTo({100, 400})
                      .Close()
                      .TakePath(),
                  paint);

  // Draw another thing to make sure the clip area is reset.
  Paint red;
  red.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 200, 200), red);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurStyleOuter) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  canvas.DrawPaint({.color = Color(0.1, 0.1, 0.1, 1.0)});

  Paint paint;
  paint.color = Color::Green();
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kOuter,
      .sigma = Sigma(30),
  };
  canvas.DrawPath(PathBuilder()
                      .MoveTo({200, 200})
                      .LineTo({300, 400})
                      .LineTo({100, 400})
                      .Close()
                      .TakePath(),
                  paint);

  // Draw another thing to make sure the clip area is reset.
  Paint red;
  red.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 200, 200), red);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, GaussianBlurStyleSolid) {
  Canvas canvas;
  canvas.Scale(GetContentScale());

  canvas.DrawPaint({.color = Color(0.1, 0.1, 0.1, 1.0)});

  Paint paint;
  paint.color = Color::Green();
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kSolid,
      .sigma = Sigma(30),
  };
  canvas.DrawPath(PathBuilder()
                      .MoveTo({200, 200})
                      .LineTo({300, 400})
                      .LineTo({100, 400})
                      .Close()
                      .TakePath(),
                  paint);

  // Draw another thing to make sure the clip area is reset.
  Paint red;
  red.color = Color::Red();
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 200, 200), red);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_P(AiksTest, MaskBlurTexture) {
  Scalar sigma = 30;
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Sigma", &sigma, 0, 500);
      ImGui::End();
    }
    Canvas canvas;
    canvas.Scale(GetContentScale());
    Paint paint;
    paint.color = Color::Green();
    paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
        .style = FilterContents::BlurStyle::kNormal,
        .sigma = Sigma(sigma),
    };
    std::shared_ptr<Texture> boston = CreateTextureForFixture("boston.jpg");
    canvas.DrawImage(std::make_shared<Image>(boston), {200, 200}, paint);
    Paint red;
    red.color = Color::Red();
    canvas.DrawRect(Rect::MakeXYWH(0, 0, 200, 200), red);
    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, GuassianBlurUpdatesMipmapContents) {
  // This makes sure if mip maps are recycled across invocations of blurs the
  // contents get updated each frame correctly. If they aren't updated the color
  // inside the blur and outside the blur will be different.
  //
  // If there is some change to render target caching this could display a false
  // positive in the future.  Also, if the LOD that is rendered is 1 it could
  // present a false positive.
  int32_t count = 0;
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    Canvas canvas;
    if (count++ == 0) {
      canvas.DrawCircle({100, 100}, 50, {.color = Color::CornflowerBlue()});
    } else {
      canvas.DrawCircle({100, 100}, 50, {.color = Color::Chartreuse()});
    }
    canvas.ClipRRect(Rect::MakeLTRB(75, 50, 375, 275), {20, 20});
    canvas.SaveLayer({.blend_mode = BlendMode::kSource}, std::nullopt,
                     ImageFilter::MakeBlur(Sigma(30.0), Sigma(30.0),
                                           FilterContents::BlurStyle::kNormal,
                                           Entity::TileMode::kClamp));
    canvas.Restore();
    return canvas.EndRecordingAsPicture();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, GaussianBlurSetsMipCountOnPass) {
  Canvas canvas;
  canvas.DrawCircle({100, 100}, 50, {.color = Color::CornflowerBlue()});
  canvas.SaveLayer({}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(3), Sigma(3),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.Restore();

  Picture picture = canvas.EndRecordingAsPicture();
  EXPECT_EQ(4, picture.pass->GetRequiredMipCount());
}

TEST_P(AiksTest, GaussianBlurAllocatesCorrectMipCountRenderTarget) {
  size_t blur_required_mip_count =
      GetParam() == PlaygroundBackend::kOpenGLES ? 1 : 4;

  Canvas canvas;
  canvas.DrawCircle({100, 100}, 50, {.color = Color::CornflowerBlue()});
  canvas.SaveLayer({}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(3), Sigma(3),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.Restore();

  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<RenderTargetCache> cache =
      std::make_shared<RenderTargetCache>(GetContext()->GetResourceAllocator());
  AiksContext aiks_context(GetContext(), nullptr, cache);
  picture.ToImage(aiks_context, {100, 100});

  size_t max_mip_count = 0;
  for (auto it = cache->GetRenderTargetDataBegin();
       it != cache->GetRenderTargetDataEnd(); ++it) {
    max_mip_count = std::max(it->config.mip_count, max_mip_count);
  }
  EXPECT_EQ(max_mip_count, blur_required_mip_count);
}

TEST_P(AiksTest, GaussianBlurMipMapNestedLayer) {
  fml::testing::LogCapture log_capture;
  size_t blur_required_mip_count =
      GetParam() == PlaygroundBackend::kOpenGLES ? 1 : 4;

  Canvas canvas;
  canvas.DrawPaint({.color = Color::Wheat()});
  canvas.SaveLayer({.blend_mode = BlendMode::kMultiply});
  canvas.DrawCircle({100, 100}, 50, {.color = Color::CornflowerBlue()});
  canvas.SaveLayer({}, std::nullopt,
                   ImageFilter::MakeBlur(Sigma(30), Sigma(30),
                                         FilterContents::BlurStyle::kNormal,
                                         Entity::TileMode::kClamp));
  canvas.DrawCircle({200, 200}, 50, {.color = Color::Chartreuse()});

  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<RenderTargetCache> cache =
      std::make_shared<RenderTargetCache>(GetContext()->GetResourceAllocator());
  AiksContext aiks_context(GetContext(), nullptr, cache);
  picture.ToImage(aiks_context, {100, 100});

  size_t max_mip_count = 0;
  for (auto it = cache->GetRenderTargetDataBegin();
       it != cache->GetRenderTargetDataEnd(); ++it) {
    max_mip_count = std::max(it->config.mip_count, max_mip_count);
  }
  EXPECT_EQ(max_mip_count, blur_required_mip_count);
  // The log is FML_DLOG, so only check in debug builds.
#ifndef NDEBUG
  if (GetParam() != PlaygroundBackend::kOpenGLES) {
    EXPECT_EQ(log_capture.str().find(GaussianBlurFilterContents::kNoMipsError),
              std::string::npos);
  } else {
    EXPECT_NE(log_capture.str().find(GaussianBlurFilterContents::kNoMipsError),
              std::string::npos);
  }
#endif
}

TEST_P(AiksTest, GaussianBlurMipMapImageFilter) {
  size_t blur_required_mip_count =
      GetParam() == PlaygroundBackend::kOpenGLES ? 1 : 4;
  fml::testing::LogCapture log_capture;
  Canvas canvas;
  canvas.SaveLayer(
      {.image_filter = ImageFilter::MakeBlur(Sigma(30), Sigma(30),
                                             FilterContents::BlurStyle::kNormal,
                                             Entity::TileMode::kClamp)});
  canvas.DrawCircle({200, 200}, 50, {.color = Color::Chartreuse()});

  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<RenderTargetCache> cache =
      std::make_shared<RenderTargetCache>(GetContext()->GetResourceAllocator());
  AiksContext aiks_context(GetContext(), nullptr, cache);
  picture.ToImage(aiks_context, {1024, 768});

  size_t max_mip_count = 0;
  for (auto it = cache->GetRenderTargetDataBegin();
       it != cache->GetRenderTargetDataEnd(); ++it) {
    max_mip_count = std::max(it->config.mip_count, max_mip_count);
  }
  EXPECT_EQ(max_mip_count, blur_required_mip_count);
  // The log is FML_DLOG, so only check in debug builds.
#ifndef NDEBUG
  if (GetParam() != PlaygroundBackend::kOpenGLES) {
    EXPECT_EQ(log_capture.str().find(GaussianBlurFilterContents::kNoMipsError),
              std::string::npos);
  } else {
    EXPECT_NE(log_capture.str().find(GaussianBlurFilterContents::kNoMipsError),
              std::string::npos);
  }
#endif
}

TEST_P(AiksTest, GaussianBlurMipMapSolidColor) {
  size_t blur_required_mip_count =
      GetParam() == PlaygroundBackend::kOpenGLES ? 1 : 4;
  fml::testing::LogCapture log_capture;
  Canvas canvas;
  canvas.DrawPath(PathBuilder{}
                      .MoveTo({100, 100})
                      .LineTo({200, 100})
                      .LineTo({150, 200})
                      .LineTo({50, 200})
                      .Close()
                      .TakePath(),
                  {.color = Color::Chartreuse(),
                   .image_filter = ImageFilter::MakeBlur(
                       Sigma(30), Sigma(30), FilterContents::BlurStyle::kNormal,
                       Entity::TileMode::kClamp)});

  Picture picture = canvas.EndRecordingAsPicture();
  std::shared_ptr<RenderTargetCache> cache =
      std::make_shared<RenderTargetCache>(GetContext()->GetResourceAllocator());
  AiksContext aiks_context(GetContext(), nullptr, cache);
  picture.ToImage(aiks_context, {1024, 768});

  size_t max_mip_count = 0;
  for (auto it = cache->GetRenderTargetDataBegin();
       it != cache->GetRenderTargetDataEnd(); ++it) {
    max_mip_count = std::max(it->config.mip_count, max_mip_count);
  }
  EXPECT_EQ(max_mip_count, blur_required_mip_count);
  // The log is FML_DLOG, so only check in debug builds.
#ifndef NDEBUG
  if (GetParam() != PlaygroundBackend::kOpenGLES) {
    EXPECT_EQ(log_capture.str().find(GaussianBlurFilterContents::kNoMipsError),
              std::string::npos);
  } else {
    EXPECT_NE(log_capture.str().find(GaussianBlurFilterContents::kNoMipsError),
              std::string::npos);
  }
#endif
}

TEST_P(AiksTest, MaskBlurDoesntStretchContents) {
  Scalar sigma = 70;
  auto callback = [&](AiksContext& renderer) -> std::optional<Picture> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Sigma", &sigma, 0, 500);
      ImGui::End();
    }
    Canvas canvas;
    canvas.Scale(GetContentScale());
    canvas.DrawPaint({.color = Color(0.1, 0.1, 0.1, 1.0)});

    std::shared_ptr<Texture> boston = CreateTextureForFixture("boston.jpg");
    ColorSource image_source = ColorSource::MakeImage(
        boston, Entity::TileMode::kRepeat, Entity::TileMode::kRepeat, {}, {});

    canvas.Transform(Matrix::MakeTranslation({100, 100, 0}) *
                     Matrix::MakeScale({0.5, 0.5, 1.0}));
    Paint paint = {
        .color_source = image_source,
        .mask_blur_descriptor =
            Paint::MaskBlurDescriptor{
                .style = FilterContents::BlurStyle::kNormal,
                .sigma = Sigma(sigma),
            },
    };
    canvas.DrawRect(
        Rect::MakeXYWH(0, 0, boston->GetSize().width, boston->GetSize().height),
        paint);

    return canvas.EndRecordingAsPicture();
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

}  // namespace testing
}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include "flutter/testing/testing.h"
#include "impeller/aiks/aiks_playground.h"
#include "impeller/aiks/canvas.h"
#include "impeller/aiks/image.h"
#include "impeller/geometry/geometry_unittests.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/text_render_context_skia.h"
#include "third_party/skia/include/core/SkData.h"

namespace impeller {
namespace testing {

using AiksTest = AiksPlayground;

TEST_F(AiksTest, CanvasCTMCanBeUpdated) {
  Canvas canvas;
  Matrix identity;
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransformation(), identity);
  canvas.Translate(Size{100, 100});
  ASSERT_MATRIX_NEAR(canvas.GetCurrentTransformation(),
                     Matrix::MakeTranslation({100.0, 100.0, 0.0}));
}

TEST_F(AiksTest, CanvasCanPushPopCTM) {
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

TEST_F(AiksTest, CanRenderColoredRect) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Red();
  canvas.DrawPath(PathBuilder{}
                      .AddRect(Rect::MakeXYWH(100.0, 100.0, 100.0, 100.0))
                      .TakePath(),
                  paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderImage) {
  Canvas canvas;
  Paint paint;
  auto image = std::make_shared<Image>(CreateTextureForFixture("kalimba.jpg"));
  paint.color = Color::Red();
  canvas.DrawImage(image, Point::MakeXY(100.0, 100.0), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderImageRect) {
  Canvas canvas;
  Paint paint;
  auto image = std::make_shared<Image>(CreateTextureForFixture("kalimba.jpg"));
  auto source_rect = IRect::MakeSize(image->GetSize());

  // Render the bottom right quarter of the source image in a stretched rect.
  source_rect.size.width /= 2;
  source_rect.size.height /= 2;
  source_rect.origin.x += source_rect.size.width;
  source_rect.origin.y += source_rect.size.height;
  canvas.DrawImageRect(image, source_rect, Rect::MakeXYWH(100, 100, 600, 600),
                       paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderStrokes) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Red();
  paint.stroke_width = 20.0;
  paint.style = Paint::Style::kStroke;
  canvas.DrawPath(PathBuilder{}.AddLine({200, 100}, {800, 100}).TakePath(),
                  paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderCurvedStrokes) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Red();
  paint.stroke_width = 25.0;
  paint.style = Paint::Style::kStroke;
  canvas.DrawPath(PathBuilder{}.AddCircle({500, 500}, 250).TakePath(), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderClips) {
  Canvas canvas;
  Paint paint;
  paint.color = Color::Fuchsia();
  canvas.ClipPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(0, 0, 500, 500)).TakePath());
  canvas.DrawPath(PathBuilder{}.AddCircle({500, 500}, 250).TakePath(), paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderNestedClips) {
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

TEST_F(AiksTest, ClipsUseCurrentTransform) {
  std::array<Color, 5> colors = {Color::White(), Color::Black(),
                                 Color::SkyBlue(), Color::Red(),
                                 Color::Yellow()};
  Canvas canvas;
  Paint paint;

  canvas.Translate(Vector3(300, 300));
  for (int i = 0; i < 15; i++) {
    canvas.Translate(-Vector3(300, 300));
    canvas.Scale(Vector3(0.8, 0.8));
    canvas.Translate(Vector3(300, 300));

    paint.color = colors[i % colors.size()];
    canvas.ClipPath(PathBuilder{}.AddCircle({0, 0}, 300).TakePath());
    canvas.DrawRect(Rect(-300, -300, 600, 600), paint);
  }
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanSaveLayerStandalone) {
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

TEST_F(AiksTest, CanRenderGroupOpacity) {
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

TEST_F(AiksTest, CanPerformFullScreenMSAA) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();

  canvas.DrawCircle({250, 250}, 125, red);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanPerformSkew) {
  Canvas canvas;

  Paint red;
  red.color = Color::Red();

  canvas.Skew(10, 125);
  canvas.DrawRect(Rect::MakeXYWH(0, 0, 100, 100), red);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanPerformSaveLayerWithBounds) {
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

TEST_F(AiksTest,
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

TEST_F(AiksTest, CanRenderRoundedRectWithNonUniformRadii) {
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

TEST_F(AiksTest, CanRenderDifferencePaths) {
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
  canvas.DrawPath(std::move(path), paint);

  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

static sk_sp<SkData> OpenFixtureAsSkData(const char* fixture_name) {
  auto mapping = flutter::testing::OpenFixtureAsMapping(fixture_name);
  if (!mapping) {
    return nullptr;
  }
  return SkData::MakeWithProc(
      mapping->GetMapping(), mapping->GetSize(),
      [](const void* ptr, void* context) {
        delete reinterpret_cast<fml::Mapping*>(context);
      },
      mapping.release());
}

bool RenderTextInCanvas(std::shared_ptr<Context> context,
                        Canvas& canvas,
                        const std::string& text,
                        const std::string& font_fixture,
                        Scalar font_size = 50.0) {
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
  TextRenderContextSkia text_context(context);
  if (!text_context.IsValid()) {
    return false;
  }
  auto atlas = text_context.CreateGlyphAtlas(frame);
  if (!atlas) {
    return false;
  }

  Paint text_paint;
  text_paint.color = Color::Yellow();
  canvas.DrawTextFrame(std::move(frame), std::move(atlas), text_position,
                       text_paint);
  return true;
}

TEST_F(AiksTest, CanRenderTextFrame) {
  Canvas canvas;
  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas, "the quick brown fox jumped over the lazy dog!.?",
      "Roboto-Regular.ttf"));
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderItalicizedText) {
  Canvas canvas;
  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas, "the quick brown fox jumped over the lazy dog!.?",
      "HomemadeApple.ttf"));
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanRenderEmojiTextFrame) {
  Canvas canvas;
  ASSERT_TRUE(RenderTextInCanvas(
      GetContext(), canvas,
      "😀 😃 😄 😁 😆 😅 😂 🤣 🥲 ☺️ 😊",
      "NotoColorEmoji.ttf"));
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, CanDrawPaint) {
  Paint paint;
  paint.color = Color::MediumTurquoise();
  Canvas canvas;
  canvas.DrawPaint(paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

TEST_F(AiksTest, PaintBlendModeIsRespected) {
  Paint paint;
  Canvas canvas;
  // Default is kSourceOver.
  paint.color = Color(1, 0, 0, 0.5);
  canvas.DrawCircle(Point(150, 200), 100, paint);
  paint.color = Color(0, 1, 0, 0.5);
  canvas.DrawCircle(Point(250, 200), 100, paint);

  paint.blend_mode = Entity::BlendMode::kPlus;
  paint.color = Color::Red();
  canvas.DrawCircle(Point(450, 250), 100, paint);
  paint.color = Color::Green();
  canvas.DrawCircle(Point(550, 250), 100, paint);
  paint.color = Color::Blue();
  canvas.DrawCircle(Point(500, 150), 100, paint);
  ASSERT_TRUE(OpenPlaygroundHere(canvas.EndRecordingAsPicture()));
}

}  // namespace testing
}  // namespace impeller

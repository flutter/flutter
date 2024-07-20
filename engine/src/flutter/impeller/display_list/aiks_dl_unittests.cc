
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/dl_sampling_options.h"
#include "display_list/dl_tile_mode.h"
#include "display_list/effects/dl_color_filter.h"
#include "display_list/effects/dl_color_source.h"
#include "display_list/effects/dl_image_filter.h"
#include "display_list/geometry/dl_geometry_types.h"
#include "display_list/image/dl_image.h"
#include "flutter/impeller/aiks/aiks_unittests.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/testing/testing.h"
#include "imgui.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/geometry/scalar.h"
#include "include/core/SkRSXform.h"
#include "include/core/SkRefCnt.h"

namespace impeller {
namespace testing {

using namespace flutter;

namespace {
SkRect GetCullRect(ISize window_size) {
  return SkRect::MakeSize(SkSize::Make(window_size.width, window_size.height));
}
}  // namespace

TEST_P(AiksTest, CollapsedDrawPaintInSubpass) {
  DisplayListBuilder builder;

  DlPaint paint;
  paint.setColor(DlColor::kYellow());
  paint.setBlendMode(DlBlendMode::kSrc);
  builder.DrawPaint(paint);

  DlPaint save_paint;
  save_paint.setBlendMode(DlBlendMode::kMultiply);
  builder.SaveLayer(nullptr, &save_paint);

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kCornflowerBlue().modulateOpacity(0.75f));
  builder.DrawPaint(draw_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CollapsedDrawPaintInSubpassBackdropFilter) {
  // Bug: https://github.com/flutter/flutter/issues/131576
  DisplayListBuilder builder;

  DlPaint paint;
  paint.setColor(DlColor::kYellow());
  paint.setBlendMode(DlBlendMode::kSrc);
  builder.DrawPaint(paint);

  auto filter = DlBlurImageFilter::Make(20.0, 20.0, DlTileMode::kDecal);
  builder.SaveLayer(nullptr, nullptr, filter.get());

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kCornflowerBlue());
  builder.DrawPaint(draw_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, ColorMatrixFilterSubpassCollapseOptimization) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  const float matrix[20] = {
      -1.0, 0,    0,    1.0, 0,  //
      0,    -1.0, 0,    1.0, 0,  //
      0,    0,    -1.0, 1.0, 0,  //
      1.0,  1.0,  1.0,  1.0, 0   //
  };
  auto filter = DlMatrixColorFilter::Make(matrix);

  DlPaint paint;
  paint.setColorFilter(filter);
  builder.SaveLayer(nullptr, &paint);

  builder.Translate(500, 300);
  builder.Rotate(120);  // 120 deg

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 100, 200, 200), draw_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, LinearToSrgbFilterSubpassCollapseOptimization) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColorFilter(DlLinearToSrgbGammaColorFilter::kInstance);
  builder.SaveLayer(nullptr, &paint);

  builder.Translate(500, 300);
  builder.Rotate(120);  // 120 deg.

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 100, 200, 200), draw_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, SrgbToLinearFilterSubpassCollapseOptimization) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColorFilter(DlLinearToSrgbGammaColorFilter::kInstance);
  builder.SaveLayer(nullptr, &paint);

  builder.Translate(500, 300);
  builder.Rotate(120);  // 120 deg

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 100, 200, 200), draw_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 100, 300, 300), paint);

  DlPaint save_paint;
  save_paint.setColor(DlColor::kBlack().withAlpha(128));
  builder.SaveLayer(nullptr, &save_paint);
  builder.DrawRect(SkRect::MakeXYWH(100, 500, 300, 300), paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerWithBlendColorFilterDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 100, 300, 300), paint);

  DlPaint save_paint;
  paint.setColor(DlColor::kBlack().withAlpha(128));
  paint.setColorFilter(
      DlBlendColorFilter::Make(DlColor::kRed(), DlBlendMode::kDstOver));
  builder.SaveLayer(nullptr, &paint);

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 500, 300, 300), draw_paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerWithBlendImageFilterDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 100, 300, 300), paint);

  DlPaint save_paint;
  save_paint.setColor(DlColor::kBlack().withAlpha(128));
  save_paint.setImageFilter(DlColorFilterImageFilter::Make(
      DlBlendColorFilter::Make(DlColor::kRed(), DlBlendMode::kDstOver)));

  builder.SaveLayer(nullptr, &save_paint);

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 500, 300, 300), draw_paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerWithColorAndImageFilterDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 100, 300, 300), paint);

  DlPaint save_paint;
  save_paint.setColor(DlColor::kBlack().withAlpha(128));
  save_paint.setColorFilter(
      DlBlendColorFilter::Make(DlColor::kRed(), DlBlendMode::kDstOver));
  builder.SaveLayer(nullptr, &save_paint);

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kBlue());
  builder.DrawRect(SkRect::MakeXYWH(100, 500, 300, 300), draw_paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, ImageFilteredUnboundedSaveLayerWithUnboundedContents) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));
  builder.Scale(GetContentScale().x, GetContentScale().y);

  DlPaint save_paint;
  save_paint.setImageFilter(
      DlBlurImageFilter::Make(10.0, 10.0, DlTileMode::kDecal));
  builder.SaveLayer(nullptr, &save_paint);

  {
    // DrawPaint to verify correct behavior when the contents are unbounded.
    DlPaint draw_paint;
    draw_paint.setColor(DlColor::kYellow());
    builder.DrawPaint(draw_paint);

    // Contrasting rectangle to see interior blurring
    DlPaint draw_rect;
    draw_rect.setColor(DlColor::kBlue());
    builder.DrawRect(SkRect::MakeLTRB(125, 125, 175, 175), draw_rect);
  }
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerImageDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  auto image = DlImageImpeller::Make(CreateTextureForFixture("airplane.jpg"));
  builder.DrawImage(image, {100, 100}, DlImageSampling::kMipmapLinear);

  DlPaint paint;
  paint.setColor(DlColor::kBlack().withAlpha(128));
  builder.SaveLayer(nullptr, &paint);
  builder.DrawImage(image, {100, 500}, DlImageSampling::kMipmapLinear);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerWithColorMatrixColorFilterDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  auto image = DlImageImpeller::Make(CreateTextureForFixture("airplane.jpg"));
  builder.DrawImage(image, {100, 100}, {});

  const float matrix[20] = {
      1, 0, 0, 0, 0,  //
      0, 1, 0, 0, 0,  //
      0, 0, 1, 0, 0,  //
      0, 0, 0, 2, 0   //
  };
  DlPaint paint;
  paint.setColor(DlColor::kBlack().withAlpha(128));
  paint.setColorFilter(DlMatrixColorFilter::Make(matrix));
  builder.SaveLayer(nullptr, &paint);
  builder.DrawImage(image, {100, 500}, {});
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerWithColorMatrixImageFilterDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  auto image = DlImageImpeller::Make(CreateTextureForFixture("airplane.jpg"));
  builder.DrawImage(image, {100, 100}, {});

  const float matrix[20] = {
      1, 0, 0, 0, 0,  //
      0, 1, 0, 0, 0,  //
      0, 0, 1, 0, 0,  //
      0, 0, 0, 2, 0   //
  };
  DlPaint paint;
  paint.setColor(DlColor::kBlack().withAlpha(128));
  paint.setColorFilter(DlMatrixColorFilter::Make(matrix));
  builder.SaveLayer(nullptr, &paint);
  builder.DrawImage(image, {100, 500}, {});
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest,
       TranslucentSaveLayerWithColorFilterAndImageFilterDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  auto image = DlImageImpeller::Make(CreateTextureForFixture("airplane.jpg"));
  builder.DrawImage(image, {100, 100}, {});

  const float matrix[20] = {
      1, 0,   0, 0,   0,  //
      0, 1,   0, 0,   0,  //
      0, 0.2, 1, 0,   0,  //
      0, 0,   0, 0.5, 0   //
  };
  DlPaint paint;
  paint.setColor(DlColor::kBlack().withAlpha(128));
  paint.setImageFilter(
      DlColorFilterImageFilter::Make(DlMatrixColorFilter::Make(matrix)));
  paint.setColorFilter(
      DlBlendColorFilter::Make(DlColor::kGreen(), DlBlendMode::kModulate));
  builder.SaveLayer(nullptr, &paint);
  builder.DrawImage(image, {100, 500}, {});
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, TranslucentSaveLayerWithAdvancedBlendModeDrawsCorrectly) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  builder.DrawRect(SkRect::MakeXYWH(0, 0, 400, 400), paint);

  DlPaint save_paint;
  save_paint.setAlpha(128);
  save_paint.setBlendMode(DlBlendMode::kLighten);
  builder.SaveLayer(nullptr, &save_paint);

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kGreen());
  builder.DrawCircle({200, 200}, 100, draw_paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

/// This is a regression check for https://github.com/flutter/engine/pull/41129
/// The entire screen is green if successful. If failing, no frames will render,
/// or the entire screen will be transparent black.
TEST_P(AiksTest, CanRenderTinyOverlappingSubpasses) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  builder.DrawPaint(paint);

  // Draw two overlapping subpixel circles.
  builder.SaveLayer({});

  DlPaint yellow_paint;
  yellow_paint.setColor(DlColor::kYellow());
  builder.DrawCircle({100, 100}, 0.1, yellow_paint);
  builder.Restore();
  builder.SaveLayer({});
  builder.DrawCircle({100, 100}, 0.1, yellow_paint);
  builder.Restore();

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kGreen());
  builder.DrawPaint(draw_paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderDestructiveSaveLayer) {
  DisplayListBuilder builder(GetCullRect(GetWindowSize()));

  DlPaint paint;
  paint.setColor(DlColor::kRed());
  builder.DrawPaint(paint);
  // Draw an empty savelayer with a destructive blend mode, which will replace
  // the entire red screen with fully transparent black, except for the green
  // circle drawn within the layer.

  DlPaint save_paint;
  save_paint.setBlendMode(DlBlendMode::kSrc);
  builder.SaveLayer(nullptr, &save_paint);

  DlPaint draw_paint;
  draw_paint.setColor(DlColor::kGreen());
  builder.DrawCircle({300, 300}, 100, draw_paint);
  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanDrawPoints) {
  std::vector<SkPoint> points = {
      {0, 0},      //
      {100, 100},  //
      {100, 0},    //
      {0, 100},    //
      {0, 0},      //
      {48, 48},    //
      {52, 52},    //
  };
  DlPaint paint_round;
  paint_round.setColor(DlColor::kYellow().withAlpha(128));
  paint_round.setStrokeCap(DlStrokeCap::kRound);
  paint_round.setStrokeWidth(20);

  DlPaint paint_square;
  paint_square.setColor(DlColor::kYellow().withAlpha(128));
  paint_square.setStrokeCap(DlStrokeCap::kSquare);
  paint_square.setStrokeWidth(20);

  DlPaint background;
  background.setColor(DlColor::kBlack());

  DisplayListBuilder builder(GetCullRect(GetWindowSize()));
  builder.DrawPaint(background);
  builder.Translate(200, 200);

  builder.DrawPoints(DlCanvas::PointMode::kPoints, points.size(), points.data(),
                     paint_round);
  builder.Translate(150, 0);
  builder.DrawPoints(DlCanvas::PointMode::kPoints, points.size(), points.data(),
                     paint_square);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanDrawPointsWithTextureMap) {
  auto texture = DlImageImpeller::Make(
      CreateTextureForFixture("table_mountain_nx.png",
                              /*enable_mipmapping=*/true));

  std::vector<SkPoint> points = {
      {0, 0},      //
      {100, 100},  //
      {100, 0},    //
      {0, 100},    //
      {0, 0},      //
      {48, 48},    //
      {52, 52},    //
  };

  auto image_src = std::make_shared<DlImageColorSource>(
      texture, DlTileMode::kClamp, DlTileMode::kClamp);

  DlPaint paint_round;
  paint_round.setStrokeCap(DlStrokeCap::kRound);
  paint_round.setColorSource(image_src);
  paint_round.setStrokeWidth(200);

  DlPaint paint_square;
  paint_square.setStrokeCap(DlStrokeCap::kSquare);
  paint_square.setColorSource(image_src);
  paint_square.setStrokeWidth(200);

  DisplayListBuilder builder(GetCullRect(GetWindowSize()));
  builder.Translate(200, 200);

  builder.DrawPoints(DlCanvas::PointMode::kPoints, points.size(), points.data(),
                     paint_round);
  builder.Translate(150, 0);
  builder.DrawPoints(DlCanvas::PointMode::kPoints, points.size(), points.data(),
                     paint_square);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller

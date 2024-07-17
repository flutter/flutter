// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/aiks_unittests.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/geometry/scalar.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {

using namespace flutter;

TEST_P(AiksTest, CanRenderColoredRect) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kBlue());
  SkPath path = SkPath();
  path.addRect(SkRect::MakeXYWH(100.0, 100.0, 100.0, 100.0));
  builder.DrawPath(path, paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderImage) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));
  builder.DrawImage(image, SkPoint::Make(100.0, 100.0),
                    DlImageSampling::kNearestNeighbor, &paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderInvertedImageWithColorFilter) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setColorFilter(
      DlBlendColorFilter::Make(DlColor::kYellow(), DlBlendMode::kSrcOver));
  paint.setInvertColors(true);
  auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));

  builder.DrawImage(image, SkPoint::Make(100.0, 100.0),
                    DlImageSampling::kNearestNeighbor, &paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderColorFilterWithInvertColors) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setColorFilter(
      DlBlendColorFilter::Make(DlColor::kYellow(), DlBlendMode::kSrcOver));
  paint.setInvertColors(true);

  builder.DrawRect(SkRect::MakeLTRB(0, 0, 100, 100), paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderColorFilterWithInvertColorsDrawPaint) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());
  paint.setColorFilter(
      DlBlendColorFilter::Make(DlColor::kYellow(), DlBlendMode::kSrcOver));
  paint.setInvertColors(true);

  builder.DrawPaint(paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

namespace {
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
  return context->GetCommandQueue()->Submit({buffer}).ok();
}

void CanRenderTiledTexture(AiksTest* aiks_test,
                           DlTileMode tile_mode,
                           Matrix local_matrix = {}) {
  auto context = aiks_test->GetContext();
  ASSERT_TRUE(context);
  auto texture = aiks_test->CreateTextureForFixture("table_mountain_nx.png",
                                                    /*enable_mipmapping=*/true);
  GenerateMipmap(context, texture, "table_mountain_nx");
  auto image = DlImageImpeller::Make(texture);
  SkMatrix sk_local_matrix = ToSkMatrix(local_matrix);
  DlImageColorSource color_source(image, tile_mode, tile_mode,
                                  DlImageSampling::kNearestNeighbor,
                                  &sk_local_matrix);

  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kWhite());
  paint.setColorSource(&color_source);

  builder.Scale(aiks_test->GetContentScale().x, aiks_test->GetContentScale().y);
  builder.Translate(100.0f, 100.0f);
  builder.DrawRect(SkRect::MakeXYWH(0, 0, 600, 600), paint);

  // Should not change the image.
  constexpr auto stroke_width = 64;
  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(stroke_width);
  if (tile_mode == DlTileMode::kDecal) {
    builder.DrawRect(SkRect::MakeXYWH(stroke_width, stroke_width, 600, 600),
                     paint);
  } else {
    builder.DrawRect(SkRect::MakeXYWH(0, 0, 600, 600), paint);
  }

  {
    // Should not change the image.
    SkPath path;
    path.addCircle(150, 150, 150);
    path.addRoundRect(SkRect::MakeLTRB(300, 300, 600, 600), 10, 10);

    // Make sure path cannot be simplified...
    EXPECT_FALSE(path.isRect(nullptr));
    EXPECT_FALSE(path.isOval(nullptr));
    EXPECT_FALSE(path.isRRect(nullptr));

    // Make sure path will not trigger the optimal convex code
    EXPECT_FALSE(path.isConvex());

    paint.setDrawStyle(DlDrawStyle::kFill);
    builder.DrawPath(path, paint);
  }

  {
    // Should not change the image. Tests the Convex short-cut code.
    SkPath circle;
    circle.addCircle(150, 450, 150);

    // Unfortunately, the circle path can be simplified...
    EXPECT_TRUE(circle.isOval(nullptr));
    // At least it's convex, though...
    EXPECT_TRUE(circle.isConvex());

    // Let's make a copy that doesn't remember that it's just a circle...
    SkPath path;
    // This moveTo confuses addPath into appending rather than replacing,
    // which prevents it from noticing that it's just a circle...
    path.moveTo(10, 10);
    path.addPath(circle);

    // Make sure path cannot be simplified...
    EXPECT_FALSE(path.isRect(nullptr));
    EXPECT_FALSE(path.isOval(nullptr));
    EXPECT_FALSE(path.isRRect(nullptr));

    // But check that we will trigger the optimal convex code
    EXPECT_TRUE(path.isConvex());

    paint.setDrawStyle(DlDrawStyle::kFill);
    builder.DrawPath(path, paint);
  }

  ASSERT_TRUE(aiks_test->OpenPlaygroundHere(builder.Build()));
}
}  // namespace

TEST_P(AiksTest, CanRenderTiledTextureClamp) {
  CanRenderTiledTexture(this, DlTileMode::kClamp);
}

TEST_P(AiksTest, CanRenderTiledTextureRepeat) {
  CanRenderTiledTexture(this, DlTileMode::kRepeat);
}

TEST_P(AiksTest, CanRenderTiledTextureMirror) {
  CanRenderTiledTexture(this, DlTileMode::kMirror);
}

TEST_P(AiksTest, CanRenderTiledTextureDecal) {
  CanRenderTiledTexture(this, DlTileMode::kDecal);
}

TEST_P(AiksTest, CanRenderTiledTextureClampWithTranslate) {
  CanRenderTiledTexture(this, DlTileMode::kClamp,
                        Matrix::MakeTranslation({172.f, 172.f, 0.f}));
}

TEST_P(AiksTest, CanRenderImageRect) {
  DisplayListBuilder builder;
  auto image = DlImageImpeller::Make(CreateTextureForFixture("kalimba.jpg"));

  SkSize image_half_size = SkSize::Make(image->dimensions().fWidth * 0.5f,
                                        image->dimensions().fHeight * 0.5f);

  // Render the bottom right quarter of the source image in a stretched rect.
  auto source_rect = SkRect::MakeSize(image_half_size);
  source_rect =
      source_rect.makeOffset(image_half_size.fWidth, image_half_size.fHeight);

  builder.DrawImageRect(image, source_rect,
                        SkRect::MakeXYWH(100, 100, 600, 600),
                        DlImageSampling::kNearestNeighbor);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderSimpleClips) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  DlPaint paint;

  paint.setColor(DlColor::kWhite());
  builder.DrawPaint(paint);

  auto draw = [&builder](const DlPaint& paint, Scalar x, Scalar y) {
    builder.Save();
    builder.Translate(x, y);
    {
      builder.Save();
      builder.ClipRect(SkRect::MakeLTRB(50, 50, 150, 150));
      builder.DrawPaint(paint);
      builder.Restore();
    }
    {
      builder.Save();
      builder.ClipOval(SkRect::MakeLTRB(200, 50, 300, 150));
      builder.DrawPaint(paint);
      builder.Restore();
    }
    {
      builder.Save();
      builder.ClipRRect(
          SkRRect::MakeRectXY(SkRect::MakeLTRB(50, 200, 150, 300), 20, 20));
      builder.DrawPaint(paint);
      builder.Restore();
    }
    {
      builder.Save();
      builder.ClipRRect(
          SkRRect::MakeRectXY(SkRect::MakeLTRB(200, 230, 300, 270), 20, 20));
      builder.DrawPaint(paint);
      builder.Restore();
    }
    {
      builder.Save();
      builder.ClipRRect(
          SkRRect::MakeRectXY(SkRect::MakeLTRB(230, 200, 270, 300), 20, 20));
      builder.DrawPaint(paint);
      builder.Restore();
    }
    builder.Restore();
  };

  paint.setColor(DlColor::kBlue());
  draw(paint, 0, 0);

  DlColor gradient_colors[7] = {
      DlColor::RGBA(0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0),
      DlColor::RGBA(0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0),
  };
  Scalar stops[7] = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);
  auto image = DlImageImpeller::Make(texture);

  paint.setColorSource(DlColorSource::MakeRadial(
      {500, 600}, 75, 7, gradient_colors, stops, DlTileMode::kMirror));
  draw(paint, 0, 300);

  DlImageColorSource image_source(image, DlTileMode::kRepeat,
                                  DlTileMode::kRepeat,
                                  DlImageSampling::kNearestNeighbor);
  paint.setColorSource(&image_source);
  draw(paint, 300, 0);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanSaveLayerStandalone) {
  DisplayListBuilder builder;

  DlPaint red;
  red.setColor(DlColor::kRed());

  DlPaint alpha;
  alpha.setColor(DlColor::kRed().modulateOpacity(0.5));

  builder.SaveLayer(nullptr, &alpha);

  builder.DrawCircle({125, 125}, 125, red);

  builder.Restore();

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderDifferentShapesWithSameColorSource) {
  DisplayListBuilder builder;
  DlPaint paint;

  DlColor colors[2] = {
      DlColor::RGBA(0.9568, 0.2627, 0.2118, 1.0),
      DlColor::RGBA(0.1294, 0.5882, 0.9529, 1.0),
  };
  DlScalar stops[2] = {
      0.0,
      1.0,
  };

  paint.setColorSource(DlColorSource::MakeLinear({0, 0}, {100, 100}, 2, colors,
                                                 stops, DlTileMode::kRepeat));

  builder.Save();
  builder.Translate(100, 100);
  builder.DrawRect(SkRect::MakeXYWH(0, 0, 200, 200), paint);
  builder.Restore();

  builder.Save();
  builder.Translate(100, 400);
  builder.DrawCircle({100, 100}, 100, paint);
  builder.Restore();
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanRenderRoundedRectWithNonUniformRadii) {
  DisplayListBuilder builder;
  DlPaint paint;
  paint.setColor(DlColor::kRed());

  SkRRect rrect;
  SkVector radii[4] = {
      SkVector{50, 25},
      SkVector{25, 50},
      SkVector{50, 25},
      SkVector{25, 50},
  };
  rrect.setRectRadii(SkRect::MakeXYWH(100, 100, 500, 500), radii);

  builder.DrawRRect(rrect, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanDrawPaint) {
  auto medium_turquoise =
      DlColor::RGBA(72.0f / 255.0f, 209.0f / 255.0f, 204.0f / 255.0f, 1.0f);

  DisplayListBuilder builder;
  builder.Scale(0.2, 0.2);
  builder.DrawPaint(DlPaint().setColor(medium_turquoise));
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, CanDrawPaintMultipleTimes) {
  auto medium_turquoise =
      DlColor::RGBA(72.0f / 255.0f, 209.0f / 255.0f, 204.0f / 255.0f, 1.0f);
  auto orange_red =
      DlColor::RGBA(255.0f / 255.0f, 69.0f / 255.0f, 0.0f / 255.0f, 1.0f);

  DisplayListBuilder builder;
  builder.Scale(0.2, 0.2);
  builder.DrawPaint(DlPaint().setColor(medium_turquoise));
  builder.DrawPaint(DlPaint().setColor(orange_red.modulateOpacity(0.5f)));
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, FilledCirclesRenderCorrectly) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  DlPaint paint;
  const int color_count = 3;
  DlColor colors[color_count] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::RGBA(220.0f / 255.0f, 20.0f / 255.0f, 60.0f / 255.0f, 1.0f),
  };

  paint.setColor(DlColor::kWhite());
  builder.DrawPaint(paint);

  int c_index = 0;
  int radius = 600;
  while (radius > 0) {
    paint.setColor(colors[(c_index++) % color_count]);
    builder.DrawCircle({10, 10}, radius, paint);
    if (radius > 30) {
      radius -= 10;
    } else {
      radius -= 2;
    }
  }

  DlColor gradient_colors[7] = {
      DlColor::RGBA(0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0),
      DlColor::RGBA(0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0),
  };
  DlScalar stops[7] = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);
  auto image = DlImageImpeller::Make(texture);

  paint.setColorSource(DlColorSource::MakeRadial(
      {500, 600}, 75, 7, gradient_colors, stops, DlTileMode::kMirror));
  builder.DrawCircle({500, 600}, 100, paint);

  SkMatrix local_matrix = SkMatrix::Translate(700, 200);
  DlImageColorSource image_source(
      image, DlTileMode::kRepeat, DlTileMode::kRepeat,
      DlImageSampling::kNearestNeighbor, &local_matrix);
  paint.setColorSource(&image_source);
  builder.DrawCircle({800, 300}, 100, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, StrokedCirclesRenderCorrectly) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  DlPaint paint;
  const int color_count = 3;
  DlColor colors[color_count] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::RGBA(220.0f / 255.0f, 20.0f / 255.0f, 60.0f / 255.0f, 1.0f),
  };

  paint.setColor(DlColor::kWhite());
  builder.DrawPaint(paint);

  int c_index = 0;

  auto draw = [&paint, &colors, &c_index](DlCanvas& canvas, SkPoint center,
                                          Scalar r, Scalar dr, int n) {
    for (int i = 0; i < n; i++) {
      paint.setColor(colors[(c_index++) % color_count]);
      canvas.DrawCircle(center, r, paint);
      r += dr;
    }
  };

  paint.setDrawStyle(DlDrawStyle::kStroke);
  paint.setStrokeWidth(1);
  draw(builder, {10, 10}, 2, 2, 14);  // r = [2, 28], covers [1,29]
  paint.setStrokeWidth(5);
  draw(builder, {10, 10}, 35, 10, 56);  // r = [35, 585], covers [30,590]

  DlColor gradient_colors[7] = {
      DlColor::RGBA(0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0),
      DlColor::RGBA(0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0),
  };
  DlScalar stops[7] = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);
  auto image = DlImageImpeller::Make(texture);

  paint.setColorSource(DlColorSource::MakeRadial(
      {500, 600}, 75, 7, gradient_colors, stops, DlTileMode::kMirror));
  draw(builder, {500, 600}, 5, 10, 10);

  SkMatrix local_matrix = SkMatrix::Translate(700, 200);
  DlImageColorSource image_source(
      image, DlTileMode::kRepeat, DlTileMode::kRepeat,
      DlImageSampling::kNearestNeighbor, &local_matrix);
  paint.setColorSource(&image_source);
  draw(builder, {800, 300}, 5, 10, 10);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, FilledEllipsesRenderCorrectly) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  DlPaint paint;
  const int color_count = 3;
  DlColor colors[color_count] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::RGBA(220.0f / 255.0f, 20.0f / 255.0f, 60.0f / 255.0f, 1.0f),
  };

  paint.setColor(DlColor::kWhite());
  builder.DrawPaint(paint);

  int c_index = 0;
  int long_radius = 600;
  int short_radius = 600;
  while (long_radius > 0 && short_radius > 0) {
    paint.setColor(colors[(c_index++) % color_count]);
    builder.DrawOval(SkRect::MakeXYWH(10 - long_radius, 10 - short_radius,
                                      long_radius * 2, short_radius * 2),
                     paint);
    builder.DrawOval(SkRect::MakeXYWH(1000 - short_radius, 750 - long_radius,
                                      short_radius * 2, long_radius * 2),
                     paint);
    if (short_radius > 30) {
      short_radius -= 10;
      long_radius -= 5;
    } else {
      short_radius -= 2;
      long_radius -= 1;
    }
  }

  DlColor gradient_colors[7] = {
      DlColor::RGBA(0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0),
      DlColor::RGBA(0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0),
  };
  DlScalar stops[7] = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);
  auto image = DlImageImpeller::Make(texture);

  paint.setColor(DlColor::kWhite().modulateOpacity(0.5));

  paint.setColorSource(DlColorSource::MakeRadial(
      {300, 650}, 75, 7, gradient_colors, stops, DlTileMode::kMirror));
  builder.DrawOval(SkRect::MakeXYWH(200, 625, 200, 50), paint);
  builder.DrawOval(SkRect::MakeXYWH(275, 550, 50, 200), paint);

  SkMatrix local_matrix = SkMatrix::Translate(610, 15);
  DlImageColorSource image_source(
      image, DlTileMode::kRepeat, DlTileMode::kRepeat,
      DlImageSampling::kNearestNeighbor, &local_matrix);
  paint.setColorSource(&image_source);
  builder.DrawOval(SkRect::MakeXYWH(610, 90, 200, 50), paint);
  builder.DrawOval(SkRect::MakeXYWH(685, 15, 50, 200), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, FilledRoundRectsRenderCorrectly) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  DlPaint paint;
  const int color_count = 3;
  DlColor colors[color_count] = {
      DlColor::kBlue(),
      DlColor::kGreen(),
      DlColor::RGBA(220.0f / 255.0f, 20.0f / 255.0f, 60.0f / 255.0f, 1.0f),
  };

  paint.setColor(DlColor::kWhite());
  builder.DrawPaint(paint);

  int c_index = 0;
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      paint.setColor(colors[(c_index++) % color_count]);
      builder.DrawRRect(
          SkRRect::MakeRectXY(
              SkRect::MakeXYWH(i * 100 + 10, j * 100 + 20, 80, 80),  //
              i * 5 + 10, j * 5 + 10),
          paint);
    }
  }
  paint.setColor(colors[(c_index++) % color_count]);
  builder.DrawRRect(
      SkRRect::MakeRectXY(SkRect::MakeXYWH(10, 420, 380, 80), 40, 40), paint);
  paint.setColor(colors[(c_index++) % color_count]);
  builder.DrawRRect(
      SkRRect::MakeRectXY(SkRect::MakeXYWH(410, 20, 80, 380), 40, 40), paint);

  DlColor gradient_colors[7] = {
      DlColor::RGBA(0x1f / 255.0, 0.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0x5b / 255.0, 0.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0x87 / 255.0, 0x01 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xac / 255.0, 0x25 / 255.0, 0x53 / 255.0, 1.0),
      DlColor::RGBA(0xe1 / 255.0, 0x6b / 255.0, 0x5c / 255.0, 1.0),
      DlColor::RGBA(0xf3 / 255.0, 0x90 / 255.0, 0x60 / 255.0, 1.0),
      DlColor::RGBA(0xff / 255.0, 0xb5 / 255.0, 0x6b / 250.0, 1.0),
  };
  DlScalar stops[7] = {
      0.0,
      (1.0 / 6.0) * 1,
      (1.0 / 6.0) * 2,
      (1.0 / 6.0) * 3,
      (1.0 / 6.0) * 4,
      (1.0 / 6.0) * 5,
      1.0,
  };
  auto texture = CreateTextureForFixture("airplane.jpg",
                                         /*enable_mipmapping=*/true);
  auto image = DlImageImpeller::Make(texture);

  paint.setColor(DlColor::kWhite().modulateOpacity(0.1));
  paint.setColorSource(DlColorSource::MakeRadial(
      {550, 550}, 75, 7, gradient_colors, stops, DlTileMode::kMirror));
  for (int i = 1; i <= 10; i++) {
    int j = 11 - i;
    builder.DrawRRect(
        SkRRect::MakeRectXY(SkRect::MakeLTRB(550 - i * 20, 550 - j * 20,  //
                                             550 + i * 20, 550 + j * 20),
                            i * 10, j * 10),
        paint);
  }

  paint.setColor(DlColor::kWhite().modulateOpacity(0.5));
  paint.setColorSource(DlColorSource::MakeRadial(
      {200, 650}, 75, 7, gradient_colors, stops, DlTileMode::kMirror));
  paint.setColor(DlColor::kWhite().modulateOpacity(0.5));
  builder.DrawRRect(
      SkRRect::MakeRectXY(SkRect::MakeLTRB(100, 610, 300, 690), 40, 40), paint);
  builder.DrawRRect(
      SkRRect::MakeRectXY(SkRect::MakeLTRB(160, 550, 240, 750), 40, 40), paint);

  paint.setColor(DlColor::kWhite().modulateOpacity(0.1));
  SkMatrix local_matrix = SkMatrix::Translate(520, 20);
  DlImageColorSource image_source(
      image, DlTileMode::kRepeat, DlTileMode::kRepeat,
      DlImageSampling::kNearestNeighbor, &local_matrix);
  paint.setColorSource(&image_source);
  for (int i = 1; i <= 10; i++) {
    int j = 11 - i;
    builder.DrawRRect(
        SkRRect::MakeRectXY(SkRect::MakeLTRB(720 - i * 20, 220 - j * 20,  //
                                             720 + i * 20, 220 + j * 20),
                            i * 10, j * 10),
        paint);
  }

  paint.setColor(DlColor::kWhite().modulateOpacity(0.5));
  local_matrix = SkMatrix::Translate(800, 300);
  DlImageColorSource image_source2(
      image, DlTileMode::kRepeat, DlTileMode::kRepeat,
      DlImageSampling::kNearestNeighbor, &local_matrix);
  paint.setColorSource(&image_source2);
  builder.DrawRRect(
      SkRRect::MakeRectXY(SkRect::MakeLTRB(800, 410, 1000, 490), 40, 40),
      paint);
  builder.DrawRRect(
      SkRRect::MakeRectXY(SkRect::MakeLTRB(860, 350, 940, 550), 40, 40), paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, SolidColorCirclesOvalsRRectsMaskBlurCorrectly) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  DlPaint paint;
  paint.setMaskFilter(DlBlurMaskFilter::Make(DlBlurStyle::kNormal, 1.0f));

  builder.DrawPaint(DlPaint().setColor(DlColor::kWhite()));

  paint.setColor(
      DlColor::RGBA(220.0f / 255.0f, 20.0f / 255.0f, 60.0f / 255.0f, 1.0f));
  Scalar y = 100.0f;
  for (int i = 0; i < 5; i++) {
    Scalar x = (i + 1) * 100;
    Scalar radius = x / 10.0f;
    builder.DrawRect(SkRect::MakeXYWH(x + 25 - radius / 2, y + radius / 2,  //
                                      radius, 60.0f - radius),
                     paint);
  }

  paint.setColor(DlColor::kBlue());
  y += 100.0f;
  for (int i = 0; i < 5; i++) {
    Scalar x = (i + 1) * 100;
    Scalar radius = x / 10.0f;
    builder.DrawCircle({x + 25, y + 25}, radius, paint);
  }

  paint.setColor(DlColor::kGreen());
  y += 100.0f;
  for (int i = 0; i < 5; i++) {
    Scalar x = (i + 1) * 100;
    Scalar radius = x / 10.0f;
    builder.DrawOval(SkRect::MakeXYWH(x + 25 - radius / 2, y + radius / 2,  //
                                      radius, 60.0f - radius),
                     paint);
  }

  paint.setColor(
      DlColor::RGBA(128.0f / 255.0f, 0.0f / 255.0f, 128.0f / 255.0f, 1.0f));
  y += 100.0f;
  for (int i = 0; i < 5; i++) {
    Scalar x = (i + 1) * 100;
    Scalar radius = x / 20.0f;
    builder.DrawRRect(SkRRect::MakeRectXY(SkRect::MakeXYWH(x, y, 60.0f, 60.0f),
                                          radius, radius),
                      paint);
  }

  paint.setColor(
      DlColor::RGBA(255.0f / 255.0f, 165.0f / 255.0f, 0.0f / 255.0f, 1.0f));
  y += 100.0f;
  for (int i = 0; i < 5; i++) {
    Scalar x = (i + 1) * 100;
    Scalar radius = x / 20.0f;
    builder.DrawRRect(
        SkRRect::MakeRectXY(SkRect::MakeXYWH(x, y, 60.0f, 60.0f), radius, 5.0f),
        paint);
  }

  auto dl = builder.Build();
  ASSERT_TRUE(OpenPlaygroundHere(dl));
}

}  // namespace testing
}  // namespace impeller

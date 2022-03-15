// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_attributes_testing.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_color_source.h"
#include "flutter/display_list/types.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

static sk_sp<SkImage> MakeTestImage(int w, int h, SkColor color) {
  sk_sp<SkSurface> surface;
  if (SkColorGetA(color) < 255) {
    surface = SkSurface::MakeRasterN32Premul(w, h);
  } else {
    SkImageInfo info =
        SkImageInfo::MakeN32(w, h, SkAlphaType::kOpaque_SkAlphaType);
    surface = SkSurface::MakeRaster(info);
  }
  SkCanvas* canvas = surface->getCanvas();
  canvas->drawColor(color);
  return surface->makeImageSnapshot();
}

static const sk_sp<SkImage> TestImage1 = MakeTestImage(10, 10, SK_ColorGREEN);
static const sk_sp<SkImage> TestAlphaImage1 =
    MakeTestImage(10, 10, SK_ColorTRANSPARENT);
// clang-format off
static const SkMatrix TestMatrix1 =
    SkMatrix::MakeAll(2, 0, 10,
                      0, 3, 12,
                      0, 0, 1);
static const SkMatrix TestMatrix2 =
    SkMatrix::MakeAll(4, 0, 15,
                      0, 7, 17,
                      0, 0, 1);
// clang-format on
static constexpr int kTestStopCount = 3;
static constexpr SkColor TestColors[kTestStopCount] = {
    SK_ColorRED,
    SK_ColorGREEN,
    SK_ColorBLUE,
};
static constexpr SkColor TestAlphaColors[kTestStopCount] = {
    SkColorSetA(SK_ColorBLUE, 0x7f),
    SkColorSetA(SK_ColorRED, 0x2f),
    SkColorSetA(SK_ColorGREEN, 0xcf),
};
static constexpr float TestStops[kTestStopCount] = {
    0.0f,
    0.7f,
    1.0f,
};
static constexpr float TestStops2[kTestStopCount] = {
    0.0f,
    0.3f,
    1.0f,
};
static constexpr SkPoint TestPoints[2] = {
    SkPoint::Make(5, 15),
    SkPoint::Make(7, 18),
};
static constexpr SkPoint TestPoints2[2] = {
    SkPoint::Make(100, 115),
    SkPoint::Make(107, 118),
};
static const sk_sp<SkShader> shaderA = SkShaders::Color(SK_ColorRED);
static const sk_sp<SkShader> shaderB = SkShaders::Color(SK_ColorBLUE);
static const sk_sp<SkShader> TestUnknownShader =
    SkShaders::Blend(SkBlendMode::kOverlay, shaderA, shaderB);
static const sk_sp<SkShader> TestAlphaUnknownShader =
    SkShaders::Blend(SkBlendMode::kDstOut, shaderA, shaderB);

TEST(DisplayListColorSource, BuilderSetGet) {
  DlImageColorSource source(TestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DisplayList::LinearSampling, &TestMatrix1);
  DisplayListBuilder builder;
  ASSERT_EQ(builder.getColorSource(), nullptr);
  builder.setColorSource(&source);
  ASSERT_NE(builder.getColorSource(), nullptr);
  ASSERT_TRUE(
      Equals(builder.getColorSource(), static_cast<DlColorSource*>(&source)));
  builder.setColorSource(nullptr);
  ASSERT_EQ(builder.getColorSource(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaNullShader) {
  std::shared_ptr<DlColorSource> source = DlColorSource::From(nullptr);
  ASSERT_EQ(source, nullptr);
  ASSERT_EQ(source.get(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaColorShader) {
  sk_sp<SkShader> shader = SkShaders::Color(SK_ColorBLUE);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  DlColorColorSource dl_source(SK_ColorBLUE);
  ASSERT_EQ(source->type(), DlColorSourceType::kColor);
  ASSERT_EQ(*source->asColor(), dl_source);
  ASSERT_EQ(source->asColor()->color(), SK_ColorBLUE);

  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaImageShader) {
  sk_sp<SkShader> shader =
      TestImage1->makeShader(DisplayList::LinearSampling, &TestMatrix1);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  DlImageColorSource dl_source(TestImage1, DlTileMode::kClamp,
                               DlTileMode::kClamp, DisplayList::LinearSampling,
                               &TestMatrix1);
  ASSERT_EQ(source->type(), DlColorSourceType::kImage);
  ASSERT_EQ(*source->asImage(), dl_source);
  ASSERT_EQ(source->asImage()->image(), TestImage1);
  ASSERT_EQ(source->asImage()->matrix(), TestMatrix1);
  ASSERT_EQ(source->asImage()->horizontal_tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asImage()->vertical_tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asImage()->sampling(), DisplayList::LinearSampling);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaLinearGradient) {
  // We can read back all of the parameters of a Linear gradient
  // except for matrix.
  sk_sp<SkShader> shader = SkGradientShader::MakeLinear(
      TestPoints, TestColors, TestStops, kTestStopCount, SkTileMode::kClamp);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  std::shared_ptr<DlColorSource> dl_source =
      DlColorSource::MakeLinear(TestPoints[0], TestPoints[1], kTestStopCount,
                                TestColors, TestStops, DlTileMode::kClamp);
  ASSERT_EQ(source->type(), DlColorSourceType::kLinearGradient);
  EXPECT_TRUE(*source->asLinearGradient() == *dl_source->asLinearGradient());
  ASSERT_EQ(*source->asLinearGradient(), *dl_source->asLinearGradient());
  ASSERT_EQ(source->asLinearGradient()->start_point(), TestPoints[0]);
  ASSERT_EQ(source->asLinearGradient()->end_point(), TestPoints[1]);
  ASSERT_EQ(source->asLinearGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asLinearGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asLinearGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asLinearGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asLinearGradient()->matrix(), SkMatrix::I());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaRadialGradient) {
  // We can read back all of the parameters of a Radial gradient
  // except for matrix.
  sk_sp<SkShader> shader =
      SkGradientShader::MakeRadial(TestPoints[0], 10.0, TestColors, TestStops,
                                   kTestStopCount, SkTileMode::kClamp);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  std::shared_ptr<DlColorSource> dl_source =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp);
  ASSERT_EQ(source->type(), DlColorSourceType::kRadialGradient);
  EXPECT_TRUE(*source->asRadialGradient() == *dl_source->asRadialGradient());
  ASSERT_EQ(*source->asRadialGradient(), *dl_source->asRadialGradient());
  ASSERT_EQ(source->asRadialGradient()->center(), TestPoints[0]);
  ASSERT_EQ(source->asRadialGradient()->radius(), 10.0);
  ASSERT_EQ(source->asRadialGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asRadialGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asRadialGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asRadialGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asRadialGradient()->matrix(), SkMatrix::I());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaConicalGradient) {
  // We can read back all of the parameters of a Conical gradient
  // except for matrix.
  sk_sp<SkShader> shader = SkGradientShader::MakeTwoPointConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, TestColors, TestStops,
      kTestStopCount, SkTileMode::kClamp);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  std::shared_ptr<DlColorSource> dl_source = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp);
  ASSERT_EQ(source->type(), DlColorSourceType::kConicalGradient);
  EXPECT_TRUE(*source->asConicalGradient() == *dl_source->asConicalGradient());
  ASSERT_EQ(*source->asConicalGradient(), *dl_source->asConicalGradient());
  ASSERT_EQ(source->asConicalGradient()->start_center(), TestPoints[0]);
  ASSERT_EQ(source->asConicalGradient()->start_radius(), 10.0);
  ASSERT_EQ(source->asConicalGradient()->end_center(), TestPoints[1]);
  ASSERT_EQ(source->asConicalGradient()->end_radius(), 20.0);
  ASSERT_EQ(source->asConicalGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asConicalGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asConicalGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asConicalGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asConicalGradient()->matrix(), SkMatrix::I());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaSweepGradient) {
  // We can read back all of the parameters of a Sweep gradient
  // except for matrix and the start/stop angles.
  sk_sp<SkShader> shader =
      SkGradientShader::MakeSweep(TestPoints[0].fX, TestPoints[0].fY,
                                  TestColors, TestStops, kTestStopCount);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  std::shared_ptr<DlColorSource> dl_source =
      DlColorSource::MakeSweep(TestPoints[0], 0, 360, kTestStopCount,
                               TestColors, TestStops, DlTileMode::kClamp);
  ASSERT_EQ(source->type(), DlColorSourceType::kSweepGradient);
  EXPECT_TRUE(*source->asSweepGradient() == *dl_source->asSweepGradient());
  ASSERT_EQ(*source->asSweepGradient(), *dl_source->asSweepGradient());
  ASSERT_EQ(source->asSweepGradient()->center(), TestPoints[0]);
  ASSERT_EQ(source->asSweepGradient()->start(), 0);
  ASSERT_EQ(source->asSweepGradient()->end(), 360);
  ASSERT_EQ(source->asSweepGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asSweepGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asSweepGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asSweepGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asSweepGradient()->matrix(), SkMatrix::I());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_NE(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaUnrecognizedShader) {
  std::shared_ptr<DlColorSource> source =
      DlColorSource::From(TestUnknownShader);
  ASSERT_EQ(source->type(), DlColorSourceType::kUnknown);
  ASSERT_EQ(source->skia_object(), TestUnknownShader);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, ColorConstructor) {
  DlColorColorSource source(SK_ColorRED);
}

TEST(DisplayListColorSource, ColorShared) {
  DlColorColorSource source(SK_ColorRED);
  ASSERT_NE(source.shared().get(), &source);
  ASSERT_EQ(*source.shared(), source);
}

TEST(DisplayListColorSource, ColorAsColor) {
  DlColorColorSource source(SK_ColorRED);
  ASSERT_NE(source.asColor(), nullptr);
  ASSERT_EQ(source.asColor(), &source);

  ASSERT_EQ(source.asImage(), nullptr);
  ASSERT_EQ(source.asLinearGradient(), nullptr);
  ASSERT_EQ(source.asRadialGradient(), nullptr);
  ASSERT_EQ(source.asConicalGradient(), nullptr);
  ASSERT_EQ(source.asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, ColorContents) {
  DlColorColorSource source(SK_ColorRED);
  ASSERT_EQ(source.color(), SK_ColorRED);
  ASSERT_EQ(source.is_opaque(), true);
  for (int i = 0; i < 255; i++) {
    SkColor alpha_color = SkColorSetA(SK_ColorRED, i);
    DlColorColorSource alpha_source(alpha_color);
    ASSERT_EQ(alpha_source.color(), alpha_color);
    ASSERT_EQ(alpha_source.is_opaque(), false);
  }
}

TEST(DisplayListColorSource, ColorEquals) {
  DlColorColorSource source1(SK_ColorRED);
  DlColorColorSource source2(SK_ColorRED);
  TestEquals(source1, source2);
}

TEST(DisplayListColorSource, ColorNotEquals) {
  DlColorColorSource source1(SK_ColorRED);
  DlColorColorSource source2(SK_ColorBLUE);
  TestNotEquals(source1, source2, "Color differs");
}

TEST(DisplayListColorSource, ImageConstructor) {
  DlImageColorSource source(TestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DisplayList::LinearSampling, &TestMatrix1);
}

TEST(DisplayListColorSource, ImageShared) {
  DlImageColorSource source(TestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DisplayList::LinearSampling, &TestMatrix1);
  ASSERT_NE(source.shared().get(), &source);
  ASSERT_EQ(*source.shared(), source);
}

TEST(DisplayListColorSource, ImageAsImage) {
  DlImageColorSource source(TestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DisplayList::LinearSampling, &TestMatrix1);
  ASSERT_NE(source.asImage(), nullptr);
  ASSERT_EQ(source.asImage(), &source);

  ASSERT_EQ(source.asColor(), nullptr);
  ASSERT_EQ(source.asLinearGradient(), nullptr);
  ASSERT_EQ(source.asRadialGradient(), nullptr);
  ASSERT_EQ(source.asConicalGradient(), nullptr);
  ASSERT_EQ(source.asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, ImageContents) {
  DlImageColorSource source(TestImage1, DlTileMode::kRepeat,
                            DlTileMode::kMirror, DisplayList::LinearSampling,
                            &TestMatrix1);
  ASSERT_EQ(source.image(), TestImage1);
  ASSERT_EQ(source.horizontal_tile_mode(), DlTileMode::kRepeat);
  ASSERT_EQ(source.vertical_tile_mode(), DlTileMode::kMirror);
  ASSERT_EQ(source.sampling(), DisplayList::LinearSampling);
  ASSERT_EQ(source.matrix(), TestMatrix1);
  ASSERT_EQ(source.is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaImageContents) {
  DlImageColorSource source(TestAlphaImage1, DlTileMode::kRepeat,
                            DlTileMode::kMirror, DisplayList::LinearSampling,
                            &TestMatrix1);
  ASSERT_EQ(source.image(), TestAlphaImage1);
  ASSERT_EQ(source.horizontal_tile_mode(), DlTileMode::kRepeat);
  ASSERT_EQ(source.vertical_tile_mode(), DlTileMode::kMirror);
  ASSERT_EQ(source.sampling(), DisplayList::LinearSampling);
  ASSERT_EQ(source.matrix(), TestMatrix1);
  ASSERT_EQ(source.is_opaque(), false);
}

TEST(DisplayListColorSource, ImageEquals) {
  DlImageColorSource source1(TestImage1, DlTileMode::kClamp,
                             DlTileMode::kMirror, DisplayList::LinearSampling,
                             &TestMatrix1);
  DlImageColorSource source2(TestImage1, DlTileMode::kClamp,
                             DlTileMode::kMirror, DisplayList::LinearSampling,
                             &TestMatrix1);
  TestEquals(source1, source2);
}

TEST(DisplayListColorSource, ImageNotEquals) {
  DlImageColorSource source1(TestImage1, DlTileMode::kClamp,
                             DlTileMode::kMirror, DisplayList::LinearSampling,
                             &TestMatrix1);
  {
    DlImageColorSource source2(TestAlphaImage1, DlTileMode::kClamp,
                               DlTileMode::kMirror, DisplayList::LinearSampling,
                               &TestMatrix1);
    TestNotEquals(source1, source2, "Image differs");
  }
  {
    DlImageColorSource source2(TestImage1, DlTileMode::kRepeat,
                               DlTileMode::kMirror, DisplayList::LinearSampling,
                               &TestMatrix1);
    TestNotEquals(source1, source2, "hTileMode differs");
  }
  {
    DlImageColorSource source2(TestImage1, DlTileMode::kClamp,
                               DlTileMode::kRepeat, DisplayList::LinearSampling,
                               &TestMatrix1);
    TestNotEquals(source1, source2, "vTileMode differs");
  }
  {
    DlImageColorSource source2(TestImage1, DlTileMode::kClamp,
                               DlTileMode::kMirror, DisplayList::CubicSampling,
                               &TestMatrix1);
    TestNotEquals(source1, source2, "Sampling differs");
  }
  {
    DlImageColorSource source2(TestImage1, DlTileMode::kClamp,
                               DlTileMode::kMirror, DisplayList::LinearSampling,
                               &TestMatrix2);
    TestNotEquals(source1, source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, LinearGradientConstructor) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
}

TEST(DisplayListColorSource, LinearGradientShared) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, LinearGradientAsLinear) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), source.get());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, LinearGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asLinearGradient()->start_point(), TestPoints[0]);
  ASSERT_EQ(source->asLinearGradient()->end_point(), TestPoints[1]);
  ASSERT_EQ(source->asLinearGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asLinearGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asLinearGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asLinearGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asLinearGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaLinearGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestAlphaColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asLinearGradient()->start_point(), TestPoints[0]);
  ASSERT_EQ(source->asLinearGradient()->end_point(), TestPoints[1]);
  ASSERT_EQ(source->asLinearGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asLinearGradient()->colors()[i], TestAlphaColors[i]);
    ASSERT_EQ(source->asLinearGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asLinearGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asLinearGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, LinearGradientEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, LinearGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeLinear(
      TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        TestPoints2[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Point 0 differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        TestPoints[0], TestPoints2[1], kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Point 1 differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        TestPoints[0], TestPoints[1], 2, TestColors, TestStops,  //
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        TestPoints[0], TestPoints[1], kTestStopCount, TestAlphaColors,
        TestStops, DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops2,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
        DlTileMode::kMirror, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        TestPoints[0], TestPoints[1], kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, RadialGradientConstructor) {
  std::shared_ptr<DlColorSource> source =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp, &TestMatrix1);
}

TEST(DisplayListColorSource, RadialGradientShared) {
  std::shared_ptr<DlColorSource> source =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, RadialGradientAsRadial) {
  std::shared_ptr<DlColorSource> source =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), source.get());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, RadialGradientContents) {
  std::shared_ptr<DlColorSource> source =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asRadialGradient()->center(), TestPoints[0]);
  ASSERT_EQ(source->asRadialGradient()->radius(), 10.0);
  ASSERT_EQ(source->asRadialGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asRadialGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asRadialGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asRadialGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asRadialGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaRadialGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeRadial(
      TestPoints[0], 10.0, kTestStopCount, TestAlphaColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asRadialGradient()->center(), TestPoints[0]);
  ASSERT_EQ(source->asRadialGradient()->radius(), 10.0);
  ASSERT_EQ(source->asRadialGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asRadialGradient()->colors()[i], TestAlphaColors[i]);
    ASSERT_EQ(source->asRadialGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asRadialGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asRadialGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, RadialGradientEquals) {
  std::shared_ptr<DlColorSource> source1 =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp, &TestMatrix1);
  std::shared_ptr<DlColorSource> source2 =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp, &TestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, RadialGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 =
      DlColorSource::MakeRadial(TestPoints[0], 10.0, kTestStopCount, TestColors,
                                TestStops, DlTileMode::kClamp, &TestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        TestPoints2[0], 10.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        TestPoints[0], 20.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Radius differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        TestPoints[0], 10.0, 2, TestColors, TestStops,  //
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        TestPoints[0], 10.0, kTestStopCount, TestAlphaColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        TestPoints[0], 10.0, kTestStopCount, TestColors, TestStops2,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        TestPoints[0], 10.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kMirror, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        TestPoints[0], 10.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, ConicalGradientConstructor) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
}

TEST(DisplayListColorSource, ConicalGradientShared) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, ConicalGradientAsConical) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), source.get());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, ConicalGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asConicalGradient()->start_center(), TestPoints[0]);
  ASSERT_EQ(source->asConicalGradient()->start_radius(), 10.0);
  ASSERT_EQ(source->asConicalGradient()->end_center(), TestPoints[1]);
  ASSERT_EQ(source->asConicalGradient()->end_radius(), 20.0);
  ASSERT_EQ(source->asConicalGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asConicalGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asConicalGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asConicalGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asConicalGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaConicalGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestAlphaColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asConicalGradient()->start_center(), TestPoints[0]);
  ASSERT_EQ(source->asConicalGradient()->start_radius(), 10.0);
  ASSERT_EQ(source->asConicalGradient()->end_center(), TestPoints[1]);
  ASSERT_EQ(source->asConicalGradient()->end_radius(), 20.0);
  ASSERT_EQ(source->asConicalGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asConicalGradient()->colors()[i], TestAlphaColors[i]);
    ASSERT_EQ(source->asConicalGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asConicalGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asConicalGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, ConicalGradientEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
  std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, ConicalGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeConical(
      TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
      TestStops, DlTileMode::kClamp, &TestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints2[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
        TestStops, DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Start Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 15.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
        TestStops, DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Start Radius differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 10.0, TestPoints2[1], 20.0, kTestStopCount, TestColors,
        TestStops, DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "End Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 10.0, TestPoints[1], 25.0, kTestStopCount, TestColors,
        TestStops, DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "End Radius differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 10.0, TestPoints[1], 20.0, 2, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount,
        TestAlphaColors, TestStops, DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
        TestStops2, DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
        TestStops, DlTileMode::kMirror, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        TestPoints[0], 10.0, TestPoints[1], 20.0, kTestStopCount, TestColors,
        TestStops, DlTileMode::kClamp, &TestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, SweepGradientConstructor) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
}

TEST(DisplayListColorSource, SweepGradientShared) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, SweepGradientAsSweep) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_NE(source->asSweepGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), source.get());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
}

TEST(DisplayListColorSource, SweepGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asSweepGradient()->center(), TestPoints[0]);
  ASSERT_EQ(source->asSweepGradient()->start(), 10.0);
  ASSERT_EQ(source->asSweepGradient()->end(), 20.0);
  ASSERT_EQ(source->asSweepGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asSweepGradient()->colors()[i], TestColors[i]);
    ASSERT_EQ(source->asSweepGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asSweepGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asSweepGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaSweepGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestAlphaColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  ASSERT_EQ(source->asSweepGradient()->center(), TestPoints[0]);
  ASSERT_EQ(source->asSweepGradient()->start(), 10.0);
  ASSERT_EQ(source->asSweepGradient()->end(), 20.0);
  ASSERT_EQ(source->asSweepGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asSweepGradient()->colors()[i], TestAlphaColors[i]);
    ASSERT_EQ(source->asSweepGradient()->stops()[i], TestStops[i]);
  }
  ASSERT_EQ(source->asSweepGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asSweepGradient()->matrix(), TestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, SweepGradientEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, SweepGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeSweep(
      TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
      DlTileMode::kClamp, &TestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints2[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints[0], 15.0, 20.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Start Angle differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints[0], 10.0, 25.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "End Angle differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints[0], 10.0, 20.0, 2, TestColors, TestStops,  //
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints[0], 10.0, 20.0, kTestStopCount, TestAlphaColors, TestStops,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops2,
        DlTileMode::kClamp, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kMirror, &TestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        TestPoints[0], 10.0, 20.0, kTestStopCount, TestColors, TestStops,
        DlTileMode::kClamp, &TestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, UnknownConstructor) {
  DlUnknownColorSource source(TestUnknownShader);
}

TEST(DisplayListColorSource, UnknownShared) {
  DlUnknownColorSource source(TestUnknownShader);
  ASSERT_NE(source.shared().get(), &source);
  ASSERT_EQ(*source.shared(), source);
}

TEST(DisplayListColorSource, UnknownAsNone) {
  DlUnknownColorSource source(TestUnknownShader);
  ASSERT_EQ(source.asColor(), nullptr);
  ASSERT_EQ(source.asImage(), nullptr);
  ASSERT_EQ(source.asLinearGradient(), nullptr);
  ASSERT_EQ(source.asRadialGradient(), nullptr);
  ASSERT_EQ(source.asConicalGradient(), nullptr);
  ASSERT_EQ(source.asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, UnknownContents) {
  DlUnknownColorSource source(TestUnknownShader);
  ASSERT_EQ(source.skia_object(), TestUnknownShader);
  // Blend shaders always return false for is_opaque.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=13046
  ASSERT_EQ(source.is_opaque(), false);
}

TEST(DisplayListColorSource, AlphaUnknownContents) {
  DlUnknownColorSource source(TestAlphaUnknownShader);
  ASSERT_EQ(source.skia_object(), TestAlphaUnknownShader);
  ASSERT_EQ(source.is_opaque(), false);
}

TEST(DisplayListColorSource, UnknownEquals) {
  DlUnknownColorSource source1(TestUnknownShader);
  DlUnknownColorSource source2(TestUnknownShader);
  TestEquals(source1, source2);
}

TEST(DisplayListColorSource, UnknownNotEquals) {
  DlUnknownColorSource source1(TestUnknownShader);
  DlUnknownColorSource source2(TestAlphaUnknownShader);
  TestNotEquals(source1, source2, "SkShader differs");
}

}  // namespace testing
}  // namespace flutter

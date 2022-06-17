// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_attributes_testing.h"
#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_color_source.h"
#include "flutter/display_list/display_list_sampling_options.h"
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

static const sk_sp<SkImage> kTestImage1 = MakeTestImage(10, 10, SK_ColorGREEN);
static const sk_sp<SkImage> kTestAlphaImage1 =
    MakeTestImage(10, 10, SK_ColorTRANSPARENT);
// clang-format off
static const SkMatrix kTestMatrix1 =
    SkMatrix::MakeAll(2, 0, 10,
                      0, 3, 12,
                      0, 0, 1);
static const SkMatrix kTestMatrix2 =
    SkMatrix::MakeAll(4, 0, 15,
                      0, 7, 17,
                      0, 0, 1);
// clang-format on
static constexpr int kTestStopCount = 3;
static constexpr DlColor kTestColors[kTestStopCount] = {
    DlColor::kRed(),
    DlColor::kGreen(),
    DlColor::kBlue(),
};
static const DlColor kTestAlphaColors[kTestStopCount] = {
    DlColor::kBlue().withAlpha(0x7F),
    DlColor::kRed().withAlpha(0x2F),
    DlColor::kGreen().withAlpha(0xCF),
};
static constexpr float kTestStops[kTestStopCount] = {
    0.0f,
    0.7f,
    1.0f,
};
static constexpr float kTestStops2[kTestStopCount] = {
    0.0f,
    0.3f,
    1.0f,
};
static constexpr SkPoint kTestPoints[2] = {
    SkPoint::Make(5, 15),
    SkPoint::Make(7, 18),
};
static constexpr SkPoint kTestPoints2[2] = {
    SkPoint::Make(100, 115),
    SkPoint::Make(107, 118),
};
static const sk_sp<SkShader> kShaderA = SkShaders::Color(SK_ColorRED);
static const sk_sp<SkShader> kShaderB = SkShaders::Color(SK_ColorBLUE);
static const sk_sp<SkShader> kTestUnknownShader =
    SkShaders::Blend(SkBlendMode::kOverlay, kShaderA, kShaderB);
static const sk_sp<SkShader> kTestAlphaUnknownShader =
    SkShaders::Blend(SkBlendMode::kDstOut, kShaderA, kShaderB);

TEST(DisplayListColorSource, BuilderSetGet) {
  DlImageColorSource source(kTestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DlImageSampling::kLinear, &kTestMatrix1);
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
  // We cannot read back the matrix parameter from a Skia LinearGradient
  // so we conservatively use an UnknownColorSource wrapper so as to not
  // lose any data. Note that the Skia Color shader end is read back from
  // the Skia asAGradient() method so while this type of color source
  // does not really need the matrix, we represent all of the gradient
  // sources using an unknown source.
  // Note that this shader should never really happen in practice as it
  // represents a degenerate gradient that collapsed to a single color.
  sk_sp<SkShader> shader = SkShaders::Color(SK_ColorBLUE);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  ASSERT_EQ(source->type(), DlColorSourceType::kUnknown);
  ASSERT_EQ(source->skia_object(), shader);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaImageShader) {
  sk_sp<SkShader> shader =
      kTestImage1->makeShader(ToSk(DlImageSampling::kLinear), &kTestMatrix1);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  DlImageColorSource dl_source(kTestImage1, DlTileMode::kClamp,
                               DlTileMode::kClamp, DlImageSampling::kLinear,
                               &kTestMatrix1);
  ASSERT_EQ(source->type(), DlColorSourceType::kImage);
  ASSERT_EQ(*source->asImage(), dl_source);
  ASSERT_EQ(source->asImage()->image(), kTestImage1);
  ASSERT_EQ(source->asImage()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->asImage()->horizontal_tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asImage()->vertical_tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asImage()->sampling(), DlImageSampling::kLinear);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaLinearGradient) {
  // We cannot read back the matrix parameter from a Skia LinearGradient
  // so we conservatively use an UnknownColorSource wrapper so as to not
  // lose any data.
  const SkColor* sk_colors = reinterpret_cast<const SkColor*>(kTestColors);
  sk_sp<SkShader> shader = SkGradientShader::MakeLinear(
      kTestPoints, sk_colors, kTestStops, kTestStopCount, SkTileMode::kClamp);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  ASSERT_EQ(source->type(), DlColorSourceType::kUnknown);
  ASSERT_EQ(source->skia_object(), shader);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaRadialGradient) {
  // We cannot read back the matrix parameter from a Skia RadialGradient
  // so we conservatively use an UnknownColorSource wrapper so as to not
  // lose any data.
  const SkColor* sk_colors = reinterpret_cast<const SkColor*>(kTestColors);
  sk_sp<SkShader> shader =
      SkGradientShader::MakeRadial(kTestPoints[0], 10.0, sk_colors, kTestStops,
                                   kTestStopCount, SkTileMode::kClamp);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  ASSERT_EQ(source->type(), DlColorSourceType::kUnknown);
  ASSERT_EQ(source->skia_object(), shader);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaConicalGradient) {
  // We cannot read back the matrix parameter from a Skia ConicalGradient
  // so we conservatively use an UnknownColorSource wrapper so as to not
  // lose any data.
  const SkColor* sk_colors = reinterpret_cast<const SkColor*>(kTestColors);
  sk_sp<SkShader> shader = SkGradientShader::MakeTwoPointConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, sk_colors, kTestStops,
      kTestStopCount, SkTileMode::kClamp);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  ASSERT_EQ(source->type(), DlColorSourceType::kUnknown);
  ASSERT_EQ(source->skia_object(), shader);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaSweepGradient) {
  // We cannot read back the matrix parameter, nor the sweep parameters from a
  // Skia SweepGradient so we conservatively use an UnknownColorSource wrapper
  // so as to not lose any data.
  const SkColor* sk_colors = reinterpret_cast<const SkColor*>(kTestColors);
  sk_sp<SkShader> shader =
      SkGradientShader::MakeSweep(kTestPoints[0].fX, kTestPoints[0].fY,
                                  sk_colors, kTestStops, kTestStopCount);
  std::shared_ptr<DlColorSource> source = DlColorSource::From(shader);
  ASSERT_EQ(source->type(), DlColorSourceType::kUnknown);
  ASSERT_EQ(source->skia_object(), shader);

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, FromSkiaUnrecognizedShader) {
  std::shared_ptr<DlColorSource> source =
      DlColorSource::From(kTestUnknownShader);
  ASSERT_EQ(source->type(), DlColorSourceType::kUnknown);
  ASSERT_EQ(source->skia_object(), kTestUnknownShader);

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
  DlImageColorSource source(kTestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DlImageSampling::kLinear, &kTestMatrix1);
}

TEST(DisplayListColorSource, ImageShared) {
  DlImageColorSource source(kTestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DlImageSampling::kLinear, &kTestMatrix1);
  ASSERT_NE(source.shared().get(), &source);
  ASSERT_EQ(*source.shared(), source);
}

TEST(DisplayListColorSource, ImageAsImage) {
  DlImageColorSource source(kTestImage1, DlTileMode::kClamp, DlTileMode::kClamp,
                            DlImageSampling::kLinear, &kTestMatrix1);
  ASSERT_NE(source.asImage(), nullptr);
  ASSERT_EQ(source.asImage(), &source);

  ASSERT_EQ(source.asColor(), nullptr);
  ASSERT_EQ(source.asLinearGradient(), nullptr);
  ASSERT_EQ(source.asRadialGradient(), nullptr);
  ASSERT_EQ(source.asConicalGradient(), nullptr);
  ASSERT_EQ(source.asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, ImageContents) {
  DlImageColorSource source(kTestImage1, DlTileMode::kRepeat,
                            DlTileMode::kMirror, DlImageSampling::kLinear,
                            &kTestMatrix1);
  ASSERT_EQ(source.image(), kTestImage1);
  ASSERT_EQ(source.horizontal_tile_mode(), DlTileMode::kRepeat);
  ASSERT_EQ(source.vertical_tile_mode(), DlTileMode::kMirror);
  ASSERT_EQ(source.sampling(), DlImageSampling::kLinear);
  ASSERT_EQ(source.matrix(), kTestMatrix1);
  ASSERT_EQ(source.is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaImageContents) {
  DlImageColorSource source(kTestAlphaImage1, DlTileMode::kRepeat,
                            DlTileMode::kMirror, DlImageSampling::kLinear,
                            &kTestMatrix1);
  ASSERT_EQ(source.image(), kTestAlphaImage1);
  ASSERT_EQ(source.horizontal_tile_mode(), DlTileMode::kRepeat);
  ASSERT_EQ(source.vertical_tile_mode(), DlTileMode::kMirror);
  ASSERT_EQ(source.sampling(), DlImageSampling::kLinear);
  ASSERT_EQ(source.matrix(), kTestMatrix1);
  ASSERT_EQ(source.is_opaque(), false);
}

TEST(DisplayListColorSource, ImageEquals) {
  DlImageColorSource source1(kTestImage1, DlTileMode::kClamp,
                             DlTileMode::kMirror, DlImageSampling::kLinear,
                             &kTestMatrix1);
  DlImageColorSource source2(kTestImage1, DlTileMode::kClamp,
                             DlTileMode::kMirror, DlImageSampling::kLinear,
                             &kTestMatrix1);
  TestEquals(source1, source2);
}

TEST(DisplayListColorSource, ImageNotEquals) {
  DlImageColorSource source1(kTestImage1, DlTileMode::kClamp,
                             DlTileMode::kMirror, DlImageSampling::kLinear,
                             &kTestMatrix1);
  {
    DlImageColorSource source2(kTestAlphaImage1, DlTileMode::kClamp,
                               DlTileMode::kMirror, DlImageSampling::kLinear,
                               &kTestMatrix1);
    TestNotEquals(source1, source2, "Image differs");
  }
  {
    DlImageColorSource source2(kTestImage1, DlTileMode::kRepeat,
                               DlTileMode::kMirror, DlImageSampling::kLinear,
                               &kTestMatrix1);
    TestNotEquals(source1, source2, "hTileMode differs");
  }
  {
    DlImageColorSource source2(kTestImage1, DlTileMode::kClamp,
                               DlTileMode::kRepeat, DlImageSampling::kLinear,
                               &kTestMatrix1);
    TestNotEquals(source1, source2, "vTileMode differs");
  }
  {
    DlImageColorSource source2(kTestImage1, DlTileMode::kClamp,
                               DlTileMode::kMirror, DlImageSampling::kCubic,
                               &kTestMatrix1);
    TestNotEquals(source1, source2, "Sampling differs");
  }
  {
    DlImageColorSource source2(kTestImage1, DlTileMode::kClamp,
                               DlTileMode::kMirror, DlImageSampling::kLinear,
                               &kTestMatrix2);
    TestNotEquals(source1, source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, LinearGradientConstructor) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
}

TEST(DisplayListColorSource, LinearGradientShared) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, LinearGradientAsLinear) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
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
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asLinearGradient()->start_point(), kTestPoints[0]);
  ASSERT_EQ(source->asLinearGradient()->end_point(), kTestPoints[1]);
  ASSERT_EQ(source->asLinearGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asLinearGradient()->colors()[i], kTestColors[i]);
    ASSERT_EQ(source->asLinearGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asLinearGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asLinearGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaLinearGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeLinear(
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestAlphaColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asLinearGradient()->start_point(), kTestPoints[0]);
  ASSERT_EQ(source->asLinearGradient()->end_point(), kTestPoints[1]);
  ASSERT_EQ(source->asLinearGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asLinearGradient()->colors()[i], kTestAlphaColors[i]);
    ASSERT_EQ(source->asLinearGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asLinearGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asLinearGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, LinearGradientEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeLinear(
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, LinearGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeLinear(
      kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        kTestPoints2[0], kTestPoints[1], kTestStopCount, kTestColors,
        kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Point 0 differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        kTestPoints[0], kTestPoints2[1], kTestStopCount, kTestColors,
        kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Point 1 differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        kTestPoints[0], kTestPoints[1], 2, kTestColors, kTestStops,  //
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        kTestPoints[0], kTestPoints[1], kTestStopCount, kTestAlphaColors,
        kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors,
        kTestStops2, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kMirror, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeLinear(
        kTestPoints[0], kTestPoints[1], kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, RadialGradientConstructor) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
}

TEST(DisplayListColorSource, RadialGradientShared) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, RadialGradientAsRadial) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_NE(source->asRadialGradient(), nullptr);
  ASSERT_EQ(source->asRadialGradient(), source.get());

  ASSERT_EQ(source->asColor(), nullptr);
  ASSERT_EQ(source->asImage(), nullptr);
  ASSERT_EQ(source->asLinearGradient(), nullptr);
  ASSERT_EQ(source->asConicalGradient(), nullptr);
  ASSERT_EQ(source->asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, RadialGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asRadialGradient()->center(), kTestPoints[0]);
  ASSERT_EQ(source->asRadialGradient()->radius(), 10.0);
  ASSERT_EQ(source->asRadialGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asRadialGradient()->colors()[i], kTestColors[i]);
    ASSERT_EQ(source->asRadialGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asRadialGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asRadialGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaRadialGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestAlphaColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asRadialGradient()->center(), kTestPoints[0]);
  ASSERT_EQ(source->asRadialGradient()->radius(), 10.0);
  ASSERT_EQ(source->asRadialGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asRadialGradient()->colors()[i], kTestAlphaColors[i]);
    ASSERT_EQ(source->asRadialGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asRadialGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asRadialGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, RadialGradientEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, RadialGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeRadial(
      kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        kTestPoints2[0], 10.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        kTestPoints[0], 20.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Radius differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        kTestPoints[0], 10.0, 2, kTestColors, kTestStops,  //
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        kTestPoints[0], 10.0, kTestStopCount, kTestAlphaColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops2,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kMirror, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeRadial(
        kTestPoints[0], 10.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, ConicalGradientConstructor) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
}

TEST(DisplayListColorSource, ConicalGradientShared) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, ConicalGradientAsConical) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
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
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asConicalGradient()->start_center(), kTestPoints[0]);
  ASSERT_EQ(source->asConicalGradient()->start_radius(), 10.0);
  ASSERT_EQ(source->asConicalGradient()->end_center(), kTestPoints[1]);
  ASSERT_EQ(source->asConicalGradient()->end_radius(), 20.0);
  ASSERT_EQ(source->asConicalGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asConicalGradient()->colors()[i], kTestColors[i]);
    ASSERT_EQ(source->asConicalGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asConicalGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asConicalGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaConicalGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount,
      kTestAlphaColors, kTestStops, DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asConicalGradient()->start_center(), kTestPoints[0]);
  ASSERT_EQ(source->asConicalGradient()->start_radius(), 10.0);
  ASSERT_EQ(source->asConicalGradient()->end_center(), kTestPoints[1]);
  ASSERT_EQ(source->asConicalGradient()->end_radius(), 20.0);
  ASSERT_EQ(source->asConicalGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asConicalGradient()->colors()[i], kTestAlphaColors[i]);
    ASSERT_EQ(source->asConicalGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asConicalGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asConicalGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, ConicalGradientEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
  std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, ConicalGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeConical(
      kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
      kTestStops, DlTileMode::kClamp, &kTestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints2[0], 10.0, kTestPoints[1], 20.0, kTestStopCount,
        kTestColors, kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Start Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 15.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
        kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Start Radius differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 10.0, kTestPoints2[1], 20.0, kTestStopCount,
        kTestColors, kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "End Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 10.0, kTestPoints[1], 25.0, kTestStopCount, kTestColors,
        kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "End Radius differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 10.0, kTestPoints[1], 20.0, 2, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount,
        kTestAlphaColors, kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
        kTestStops2, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
        kTestStops, DlTileMode::kMirror, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeConical(
        kTestPoints[0], 10.0, kTestPoints[1], 20.0, kTestStopCount, kTestColors,
        kTestStops, DlTileMode::kClamp, &kTestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, SweepGradientConstructor) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
}

TEST(DisplayListColorSource, SweepGradientShared) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_NE(source->shared().get(), source.get());
  ASSERT_EQ(*source->shared().get(), *source.get());
}

TEST(DisplayListColorSource, SweepGradientAsSweep) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
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
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asSweepGradient()->center(), kTestPoints[0]);
  ASSERT_EQ(source->asSweepGradient()->start(), 10.0);
  ASSERT_EQ(source->asSweepGradient()->end(), 20.0);
  ASSERT_EQ(source->asSweepGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asSweepGradient()->colors()[i], kTestColors[i]);
    ASSERT_EQ(source->asSweepGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asSweepGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asSweepGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), true);
}

TEST(DisplayListColorSource, AlphaSweepGradientContents) {
  std::shared_ptr<DlColorSource> source = DlColorSource::MakeSweep(
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestAlphaColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  ASSERT_EQ(source->asSweepGradient()->center(), kTestPoints[0]);
  ASSERT_EQ(source->asSweepGradient()->start(), 10.0);
  ASSERT_EQ(source->asSweepGradient()->end(), 20.0);
  ASSERT_EQ(source->asSweepGradient()->stop_count(), kTestStopCount);
  for (int i = 0; i < kTestStopCount; i++) {
    ASSERT_EQ(source->asSweepGradient()->colors()[i], kTestAlphaColors[i]);
    ASSERT_EQ(source->asSweepGradient()->stops()[i], kTestStops[i]);
  }
  ASSERT_EQ(source->asSweepGradient()->tile_mode(), DlTileMode::kClamp);
  ASSERT_EQ(source->asSweepGradient()->matrix(), kTestMatrix1);
  ASSERT_EQ(source->is_opaque(), false);
}

TEST(DisplayListColorSource, SweepGradientEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeSweep(
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  TestEquals(*source1, *source2);
}

TEST(DisplayListColorSource, SweepGradientNotEquals) {
  std::shared_ptr<DlColorSource> source1 = DlColorSource::MakeSweep(
      kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
      DlTileMode::kClamp, &kTestMatrix1);
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints2[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Center differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints[0], 15.0, 20.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Start Angle differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints[0], 10.0, 25.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "End Angle differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints[0], 10.0, 20.0, 2, kTestColors, kTestStops,  //
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stop count differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestAlphaColors,
        kTestStops, DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Colors differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops2,
        DlTileMode::kClamp, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Stops differ");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kMirror, &kTestMatrix1);
    TestNotEquals(*source1, *source2, "Tile Mode differs");
  }
  {
    std::shared_ptr<DlColorSource> source2 = DlColorSource::MakeSweep(
        kTestPoints[0], 10.0, 20.0, kTestStopCount, kTestColors, kTestStops,
        DlTileMode::kClamp, &kTestMatrix2);
    TestNotEquals(*source1, *source2, "Matrix differs");
  }
}

TEST(DisplayListColorSource, UnknownConstructor) {
  DlUnknownColorSource source(kTestUnknownShader);
}

TEST(DisplayListColorSource, UnknownShared) {
  DlUnknownColorSource source(kTestUnknownShader);
  ASSERT_NE(source.shared().get(), &source);
  ASSERT_EQ(*source.shared(), source);
}

TEST(DisplayListColorSource, UnknownAsNone) {
  DlUnknownColorSource source(kTestUnknownShader);
  ASSERT_EQ(source.asColor(), nullptr);
  ASSERT_EQ(source.asImage(), nullptr);
  ASSERT_EQ(source.asLinearGradient(), nullptr);
  ASSERT_EQ(source.asRadialGradient(), nullptr);
  ASSERT_EQ(source.asConicalGradient(), nullptr);
  ASSERT_EQ(source.asSweepGradient(), nullptr);
}

TEST(DisplayListColorSource, UnknownContents) {
  DlUnknownColorSource source(kTestUnknownShader);
  ASSERT_EQ(source.skia_object(), kTestUnknownShader);
  // Blend shaders always return false for is_opaque.
  // See: https://bugs.chromium.org/p/skia/issues/detail?id=13046
  ASSERT_EQ(source.is_opaque(), false);
}

TEST(DisplayListColorSource, AlphaUnknownContents) {
  DlUnknownColorSource source(kTestAlphaUnknownShader);
  ASSERT_EQ(source.skia_object(), kTestAlphaUnknownShader);
  ASSERT_EQ(source.is_opaque(), false);
}

TEST(DisplayListColorSource, UnknownEquals) {
  DlUnknownColorSource source1(kTestUnknownShader);
  DlUnknownColorSource source2(kTestUnknownShader);
  TestEquals(source1, source2);
}

TEST(DisplayListColorSource, UnknownNotEquals) {
  DlUnknownColorSource source1(kTestUnknownShader);
  DlUnknownColorSource source2(kTestAlphaUnknownShader);
  TestNotEquals(source1, source2, "SkShader differs");
}

}  // namespace testing
}  // namespace flutter

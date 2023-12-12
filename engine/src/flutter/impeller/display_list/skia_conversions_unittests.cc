// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/dl_color.h"
#include "display_list/dl_tile_mode.h"
#include "flutter/testing/testing.h"
#include "impeller/display_list/skia_conversions.h"
#include "impeller/geometry/scalar.h"

namespace impeller {
namespace testing {

TEST(SkiaConversionsTest, SkPointToPoint) {
  for (int x = -100; x < 100; x += 4) {
    for (int y = -100; y < 100; y += 4) {
      EXPECT_EQ(skia_conversions::ToPoint(SkPoint::Make(x * 0.25f, y * 0.25f)),
                Point(x * 0.25f, y * 0.25f));
    }
  }
}

TEST(SkiaConversionsTest, SkPointToSize) {
  for (int x = -100; x < 100; x += 4) {
    for (int y = -100; y < 100; y += 4) {
      EXPECT_EQ(skia_conversions::ToSize(SkPoint::Make(x * 0.25f, y * 0.25f)),
                Size(x * 0.25f, y * 0.25f));
    }
  }
}

TEST(SkiaConversionsTest, ToColor) {
  // Create a color with alpha, red, green, and blue values that are all
  // trivially divisible by 255 so that we can test the conversion results in
  // correct scalar values.
  //                                                AARRGGBB
  const flutter::DlColor color = flutter::DlColor(0x8040C020);
  auto converted_color = skia_conversions::ToColor(color);

  ASSERT_TRUE(ScalarNearlyEqual(converted_color.alpha, 0x80 * (1.0f / 255)));
  ASSERT_TRUE(ScalarNearlyEqual(converted_color.red, 0x40 * (1.0f / 255)));
  ASSERT_TRUE(ScalarNearlyEqual(converted_color.green, 0xC0 * (1.0f / 255)));
  ASSERT_TRUE(ScalarNearlyEqual(converted_color.blue, 0x20 * (1.0f / 255)));
}

TEST(SkiaConversionsTest, GradientStopConversion) {
  // Typical gradient.
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed(),
                                          flutter::DlColor::kGreen()};
  std::vector<float> stops = {0.0, 0.5, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(SkPoint::Make(0, 0),          //
                                         SkPoint::Make(1.0, 1.0),      //
                                         3,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  skia_conversions::ConvertStops(gradient.get(), converted_colors,
                                 converted_stops);

  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(SkiaConversionsTest, GradientMissing0) {
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  std::vector<float> stops = {0.5, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(SkPoint::Make(0, 0),          //
                                         SkPoint::Make(1.0, 1.0),      //
                                         2,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  skia_conversions::ConvertStops(gradient.get(), converted_colors,
                                 converted_stops);

  // First color is inserted as blue.
  ASSERT_TRUE(ScalarNearlyEqual(converted_colors[0].blue, 1.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(SkiaConversionsTest, GradientMissingLastValue) {
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  std::vector<float> stops = {0.0, .5};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(SkPoint::Make(0, 0),          //
                                         SkPoint::Make(1.0, 1.0),      //
                                         2,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  skia_conversions::ConvertStops(gradient.get(), converted_colors,
                                 converted_stops);

  // Last color is inserted as red.
  ASSERT_TRUE(ScalarNearlyEqual(converted_colors[2].red, 1.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(SkiaConversionsTest, GradientStopGreaterThan1) {
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kGreen(),
                                          flutter::DlColor::kRed()};
  std::vector<float> stops = {0.0, 100, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(SkPoint::Make(0, 0),          //
                                         SkPoint::Make(1.0, 1.0),      //
                                         3,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  skia_conversions::ConvertStops(gradient.get(), converted_colors,
                                 converted_stops);

  // Value is clamped to 1.0
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 1.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(SkiaConversionsTest, GradientConversionNonMonotonic) {
  std::vector<flutter::DlColor> colors = {
      flutter::DlColor::kBlue(), flutter::DlColor::kGreen(),
      flutter::DlColor::kGreen(), flutter::DlColor::kRed()};
  std::vector<float> stops = {0.0, 0.5, 0.4, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(SkPoint::Make(0, 0),          //
                                         SkPoint::Make(1.0, 1.0),      //
                                         4,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  skia_conversions::ConvertStops(gradient.get(), converted_colors,
                                 converted_stops);

  // Value is clamped to 0.5
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[3], 1.0f));
}

}  // namespace testing
}  // namespace impeller

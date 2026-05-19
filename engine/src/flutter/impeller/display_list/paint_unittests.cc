// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/display_list/paint.h"

#include "gtest/gtest.h"

#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_tile_mode.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/impeller/geometry/scalar.h"

namespace impeller {
namespace testing {

TEST(PaintTest, GradientStopConversion) {
  // Typical gradient.
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed(),
                                          flutter::DlColor::kGreen()};
  std::vector<float> stops = {0.0, 0.5, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(flutter::DlPoint(0, 0),       //
                                         flutter::DlPoint(1.0, 1.0),   //
                                         3,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  Paint::ConvertStops(gradient->asLinearGradient(), converted_colors,
                      converted_stops);

  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(PaintTest, GradientMissing0) {
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  std::vector<float> stops = {0.5, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(flutter::DlPoint(0, 0),       //
                                         flutter::DlPoint(1.0, 1.0),   //
                                         2,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  Paint::ConvertStops(gradient->asLinearGradient(), converted_colors,
                      converted_stops);

  // First color is inserted as blue.
  ASSERT_TRUE(ScalarNearlyEqual(converted_colors[0].blue, 1.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(PaintTest, GradientMissingLastValue) {
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  std::vector<float> stops = {0.0, .5};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(flutter::DlPoint(0, 0),       //
                                         flutter::DlPoint(1.0, 1.0),   //
                                         2,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  Paint::ConvertStops(gradient->asLinearGradient(), converted_colors,
                      converted_stops);

  // Last color is inserted as red.
  ASSERT_TRUE(ScalarNearlyEqual(converted_colors[2].red, 1.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(PaintTest, GradientStopGreaterThan1) {
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kGreen(),
                                          flutter::DlColor::kRed()};
  std::vector<float> stops = {0.0, 100, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(flutter::DlPoint(0, 0),       //
                                         flutter::DlPoint(1.0, 1.0),   //
                                         3,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  Paint::ConvertStops(gradient->asLinearGradient(), converted_colors,
                      converted_stops);

  // Value is clamped to 1.0
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 1.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 1.0f));
}

TEST(PaintTest, GradientConversionNonMonotonic) {
  std::vector<flutter::DlColor> colors = {
      flutter::DlColor::kBlue(), flutter::DlColor::kGreen(),
      flutter::DlColor::kGreen(), flutter::DlColor::kRed()};
  std::vector<float> stops = {0.0, 0.5, 0.4, 1.0};
  const auto gradient =
      flutter::DlColorSource::MakeLinear(flutter::DlPoint(0, 0),       //
                                         flutter::DlPoint(1.0, 1.0),   //
                                         4,                            //
                                         colors.data(),                //
                                         stops.data(),                 //
                                         flutter::DlTileMode::kClamp,  //
                                         nullptr                       //
      );

  std::vector<Color> converted_colors;
  std::vector<Scalar> converted_stops;
  Paint::ConvertStops(gradient->asLinearGradient(), converted_colors,
                      converted_stops);

  // Value is clamped to 0.5
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[0], 0.0f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[1], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[2], 0.5f));
  ASSERT_TRUE(ScalarNearlyEqual(converted_stops[3], 1.0f));
}

}  // namespace testing
}  // namespace impeller

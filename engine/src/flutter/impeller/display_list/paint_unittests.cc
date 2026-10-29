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

// Initial paint must match DlPaint::kDefault (see DlOpReceiver).
// https://github.com/flutter/flutter/issues/193388.
TEST(PaintTest, DefaultsMatchDlPaintDefaults) {
  Paint paint;
  const flutter::DlPaint& defaults = flutter::DlPaint::kDefault;

  EXPECT_EQ(paint.anti_alias, defaults.isAntiAlias());
  EXPECT_EQ(paint.invert_colors, defaults.isInvertColors());
  EXPECT_EQ(paint.color, Color::Black());
  EXPECT_EQ(paint.color_source, nullptr);
  EXPECT_EQ(paint.color_filter, nullptr);
  EXPECT_EQ(paint.image_filter, nullptr);
  EXPECT_FALSE(paint.mask_blur_descriptor.has_value());
  EXPECT_EQ(paint.style, Paint::Style::kFill);
  EXPECT_EQ(paint.blend_mode, BlendMode::kSrcOver);
  EXPECT_EQ(paint.stroke.width, defaults.getStrokeWidth());
  EXPECT_EQ(paint.stroke.miter_limit, defaults.getStrokeMiter());
  EXPECT_EQ(paint.stroke.cap, Cap::kButt);
  EXPECT_EQ(paint.stroke.join, Join::kMiter);
}

TEST(PaintTest, OptionalStrokeWithFill) {
  Paint paint;
  paint.style = Paint::Style::kFill;
  paint.stroke.cap = Cap::kRound;
  paint.stroke.join = Join::kRound;
  paint.stroke.width = 20.0f;
  paint.stroke.miter_limit = 100.0f;

  EXPECT_FALSE(paint.GetStroke().has_value());
  // Even though optional stroke wasn't returned, the underlying values
  // are still in the Paint.
  EXPECT_EQ(paint.stroke.cap, Cap::kRound);
  EXPECT_EQ(paint.stroke.join, Join::kRound);
  EXPECT_EQ(paint.stroke.width, 20.0f);
  EXPECT_EQ(paint.stroke.miter_limit, 100.0f);
}

TEST(PaintTest, OptionalStrokeWithStroke) {
  Paint paint;
  paint.style = Paint::Style::kStroke;
  paint.stroke.cap = Cap::kRound;
  paint.stroke.join = Join::kRound;
  paint.stroke.width = 20.0f;
  paint.stroke.miter_limit = 100.0f;

  std::optional<StrokeParameters> optional_stroke = paint.GetStroke();
  EXPECT_TRUE(optional_stroke.has_value());
  if (optional_stroke.has_value()) {  // Test to keep clang-tidy happy.
    EXPECT_EQ(optional_stroke->cap, Cap::kRound);
    EXPECT_EQ(optional_stroke->join, Join::kRound);
    EXPECT_EQ(optional_stroke->width, 20.0f);
    EXPECT_EQ(optional_stroke->miter_limit, 100.0f);
  }
}

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

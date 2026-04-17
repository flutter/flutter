// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/geometry/rect.h"

namespace impeller {
namespace testing {

TEST(UberSDFParametersTest, MakeFillRect) {
  auto rect = Rect::MakeLTRB(100, 100, 200, 200);
  auto params = UberSDFParameters::MakeRect(Color::Red(), rect, std::nullopt);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kRect);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, Point(150, 150));
  EXPECT_EQ(params.size, Point(50, 50));
  EXPECT_FALSE(params.stroke.has_value());
}

TEST(UberSDFParametersTest, MakeStrokeRect) {
  auto rect = Rect::MakeLTRB(100, 100, 200, 200);
  StrokeParameters stroke = {.width = 4.0f};
  auto params = UberSDFParameters::MakeRect(Color::Red(), rect, stroke);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kRect);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, Point(150, 150));
  EXPECT_EQ(params.size, Point(50, 50));
  EXPECT_EQ(params.stroke, stroke);
}

TEST(UberSDFParametersTest, MakeStrokeRectLowMiterLimitBecomesBevel) {
  auto rect = Rect::MakeLTRB(100, 100, 200, 200);
  StrokeParameters stroke = {
      .width = 4.0f, .join = Join::kMiter, .miter_limit = 1.0f};
  auto params = UberSDFParameters::MakeRect(Color::Red(), rect, stroke);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kRect);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, Point(150, 150));
  EXPECT_EQ(params.size, Point(50, 50));
  StrokeParameters expected_stroke = {.width = 4.0f, .join = Join::kBevel};
  EXPECT_EQ(params.stroke, expected_stroke);
}

TEST(UberSDFParametersTest, MakeFillCircle) {
  Point center = {50, 50};
  auto params =
      UberSDFParameters::MakeCircle(Color::Red(), center, 10.0f, std::nullopt);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kCircle);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, center);
  EXPECT_EQ(params.size, Point(10.0f, 10.0f));
  EXPECT_FALSE(params.stroke.has_value());
}

TEST(UberSDFParametersTest, MakeStrokeCircle) {
  Point center = {50, 50};
  StrokeParameters stroke = {.width = 4.0f};
  auto params =
      UberSDFParameters::MakeCircle(Color::Red(), center, 10.0f, stroke);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kCircle);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, center);
  EXPECT_EQ(params.size, Point(10.0f, 10.0f));
  EXPECT_EQ(params.stroke, stroke);
}

TEST(UberSDFParametersTest, MakeFillOval) {
  Point center = {25, 25};
  Size size = Size(50, 50);
  Rect bounds = Rect::MakeOriginSize(Point(), size);

  auto params = UberSDFParameters::MakeOval(Color::Red(), bounds, std::nullopt);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kOval);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, center);
  EXPECT_EQ(params.size, Point(size) * 0.5f);
  EXPECT_FALSE(params.stroke.has_value());
}

TEST(UberSDFParametersTest, MakeStrokeOval) {
  Point center = {25, 25};
  Size size = Size(50, 50);
  Rect bounds = Rect::MakeOriginSize(Point(), size);
  StrokeParameters stroke = {.width = 4.0f};

  auto params = UberSDFParameters::MakeOval(Color::Red(), bounds, stroke);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kOval);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, center);
  EXPECT_EQ(params.size, Point(size) * 0.5f);
  EXPECT_EQ(params.stroke, stroke);
}

TEST(UberSDFParametersTest, MakeRoundedRect) {
  Rect rect = Rect::MakeXYWH(10, 20, 100, 100);
  RoundingRadii radii = {
      .top_left = Size(1.0f, 1.0f),
      .top_right = Size(2.0f, 2.0f),
      .bottom_left = Size(3.0f, 3.0f),
      .bottom_right = Size(4.0f, 4.0f),
  };
  auto params = UberSDFParameters::MakeRoundedRect(
      /*color=*/Color::Red(), /*rect=*/rect, /*radii=*/radii,
      /*stroke=*/std::nullopt);

  EXPECT_EQ(params.type, UberSDFParameters::Type::kRoundedRect);
  EXPECT_EQ(params.color, Color::Red());
  EXPECT_EQ(params.center, Point(60, 70));
  EXPECT_EQ(params.size, Point(50, 50));
  EXPECT_EQ(params.radii.top_left.width, 1.0f);
  EXPECT_EQ(params.radii.top_right.width, 2.0f);
  EXPECT_EQ(params.radii.bottom_left.width, 3.0f);
  EXPECT_EQ(params.radii.bottom_right.width, 4.0f);
  EXPECT_FALSE(params.stroke.has_value());
}

}  // namespace testing
}  // namespace impeller

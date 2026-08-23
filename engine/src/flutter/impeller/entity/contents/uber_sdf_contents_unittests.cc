// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/entity/contents/uber_sdf_contents.h"
#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/uber_sdf_geometry.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/size.h"

namespace impeller {
namespace testing {

TEST(UberSDFContentsTest, ApplyColorFilter) {
  auto rect = Rect::MakeXYWH(100, 100, 200, 200);
  auto params =
      UberSDFParameters::MakeRect(Color::Red(), rect, /*stroke=*/std::nullopt);
  auto geometry = std::make_unique<UberSDFGeometry>(params);
  auto contents = UberSDFContents::Make(params, std::move(geometry));

  EXPECT_EQ(contents->GetColor(), Color::Red());

  bool result =
      contents->ApplyColorFilter([](Color color) { return Color::Blue(); });

  EXPECT_TRUE(result);
  EXPECT_EQ(contents->GetColor(), Color::Blue());
}

TEST(UberSDFContentsTest, AsBackgroundColor) {
  auto rect = Rect::MakeXYWH(-2, -2, 504, 504);
  auto params =
      UberSDFParameters::MakeRect(Color::Red(), rect, /*stroke=*/std::nullopt);
  auto geometry = std::make_unique<UberSDFGeometry>(params);
  auto contents = UberSDFContents::Make(params, std::move(geometry));

  Entity entity;
  entity.SetTransform(Matrix());

  EXPECT_EQ(contents->AsBackgroundColor(entity, ISize(500, 500)), Color::Red());

  auto small_bg_color = contents->AsBackgroundColor(entity, ISize(400, 400));
  EXPECT_TRUE(small_bg_color.has_value());
  if (small_bg_color.has_value()) {
    EXPECT_EQ(small_bg_color.value(), Color::Red());
  }

  auto huge_bg_color = contents->AsBackgroundColor(entity, ISize(600, 600));
  EXPECT_FALSE(huge_bg_color.has_value());
}

TEST(UberSDFContentsTest, AsBackgroundColorExactSize) {
  auto rect = Rect::MakeXYWH(0, 0, 500, 500);
  auto params =
      UberSDFParameters::MakeRect(Color::Red(), rect, /*stroke=*/std::nullopt);
  auto geometry = std::make_unique<UberSDFGeometry>(params);
  auto contents = UberSDFContents::Make(params, std::move(geometry));

  Entity entity;
  entity.SetTransform(Matrix());

  auto bg_color = contents->AsBackgroundColor(entity, ISize(500, 500));
  // The exact size now returns true because over-conservative AA insets are
  // removed
  EXPECT_TRUE(bg_color.has_value());
  if (bg_color.has_value()) {
    EXPECT_EQ(bg_color.value(), Color::Red());
  }
}

TEST(UberSDFContentsTest, AsBackgroundColorNonRect) {
  Entity entity;
  entity.SetTransform(Matrix());

  // Non-rect shape (Circle) should return nullopt
  auto circle_params = UberSDFParameters::MakeCircle(
      Color::Red(), Point(250, 250), 250.0f, /*stroke=*/std::nullopt);
  auto circle_geometry = std::make_unique<UberSDFGeometry>(circle_params);
  auto circle_contents =
      UberSDFContents::Make(circle_params, std::move(circle_geometry));

  auto circle_bg_color =
      circle_contents->AsBackgroundColor(entity, ISize(500, 500));
  EXPECT_FALSE(circle_bg_color.has_value());
}

TEST(UberSDFContentsTest, AsBackgroundColorStrokedRect) {
  auto rect = Rect::MakeXYWH(-2, -2, 504, 504);
  auto params = UberSDFParameters::MakeRect(Color::Red(), rect,
                                            StrokeParameters{.width = 2.0f});
  auto geometry = std::make_unique<UberSDFGeometry>(params);
  auto contents = UberSDFContents::Make(params, std::move(geometry));

  Entity entity;
  entity.SetTransform(Matrix());

  auto bg_color = contents->AsBackgroundColor(entity, ISize(500, 500));
  EXPECT_FALSE(bg_color.has_value());
}

}  // namespace testing
}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/round_rect_geometry.h"
#include "impeller/entity/geometry/stroke_path_geometry.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/renderer/testing/mocks.h"

inline ::testing::AssertionResult SolidVerticesNear(
    std::vector<impeller::Point> a,
    std::vector<impeller::Point> b) {
  if (a.size() != b.size()) {
    return ::testing::AssertionFailure() << "Colors length does not match";
  }
  for (auto i = 0u; i < b.size(); i++) {
    if (!PointNear(a[i], b[i])) {
      return ::testing::AssertionFailure() << "Positions are not equal.";
    }
  }
  return ::testing::AssertionSuccess();
}

inline ::testing::AssertionResult TextureVerticesNear(
    std::vector<impeller::TextureFillVertexShader::PerVertexData> a,
    std::vector<impeller::TextureFillVertexShader::PerVertexData> b) {
  if (a.size() != b.size()) {
    return ::testing::AssertionFailure() << "Colors length does not match";
  }
  for (auto i = 0u; i < b.size(); i++) {
    if (!PointNear(a[i].position, b[i].position)) {
      return ::testing::AssertionFailure() << "Positions are not equal.";
    }
    if (!PointNear(a[i].texture_coords, b[i].texture_coords)) {
      return ::testing::AssertionFailure() << "Texture coords are not equal.";
    }
  }
  return ::testing::AssertionSuccess();
}

#define EXPECT_SOLID_VERTICES_NEAR(a, b) \
  EXPECT_PRED2(&::SolidVerticesNear, a, b)
#define EXPECT_TEXTURE_VERTICES_NEAR(a, b) \
  EXPECT_PRED2(&::TextureVerticesNear, a, b)

namespace impeller {

class ImpellerEntityUnitTestAccessor {
 public:
  static std::vector<Point> GenerateSolidStrokeVertices(
      const PathSource& path,
      const StrokeParameters& stroke,
      Scalar scale) {
    // We could create a single Tessellator instance for the whole suite,
    // but we don't really need performance for unit tests.
    Tessellator tessellator;
    return StrokePathGeometry::GenerateSolidStrokeVertices(  //
        tessellator, path, stroke, scale);
  }
};

namespace testing {

TEST(EntityGeometryTest, RectGeometryCoversArea) {
  auto geometry = Geometry::MakeRect(Rect::MakeLTRB(0, 0, 100, 100));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillPathGeometryCoversArea) {
  auto path = flutter::DlPathBuilder{}
                  .AddRect(Rect::MakeLTRB(0, 0, 100, 100))
                  .TakePath();
  auto geometry = Geometry::MakeFillPath(
      path, /* inner rect */ Rect::MakeLTRB(0, 0, 100, 100));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillPathGeometryCoversAreaNoInnerRect) {
  auto path = flutter::DlPathBuilder{}
                  .AddRect(Rect::MakeLTRB(0, 0, 100, 100))
                  .TakePath();
  auto geometry = Geometry::MakeFillPath(path);
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillArcGeometryCoverage) {
  Rect oval_bounds = Rect::MakeLTRB(100, 100, 200, 200);
  Matrix transform45 = Matrix::MakeTranslation(oval_bounds.GetCenter()) *
                       Matrix::MakeRotationZ(Degrees(45)) *
                       Matrix::MakeTranslation(-oval_bounds.GetCenter());

  {  // Sweeps <=-360 or >=360
    for (int start = -720; start <= 720; start += 10) {
      for (int sweep = 360; sweep <= 720; sweep += 30) {
        std::string label =
            "start: " + std::to_string(start) + " + " + std::to_string(sweep);
        auto geometry = Geometry::MakeFilledArc(oval_bounds, Degrees(start),
                                                Degrees(sweep), false);
        EXPECT_EQ(geometry->GetCoverage({}), oval_bounds)
            << "start: " << start << ", sweep: " << sweep;
        geometry = Geometry::MakeFilledArc(oval_bounds, Degrees(start),
                                           Degrees(-sweep), false);
        EXPECT_EQ(geometry->GetCoverage({}), oval_bounds)
            << "start: " << start << ", sweep: " << -sweep;
        geometry = Geometry::MakeFilledArc(oval_bounds, Degrees(start),
                                           Degrees(-sweep), true);
        EXPECT_EQ(geometry->GetCoverage({}), oval_bounds)
            << "start: " << start << ", sweep: " << -sweep << ", with center";
      }
    }
  }
  {  // Sweep from late in one quadrant to earlier in same quadrant
    for (int start = 60; start < 360; start += 90) {
      auto geometry = Geometry::MakeFilledArc(oval_bounds, Degrees(start),
                                              Degrees(330), false);
      EXPECT_EQ(geometry->GetCoverage({}), oval_bounds)
          << "start: " << start << " without center";
      geometry = Geometry::MakeFilledArc(oval_bounds, Degrees(start),
                                         Degrees(330), true);
      EXPECT_EQ(geometry->GetCoverage({}), oval_bounds)
          << "start: " << start << " with center";
    }
  }
  {  // Sweep from early in one quadrant backwards to later in same quadrant
    for (int start = 30; start < 360; start += 90) {
      auto geometry = Geometry::MakeFilledArc(oval_bounds, Degrees(start),
                                              Degrees(-330), false);
      EXPECT_EQ(geometry->GetCoverage({}), oval_bounds)
          << "start: " << start << " without center";
      geometry = Geometry::MakeFilledArc(oval_bounds, Degrees(start),
                                         Degrees(-330), true);
      EXPECT_EQ(geometry->GetCoverage({}), oval_bounds)
          << "start: " << start << " with center";
    }
  }
  {  // Sweep past each quadrant axis individually, no center
    for (int start = -360; start <= 720; start += 360) {
      {  // Quadrant 0
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start - 45), Degrees(90), false);
        Rect expected_bounds = Rect::MakeLTRB(150 + 50 * kSqrt2Over2,  //
                                              150 - 50 * kSqrt2Over2,  //
                                              200,                     //
                                              150 + 50 * kSqrt2Over2);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start - 45;
      }
      {  // Quadrant 1
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start + 45), Degrees(90), false);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2,  //
                                              150 + 50 * kSqrt2Over2,  //
                                              150 + 50 * kSqrt2Over2,  //
                                              200);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 45;
      }
      {  // Quadrant 2
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start + 135), Degrees(90), false);
        Rect expected_bounds = Rect::MakeLTRB(100,                     //
                                              150 - 50 * kSqrt2Over2,  //
                                              150 - 50 * kSqrt2Over2,  //
                                              150 + 50 * kSqrt2Over2);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 135;
      }
      {  // Quadrant 3
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start + 225), Degrees(90), false);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2,  //
                                              100,                     //
                                              150 + 50 * kSqrt2Over2,  //
                                              150 - 50 * kSqrt2Over2);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 225;
      }
    }
  }
  {  // Sweep past each quadrant axis individually, including the center
    for (int start = -360; start <= 720; start += 360) {
      {  // Quadrant 0
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start - 45), Degrees(90), true);
        Rect expected_bounds = Rect::MakeLTRB(150,                     //
                                              150 - 50 * kSqrt2Over2,  //
                                              200,                     //
                                              150 + 50 * kSqrt2Over2);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start - 45;
      }
      {  // Quadrant 1
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start + 45), Degrees(90), true);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2,  //
                                              150,                     //
                                              150 + 50 * kSqrt2Over2,  //
                                              200);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 45;
      }
      {  // Quadrant 2
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start + 135), Degrees(90), true);
        Rect expected_bounds = Rect::MakeLTRB(100,                     //
                                              150 - 50 * kSqrt2Over2,  //
                                              150,                     //
                                              150 + 50 * kSqrt2Over2);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 135;
      }
      {  // Quadrant 3
        auto geometry = Geometry::MakeFilledArc(
            oval_bounds, Degrees(start + 225), Degrees(90), true);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2,  //
                                              100,                     //
                                              150 + 50 * kSqrt2Over2,  //
                                              150);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 225;
      }
    }
  }
  {  // 45 degree tilted full circle
    auto geometry =
        Geometry::MakeFilledArc(oval_bounds, Degrees(0), Degrees(360), false);
    ASSERT_TRUE(oval_bounds.TransformBounds(transform45).Contains(oval_bounds));

    EXPECT_TRUE(geometry->GetCoverage(transform45)
                    .value_or(Rect())
                    .Contains(oval_bounds));
  }
  {  // 45 degree tilted mostly full circle
    auto geometry =
        Geometry::MakeFilledArc(oval_bounds, Degrees(3), Degrees(359), false);
    ASSERT_TRUE(oval_bounds.TransformBounds(transform45).Contains(oval_bounds));

    EXPECT_TRUE(geometry->GetCoverage(transform45)
                    .value_or(Rect())
                    .Contains(oval_bounds));
  }
}

TEST(EntityGeometryTest, StrokeArcGeometryCoverage) {
  Rect oval_bounds = Rect::MakeLTRB(100, 100, 200, 200);
  Rect expanded_bounds = Rect::MakeLTRB(95, 95, 205, 205);
  Rect squared_bounds = Rect::MakeLTRB(100 - 5 * kSqrt2, 100 - 5 * kSqrt2,
                                       200 + 5 * kSqrt2, 200 + 5 * kSqrt2);
  Matrix transform45 = Matrix::MakeTranslation(oval_bounds.GetCenter()) *
                       Matrix::MakeRotationZ(Degrees(45)) *
                       Matrix::MakeTranslation(-oval_bounds.GetCenter());

  StrokeParameters butt_params = {
      .width = 10.0f,
      .cap = Cap::kButt,
  };
  StrokeParameters square_params = {
      .width = 10.0f,
      .cap = Cap::kSquare,
  };

  {  // Sweeps <=-360 or >=360
    for (int start = -720; start <= 720; start += 10) {
      for (int sweep = 360; sweep <= 720; sweep += 30) {
        std::string label =
            "start: " + std::to_string(start) + " + " + std::to_string(sweep);
        auto geometry = Geometry::MakeStrokedArc(oval_bounds, Degrees(start),
                                                 Degrees(sweep), butt_params);
        EXPECT_EQ(geometry->GetCoverage({}), expanded_bounds)
            << "start: " << start << ", sweep: " << sweep;
        geometry = Geometry::MakeStrokedArc(oval_bounds, Degrees(start),
                                            Degrees(-sweep), butt_params);
        EXPECT_EQ(geometry->GetCoverage({}), expanded_bounds)
            << "start: " << start << ", sweep: " << -sweep;
        geometry = Geometry::MakeStrokedArc(oval_bounds, Degrees(start),
                                            Degrees(-sweep), square_params);
        EXPECT_EQ(geometry->GetCoverage({}), expanded_bounds)
            << "start: " << start << ", sweep: " << -sweep << ", square caps";
      }
    }
  }
  {  // Sweep from late in one quadrant to earlier in same quadrant
    for (int start = 60; start < 360; start += 90) {
      auto geometry = Geometry::MakeStrokedArc(oval_bounds, Degrees(start),
                                               Degrees(330), butt_params);
      EXPECT_EQ(geometry->GetCoverage({}), expanded_bounds)
          << "start: " << start << ", butt caps";
      geometry = Geometry::MakeStrokedArc(oval_bounds, Degrees(start),
                                          Degrees(330), square_params);
      EXPECT_EQ(geometry->GetCoverage({}), squared_bounds)
          << "start: " << start << ", square caps";
    }
  }
  {  // Sweep from early in one quadrant backwards to later in same quadrant
    for (int start = 30; start < 360; start += 90) {
      auto geometry = Geometry::MakeStrokedArc(oval_bounds, Degrees(start),
                                               Degrees(-330), butt_params);
      EXPECT_EQ(geometry->GetCoverage({}), expanded_bounds)
          << "start: " << start << " without center";
      geometry = Geometry::MakeStrokedArc(oval_bounds, Degrees(start),
                                          Degrees(-330), square_params);
      EXPECT_EQ(geometry->GetCoverage({}), squared_bounds)
          << "start: " << start << " with center";
    }
  }
  {  // Sweep past each quadrant axis individually with butt caps
    for (int start = -360; start <= 720; start += 360) {
      {  // Quadrant 0
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start - 45), Degrees(90), butt_params);
        Rect expected_bounds = Rect::MakeLTRB(150 + 50 * kSqrt2Over2 - 5,  //
                                              150 - 50 * kSqrt2Over2 - 5,  //
                                              205,                         //
                                              150 + 50 * kSqrt2Over2 + 5);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start - 45;
      }
      {  // Quadrant 1
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start + 45), Degrees(90), butt_params);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2 - 5,  //
                                              150 + 50 * kSqrt2Over2 - 5,  //
                                              150 + 50 * kSqrt2Over2 + 5,  //
                                              205);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 45;
      }
      {  // Quadrant 2
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start + 135), Degrees(90), butt_params);
        Rect expected_bounds = Rect::MakeLTRB(95,                          //
                                              150 - 50 * kSqrt2Over2 - 5,  //
                                              150 - 50 * kSqrt2Over2 + 5,  //
                                              150 + 50 * kSqrt2Over2 + 5);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 135;
      }
      {  // Quadrant 3
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start + 225), Degrees(90), butt_params);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2 - 5,  //
                                              95,                          //
                                              150 + 50 * kSqrt2Over2 + 5,  //
                                              150 - 50 * kSqrt2Over2 + 5);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 225;
      }
    }
  }
  {  // Sweep past each quadrant axis individually with square caps
    Scalar pad = 5 * kSqrt2;
    for (int start = -360; start <= 720; start += 360) {
      {  // Quadrant 0
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start - 45), Degrees(90), square_params);
        Rect expected_bounds = Rect::MakeLTRB(150 + 50 * kSqrt2Over2 - pad,  //
                                              150 - 50 * kSqrt2Over2 - pad,  //
                                              200 + pad,                     //
                                              150 + 50 * kSqrt2Over2 + pad);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start - 45;
      }
      {  // Quadrant 1
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start + 45), Degrees(90), square_params);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2 - pad,  //
                                              150 + 50 * kSqrt2Over2 - pad,  //
                                              150 + 50 * kSqrt2Over2 + pad,  //
                                              200 + pad);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 45;
      }
      {  // Quadrant 2
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start + 135), Degrees(90), square_params);
        Rect expected_bounds = Rect::MakeLTRB(100 - pad,                     //
                                              150 - 50 * kSqrt2Over2 - pad,  //
                                              150 - 50 * kSqrt2Over2 + pad,  //
                                              150 + 50 * kSqrt2Over2 + pad);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 135;
      }
      {  // Quadrant 3
        auto geometry = Geometry::MakeStrokedArc(
            oval_bounds, Degrees(start + 225), Degrees(90), square_params);
        Rect expected_bounds = Rect::MakeLTRB(150 - 50 * kSqrt2Over2 - pad,  //
                                              100 - pad,                     //
                                              150 + 50 * kSqrt2Over2 + pad,  //
                                              150 - 50 * kSqrt2Over2 + pad);
        EXPECT_RECT_NEAR(geometry->GetCoverage({}).value_or(Rect()),
                         expected_bounds)
            << "start: " << start + 225;
      }
    }
  }
  {  // 45 degree tilted full circle, butt caps
    auto geometry = Geometry::MakeStrokedArc(  //
        oval_bounds, Degrees(0), Degrees(360), butt_params);
    ASSERT_TRUE(
        oval_bounds.TransformBounds(transform45).Contains(expanded_bounds));

    EXPECT_TRUE(geometry->GetCoverage(transform45)
                    .value_or(Rect())
                    .Contains(expanded_bounds));
  }
  {  // 45 degree tilted full circle, square caps
    auto geometry = Geometry::MakeStrokedArc(  //
        oval_bounds, Degrees(0), Degrees(360), square_params);
    ASSERT_TRUE(
        oval_bounds.TransformBounds(transform45).Contains(expanded_bounds));

    EXPECT_TRUE(geometry->GetCoverage(transform45)
                    .value_or(Rect())
                    .Contains(squared_bounds));
  }
  {  // 45 degree tilted mostly full circle, butt caps
    auto geometry = Geometry::MakeStrokedArc(  //
        oval_bounds, Degrees(3), Degrees(359), butt_params);
    ASSERT_TRUE(
        oval_bounds.TransformBounds(transform45).Contains(expanded_bounds));

    EXPECT_TRUE(geometry->GetCoverage(transform45)
                    .value_or(Rect())
                    .Contains(expanded_bounds));
  }
  {  // 45 degree tilted mostly full circle, square caps
    auto geometry = Geometry::MakeStrokedArc(  //
        oval_bounds, Degrees(3), Degrees(359), square_params);
    ASSERT_TRUE(
        oval_bounds.TransformBounds(transform45).Contains(expanded_bounds));

    EXPECT_TRUE(geometry->GetCoverage(transform45)
                    .value_or(Rect())
                    .Contains(squared_bounds));
  }
}

TEST(EntityGeometryTest, FillRoundRectGeometryCoversArea) {
  Rect bounds = Rect::MakeLTRB(100, 100, 200, 200);
  RoundRect round_rect =
      RoundRect::MakeRectRadii(bounds, RoundingRadii{
                                           .top_left = Size(1, 11),
                                           .top_right = Size(2, 12),
                                           .bottom_left = Size(3, 13),
                                           .bottom_right = Size(4, 14),
                                       });
  FillRoundRectGeometry geom(round_rect);

  // Tall middle rect should barely be covered.
  EXPECT_TRUE(geom.CoversArea({}, Rect::MakeLTRB(103, 100, 196, 200)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(102, 100, 196, 200)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(103, 99, 196, 200)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(103, 100, 197, 200)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(103, 100, 196, 201)));

  // Wide middle rect should barely be covered.
  EXPECT_TRUE(geom.CoversArea({}, Rect::MakeLTRB(100, 112, 200, 186)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(99, 112, 200, 186)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(100, 111, 200, 186)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(100, 112, 201, 186)));
  EXPECT_FALSE(geom.CoversArea({}, Rect::MakeLTRB(100, 112, 200, 187)));
}

TEST(EntityGeometryTest, LineGeometryCoverage) {
  {
    auto geometry = Geometry::MakeLine(  //
        {10, 10}, {20, 10}, {.width = 2, .cap = Cap::kButt});
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(10, 9, 20, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(10, 9, 20, 11)));
  }

  {
    auto geometry = Geometry::MakeLine(  //
        {10, 10}, {20, 10}, {.width = 2, .cap = Cap::kSquare});
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 9, 21, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 9, 21, 11)));
  }

  {
    auto geometry = Geometry::MakeLine(  //
        {10, 10}, {10, 20}, {.width = 2, .cap = Cap::kButt});
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 10, 11, 20));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 10, 11, 20)));
  }

  {
    auto geometry = Geometry::MakeLine(  //
        {10, 10}, {10, 20}, {.width = 2, .cap = Cap::kSquare});
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 9, 11, 21));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 9, 11, 21)));
  }
}

TEST(EntityGeometryTest, RoundRectGeometryCoversArea) {
  auto geometry =
      Geometry::MakeRoundRect(Rect::MakeLTRB(0, 0, 100, 100), Size(20, 20));
  EXPECT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(15, 15, 85, 85)));
  EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(20, 20, 80, 80)));
  EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(30, 1, 70, 99)));
  EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 30, 99, 70)));
}

TEST(EntityGeometryTest, GeometryResultHasReasonableDefaults) {
  GeometryResult result;
  EXPECT_EQ(result.type, PrimitiveType::kTriangleStrip);
  EXPECT_EQ(result.transform, Matrix());
  EXPECT_EQ(result.mode, GeometryResult::Mode::kNormal);
}

TEST(EntityGeometryTest, AlphaCoverageStrokePaths) {
  auto matrix = Matrix::MakeScale(Vector2{3.0, 3.0});
  EXPECT_EQ(Geometry::MakeStrokePath({}, {.width = 0.5f})
                ->ComputeAlphaCoverage(matrix),
            1.0f);
  EXPECT_NEAR(Geometry::MakeStrokePath({}, {.width = 0.1f})
                  ->ComputeAlphaCoverage(matrix),
              0.6, 0.05);
  EXPECT_NEAR(Geometry::MakeStrokePath({}, {.width = 0.05})
                  ->ComputeAlphaCoverage(matrix),
              0.3, 0.05);
  EXPECT_NEAR(Geometry::MakeStrokePath({}, {.width = 0.01})
                  ->ComputeAlphaCoverage(matrix),
              0.1, 0.1);
  EXPECT_NEAR(Geometry::MakeStrokePath({}, {.width = 0.0000005f})
                  ->ComputeAlphaCoverage(matrix),
              1e-05, 0.001);
  EXPECT_EQ(Geometry::MakeStrokePath({}, {.width = 0.0f})
                ->ComputeAlphaCoverage(matrix),
            1.0f);
  EXPECT_EQ(Geometry::MakeStrokePath({}, {.width = 40.0f})
                ->ComputeAlphaCoverage(matrix),
            1.0f);
}

TEST(EntityGeometryTest, SimpleTwoLineStrokeVerticesButtCap) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.MoveTo({120, 20});
  path_builder.LineTo({130, 20});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 10.0f,
          .cap = Cap::kButt,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the first segment (20, 20) -> (30, 20)
      Point(20, 25),
      Point(20, 15),
      Point(30, 25),
      Point(30, 15),

      // The glue points that allow us to "pick up the pen" between segments
      Point(30, 20),
      Point(30, 20),
      Point(120, 20),
      Point(120, 20),

      // The points for the second segment (120, 20) -> (130, 20)
      Point(120, 25),
      Point(120, 15),
      Point(130, 25),
      Point(130, 15),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, SimpleTwoLineStrokeVerticesRoundCap) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.MoveTo({120, 20});
  path_builder.LineTo({130, 20});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 10.0f,
          .cap = Cap::kRound,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  size_t count = points.size();
  ASSERT_TRUE((count & 0x1) == 0x0);  // Should always be even

  // For a scale factor of 1.0 and a stroke width of 10.0 we currently
  // generate 40 total points for the 2 line segments based on the number
  // of quadrant circle divisions for a radius of 5.0
  //
  // If the number of points changes because of a change in the way we
  // compute circle divisions, we need to recompute the circular offsets
  ASSERT_EQ(points.size(), 40u);

  // Compute the indicated circular end cap offset based on the current
  // step out of 4 divisions [1, 2, 3] (not 0 or 4) based on whether this
  // is the left or right side of the path and whether this is a backwards
  // (starting) cap or a forwards (ending) cap.
  auto offset = [](int step, bool left, bool backwards) -> Point {
    Radians angle(kPiOver2 * (step / 4.0f));
    Point along = Point(5.0f, 0.0f) * std::cos(angle.radians);
    Point across = Point(0.0f, 5.0f) * std::sin(angle.radians);
    Point center = backwards ? -along : along;
    return left ? center + across : center - across;
  };

  // The points for the first segment (20, 20) -> (30, 20)
  EXPECT_EQ(points[0], Point(15, 20));
  EXPECT_EQ(points[1], Point(20, 20) + offset(1, true, true));
  EXPECT_EQ(points[2], Point(20, 20) + offset(1, false, true));
  EXPECT_EQ(points[3], Point(20, 20) + offset(2, true, true));
  EXPECT_EQ(points[4], Point(20, 20) + offset(2, false, true));
  EXPECT_EQ(points[5], Point(20, 20) + offset(3, true, true));
  EXPECT_EQ(points[6], Point(20, 20) + offset(3, false, true));
  EXPECT_EQ(points[7], Point(20, 25));
  EXPECT_EQ(points[8], Point(20, 15));
  EXPECT_EQ(points[9], Point(30, 25));
  EXPECT_EQ(points[10], Point(30, 15));
  EXPECT_EQ(points[11], Point(30, 20) + offset(3, true, false));
  EXPECT_EQ(points[12], Point(30, 20) + offset(3, false, false));
  EXPECT_EQ(points[13], Point(30, 20) + offset(2, true, false));
  EXPECT_EQ(points[14], Point(30, 20) + offset(2, false, false));
  EXPECT_EQ(points[15], Point(30, 20) + offset(1, true, false));
  EXPECT_EQ(points[16], Point(30, 20) + offset(1, false, false));
  EXPECT_EQ(points[17], Point(35, 20));

  // The glue points that allow us to "pick up the pen" between segments
  EXPECT_EQ(points[18], Point(30, 20));
  EXPECT_EQ(points[19], Point(30, 20));
  EXPECT_EQ(points[20], Point(120, 20));
  EXPECT_EQ(points[21], Point(120, 20));

  // The points for the second segment (120, 20) -> (130, 20)
  EXPECT_EQ(points[22], Point(115, 20));
  EXPECT_EQ(points[23], Point(120, 20) + offset(1, true, true));
  EXPECT_EQ(points[24], Point(120, 20) + offset(1, false, true));
  EXPECT_EQ(points[25], Point(120, 20) + offset(2, true, true));
  EXPECT_EQ(points[26], Point(120, 20) + offset(2, false, true));
  EXPECT_EQ(points[27], Point(120, 20) + offset(3, true, true));
  EXPECT_EQ(points[28], Point(120, 20) + offset(3, false, true));
  EXPECT_EQ(points[29], Point(120, 25));
  EXPECT_EQ(points[30], Point(120, 15));
  EXPECT_EQ(points[31], Point(130, 25));
  EXPECT_EQ(points[32], Point(130, 15));
  EXPECT_EQ(points[33], Point(130, 20) + offset(3, true, false));
  EXPECT_EQ(points[34], Point(130, 20) + offset(3, false, false));
  EXPECT_EQ(points[35], Point(130, 20) + offset(2, true, false));
  EXPECT_EQ(points[36], Point(130, 20) + offset(2, false, false));
  EXPECT_EQ(points[37], Point(130, 20) + offset(1, true, false));
  EXPECT_EQ(points[38], Point(130, 20) + offset(1, false, false));
  EXPECT_EQ(points[39], Point(135, 20));
}

TEST(EntityGeometryTest, SimpleTwoLineStrokeVerticesSquareCap) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.MoveTo({120, 20});
  path_builder.LineTo({130, 20});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 10.0f,
          .cap = Cap::kSquare,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  // clang-format off
  std::vector<Point> expected = {
      // The points for the first segment (20, 20) -> (30, 20)
      Point(15, 25),
      Point(15, 15),
      Point(20, 25),
      Point(20, 15),
      Point(30, 25),
      Point(30, 15),
      Point(35, 25),
      Point(35, 15),

      // The glue points that allow us to "pick up the pen" between segments
      Point(30, 20),
      Point(30, 20),
      Point(120, 20),
      Point(120, 20),

      // The points for the second segment (120, 20) -> (130, 20)
      Point(115, 25),
      Point(115, 15),
      Point(120, 25),
      Point(120, 15),
      Point(130, 25),
      Point(130, 15),
      Point(135, 25),
      Point(135, 15),
  };
  // clang-format on

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TwoLineSegmentsRightTurnStrokeVerticesBevelJoin) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 30});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 10.0f,
          .cap = Cap::kButt,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the first segment (20, 20) -> (30, 20)
      Point(20, 25),
      Point(20, 15),
      Point(30, 25),
      Point(30, 15),

      // The points for the second segment (120, 20) -> (130, 20)
      Point(25, 20),
      Point(35, 20),
      Point(25, 30),
      Point(35, 30),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TwoLineSegmentsLeftTurnStrokeVerticesBevelJoin) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 10});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 10.0f,
          .cap = Cap::kButt,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the first segment (20, 20) -> (30, 20)
      Point(20, 25),
      Point(20, 15),
      Point(30, 25),
      Point(30, 15),

      // The points for the second segment (120, 20) -> (130, 20)
      Point(35, 20),
      Point(25, 20),
      Point(35, 10),
      Point(25, 10),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TwoLineSegmentsRightTurnStrokeVerticesMiterJoin) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 30});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 10.0f,
          .cap = Cap::kButt,
          .join = Join::kMiter,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the first segment (20, 20) -> (30, 20)
      Point(20, 25),
      Point(20, 15),
      Point(30, 25),
      Point(30, 15),

      // And one point makes a Miter
      Point(35, 15),

      // The points for the second segment (120, 20) -> (130, 20)
      Point(25, 20),
      Point(35, 20),
      Point(25, 30),
      Point(35, 30),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TwoLineSegmentsLeftTurnStrokeVerticesMiterJoin) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 10});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 10.0f,
          .cap = Cap::kButt,
          .join = Join::kMiter,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the first segment (20, 20) -> (30, 20)
      Point(20, 25),
      Point(20, 15),
      Point(30, 25),
      Point(30, 15),

      // And one point makes a Miter
      Point(35, 25),

      // The points for the second segment (120, 20) -> (130, 20)
      Point(35, 20),
      Point(25, 20),
      Point(35, 10),
      Point(25, 10),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TinyQuadGeneratesCaps) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.QuadraticCurveTo({20.125, 20}, {20.250, 20});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 4.0f,
          .cap = Cap::kSquare,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the opening square cap
      Point(18, 22),
      Point(18, 18),

      // The points for the start of the curve
      Point(20, 22),
      Point(20, 18),

      // The points for the end of the curve
      Point(20.25, 22),
      Point(20.25, 18),

      // The points for the closing square cap
      Point(22.25, 22),
      Point(22.25, 18),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TinyConicGeneratesCaps) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.ConicCurveTo({20.125, 20}, {20.250, 20}, 0.6);
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 4.0f,
          .cap = Cap::kSquare,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the opening square cap
      Point(18, 22),
      Point(18, 18),

      // The points for the start of the curve
      Point(20, 22),
      Point(20, 18),

      // The points for the end of the curve
      Point(20.25, 22),
      Point(20.25, 18),

      // The points for the closing square cap
      Point(22.25, 22),
      Point(22.25, 18),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TinyCubicGeneratesCaps) {
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.CubicCurveTo({20.0625, 20}, {20.125, 20}, {20.250, 20});
  flutter::DlPath path = path_builder.TakePath();

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path,
      {
          .width = 4.0f,
          .cap = Cap::kSquare,
          .join = Join::kBevel,
          .miter_limit = 4.0f,
      },
      1.0f);

  std::vector<Point> expected = {
      // The points for the opening square cap
      Point(18, 22),
      Point(18, 18),

      // The points for the start of the curve
      Point(20, 22),
      Point(20, 18),

      // The points for the end of the curve
      Point(20.25, 22),
      Point(20.25, 18),

      // The points for the closing square cap
      Point(22.25, 22),
      Point(22.25, 18),
  };

  EXPECT_EQ(points, expected);
}

TEST(EntityGeometryTest, TwoLineSegmentsMiterLimit) {
  // degrees is the angle that the line deviates from "straight ahead"
  for (int degrees = 10; degrees < 180; degrees += 10) {
    // Start with a width of 2 since line widths of 1 usually decide
    // that they don't need join geometry at a scale of 1.0
    for (int width = 2; width <= 10; width++) {
      Degrees d(degrees);
      Radians r(d);
      Point pixel_delta = Point(std::cos(r.radians), std::sin(r.radians));

      if (pixel_delta.GetDistance(Point(1, 0)) * width < 1.0f) {
        // Some combinations of angle and width result in a join that is
        // less than a pixel in size. We don't care about compliance on
        // such a small join delta (and, in fact, the implementation may
        // decide to elide those small joins).
        continue;
      }

      // Miter limits are based on angle between the vectors/segments
      Degrees between(180 - degrees);
      Radians r_between(between);
      Scalar limit = 1.0f / std::sin(r_between.radians / 2.0f);

      flutter::DlPathBuilder path_builder;
      path_builder.MoveTo(Point(20, 20));
      path_builder.LineTo(Point(30, 20));
      path_builder.LineTo(Point(30, 20) + pixel_delta * 10.0f);
      flutter::DlPath path = path_builder.TakePath();

      // Miter limit too small (99% of required) to allow a miter
      auto points1 =
          ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
              path,
              {
                  .width = static_cast<Scalar>(width),
                  .cap = Cap::kButt,
                  .join = Join::kMiter,
                  .miter_limit = limit * 0.99f,
              },
              1.0f);
      EXPECT_EQ(points1.size(), 8u)
          << "degrees: " << degrees << ", width: " << width << ", "
          << points1[4];

      // Miter limit large enough (101% of required) to allow a miter
      auto points2 =
          ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
              path,
              {
                  .width = static_cast<Scalar>(width),
                  .cap = Cap::kButt,
                  .join = Join::kMiter,
                  .miter_limit = limit * 1.01f,
              },
              1.0f);
      EXPECT_EQ(points2.size(), 9u)
          << "degrees: " << degrees << ", width: " << width;
      EXPECT_LE(points2[4].GetDistance({30, 20}), width * limit * 1.05f)
          << "degrees: " << degrees << ", width: " << width << ", "
          << points2[4];
    }
  }
}

TEST(EntityGeometryTest, TwoLineSegments180DegreeJoins) {
  // First, create a path that doubles back on itself.
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.LineTo(Point(100, 10));
  path_builder.LineTo(Point(10, 10));
  flutter::DlPath path = path_builder.TakePath();

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kBevel,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates no join - because it is a bevel join
  EXPECT_EQ(points_bevel.size(), 8u);

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kMiter,
              .miter_limit = 400.0f,
          },
          1.0f);
  // Generates no join - even with a very large miter limit
  EXPECT_EQ(points_miter.size(), 8u);

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kRound,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates lots of join points - to round off the 180 degree bend
  EXPECT_EQ(points_round.size(), 19u);
}

TEST(EntityGeometryTest, TightQuadratic180DegreeJoins) {
  // First, create a mild quadratic that helps us verify how many points
  // should normally be on a quad with 2 legs of length 90.
  flutter::DlPathBuilder path_builder_refrence;
  path_builder_refrence.MoveTo(Point(10, 10));
  path_builder_refrence.QuadraticCurveTo(Point(100, 10), Point(100, 100));
  flutter::DlPath path_reference = path_builder_refrence.TakePath();

  auto points_bevel_reference =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path_reference,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kBevel,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates no joins because the curve is smooth
  EXPECT_EQ(points_bevel_reference.size(), 74u);

  // Now create a path that doubles back on itself with a quadratic.
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.QuadraticCurveTo(Point(100, 10), Point(10, 10));
  flutter::DlPath path = path_builder.TakePath();

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kBevel,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_bevel.size(), points_bevel_reference.size());

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kMiter,
              .miter_limit = 400.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_miter.size(), points_bevel_reference.size());

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kRound,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_round.size(), points_bevel_reference.size());
}

TEST(EntityGeometryTest, TightConic180DegreeJoins) {
  // First, create a mild conic that helps us verify how many points
  // should normally be on a quad with 2 legs of length 90.
  flutter::DlPathBuilder path_builder_refrence;
  path_builder_refrence.MoveTo(Point(10, 10));
  path_builder_refrence.ConicCurveTo(Point(100, 10), Point(100, 100), 0.9f);
  flutter::DlPath path_reference = path_builder_refrence.TakePath();

  auto points_bevel_reference =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path_reference,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kBevel,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates no joins because the curve is smooth
  EXPECT_EQ(points_bevel_reference.size(), 78u);

  // Now create a path that doubles back on itself with a conic.
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.QuadraticCurveTo(Point(100, 10), Point(10, 10));
  flutter::DlPath path = path_builder.TakePath();

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kBevel,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_bevel.size(), points_bevel_reference.size());

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kMiter,
              .miter_limit = 400.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_miter.size(), points_bevel_reference.size());

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kRound,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_round.size(), points_bevel_reference.size());
}

TEST(EntityGeometryTest, TightCubic180DegreeJoins) {
  // First, create a mild cubic that helps us verify how many points
  // should normally be on a quad with 3 legs of length ~50.
  flutter::DlPathBuilder path_builder_reference;
  path_builder_reference.MoveTo(Point(10, 10));
  path_builder_reference.CubicCurveTo(Point(60, 10), Point(100, 40),
                                      Point(100, 90));
  flutter::DlPath path_reference = path_builder_reference.TakePath();

  auto points_reference =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path_reference,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kBevel,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates no joins because the curve is smooth
  EXPECT_EQ(points_reference.size(), 76u);

  // Now create a path that doubles back on itself with a cubic.
  flutter::DlPathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.CubicCurveTo(Point(60, 10), Point(100, 40), Point(60, 10));
  flutter::DlPath path = path_builder.TakePath();

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kBevel,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_bevel.size(), points_reference.size());

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kMiter,
              .miter_limit = 400.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_miter.size(), points_reference.size());

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path,
          {
              .width = 20.0f,
              .cap = Cap::kButt,
              .join = Join::kRound,
              .miter_limit = 4.0f,
          },
          1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_round.size(), points_reference.size());
}

TEST(EntityGeometryTest, RotatedFilledCircleGeometryCoverage) {
  Point center = Point(50, 50);
  auto geometry = Geometry::MakeCircle(center, 50);
  Rect circle_bounds = Rect::MakeLTRB(0, 0, 100, 100);
  ASSERT_EQ(geometry->GetCoverage({}).value_or(Rect()), circle_bounds);

  Matrix transform45 = Matrix::MakeTranslation(center) *
                       Matrix::MakeRotationZ(Degrees(45)) *
                       Matrix::MakeTranslation(-center);

  EXPECT_TRUE(geometry->GetCoverage(transform45).has_value());
  Rect bounds = geometry->GetCoverage(transform45).value_or(Rect());
  EXPECT_TRUE(bounds.Contains(circle_bounds))
      << "geometry bounds: " << bounds << std::endl
      << "  circle bounds: " << circle_bounds;
}

TEST(EntityGeometryTest, RotatedStrokedCircleGeometryCoverage) {
  Point center = Point(50, 50);
  auto geometry = Geometry::MakeStrokedCircle(center, 50, 10);
  Rect circle_bounds = Rect::MakeLTRB(0, 0, 100, 100).Expand(5);
  ASSERT_EQ(geometry->GetCoverage({}).value_or(Rect()), circle_bounds);

  Matrix transform45 = Matrix::MakeTranslation(center) *
                       Matrix::MakeRotationZ(Degrees(45)) *
                       Matrix::MakeTranslation(-center);

  EXPECT_TRUE(geometry->GetCoverage(transform45).has_value());
  Rect bounds = geometry->GetCoverage(transform45).value_or(Rect());
  EXPECT_TRUE(bounds.Contains(circle_bounds))
      << "geometry bounds: " << bounds << std::endl
      << "  circle bounds: " << circle_bounds;
}

}  // namespace testing
}  // namespace impeller

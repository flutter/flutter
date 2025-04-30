// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/testing/testing.h"
#include "gtest/gtest.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/stroke_path_geometry.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/path_builder.h"
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
  static std::vector<Point> GenerateSolidStrokeVertices(const PathSource& path,
                                                        Scalar stroke_width,
                                                        Scalar miter_limit,
                                                        Join stroke_join,
                                                        Cap stroke_cap,
                                                        Scalar scale) {
    return StrokePathGeometry::GenerateSolidStrokeVertices(
        path, stroke_width, miter_limit, stroke_join, stroke_cap, scale);
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
  auto path = PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath();
  auto geometry = Geometry::MakeFillPath(
      path, /* inner rect */ Rect::MakeLTRB(0, 0, 100, 100));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_TRUE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, FillPathGeometryCoversAreaNoInnerRect) {
  auto path = PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath();
  auto geometry = Geometry::MakeFillPath(path);
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(0, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(-1, 0, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect::MakeLTRB(1, 1, 100, 100)));
  ASSERT_FALSE(geometry->CoversArea({}, Rect()));
}

TEST(EntityGeometryTest, LineGeometryCoverage) {
  {
    auto geometry = Geometry::MakeLine({10, 10}, {20, 10}, 2, Cap::kButt);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(10, 9, 20, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(10, 9, 20, 11)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {20, 10}, 2, Cap::kSquare);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 9, 21, 11));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 9, 21, 11)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {10, 20}, 2, Cap::kButt);
    EXPECT_EQ(geometry->GetCoverage({}), Rect::MakeLTRB(9, 10, 11, 20));
    EXPECT_TRUE(geometry->CoversArea({}, Rect::MakeLTRB(9, 10, 11, 20)));
  }

  {
    auto geometry = Geometry::MakeLine({10, 10}, {10, 20}, 2, Cap::kSquare);
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
  EXPECT_EQ(Geometry::MakeStrokePath({}, 0.5)->ComputeAlphaCoverage(matrix), 1);
  EXPECT_NEAR(Geometry::MakeStrokePath({}, 0.1)->ComputeAlphaCoverage(matrix),
              0.6, 0.05);
  EXPECT_NEAR(Geometry::MakeStrokePath({}, 0.05)->ComputeAlphaCoverage(matrix),
              0.3, 0.05);
  EXPECT_NEAR(Geometry::MakeStrokePath({}, 0.01)->ComputeAlphaCoverage(matrix),
              0.1, 0.1);
  EXPECT_NEAR(
      Geometry::MakeStrokePath({}, 0.0000005)->ComputeAlphaCoverage(matrix),
      1e-05, 0.001);
  EXPECT_EQ(Geometry::MakeStrokePath({}, 0)->ComputeAlphaCoverage(matrix), 1);
  EXPECT_EQ(Geometry::MakeStrokePath({}, 40)->ComputeAlphaCoverage(matrix), 1);
}

TEST(EntityGeometryTest, SimpleTwoLineStrokeVerticesButtCap) {
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.MoveTo({120, 20});
  path_builder.LineTo({130, 20});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 10.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.MoveTo({120, 20});
  path_builder.LineTo({130, 20});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 10.0f, 4.0f, Join::kBevel, Cap::kRound, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.MoveTo({120, 20});
  path_builder.LineTo({130, 20});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 10.0f, 4.0f, Join::kBevel, Cap::kSquare, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 30});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 10.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 10});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 10.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 30});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 10.0f, 4.0f, Join::kMiter, Cap::kButt, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.LineTo({30, 20});
  path_builder.LineTo({30, 10});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 10.0f, 4.0f, Join::kMiter, Cap::kButt, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.QuadraticCurveTo({20.125, 20}, {20.250, 20});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 4.0f, 4.0f, Join::kBevel, Cap::kSquare, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.ConicCurveTo({20.125, 20}, {20.250, 20}, 0.6);
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 4.0f, 4.0f, Join::kBevel, Cap::kSquare, 1.0f);

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
  PathBuilder path_builder;
  path_builder.MoveTo({20, 20});
  path_builder.CubicCurveTo({20.0625, 20}, {20.125, 20}, {20.250, 20});
  flutter::DlPath path(path_builder);

  auto points = ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
      path, 4.0f, 4.0f, Join::kBevel, Cap::kSquare, 1.0f);

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

      PathBuilder path_builder;
      path_builder.MoveTo(Point(20, 20));
      path_builder.LineTo(Point(30, 20));
      path_builder.LineTo(Point(30, 20) + pixel_delta * 10.0f);
      flutter::DlPath path(path_builder);

      // Miter limit too small (99% of required) to allow a miter
      auto points1 =
          ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
              path, width, limit * 0.99f, Join::kMiter, Cap::kButt, 1.0f);
      EXPECT_EQ(points1.size(), 8u)
          << "degrees: " << degrees << ", width: " << width << ", "
          << points1[4];

      // Miter limit large enough (101% of required) to allow a miter
      auto points2 =
          ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
              path, width, limit * 1.01f, Join::kMiter, Cap::kButt, 1.0f);
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
  PathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.LineTo(Point(100, 10));
  path_builder.LineTo(Point(10, 10));
  flutter::DlPath path(path_builder);

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);
  // Generates no join - because it is a bevel join
  EXPECT_EQ(points_bevel.size(), 8u);

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 400.0f, Join::kMiter, Cap::kButt, 1.0f);
  // Generates no join - even with a very large miter limit
  EXPECT_EQ(points_miter.size(), 8u);

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kRound, Cap::kButt, 1.0f);
  // Generates lots of join points - to round off the 180 degree bend
  EXPECT_EQ(points_round.size(), 19u);
}

TEST(EntityGeometryTest, TightQuadratic180DegreeJoins) {
  // First, create a mild quadratic that helps us verify how many points
  // should normally be on a quad with 2 legs of length 90.
  PathBuilder path_builder_refrence;
  path_builder_refrence.MoveTo(Point(10, 10));
  path_builder_refrence.QuadraticCurveTo(Point(100, 10), Point(100, 100));
  flutter::DlPath path_reference(path_builder_refrence);

  auto points_bevel_reference =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path_reference, 20.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);
  // Generates no joins because the curve is smooth
  EXPECT_EQ(points_bevel_reference.size(), 74u);

  // Now create a path that doubles back on itself with a quadratic.
  PathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.QuadraticCurveTo(Point(100, 10), Point(10, 10));
  flutter::DlPath path(path_builder);

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_bevel.size(), points_bevel_reference.size());

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 400.0f, Join::kMiter, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_miter.size(), points_bevel_reference.size());

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kRound, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_round.size(), points_bevel_reference.size());
}

TEST(EntityGeometryTest, TightConic180DegreeJoins) {
  // First, create a mild conic that helps us verify how many points
  // should normally be on a quad with 2 legs of length 90.
  PathBuilder path_builder_refrence;
  path_builder_refrence.MoveTo(Point(10, 10));
  path_builder_refrence.ConicCurveTo(Point(100, 10), Point(100, 100), 0.9f);
  flutter::DlPath path_reference(path_builder_refrence);

  auto points_bevel_reference =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path_reference, 20.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);
  // Generates no joins because the curve is smooth
  EXPECT_EQ(points_bevel_reference.size(), 78u);

  // Now create a path that doubles back on itself with a conic.
  PathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.QuadraticCurveTo(Point(100, 10), Point(10, 10));
  flutter::DlPath path(path_builder);

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_bevel.size(), points_bevel_reference.size());

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 400.0f, Join::kMiter, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_miter.size(), points_bevel_reference.size());

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kRound, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_round.size(), points_bevel_reference.size());
}

TEST(EntityGeometryTest, TightCubic180DegreeJoins) {
  // First, create a mild cubic that helps us verify how many points
  // should normally be on a quad with 3 legs of length ~50.
  PathBuilder path_builder_reference;
  path_builder_reference.MoveTo(Point(10, 10));
  path_builder_reference.CubicCurveTo(Point(60, 10), Point(100, 40),
                                      Point(100, 90));
  flutter::DlPath path_reference(path_builder_reference);

  auto points_reference =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path_reference, 20.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);
  // Generates no joins because the curve is smooth
  EXPECT_EQ(points_reference.size(), 80u);

  // Now create a path that doubles back on itself with a cubic.
  PathBuilder path_builder;
  path_builder.MoveTo(Point(10, 10));
  path_builder.CubicCurveTo(Point(60, 10), Point(100, 40), Point(60, 10));
  flutter::DlPath path(path_builder);

  auto points_bevel =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kBevel, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_bevel.size(), points_reference.size());

  auto points_miter =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 400.0f, Join::kMiter, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_miter.size(), points_reference.size());

  auto points_round =
      ImpellerEntityUnitTestAccessor::GenerateSolidStrokeVertices(
          path, 20.0f, 4.0f, Join::kRound, Cap::kButt, 1.0f);
  // Generates round join because it is in the middle of a curved segment
  EXPECT_GT(points_round.size(), points_reference.size());
}

}  // namespace testing
}  // namespace impeller

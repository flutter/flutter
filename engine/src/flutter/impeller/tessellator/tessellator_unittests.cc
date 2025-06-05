// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

#include "flutter/display_list/geometry/dl_path_builder.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/tessellator/tessellator.h"
#include "impeller/tessellator/tessellator_libtess.h"

namespace impeller {
namespace testing {

TEST(TessellatorTest, TessellatorBuilderReturnsCorrectResultStatus) {
  // Zero points.
  {
    TessellatorLibtess t;
    auto path = flutter::DlPathBuilder{}  //
                    .SetFillType(FillType::kOdd)
                    .TakePath();
    TessellatorLibtess::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, TessellatorLibtess::Result::kInputError);
  }

  // One point.
  {
    TessellatorLibtess t;
    auto path = flutter::DlPathBuilder{}
                    .LineTo({0, 0})
                    .SetFillType(FillType::kOdd)
                    .TakePath();
    TessellatorLibtess::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, TessellatorLibtess::Result::kSuccess);
  }

  // Two points.
  {
    TessellatorLibtess t;
    auto path = flutter::DlPathBuilder{}
                    .MoveTo({0, 0})
                    .LineTo({0, 1})
                    .SetFillType(FillType::kOdd)
                    .TakePath();
    TessellatorLibtess::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, TessellatorLibtess::Result::kSuccess);
  }

  // Many points.
  {
    TessellatorLibtess t;
    flutter::DlPathBuilder builder;
    for (int i = 0; i < 1000; i++) {
      auto coord = i * 1.0f;
      builder.MoveTo({coord, coord}).LineTo({coord + 1, coord + 1});
    }
    auto path = builder.SetFillType(FillType::kOdd).TakePath();
    TessellatorLibtess::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, TessellatorLibtess::Result::kSuccess);
  }

  // Closure fails.
  {
    TessellatorLibtess t;
    auto path = flutter::DlPathBuilder{}
                    .MoveTo({0, 0})
                    .LineTo({0, 1})
                    .SetFillType(FillType::kOdd)
                    .TakePath();
    TessellatorLibtess::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return false; });

    ASSERT_EQ(result, TessellatorLibtess::Result::kInputError);
  }
}

TEST(TessellatorTest, TessellateConvex) {
  {
    std::vector<Point> points;
    std::vector<uint16_t> indices;
    // Sanity check simple rectangle.
    Tessellator::TessellateConvexInternal(
        flutter::DlPath::MakeRect(Rect::MakeLTRB(0, 0, 10, 10)), points,
        indices, 1.0);

    // Note: the origin point is repeated but not referenced in the indices
    // below
    std::vector<Point> expected = {{0, 0}, {10, 0}, {10, 10}, {0, 10}, {0, 0}};
    std::vector<uint16_t> expected_indices = {0, 1, 3, 2};
    EXPECT_EQ(points, expected);
    EXPECT_EQ(indices, expected_indices);
  }

  {
    std::vector<Point> points;
    std::vector<uint16_t> indices;
    Tessellator::TessellateConvexInternal(
        flutter::DlPath(flutter::DlPathBuilder{}
                            .AddRect(Rect::MakeLTRB(0, 0, 10, 10))
                            .AddRect(Rect::MakeLTRB(20, 20, 30, 30))
                            .TakePath()),
        points, indices, 1.0);

    std::vector<Point> expected = {{0, 0},   {10, 0},  {10, 10}, {0, 10},
                                   {0, 0},   {20, 20}, {30, 20}, {30, 30},
                                   {20, 30}, {20, 20}};
    std::vector<uint16_t> expected_indices = {0, 1, 3, 2, 2, 5, 5, 6, 8, 7};
    EXPECT_EQ(points, expected);
    EXPECT_EQ(indices, expected_indices);
  }
}

// Filled Paths without an explicit close should still be closed implicitly
TEST(TessellatorTest, TessellateConvexUnclosedPath) {
  std::vector<Point> points;
  std::vector<uint16_t> indices;

  // Create a rectangle that lacks an explicit close.
  flutter::DlPath path = flutter::DlPathBuilder{}
                             .LineTo({100, 0})
                             .LineTo({100, 100})
                             .LineTo({0, 100})
                             .TakePath();
  Tessellator::TessellateConvexInternal(flutter::DlPath(path), points, indices,
                                        1.0);

  std::vector<Point> expected = {
      {0, 0}, {100, 0}, {100, 100}, {0, 100}, {0, 0}};
  std::vector<uint16_t> expected_indices = {0, 1, 3, 2};
  EXPECT_EQ(points, expected);
  EXPECT_EQ(indices, expected_indices);
}

TEST(TessellatorTest, CircleVertexCounts) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](const Matrix& transform, Scalar radius) {
    auto generator = tessellator->FilledCircle(transform, {}, radius);
    size_t quadrant_divisions = generator.GetVertexCount() / 4;

    // Confirm the approximation error is within the currently accepted
    // |kCircleTolerance| value advertised by |CircleTessellator|.
    // (With an additional 1% tolerance for floating point rounding.)
    double angle = kPiOver2 / quadrant_divisions;
    Point first = {radius, 0};
    Point next = {static_cast<Scalar>(cos(angle) * radius),
                  static_cast<Scalar>(sin(angle) * radius)};
    Point midpoint = (first + next) * 0.5;
    EXPECT_GE(midpoint.GetLength(),
              radius - Tessellator::kCircleTolerance * 1.01)
        << ", transform = " << transform << ", radius = " << radius
        << ", divisions = " << quadrant_divisions;
  };

  test({}, 0.0);
  test({}, 0.9);
  test({}, 1.0);
  test({}, 1.9);
  test(Matrix::MakeScale(Vector2(2.0, 2.0)), 0.95);
  test({}, 2.0);
  test(Matrix::MakeScale(Vector2(2.0, 2.0)), 1.0);
  test({}, 11.9);
  test({}, 12.0);
  test({}, 35.9);
  for (int i = 36; i < 10000; i += 4) {
    test({}, i);
  }
}

TEST(TessellatorTest, FilledCircleTessellationVertices) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](const Matrix& transform, const Point& center,
                             Scalar radius) {
    auto generator = tessellator->FilledCircle(transform, center, radius);
    EXPECT_EQ(generator.GetTriangleType(), PrimitiveType::kTriangleStrip);

    auto vertex_count = generator.GetVertexCount();
    auto vertices = std::vector<Point>();
    generator.GenerateVertices([&vertices](const Point& p) {  //
      vertices.push_back(p);
    });
    EXPECT_EQ(vertices.size(), vertex_count);
    ASSERT_EQ(vertex_count % 4, 0u);

    auto quadrant_count = vertex_count / 4;
    for (size_t i = 0; i < quadrant_count; i++) {
      double angle = kPiOver2 * i / (quadrant_count - 1);
      double degrees = angle * 180.0 / kPi;
      double rsin = sin(angle) * radius;
      // Note that cos(radians(90 degrees)) isn't exactly 0.0 like it should be
      double rcos = (i == quadrant_count - 1) ? 0.0f : cos(angle) * radius;
      EXPECT_POINT_NEAR(vertices[i * 2],
                        Point(center.x - rcos, center.y + rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[i * 2 + 1],
                        Point(center.x - rcos, center.y - rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 1],
                        Point(center.x + rcos, center.y - rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 2],
                        Point(center.x + rcos, center.y + rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
    }
  };

  test({}, {}, 2.0);
  test({}, {10, 10}, 2.0);
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), {}, 2.0);
  test(Matrix::MakeScale({0.002, 0.002, 0.0}), {}, 1000.0);
}

TEST(TessellatorTest, StrokedCircleTessellationVertices) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](const Matrix& transform, const Point& center,
                             Scalar radius, Scalar half_width) {
    ASSERT_GT(radius, half_width);
    auto generator =
        tessellator->StrokedCircle(transform, center, radius, half_width);
    EXPECT_EQ(generator.GetTriangleType(), PrimitiveType::kTriangleStrip);

    auto vertex_count = generator.GetVertexCount();
    auto vertices = std::vector<Point>();
    generator.GenerateVertices([&vertices](const Point& p) {  //
      vertices.push_back(p);
    });
    EXPECT_EQ(vertices.size(), vertex_count);
    ASSERT_EQ(vertex_count % 4, 0u);

    auto quadrant_count = vertex_count / 8;

    // Test outer points first
    for (size_t i = 0; i < quadrant_count; i++) {
      double angle = kPiOver2 * i / (quadrant_count - 1);
      double degrees = angle * 180.0 / kPi;
      double rsin = sin(angle) * (radius + half_width);
      // Note that cos(radians(90 degrees)) isn't exactly 0.0 like it should be
      double rcos =
          (i == quadrant_count - 1) ? 0.0f : cos(angle) * (radius + half_width);
      EXPECT_POINT_NEAR(vertices[i * 2],
                        Point(center.x - rcos, center.y - rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[quadrant_count * 2 + i * 2],
                        Point(center.x + rsin, center.y - rcos))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[quadrant_count * 4 + i * 2],
                        Point(center.x + rcos, center.y + rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[quadrant_count * 6 + i * 2],
                        Point(center.x - rsin, center.y + rcos))
          << "vertex " << i << ", angle = " << degrees << std::endl;
    }

    // Then test innerer points
    for (size_t i = 0; i < quadrant_count; i++) {
      double angle = kPiOver2 * i / (quadrant_count - 1);
      double degrees = angle * 180.0 / kPi;
      double rsin = sin(angle) * (radius - half_width);
      // Note that cos(radians(90 degrees)) isn't exactly 0.0 like it should be
      double rcos =
          (i == quadrant_count - 1) ? 0.0f : cos(angle) * (radius - half_width);
      EXPECT_POINT_NEAR(vertices[i * 2 + 1],
                        Point(center.x - rcos, center.y - rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[quadrant_count * 2 + i * 2 + 1],
                        Point(center.x + rsin, center.y - rcos))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[quadrant_count * 4 + i * 2 + 1],
                        Point(center.x + rcos, center.y + rsin))
          << "vertex " << i << ", angle = " << degrees << std::endl;
      EXPECT_POINT_NEAR(vertices[quadrant_count * 6 + i * 2 + 1],
                        Point(center.x - rsin, center.y + rcos))
          << "vertex " << i << ", angle = " << degrees << std::endl;
    }
  };

  test({}, {}, 2.0, 1.0);
  test({}, {}, 2.0, 0.5);
  test({}, {10, 10}, 2.0, 1.0);
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), {}, 2.0, 1.0);
  test(Matrix::MakeScale({0.002, 0.002, 0.0}), {}, 1000.0, 10.0);
}

TEST(TessellatorTest, RoundCapLineTessellationVertices) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](const Matrix& transform, const Point& p0,
                             const Point& p1, Scalar radius) {
    auto generator = tessellator->RoundCapLine(transform, p0, p1, radius);
    EXPECT_EQ(generator.GetTriangleType(), PrimitiveType::kTriangleStrip);

    auto vertex_count = generator.GetVertexCount();
    auto vertices = std::vector<Point>();
    generator.GenerateVertices([&vertices](const Point& p) {  //
      vertices.push_back(p);
    });
    EXPECT_EQ(vertices.size(), vertex_count);
    ASSERT_EQ(vertex_count % 4, 0u);

    Point along = p1 - p0;
    Scalar length = along.GetLength();
    if (length > 0) {
      along *= radius / length;
    } else {
      along = {radius, 0};
    }
    Point across = {-along.y, along.x};

    auto quadrant_count = vertex_count / 4;
    for (size_t i = 0; i < quadrant_count; i++) {
      double angle = kPiOver2 * i / (quadrant_count - 1);
      double degrees = angle * 180.0 / kPi;
      // Note that cos(radians(90 degrees)) isn't exactly 0.0 like it should be
      Point relative_along =
          along * ((i == quadrant_count - 1) ? 0.0f : cos(angle));
      Point relative_across = across * sin(angle);
      EXPECT_POINT_NEAR(vertices[i * 2],  //
                        p0 - relative_along + relative_across)
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "line = " << p0 << " => " << p1 << ", "            //
          << "radius = " << radius << std::endl;
      EXPECT_POINT_NEAR(vertices[i * 2 + 1],  //
                        p0 - relative_along - relative_across)
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "line = " << p0 << " => " << p1 << ", "            //
          << "radius = " << radius << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 1],  //
                        p1 + relative_along - relative_across)
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "line = " << p0 << " => " << p1 << ", "            //
          << "radius = " << radius << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 2],  //
                        p1 + relative_along + relative_across)
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "line = " << p0 << " => " << p1 << ", "            //
          << "radius = " << radius << std::endl;
    }
  };

  // Empty line should actually use the circle generator, but its
  // results should match the same math as the round cap generator.
  test({}, {0, 0}, {0, 0}, 10);

  test({}, {0, 0}, {10, 0}, 2);
  test({}, {10, 0}, {0, 0}, 2);
  test({}, {0, 0}, {10, 10}, 2);

  test(Matrix::MakeScale({500.0, 500.0, 0.0}), {0, 0}, {10, 0}, 2);
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), {10, 0}, {0, 0}, 2);
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), {0, 0}, {10, 10}, 2);

  test(Matrix::MakeScale({0.002, 0.002, 0.0}), {0, 0}, {10, 0}, 2);
  test(Matrix::MakeScale({0.002, 0.002, 0.0}), {10, 0}, {0, 0}, 2);
  test(Matrix::MakeScale({0.002, 0.002, 0.0}), {0, 0}, {10, 10}, 2);
}

TEST(TessellatorTest, FilledEllipseTessellationVertices) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](const Matrix& transform, const Rect& bounds) {
    auto center = bounds.GetCenter();
    auto half_size = bounds.GetSize() * 0.5f;

    auto generator = tessellator->FilledEllipse(transform, bounds);
    EXPECT_EQ(generator.GetTriangleType(), PrimitiveType::kTriangleStrip);

    auto vertex_count = generator.GetVertexCount();
    auto vertices = std::vector<Point>();
    generator.GenerateVertices([&vertices](const Point& p) {  //
      vertices.push_back(p);
    });
    EXPECT_EQ(vertices.size(), vertex_count);
    ASSERT_EQ(vertex_count % 4, 0u);

    auto quadrant_count = vertex_count / 4;
    for (size_t i = 0; i < quadrant_count; i++) {
      double angle = kPiOver2 * i / (quadrant_count - 1);
      double degrees = angle * 180.0 / kPi;
      // Note that cos(radians(90 degrees)) isn't exactly 0.0 like it should be
      double rcos =
          (i == quadrant_count - 1) ? 0.0f : cos(angle) * half_size.width;
      double rsin = sin(angle) * half_size.height;
      EXPECT_POINT_NEAR(vertices[i * 2],
                        Point(center.x - rcos, center.y + rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
      EXPECT_POINT_NEAR(vertices[i * 2 + 1],
                        Point(center.x - rcos, center.y - rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 1],
                        Point(center.x + rcos, center.y - rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 2],
                        Point(center.x + rcos, center.y + rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
    }
  };

  // Square bounds should actually use the circle generator, but its
  // results should match the same math as the ellipse generator.
  test({}, Rect::MakeXYWH(0, 0, 2, 2));

  test({}, Rect::MakeXYWH(0, 0, 2, 3));
  test({}, Rect::MakeXYWH(0, 0, 3, 2));
  test({}, Rect::MakeXYWH(5, 10, 2, 3));
  test({}, Rect::MakeXYWH(16, 7, 3, 2));
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), Rect::MakeXYWH(5, 10, 3, 2));
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), Rect::MakeXYWH(5, 10, 2, 3));
  test(Matrix::MakeScale({0.002, 0.002, 0.0}),
       Rect::MakeXYWH(5000, 10000, 3000, 2000));
  test(Matrix::MakeScale({0.002, 0.002, 0.0}),
       Rect::MakeXYWH(5000, 10000, 2000, 3000));
}

TEST(TessellatorTest, FilledRoundRectTessellationVertices) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](const Matrix& transform, const Rect& bounds,
                             const Size& radii) {
    FML_DCHECK(radii.width * 2 <= bounds.GetWidth()) << radii << bounds;
    FML_DCHECK(radii.height * 2 <= bounds.GetHeight()) << radii << bounds;

    Scalar middle_left = bounds.GetX() + radii.width;
    Scalar middle_top = bounds.GetY() + radii.height;
    Scalar middle_right = bounds.GetX() + bounds.GetWidth() - radii.width;
    Scalar middle_bottom = bounds.GetY() + bounds.GetHeight() - radii.height;

    auto generator = tessellator->FilledRoundRect(transform, bounds, radii);
    EXPECT_EQ(generator.GetTriangleType(), PrimitiveType::kTriangleStrip);

    auto vertex_count = generator.GetVertexCount();
    auto vertices = std::vector<Point>();
    generator.GenerateVertices([&vertices](const Point& p) {  //
      vertices.push_back(p);
    });
    EXPECT_EQ(vertices.size(), vertex_count);
    ASSERT_EQ(vertex_count % 4, 0u);

    auto quadrant_count = vertex_count / 4;
    for (size_t i = 0; i < quadrant_count; i++) {
      double angle = kPiOver2 * i / (quadrant_count - 1);
      double degrees = angle * 180.0 / kPi;
      // Note that cos(radians(90 degrees)) isn't exactly 0.0 like it should be
      double rcos = (i == quadrant_count - 1) ? 0.0f : cos(angle) * radii.width;
      double rsin = sin(angle) * radii.height;
      EXPECT_POINT_NEAR(vertices[i * 2],
                        Point(middle_left - rcos, middle_bottom + rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
      EXPECT_POINT_NEAR(vertices[i * 2 + 1],
                        Point(middle_left - rcos, middle_top - rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 1],
                        Point(middle_right + rcos, middle_top - rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
      EXPECT_POINT_NEAR(vertices[vertex_count - i * 2 - 2],
                        Point(middle_right + rcos, middle_bottom + rsin))
          << "vertex " << i << ", angle = " << degrees << ", "  //
          << "bounds = " << bounds << std::endl;
    }
  };

  // Both radii spanning the bounds should actually use the circle/ellipse
  // generator, but their results should match the same math as the round
  // rect generator.
  test({}, Rect::MakeXYWH(0, 0, 20, 20), {10, 10});

  // One radius spanning the bounds, but not the other will not match the
  // round rect math if the generator transfers to circle/ellipse
  test({}, Rect::MakeXYWH(0, 0, 20, 20), {10, 5});
  test({}, Rect::MakeXYWH(0, 0, 20, 20), {5, 10});

  test({}, Rect::MakeXYWH(0, 0, 20, 30), {2, 2});
  test({}, Rect::MakeXYWH(0, 0, 30, 20), {2, 2});
  test({}, Rect::MakeXYWH(5, 10, 20, 30), {2, 3});
  test({}, Rect::MakeXYWH(16, 7, 30, 20), {2, 3});
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), Rect::MakeXYWH(5, 10, 30, 20),
       {2, 3});
  test(Matrix::MakeScale({500.0, 500.0, 0.0}), Rect::MakeXYWH(5, 10, 20, 30),
       {2, 3});
  test(Matrix::MakeScale({0.002, 0.002, 0.0}),
       Rect::MakeXYWH(5000, 10000, 3000, 2000), {50, 70});
  test(Matrix::MakeScale({0.002, 0.002, 0.0}),
       Rect::MakeXYWH(5000, 10000, 2000, 3000), {50, 70});
}

TEST(TessellatorTest, EarlyReturnEmptyConvexShape) {
  // This path is not technically empty (it has a size in one dimension), but
  // it contains only move commands and no actual path segment definitions.
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.MoveTo({10, 10});

  std::vector<Point> points;
  std::vector<uint16_t> indices;
  Tessellator::TessellateConvexInternal(builder.TakePath(), points, indices,
                                        3.0f);

  EXPECT_TRUE(points.empty());
  EXPECT_TRUE(indices.empty());
}

namespace {

// Tests the basic relationships of the angles iterated according to the
// rules of the ArcIteration struct. Each step iterated should be just
// about the same angular distance from the previous step, computed using
// the Cross product of the adjacent vectors, which should be the same as
// the sine of the angle between them when using unit vectors.
//
// Special support for shorter starting and ending steps to bridge the gap
// from the true arc start and the true arc end and the first and last
// angles iterated from the trigs.
void TestArcIterator(const impeller::Tessellator::ArcIteration arc_iteration,
                     const impeller::Tessellator::Trigs& trigs,
                     Degrees start,
                     Degrees sweep,
                     const std::string& label) {
  EXPECT_POINT_NEAR(arc_iteration.start, impeller::Matrix::CosSin(start))
      << label;
  EXPECT_POINT_NEAR(arc_iteration.end, impeller::Matrix::CosSin(start + sweep))
      << label;
  if (arc_iteration.quadrant_count == 0u) {
    // There is just the begin and end angle and there are no constraints
    // on how far apart they should be, but the end vector should be
    // non-counterclockwise from the start vector.
    EXPECT_GE(arc_iteration.start.Cross(arc_iteration.end), 0.0f);
    return;
  }

  const size_t steps = trigs.size() - 1;
  const Scalar step_angle = kPiOver2 / steps;

  // The first and last steps are allowed to be from 0.1 to 1.1 in size
  // as we don't want to iterate an extra step that is less than 0.1 steps
  // from the begin/end angles. We use min/max values that are ever so
  // slightly larger than that to avoid round-off errors.
  const Scalar edge_min_cross = std::sin(step_angle * 0.099f);
  const Scalar edge_max_cross = std::sin(step_angle * 1.101f);
  const Scalar typical_min_cross = std::sin(step_angle * 0.999f);
  const Scalar typical_max_cross = std::sin(step_angle * 1.001f);

  Vector2 cur_vector;
  auto trace = [&cur_vector](Vector2 vector, Scalar min_cross, Scalar max_cross,
                             const std::string& label) -> void {
    EXPECT_GT(cur_vector.Cross(vector), min_cross) << label;
    EXPECT_LT(cur_vector.Cross(vector), max_cross) << label;
    cur_vector = vector;
  };

  // The first edge encountered in the loop should be judged by the edge
  // conditions. After that the steps derived from the Trigs should be
  // judged by the typical min/max values.
  Scalar min_cross = edge_min_cross;
  Scalar max_cross = edge_max_cross;

  cur_vector = arc_iteration.start;
  for (size_t i = 0; i < arc_iteration.quadrant_count; i++) {
    auto& quadrant = arc_iteration.quadrants[i];
    EXPECT_LT(quadrant.start_index, quadrant.end_index)
        << label << ", quadrant: " << i;
    for (size_t j = quadrant.start_index; j < quadrant.end_index; j++) {
      trace(trigs[j] * quadrant.axis, min_cross, max_cross,
            label + ", quadrant: " + std::to_string(i) +
                ", step: " + std::to_string(j));
      // At this point we can guarantee that we've already used the initial
      // min/max values, now replace them with the typical values.
      min_cross = typical_min_cross;
      max_cross = typical_max_cross;
    }
  }

  // The jump to the end angle should be judged by the edge conditions.
  trace(arc_iteration.end, edge_min_cross, edge_max_cross,
        label + " step to end");
}

void TestFullCircleArc(Degrees start, Degrees sweep) {
  auto label =
      std::to_string(start.degrees) + " += " + std::to_string(sweep.degrees);

  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  size_t steps = trigs.size() - 1;
  const auto& arc_iteration =
      impeller::Tessellator::ComputeArcQuadrantIterations(trigs.size(), start,
                                                          sweep);

  EXPECT_EQ(arc_iteration.start, Vector2(1.0f, 0.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrant_count, 4u) << label;
  EXPECT_EQ(arc_iteration.quadrants[0].axis, Vector2(1.0f, 0.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[0].start_index, 1u) << label;
  EXPECT_EQ(arc_iteration.quadrants[0].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].axis, Vector2(0.0f, 1.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].axis, Vector2(-1.0f, 0.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].axis, Vector2(0.0f, -1.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.end, Vector2(1.0f, 0.0f)) << label;

  // For full circle arcs the original start and sweep are ignored and it
  // returns an iterator that always goes from 0->360.
  TestArcIterator(arc_iteration, trigs, Degrees(0), Degrees(360),
                  "Full Circle(" + label + ")");
}

}  // namespace

TEST(TessellatorTest, ArcIterationsFullCircle) {
  // Anything with a sweep <=-360 or >=360 is a full circle regardless of
  // starting angle
  for (int start = -720; start < 720; start += 30) {
    for (int sweep = 360; sweep < 1080; sweep += 45) {
      TestFullCircleArc(Degrees(start), Degrees(sweep));
      TestFullCircleArc(Degrees(start), Degrees(-sweep));
    }
  }
}

namespace {
static void CheckOneQuadrant(Degrees start, Degrees sweep) {
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  const auto& arc_iteration =
      Tessellator::ComputeArcQuadrantIterations(trigs.size(), start, sweep);

  EXPECT_POINT_NEAR(arc_iteration.start, Matrix::CosSin(start));
  EXPECT_EQ(arc_iteration.quadrant_count, 1u);
  EXPECT_POINT_NEAR(arc_iteration.end, Matrix::CosSin(start + sweep));

  std::string label = "Quadrant(" + std::to_string(start.degrees) +
                      " += " + std::to_string(sweep.degrees) + ")";
  TestArcIterator(arc_iteration, trigs, start, sweep, label);
}
}  // namespace

TEST(TessellatorTest, ArcIterationsVariousStartAnglesNearQuadrantAxis) {
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  const Degrees sweep(45);

  for (int start_i = -1000; start_i < 1000; start_i += 5) {
    Scalar start_degrees = start_i * 0.01f;
    for (int quadrant = -360; quadrant <= 360; quadrant += 90) {
      const Degrees start(quadrant + start_degrees);
      const auto& arc_iteration =
          Tessellator::ComputeArcQuadrantIterations(trigs.size(), start, sweep);

      TestArcIterator(arc_iteration, trigs, start, sweep,
                      "Various angles(" + std::to_string(start.degrees) +
                          " += " + std::to_string(sweep.degrees));
    }
  }
}

TEST(TessellatorTest, ArcIterationsVariousEndAnglesNearQuadrantAxis) {
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);

  for (int sweep_i = 5; sweep_i < 20000; sweep_i += 5) {
    const Degrees sweep(sweep_i * 0.01f);
    for (int quadrant = -360; quadrant <= 360; quadrant += 90) {
      const Degrees start(quadrant + 80);
      const auto& arc_iteration =
          Tessellator::ComputeArcQuadrantIterations(trigs.size(), start, sweep);

      TestArcIterator(arc_iteration, trigs, start, sweep,
                      "Various angles(" + std::to_string(start.degrees) +
                          " += " + std::to_string(sweep.degrees));
    }
  }
}

TEST(TessellatorTest, ArcIterationsVariousTinyArcsNearQuadrantAxis) {
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  const Degrees sweep(0.1f);

  for (int start_i = -1000; start_i < 1000; start_i += 5) {
    Scalar start_degrees = start_i * 0.01f;
    for (int quadrant = -360; quadrant <= 360; quadrant += 90) {
      const Degrees start(quadrant + start_degrees);
      const auto& arc_iteration =
          Tessellator::ComputeArcQuadrantIterations(trigs.size(), start, sweep);
      ASSERT_EQ(arc_iteration.quadrant_count, 0u);

      TestArcIterator(arc_iteration, trigs, start, sweep,
                      "Various angles(" + std::to_string(start.degrees) +
                          " += " + std::to_string(sweep.degrees));
    }
  }
}

TEST(TessellatorTest, ArcIterationsOnlyFirstQuadrant) {
  CheckOneQuadrant(Degrees(90 * 0 + 30), Degrees(30));
}

TEST(TessellatorTest, ArcIterationsOnlySecondQuadrant) {
  CheckOneQuadrant(Degrees(90 * 1 + 30), Degrees(30));
}

TEST(TessellatorTest, ArcIterationsOnlyThirdQuadrant) {
  CheckOneQuadrant(Degrees(90 * 2 + 30), Degrees(30));
}

TEST(TessellatorTest, ArcIterationsOnlyFourthQuadrant) {
  CheckOneQuadrant(Degrees(90 * 3 + 30), Degrees(30));
}

namespace {
static void CheckFiveQuadrants(Degrees start, Degrees sweep) {
  std::string label =
      std::to_string(start.degrees) + " += " + std::to_string(sweep.degrees);

  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  const auto& arc_iteration =
      Tessellator::ComputeArcQuadrantIterations(trigs.size(), start, sweep);
  size_t steps = trigs.size() - 1;

  EXPECT_POINT_NEAR(arc_iteration.start, Matrix::CosSin(start)) << label;
  EXPECT_EQ(arc_iteration.quadrant_count, 5u) << label;

  // quadrant 0 start index depends on angle
  EXPECT_EQ(arc_iteration.quadrants[0].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[1].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[2].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[3].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[4].start_index, 0u) << label;
  // quadrant 4 end index depends on angle

  EXPECT_POINT_NEAR(arc_iteration.end, Matrix::CosSin(start + sweep)) << label;

  TestArcIterator(arc_iteration, trigs, start, sweep,
                  "Five quadrants(" + label + ")");
}
}  // namespace

TEST(TessellatorTest, ArcIterationsAllQuadrantsFromFirst) {
  CheckFiveQuadrants(Degrees(90 * 0 + 60), Degrees(330));
}

TEST(TessellatorTest, ArcIterationsAllQuadrantsFromSecond) {
  CheckFiveQuadrants(Degrees(90 * 1 + 60), Degrees(330));
}

TEST(TessellatorTest, ArcIterationsAllQuadrantsFromThird) {
  CheckFiveQuadrants(Degrees(90 * 2 + 60), Degrees(330));
}

TEST(TessellatorTest, ArcIterationsAllQuadrantsFromFourth) {
  CheckFiveQuadrants(Degrees(90 * 3 + 60), Degrees(330));
}

}  // namespace testing
}  // namespace impeller

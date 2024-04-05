// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {
namespace testing {

TEST(TessellatorTest, TessellatorBuilderReturnsCorrectResultStatus) {
  // Zero points.
  {
    Tessellator t;
    auto path = PathBuilder{}.TakePath(FillType::kOdd);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, Tessellator::Result::kInputError);
  }

  // One point.
  {
    Tessellator t;
    auto path = PathBuilder{}.LineTo({0, 0}).TakePath(FillType::kOdd);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Two points.
  {
    Tessellator t;
    auto path = PathBuilder{}.AddLine({0, 0}, {0, 1}).TakePath(FillType::kOdd);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Many points.
  {
    Tessellator t;
    PathBuilder builder;
    for (int i = 0; i < 1000; i++) {
      auto coord = i * 1.0f;
      builder.AddLine({coord, coord}, {coord + 1, coord + 1});
    }
    auto path = builder.TakePath(FillType::kOdd);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return true; });

    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }

  // Closure fails.
  {
    Tessellator t;
    auto path = PathBuilder{}.AddLine({0, 0}, {0, 1}).TakePath(FillType::kOdd);
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [](const float* vertices, size_t vertices_count,
           const uint16_t* indices, size_t indices_count) { return false; });

    ASSERT_EQ(result, Tessellator::Result::kInputError);
  }

  // More than uint16 points, odd fill mode.
  {
    Tessellator t;
    PathBuilder builder = {};
    for (auto i = 0; i < 1000; i++) {
      builder.AddCircle(Point(i, i), 4);
    }
    auto path = builder.TakePath(FillType::kOdd);
    bool no_indices = false;
    size_t count = 0u;
    Tessellator::Result result = t.Tessellate(
        path, 1.0f,
        [&no_indices, &count](const float* vertices, size_t vertices_count,
                              const uint16_t* indices, size_t indices_count) {
          no_indices = indices == nullptr;
          count = vertices_count;
          return true;
        });

    ASSERT_TRUE(no_indices);
    ASSERT_TRUE(count >= USHRT_MAX);
    ASSERT_EQ(result, Tessellator::Result::kSuccess);
  }
}

TEST(TessellatorTest, TessellateConvex) {
  {
    Tessellator t;
    // Sanity check simple rectangle.
    auto pts = t.TessellateConvex(
        PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 10, 10)).TakePath(), 1.0);

    std::vector<Point> expected = {{0, 0}, {10, 0}, {0, 10}, {10, 10}};
    EXPECT_EQ(pts, expected);
  }

  {
    Tessellator t;
    auto pts = t.TessellateConvex(PathBuilder{}
                                      .AddRect(Rect::MakeLTRB(0, 0, 10, 10))
                                      .AddRect(Rect::MakeLTRB(20, 20, 30, 30))
                                      .TakePath(),
                                  1.0);

    std::vector<Point> expected = {{0, 0},   {10, 0},  {0, 10},  {10, 10},
                                   {10, 10}, {20, 20}, {20, 20}, {30, 20},
                                   {20, 30}, {30, 30}};
    EXPECT_EQ(pts, expected);
  }
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
      double rcos = cos(angle) * radius;
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
      double rcos = cos(angle) * (radius + half_width);
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
      double rcos = cos(angle) * (radius - half_width);
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
      Point relative_along = along * cos(angle);
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
      double rcos = cos(angle) * half_size.width;
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
      double rcos = cos(angle) * radii.width;
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
  // This path is not technically empty (it has a size in one dimension),
  // but is otherwise completely flat.
  auto tessellator = std::make_shared<Tessellator>();
  PathBuilder builder;
  builder.MoveTo({0, 0});
  builder.MoveTo({10, 10}, /*relative=*/true);

  auto points = tessellator->TessellateConvex(builder.TakePath(), 3.0);

  EXPECT_TRUE(points.empty());
}

#if !NDEBUG
TEST(TessellatorTest, ChecksConcurrentPolylineUsage) {
  auto tessellator = std::make_shared<Tessellator>();
  PathBuilder builder;
  builder.AddLine({0, 0}, {100, 100});
  auto path = builder.TakePath();

  auto polyline = tessellator->CreateTempPolyline(path, 0.1);
  EXPECT_DEBUG_DEATH(tessellator->CreateTempPolyline(path, 0.1),
                     "point_buffer_");
}
#endif  // NDEBUG

}  // namespace testing
}  // namespace impeller

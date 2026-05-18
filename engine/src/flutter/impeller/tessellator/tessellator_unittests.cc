// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

#include "flutter/display_list/geometry/dl_path_builder.h"
#include "impeller/geometry/constants.h"
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
  Tessellator tessellator;

  auto test = [&tessellator](const Matrix& transform, Scalar radius) {
    auto generator = tessellator.FilledCircle(transform, {}, radius);
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
  Tessellator tessellator;

  auto test = [&tessellator](const Matrix& transform, const Point& center,
                             Scalar radius) {
    auto generator = tessellator.FilledCircle(transform, center, radius);
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
  Tessellator tessellator;

  auto test = [&tessellator](const Matrix& transform, const Point& center,
                             Scalar radius, Scalar half_width) {
    ASSERT_GT(radius, half_width);
    auto generator =
        tessellator.StrokedCircle(transform, center, radius, half_width);
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

TEST(TessellatorTest, FilledArcStripTessellationVertices) {
  Tessellator tessellator;

  auto test = [&tessellator](const Matrix& transform, const Arc& arc) {
    auto generator = tessellator.FilledArc(transform, arc,
                                           /*supports_triangle_fans=*/false);
    EXPECT_EQ(generator.GetTriangleType(), PrimitiveType::kTriangleStrip);

    auto vertex_count = generator.GetVertexCount();
    auto vertices = std::vector<Point>();
    generator.GenerateVertices([&vertices](const Point& p) {  //
      vertices.push_back(p);
    });
    EXPECT_EQ(vertices.size(), vertex_count);

    auto center = arc.GetOvalBounds().GetCenter();
    auto radius = arc.GetOvalSize().width * 0.5;

    // Test position of first point
    EXPECT_POINT_NEAR(
        vertices[0],
        Point(center.x + cos(Radians(arc.GetStart()).radians) * radius,
              center.y + sin(Radians(arc.GetStart()).radians) * radius));

    // Test position of last point
    auto last_angle = arc.GetStart() + arc.GetSweep();
    EXPECT_POINT_NEAR(
        vertices[vertex_count - 1],
        Point(center.x + cos(Radians(last_angle).radians) * radius,
              center.y + sin(Radians(last_angle).radians) * radius));

    // Test odd-indexed points. These are all the origin.
    Point origin = arc.IncludeCenter()
                       ? center
                       : (vertices[0] + vertices[vertex_count - 1]) * 0.5f;
    for (size_t i = 1; i < vertex_count; i += 2) {
      EXPECT_POINT_NEAR(vertices[i], origin);
    }

    // Test even-indexed points. These are points on the outer edge of the arc.
    auto previous_outer_point = vertices[0];
    auto outer_increment_distance = (vertices[4] - vertices[2]).GetLength();
    for (size_t i = 2; i < vertex_count; i += 2) {
      // Each is |radius| from the center.
      EXPECT_NEAR((vertices[i] - center).GetLength(), radius, kEhCloseEnough);

      // Each is within |outer_increment_distance| from the previous
      if (i == 2 || i == vertex_count - 1) {
        // The very first and last points may be closer than
        // |outer_increment_distance| to their adjacent outer points
        EXPECT_LE((vertices[i] - previous_outer_point).GetLength(),
                  outer_increment_distance + kEhCloseEnough);
      } else {
        // Other outer points are |outer_increment_distance| apart
        EXPECT_NEAR((vertices[i] - previous_outer_point).GetLength(),
                    outer_increment_distance, kEhCloseEnough);
      }

      previous_outer_point = vertices[i];
    }
  };

  test({}, Arc(Rect::MakeXYWH(0, 0, 100, 100), Degrees(0), Degrees(90), false));
  test({}, Arc(Rect::MakeXYWH(0, 0, 100, 100), Degrees(0), Degrees(90), true));

  test({},
       Arc(Rect::MakeXYWH(0, 0, 100, 100), Degrees(0), Degrees(-270), false));
  test({},
       Arc(Rect::MakeXYWH(0, 0, 100, 100), Degrees(0), Degrees(-270), true));

  test({},
       Arc(Rect::MakeXYWH(0, 0, 100, 100), Degrees(94), Degrees(322), false));
  test({},
       Arc(Rect::MakeXYWH(0, 0, 100, 100), Degrees(94), Degrees(322), true));
}

TEST(TessellatorTest, RoundCapLineTessellationVertices) {
  Tessellator tessellator;

  auto test = [&tessellator](const Matrix& transform, const Point& p0,
                             const Point& p1, Scalar radius) {
    auto generator = tessellator.RoundCapLine(transform, p0, p1, radius);
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
  Tessellator tessellator;

  auto test = [&tessellator](const Matrix& transform, const Rect& bounds) {
    auto center = bounds.GetCenter();
    auto half_size = bounds.GetSize() * 0.5f;

    auto generator = tessellator.FilledEllipse(transform, bounds);
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
  Tessellator tessellator;

  auto test = [&tessellator](const Matrix& transform, const Rect& bounds,
                             const Size& radii) {
    FML_DCHECK(radii.width * 2 <= bounds.GetWidth()) << radii << bounds;
    FML_DCHECK(radii.height * 2 <= bounds.GetHeight()) << radii << bounds;

    Scalar middle_left = bounds.GetX() + radii.width;
    Scalar middle_top = bounds.GetY() + radii.height;
    Scalar middle_right = bounds.GetX() + bounds.GetWidth() - radii.width;
    Scalar middle_bottom = bounds.GetY() + bounds.GetHeight() - radii.height;

    auto generator = tessellator.FilledRoundRect(transform, bounds, radii);
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

}  // namespace testing
}  // namespace impeller

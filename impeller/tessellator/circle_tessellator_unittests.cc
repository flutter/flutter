// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fml/logging.h"
#include "gtest/gtest.h"

#include "flutter/impeller/geometry/geometry_asserts.h"
#include "flutter/impeller/tessellator/circle_tessellator.h"

namespace impeller {
namespace testing {

TEST(CircleTessellator, DivisionAndVertexCounts) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](const Matrix& transform, Scalar radius) {
    CircleTessellator circle_tessellator(tessellator, transform, radius);
    size_t quadrant_divisions = circle_tessellator.GetQuadrantDivisionCount();

    EXPECT_EQ(circle_tessellator.GetCircleVertexCount(),
              (quadrant_divisions + 1) * 4)
        << "transform = " << transform << ", radius = " << radius;

    EXPECT_EQ(circle_tessellator.GetStrokedCircleVertexCount(),
              (quadrant_divisions + 1) * 8)
        << "transform = " << transform << ", radius = " << radius;

    // Confirm the approximation error is within the currently accepted
    // |kCircleTolerance| value advertised by |CircleTessellator|.
    // (With an additional 1% tolerance for floating point rounding.)
    double angle = kPiOver2 / quadrant_divisions;
    Point first = {radius, 0};
    Point next = {static_cast<Scalar>(cos(angle) * radius),
                  static_cast<Scalar>(sin(angle) * radius)};
    Point midpoint = (first + next) * 0.5;
    EXPECT_GE(midpoint.GetLength(),
              radius - CircleTessellator::kCircleTolerance * 1.01)
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

TEST(CircleTessellator, FilledCircleTessellationVertices) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](Scalar pixel_radius, Point center, Scalar radius) {
    CircleTessellator circle_tessellator(tessellator, {}, pixel_radius);

    auto vertex_count = circle_tessellator.GetCircleVertexCount();
    auto vertices = std::vector<Point>();
    circle_tessellator.GenerateCircleTriangleStrip(
        [&vertices](const Point& p) {  //
          vertices.push_back(p);
        },
        center, radius);
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

  test(2.0, {}, 2.0);
  test(2.0, {10, 10}, 2.0);
  test(1000.0, {}, 2.0);
  test(2.0, {}, 1000.0);
}

TEST(CircleTessellator, StrokedCircleTessellationVertices) {
  auto tessellator = std::make_shared<Tessellator>();

  auto test = [&tessellator](Scalar pixel_radius, Point center, Scalar radius,
                             Scalar width) {
    ASSERT_GT(radius, width);
    CircleTessellator circle_tessellator(tessellator, {}, pixel_radius);

    auto vertex_count = circle_tessellator.GetStrokedCircleVertexCount();
    auto vertices = std::vector<Point>();
    circle_tessellator.GenerateStrokedCircleTriangleStrip(
        [&vertices](const Point& p) {  //
          vertices.push_back(p);
        },
        center, radius + width, radius - width);
    EXPECT_EQ(vertices.size(), vertex_count);
    ASSERT_EQ(vertex_count % 4, 0u);

    auto quadrant_count = vertex_count / 8;

    // Test outer points first
    for (size_t i = 0; i < quadrant_count; i++) {
      double angle = kPiOver2 * i / (quadrant_count - 1);
      double degrees = angle * 180.0 / kPi;
      double rsin = sin(angle) * (radius + width);
      double rcos = cos(angle) * (radius + width);
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
      double rsin = sin(angle) * (radius - width);
      double rcos = cos(angle) * (radius - width);
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

  test(2.0, {}, 2.0, 1.0);
  test(2.0, {}, 2.0, 0.5);
  test(2.0, {10, 10}, 2.0, 1.0);
  test(1000.0, {}, 2.0, 1.0);
  test(2.0, {}, 1000.0, 10.0);
}

}  // namespace testing
}  // namespace impeller

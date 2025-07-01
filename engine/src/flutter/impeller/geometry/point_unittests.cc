// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/point.h"

#include "flutter/impeller/geometry/geometry_asserts.h"
#include "gtest/gtest.h"

namespace impeller {
namespace testing {

TEST(PointTest, Length) {
  for (int i = 0; i < 21; i++) {
    EXPECT_EQ(Point(i, 0).GetLengthSquared(), i * i) << "i: " << i;
    EXPECT_EQ(Point(0, i).GetLengthSquared(), i * i) << "i: " << i;
    EXPECT_EQ(Point(-i, 0).GetLengthSquared(), i * i) << "i: " << i;
    EXPECT_EQ(Point(0, -i).GetLengthSquared(), i * i) << "i: " << i;

    EXPECT_EQ(Point(i, 0).GetLength(), i) << "i: " << i;
    EXPECT_EQ(Point(0, i).GetLength(), i) << "i: " << i;
    EXPECT_EQ(Point(-i, 0).GetLength(), i) << "i: " << i;
    EXPECT_EQ(Point(0, -i).GetLength(), i) << "i: " << i;

    EXPECT_EQ(Point(i, i).GetLengthSquared(), 2 * i * i) << "i: " << i;
    EXPECT_EQ(Point(-i, i).GetLengthSquared(), 2 * i * i) << "i: " << i;
    EXPECT_EQ(Point(i, -i).GetLengthSquared(), 2 * i * i) << "i: " << i;
    EXPECT_EQ(Point(-i, -i).GetLengthSquared(), 2 * i * i) << "i: " << i;

    EXPECT_FLOAT_EQ(Point(i, i).GetLength(), kSqrt2 * i) << "i: " << i;
    EXPECT_FLOAT_EQ(Point(-i, i).GetLength(), kSqrt2 * i) << "i: " << i;
    EXPECT_FLOAT_EQ(Point(i, -i).GetLength(), kSqrt2 * i) << "i: " << i;
    EXPECT_FLOAT_EQ(Point(-i, -i).GetLength(), kSqrt2 * i) << "i: " << i;
  }
}

TEST(PointTest, Distance) {
  for (int j = 0; j < 21; j++) {
    for (int i = 0; i < 21; i++) {
      {
        Scalar d = i - j;

        EXPECT_EQ(Point(i, 0).GetDistanceSquared(Point(j, 0)), d * d)
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(0, i).GetDistanceSquared(Point(0, j)), d * d)
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(j, 0).GetDistanceSquared(Point(i, 0)), d * d)
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(0, j).GetDistanceSquared(Point(0, i)), d * d)
            << "i: " << i << ", j: " << j;

        EXPECT_EQ(Point(i, 0).GetDistance(Point(j, 0)), std::abs(d))
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(0, i).GetDistance(Point(0, j)), std::abs(d))
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(j, 0).GetDistance(Point(i, 0)), std::abs(d))
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(0, j).GetDistance(Point(0, i)), std::abs(d))
            << "i: " << i << ", j: " << j;
      }

      {
        Scalar d_squared = i * i + j * j;

        EXPECT_EQ(Point(i, 0).GetDistanceSquared(Point(0, j)), d_squared)
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(-i, 0).GetDistanceSquared(Point(0, j)), d_squared)
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(i, 0).GetDistanceSquared(Point(0, -j)), d_squared)
            << "i: " << i << ", j: " << j;
        EXPECT_EQ(Point(-i, 0).GetDistanceSquared(Point(0, -j)), d_squared)
            << "i: " << i << ", j: " << j;

        Scalar d = std::sqrt(d_squared);

        EXPECT_FLOAT_EQ(Point(i, 0).GetDistance(Point(0, j)), d)
            << "i: " << i << ", j: " << j;
        EXPECT_FLOAT_EQ(Point(-i, 0).GetDistance(Point(0, j)), d)
            << "i: " << i << ", j: " << j;
        EXPECT_FLOAT_EQ(Point(i, 0).GetDistance(Point(0, -j)), d)
            << "i: " << i << ", j: " << j;
        EXPECT_FLOAT_EQ(Point(-i, 0).GetDistance(Point(0, -j)), d)
            << "i: " << i << ", j: " << j;
      }
    }
  }
}

TEST(PointTest, PerpendicularLeft) {
  EXPECT_EQ(Point(1, 0).PerpendicularLeft(), Point(0, -1));
  EXPECT_EQ(Point(0, 1).PerpendicularLeft(), Point(1, 0));
  EXPECT_EQ(Point(-1, 0).PerpendicularLeft(), Point(0, 1));
  EXPECT_EQ(Point(0, -1).PerpendicularLeft(), Point(-1, 0));

  EXPECT_EQ(Point(1, 1).PerpendicularLeft(), Point(1, -1));
  EXPECT_EQ(Point(-1, 1).PerpendicularLeft(), Point(1, 1));
  EXPECT_EQ(Point(-1, -1).PerpendicularLeft(), Point(-1, 1));
  EXPECT_EQ(Point(1, -1).PerpendicularLeft(), Point(-1, -1));
}

TEST(PointTest, PerpendicularRight) {
  EXPECT_EQ(Point(1, 0).PerpendicularRight(), Point(0, 1));
  EXPECT_EQ(Point(0, 1).PerpendicularRight(), Point(-1, 0));
  EXPECT_EQ(Point(-1, 0).PerpendicularRight(), Point(0, -1));
  EXPECT_EQ(Point(0, -1).PerpendicularRight(), Point(1, 0));

  EXPECT_EQ(Point(1, 1).PerpendicularRight(), Point(-1, 1));
  EXPECT_EQ(Point(-1, 1).PerpendicularRight(), Point(-1, -1));
  EXPECT_EQ(Point(-1, -1).PerpendicularRight(), Point(1, -1));
  EXPECT_EQ(Point(1, -1).PerpendicularRight(), Point(1, 1));
}

namespace {
typedef std::pair<Scalar, Scalar> PtSegmentDistanceFunc(Point);

void TestPointToSegmentGroup(Point segment0,
                             Point segment1,
                             Point p0,
                             Point delta,
                             int count,
                             PtSegmentDistanceFunc calc_distance) {
  for (int i = 0; i < count; i++) {
    auto [distance, squared] = calc_distance(p0);
    EXPECT_FLOAT_EQ(p0.GetDistanceToSegmentSquared(segment0, segment1), squared)
        << p0 << " => [" << segment0 << ", " << segment1 << "]";
    EXPECT_FLOAT_EQ(p0.GetDistanceToSegmentSquared(segment1, segment0), squared)
        << p0 << " => [" << segment0 << ", " << segment1 << "]";
    EXPECT_FLOAT_EQ(p0.GetDistanceToSegment(segment0, segment1), distance)
        << p0 << " => [" << segment0 << ", " << segment1 << "]";
    EXPECT_FLOAT_EQ(p0.GetDistanceToSegment(segment1, segment0), distance)
        << p0 << " => [" << segment0 << ", " << segment1 << "]";
    p0 += delta;
  }
}
}  // namespace

TEST(PointTest, PointToSegment) {
  // Horizontal segment and points to the left of it on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 10},
      // Starting point, delta, count ({0,10} through {10,10})
      {0, 10}, {1, 0}, 11,
      // Distance computation
      [](Point p) {
        Scalar d = 10 - p.x;
        return std::make_pair(d, d * d);
      });

  // Horizontal segment and points on the segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 10},
      // Starting point, delta, count ({11,10} through {19, 10})
      {11, 10}, {1, 0}, 9,
      // Distance computation
      [](Point p) {  //
        return std::make_pair(0.0f, 0.0f);
      });

  // Horizontal segment and points to the right of it on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 10},
      // Starting point, delta, count ({20,10} through {30,10})
      {20, 10}, {1, 0}, 11,
      // Distance computation
      [](Point p) {
        Scalar d = p.x - 20;
        return std::make_pair(d, d * d);
      });

  // Vertical segment and points above the top of it on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {10, 20},
      // Starting point, delta, count ({10,0} through {10,10})
      {10, 0}, {0, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d = 10 - p.y;
        return std::make_pair(d, d * d);
      });

  // Vertical segment and points on the segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {10, 20},
      // Starting point, delta, count ({10,11} through {10, 19})
      {10, 11}, {0, 1}, 9,
      // Distance computation
      [](Point p) {  //
        return std::make_pair(0.0f, 0.0f);
      });

  // Vertical segment and points below the bottom of it on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {10, 20},
      // Starting point, delta, count ({10,20} through {10,30})
      {10, 20}, {0, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d = p.y - 20;
        return std::make_pair(d, d * d);
      });

  // Horizontal segment and points 5 pixels above and to the left of it
  // on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 10},
      // Starting point, delta, count ({0,5} through {10,5})
      {0, 5}, {1, 0}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = (10 - p.x) * (10 - p.x) + 25;
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Horizontal segment and points 5 pixels directly above the segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 10},
      // Starting point, delta, count ({11,5} through {19, 5})
      {11, 5}, {1, 0}, 9,
      // Distance computation
      [](Point p) {  //
        return std::make_pair(5.0f, 25.0f);
      });

  // Horizontal segment and points 5 pixels above and to the right of it
  // on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 10},
      // Starting point, delta, count ({20,5} through {30,5})
      {20, 5}, {1, 0}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = (p.x - 20) * (p.x - 20) + 25;
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Vertical segment and points 5 pixels to the left and above the segment
  // on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {10, 20},
      // Starting point, delta, count ({5,0} through {5,10})
      {5, 0}, {0, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = 25 + (10 - p.y) * (10 - p.y);
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Vertical segment and points 5 pixels directly to the left of the segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {10, 20},
      // Starting point, delta, count ({5,11} through {5,19,})
      {5, 11}, {0, 1}, 9,
      // Distance computation
      [](Point p) {  //
        return std::make_pair(5.0f, 25.0f);
      });

  // Vertical segment and points 5 pixels to the left and below the segment
  // on the same line.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {10, 20},
      // Starting point, delta, count ({20,5} through {30,5})
      {5, 20}, {0, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = 25 + (p.y - 20) * (p.y - 20);
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Diagonal segment and points up and to the right of the top of the segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 20},
      // Starting point, delta, count ({5,-5} through {15,5})
      {5, -5}, {1, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = (p.x - 10) * (p.x - 10) + (p.y - 10) * (p.y - 10);
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Diagonal segment and points up and to the right of the segment itself.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 20},
      // Starting point, delta, count ({15,5} through {24,14})
      {15, 5}, {1, 1}, 9,
      // Distance computation
      [](Point p) {
        Scalar d_sq = 50.0f;
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Diagonal segment and points up and to the right of the bottom of the
  // segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 20},
      // Starting point, delta, count ({25,15} through {35,25})
      {25, 15}, {1, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = (p.x - 20) * (p.x - 20) + (p.y - 20) * (p.y - 20);
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Diagonal segment and points down and to the left of the top of the segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 20},
      // Starting point, delta, count ({-5,5} through {5,15})
      {-5, 5}, {1, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = (p.x - 10) * (p.x - 10) + (p.y - 10) * (p.y - 10);
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Diagonal segment and points down and to the left of the segment itself.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 20},
      // Starting point, delta, count ({5,15} through {14,24})
      {5, 15}, {1, 1}, 9,
      // Distance computation
      [](Point p) {
        Scalar d_sq = 50.0f;
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });

  // Diagonal segment and points down and to the left of the bottom of the
  // segment.
  TestPointToSegmentGroup(
      // Segment
      {10, 10}, {20, 20},
      // Starting point, delta, count ({15,25} through {25,35})
      {15, 25}, {1, 1}, 11,
      // Distance computation
      [](Point p) {
        Scalar d_sq = (p.x - 20) * (p.x - 20) + (p.y - 20) * (p.y - 20);
        return std::make_pair(std::sqrt(d_sq), d_sq);
      });
}

TEST(PointTest, CrossProductThreePoints) {
  // Colinear
  EXPECT_FLOAT_EQ(Point::Cross(Point(-1, 0), Point(0, 0), Point(1, 0)), 0);
  EXPECT_FLOAT_EQ(Point::Cross(Point(1, 0), Point(0, 0), Point(-1, 0)), 0);

  // Right turn
  EXPECT_FLOAT_EQ(Point::Cross(Point(-1, 0), Point(0, 0), Point(0, 1)), 1);
  EXPECT_FLOAT_EQ(Point::Cross(Point(-2, 0), Point(0, 0), Point(0, 2)), 4);

  // Left turn
  EXPECT_FLOAT_EQ(Point::Cross(Point(-1, 0), Point(0, 0), Point(0, -1)), -1);
  EXPECT_FLOAT_EQ(Point::Cross(Point(-2, 0), Point(0, 0), Point(0, -2)), -4);

  // Convenient values for a less obvious left turn.
  // p1 - p0 == (0, 0) - (3, -4) == (-3, 4)
  // p2 - p0 == (1, 2) - (3, -4) == (-2, 6)
  // product of the magnitude of the 2 legs and the sin of their angle
  // (||(-3, 4)||) * (||(-2, 6)||) * sin(angle)
  // 5 * sqrt(40) * sin(angle)
  // angle = arcsin(4 / 5) - arcsin(6 / sqrt(40)) ~= -18.4349
  // sin(angle) ~= -0.316227766
  // 5 * sqrt(40) * sin(angle) == -10
  // The math is cleaner with the cross product:
  // (-3 * 6) - (-2 * 4) == -18 - -8 == -10
  EXPECT_FLOAT_EQ(Point::Cross(Point(3, -4), Point(0, 0), Point(1, 2)), -10);
}

}  // namespace testing
}  // namespace impeller

// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/geometry/point.h"
#include "ui/gfx/geometry/point_conversions.h"
#include "ui/gfx/geometry/point_f.h"

namespace gfx {

namespace {

int TestPointF(const PointF& p) {
  return p.x();
}

}  // namespace

TEST(PointTest, ToPointF) {
  // Check that implicit conversion from integer to float compiles.
  Point a(10, 20);
  float x = TestPointF(a);
  EXPECT_EQ(x, a.x());

  PointF b(10, 20);
  EXPECT_EQ(a, b);
  EXPECT_EQ(b, a);
}

TEST(PointTest, IsOrigin) {
  EXPECT_FALSE(Point(1, 0).IsOrigin());
  EXPECT_FALSE(Point(0, 1).IsOrigin());
  EXPECT_FALSE(Point(1, 2).IsOrigin());
  EXPECT_FALSE(Point(-1, 0).IsOrigin());
  EXPECT_FALSE(Point(0, -1).IsOrigin());
  EXPECT_FALSE(Point(-1, -2).IsOrigin());
  EXPECT_TRUE(Point(0, 0).IsOrigin());

  EXPECT_FALSE(PointF(0.1f, 0).IsOrigin());
  EXPECT_FALSE(PointF(0, 0.1f).IsOrigin());
  EXPECT_FALSE(PointF(0.1f, 2).IsOrigin());
  EXPECT_FALSE(PointF(-0.1f, 0).IsOrigin());
  EXPECT_FALSE(PointF(0, -0.1f).IsOrigin());
  EXPECT_FALSE(PointF(-0.1f, -2).IsOrigin());
  EXPECT_TRUE(PointF(0, 0).IsOrigin());
}

TEST(PointTest, VectorArithmetic) {
  Point a(1, 5);
  Vector2d v1(3, -3);
  Vector2d v2(-8, 1);

  static const struct {
    Point expected;
    Point actual;
  } tests[] = {
    { Point(4, 2), a + v1 },
    { Point(-2, 8), a - v1 },
    { a, a - v1 + v1 },
    { a, a + v1 - v1 },
    { a, a + Vector2d() },
    { Point(12, 1), a + v1 - v2 },
    { Point(-10, 9), a - v1 + v2 }
  };

  for (size_t i = 0; i < arraysize(tests); ++i)
    EXPECT_EQ(tests[i].expected.ToString(), tests[i].actual.ToString());
}

TEST(PointTest, OffsetFromPoint) {
  Point a(1, 5);
  Point b(-20, 8);
  EXPECT_EQ(Vector2d(-20 - 1, 8 - 5).ToString(), (b - a).ToString());
}

TEST(PointTest, ToRoundedPoint) {
  EXPECT_EQ(Point(0, 0), ToRoundedPoint(PointF(0, 0)));
  EXPECT_EQ(Point(0, 0), ToRoundedPoint(PointF(0.0001f, 0.0001f)));
  EXPECT_EQ(Point(0, 0), ToRoundedPoint(PointF(0.4999f, 0.4999f)));
  EXPECT_EQ(Point(1, 1), ToRoundedPoint(PointF(0.5f, 0.5f)));
  EXPECT_EQ(Point(1, 1), ToRoundedPoint(PointF(0.9999f, 0.9999f)));

  EXPECT_EQ(Point(10, 10), ToRoundedPoint(PointF(10, 10)));
  EXPECT_EQ(Point(10, 10), ToRoundedPoint(PointF(10.0001f, 10.0001f)));
  EXPECT_EQ(Point(10, 10), ToRoundedPoint(PointF(10.4999f, 10.4999f)));
  EXPECT_EQ(Point(11, 11), ToRoundedPoint(PointF(10.5f, 10.5f)));
  EXPECT_EQ(Point(11, 11), ToRoundedPoint(PointF(10.9999f, 10.9999f)));

  EXPECT_EQ(Point(-10, -10), ToRoundedPoint(PointF(-10, -10)));
  EXPECT_EQ(Point(-10, -10), ToRoundedPoint(PointF(-10.0001f, -10.0001f)));
  EXPECT_EQ(Point(-10, -10), ToRoundedPoint(PointF(-10.4999f, -10.4999f)));
  EXPECT_EQ(Point(-11, -11), ToRoundedPoint(PointF(-10.5f, -10.5f)));
  EXPECT_EQ(Point(-11, -11), ToRoundedPoint(PointF(-10.9999f, -10.9999f)));
}

TEST(PointTest, Scale) {
  EXPECT_EQ(PointF().ToString(), ScalePoint(Point(), 2).ToString());
  EXPECT_EQ(PointF().ToString(), ScalePoint(Point(), 2, 2).ToString());

  EXPECT_EQ(PointF(2, -2).ToString(),
            ScalePoint(Point(1, -1), 2).ToString());
  EXPECT_EQ(PointF(2, -2).ToString(),
            ScalePoint(Point(1, -1), 2, 2).ToString());

  PointF zero;
  PointF one(1, -1);

  zero.Scale(2);
  zero.Scale(3, 1.5);

  one.Scale(2);
  one.Scale(3, 1.5);

  EXPECT_EQ(PointF().ToString(), zero.ToString());
  EXPECT_EQ(PointF(6, -3).ToString(), one.ToString());
}

TEST(PointTest, ClampPoint) {
  Point a;

  a = Point(3, 5);
  EXPECT_EQ(Point(3, 5).ToString(), a.ToString());
  a.SetToMax(Point(2, 4));
  EXPECT_EQ(Point(3, 5).ToString(), a.ToString());
  a.SetToMax(Point(3, 5));
  EXPECT_EQ(Point(3, 5).ToString(), a.ToString());
  a.SetToMax(Point(4, 2));
  EXPECT_EQ(Point(4, 5).ToString(), a.ToString());
  a.SetToMax(Point(8, 10));
  EXPECT_EQ(Point(8, 10).ToString(), a.ToString());

  a.SetToMin(Point(9, 11));
  EXPECT_EQ(Point(8, 10).ToString(), a.ToString());
  a.SetToMin(Point(8, 10));
  EXPECT_EQ(Point(8, 10).ToString(), a.ToString());
  a.SetToMin(Point(11, 9));
  EXPECT_EQ(Point(8, 9).ToString(), a.ToString());
  a.SetToMin(Point(7, 11));
  EXPECT_EQ(Point(7, 9).ToString(), a.ToString());
  a.SetToMin(Point(3, 5));
  EXPECT_EQ(Point(3, 5).ToString(), a.ToString());
}

TEST(PointTest, ClampPointF) {
  PointF a;

  a = PointF(3.5f, 5.5f);
  EXPECT_EQ(PointF(3.5f, 5.5f).ToString(), a.ToString());
  a.SetToMax(PointF(2.5f, 4.5f));
  EXPECT_EQ(PointF(3.5f, 5.5f).ToString(), a.ToString());
  a.SetToMax(PointF(3.5f, 5.5f));
  EXPECT_EQ(PointF(3.5f, 5.5f).ToString(), a.ToString());
  a.SetToMax(PointF(4.5f, 2.5f));
  EXPECT_EQ(PointF(4.5f, 5.5f).ToString(), a.ToString());
  a.SetToMax(PointF(8.5f, 10.5f));
  EXPECT_EQ(PointF(8.5f, 10.5f).ToString(), a.ToString());

  a.SetToMin(PointF(9.5f, 11.5f));
  EXPECT_EQ(PointF(8.5f, 10.5f).ToString(), a.ToString());
  a.SetToMin(PointF(8.5f, 10.5f));
  EXPECT_EQ(PointF(8.5f, 10.5f).ToString(), a.ToString());
  a.SetToMin(PointF(11.5f, 9.5f));
  EXPECT_EQ(PointF(8.5f, 9.5f).ToString(), a.ToString());
  a.SetToMin(PointF(7.5f, 11.5f));
  EXPECT_EQ(PointF(7.5f, 9.5f).ToString(), a.ToString());
  a.SetToMin(PointF(3.5f, 5.5f));
  EXPECT_EQ(PointF(3.5f, 5.5f).ToString(), a.ToString());
}

}  // namespace gfx

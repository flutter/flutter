// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/geometry/rect_conversions.h"
#include "ui/gfx/test/gfx_util.h"

namespace gfx {

TEST(RectTest, Contains) {
  static const struct ContainsCase {
    int rect_x;
    int rect_y;
    int rect_width;
    int rect_height;
    int point_x;
    int point_y;
    bool contained;
  } contains_cases[] = {
    {0, 0, 10, 10, 0, 0, true},
    {0, 0, 10, 10, 5, 5, true},
    {0, 0, 10, 10, 9, 9, true},
    {0, 0, 10, 10, 5, 10, false},
    {0, 0, 10, 10, 10, 5, false},
    {0, 0, 10, 10, -1, -1, false},
    {0, 0, 10, 10, 50, 50, false},
  #if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
    {0, 0, -10, -10, 0, 0, false},
  #endif
  };
  for (size_t i = 0; i < arraysize(contains_cases); ++i) {
    const ContainsCase& value = contains_cases[i];
    Rect rect(value.rect_x, value.rect_y, value.rect_width, value.rect_height);
    EXPECT_EQ(value.contained, rect.Contains(value.point_x, value.point_y));
  }
}

TEST(RectTest, Intersects) {
  static const struct {
    int x1;  // rect 1
    int y1;
    int w1;
    int h1;
    int x2;  // rect 2
    int y2;
    int w2;
    int h2;
    bool intersects;
  } tests[] = {
    { 0, 0, 0, 0, 0, 0, 0, 0, false },
    { 0, 0, 0, 0, -10, -10, 20, 20, false },
    { -10, 0, 0, 20, 0, -10, 20, 0, false },
    { 0, 0, 10, 10, 0, 0, 10, 10, true },
    { 0, 0, 10, 10, 10, 10, 10, 10, false },
    { 10, 10, 10, 10, 0, 0, 10, 10, false },
    { 10, 10, 10, 10, 5, 5, 10, 10, true },
    { 10, 10, 10, 10, 15, 15, 10, 10, true },
    { 10, 10, 10, 10, 20, 15, 10, 10, false },
    { 10, 10, 10, 10, 21, 15, 10, 10, false }
  };
  for (size_t i = 0; i < arraysize(tests); ++i) {
    Rect r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    Rect r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);
    EXPECT_EQ(tests[i].intersects, r1.Intersects(r2));
    EXPECT_EQ(tests[i].intersects, r2.Intersects(r1));
  }
}

TEST(RectTest, Intersect) {
  static const struct {
    int x1;  // rect 1
    int y1;
    int w1;
    int h1;
    int x2;  // rect 2
    int y2;
    int w2;
    int h2;
    int x3;  // rect 3: the union of rects 1 and 2
    int y3;
    int w3;
    int h3;
  } tests[] = {
    { 0, 0, 0, 0,   // zeros
      0, 0, 0, 0,
      0, 0, 0, 0 },
    { 0, 0, 4, 4,   // equal
      0, 0, 4, 4,
      0, 0, 4, 4 },
    { 0, 0, 4, 4,   // neighboring
      4, 4, 4, 4,
      0, 0, 0, 0 },
    { 0, 0, 4, 4,   // overlapping corners
      2, 2, 4, 4,
      2, 2, 2, 2 },
    { 0, 0, 4, 4,   // T junction
      3, 1, 4, 2,
      3, 1, 1, 2 },
    { 3, 0, 2, 2,   // gap
      0, 0, 2, 2,
      0, 0, 0, 0 }
  };
  for (size_t i = 0; i < arraysize(tests); ++i) {
    Rect r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    Rect r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);
    Rect r3(tests[i].x3, tests[i].y3, tests[i].w3, tests[i].h3);
    Rect ir = IntersectRects(r1, r2);
    EXPECT_EQ(r3.x(), ir.x());
    EXPECT_EQ(r3.y(), ir.y());
    EXPECT_EQ(r3.width(), ir.width());
    EXPECT_EQ(r3.height(), ir.height());
  }
}

TEST(RectTest, Union) {
  static const struct Test {
    int x1;  // rect 1
    int y1;
    int w1;
    int h1;
    int x2;  // rect 2
    int y2;
    int w2;
    int h2;
    int x3;  // rect 3: the union of rects 1 and 2
    int y3;
    int w3;
    int h3;
  } tests[] = {
    { 0, 0, 0, 0,
      0, 0, 0, 0,
      0, 0, 0, 0 },
    { 0, 0, 4, 4,
      0, 0, 4, 4,
      0, 0, 4, 4 },
    { 0, 0, 4, 4,
      4, 4, 4, 4,
      0, 0, 8, 8 },
    { 0, 0, 4, 4,
      0, 5, 4, 4,
      0, 0, 4, 9 },
    { 0, 0, 2, 2,
      3, 3, 2, 2,
      0, 0, 5, 5 },
    { 3, 3, 2, 2,   // reverse r1 and r2 from previous test
      0, 0, 2, 2,
      0, 0, 5, 5 },
    { 0, 0, 0, 0,   // union with empty rect
      2, 2, 2, 2,
      2, 2, 2, 2 }
  };
  for (size_t i = 0; i < arraysize(tests); ++i) {
    Rect r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    Rect r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);
    Rect r3(tests[i].x3, tests[i].y3, tests[i].w3, tests[i].h3);
    Rect u = UnionRects(r1, r2);
    EXPECT_EQ(r3.x(), u.x());
    EXPECT_EQ(r3.y(), u.y());
    EXPECT_EQ(r3.width(), u.width());
    EXPECT_EQ(r3.height(), u.height());
  }
}

TEST(RectTest, Equals) {
  ASSERT_TRUE(Rect(0, 0, 0, 0) == Rect(0, 0, 0, 0));
  ASSERT_TRUE(Rect(1, 2, 3, 4) == Rect(1, 2, 3, 4));
  ASSERT_FALSE(Rect(0, 0, 0, 0) == Rect(0, 0, 0, 1));
  ASSERT_FALSE(Rect(0, 0, 0, 0) == Rect(0, 0, 1, 0));
  ASSERT_FALSE(Rect(0, 0, 0, 0) == Rect(0, 1, 0, 0));
  ASSERT_FALSE(Rect(0, 0, 0, 0) == Rect(1, 0, 0, 0));
}

TEST(RectTest, AdjustToFit) {
  static const struct Test {
    int x1;  // source
    int y1;
    int w1;
    int h1;
    int x2;  // target
    int y2;
    int w2;
    int h2;
    int x3;  // rect 3: results of invoking AdjustToFit
    int y3;
    int w3;
    int h3;
  } tests[] = {
    { 0, 0, 2, 2,
      0, 0, 2, 2,
      0, 0, 2, 2 },
    { 2, 2, 3, 3,
      0, 0, 4, 4,
      1, 1, 3, 3 },
    { -1, -1, 5, 5,
      0, 0, 4, 4,
      0, 0, 4, 4 },
    { 2, 2, 4, 4,
      0, 0, 3, 3,
      0, 0, 3, 3 },
    { 2, 2, 1, 1,
      0, 0, 3, 3,
      2, 2, 1, 1 }
  };
  for (size_t i = 0; i < arraysize(tests); ++i) {
    Rect r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    Rect r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);
    Rect r3(tests[i].x3, tests[i].y3, tests[i].w3, tests[i].h3);
    Rect u = r1;
    u.AdjustToFit(r2);
    EXPECT_EQ(r3.x(), u.x());
    EXPECT_EQ(r3.y(), u.y());
    EXPECT_EQ(r3.width(), u.width());
    EXPECT_EQ(r3.height(), u.height());
  }
}

TEST(RectTest, Subtract) {
  Rect result;

  // Matching
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(10, 10, 20, 20));
  EXPECT_EQ(Rect(0, 0, 0, 0), result);

  // Contains
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(5, 5, 30, 30));
  EXPECT_EQ(Rect(0, 0, 0, 0), result);

  // No intersection
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(30, 30, 30, 30));
  EXPECT_EQ(Rect(10, 10, 20, 20), result);

  // Not a complete intersection in either direction
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(15, 15, 20, 20));
  EXPECT_EQ(Rect(10, 10, 20, 20), result);

  // Complete intersection in the x-direction, top edge is fully covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(10, 15, 20, 20));
  EXPECT_EQ(Rect(10, 10, 20, 5), result);

  // Complete intersection in the x-direction, top edge is fully covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(5, 15, 30, 20));
  EXPECT_EQ(Rect(10, 10, 20, 5), result);

  // Complete intersection in the x-direction, bottom edge is fully covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(5, 5, 30, 20));
  EXPECT_EQ(Rect(10, 25, 20, 5), result);

  // Complete intersection in the x-direction, none of the edges is fully
  // covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(5, 15, 30, 1));
  EXPECT_EQ(Rect(10, 10, 20, 20), result);

  // Complete intersection in the y-direction, left edge is fully covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(10, 10, 10, 30));
  EXPECT_EQ(Rect(20, 10, 10, 20), result);

  // Complete intersection in the y-direction, left edge is fully covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(5, 5, 20, 30));
  EXPECT_EQ(Rect(25, 10, 5, 20), result);

  // Complete intersection in the y-direction, right edge is fully covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(20, 5, 20, 30));
  EXPECT_EQ(Rect(10, 10, 10, 20), result);

  // Complete intersection in the y-direction, none of the edges is fully
  // covered.
  result = Rect(10, 10, 20, 20);
  result.Subtract(Rect(15, 5, 1, 30));
  EXPECT_EQ(Rect(10, 10, 20, 20), result);
}

TEST(RectTest, IsEmpty) {
  EXPECT_TRUE(Rect(0, 0, 0, 0).IsEmpty());
  EXPECT_TRUE(Rect(0, 0, 0, 0).size().IsEmpty());
  EXPECT_TRUE(Rect(0, 0, 10, 0).IsEmpty());
  EXPECT_TRUE(Rect(0, 0, 10, 0).size().IsEmpty());
  EXPECT_TRUE(Rect(0, 0, 0, 10).IsEmpty());
  EXPECT_TRUE(Rect(0, 0, 0, 10).size().IsEmpty());
  EXPECT_FALSE(Rect(0, 0, 10, 10).IsEmpty());
  EXPECT_FALSE(Rect(0, 0, 10, 10).size().IsEmpty());
}

TEST(RectTest, SplitVertically) {
  Rect left_half, right_half;

  // Splitting when origin is (0, 0).
  Rect(0, 0, 20, 20).SplitVertically(&left_half, &right_half);
  EXPECT_TRUE(left_half == Rect(0, 0, 10, 20));
  EXPECT_TRUE(right_half == Rect(10, 0, 10, 20));

  // Splitting when origin is arbitrary.
  Rect(10, 10, 20, 10).SplitVertically(&left_half, &right_half);
  EXPECT_TRUE(left_half == Rect(10, 10, 10, 10));
  EXPECT_TRUE(right_half == Rect(20, 10, 10, 10));

  // Splitting a rectangle of zero width.
  Rect(10, 10, 0, 10).SplitVertically(&left_half, &right_half);
  EXPECT_TRUE(left_half == Rect(10, 10, 0, 10));
  EXPECT_TRUE(right_half == Rect(10, 10, 0, 10));

  // Splitting a rectangle of odd width.
  Rect(10, 10, 5, 10).SplitVertically(&left_half, &right_half);
  EXPECT_TRUE(left_half == Rect(10, 10, 2, 10));
  EXPECT_TRUE(right_half == Rect(12, 10, 3, 10));
}

TEST(RectTest, CenterPoint) {
  Point center;

  // When origin is (0, 0).
  center = Rect(0, 0, 20, 20).CenterPoint();
  EXPECT_TRUE(center == Point(10, 10));

  // When origin is even.
  center = Rect(10, 10, 20, 20).CenterPoint();
  EXPECT_TRUE(center == Point(20, 20));

  // When origin is odd.
  center = Rect(11, 11, 20, 20).CenterPoint();
  EXPECT_TRUE(center == Point(21, 21));

  // When 0 width or height.
  center = Rect(10, 10, 0, 20).CenterPoint();
  EXPECT_TRUE(center == Point(10, 20));
  center = Rect(10, 10, 20, 0).CenterPoint();
  EXPECT_TRUE(center == Point(20, 10));

  // When an odd size.
  center = Rect(10, 10, 21, 21).CenterPoint();
  EXPECT_TRUE(center == Point(20, 20));

  // When an odd size and position.
  center = Rect(11, 11, 21, 21).CenterPoint();
  EXPECT_TRUE(center == Point(21, 21));
}

TEST(RectTest, CenterPointF) {
  PointF center;

  // When origin is (0, 0).
  center = RectF(0, 0, 20, 20).CenterPoint();
  EXPECT_TRUE(center == PointF(10, 10));

  // When origin is even.
  center = RectF(10, 10, 20, 20).CenterPoint();
  EXPECT_TRUE(center == PointF(20, 20));

  // When origin is odd.
  center = RectF(11, 11, 20, 20).CenterPoint();
  EXPECT_TRUE(center == PointF(21, 21));

  // When 0 width or height.
  center = RectF(10, 10, 0, 20).CenterPoint();
  EXPECT_TRUE(center == PointF(10, 20));
  center = RectF(10, 10, 20, 0).CenterPoint();
  EXPECT_TRUE(center == PointF(20, 10));

  // When an odd size.
  center = RectF(10, 10, 21, 21).CenterPoint();
  EXPECT_TRUE(center == PointF(20.5f, 20.5f));

  // When an odd size and position.
  center = RectF(11, 11, 21, 21).CenterPoint();
  EXPECT_TRUE(center == PointF(21.5f, 21.5f));
}

TEST(RectTest, SharesEdgeWith) {
  Rect r(2, 3, 4, 5);

  // Must be non-overlapping
  EXPECT_FALSE(r.SharesEdgeWith(r));

  Rect just_above(2, 1, 4, 2);
  Rect just_below(2, 8, 4, 2);
  Rect just_left(0, 3, 2, 5);
  Rect just_right(6, 3, 2, 5);

  EXPECT_TRUE(r.SharesEdgeWith(just_above));
  EXPECT_TRUE(r.SharesEdgeWith(just_below));
  EXPECT_TRUE(r.SharesEdgeWith(just_left));
  EXPECT_TRUE(r.SharesEdgeWith(just_right));

  // Wrong placement
  Rect same_height_no_edge(0, 0, 1, 5);
  Rect same_width_no_edge(0, 0, 4, 1);

  EXPECT_FALSE(r.SharesEdgeWith(same_height_no_edge));
  EXPECT_FALSE(r.SharesEdgeWith(same_width_no_edge));

  Rect just_above_no_edge(2, 1, 5, 2);  // too wide
  Rect just_below_no_edge(2, 8, 3, 2);  // too narrow
  Rect just_left_no_edge(0, 3, 2, 6);   // too tall
  Rect just_right_no_edge(6, 3, 2, 4);  // too short

  EXPECT_FALSE(r.SharesEdgeWith(just_above_no_edge));
  EXPECT_FALSE(r.SharesEdgeWith(just_below_no_edge));
  EXPECT_FALSE(r.SharesEdgeWith(just_left_no_edge));
  EXPECT_FALSE(r.SharesEdgeWith(just_right_no_edge));
}

// Similar to EXPECT_FLOAT_EQ, but lets NaN equal NaN
#define EXPECT_FLOAT_AND_NAN_EQ(a, b) \
  { if (a == a || b == b) { EXPECT_FLOAT_EQ(a, b); } }

TEST(RectTest, ScaleRect) {
  static const struct Test {
    int x1;  // source
    int y1;
    int w1;
    int h1;
    float scale;
    float x2;  // target
    float y2;
    float w2;
    float h2;
  } tests[] = {
    { 3, 3, 3, 3,
      1.5f,
      4.5f, 4.5f, 4.5f, 4.5f },
    { 3, 3, 3, 3,
      0.0f,
      0.0f, 0.0f, 0.0f, 0.0f },
    { 3, 3, 3, 3,
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN() },
    { 3, 3, 3, 3,
      std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max() }
  };

  for (size_t i = 0; i < arraysize(tests); ++i) {
    Rect r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    RectF r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);

    RectF scaled = ScaleRect(r1, tests[i].scale);
    EXPECT_FLOAT_AND_NAN_EQ(r2.x(), scaled.x());
    EXPECT_FLOAT_AND_NAN_EQ(r2.y(), scaled.y());
    EXPECT_FLOAT_AND_NAN_EQ(r2.width(), scaled.width());
    EXPECT_FLOAT_AND_NAN_EQ(r2.height(), scaled.height());
  }
}

TEST(RectTest, ToEnclosedRect) {
  static const struct Test {
    float x1; // source
    float y1;
    float w1;
    float h1;
    int x2; // target
    int y2;
    int w2;
    int h2;
  } tests [] = {
    { 0.0f, 0.0f, 0.0f, 0.0f,
      0, 0, 0, 0 },
    { -1.5f, -1.5f, 3.0f, 3.0f,
      -1, -1, 2, 2 },
    { -1.5f, -1.5f, 3.5f, 3.5f,
      -1, -1, 3, 3 },
    { std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max(),
      2.0f, 2.0f,
      std::numeric_limits<int>::max(),
      std::numeric_limits<int>::max(),
      0, 0 },
    { 0.0f, 0.0f,
      std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max(),
      0, 0,
      std::numeric_limits<int>::max(),
      std::numeric_limits<int>::max() },
    { 20000.5f, 20000.5f, 0.5f, 0.5f,
      20001, 20001, 0, 0 },
    { std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      0, 0, 0, 0 }
  };

  for (size_t i = 0; i < arraysize(tests); ++i) {
    RectF r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    Rect r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);

    Rect enclosed = ToEnclosedRect(r1);
    EXPECT_FLOAT_AND_NAN_EQ(r2.x(), enclosed.x());
    EXPECT_FLOAT_AND_NAN_EQ(r2.y(), enclosed.y());
    EXPECT_FLOAT_AND_NAN_EQ(r2.width(), enclosed.width());
    EXPECT_FLOAT_AND_NAN_EQ(r2.height(), enclosed.height());
  }
}

TEST(RectTest, ToEnclosingRect) {
  static const struct Test {
    float x1; // source
    float y1;
    float w1;
    float h1;
    int x2; // target
    int y2;
    int w2;
    int h2;
  } tests [] = {
    { 0.0f, 0.0f, 0.0f, 0.0f,
      0, 0, 0, 0 },
    { 5.5f, 5.5f, 0.0f, 0.0f,
      5, 5, 0, 0 },
    { -1.5f, -1.5f, 3.0f, 3.0f,
      -2, -2, 4, 4 },
    { -1.5f, -1.5f, 3.5f, 3.5f,
      -2, -2, 4, 4 },
    { std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max(),
      2.0f, 2.0f,
      std::numeric_limits<int>::max(),
      std::numeric_limits<int>::max(),
      0, 0 },
    { 0.0f, 0.0f,
      std::numeric_limits<float>::max(),
      std::numeric_limits<float>::max(),
      0, 0,
      std::numeric_limits<int>::max(),
      std::numeric_limits<int>::max() },
    { 20000.5f, 20000.5f, 0.5f, 0.5f,
      20000, 20000, 1, 1 },
    { std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      std::numeric_limits<float>::quiet_NaN(),
      0, 0, 0, 0 }
  };

  for (size_t i = 0; i < arraysize(tests); ++i) {
    RectF r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    Rect r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);

    Rect enclosed = ToEnclosingRect(r1);
    EXPECT_FLOAT_AND_NAN_EQ(r2.x(), enclosed.x());
    EXPECT_FLOAT_AND_NAN_EQ(r2.y(), enclosed.y());
    EXPECT_FLOAT_AND_NAN_EQ(r2.width(), enclosed.width());
    EXPECT_FLOAT_AND_NAN_EQ(r2.height(), enclosed.height());
  }
}

TEST(RectTest, ToNearestRect) {
  Rect rect;
  EXPECT_EQ(rect, ToNearestRect(RectF(rect)));

  rect = Rect(-1, -1, 3, 3);
  EXPECT_EQ(rect, ToNearestRect(RectF(rect)));

  RectF rectf(-1.00001f, -0.999999f, 3.0000001f, 2.999999f);
  EXPECT_EQ(rect, ToNearestRect(rectf));
}

TEST(RectTest, ToFlooredRect) {
  static const struct Test {
    float x1; // source
    float y1;
    float w1;
    float h1;
    int x2; // target
    int y2;
    int w2;
    int h2;
  } tests [] = {
    { 0.0f, 0.0f, 0.0f, 0.0f,
      0, 0, 0, 0 },
    { -1.5f, -1.5f, 3.0f, 3.0f,
      -2, -2, 3, 3 },
    { -1.5f, -1.5f, 3.5f, 3.5f,
      -2, -2, 3, 3 },
    { 20000.5f, 20000.5f, 0.5f, 0.5f,
      20000, 20000, 0, 0 },
  };

  for (size_t i = 0; i < arraysize(tests); ++i) {
    RectF r1(tests[i].x1, tests[i].y1, tests[i].w1, tests[i].h1);
    Rect r2(tests[i].x2, tests[i].y2, tests[i].w2, tests[i].h2);

    Rect floored = ToFlooredRectDeprecated(r1);
    EXPECT_FLOAT_EQ(r2.x(), floored.x());
    EXPECT_FLOAT_EQ(r2.y(), floored.y());
    EXPECT_FLOAT_EQ(r2.width(), floored.width());
    EXPECT_FLOAT_EQ(r2.height(), floored.height());
  }
}

TEST(RectTest, ScaleToEnclosedRect) {
  static const struct Test {
    Rect input_rect;
    float input_scale;
    Rect expected_rect;
  } tests[] = {
    {
      Rect(),
      5.f,
      Rect(),
    }, {
      Rect(1, 1, 1, 1),
      5.f,
      Rect(5, 5, 5, 5),
    }, {
      Rect(-1, -1, 0, 0),
      5.f,
      Rect(-5, -5, 0, 0),
    }, {
      Rect(1, -1, 0, 1),
      5.f,
      Rect(5, -5, 0, 5),
    }, {
      Rect(-1, 1, 1, 0),
      5.f,
      Rect(-5, 5, 5, 0),
    }, {
      Rect(1, 2, 3, 4),
      1.5f,
      Rect(2, 3, 4, 6),
    }, {
      Rect(-1, -2, 0, 0),
      1.5f,
      Rect(-1, -3, 0, 0),
    }
  };

  for (size_t i = 0; i < arraysize(tests); ++i) {
    Rect result = ScaleToEnclosedRect(tests[i].input_rect,
                                      tests[i].input_scale);
    EXPECT_EQ(tests[i].expected_rect, result);
  }
}

TEST(RectTest, ScaleToEnclosingRect) {
  static const struct Test {
    Rect input_rect;
    float input_scale;
    Rect expected_rect;
  } tests[] = {
    {
      Rect(),
      5.f,
      Rect(),
    }, {
      Rect(1, 1, 1, 1),
      5.f,
      Rect(5, 5, 5, 5),
    }, {
      Rect(-1, -1, 0, 0),
      5.f,
      Rect(-5, -5, 0, 0),
    }, {
      Rect(1, -1, 0, 1),
      5.f,
      Rect(5, -5, 0, 5),
    }, {
      Rect(-1, 1, 1, 0),
      5.f,
      Rect(-5, 5, 5, 0),
    }, {
      Rect(1, 2, 3, 4),
      1.5f,
      Rect(1, 3, 5, 6),
    }, {
      Rect(-1, -2, 0, 0),
      1.5f,
      Rect(-2, -3, 0, 0),
    }
  };

  for (size_t i = 0; i < arraysize(tests); ++i) {
    Rect result = ScaleToEnclosingRect(tests[i].input_rect,
                                       tests[i].input_scale);
    EXPECT_EQ(tests[i].expected_rect, result);
  }
}

TEST(RectTest, ToRectF) {
  // Check that implicit conversion from integer to float compiles.
  Rect a(10, 20, 30, 40);
  RectF b(10, 20, 30, 40);

  RectF intersect = IntersectRects(a, b);
  EXPECT_EQ(b, intersect);

  EXPECT_EQ(a, b);
  EXPECT_EQ(b, a);
}

TEST(RectTest, BoundingRect) {
  struct {
    Point a;
    Point b;
    Rect expected;
  } int_tests[] = {
    // If point B dominates A, then A should be the origin.
    { Point(4, 6), Point(4, 6), Rect(4, 6, 0, 0) },
    { Point(4, 6), Point(8, 6), Rect(4, 6, 4, 0) },
    { Point(4, 6), Point(4, 9), Rect(4, 6, 0, 3) },
    { Point(4, 6), Point(8, 9), Rect(4, 6, 4, 3) },
    // If point A dominates B, then B should be the origin.
    { Point(4, 6), Point(4, 6), Rect(4, 6, 0, 0) },
    { Point(8, 6), Point(4, 6), Rect(4, 6, 4, 0) },
    { Point(4, 9), Point(4, 6), Rect(4, 6, 0, 3) },
    { Point(8, 9), Point(4, 6), Rect(4, 6, 4, 3) },
    // If neither point dominates, then the origin is a combination of the two.
    { Point(4, 6), Point(6, 4), Rect(4, 4, 2, 2) },
    { Point(-4, -6), Point(-6, -4), Rect(-6, -6, 2, 2) },
    { Point(-4, 6), Point(6, -4), Rect(-4, -4, 10, 10) },
  };

  for (size_t i = 0; i < arraysize(int_tests); ++i) {
    Rect actual = BoundingRect(int_tests[i].a, int_tests[i].b);
    EXPECT_EQ(int_tests[i].expected, actual);
  }

  struct {
    PointF a;
    PointF b;
    RectF expected;
  } float_tests[] = {
    // If point B dominates A, then A should be the origin.
    { PointF(4.2f, 6.8f), PointF(4.2f, 6.8f),
      RectF(4.2f, 6.8f, 0, 0) },
    { PointF(4.2f, 6.8f), PointF(8.5f, 6.8f),
      RectF(4.2f, 6.8f, 4.3f, 0) },
    { PointF(4.2f, 6.8f), PointF(4.2f, 9.3f),
      RectF(4.2f, 6.8f, 0, 2.5f) },
    { PointF(4.2f, 6.8f), PointF(8.5f, 9.3f),
      RectF(4.2f, 6.8f, 4.3f, 2.5f) },
    // If point A dominates B, then B should be the origin.
    { PointF(4.2f, 6.8f), PointF(4.2f, 6.8f),
      RectF(4.2f, 6.8f, 0, 0) },
    { PointF(8.5f, 6.8f), PointF(4.2f, 6.8f),
      RectF(4.2f, 6.8f, 4.3f, 0) },
    { PointF(4.2f, 9.3f), PointF(4.2f, 6.8f),
      RectF(4.2f, 6.8f, 0, 2.5f) },
    { PointF(8.5f, 9.3f), PointF(4.2f, 6.8f),
      RectF(4.2f, 6.8f, 4.3f, 2.5f) },
    // If neither point dominates, then the origin is a combination of the two.
    { PointF(4.2f, 6.8f), PointF(6.8f, 4.2f),
      RectF(4.2f, 4.2f, 2.6f, 2.6f) },
    { PointF(-4.2f, -6.8f), PointF(-6.8f, -4.2f),
      RectF(-6.8f, -6.8f, 2.6f, 2.6f) },
    { PointF(-4.2f, 6.8f), PointF(6.8f, -4.2f),
      RectF(-4.2f, -4.2f, 11.0f, 11.0f) }
  };

  for (size_t i = 0; i < arraysize(float_tests); ++i) {
    RectF actual = BoundingRect(float_tests[i].a, float_tests[i].b);
    EXPECT_RECTF_EQ(float_tests[i].expected, actual);
  }
}

TEST(RectTest, IsExpressibleAsRect) {
  EXPECT_TRUE(RectF().IsExpressibleAsRect());

  float min = std::numeric_limits<int>::min();
  float max = std::numeric_limits<int>::max();
  float infinity = std::numeric_limits<float>::infinity();

  EXPECT_TRUE(RectF(
      min + 200, min + 200, max - 200, max - 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(
      min - 200, min + 200, max + 200, max + 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(
      min + 200 , min - 200, max + 200, max + 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(
      min + 200, min + 200, max + 200, max - 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(
      min + 200, min + 200, max - 200, max + 200).IsExpressibleAsRect());

  EXPECT_TRUE(RectF(0, 0, max - 200, max - 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(200, 0, max + 200, max - 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(0, 200, max - 200, max + 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(0, 0, max + 200, max - 200).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(0, 0, max - 200, max + 200).IsExpressibleAsRect());

  EXPECT_FALSE(RectF(infinity, 0, 1, 1).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(0, infinity, 1, 1).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(0, 0, infinity, 1).IsExpressibleAsRect());
  EXPECT_FALSE(RectF(0, 0, 1, infinity).IsExpressibleAsRect());
}

TEST(RectTest, Offset) {
  Rect i(1, 2, 3, 4);

  EXPECT_EQ(Rect(2, 1, 3, 4), (i + Vector2d(1, -1)));
  EXPECT_EQ(Rect(2, 1, 3, 4), (Vector2d(1, -1) + i));
  i += Vector2d(1, -1);
  EXPECT_EQ(Rect(2, 1, 3, 4), i);
  EXPECT_EQ(Rect(1, 2, 3, 4), (i - Vector2d(1, -1)));
  i -= Vector2d(1, -1);
  EXPECT_EQ(Rect(1, 2, 3, 4), i);

  RectF f(1.1f, 2.2f, 3.3f, 4.4f);
  EXPECT_EQ(RectF(2.2f, 1.1f, 3.3f, 4.4f), (f + Vector2dF(1.1f, -1.1f)));
  EXPECT_EQ(RectF(2.2f, 1.1f, 3.3f, 4.4f), (Vector2dF(1.1f, -1.1f) + f));
  f += Vector2dF(1.1f, -1.1f);
  EXPECT_EQ(RectF(2.2f, 1.1f, 3.3f, 4.4f), f);
  EXPECT_EQ(RectF(1.1f, 2.2f, 3.3f, 4.4f), (f - Vector2dF(1.1f, -1.1f)));
  f -= Vector2dF(1.1f, -1.1f);
  EXPECT_EQ(RectF(1.1f, 2.2f, 3.3f, 4.4f), f);
}

TEST(RectTest, Corners) {
  Rect i(1, 2, 3, 4);
  RectF f(1.1f, 2.1f, 3.1f, 4.1f);

  EXPECT_EQ(Point(1, 2), i.origin());
  EXPECT_EQ(Point(4, 2), i.top_right());
  EXPECT_EQ(Point(1, 6), i.bottom_left());
  EXPECT_EQ(Point(4, 6), i.bottom_right());

  EXPECT_EQ(PointF(1.1f, 2.1f), f.origin());
  EXPECT_EQ(PointF(4.2f, 2.1f), f.top_right());
  EXPECT_EQ(PointF(1.1f, 6.2f), f.bottom_left());
  EXPECT_EQ(PointF(4.2f, 6.2f), f.bottom_right());
}

TEST(RectTest, ManhattanDistanceToPoint) {
  Rect i(1, 2, 3, 4);
  EXPECT_EQ(0, i.ManhattanDistanceToPoint(Point(1, 2)));
  EXPECT_EQ(0, i.ManhattanDistanceToPoint(Point(4, 6)));
  EXPECT_EQ(0, i.ManhattanDistanceToPoint(Point(2, 4)));
  EXPECT_EQ(3, i.ManhattanDistanceToPoint(Point(0, 0)));
  EXPECT_EQ(2, i.ManhattanDistanceToPoint(Point(2, 0)));
  EXPECT_EQ(3, i.ManhattanDistanceToPoint(Point(5, 0)));
  EXPECT_EQ(1, i.ManhattanDistanceToPoint(Point(5, 4)));
  EXPECT_EQ(3, i.ManhattanDistanceToPoint(Point(5, 8)));
  EXPECT_EQ(2, i.ManhattanDistanceToPoint(Point(3, 8)));
  EXPECT_EQ(2, i.ManhattanDistanceToPoint(Point(0, 7)));
  EXPECT_EQ(1, i.ManhattanDistanceToPoint(Point(0, 3)));

  RectF f(1.1f, 2.1f, 3.1f, 4.1f);
  EXPECT_FLOAT_EQ(0.f, f.ManhattanDistanceToPoint(PointF(1.1f, 2.1f)));
  EXPECT_FLOAT_EQ(0.f, f.ManhattanDistanceToPoint(PointF(4.2f, 6.f)));
  EXPECT_FLOAT_EQ(0.f, f.ManhattanDistanceToPoint(PointF(2.f, 4.f)));
  EXPECT_FLOAT_EQ(3.2f, f.ManhattanDistanceToPoint(PointF(0.f, 0.f)));
  EXPECT_FLOAT_EQ(2.1f, f.ManhattanDistanceToPoint(PointF(2.f, 0.f)));
  EXPECT_FLOAT_EQ(2.9f, f.ManhattanDistanceToPoint(PointF(5.f, 0.f)));
  EXPECT_FLOAT_EQ(.8f, f.ManhattanDistanceToPoint(PointF(5.f, 4.f)));
  EXPECT_FLOAT_EQ(2.6f, f.ManhattanDistanceToPoint(PointF(5.f, 8.f)));
  EXPECT_FLOAT_EQ(1.8f, f.ManhattanDistanceToPoint(PointF(3.f, 8.f)));
  EXPECT_FLOAT_EQ(1.9f, f.ManhattanDistanceToPoint(PointF(0.f, 7.f)));
  EXPECT_FLOAT_EQ(1.1f, f.ManhattanDistanceToPoint(PointF(0.f, 3.f)));
}

TEST(RectTest, ManhattanInternalDistance) {
  Rect i(0, 0, 400, 400);
  EXPECT_EQ(0, i.ManhattanInternalDistance(gfx::Rect(-1, 0, 2, 1)));
  EXPECT_EQ(1, i.ManhattanInternalDistance(gfx::Rect(400, 0, 1, 400)));
  EXPECT_EQ(2, i.ManhattanInternalDistance(gfx::Rect(-100, -100, 100, 100)));
  EXPECT_EQ(2, i.ManhattanInternalDistance(gfx::Rect(-101, 100, 100, 100)));
  EXPECT_EQ(4, i.ManhattanInternalDistance(gfx::Rect(-101, -101, 100, 100)));
  EXPECT_EQ(435, i.ManhattanInternalDistance(gfx::Rect(630, 603, 100, 100)));

  RectF f(0.0f, 0.0f, 400.0f, 400.0f);
  static const float kEpsilon = std::numeric_limits<float>::epsilon();

  EXPECT_FLOAT_EQ(
      0.0f, f.ManhattanInternalDistance(gfx::RectF(-1.0f, 0.0f, 2.0f, 1.0f)));
  EXPECT_FLOAT_EQ(
      kEpsilon,
      f.ManhattanInternalDistance(gfx::RectF(400.0f, 0.0f, 1.0f, 400.0f)));
  EXPECT_FLOAT_EQ(2.0f * kEpsilon,
                  f.ManhattanInternalDistance(
                      gfx::RectF(-100.0f, -100.0f, 100.0f, 100.0f)));
  EXPECT_FLOAT_EQ(
      1.0f + kEpsilon,
      f.ManhattanInternalDistance(gfx::RectF(-101.0f, 100.0f, 100.0f, 100.0f)));
  EXPECT_FLOAT_EQ(2.0f + 2.0f * kEpsilon,
                  f.ManhattanInternalDistance(
                      gfx::RectF(-101.0f, -101.0f, 100.0f, 100.0f)));
  EXPECT_FLOAT_EQ(
      433.0f + 2.0f * kEpsilon,
      f.ManhattanInternalDistance(gfx::RectF(630.0f, 603.0f, 100.0f, 100.0f)));

  EXPECT_FLOAT_EQ(
      0.0f, f.ManhattanInternalDistance(gfx::RectF(-1.0f, 0.0f, 1.1f, 1.0f)));
  EXPECT_FLOAT_EQ(
      0.1f + kEpsilon,
      f.ManhattanInternalDistance(gfx::RectF(-1.5f, 0.0f, 1.4f, 1.0f)));
  EXPECT_FLOAT_EQ(
      kEpsilon,
      f.ManhattanInternalDistance(gfx::RectF(-1.5f, 0.0f, 1.5f, 1.0f)));
}

}  // namespace gfx

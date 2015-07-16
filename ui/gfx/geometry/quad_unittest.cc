// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/geometry/quad_f.h"
#include "ui/gfx/geometry/rect_f.h"

namespace gfx {

TEST(QuadTest, Construction) {
  // Verify constructors.
  PointF a(1, 1);
  PointF b(2, 1);
  PointF c(2, 2);
  PointF d(1, 2);
  PointF e;
  QuadF q1;
  QuadF q2(e, e, e, e);
  QuadF q3(a, b, c, d);
  QuadF q4(BoundingRect(a, c));
  EXPECT_EQ(q1, q2);
  EXPECT_EQ(q3, q4);

  // Verify getters.
  EXPECT_EQ(q3.p1(), a);
  EXPECT_EQ(q3.p2(), b);
  EXPECT_EQ(q3.p3(), c);
  EXPECT_EQ(q3.p4(), d);

  // Verify setters.
  q3.set_p1(b);
  q3.set_p2(c);
  q3.set_p3(d);
  q3.set_p4(a);
  EXPECT_EQ(q3.p1(), b);
  EXPECT_EQ(q3.p2(), c);
  EXPECT_EQ(q3.p3(), d);
  EXPECT_EQ(q3.p4(), a);

  // Verify operator=(Rect)
  EXPECT_NE(q1, q4);
  q1 = BoundingRect(a, c);
  EXPECT_EQ(q1, q4);

  // Verify operator=(Quad)
  EXPECT_NE(q1, q3);
  q1 = q3;
  EXPECT_EQ(q1, q3);
}

TEST(QuadTest, AddingVectors) {
  PointF a(1, 1);
  PointF b(2, 1);
  PointF c(2, 2);
  PointF d(1, 2);
  Vector2dF v(3.5f, -2.5f);

  QuadF q1(a, b, c, d);
  QuadF added = q1 + v;
  q1 += v;
  QuadF expected1(PointF(4.5f, -1.5f),
                  PointF(5.5f, -1.5f),
                  PointF(5.5f, -0.5f),
                  PointF(4.5f, -0.5f));
  EXPECT_EQ(expected1, added);
  EXPECT_EQ(expected1, q1);

  QuadF q2(a, b, c, d);
  QuadF subtracted = q2 - v;
  q2 -= v;
  QuadF expected2(PointF(-2.5f, 3.5f),
                  PointF(-1.5f, 3.5f),
                  PointF(-1.5f, 4.5f),
                  PointF(-2.5f, 4.5f));
  EXPECT_EQ(expected2, subtracted);
  EXPECT_EQ(expected2, q2);

  QuadF q3(a, b, c, d);
  q3 += v;
  q3 -= v;
  EXPECT_EQ(QuadF(a, b, c, d), q3);
  EXPECT_EQ(q3, (q3 + v - v));
}

TEST(QuadTest, IsRectilinear) {
  PointF a(1, 1);
  PointF b(2, 1);
  PointF c(2, 2);
  PointF d(1, 2);
  Vector2dF v(3.5f, -2.5f);

  EXPECT_TRUE(QuadF().IsRectilinear());
  EXPECT_TRUE(QuadF(a, b, c, d).IsRectilinear());
  EXPECT_TRUE((QuadF(a, b, c, d) + v).IsRectilinear());

  float epsilon = std::numeric_limits<float>::epsilon();
  PointF a2(1 + epsilon / 2, 1 + epsilon / 2);
  PointF b2(2 + epsilon / 2, 1 + epsilon / 2);
  PointF c2(2 + epsilon / 2, 2 + epsilon / 2);
  PointF d2(1 + epsilon / 2, 2 + epsilon / 2);
  EXPECT_TRUE(QuadF(a2, b, c, d).IsRectilinear());
  EXPECT_TRUE((QuadF(a2, b, c, d) + v).IsRectilinear());
  EXPECT_TRUE(QuadF(a, b2, c, d).IsRectilinear());
  EXPECT_TRUE((QuadF(a, b2, c, d) + v).IsRectilinear());
  EXPECT_TRUE(QuadF(a, b, c2, d).IsRectilinear());
  EXPECT_TRUE((QuadF(a, b, c2, d) + v).IsRectilinear());
  EXPECT_TRUE(QuadF(a, b, c, d2).IsRectilinear());
  EXPECT_TRUE((QuadF(a, b, c, d2) + v).IsRectilinear());

  struct {
    PointF a_off, b_off, c_off, d_off;
  } tests[] = {
    {
      PointF(1, 1.00001f),
      PointF(2, 1.00001f),
      PointF(2, 2.00001f),
      PointF(1, 2.00001f)
    },
    {
      PointF(1.00001f, 1),
      PointF(2.00001f, 1),
      PointF(2.00001f, 2),
      PointF(1.00001f, 2)
    },
    {
      PointF(1.00001f, 1.00001f),
      PointF(2.00001f, 1.00001f),
      PointF(2.00001f, 2.00001f),
      PointF(1.00001f, 2.00001f)
    },
    {
      PointF(1, 0.99999f),
      PointF(2, 0.99999f),
      PointF(2, 1.99999f),
      PointF(1, 1.99999f)
    },
    {
      PointF(0.99999f, 1),
      PointF(1.99999f, 1),
      PointF(1.99999f, 2),
      PointF(0.99999f, 2)
    },
    {
      PointF(0.99999f, 0.99999f),
      PointF(1.99999f, 0.99999f),
      PointF(1.99999f, 1.99999f),
      PointF(0.99999f, 1.99999f)
    }
  };

  for (size_t i = 0; i < arraysize(tests); ++i) {
    PointF a_off = tests[i].a_off;
    PointF b_off = tests[i].b_off;
    PointF c_off = tests[i].c_off;
    PointF d_off = tests[i].d_off;

    EXPECT_FALSE(QuadF(a_off, b, c, d).IsRectilinear());
    EXPECT_FALSE((QuadF(a_off, b, c, d) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a, b_off, c, d).IsRectilinear());
    EXPECT_FALSE((QuadF(a, b_off, c, d) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a, b, c_off, d).IsRectilinear());
    EXPECT_FALSE((QuadF(a, b, c_off, d) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a, b, c, d_off).IsRectilinear());
    EXPECT_FALSE((QuadF(a, b, c, d_off) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a_off, b, c_off, d).IsRectilinear());
    EXPECT_FALSE((QuadF(a_off, b, c_off, d) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a, b_off, c, d_off).IsRectilinear());
    EXPECT_FALSE((QuadF(a, b_off, c, d_off) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a, b_off, c_off, d_off).IsRectilinear());
    EXPECT_FALSE((QuadF(a, b_off, c_off, d_off) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a_off, b, c_off, d_off).IsRectilinear());
    EXPECT_FALSE((QuadF(a_off, b, c_off, d_off) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a_off, b_off, c, d_off).IsRectilinear());
    EXPECT_FALSE((QuadF(a_off, b_off, c, d_off) + v).IsRectilinear());
    EXPECT_FALSE(QuadF(a_off, b_off, c_off, d).IsRectilinear());
    EXPECT_FALSE((QuadF(a_off, b_off, c_off, d) + v).IsRectilinear());
    EXPECT_TRUE(QuadF(a_off, b_off, c_off, d_off).IsRectilinear());
    EXPECT_TRUE((QuadF(a_off, b_off, c_off, d_off) + v).IsRectilinear());
  }
}

TEST(QuadTest, IsCounterClockwise) {
  PointF a1(1, 1);
  PointF b1(2, 1);
  PointF c1(2, 2);
  PointF d1(1, 2);
  EXPECT_FALSE(QuadF(a1, b1, c1, d1).IsCounterClockwise());
  EXPECT_FALSE(QuadF(b1, c1, d1, a1).IsCounterClockwise());
  EXPECT_TRUE(QuadF(a1, d1, c1, b1).IsCounterClockwise());
  EXPECT_TRUE(QuadF(c1, b1, a1, d1).IsCounterClockwise());

  // Slightly more complicated quads should work just as easily.
  PointF a2(1.3f, 1.4f);
  PointF b2(-0.7f, 4.9f);
  PointF c2(1.8f, 6.2f);
  PointF d2(2.1f, 1.6f);
  EXPECT_TRUE(QuadF(a2, b2, c2, d2).IsCounterClockwise());
  EXPECT_TRUE(QuadF(b2, c2, d2, a2).IsCounterClockwise());
  EXPECT_FALSE(QuadF(a2, d2, c2, b2).IsCounterClockwise());
  EXPECT_FALSE(QuadF(c2, b2, a2, d2).IsCounterClockwise());

  // Quads with 3 collinear points should work correctly, too.
  PointF a3(0, 0);
  PointF b3(1, 0);
  PointF c3(2, 0);
  PointF d3(1, 1);
  EXPECT_FALSE(QuadF(a3, b3, c3, d3).IsCounterClockwise());
  EXPECT_FALSE(QuadF(b3, c3, d3, a3).IsCounterClockwise());
  EXPECT_TRUE(QuadF(a3, d3, c3, b3).IsCounterClockwise());
  // The next expectation in particular would fail for an implementation
  // that incorrectly uses only a cross product of the first 3 vertices.
  EXPECT_TRUE(QuadF(c3, b3, a3, d3).IsCounterClockwise());

  // Non-convex quads should work correctly, too.
  PointF a4(0, 0);
  PointF b4(1, 1);
  PointF c4(2, 0);
  PointF d4(1, 3);
  EXPECT_FALSE(QuadF(a4, b4, c4, d4).IsCounterClockwise());
  EXPECT_FALSE(QuadF(b4, c4, d4, a4).IsCounterClockwise());
  EXPECT_TRUE(QuadF(a4, d4, c4, b4).IsCounterClockwise());
  EXPECT_TRUE(QuadF(c4, b4, a4, d4).IsCounterClockwise());

  // A quad with huge coordinates should not fail this check due to
  // single-precision overflow.
  PointF a5(1e30f, 1e30f);
  PointF b5(1e35f, 1e30f);
  PointF c5(1e35f, 1e35f);
  PointF d5(1e30f, 1e35f);
  EXPECT_FALSE(QuadF(a5, b5, c5, d5).IsCounterClockwise());
  EXPECT_FALSE(QuadF(b5, c5, d5, a5).IsCounterClockwise());
  EXPECT_TRUE(QuadF(a5, d5, c5, b5).IsCounterClockwise());
  EXPECT_TRUE(QuadF(c5, b5, a5, d5).IsCounterClockwise());
}

TEST(QuadTest, BoundingBox) {
  RectF r(3.2f, 5.4f, 7.007f, 12.01f);
  EXPECT_EQ(r, QuadF(r).BoundingBox());

  PointF a(1.3f, 1.4f);
  PointF b(-0.7f, 4.9f);
  PointF c(1.8f, 6.2f);
  PointF d(2.1f, 1.6f);
  float left = -0.7f;
  float top = 1.4f;
  float right = 2.1f;
  float bottom = 6.2f;
  EXPECT_EQ(RectF(left, top, right - left, bottom - top),
            QuadF(a, b, c, d).BoundingBox());
}

TEST(QuadTest, ContainsPoint) {
  PointF a(1.3f, 1.4f);
  PointF b(-0.8f, 4.4f);
  PointF c(1.8f, 6.1f);
  PointF d(2.1f, 1.6f);

  Vector2dF epsilon_x(2 * std::numeric_limits<float>::epsilon(), 0);
  Vector2dF epsilon_y(0, 2 * std::numeric_limits<float>::epsilon());

  Vector2dF ac_center = c - a;
  ac_center.Scale(0.5f);
  Vector2dF bd_center = d - b;
  bd_center.Scale(0.5f);

  EXPECT_TRUE(QuadF(a, b, c, d).Contains(a + ac_center));
  EXPECT_TRUE(QuadF(a, b, c, d).Contains(b + bd_center));
  EXPECT_TRUE(QuadF(a, b, c, d).Contains(c - ac_center));
  EXPECT_TRUE(QuadF(a, b, c, d).Contains(d - bd_center));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(a - ac_center));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(b - bd_center));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(c + ac_center));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(d + bd_center));

  EXPECT_TRUE(QuadF(a, b, c, d).Contains(a));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(a - epsilon_x));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(a - epsilon_y));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(a + epsilon_x));
  EXPECT_TRUE(QuadF(a, b, c, d).Contains(a + epsilon_y));

  EXPECT_TRUE(QuadF(a, b, c, d).Contains(b));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(b - epsilon_x));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(b - epsilon_y));
  EXPECT_TRUE(QuadF(a, b, c, d).Contains(b + epsilon_x));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(b + epsilon_y));

  EXPECT_TRUE(QuadF(a, b, c, d).Contains(c));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(c - epsilon_x));
  EXPECT_TRUE(QuadF(a, b, c, d).Contains(c - epsilon_y));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(c + epsilon_x));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(c + epsilon_y));

  EXPECT_TRUE(QuadF(a, b, c, d).Contains(d));
  EXPECT_TRUE(QuadF(a, b, c, d).Contains(d - epsilon_x));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(d - epsilon_y));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(d + epsilon_x));
  EXPECT_FALSE(QuadF(a, b, c, d).Contains(d + epsilon_y));

  // Test a simple square.
  PointF s1(-1, -1);
  PointF s2(1, -1);
  PointF s3(1, 1);
  PointF s4(-1, 1);
  // Top edge.
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.1f, -1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.0f, -1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(0.0f, -1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(1.0f, -1.0f)));
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(1.1f, -1.0f)));
  // Bottom edge.
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.1f, 1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.0f, 1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(0.0f, 1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(1.0f, 1.0f)));
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(1.1f, 1.0f)));
  // Left edge.
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.0f, -1.1f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.0f, -1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.0f, 0.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.0f, 1.0f)));
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.0f, 1.1f)));
  // Right edge.
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(1.0f, -1.1f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(1.0f, -1.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(1.0f, 0.0f)));
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(1.0f, 1.0f)));
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(1.0f, 1.1f)));
  // Centered inside.
  EXPECT_TRUE(QuadF(s1, s2, s3, s4).Contains(PointF(0, 0)));
  // Centered outside.
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(-1.1f, 0)));
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(1.1f, 0)));
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(0, -1.1f)));
  EXPECT_FALSE(QuadF(s1, s2, s3, s4).Contains(PointF(0, 1.1f)));
}

TEST(QuadTest, Scale) {
  PointF a(1.3f, 1.4f);
  PointF b(-0.8f, 4.4f);
  PointF c(1.8f, 6.1f);
  PointF d(2.1f, 1.6f);
  QuadF q1(a, b, c, d);
  q1.Scale(1.5f);

  PointF a_scaled = ScalePoint(a, 1.5f);
  PointF b_scaled = ScalePoint(b, 1.5f);
  PointF c_scaled = ScalePoint(c, 1.5f);
  PointF d_scaled = ScalePoint(d, 1.5f);
  EXPECT_EQ(q1, QuadF(a_scaled, b_scaled, c_scaled, d_scaled));

  QuadF q2;
  q2.Scale(1.5f);
  EXPECT_EQ(q2, q2);
}

}  // namespace gfx

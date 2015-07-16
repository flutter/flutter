// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <limits>

#include "base/basictypes.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/geometry/scroll_offset.h"

namespace gfx {

TEST(ScrollOffsetTest, IsZero) {
  ScrollOffset zero(0, 0);
  ScrollOffset nonzero(0.1, -0.1);

  EXPECT_TRUE(zero.IsZero());
  EXPECT_FALSE(nonzero.IsZero());
}

TEST(ScrollOffsetTest, Add) {
  ScrollOffset f1(3.1, 5.1);
  ScrollOffset f2(4.3, -1.3);

  const struct {
    ScrollOffset expected;
    ScrollOffset actual;
  } scroll_offset_tests[] = {
    { ScrollOffset(3.1, 5.1), f1 + ScrollOffset() },
    { ScrollOffset(3.1 + 4.3, 5.1f - 1.3), f1 + f2 },
    { ScrollOffset(3.1 - 4.3, 5.1f + 1.3), f1 - f2 }
  };

  for (size_t i = 0; i < arraysize(scroll_offset_tests); ++i)
    EXPECT_EQ(scroll_offset_tests[i].expected.ToString(),
              scroll_offset_tests[i].actual.ToString());
}

TEST(ScrollOffsetTest, Negative) {
  const struct {
    ScrollOffset expected;
    ScrollOffset actual;
  } scroll_offset_tests[] = {
    { ScrollOffset(-0.3, -0.3), -ScrollOffset(0.3, 0.3) },
    { ScrollOffset(0.3, 0.3), -ScrollOffset(-0.3, -0.3) },
    { ScrollOffset(-0.3, 0.3), -ScrollOffset(0.3, -0.3) },
    { ScrollOffset(0.3, -0.3), -ScrollOffset(-0.3, 0.3) }
  };

  for (size_t i = 0; i < arraysize(scroll_offset_tests); ++i)
    EXPECT_EQ(scroll_offset_tests[i].expected.ToString(),
              scroll_offset_tests[i].actual.ToString());
}

TEST(ScrollOffsetTest, Scale) {
  double double_values[][4] = {
    { 4.5, 1.2, 3.3, 5.6 },
    { 4.5, -1.2, 3.3, 5.6 },
    { 4.5, 1.2, 3.3, -5.6 },
    { 4.5, 1.2, -3.3, -5.6 },
    { -4.5, 1.2, 3.3, 5.6 },
    { -4.5, 1.2, 0, 5.6 },
    { -4.5, 1.2, 3.3, 0 },
    { 4.5, 0, 3.3, 5.6 },
    { 0, 1.2, 3.3, 5.6 }
  };

  for (size_t i = 0; i < arraysize(double_values); ++i) {
    ScrollOffset v(double_values[i][0], double_values[i][1]);
    v.Scale(double_values[i][2], double_values[i][3]);
    EXPECT_EQ(v.x(), double_values[i][0] * double_values[i][2]);
    EXPECT_EQ(v.y(), double_values[i][1] * double_values[i][3]);
  }

  double single_values[][3] = {
    { 4.5, 1.2, 3.3 },
    { 4.5, -1.2, 3.3 },
    { 4.5, 1.2, 3.3 },
    { 4.5, 1.2, -3.3 },
    { -4.5, 1.2, 3.3 },
    { -4.5, 1.2, 0 },
    { -4.5, 1.2, 3.3 },
    { 4.5, 0, 3.3 },
    { 0, 1.2, 3.3 }
  };

  for (size_t i = 0; i < arraysize(single_values); ++i) {
    ScrollOffset v(single_values[i][0], single_values[i][1]);
    v.Scale(single_values[i][2]);
    EXPECT_EQ(v.x(), single_values[i][0] * single_values[i][2]);
    EXPECT_EQ(v.y(), single_values[i][1] * single_values[i][2]);
  }
}

TEST(ScrollOffsetTest, ClampScrollOffset) {
  ScrollOffset a;

  a = ScrollOffset(3.5, 5.5);
  EXPECT_EQ(ScrollOffset(3.5, 5.5).ToString(), a.ToString());
  a.SetToMax(ScrollOffset(2.5, 4.5));
  EXPECT_EQ(ScrollOffset(3.5, 5.5).ToString(), a.ToString());
  a.SetToMax(ScrollOffset(3.5, 5.5));
  EXPECT_EQ(ScrollOffset(3.5, 5.5).ToString(), a.ToString());
  a.SetToMax(ScrollOffset(4.5, 2.5));
  EXPECT_EQ(ScrollOffset(4.5, 5.5).ToString(), a.ToString());
  a.SetToMax(ScrollOffset(8.5, 10.5));
  EXPECT_EQ(ScrollOffset(8.5, 10.5).ToString(), a.ToString());

  a.SetToMin(ScrollOffset(9.5, 11.5));
  EXPECT_EQ(ScrollOffset(8.5, 10.5).ToString(), a.ToString());
  a.SetToMin(ScrollOffset(8.5, 10.5));
  EXPECT_EQ(ScrollOffset(8.5, 10.5).ToString(), a.ToString());
  a.SetToMin(ScrollOffset(11.5, 9.5));
  EXPECT_EQ(ScrollOffset(8.5, 9.5).ToString(), a.ToString());
  a.SetToMin(ScrollOffset(7.5, 11.5));
  EXPECT_EQ(ScrollOffset(7.5, 9.5).ToString(), a.ToString());
  a.SetToMin(ScrollOffset(3.5, 5.5));
  EXPECT_EQ(ScrollOffset(3.5, 5.5).ToString(), a.ToString());
}

}  // namespace gfx

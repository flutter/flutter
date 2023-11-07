// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/rect.h"

#include "flutter/impeller/geometry/geometry_asserts.h"

namespace impeller {
namespace testing {

TEST(RectTest, RectOriginSizeGetters) {
  {
    Rect r = Rect::MakeOriginSize({10, 20}, {50, 40});
    ASSERT_EQ(r.GetOrigin(), Point(10, 20));
    ASSERT_EQ(r.GetSize(), Size(50, 40));
  }

  {
    Rect r = Rect::MakeLTRB(10, 20, 50, 40);
    ASSERT_EQ(r.GetOrigin(), Point(10, 20));
    ASSERT_EQ(r.GetSize(), Size(40, 20));
  }
}

TEST(RectTest, RectMakeSize) {
  {
    Size s(100, 200);
    Rect r = Rect::MakeSize(s);
    Rect expected = Rect::MakeLTRB(0, 0, 100, 200);
    ASSERT_RECT_NEAR(r, expected);
  }

  {
    ISize s(100, 200);
    Rect r = Rect::MakeSize(s);
    Rect expected = Rect::MakeLTRB(0, 0, 100, 200);
    ASSERT_RECT_NEAR(r, expected);
  }

  {
    Size s(100, 200);
    IRect r = IRect::MakeSize(s);
    IRect expected = IRect::MakeLTRB(0, 0, 100, 200);
    ASSERT_EQ(r, expected);
  }

  {
    ISize s(100, 200);
    IRect r = IRect::MakeSize(s);
    IRect expected = IRect::MakeLTRB(0, 0, 100, 200);
    ASSERT_EQ(r, expected);
  }
}

TEST(SizeTest, RectIsEmpty) {
  auto nan = std::numeric_limits<Scalar>::quiet_NaN();

  // Non-empty
  EXPECT_FALSE(Rect::MakeXYWH(1.5, 2.3, 10.5, 7.2).IsEmpty());

  // Empty both width and height both 0 or negative, in all combinations
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, 0.0, 0.0).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, -1.0, -1.0).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, 0.0, -1.0).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, -1.0, 0.0).IsEmpty());

  // Empty for 0 or negative width or height (but not both at the same time)
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, 10.5, 0.0).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, 10.5, -1.0).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, 0.0, 7.2).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, -1.0, 7.2).IsEmpty());

  // Empty for NaN in width or height or both
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, 10.5, nan).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, nan, 7.2).IsEmpty());
  EXPECT_TRUE(Rect::MakeXYWH(1.5, 2.3, nan, nan).IsEmpty());
}

TEST(SizeTest, IRectIsEmpty) {
  // Non-empty
  EXPECT_FALSE(IRect::MakeXYWH(1, 2, 10, 7).IsEmpty());

  // Empty both width and height both 0 or negative, in all combinations
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, 0, 0).IsEmpty());
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, -1, -1).IsEmpty());
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, -1, 0).IsEmpty());
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, 0, -1).IsEmpty());

  // Empty for 0 or negative width or height (but not both at the same time)
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, 10, 0).IsEmpty());
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, 10, -1).IsEmpty());
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, 0, 7).IsEmpty());
  EXPECT_TRUE(IRect::MakeXYWH(1, 2, -1, 7).IsEmpty());
}

}  // namespace testing
}  // namespace impeller

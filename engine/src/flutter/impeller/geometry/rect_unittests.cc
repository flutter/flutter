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
    EXPECT_EQ(r.GetOrigin(), Point(10, 20));
    EXPECT_EQ(r.GetSize(), Size(50, 40));
  }

  {
    Rect r = Rect::MakeLTRB(10, 20, 50, 40);
    EXPECT_EQ(r.GetOrigin(), Point(10, 20));
    EXPECT_EQ(r.GetSize(), Size(40, 20));
  }
}

TEST(RectTest, RectMakeSize) {
  {
    Size s(100, 200);
    Rect r = Rect::MakeSize(s);
    Rect expected = Rect::MakeLTRB(0, 0, 100, 200);
    EXPECT_RECT_NEAR(r, expected);
  }

  {
    ISize s(100, 200);
    Rect r = Rect::MakeSize(s);
    Rect expected = Rect::MakeLTRB(0, 0, 100, 200);
    EXPECT_RECT_NEAR(r, expected);
  }

  {
    Size s(100, 200);
    IRect r = IRect::MakeSize(s);
    IRect expected = IRect::MakeLTRB(0, 0, 100, 200);
    EXPECT_EQ(r, expected);
  }

  {
    ISize s(100, 200);
    IRect r = IRect::MakeSize(s);
    IRect expected = IRect::MakeLTRB(0, 0, 100, 200);
    EXPECT_EQ(r, expected);
  }
}

TEST(RectTest, RectGetNormalizingTransform) {
  {
    // Checks for expected matrix values

    auto r = Rect::MakeXYWH(100, 200, 200, 400);

    EXPECT_EQ(r.GetNormalizingTransform(),
              Matrix::MakeScale({0.005, 0.0025, 1.0}) *
                  Matrix::MakeTranslation({-100, -200}));
  }

  {
    // Checks for expected transformation of points relative to the rect

    auto r = Rect::MakeLTRB(300, 500, 400, 700);
    auto m = r.GetNormalizingTransform();

    // The 4 corners of the rect => (0, 0) to (1, 1)
    EXPECT_EQ(m * Point(300, 500), Point(0, 0));
    EXPECT_EQ(m * Point(400, 500), Point(1, 0));
    EXPECT_EQ(m * Point(400, 700), Point(1, 1));
    EXPECT_EQ(m * Point(300, 700), Point(0, 1));

    // The center => (0.5, 0.5)
    EXPECT_EQ(m * Point(350, 600), Point(0.5, 0.5));

    // Outside the 4 corners => (-1, -1) to (2, 2)
    EXPECT_EQ(m * Point(200, 300), Point(-1, -1));
    EXPECT_EQ(m * Point(500, 300), Point(2, -1));
    EXPECT_EQ(m * Point(500, 900), Point(2, 2));
    EXPECT_EQ(m * Point(200, 900), Point(-1, 2));
  }

  {
    // Checks for behavior with empty rects

    auto zero = Matrix::MakeScale({0.0, 0.0, 1.0});

    // Empty for width and/or height == 0
    EXPECT_EQ(Rect::MakeXYWH(10, 10, 0, 10).GetNormalizingTransform(), zero);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, 10, 0).GetNormalizingTransform(), zero);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, 0, 0).GetNormalizingTransform(), zero);

    // Empty for width and/or height < 0
    EXPECT_EQ(Rect::MakeXYWH(10, 10, -1, 10).GetNormalizingTransform(), zero);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, 10, -1).GetNormalizingTransform(), zero);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, -1, -1).GetNormalizingTransform(), zero);
  }

  {
    // Checks for behavior with non-finite rects

    auto z = Matrix::MakeScale({0.0, 0.0, 1.0});
    auto nan = std::numeric_limits<Scalar>::quiet_NaN();
    auto inf = std::numeric_limits<Scalar>::infinity();

    // Non-finite for width and/or height == nan
    EXPECT_EQ(Rect::MakeXYWH(10, 10, nan, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, 10, nan).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, nan, nan).GetNormalizingTransform(), z);

    // Non-finite for width and/or height == inf
    EXPECT_EQ(Rect::MakeXYWH(10, 10, inf, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, 10, inf).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, inf, inf).GetNormalizingTransform(), z);

    // Non-finite for width and/or height == -inf
    EXPECT_EQ(Rect::MakeXYWH(10, 10, -inf, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, 10, -inf).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, 10, -inf, -inf).GetNormalizingTransform(), z);

    // Non-finite for origin X and/or Y == nan
    EXPECT_EQ(Rect::MakeXYWH(nan, 10, 10, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, nan, 10, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(nan, nan, 10, 10).GetNormalizingTransform(), z);

    // Non-finite for origin X and/or Y == inf
    EXPECT_EQ(Rect::MakeXYWH(inf, 10, 10, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, inf, 10, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(inf, inf, 10, 10).GetNormalizingTransform(), z);

    // Non-finite for origin X and/or Y == -inf
    EXPECT_EQ(Rect::MakeXYWH(-inf, 10, 10, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(10, -inf, 10, 10).GetNormalizingTransform(), z);
    EXPECT_EQ(Rect::MakeXYWH(-inf, -inf, 10, 10).GetNormalizingTransform(), z);
  }
}

TEST(RectTest, IRectGetNormalizingTransform) {
  {
    // Checks for expected matrix values

    auto r = IRect::MakeXYWH(100, 200, 200, 400);

    EXPECT_EQ(r.GetNormalizingTransform(),
              Matrix::MakeScale({0.005, 0.0025, 1.0}) *
                  Matrix::MakeTranslation({-100, -200}));
  }

  {
    // Checks for expected transformation of points relative to the rect

    auto r = IRect::MakeLTRB(300, 500, 400, 700);
    auto m = r.GetNormalizingTransform();

    // The 4 corners of the rect => (0, 0) to (1, 1)
    EXPECT_EQ(m * Point(300, 500), Point(0, 0));
    EXPECT_EQ(m * Point(400, 500), Point(1, 0));
    EXPECT_EQ(m * Point(400, 700), Point(1, 1));
    EXPECT_EQ(m * Point(300, 700), Point(0, 1));

    // The center => (0.5, 0.5)
    EXPECT_EQ(m * Point(350, 600), Point(0.5, 0.5));

    // Outside the 4 corners => (-1, -1) to (2, 2)
    EXPECT_EQ(m * Point(200, 300), Point(-1, -1));
    EXPECT_EQ(m * Point(500, 300), Point(2, -1));
    EXPECT_EQ(m * Point(500, 900), Point(2, 2));
    EXPECT_EQ(m * Point(200, 900), Point(-1, 2));
  }

  {
    // Checks for behavior with empty rects

    auto zero = Matrix::MakeScale({0.0, 0.0, 1.0});

    // Empty for width and/or height == 0
    EXPECT_EQ(IRect::MakeXYWH(10, 10, 0, 10).GetNormalizingTransform(), zero);
    EXPECT_EQ(IRect::MakeXYWH(10, 10, 10, 0).GetNormalizingTransform(), zero);
    EXPECT_EQ(IRect::MakeXYWH(10, 10, 0, 0).GetNormalizingTransform(), zero);

    // Empty for width and/or height < 0
    EXPECT_EQ(IRect::MakeXYWH(10, 10, -1, 10).GetNormalizingTransform(), zero);
    EXPECT_EQ(IRect::MakeXYWH(10, 10, 10, -1).GetNormalizingTransform(), zero);
    EXPECT_EQ(IRect::MakeXYWH(10, 10, -1, -1).GetNormalizingTransform(), zero);
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

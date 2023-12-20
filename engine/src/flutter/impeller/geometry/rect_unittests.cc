// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/rect.h"

#include "flutter/impeller/geometry/geometry_asserts.h"

namespace impeller {
namespace testing {

TEST(RectTest, RectOriginSizeXYWHGetters) {
  {
    Rect r = Rect::MakeOriginSize({10, 20}, {50, 40});
    EXPECT_EQ(r.GetOrigin(), Point(10, 20));
    EXPECT_EQ(r.GetSize(), Size(50, 40));
    EXPECT_EQ(r.GetX(), 10);
    EXPECT_EQ(r.GetY(), 20);
    EXPECT_EQ(r.GetWidth(), 50);
    EXPECT_EQ(r.GetHeight(), 40);
    auto expected_array = std::array<Scalar, 4>{10, 20, 50, 40};
    EXPECT_EQ(r.GetXYWH(), expected_array);
  }

  {
    Rect r = Rect::MakeLTRB(10, 20, 50, 40);
    EXPECT_EQ(r.GetOrigin(), Point(10, 20));
    EXPECT_EQ(r.GetSize(), Size(40, 20));
    EXPECT_EQ(r.GetX(), 10);
    EXPECT_EQ(r.GetY(), 20);
    EXPECT_EQ(r.GetWidth(), 40);
    EXPECT_EQ(r.GetHeight(), 20);
    auto expected_array = std::array<Scalar, 4>{10, 20, 40, 20};
    EXPECT_EQ(r.GetXYWH(), expected_array);
  }
}

TEST(RectTest, IRectOriginSizeXYWHGetters) {
  {
    IRect r = IRect::MakeOriginSize({10, 20}, {50, 40});
    EXPECT_EQ(r.GetOrigin(), IPoint(10, 20));
    EXPECT_EQ(r.GetSize(), ISize(50, 40));
    EXPECT_EQ(r.GetX(), 10);
    EXPECT_EQ(r.GetY(), 20);
    EXPECT_EQ(r.GetWidth(), 50);
    EXPECT_EQ(r.GetHeight(), 40);
    auto expected_array = std::array<int64_t, 4>{10, 20, 50, 40};
    EXPECT_EQ(r.GetXYWH(), expected_array);
  }

  {
    IRect r = IRect::MakeLTRB(10, 20, 50, 40);
    EXPECT_EQ(r.GetOrigin(), IPoint(10, 20));
    EXPECT_EQ(r.GetSize(), ISize(40, 20));
    EXPECT_EQ(r.GetX(), 10);
    EXPECT_EQ(r.GetY(), 20);
    EXPECT_EQ(r.GetWidth(), 40);
    EXPECT_EQ(r.GetHeight(), 20);
    auto expected_array = std::array<int64_t, 4>{10, 20, 40, 20};
    EXPECT_EQ(r.GetXYWH(), expected_array);
  }
}

TEST(RectTest, RectFromRect) {
  EXPECT_EQ(Rect(Rect::MakeXYWH(2, 3, 7, 15)),
            Rect::MakeXYWH(2.0, 3.0, 7.0, 15.0));
  EXPECT_EQ(Rect(Rect::MakeLTRB(2, 3, 7, 15)),
            Rect::MakeLTRB(2.0, 3.0, 7.0, 15.0));
}

TEST(RectTest, RectFromIRect) {
  EXPECT_EQ(Rect(IRect::MakeXYWH(2, 3, 7, 15)),
            Rect::MakeXYWH(2.0, 3.0, 7.0, 15.0));
  EXPECT_EQ(Rect(IRect::MakeLTRB(2, 3, 7, 15)),
            Rect::MakeLTRB(2.0, 3.0, 7.0, 15.0));
}

TEST(RectTest, IRectFromRect) {
  EXPECT_EQ(IRect(Rect::MakeXYWH(2, 3, 7, 15)),  //
            IRect::MakeXYWH(2, 3, 7, 15));
  EXPECT_EQ(IRect(Rect::MakeLTRB(2, 3, 7, 15)),  //
            IRect::MakeLTRB(2, 3, 7, 15));

  EXPECT_EQ(IRect(Rect::MakeXYWH(2.5, 3.5, 7.75, 15.75)),
            IRect::MakeXYWH(2, 3, 7, 15));
  EXPECT_EQ(IRect(Rect::MakeLTRB(2.5, 3.5, 7.75, 15.75)),
            IRect::MakeLTRB(2, 3, 7, 15));
}

TEST(RectTest, IRectFromIRect) {
  EXPECT_EQ(IRect(IRect::MakeXYWH(2, 3, 7, 15)),  //
            IRect::MakeXYWH(2, 3, 7, 15));
  EXPECT_EQ(IRect(IRect::MakeLTRB(2, 3, 7, 15)),  //
            IRect::MakeLTRB(2, 3, 7, 15));
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

TEST(RectTest, RectScale) {
  auto test1 = [](Rect rect, Scalar scale) {
    Rect expected = Rect::MakeXYWH(rect.GetX() * scale,      //
                                   rect.GetY() * scale,      //
                                   rect.GetWidth() * scale,  //
                                   rect.GetHeight() * scale);

    EXPECT_RECT_NEAR(rect.Scale(scale), expected)  //
        << rect << " * " << scale;
    EXPECT_RECT_NEAR(rect.Scale(scale, scale), expected)  //
        << rect << " * " << scale;
    EXPECT_RECT_NEAR(rect.Scale(Point(scale, scale)), expected)  //
        << rect << " * " << scale;
    EXPECT_RECT_NEAR(rect.Scale(Size(scale, scale)), expected)  //
        << rect << " * " << scale;
  };

  auto test2 = [&test1](Rect rect, Scalar scale_x, Scalar scale_y) {
    Rect expected = Rect::MakeXYWH(rect.GetX() * scale_x,      //
                                   rect.GetY() * scale_y,      //
                                   rect.GetWidth() * scale_x,  //
                                   rect.GetHeight() * scale_y);

    EXPECT_RECT_NEAR(rect.Scale(scale_x, scale_y), expected)  //
        << rect << " * " << scale_x << ", " << scale_y;
    EXPECT_RECT_NEAR(rect.Scale(Point(scale_x, scale_y)), expected)  //
        << rect << " * " << scale_x << ", " << scale_y;
    EXPECT_RECT_NEAR(rect.Scale(Size(scale_x, scale_y)), expected)  //
        << rect << " * " << scale_x << ", " << scale_y;

    test1(rect, scale_x);
    test1(rect, scale_y);
  };

  test2(Rect::MakeLTRB(10, 15, 100, 150), 2.5, 3.5);
  test2(Rect::MakeLTRB(10, 15, 100, 150), 3.5, 2.5);
  test2(Rect::MakeLTRB(10, 15, -100, 150), 2.5, 3.5);
  test2(Rect::MakeLTRB(10, 15, 100, -150), 2.5, 3.5);
  test2(Rect::MakeLTRB(10, 15, 100, 150), -2.5, 3.5);
  test2(Rect::MakeLTRB(10, 15, 100, 150), 2.5, -3.5);
}

TEST(RectTest, IRectScale) {
  auto test1 = [](IRect rect, int64_t scale) {
    IRect expected = IRect::MakeXYWH(rect.GetX() * scale,      //
                                     rect.GetY() * scale,      //
                                     rect.GetWidth() * scale,  //
                                     rect.GetHeight() * scale);

    EXPECT_EQ(rect.Scale(scale), expected)  //
        << rect << " * " << scale;
    EXPECT_EQ(rect.Scale(scale, scale), expected)  //
        << rect << " * " << scale;
    EXPECT_EQ(rect.Scale(IPoint(scale, scale)), expected)  //
        << rect << " * " << scale;
    EXPECT_EQ(rect.Scale(ISize(scale, scale)), expected)  //
        << rect << " * " << scale;
  };

  auto test2 = [&test1](IRect rect, int64_t scale_x, int64_t scale_y) {
    IRect expected = IRect::MakeXYWH(rect.GetX() * scale_x,      //
                                     rect.GetY() * scale_y,      //
                                     rect.GetWidth() * scale_x,  //
                                     rect.GetHeight() * scale_y);

    EXPECT_EQ(rect.Scale(scale_x, scale_y), expected)  //
        << rect << " * " << scale_x << ", " << scale_y;
    EXPECT_EQ(rect.Scale(IPoint(scale_x, scale_y)), expected)  //
        << rect << " * " << scale_x << ", " << scale_y;
    EXPECT_EQ(rect.Scale(ISize(scale_x, scale_y)), expected)  //
        << rect << " * " << scale_x << ", " << scale_y;

    test1(rect, scale_x);
    test1(rect, scale_y);
  };

  test2(IRect::MakeLTRB(10, 15, 100, 150), 2, 3);
  test2(IRect::MakeLTRB(10, 15, 100, 150), 3, 2);
  test2(IRect::MakeLTRB(10, 15, -100, 150), 2, 3);
  test2(IRect::MakeLTRB(10, 15, 100, -150), 2, 3);
  test2(IRect::MakeLTRB(10, 15, 100, 150), -2, 3);
  test2(IRect::MakeLTRB(10, 15, 100, 150), 2, -3);
}

TEST(RectTest, RectArea) {
  EXPECT_EQ(Rect::MakeXYWH(0, 0, 100, 200).Area(), 20000);
  EXPECT_EQ(Rect::MakeXYWH(10, 20, 100, 200).Area(), 20000);
  EXPECT_EQ(Rect::MakeXYWH(0, 0, 200, 100).Area(), 20000);
  EXPECT_EQ(Rect::MakeXYWH(10, 20, 200, 100).Area(), 20000);
  EXPECT_EQ(Rect::MakeXYWH(0, 0, 100, 100).Area(), 10000);
  EXPECT_EQ(Rect::MakeXYWH(10, 20, 100, 100).Area(), 10000);
}

TEST(RectTest, IRectArea) {
  EXPECT_EQ(IRect::MakeXYWH(0, 0, 100, 200).Area(), 20000);
  EXPECT_EQ(IRect::MakeXYWH(10, 20, 100, 200).Area(), 20000);
  EXPECT_EQ(IRect::MakeXYWH(0, 0, 200, 100).Area(), 20000);
  EXPECT_EQ(IRect::MakeXYWH(10, 20, 200, 100).Area(), 20000);
  EXPECT_EQ(IRect::MakeXYWH(0, 0, 100, 100).Area(), 10000);
  EXPECT_EQ(IRect::MakeXYWH(10, 20, 100, 100).Area(), 10000);
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
    // Checks for expected transform of points relative to the rect

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
    // Checks for expected transform of points relative to the rect

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

TEST(RectTest, MakePointBoundsQuad) {
  Quad quad = {
      Point(10, 10),
      Point(20, 10),
      Point(10, 20),
      Point(20, 20),
  };
  std::optional<Rect> bounds = Rect::MakePointBounds(quad);
  EXPECT_TRUE(bounds.has_value());
  if (bounds.has_value()) {
    EXPECT_TRUE(RectNear(bounds.value(), Rect::MakeLTRB(10, 10, 20, 20)));
  }
}

TEST(RectTest, IsSquare) {
  EXPECT_TRUE(Rect::MakeXYWH(10, 30, 20, 20).IsSquare());
  EXPECT_FALSE(Rect::MakeXYWH(10, 30, 20, 19).IsSquare());
  EXPECT_FALSE(Rect::MakeXYWH(10, 30, 19, 20).IsSquare());

  EXPECT_TRUE(IRect::MakeXYWH(10, 30, 20, 20).IsSquare());
  EXPECT_FALSE(IRect::MakeXYWH(10, 30, 20, 19).IsSquare());
  EXPECT_FALSE(IRect::MakeXYWH(10, 30, 19, 20).IsSquare());
}

TEST(RectTest, GetCenter) {
  EXPECT_EQ(Rect::MakeXYWH(10, 30, 20, 20).GetCenter(), Point(20, 40));
  EXPECT_EQ(Rect::MakeXYWH(10, 30, 20, 19).GetCenter(), Point(20, 39.5));

  // Note that we expect a Point as the answer from an IRect
  EXPECT_EQ(IRect::MakeXYWH(10, 30, 20, 20).GetCenter(), Point(20, 40));
  EXPECT_EQ(IRect::MakeXYWH(10, 30, 20, 19).GetCenter(), Point(20, 39.5));
}

TEST(RectTest, RectExpand) {
  auto rect = Rect::MakeLTRB(100, 100, 200, 200);

  // Expand(T amount)
  EXPECT_EQ(rect.Expand(10), Rect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(-10), Rect::MakeLTRB(110, 110, 190, 190));

  // Expand(amount, amount)
  EXPECT_EQ(rect.Expand(10, 10), Rect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(10, -10), Rect::MakeLTRB(90, 110, 210, 190));
  EXPECT_EQ(rect.Expand(-10, 10), Rect::MakeLTRB(110, 90, 190, 210));
  EXPECT_EQ(rect.Expand(-10, -10), Rect::MakeLTRB(110, 110, 190, 190));

  // Expand(Point amount)
  EXPECT_EQ(rect.Expand(Point{10, 10}), Rect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(Point{10, -10}), Rect::MakeLTRB(90, 110, 210, 190));
  EXPECT_EQ(rect.Expand(Point{-10, 10}), Rect::MakeLTRB(110, 90, 190, 210));
  EXPECT_EQ(rect.Expand(Point{-10, -10}), Rect::MakeLTRB(110, 110, 190, 190));

  // Expand(Size amount)
  EXPECT_EQ(rect.Expand(Size{10, 10}), Rect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(Size{10, -10}), Rect::MakeLTRB(90, 110, 210, 190));
  EXPECT_EQ(rect.Expand(Size{-10, 10}), Rect::MakeLTRB(110, 90, 190, 210));
  EXPECT_EQ(rect.Expand(Size{-10, -10}), Rect::MakeLTRB(110, 110, 190, 190));
}

TEST(RectTest, IRectExpand) {
  auto rect = IRect::MakeLTRB(100, 100, 200, 200);

  // Expand(T amount)
  EXPECT_EQ(rect.Expand(10), IRect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(-10), IRect::MakeLTRB(110, 110, 190, 190));

  // Expand(amount, amount)
  EXPECT_EQ(rect.Expand(10, 10), IRect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(10, -10), IRect::MakeLTRB(90, 110, 210, 190));
  EXPECT_EQ(rect.Expand(-10, 10), IRect::MakeLTRB(110, 90, 190, 210));
  EXPECT_EQ(rect.Expand(-10, -10), IRect::MakeLTRB(110, 110, 190, 190));

  // Expand(IPoint amount)
  EXPECT_EQ(rect.Expand(IPoint{10, 10}), IRect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(IPoint{10, -10}), IRect::MakeLTRB(90, 110, 210, 190));
  EXPECT_EQ(rect.Expand(IPoint{-10, 10}), IRect::MakeLTRB(110, 90, 190, 210));
  EXPECT_EQ(rect.Expand(IPoint{-10, -10}), IRect::MakeLTRB(110, 110, 190, 190));

  // Expand(ISize amount)
  EXPECT_EQ(rect.Expand(ISize{10, 10}), IRect::MakeLTRB(90, 90, 210, 210));
  EXPECT_EQ(rect.Expand(ISize{10, -10}), IRect::MakeLTRB(90, 110, 210, 190));
  EXPECT_EQ(rect.Expand(ISize{-10, 10}), IRect::MakeLTRB(110, 90, 190, 210));
  EXPECT_EQ(rect.Expand(ISize{-10, -10}), IRect::MakeLTRB(110, 110, 190, 190));
}

TEST(RectTest, ContainsFloatingPoint) {
  auto rect1 =
      Rect::MakeXYWH(472.599945f, 440.999969f, 1102.80005f, 654.000061f);
  auto rect2 = Rect::MakeXYWH(724.f, 618.f, 600.f, 300.f);
  EXPECT_TRUE(rect1.Contains(rect2));
}

}  // namespace testing
}  // namespace impeller

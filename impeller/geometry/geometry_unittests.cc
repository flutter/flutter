// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/geometry/geometry_unittests.h"
#include "flutter/testing/testing.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/size.h"

namespace impeller {
namespace testing {

TEST(GeometryTest, RotationMatrix) {
  auto rotation = Matrix::MakeRotationZ(Radians{M_PI_4});
  auto expect = Matrix{0.707,  0.707, 0, 0,  //
                       -0.707, 0.707, 0, 0,  //
                       0,      0,     1, 0,  //
                       0,      0,     0, 1};
  ASSERT_MATRIX_NEAR(rotation, expect);
}

TEST(GeometryTest, InvertMultMatrix) {
  auto rotation = Matrix::MakeRotationZ(Radians{M_PI_4});
  auto invert = rotation.Invert();
  auto expect = Matrix{0.707, -0.707, 0, 0,  //
                       0.707, 0.707,  0, 0,  //
                       0,     0,      1, 0,  //
                       0,     0,      0, 1};
  ASSERT_MATRIX_NEAR(invert, expect);
}

TEST(GeometryTest, MutliplicationMatrix) {
  auto rotation = Matrix::MakeRotationZ(Radians{M_PI_4});
  auto invert = rotation.Invert();
  ASSERT_MATRIX_NEAR(rotation * invert, Matrix{});
}

TEST(GeometryTest, DeterminantTest) {
  auto matrix = Matrix{3, 4, 14, 155, 2, 1, 3, 4, 2, 3, 2, 1, 1, 2, 4, 2};
  ASSERT_EQ(matrix.GetDeterminant(), -1889);
}

TEST(GeometryTest, InvertMatrix) {
  auto inverted = Matrix{10,  -9,  -12, 8,   //
                         7,   -12, 11,  22,  //
                         -10, 10,  3,   6,   //
                         -2,  22,  2,   1}
                      .Invert();

  auto result = Matrix{
      438.0 / 85123.0,   1751.0 / 85123.0, -7783.0 / 85123.0, 4672.0 / 85123.0,
      393.0 / 85123.0,   -178.0 / 85123.0, -570.0 / 85123.0,  4192 / 85123.0,
      -5230.0 / 85123.0, 2802.0 / 85123.0, -3461.0 / 85123.0, 962.0 / 85123.0,
      2690.0 / 85123.0,  1814.0 / 85123.0, 3896.0 / 85123.0,  319.0 / 85123.0};

  ASSERT_MATRIX_NEAR(inverted, result);
}

TEST(GeometryTest, TestDecomposition) {
  auto rotated = Matrix::MakeRotationZ(Radians{M_PI_4});

  auto result = rotated.Decompose();

  ASSERT_TRUE(result.has_value());

  MatrixDecomposition res = result.value();

  auto quaternion = Quaternion{{0.0, 0.0, 1.0}, M_PI_4};
  ASSERT_QUATERNION_NEAR(res.rotation, quaternion);
}

TEST(GeometryTest, TestDecomposition2) {
  auto rotated = Matrix::MakeRotationZ(Radians{M_PI_4});
  auto scaled = Matrix::MakeScale({2.0, 3.0, 1.0});
  auto translated = Matrix::MakeTranslation({-200, 750, 20});

  auto result = (translated * rotated * scaled).Decompose();

  ASSERT_TRUE(result.has_value());

  MatrixDecomposition res = result.value();

  auto quaternion = Quaternion{{0.0, 0.0, 1.0}, M_PI_4};

  ASSERT_QUATERNION_NEAR(res.rotation, quaternion);

  ASSERT_FLOAT_EQ(res.translation.x, -200);
  ASSERT_FLOAT_EQ(res.translation.y, 750);
  ASSERT_FLOAT_EQ(res.translation.z, 20);

  ASSERT_FLOAT_EQ(res.scale.x, 2);
  ASSERT_FLOAT_EQ(res.scale.y, 3);
  ASSERT_FLOAT_EQ(res.scale.z, 1);
}

TEST(GeometryTest, TestRecomposition) {
  /*
   *  Decomposition.
   */
  auto rotated = Matrix::MakeRotationZ(Radians{M_PI_4});

  auto result = rotated.Decompose();

  ASSERT_TRUE(result.has_value());

  MatrixDecomposition res = result.value();

  auto quaternion = Quaternion{{0.0, 0.0, 1.0}, M_PI_4};

  ASSERT_QUATERNION_NEAR(res.rotation, quaternion);

  /*
   *  Recomposition.
   */
  ASSERT_MATRIX_NEAR(rotated, Matrix{res});
}

TEST(GeometryTest, TestRecomposition2) {
  auto matrix = Matrix::MakeTranslation({100, 100, 100}) *
                Matrix::MakeRotationZ(Radians{M_PI_4}) *
                Matrix::MakeScale({2.0, 2.0, 2.0});

  auto result = matrix.Decompose();

  ASSERT_TRUE(result.has_value());

  ASSERT_MATRIX_NEAR(matrix, Matrix{result.value()});
}

TEST(GeometryTest, QuaternionLerp) {
  auto q1 = Quaternion{{0.0, 0.0, 1.0}, 0.0};
  auto q2 = Quaternion{{0.0, 0.0, 1.0}, M_PI_4};

  auto q3 = q1.Slerp(q2, 0.5);

  auto expected = Quaternion{{0.0, 0.0, 1.0}, M_PI_4 / 2.0};

  ASSERT_QUATERNION_NEAR(q3, expected);
}

TEST(GeometryTest, SimplePath) {
  Path path;

  path.AddLinearComponent({0, 0}, {100, 100})
      .AddQuadraticComponent({100, 100}, {200, 200}, {300, 300})
      .AddCubicComponent({300, 300}, {400, 400}, {500, 500}, {600, 600});

  ASSERT_EQ(path.GetComponentCount(), 3u);

  path.EnumerateComponents(
      [](size_t index, const LinearPathComponent& linear) {
        Point p1(0, 0);
        Point p2(100, 100);
        ASSERT_EQ(index, 0u);
        ASSERT_EQ(linear.p1, p1);
        ASSERT_EQ(linear.p2, p2);
      },
      [](size_t index, const QuadraticPathComponent& quad) {
        Point p1(100, 100);
        Point cp(200, 200);
        Point p2(300, 300);
        ASSERT_EQ(index, 1u);
        ASSERT_EQ(quad.p1, p1);
        ASSERT_EQ(quad.cp, cp);
        ASSERT_EQ(quad.p2, p2);
      },
      [](size_t index, const CubicPathComponent& cubic) {
        Point p1(300, 300);
        Point cp1(400, 400);
        Point cp2(500, 500);
        Point p2(600, 600);
        ASSERT_EQ(index, 2u);
        ASSERT_EQ(cubic.p1, p1);
        ASSERT_EQ(cubic.cp1, cp1);
        ASSERT_EQ(cubic.cp2, cp2);
        ASSERT_EQ(cubic.p2, p2);
      });
}

TEST(GeometryTest, BoundingBoxCubic) {
  Path path;
  path.AddCubicComponent({120, 160}, {25, 200}, {220, 260}, {220, 40});
  auto box = path.GetBoundingBox();
  Rect expected(93.9101, 40, 126.09, 158.862);
  ASSERT_TRUE(box.has_value());
  ASSERT_RECT_NEAR(box.value(), expected);
}

TEST(GeometryTest, BoundingBoxOfCompositePathIsCorrect) {
  PathBuilder builder;
  builder.AddRoundedRect({{10, 10}, {300, 300}}, {50, 50, 50, 50});
  auto path = builder.TakePath();
  auto actual = path.GetBoundingBox();
  Rect expected(10, 10, 300, 300);
  ASSERT_TRUE(actual.has_value());
  ASSERT_RECT_NEAR(actual.value(), expected);
}

TEST(GeometryTest, CanGenerateMipCounts) {
  ASSERT_EQ((Size{128, 128}.MipCount()), 7u);
  ASSERT_EQ((Size{128, 256}.MipCount()), 8u);
  ASSERT_EQ((Size{128, 130}.MipCount()), 8u);
  ASSERT_EQ((Size{128, 257}.MipCount()), 9u);
  ASSERT_EQ((Size{257, 128}.MipCount()), 9u);
  ASSERT_EQ((Size{128, 0}.MipCount()), 1u);
  ASSERT_EQ((Size{128, -25}.MipCount()), 1u);
  ASSERT_EQ((Size{-128, 25}.MipCount()), 1u);
}

TEST(GeometryTest, CanConvertTTypesExplicitly) {
  {
    Point p1(1.0, 2.0);
    IPoint p2 = static_cast<IPoint>(p1);
    ASSERT_EQ(p2.x, 1u);
    ASSERT_EQ(p2.y, 2u);
  }

  {
    Size s1(1.0, 2.0);
    ISize s2 = static_cast<ISize>(s1);
    ASSERT_EQ(s2.width, 1u);
    ASSERT_EQ(s2.height, 2u);
  }

  {
    Rect r1(1.0, 2.0, 3.0, 4.0);
    IRect r2 = static_cast<IRect>(r1);
    ASSERT_EQ(r2.origin.x, 1u);
    ASSERT_EQ(r2.origin.y, 2u);
    ASSERT_EQ(r2.size.width, 3u);
    ASSERT_EQ(r2.size.height, 4u);
  }
}

TEST(GeometryTest, CanConvertBetweenDegressAndRadians) {
  {
    auto deg = Degrees{90.0};
    Radians rad = deg;
    ASSERT_FLOAT_EQ(rad.radians, kPiOver2);
  }
}

TEST(GeometryTest, RectUnion) {
  {
    Rect a(100, 100, 100, 100);
    Rect b(0, 0, 0, 0);
    auto u = a.Union(b);
    auto expected = Rect(0, 0, 200, 200);
    ASSERT_RECT_NEAR(u, expected);
  }

  {
    Rect a(100, 100, 100, 100);
    Rect b(10, 10, 0, 0);
    auto u = a.Union(b);
    auto expected = Rect(10, 10, 190, 190);
    ASSERT_RECT_NEAR(u, expected);
  }

  {
    Rect a(0, 0, 100, 100);
    Rect b(10, 10, 100, 100);
    auto u = a.Union(b);
    auto expected = Rect(0, 0, 110, 110);
    ASSERT_RECT_NEAR(u, expected);
  }

  {
    Rect a(0, 0, 100, 100);
    Rect b(100, 100, 100, 100);
    auto u = a.Union(b);
    auto expected = Rect(0, 0, 200, 200);
    ASSERT_RECT_NEAR(u, expected);
  }
}

TEST(GeometryTest, RectIntersection) {
  {
    Rect a(100, 100, 100, 100);
    Rect b(0, 0, 0, 0);

    auto u = a.Intersection(b);
    ASSERT_FALSE(u.has_value());
  }

  {
    Rect a(100, 100, 100, 100);
    Rect b(10, 10, 0, 0);
    auto u = a.Intersection(b);
    ASSERT_FALSE(u.has_value());
  }

  {
    Rect a(0, 0, 100, 100);
    Rect b(10, 10, 100, 100);
    auto u = a.Intersection(b);
    ASSERT_TRUE(u.has_value());
    auto expected = Rect(10, 10, 90, 90);
    ASSERT_RECT_NEAR(u.value(), expected);
  }

  {
    Rect a(0, 0, 100, 100);
    Rect b(100, 100, 100, 100);
    auto u = a.Intersection(b);
    ASSERT_FALSE(u.has_value());
  }
}

}  // namespace testing
}  // namespace impeller

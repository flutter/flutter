// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/geometry/geometry_asserts.h"

#include <limits>
#include <sstream>
#include <type_traits>

#include "flutter/fml/build_config.h"
#include "flutter/testing/testing.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/gradient.h"
#include "impeller/geometry/half.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/path_component.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/size.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace impeller {
namespace testing {

TEST(GeometryTest, ScalarNearlyEqual) {
  ASSERT_FALSE(ScalarNearlyEqual(0.0021f, 0.001f));
  ASSERT_TRUE(ScalarNearlyEqual(0.0019f, 0.001f));
  ASSERT_TRUE(ScalarNearlyEqual(0.002f, 0.001f, 0.0011f));
  ASSERT_FALSE(ScalarNearlyEqual(0.002f, 0.001f, 0.0009f));
  ASSERT_TRUE(ScalarNearlyEqual(
      1.0f, 1.0f + std::numeric_limits<float>::epsilon() * 4));
}

TEST(GeometryTest, MakeColumn) {
  auto matrix = Matrix::MakeColumn(1, 2, 3, 4,     //
                                   5, 6, 7, 8,     //
                                   9, 10, 11, 12,  //
                                   13, 14, 15, 16);

  auto expect = Matrix{1,  2,  3,  4,   //
                       5,  6,  7,  8,   //
                       9,  10, 11, 12,  //
                       13, 14, 15, 16};

  ASSERT_TRUE(matrix == expect);
}

TEST(GeometryTest, MakeRow) {
  auto matrix = Matrix::MakeRow(1, 2, 3, 4,     //
                                5, 6, 7, 8,     //
                                9, 10, 11, 12,  //
                                13, 14, 15, 16);

  auto expect = Matrix{1, 5, 9,  13,  //
                       2, 6, 10, 14,  //
                       3, 7, 11, 15,  //
                       4, 8, 12, 16};

  ASSERT_TRUE(matrix == expect);
}

TEST(GeometryTest, RotationMatrix) {
  auto rotation = Matrix::MakeRotationZ(Radians{kPiOver4});
  auto expect = Matrix{0.707,  0.707, 0, 0,  //
                       -0.707, 0.707, 0, 0,  //
                       0,      0,     1, 0,  //
                       0,      0,     0, 1};
  ASSERT_MATRIX_NEAR(rotation, expect);
}

TEST(GeometryTest, InvertMultMatrix) {
  {
    auto rotation = Matrix::MakeRotationZ(Radians{kPiOver4});
    auto invert = rotation.Invert();
    auto expect = Matrix{0.707, -0.707, 0, 0,  //
                         0.707, 0.707,  0, 0,  //
                         0,     0,      1, 0,  //
                         0,     0,      0, 1};
    ASSERT_MATRIX_NEAR(invert, expect);
  }
  {
    auto scale = Matrix::MakeScale(Vector2{2, 4});
    auto invert = scale.Invert();
    auto expect = Matrix{0.5, 0,    0, 0,  //
                         0,   0.25, 0, 0,  //
                         0,   0,    1, 0,  //
                         0,   0,    0, 1};
    ASSERT_MATRIX_NEAR(invert, expect);
  }
}

TEST(GeometryTest, MatrixBasis) {
  auto matrix = Matrix{1,  2,  3,  4,   //
                       5,  6,  7,  8,   //
                       9,  10, 11, 12,  //
                       13, 14, 15, 16};
  auto basis = matrix.Basis();
  auto expect = Matrix{1, 2,  3,  0,  //
                       5, 6,  7,  0,  //
                       9, 10, 11, 0,  //
                       0, 0,  0,  1};
  ASSERT_MATRIX_NEAR(basis, expect);
}

TEST(GeometryTest, MutliplicationMatrix) {
  auto rotation = Matrix::MakeRotationZ(Radians{kPiOver4});
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
  auto rotated = Matrix::MakeRotationZ(Radians{kPiOver4});

  auto result = rotated.Decompose();

  ASSERT_TRUE(result.has_value());

  MatrixDecomposition res = result.value();

  auto quaternion = Quaternion{{0.0, 0.0, 1.0}, kPiOver4};
  ASSERT_QUATERNION_NEAR(res.rotation, quaternion);
}

TEST(GeometryTest, TestDecomposition2) {
  auto rotated = Matrix::MakeRotationZ(Radians{kPiOver4});
  auto scaled = Matrix::MakeScale({2.0, 3.0, 1.0});
  auto translated = Matrix::MakeTranslation({-200, 750, 20});

  auto result = (translated * rotated * scaled).Decompose();

  ASSERT_TRUE(result.has_value());

  MatrixDecomposition res = result.value();

  auto quaternion = Quaternion{{0.0, 0.0, 1.0}, kPiOver4};

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
  auto rotated = Matrix::MakeRotationZ(Radians{kPiOver4});

  auto result = rotated.Decompose();

  ASSERT_TRUE(result.has_value());

  MatrixDecomposition res = result.value();

  auto quaternion = Quaternion{{0.0, 0.0, 1.0}, kPiOver4};

  ASSERT_QUATERNION_NEAR(res.rotation, quaternion);

  /*
   *  Recomposition.
   */
  ASSERT_MATRIX_NEAR(rotated, Matrix{res});
}

TEST(GeometryTest, TestRecomposition2) {
  auto matrix = Matrix::MakeTranslation({100, 100, 100}) *
                Matrix::MakeRotationZ(Radians{kPiOver4}) *
                Matrix::MakeScale({2.0, 2.0, 2.0});

  auto result = matrix.Decompose();

  ASSERT_TRUE(result.has_value());

  ASSERT_MATRIX_NEAR(matrix, Matrix{result.value()});
}

TEST(GeometryTest, MatrixVectorMultiplication) {
  {
    auto matrix = Matrix::MakeTranslation({100, 100, 100}) *
                  Matrix::MakeRotationZ(Radians{kPiOver2}) *
                  Matrix::MakeScale({2.0, 2.0, 2.0});
    auto vector = Vector4(10, 20, 30, 2);

    Vector4 result = matrix * vector;
    auto expected = Vector4(160, 220, 260, 2);
    ASSERT_VECTOR4_NEAR(result, expected);
  }

  {
    auto matrix = Matrix::MakeTranslation({100, 100, 100}) *
                  Matrix::MakeRotationZ(Radians{kPiOver2}) *
                  Matrix::MakeScale({2.0, 2.0, 2.0});
    auto vector = Vector3(10, 20, 30);

    Vector3 result = matrix * vector;
    auto expected = Vector3(60, 120, 160);
    ASSERT_VECTOR3_NEAR(result, expected);
  }

  {
    auto matrix = Matrix::MakeTranslation({100, 100, 100}) *
                  Matrix::MakeRotationZ(Radians{kPiOver2}) *
                  Matrix::MakeScale({2.0, 2.0, 2.0});
    auto vector = Point(10, 20);

    Point result = matrix * vector;
    auto expected = Point(60, 120);
    ASSERT_POINT_NEAR(result, expected);
  }

  // Matrix Vector ops should respect perspective transforms.
  {
    auto matrix = Matrix::MakePerspective(Radians(kPiOver2), 1, 1, 100);
    auto vector = Vector3(3, 3, -3);

    Vector3 result = matrix * vector;
    auto expected = Vector3(-1, -1, 1.3468);
    ASSERT_VECTOR3_NEAR(result, expected);
  }

  {
    auto matrix = Matrix::MakePerspective(Radians(kPiOver2), 1, 1, 100) *
                  Matrix::MakeTranslation(Vector3(0, 0, -3));
    auto point = Point(3, 3);

    Point result = matrix * point;
    auto expected = Point(-1, -1);
    ASSERT_POINT_NEAR(result, expected);
  }

  // Resolves to 0 on perspective singularity.
  {
    auto matrix = Matrix::MakePerspective(Radians(kPiOver2), 1, 1, 100);
    auto point = Point(3, 3);

    Point result = matrix * point;
    auto expected = Point(0, 0);
    ASSERT_POINT_NEAR(result, expected);
  }
}

TEST(GeometryTest, MatrixMakeRotationFromQuaternion) {
  {
    auto matrix = Matrix::MakeRotation(Quaternion({1, 0, 0}, kPiOver2));
    auto expected = Matrix::MakeRotationX(Radians(kPiOver2));
    ASSERT_MATRIX_NEAR(matrix, expected);
  }

  {
    auto matrix = Matrix::MakeRotation(Quaternion({0, 1, 0}, kPiOver2));
    auto expected = Matrix::MakeRotationY(Radians(kPiOver2));
    ASSERT_MATRIX_NEAR(matrix, expected);
  }

  {
    auto matrix = Matrix::MakeRotation(Quaternion({0, 0, 1}, kPiOver2));
    auto expected = Matrix::MakeRotationZ(Radians(kPiOver2));
    ASSERT_MATRIX_NEAR(matrix, expected);
  }
}

TEST(GeometryTest, MatrixTransformDirection) {
  {
    auto matrix = Matrix::MakeTranslation({100, 100, 100}) *
                  Matrix::MakeRotationZ(Radians{kPiOver2}) *
                  Matrix::MakeScale({2.0, 2.0, 2.0});
    auto vector = Vector4(10, 20, 30, 2);

    Vector4 result = matrix.TransformDirection(vector);
    auto expected = Vector4(-40, 20, 60, 2);
    ASSERT_VECTOR4_NEAR(result, expected);
  }

  {
    auto matrix = Matrix::MakeTranslation({100, 100, 100}) *
                  Matrix::MakeRotationZ(Radians{kPiOver2}) *
                  Matrix::MakeScale({2.0, 2.0, 2.0});
    auto vector = Vector3(10, 20, 30);

    Vector3 result = matrix.TransformDirection(vector);
    auto expected = Vector3(-40, 20, 60);
    ASSERT_VECTOR3_NEAR(result, expected);
  }

  {
    auto matrix = Matrix::MakeTranslation({0, -0.4, 100}) *
                  Matrix::MakeRotationZ(Radians{kPiOver2}) *
                  Matrix::MakeScale({2.0, 2.0, 2.0});
    auto vector = Point(10, 20);

    Point result = matrix.TransformDirection(vector);
    auto expected = Point(-40, 20);
    ASSERT_POINT_NEAR(result, expected);
  }
}

TEST(GeometryTest, MatrixGetMaxBasisLength) {
  {
    auto m = Matrix::MakeScale({3, 1, 1});
    ASSERT_EQ(m.GetMaxBasisLength(), 3);

    m = m * Matrix::MakeSkew(0, 4);
    ASSERT_EQ(m.GetMaxBasisLength(), 5);
  }

  {
    auto m = Matrix::MakeScale({-3, 4, 2});
    ASSERT_EQ(m.GetMaxBasisLength(), 4);
  }
}

TEST(GeometryTest, MatrixGetMaxBasisLengthXY) {
  {
    auto m = Matrix::MakeScale({3, 1, 1});
    ASSERT_EQ(m.GetMaxBasisLengthXY(), 3);

    m = m * Matrix::MakeSkew(0, 4);
    ASSERT_EQ(m.GetMaxBasisLengthXY(), 5);
  }

  {
    auto m = Matrix::MakeScale({-3, 4, 7});
    ASSERT_EQ(m.GetMaxBasisLengthXY(), 4);
  }
}

TEST(GeometryTest, MatrixMakeOrthographic) {
  {
    auto m = Matrix::MakeOrthographic(Size(100, 200));
    auto expect = Matrix{
        0.02, 0,     0,   0,  //
        0,    -0.01, 0,   0,  //
        0,    0,     0,   0,  //
        -1,   1,     0.5, 1,  //
    };
    ASSERT_MATRIX_NEAR(m, expect);
  }

  {
    auto m = Matrix::MakeOrthographic(Size(400, 100));
    auto expect = Matrix{
        0.005, 0,     0,   0,  //
        0,     -0.02, 0,   0,  //
        0,     0,     0,   0,  //
        -1,    1,     0.5, 1,  //
    };
    ASSERT_MATRIX_NEAR(m, expect);
  }
}

TEST(GeometryTest, MatrixMakePerspective) {
  {
    auto m = Matrix::MakePerspective(Degrees(60), Size(100, 200), 1, 10);
    auto expect = Matrix{
        3.4641, 0,       0,        0,  //
        0,      1.73205, 0,        0,  //
        0,      0,       1.11111,  1,  //
        0,      0,       -1.11111, 0,  //
    };
    ASSERT_MATRIX_NEAR(m, expect);
  }

  {
    auto m = Matrix::MakePerspective(Radians(1), 2, 10, 20);
    auto expect = Matrix{
        0.915244, 0,       0,   0,  //
        0,        1.83049, 0,   0,  //
        0,        0,       2,   1,  //
        0,        0,       -20, 0,  //
    };
    ASSERT_MATRIX_NEAR(m, expect);
  }
}

TEST(GeometryTest, MatrixGetBasisVectors) {
  {
    auto m = Matrix();
    Vector3 x = m.GetBasisX();
    Vector3 y = m.GetBasisY();
    Vector3 z = m.GetBasisZ();
    ASSERT_VECTOR3_NEAR(x, Vector3(1, 0, 0));
    ASSERT_VECTOR3_NEAR(y, Vector3(0, 1, 0));
    ASSERT_VECTOR3_NEAR(z, Vector3(0, 0, 1));
  }

  {
    auto m = Matrix::MakeRotationZ(Radians{kPiOver2}) *
             Matrix::MakeRotationX(Radians{kPiOver2}) *
             Matrix::MakeScale(Vector3(2, 3, 4));
    Vector3 x = m.GetBasisX();
    Vector3 y = m.GetBasisY();
    Vector3 z = m.GetBasisZ();
    ASSERT_VECTOR3_NEAR(x, Vector3(0, 2, 0));
    ASSERT_VECTOR3_NEAR(y, Vector3(0, 0, 3));
    ASSERT_VECTOR3_NEAR(z, Vector3(4, 0, 0));
  }
}

TEST(GeometryTest, MatrixGetDirectionScale) {
  {
    auto m = Matrix();
    Scalar result = m.GetDirectionScale(Vector3{1, 0, 0});
    ASSERT_FLOAT_EQ(result, 1);
  }

  {
    auto m = Matrix::MakeRotationX(Degrees{10}) *
             Matrix::MakeRotationY(Degrees{83}) *
             Matrix::MakeRotationZ(Degrees{172});
    Scalar result = m.GetDirectionScale(Vector3{0, 1, 0});
    ASSERT_FLOAT_EQ(result, 1);
  }

  {
    auto m = Matrix::MakeRotationZ(Radians{kPiOver2}) *
             Matrix::MakeScale(Vector3(3, 4, 5));
    Scalar result = m.GetDirectionScale(Vector3{2, 0, 0});
    ASSERT_FLOAT_EQ(result, 8);
  }
}

TEST(GeometryTest, MatrixIsAligned) {
  {
    auto m = Matrix::MakeTranslation({1, 2, 3});
    bool result = m.IsAligned();
    ASSERT_TRUE(result);
  }

  {
    auto m = Matrix::MakeRotationZ(Degrees{123});
    bool result = m.IsAligned();
    ASSERT_FALSE(result);
  }
}

TEST(GeometryTest, MatrixTranslationScaleOnly) {
  {
    auto m = Matrix();
    bool result = m.IsTranslationScaleOnly();
    ASSERT_TRUE(result);
  }

  {
    auto m = Matrix::MakeScale(Vector3(2, 3, 4));
    bool result = m.IsTranslationScaleOnly();
    ASSERT_TRUE(result);
  }

  {
    auto m = Matrix::MakeTranslation(Vector3(2, 3, 4));
    bool result = m.IsTranslationScaleOnly();
    ASSERT_TRUE(result);
  }

  {
    auto m = Matrix::MakeRotationZ(Degrees(10));
    bool result = m.IsTranslationScaleOnly();
    ASSERT_FALSE(result);
  }
}

TEST(GeometryTest, MatrixLookAt) {
  {
    auto m = Matrix::MakeLookAt(Vector3(0, 0, -1), Vector3(0, 0, 1),
                                Vector3(0, 1, 0));
    auto expected = Matrix{
        1, 0, 0, 0,  //
        0, 1, 0, 0,  //
        0, 0, 1, 0,  //
        0, 0, 1, 1,  //
    };
    ASSERT_MATRIX_NEAR(m, expected);
  }

  // Sideways tilt.
  {
    auto m = Matrix::MakeLookAt(Vector3(0, 0, -1), Vector3(0, 0, 1),
                                Vector3(1, 1, 0).Normalize());

    // clang-format off
    auto expected = Matrix{
        k1OverSqrt2, k1OverSqrt2, 0, 0,
       -k1OverSqrt2, k1OverSqrt2, 0, 0,
        0,           0,           1, 0,
        0,           0,           1, 1,
    };
    // clang-format on
    ASSERT_MATRIX_NEAR(m, expected);
  }

  // Half way between +x and -y, yaw 90
  {
    auto m =
        Matrix::MakeLookAt(Vector3(), Vector3(10, -10, 0), Vector3(0, 0, -1));

    // clang-format off
    auto expected = Matrix{
       -k1OverSqrt2,  0,  k1OverSqrt2, 0,
       -k1OverSqrt2,  0, -k1OverSqrt2, 0,
        0,           -1,  0,           0,
        0,            0,  0,           1,
    };
    // clang-format on
    ASSERT_MATRIX_NEAR(m, expected);
  }
}

TEST(GeometryTest, QuaternionLerp) {
  auto q1 = Quaternion{{0.0, 0.0, 1.0}, 0.0};
  auto q2 = Quaternion{{0.0, 0.0, 1.0}, kPiOver4};

  auto q3 = q1.Slerp(q2, 0.5);

  auto expected = Quaternion{{0.0, 0.0, 1.0}, kPiOver4 / 2.0};

  ASSERT_QUATERNION_NEAR(q3, expected);
}

TEST(GeometryTest, QuaternionVectorMultiply) {
  {
    Quaternion q({0, 0, 1}, 0);
    Vector3 v(0, 1, 0);

    Vector3 result = q * v;
    Vector3 expected(0, 1, 0);

    ASSERT_VECTOR3_NEAR(result, expected);
  }

  {
    Quaternion q({0, 0, 1}, k2Pi);
    Vector3 v(1, 0, 0);

    Vector3 result = q * v;
    Vector3 expected(1, 0, 0);

    ASSERT_VECTOR3_NEAR(result, expected);
  }

  {
    Quaternion q({0, 0, 1}, kPiOver4);
    Vector3 v(0, 1, 0);

    Vector3 result = q * v;
    Vector3 expected(-k1OverSqrt2, k1OverSqrt2, 0);

    ASSERT_VECTOR3_NEAR(result, expected);
  }

  {
    Quaternion q(Vector3(1, 0, 1).Normalize(), kPi);
    Vector3 v(0, 0, -1);

    Vector3 result = q * v;
    Vector3 expected(-1, 0, 0);

    ASSERT_VECTOR3_NEAR(result, expected);
  }
}

TEST(GeometryTest, EmptyPath) {
  auto path = PathBuilder{}.TakePath();
  ASSERT_EQ(path.GetComponentCount(), 1u);

  ContourComponent c;
  path.GetContourComponentAtIndex(0, c);
  ASSERT_POINT_NEAR(c.destination, Point());

  Path::Polyline polyline = path.CreatePolyline(1.0f);
  ASSERT_TRUE(polyline.points.empty());
  ASSERT_TRUE(polyline.contours.empty());
}

TEST(GeometryTest, SimplePath) {
  PathBuilder builder;

  auto path = builder.AddLine({0, 0}, {100, 100})
                  .AddQuadraticCurve({100, 100}, {200, 200}, {300, 300})
                  .AddCubicCurve({300, 300}, {400, 400}, {500, 500}, {600, 600})
                  .TakePath();

  ASSERT_EQ(path.GetComponentCount(), 6u);
  ASSERT_EQ(path.GetComponentCount(Path::ComponentType::kLinear), 1u);
  ASSERT_EQ(path.GetComponentCount(Path::ComponentType::kQuadratic), 1u);
  ASSERT_EQ(path.GetComponentCount(Path::ComponentType::kCubic), 1u);
  ASSERT_EQ(path.GetComponentCount(Path::ComponentType::kContour), 3u);

  path.EnumerateComponents(
      [](size_t index, const LinearPathComponent& linear) {
        Point p1(0, 0);
        Point p2(100, 100);
        ASSERT_EQ(index, 1u);
        ASSERT_EQ(linear.p1, p1);
        ASSERT_EQ(linear.p2, p2);
      },
      [](size_t index, const QuadraticPathComponent& quad) {
        Point p1(100, 100);
        Point cp(200, 200);
        Point p2(300, 300);
        ASSERT_EQ(index, 3u);
        ASSERT_EQ(quad.p1, p1);
        ASSERT_EQ(quad.cp, cp);
        ASSERT_EQ(quad.p2, p2);
      },
      [](size_t index, const CubicPathComponent& cubic) {
        Point p1(300, 300);
        Point cp1(400, 400);
        Point cp2(500, 500);
        Point p2(600, 600);
        ASSERT_EQ(index, 5u);
        ASSERT_EQ(cubic.p1, p1);
        ASSERT_EQ(cubic.cp1, cp1);
        ASSERT_EQ(cubic.cp2, cp2);
        ASSERT_EQ(cubic.p2, p2);
      },
      [](size_t index, const ContourComponent& contour) {
        // There is an initial countour added for each curve.
        if (index == 0u) {
          Point p1(0, 0);
          ASSERT_EQ(contour.destination, p1);
        } else if (index == 2u) {
          Point p1(100, 100);
          ASSERT_EQ(contour.destination, p1);
        } else if (index == 4u) {
          Point p1(300, 300);
          ASSERT_EQ(contour.destination, p1);
        } else {
          ASSERT_FALSE(true);
        }
        ASSERT_FALSE(contour.is_closed);
      });
}

TEST(GeometryTest, BoundingBoxCubic) {
  PathBuilder builder;
  auto path =
      builder.AddCubicCurve({120, 160}, {25, 200}, {220, 260}, {220, 40})
          .TakePath();
  auto box = path.GetBoundingBox();
  Rect expected = Rect::MakeXYWH(93.9101, 40, 126.09, 158.862);
  ASSERT_TRUE(box.has_value());
  ASSERT_RECT_NEAR(box.value(), expected);
}

TEST(GeometryTest, BoundingBoxOfCompositePathIsCorrect) {
  PathBuilder builder;
  builder.AddRoundedRect(Rect::MakeXYWH(10, 10, 300, 300), {50, 50, 50, 50});
  auto path = builder.TakePath();
  auto actual = path.GetBoundingBox();
  Rect expected = Rect::MakeXYWH(10, 10, 300, 300);
  ASSERT_TRUE(actual.has_value());
  ASSERT_RECT_NEAR(actual.value(), expected);
}

TEST(GeometryTest, ExtremaOfCubicPathComponentIsCorrect) {
  CubicPathComponent cubic{{11.769268, 252.883148},
                           {-6.2857933, 204.356461},
                           {-4.53997231, 156.552902},
                           {17.0067291, 109.472488}};
  auto points = cubic.Extrema();
  ASSERT_EQ(points.size(), static_cast<size_t>(3));
  ASSERT_POINT_NEAR(points[2], cubic.Solve(0.455916));
}

TEST(GeometryTest, PathGetBoundingBoxForCubicWithNoDerivativeRootsIsCorrect) {
  PathBuilder builder;
  // Straight diagonal line.
  builder.AddCubicCurve({0, 1}, {2, 3}, {4, 5}, {6, 7});
  auto path = builder.TakePath();
  auto actual = path.GetBoundingBox();
  auto expected = Rect::MakeLTRB(0, 1, 6, 7);
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
  ASSERT_EQ((Size{1, 1}.MipCount()), 1u);
  ASSERT_EQ((Size{0, 0}.MipCount()), 1u);
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
    Size s1(1.0, 2.0);
    Point p1 = static_cast<Point>(s1);
    ASSERT_EQ(p1.x, 1u);
    ASSERT_EQ(p1.y, 2u);
  }

  {
    Rect r1 = Rect::MakeXYWH(1.0, 2.0, 3.0, 4.0);
    IRect r2 = static_cast<IRect>(r1);
    ASSERT_EQ(r2.origin.x, 1u);
    ASSERT_EQ(r2.origin.y, 2u);
    ASSERT_EQ(r2.size.width, 3u);
    ASSERT_EQ(r2.size.height, 4u);
  }
}

TEST(GeometryTest, CanPerformAlgebraicPointOps) {
  {
    IPoint p1(1, 2);
    IPoint p2 = p1 + IPoint(1, 2);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(3, 6);
    IPoint p2 = p1 - IPoint(1, 2);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(1, 2);
    IPoint p2 = p1 * IPoint(2, 3);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 6u);
  }

  {
    IPoint p1(2, 6);
    IPoint p2 = p1 / IPoint(2, 3);
    ASSERT_EQ(p2.x, 1u);
    ASSERT_EQ(p2.y, 2u);
  }
}

TEST(GeometryTest, CanPerformAlgebraicPointOpsWithArithmeticTypes) {
  // LHS
  {
    IPoint p1(1, 2);
    IPoint p2 = p1 * 2.0f;
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(2, 6);
    IPoint p2 = p1 / 2.0f;
    ASSERT_EQ(p2.x, 1u);
    ASSERT_EQ(p2.y, 3u);
  }

  // RHS
  {
    IPoint p1(1, 2);
    IPoint p2 = 2.0f * p1;
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(2, 6);
    IPoint p2 = 12.0f / p1;
    ASSERT_EQ(p2.x, 6u);
    ASSERT_EQ(p2.y, 2u);
  }
}

TEST(GeometryTest, PointIntegerCoercesToFloat) {
  // Integer on LHS, float on RHS
  {
    IPoint p1(1, 2);
    Point p2 = p1 + Point(1, 2);
    ASSERT_FLOAT_EQ(p2.x, 2u);
    ASSERT_FLOAT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(3, 6);
    Point p2 = p1 - Point(1, 2);
    ASSERT_FLOAT_EQ(p2.x, 2u);
    ASSERT_FLOAT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(1, 2);
    Point p2 = p1 * Point(2, 3);
    ASSERT_FLOAT_EQ(p2.x, 2u);
    ASSERT_FLOAT_EQ(p2.y, 6u);
  }

  {
    IPoint p1(2, 6);
    Point p2 = p1 / Point(2, 3);
    ASSERT_FLOAT_EQ(p2.x, 1u);
    ASSERT_FLOAT_EQ(p2.y, 2u);
  }

  // Float on LHS, integer on RHS
  {
    Point p1(1, 2);
    Point p2 = p1 + IPoint(1, 2);
    ASSERT_FLOAT_EQ(p2.x, 2u);
    ASSERT_FLOAT_EQ(p2.y, 4u);
  }

  {
    Point p1(3, 6);
    Point p2 = p1 - IPoint(1, 2);
    ASSERT_FLOAT_EQ(p2.x, 2u);
    ASSERT_FLOAT_EQ(p2.y, 4u);
  }

  {
    Point p1(1, 2);
    Point p2 = p1 * IPoint(2, 3);
    ASSERT_FLOAT_EQ(p2.x, 2u);
    ASSERT_FLOAT_EQ(p2.y, 6u);
  }

  {
    Point p1(2, 6);
    Point p2 = p1 / IPoint(2, 3);
    ASSERT_FLOAT_EQ(p2.x, 1u);
    ASSERT_FLOAT_EQ(p2.y, 2u);
  }
}

TEST(GeometryTest, SizeCoercesToPoint) {
  // Point on LHS, Size on RHS
  {
    IPoint p1(1, 2);
    IPoint p2 = p1 + ISize(1, 2);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(3, 6);
    IPoint p2 = p1 - ISize(1, 2);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    IPoint p1(1, 2);
    IPoint p2 = p1 * ISize(2, 3);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 6u);
  }

  {
    IPoint p1(2, 6);
    IPoint p2 = p1 / ISize(2, 3);
    ASSERT_EQ(p2.x, 1u);
    ASSERT_EQ(p2.y, 2u);
  }

  // Size on LHS, Point on RHS
  {
    ISize p1(1, 2);
    IPoint p2 = p1 + IPoint(1, 2);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    ISize p1(3, 6);
    IPoint p2 = p1 - IPoint(1, 2);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
  }

  {
    ISize p1(1, 2);
    IPoint p2 = p1 * IPoint(2, 3);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 6u);
  }

  {
    ISize p1(2, 6);
    IPoint p2 = p1 / IPoint(2, 3);
    ASSERT_EQ(p2.x, 1u);
    ASSERT_EQ(p2.y, 2u);
  }
}

TEST(GeometryTest, CanUsePointAssignmentOperators) {
  // Point on RHS
  {
    IPoint p(1, 2);
    p += IPoint(1, 2);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 4u);
  }

  {
    IPoint p(3, 6);
    p -= IPoint(1, 2);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 4u);
  }

  {
    IPoint p(1, 2);
    p *= IPoint(2, 3);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 6u);
  }

  {
    IPoint p(2, 6);
    p /= IPoint(2, 3);
    ASSERT_EQ(p.x, 1u);
    ASSERT_EQ(p.y, 2u);
  }

  // Size on RHS
  {
    IPoint p(1, 2);
    p += ISize(1, 2);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 4u);
  }

  {
    IPoint p(3, 6);
    p -= ISize(1, 2);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 4u);
  }

  {
    IPoint p(1, 2);
    p *= ISize(2, 3);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 6u);
  }

  {
    IPoint p(2, 6);
    p /= ISize(2, 3);
    ASSERT_EQ(p.x, 1u);
    ASSERT_EQ(p.y, 2u);
  }

  // Arithmetic type on RHS
  {
    IPoint p(1, 2);
    p *= 3;
    ASSERT_EQ(p.x, 3u);
    ASSERT_EQ(p.y, 6u);
  }

  {
    IPoint p(3, 6);
    p /= 3;
    ASSERT_EQ(p.x, 1u);
    ASSERT_EQ(p.y, 2u);
  }
}

TEST(GeometryTest, PointDotProduct) {
  {
    Point p(1, 0);
    Scalar s = p.Dot(Point(-1, 0));
    ASSERT_FLOAT_EQ(s, -1);
  }

  {
    Point p(0, -1);
    Scalar s = p.Dot(Point(-1, 0));
    ASSERT_FLOAT_EQ(s, 0);
  }

  {
    Point p(1, 2);
    Scalar s = p.Dot(Point(3, -4));
    ASSERT_FLOAT_EQ(s, -5);
  }
}

TEST(GeometryTest, PointCrossProduct) {
  {
    Point p(1, 0);
    Scalar s = p.Cross(Point(-1, 0));
    ASSERT_FLOAT_EQ(s, 0);
  }

  {
    Point p(0, -1);
    Scalar s = p.Cross(Point(-1, 0));
    ASSERT_FLOAT_EQ(s, -1);
  }

  {
    Point p(1, 2);
    Scalar s = p.Cross(Point(3, -4));
    ASSERT_FLOAT_EQ(s, -10);
  }
}

TEST(GeometryTest, PointReflect) {
  {
    Point axis = Point(0, 1);
    Point a(2, 3);
    auto reflected = a.Reflect(axis);
    auto expected = Point(2, -3);
    ASSERT_POINT_NEAR(reflected, expected);
  }

  {
    Point axis = Point(1, 1).Normalize();
    Point a(1, 0);
    auto reflected = a.Reflect(axis);
    auto expected = Point(0, -1);
    ASSERT_POINT_NEAR(reflected, expected);
  }

  {
    Point axis = Point(1, 1).Normalize();
    Point a(-1, -1);
    auto reflected = a.Reflect(axis);
    ASSERT_POINT_NEAR(reflected, -a);
  }
}

TEST(GeometryTest, PointAbs) {
  Point a(-1, -2);
  auto a_abs = a.Abs();
  auto expected = Point(1, 2);
  ASSERT_POINT_NEAR(a_abs, expected);
}

TEST(GeometryTest, PointAngleTo) {
  // Negative result in the CCW (with up = -Y) direction.
  {
    Point a(1, 1);
    Point b(1, -1);
    Radians actual = a.AngleTo(b);
    Radians expected = Radians{-kPi / 2};
    ASSERT_FLOAT_EQ(actual.radians, expected.radians);
  }

  // Check the other direction to ensure the result is signed correctly.
  {
    Point a(1, -1);
    Point b(1, 1);
    Radians actual = a.AngleTo(b);
    Radians expected = Radians{kPi / 2};
    ASSERT_FLOAT_EQ(actual.radians, expected.radians);
  }

  // Differences in magnitude should have no impact on the result.
  {
    Point a(100, -100);
    Point b(0.01, 0.01);
    Radians actual = a.AngleTo(b);
    Radians expected = Radians{kPi / 2};
    ASSERT_FLOAT_EQ(actual.radians, expected.radians);
  }
}

TEST(GeometryTest, PointMin) {
  Point p(1, 2);
  Point result = p.Min({0, 10});
  Point expected(0, 2);
  ASSERT_POINT_NEAR(result, expected);
}

TEST(GeometryTest, Vector3Min) {
  Vector3 p(1, 2, 3);
  Vector3 result = p.Min({0, 10, 2});
  Vector3 expected(0, 2, 2);
  ASSERT_VECTOR3_NEAR(result, expected);
}

TEST(GeometryTest, Vector4Min) {
  Vector4 p(1, 2, 3, 4);
  Vector4 result = p.Min({0, 10, 2, 1});
  Vector4 expected(0, 2, 2, 1);
  ASSERT_VECTOR4_NEAR(result, expected);
}

TEST(GeometryTest, PointMax) {
  Point p(1, 2);
  Point result = p.Max({0, 10});
  Point expected(1, 10);
  ASSERT_POINT_NEAR(result, expected);
}

TEST(GeometryTest, Vector3Max) {
  Vector3 p(1, 2, 3);
  Vector3 result = p.Max({0, 10, 2});
  Vector3 expected(1, 10, 3);
  ASSERT_VECTOR3_NEAR(result, expected);
}

TEST(GeometryTest, Vector4Max) {
  Vector4 p(1, 2, 3, 4);
  Vector4 result = p.Max({0, 10, 2, 1});
  Vector4 expected(1, 10, 3, 4);
  ASSERT_VECTOR4_NEAR(result, expected);
}

TEST(GeometryTest, PointFloor) {
  Point p(1.5, 2.3);
  Point result = p.Floor();
  Point expected(1, 2);
  ASSERT_POINT_NEAR(result, expected);
}

TEST(GeometryTest, Vector3Floor) {
  Vector3 p(1.5, 2.3, 3.9);
  Vector3 result = p.Floor();
  Vector3 expected(1, 2, 3);
  ASSERT_VECTOR3_NEAR(result, expected);
}

TEST(GeometryTest, Vector4Floor) {
  Vector4 p(1.5, 2.3, 3.9, 4.0);
  Vector4 result = p.Floor();
  Vector4 expected(1, 2, 3, 4);
  ASSERT_VECTOR4_NEAR(result, expected);
}

TEST(GeometryTest, PointCeil) {
  Point p(1.5, 2.3);
  Point result = p.Ceil();
  Point expected(2, 3);
  ASSERT_POINT_NEAR(result, expected);
}

TEST(GeometryTest, Vector3Ceil) {
  Vector3 p(1.5, 2.3, 3.9);
  Vector3 result = p.Ceil();
  Vector3 expected(2, 3, 4);
  ASSERT_VECTOR3_NEAR(result, expected);
}

TEST(GeometryTest, Vector4Ceil) {
  Vector4 p(1.5, 2.3, 3.9, 4.0);
  Vector4 result = p.Ceil();
  Vector4 expected(2, 3, 4, 4);
  ASSERT_VECTOR4_NEAR(result, expected);
}

TEST(GeometryTest, PointRound) {
  Point p(1.5, 2.3);
  Point result = p.Round();
  Point expected(2, 2);
  ASSERT_POINT_NEAR(result, expected);
}

TEST(GeometryTest, Vector3Round) {
  Vector3 p(1.5, 2.3, 3.9);
  Vector3 result = p.Round();
  Vector3 expected(2, 2, 4);
  ASSERT_VECTOR3_NEAR(result, expected);
}

TEST(GeometryTest, Vector4Round) {
  Vector4 p(1.5, 2.3, 3.9, 4.0);
  Vector4 result = p.Round();
  Vector4 expected(2, 2, 4, 4);
  ASSERT_VECTOR4_NEAR(result, expected);
}

TEST(GeometryTest, PointLerp) {
  Point p(1, 2);
  Point result = p.Lerp({5, 10}, 0.75);
  Point expected(4, 8);
  ASSERT_POINT_NEAR(result, expected);
}

TEST(GeometryTest, Vector3Lerp) {
  Vector3 p(1, 2, 3);
  Vector3 result = p.Lerp({5, 10, 15}, 0.75);
  Vector3 expected(4, 8, 12);
  ASSERT_VECTOR3_NEAR(result, expected);
}

TEST(GeometryTest, Vector4Lerp) {
  Vector4 p(1, 2, 3, 4);
  Vector4 result = p.Lerp({5, 10, 15, 20}, 0.75);
  Vector4 expected(4, 8, 12, 16);
  ASSERT_VECTOR4_NEAR(result, expected);
}

TEST(GeometryTest, CanUseVector3AssignmentOperators) {
  {
    Vector3 p(1, 2, 4);
    p += Vector3(1, 2, 4);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 4u);
    ASSERT_EQ(p.z, 8u);
  }

  {
    Vector3 p(3, 6, 8);
    p -= Vector3(1, 2, 3);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 4u);
    ASSERT_EQ(p.z, 5u);
  }

  {
    Vector3 p(1, 2, 3);
    p *= Vector3(2, 3, 4);
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 6u);
    ASSERT_EQ(p.z, 12u);
  }

  {
    Vector3 p(1, 2, 3);
    p *= 2;
    ASSERT_EQ(p.x, 2u);
    ASSERT_EQ(p.y, 4u);
    ASSERT_EQ(p.z, 6u);
  }

  {
    Vector3 p(2, 6, 12);
    p /= Vector3(2, 3, 4);
    ASSERT_EQ(p.x, 1u);
    ASSERT_EQ(p.y, 2u);
    ASSERT_EQ(p.z, 3u);
  }

  {
    Vector3 p(2, 6, 12);
    p /= 2;
    ASSERT_EQ(p.x, 1u);
    ASSERT_EQ(p.y, 3u);
    ASSERT_EQ(p.z, 6u);
  }
}

TEST(GeometryTest, CanPerformAlgebraicVector3Ops) {
  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = p1 + Vector3(1, 2, 3);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
    ASSERT_EQ(p2.z, 6u);
  }

  {
    Vector3 p1(3, 6, 9);
    Vector3 p2 = p1 - Vector3(1, 2, 3);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 4u);
    ASSERT_EQ(p2.z, 6u);
  }

  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = p1 * Vector3(2, 3, 4);
    ASSERT_EQ(p2.x, 2u);
    ASSERT_EQ(p2.y, 6u);
    ASSERT_EQ(p2.z, 12u);
  }

  {
    Vector3 p1(2, 6, 12);
    Vector3 p2 = p1 / Vector3(2, 3, 4);
    ASSERT_EQ(p2.x, 1u);
    ASSERT_EQ(p2.y, 2u);
    ASSERT_EQ(p2.z, 3u);
  }
}

TEST(GeometryTest, CanPerformAlgebraicVector3OpsWithArithmeticTypes) {
  // LHS
  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = p1 + 2.0f;
    ASSERT_EQ(p2.x, 3);
    ASSERT_EQ(p2.y, 4);
    ASSERT_EQ(p2.z, 5);
  }

  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = p1 - 2.0f;
    ASSERT_EQ(p2.x, -1);
    ASSERT_EQ(p2.y, 0);
    ASSERT_EQ(p2.z, 1);
  }

  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = p1 * 2.0f;
    ASSERT_EQ(p2.x, 2);
    ASSERT_EQ(p2.y, 4);
    ASSERT_EQ(p2.z, 6);
  }

  {
    Vector3 p1(2, 6, 12);
    Vector3 p2 = p1 / 2.0f;
    ASSERT_EQ(p2.x, 1);
    ASSERT_EQ(p2.y, 3);
    ASSERT_EQ(p2.z, 6);
  }

  // RHS
  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = 2.0f + p1;
    ASSERT_EQ(p2.x, 3);
    ASSERT_EQ(p2.y, 4);
    ASSERT_EQ(p2.z, 5);
  }

  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = 2.0f - p1;
    ASSERT_EQ(p2.x, 1);
    ASSERT_EQ(p2.y, 0);
    ASSERT_EQ(p2.z, -1);
  }

  {
    Vector3 p1(1, 2, 3);
    Vector3 p2 = 2.0f * p1;
    ASSERT_EQ(p2.x, 2);
    ASSERT_EQ(p2.y, 4);
    ASSERT_EQ(p2.z, 6);
  }

  {
    Vector3 p1(2, 6, 12);
    Vector3 p2 = 12.0f / p1;
    ASSERT_EQ(p2.x, 6);
    ASSERT_EQ(p2.y, 2);
    ASSERT_EQ(p2.z, 1);
  }
}

TEST(GeometryTest, ColorPremultiply) {
  {
    Color a(1.0, 0.5, 0.2, 0.5);
    Color premultiplied = a.Premultiply();
    Color expected = Color(0.5, 0.25, 0.1, 0.5);
    ASSERT_COLOR_NEAR(premultiplied, expected);
  }

  {
    Color a(0.5, 0.25, 0.1, 0.5);
    Color unpremultiplied = a.Unpremultiply();
    Color expected = Color(1.0, 0.5, 0.2, 0.5);
    ASSERT_COLOR_NEAR(unpremultiplied, expected);
  }

  {
    Color a(0.5, 0.25, 0.1, 0.0);
    Color unpremultiplied = a.Unpremultiply();
    Color expected = Color(0.0, 0.0, 0.0, 0.0);
    ASSERT_COLOR_NEAR(unpremultiplied, expected);
  }
}

TEST(GeometryTest, ColorR8G8B8A8) {
  {
    Color a(1.0, 0.5, 0.2, 0.5);
    std::array<uint8_t, 4> expected = {255, 128, 51, 128};
    ASSERT_ARRAY_4_NEAR(a.ToR8G8B8A8(), expected);
  }

  {
    Color a(0.0, 0.0, 0.0, 0.0);
    std::array<uint8_t, 4> expected = {0, 0, 0, 0};
    ASSERT_ARRAY_4_NEAR(a.ToR8G8B8A8(), expected);
  }

  {
    Color a(1.0, 1.0, 1.0, 1.0);
    std::array<uint8_t, 4> expected = {255, 255, 255, 255};
    ASSERT_ARRAY_4_NEAR(a.ToR8G8B8A8(), expected);
  }
}

TEST(GeometryTest, ColorLerp) {
  {
    Color a(0.0, 0.0, 0.0, 0.0);
    Color b(1.0, 1.0, 1.0, 1.0);

    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 0.5), Color(0.5, 0.5, 0.5, 0.5));
    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 0.0), a);
    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 1.0), b);
    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 0.2), Color(0.2, 0.2, 0.2, 0.2));
  }

  {
    Color a(0.2, 0.4, 1.0, 0.5);
    Color b(0.4, 1.0, 0.2, 0.3);

    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 0.5), Color(0.3, 0.7, 0.6, 0.4));
    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 0.0), a);
    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 1.0), b);
    ASSERT_COLOR_NEAR(Color::Lerp(a, b, 0.2), Color(0.24, 0.52, 0.84, 0.46));
  }
}

TEST(GeometryTest, ColorClamp01) {
  {
    Color result = Color(0.5, 0.5, 0.5, 0.5).Clamp01();
    Color expected = Color(0.5, 0.5, 0.5, 0.5);
    ASSERT_COLOR_NEAR(result, expected);
  }

  {
    Color result = Color(-1, -1, -1, -1).Clamp01();
    Color expected = Color(0, 0, 0, 0);
    ASSERT_COLOR_NEAR(result, expected);
  }

  {
    Color result = Color(2, 2, 2, 2).Clamp01();
    Color expected = Color(1, 1, 1, 1);
    ASSERT_COLOR_NEAR(result, expected);
  }
}

TEST(GeometryTest, ColorMakeRGBA8) {
  {
    Color a = Color::MakeRGBA8(0, 0, 0, 0);
    Color b = Color::BlackTransparent();
    ASSERT_COLOR_NEAR(a, b);
  }

  {
    Color a = Color::MakeRGBA8(255, 255, 255, 255);
    Color b = Color::White();
    ASSERT_COLOR_NEAR(a, b);
  }

  {
    Color a = Color::MakeRGBA8(63, 127, 191, 127);
    Color b(0.247059, 0.498039, 0.74902, 0.498039);
    ASSERT_COLOR_NEAR(a, b);
  }
}

TEST(GeometryTest, ColorApplyColorMatrix) {
  {
    ColorMatrix color_matrix = {
        1, 1, 1, 1, 1,  //
        1, 1, 1, 1, 1,  //
        1, 1, 1, 1, 1,  //
        1, 1, 1, 1, 1,  //
    };
    auto result = Color::White().ApplyColorMatrix(color_matrix);
    auto expected = Color(1, 1, 1, 1);
    ASSERT_COLOR_NEAR(result, expected);
  }

  {
    ColorMatrix color_matrix = {
        0.1, 0,   0,   0,   0.01,  //
        0,   0.2, 0,   0,   0.02,  //
        0,   0,   0.3, 0,   0.03,  //
        0,   0,   0,   0.4, 0.04,  //
    };
    auto result = Color::White().ApplyColorMatrix(color_matrix);
    auto expected = Color(0.11, 0.22, 0.33, 0.44);
    ASSERT_COLOR_NEAR(result, expected);
  }
}

TEST(GeometryTest, ColorLinearToSRGB) {
  {
    auto result = Color::White().LinearToSRGB();
    auto expected = Color(1, 1, 1, 1);
    ASSERT_COLOR_NEAR(result, expected);
  }

  {
    auto result = Color::BlackTransparent().LinearToSRGB();
    auto expected = Color(0, 0, 0, 0);
    ASSERT_COLOR_NEAR(result, expected);
  }

  {
    auto result = Color(0.2, 0.4, 0.6, 0.8).LinearToSRGB();
    auto expected = Color(0.484529, 0.665185, 0.797738, 0.8);
    ASSERT_COLOR_NEAR(result, expected);
  }
}

TEST(GeometryTest, ColorSRGBToLinear) {
  {
    auto result = Color::White().SRGBToLinear();
    auto expected = Color(1, 1, 1, 1);
    ASSERT_COLOR_NEAR(result, expected);
  }

  {
    auto result = Color::BlackTransparent().SRGBToLinear();
    auto expected = Color(0, 0, 0, 0);
    ASSERT_COLOR_NEAR(result, expected);
  }

  {
    auto result = Color(0.2, 0.4, 0.6, 0.8).SRGBToLinear();
    auto expected = Color(0.0331048, 0.132868, 0.318547, 0.8);
    ASSERT_COLOR_NEAR(result, expected);
  }
}

#define _BLEND_MODE_NAME_CHECK(blend_mode) \
  case BlendMode::k##blend_mode:           \
    ASSERT_STREQ(result, #blend_mode);     \
    break;

TEST(GeometryTest, BlendModeToString) {
  using BlendT = std::underlying_type_t<BlendMode>;
  for (BlendT i = 0; i <= static_cast<BlendT>(BlendMode::kLast); i++) {
    auto mode = static_cast<BlendMode>(i);
    auto result = BlendModeToString(mode);
    switch (mode) { IMPELLER_FOR_EACH_BLEND_MODE(_BLEND_MODE_NAME_CHECK) }
  }
}

TEST(GeometryTest, CanConvertBetweenDegressAndRadians) {
  {
    auto deg = Degrees{90.0};
    Radians rad = deg;
    ASSERT_FLOAT_EQ(rad.radians, kPiOver2);
  }
}

TEST(GeometryTest, RectMakeSize) {
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

TEST(GeometryTest, RectUnion) {
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(0, 0, 0, 0);
    auto u = a.Union(b);
    auto expected = Rect::MakeXYWH(0, 0, 200, 200);
    ASSERT_RECT_NEAR(u, expected);
  }

  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(10, 10, 0, 0);
    auto u = a.Union(b);
    auto expected = Rect::MakeXYWH(10, 10, 190, 190);
    ASSERT_RECT_NEAR(u, expected);
  }

  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(10, 10, 100, 100);
    auto u = a.Union(b);
    auto expected = Rect::MakeXYWH(0, 0, 110, 110);
    ASSERT_RECT_NEAR(u, expected);
  }

  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(100, 100, 100, 100);
    auto u = a.Union(b);
    auto expected = Rect::MakeXYWH(0, 0, 200, 200);
    ASSERT_RECT_NEAR(u, expected);
  }
}

TEST(GeometryTest, OptRectUnion) {
  Rect a = Rect::MakeLTRB(0, 0, 100, 100);
  Rect b = Rect::MakeLTRB(100, 100, 200, 200);
  Rect c = Rect::MakeLTRB(100, 0, 200, 100);

  // NullOpt, NullOpt
  EXPECT_FALSE(Union(std::nullopt, std::nullopt).has_value());
  EXPECT_EQ(Union(std::nullopt, std::nullopt), std::nullopt);

  auto test1 = [](const Rect& r) {
    // Rect, NullOpt
    EXPECT_TRUE(Union(r, std::nullopt).has_value());
    EXPECT_EQ(Union(r, std::nullopt).value(), r);

    // OptRect, NullOpt
    EXPECT_TRUE(Union(std::optional(r), std::nullopt).has_value());
    EXPECT_EQ(Union(std::optional(r), std::nullopt).value(), r);

    // NullOpt, Rect
    EXPECT_TRUE(Union(std::nullopt, r).has_value());
    EXPECT_EQ(Union(std::nullopt, r).value(), r);

    // NullOpt, OptRect
    EXPECT_TRUE(Union(std::nullopt, std::optional(r)).has_value());
    EXPECT_EQ(Union(std::nullopt, std::optional(r)).value(), r);
  };

  test1(a);
  test1(b);
  test1(c);

  auto test2 = [](const Rect& a, const Rect& b, const Rect& u) {
    ASSERT_EQ(a.Union(b), u);

    // Rect, OptRect
    EXPECT_TRUE(Union(a, std::optional(b)).has_value());
    EXPECT_EQ(Union(a, std::optional(b)).value(), u);

    // OptRect, Rect
    EXPECT_TRUE(Union(std::optional(a), b).has_value());
    EXPECT_EQ(Union(std::optional(a), b).value(), u);

    // OptRect, OptRect
    EXPECT_TRUE(Union(std::optional(a), std::optional(b)).has_value());
    EXPECT_EQ(Union(std::optional(a), std::optional(b)).value(), u);
  };

  test2(a, b, Rect::MakeLTRB(0, 0, 200, 200));
  test2(a, c, Rect::MakeLTRB(0, 0, 200, 100));
  test2(b, c, Rect::MakeLTRB(100, 0, 200, 200));
}

TEST(GeometryTest, RectIntersection) {
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(0, 0, 0, 0);

    auto u = a.Intersection(b);
    ASSERT_FALSE(u.has_value());
  }

  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(10, 10, 0, 0);
    auto u = a.Intersection(b);
    ASSERT_FALSE(u.has_value());
  }

  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(10, 10, 100, 100);
    auto u = a.Intersection(b);
    ASSERT_TRUE(u.has_value());
    auto expected = Rect::MakeXYWH(10, 10, 90, 90);
    ASSERT_RECT_NEAR(u.value(), expected);
  }

  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(100, 100, 100, 100);
    auto u = a.Intersection(b);
    ASSERT_FALSE(u.has_value());
  }

  {
    Rect a = Rect::MakeMaximum();
    Rect b = Rect::MakeXYWH(10, 10, 300, 300);
    auto u = a.Intersection(b);
    ASSERT_TRUE(u);
    ASSERT_RECT_NEAR(u.value(), b);
  }

  {
    Rect a = Rect::MakeMaximum();
    Rect b = Rect::MakeMaximum();
    auto u = a.Intersection(b);
    ASSERT_TRUE(u);
    ASSERT_EQ(u, Rect::MakeMaximum());
  }
}

TEST(GeometryTest, OptRectIntersection) {
  Rect a = Rect::MakeLTRB(0, 0, 110, 110);
  Rect b = Rect::MakeLTRB(100, 100, 200, 200);
  Rect c = Rect::MakeLTRB(100, 0, 200, 110);

  // NullOpt, NullOpt
  EXPECT_FALSE(Intersection(std::nullopt, std::nullopt).has_value());
  EXPECT_EQ(Intersection(std::nullopt, std::nullopt), std::nullopt);

  auto test1 = [](const Rect& r) {
    // Rect, NullOpt
    EXPECT_TRUE(Intersection(r, std::nullopt).has_value());
    EXPECT_EQ(Intersection(r, std::nullopt).value(), r);

    // OptRect, NullOpt
    EXPECT_TRUE(Intersection(std::optional(r), std::nullopt).has_value());
    EXPECT_EQ(Intersection(std::optional(r), std::nullopt).value(), r);

    // NullOpt, Rect
    EXPECT_TRUE(Intersection(std::nullopt, r).has_value());
    EXPECT_EQ(Intersection(std::nullopt, r).value(), r);

    // NullOpt, OptRect
    EXPECT_TRUE(Intersection(std::nullopt, std::optional(r)).has_value());
    EXPECT_EQ(Intersection(std::nullopt, std::optional(r)).value(), r);
  };

  test1(a);
  test1(b);
  test1(c);

  auto test2 = [](const Rect& a, const Rect& b, const Rect& i) {
    ASSERT_EQ(a.Intersection(b), i);

    // Rect, OptRect
    EXPECT_TRUE(Intersection(a, std::optional(b)).has_value());
    EXPECT_EQ(Intersection(a, std::optional(b)).value(), i);

    // OptRect, Rect
    EXPECT_TRUE(Intersection(std::optional(a), b).has_value());
    EXPECT_EQ(Intersection(std::optional(a), b).value(), i);

    // OptRect, OptRect
    EXPECT_TRUE(Intersection(std::optional(a), std::optional(b)).has_value());
    EXPECT_EQ(Intersection(std::optional(a), std::optional(b)).value(), i);
  };

  test2(a, b, Rect::MakeLTRB(100, 100, 110, 110));
  test2(a, c, Rect::MakeLTRB(100, 0, 110, 110));
  test2(b, c, Rect::MakeLTRB(100, 100, 200, 110));
}

TEST(GeometryTest, RectIntersectsWithRect) {
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(0, 0, 0, 0);
    ASSERT_FALSE(a.IntersectsWithRect(b));
  }

  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(10, 10, 0, 0);
    ASSERT_FALSE(a.IntersectsWithRect(b));
  }

  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(10, 10, 100, 100);
    ASSERT_TRUE(a.IntersectsWithRect(b));
  }

  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(100, 100, 100, 100);
    ASSERT_FALSE(a.IntersectsWithRect(b));
  }

  {
    Rect a = Rect::MakeMaximum();
    Rect b = Rect::MakeXYWH(10, 10, 100, 100);
    ASSERT_TRUE(a.IntersectsWithRect(b));
  }

  {
    Rect a = Rect::MakeMaximum();
    Rect b = Rect::MakeMaximum();
    ASSERT_TRUE(a.IntersectsWithRect(b));
  }
}

TEST(GeometryTest, RectCutout) {
  // No cutout.
  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(0, 0, 50, 50);
    auto u = a.Cutout(b);
    ASSERT_TRUE(u.has_value());
    ASSERT_RECT_NEAR(u.value(), a);
  }

  // Full cutout.
  {
    Rect a = Rect::MakeXYWH(0, 0, 100, 100);
    Rect b = Rect::MakeXYWH(-10, -10, 120, 120);
    auto u = a.Cutout(b);
    ASSERT_FALSE(u.has_value());
  }

  // Cutout from top.
  {
    auto a = Rect::MakeLTRB(0, 0, 100, 100);
    auto b = Rect::MakeLTRB(-10, -10, 110, 90);
    auto u = a.Cutout(b);
    auto expected = Rect::MakeLTRB(0, 90, 100, 100);
    ASSERT_TRUE(u.has_value());
    ASSERT_RECT_NEAR(u.value(), expected);
  }

  // Cutout from bottom.
  {
    auto a = Rect::MakeLTRB(0, 0, 100, 100);
    auto b = Rect::MakeLTRB(-10, 10, 110, 110);
    auto u = a.Cutout(b);
    auto expected = Rect::MakeLTRB(0, 0, 100, 10);
    ASSERT_TRUE(u.has_value());
    ASSERT_RECT_NEAR(u.value(), expected);
  }

  // Cutout from left.
  {
    auto a = Rect::MakeLTRB(0, 0, 100, 100);
    auto b = Rect::MakeLTRB(-10, -10, 90, 110);
    auto u = a.Cutout(b);
    auto expected = Rect::MakeLTRB(90, 0, 100, 100);
    ASSERT_TRUE(u.has_value());
    ASSERT_RECT_NEAR(u.value(), expected);
  }

  // Cutout from right.
  {
    auto a = Rect::MakeLTRB(0, 0, 100, 100);
    auto b = Rect::MakeLTRB(10, -10, 110, 110);
    auto u = a.Cutout(b);
    auto expected = Rect::MakeLTRB(0, 0, 10, 100);
    ASSERT_TRUE(u.has_value());
    ASSERT_RECT_NEAR(u.value(), expected);
  }
}

TEST(GeometryTest, RectContainsPoint) {
  {
    // Origin is inclusive
    Rect r = Rect::MakeXYWH(100, 100, 100, 100);
    Point p(100, 100);
    ASSERT_TRUE(r.Contains(p));
  }
  {
    // Size is exclusive
    Rect r = Rect::MakeXYWH(100, 100, 100, 100);
    Point p(200, 200);
    ASSERT_FALSE(r.Contains(p));
  }
  {
    Rect r = Rect::MakeXYWH(100, 100, 100, 100);
    Point p(99, 99);
    ASSERT_FALSE(r.Contains(p));
  }
  {
    Rect r = Rect::MakeXYWH(100, 100, 100, 100);
    Point p(199, 199);
    ASSERT_TRUE(r.Contains(p));
  }

  {
    Rect r = Rect::MakeMaximum();
    Point p(199, 199);
    ASSERT_TRUE(r.Contains(p));
  }
}

TEST(GeometryTest, RectContainsRect) {
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    ASSERT_TRUE(a.Contains(a));
  }
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(0, 0, 0, 0);
    ASSERT_FALSE(a.Contains(b));
  }
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(150, 150, 20, 20);
    ASSERT_TRUE(a.Contains(b));
  }
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(150, 150, 100, 100);
    ASSERT_FALSE(a.Contains(b));
  }
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(50, 50, 100, 100);
    ASSERT_FALSE(a.Contains(b));
  }
  {
    Rect a = Rect::MakeXYWH(100, 100, 100, 100);
    Rect b = Rect::MakeXYWH(0, 0, 300, 300);
    ASSERT_FALSE(a.Contains(b));
  }
  {
    Rect a = Rect::MakeMaximum();
    Rect b = Rect::MakeXYWH(0, 0, 300, 300);
    ASSERT_TRUE(a.Contains(b));
  }
}

TEST(GeometryTest, RectGetPoints) {
  {
    Rect r = Rect::MakeXYWH(100, 200, 300, 400);
    auto points = r.GetPoints();
    ASSERT_POINT_NEAR(points[0], Point(100, 200));
    ASSERT_POINT_NEAR(points[1], Point(400, 200));
    ASSERT_POINT_NEAR(points[2], Point(100, 600));
    ASSERT_POINT_NEAR(points[3], Point(400, 600));
  }

  {
    Rect r = Rect::MakeMaximum();
    auto points = r.GetPoints();
    ASSERT_EQ(points[0], Point(-std::numeric_limits<float>::infinity(),
                               -std::numeric_limits<float>::infinity()));
    ASSERT_EQ(points[1], Point(std::numeric_limits<float>::infinity(),
                               -std::numeric_limits<float>::infinity()));
    ASSERT_EQ(points[2], Point(-std::numeric_limits<float>::infinity(),
                               std::numeric_limits<float>::infinity()));
    ASSERT_EQ(points[3], Point(std::numeric_limits<float>::infinity(),
                               std::numeric_limits<float>::infinity()));
  }
}

TEST(GeometryTest, RectShift) {
  auto r = Rect::MakeLTRB(0, 0, 100, 100);

  ASSERT_EQ(r.Shift(Point(10, 5)), Rect::MakeLTRB(10, 5, 110, 105));
  ASSERT_EQ(r.Shift(Point(-10, -5)), Rect::MakeLTRB(-10, -5, 90, 95));
}

TEST(GeometryTest, RectGetTransformedPoints) {
  Rect r = Rect::MakeXYWH(100, 200, 300, 400);
  auto points = r.GetTransformedPoints(Matrix::MakeTranslation({10, 20}));
  ASSERT_POINT_NEAR(points[0], Point(110, 220));
  ASSERT_POINT_NEAR(points[1], Point(410, 220));
  ASSERT_POINT_NEAR(points[2], Point(110, 620));
  ASSERT_POINT_NEAR(points[3], Point(410, 620));
}

TEST(GeometryTest, RectMakePointBounds) {
  {
    std::vector<Point> points{{1, 5}, {4, -1}, {0, 6}};
    Rect r = Rect::MakePointBounds(points.begin(), points.end()).value();
    auto expected = Rect::MakeXYWH(0, -1, 4, 7);
    ASSERT_RECT_NEAR(r, expected);
  }
  {
    std::vector<Point> points;
    std::optional<Rect> r = Rect::MakePointBounds(points.begin(), points.end());
    ASSERT_FALSE(r.has_value());
  }
}

TEST(GeometryTest, RectExpand) {
  {
    auto a = Rect::MakeLTRB(100, 100, 200, 200);
    auto b = a.Expand(1);
    auto expected = Rect::MakeLTRB(99, 99, 201, 201);
    ASSERT_RECT_NEAR(b, expected);
  }
  {
    auto a = Rect::MakeLTRB(100, 100, 200, 200);
    auto b = a.Expand(-1);
    auto expected = Rect::MakeLTRB(101, 101, 199, 199);
    ASSERT_RECT_NEAR(b, expected);
  }

  {
    auto a = Rect::MakeLTRB(100, 100, 200, 200);
    auto b = a.Expand(1, 2, 3, 4);
    auto expected = Rect::MakeLTRB(99, 98, 203, 204);
    ASSERT_RECT_NEAR(b, expected);
  }
  {
    auto a = Rect::MakeLTRB(100, 100, 200, 200);
    auto b = a.Expand(-1, -2, -3, -4);
    auto expected = Rect::MakeLTRB(101, 102, 197, 196);
    ASSERT_RECT_NEAR(b, expected);
  }
}

TEST(GeometryTest, RectGetPositive) {
  {
    Rect r = Rect::MakeXYWH(100, 200, 300, 400);
    auto actual = r.GetPositive();
    ASSERT_RECT_NEAR(r, actual);
  }
  {
    Rect r = Rect::MakeXYWH(100, 200, -100, -100);
    auto actual = r.GetPositive();
    Rect expected = Rect::MakeXYWH(0, 100, 100, 100);
    ASSERT_RECT_NEAR(expected, actual);
  }
}

TEST(GeometryTest, RectScale) {
  {
    auto r = Rect::MakeLTRB(-100, -100, 100, 100);
    auto actual = r.Scale(0);
    auto expected = Rect::MakeLTRB(0, 0, 0, 0);
    ASSERT_RECT_NEAR(expected, actual);
  }
  {
    auto r = Rect::MakeLTRB(-100, -100, 100, 100);
    auto actual = r.Scale(-2);
    auto expected = Rect::MakeLTRB(200, 200, -200, -200);
    ASSERT_RECT_NEAR(expected, actual);
  }
  {
    auto r = Rect::MakeLTRB(-100, -100, 100, 100);
    auto actual = r.Scale(Point{0, 0});
    auto expected = Rect::MakeLTRB(0, 0, 0, 0);
    ASSERT_RECT_NEAR(expected, actual);
  }
  {
    auto r = Rect::MakeLTRB(-100, -100, 100, 100);
    auto actual = r.Scale(Size{-1, -2});
    auto expected = Rect::MakeLTRB(100, 200, -100, -200);
    ASSERT_RECT_NEAR(expected, actual);
  }
}

TEST(GeometryTest, RectDirections) {
  auto r = Rect::MakeLTRB(1, 2, 3, 4);

  ASSERT_EQ(r.GetLeft(), 1);
  ASSERT_EQ(r.GetTop(), 2);
  ASSERT_EQ(r.GetRight(), 3);
  ASSERT_EQ(r.GetBottom(), 4);

  ASSERT_POINT_NEAR(r.GetLeftTop(), Point(1, 2));
  ASSERT_POINT_NEAR(r.GetRightTop(), Point(3, 2));
  ASSERT_POINT_NEAR(r.GetLeftBottom(), Point(1, 4));
  ASSERT_POINT_NEAR(r.GetRightBottom(), Point(3, 4));
}

TEST(GeometryTest, RectProject) {
  {
    auto r = Rect::MakeLTRB(-100, -100, 100, 100);
    auto actual = r.Project(r);
    auto expected = Rect::MakeLTRB(0, 0, 1, 1);
    ASSERT_RECT_NEAR(expected, actual);
  }
  {
    auto r = Rect::MakeLTRB(-100, -100, 100, 100);
    auto actual = r.Project(Rect::MakeLTRB(0, 0, 100, 100));
    auto expected = Rect::MakeLTRB(0.5, 0.5, 1, 1);
    ASSERT_RECT_NEAR(expected, actual);
  }
}

TEST(GeometryTest, RectRoundOut) {
  {
    auto r = Rect::MakeLTRB(-100, -100, 100, 100);
    ASSERT_EQ(RoundOut(r), r);
  }
  {
    auto r = Rect::MakeLTRB(-100.1, -100.1, 100.1, 100.1);
    ASSERT_EQ(RoundOut(r), Rect::MakeLTRB(-101, -101, 101, 101));
  }
}

TEST(GeometryTest, CubicPathComponentPolylineDoesNotIncludePointOne) {
  CubicPathComponent component({10, 10}, {20, 35}, {35, 20}, {40, 40});
  auto polyline = component.CreatePolyline(1.0f);
  ASSERT_NE(polyline.front().x, 10);
  ASSERT_NE(polyline.front().y, 10);
  ASSERT_EQ(polyline.back().x, 40);
  ASSERT_EQ(polyline.back().y, 40);
}

TEST(GeometryTest, PathCreatePolyLineDoesNotDuplicatePoints) {
  PathBuilder builder;
  builder.MoveTo({10, 10});
  builder.LineTo({20, 20});
  builder.LineTo({30, 30});
  builder.MoveTo({40, 40});
  builder.LineTo({50, 50});

  auto polyline = builder.TakePath().CreatePolyline(1.0f);

  ASSERT_EQ(polyline.contours.size(), 2u);
  ASSERT_EQ(polyline.points.size(), 5u);
  ASSERT_EQ(polyline.points[0].x, 10);
  ASSERT_EQ(polyline.points[1].x, 20);
  ASSERT_EQ(polyline.points[2].x, 30);
  ASSERT_EQ(polyline.points[3].x, 40);
  ASSERT_EQ(polyline.points[4].x, 50);
}

TEST(GeometryTest, PathBuilderSetsCorrectContourPropertiesForAddCommands) {
  // Closed shapes.
  {
    Path path = PathBuilder{}.AddCircle({100, 100}, 50).TakePath();
    ContourComponent contour;
    path.GetContourComponentAtIndex(0, contour);
    ASSERT_POINT_NEAR(contour.destination, Point(100, 50));
    ASSERT_TRUE(contour.is_closed);
  }

  {
    Path path =
        PathBuilder{}.AddOval(Rect::MakeXYWH(100, 100, 100, 100)).TakePath();
    ContourComponent contour;
    path.GetContourComponentAtIndex(0, contour);
    ASSERT_POINT_NEAR(contour.destination, Point(150, 100));
    ASSERT_TRUE(contour.is_closed);
  }

  {
    Path path =
        PathBuilder{}.AddRect(Rect::MakeXYWH(100, 100, 100, 100)).TakePath();
    ContourComponent contour;
    path.GetContourComponentAtIndex(0, contour);
    ASSERT_POINT_NEAR(contour.destination, Point(100, 100));
    ASSERT_TRUE(contour.is_closed);
  }

  {
    Path path = PathBuilder{}
                    .AddRoundedRect(Rect::MakeXYWH(100, 100, 100, 100), 10)
                    .TakePath();
    ContourComponent contour;
    path.GetContourComponentAtIndex(0, contour);
    ASSERT_POINT_NEAR(contour.destination, Point(110, 100));
    ASSERT_TRUE(contour.is_closed);
  }

  // Open shapes.
  {
    Point p(100, 100);
    Path path = PathBuilder{}.AddLine(p, {200, 100}).TakePath();
    ContourComponent contour;
    path.GetContourComponentAtIndex(0, contour);
    ASSERT_POINT_NEAR(contour.destination, p);
    ASSERT_FALSE(contour.is_closed);
  }

  {
    Path path =
        PathBuilder{}
            .AddCubicCurve({100, 100}, {100, 50}, {100, 150}, {200, 100})
            .TakePath();
    ContourComponent contour;
    path.GetContourComponentAtIndex(0, contour);
    ASSERT_POINT_NEAR(contour.destination, Point(100, 100));
    ASSERT_FALSE(contour.is_closed);
  }

  {
    Path path = PathBuilder{}
                    .AddQuadraticCurve({100, 100}, {100, 50}, {200, 100})
                    .TakePath();
    ContourComponent contour;
    path.GetContourComponentAtIndex(0, contour);
    ASSERT_POINT_NEAR(contour.destination, Point(100, 100));
    ASSERT_FALSE(contour.is_closed);
  }
}

TEST(GeometryTest, PathCreatePolylineGeneratesCorrectContourData) {
  Path::Polyline polyline = PathBuilder{}
                                .AddLine({100, 100}, {200, 100})
                                .MoveTo({100, 200})
                                .LineTo({150, 250})
                                .LineTo({200, 200})
                                .Close()
                                .TakePath()
                                .CreatePolyline(1.0f);
  ASSERT_EQ(polyline.points.size(), 6u);
  ASSERT_EQ(polyline.contours.size(), 2u);
  ASSERT_EQ(polyline.contours[0].is_closed, false);
  ASSERT_EQ(polyline.contours[0].start_index, 0u);
  ASSERT_EQ(polyline.contours[1].is_closed, true);
  ASSERT_EQ(polyline.contours[1].start_index, 2u);
}

TEST(GeometryTest, PolylineGetContourPointBoundsReturnsCorrectRanges) {
  Path::Polyline polyline = PathBuilder{}
                                .AddLine({100, 100}, {200, 100})
                                .MoveTo({100, 200})
                                .LineTo({150, 250})
                                .LineTo({200, 200})
                                .Close()
                                .TakePath()
                                .CreatePolyline(1.0f);
  size_t a1, a2, b1, b2;
  std::tie(a1, a2) = polyline.GetContourPointBounds(0);
  std::tie(b1, b2) = polyline.GetContourPointBounds(1);
  ASSERT_EQ(a1, 0u);
  ASSERT_EQ(a2, 2u);
  ASSERT_EQ(b1, 2u);
  ASSERT_EQ(b2, 6u);
}

TEST(GeometryTest, PathAddRectPolylineHasCorrectContourData) {
  Path::Polyline polyline = PathBuilder{}
                                .AddRect(Rect::MakeLTRB(50, 60, 70, 80))
                                .TakePath()
                                .CreatePolyline(1.0f);
  ASSERT_EQ(polyline.contours.size(), 1u);
  ASSERT_TRUE(polyline.contours[0].is_closed);
  ASSERT_EQ(polyline.contours[0].start_index, 0u);
  ASSERT_EQ(polyline.points.size(), 5u);
  ASSERT_EQ(polyline.points[0], Point(50, 60));
  ASSERT_EQ(polyline.points[1], Point(70, 60));
  ASSERT_EQ(polyline.points[2], Point(70, 80));
  ASSERT_EQ(polyline.points[3], Point(50, 80));
  ASSERT_EQ(polyline.points[4], Point(50, 60));
}

TEST(GeometryTest, PathPolylineDuplicatesAreRemovedForSameContour) {
  Path::Polyline polyline =
      PathBuilder{}
          .MoveTo({50, 50})
          .LineTo({50, 50})  // Insert duplicate at beginning of contour.
          .LineTo({100, 50})
          .LineTo({100, 50})  // Insert duplicate at contour join.
          .LineTo({100, 100})
          .Close()  // Implicitly insert duplicate {50, 50} across contours.
          .LineTo({0, 50})
          .LineTo({0, 100})
          .LineTo({0, 100})  // Insert duplicate at end of contour.
          .TakePath()
          .CreatePolyline(1.0f);
  ASSERT_EQ(polyline.contours.size(), 2u);
  ASSERT_EQ(polyline.contours[0].start_index, 0u);
  ASSERT_TRUE(polyline.contours[0].is_closed);
  ASSERT_EQ(polyline.contours[1].start_index, 4u);
  ASSERT_FALSE(polyline.contours[1].is_closed);
  ASSERT_EQ(polyline.points.size(), 7u);
  ASSERT_EQ(polyline.points[0], Point(50, 50));
  ASSERT_EQ(polyline.points[1], Point(100, 50));
  ASSERT_EQ(polyline.points[2], Point(100, 100));
  ASSERT_EQ(polyline.points[3], Point(50, 50));
  ASSERT_EQ(polyline.points[4], Point(50, 50));
  ASSERT_EQ(polyline.points[5], Point(0, 50));
  ASSERT_EQ(polyline.points[6], Point(0, 100));
}

TEST(GeometryTest, MatrixPrinting) {
  {
    std::stringstream stream;
    Matrix m;
    stream << m;
    ASSERT_EQ(stream.str(), R"((
       1.000000,       0.000000,       0.000000,       0.000000,
       0.000000,       1.000000,       0.000000,       0.000000,
       0.000000,       0.000000,       1.000000,       0.000000,
       0.000000,       0.000000,       0.000000,       1.000000,
))");
  }

  {
    std::stringstream stream;
    Matrix m = Matrix::MakeTranslation(Vector3(10, 20, 30));
    stream << m;

    ASSERT_EQ(stream.str(), R"((
       1.000000,       0.000000,       0.000000,      10.000000,
       0.000000,       1.000000,       0.000000,      20.000000,
       0.000000,       0.000000,       1.000000,      30.000000,
       0.000000,       0.000000,       0.000000,       1.000000,
))");
  }
}

TEST(GeometryTest, PointPrinting) {
  {
    std::stringstream stream;
    Point m;
    stream << m;
    ASSERT_EQ(stream.str(), "(0, 0)");
  }

  {
    std::stringstream stream;
    Point m(13, 37);
    stream << m;
    ASSERT_EQ(stream.str(), "(13, 37)");
  }
}

TEST(GeometryTest, Vector3Printing) {
  {
    std::stringstream stream;
    Vector3 m;
    stream << m;
    ASSERT_EQ(stream.str(), "(0, 0, 0)");
  }

  {
    std::stringstream stream;
    Vector3 m(1, 2, 3);
    stream << m;
    ASSERT_EQ(stream.str(), "(1, 2, 3)");
  }
}

TEST(GeometryTest, Vector4Printing) {
  {
    std::stringstream stream;
    Vector4 m;
    stream << m;
    ASSERT_EQ(stream.str(), "(0, 0, 0, 1)");
  }

  {
    std::stringstream stream;
    Vector4 m(1, 2, 3, 4);
    stream << m;
    ASSERT_EQ(stream.str(), "(1, 2, 3, 4)");
  }
}

TEST(GeometryTest, ColorPrinting) {
  {
    std::stringstream stream;
    Color m;
    stream << m;
    ASSERT_EQ(stream.str(), "(0, 0, 0, 0)");
  }

  {
    std::stringstream stream;
    Color m(1, 2, 3, 4);
    stream << m;
    ASSERT_EQ(stream.str(), "(1, 2, 3, 4)");
  }
}

TEST(GeometryTest, ToIColor) {
  ASSERT_EQ(Color::ToIColor(Color(0, 0, 0, 0)), 0u);
  ASSERT_EQ(Color::ToIColor(Color(1.0, 1.0, 1.0, 1.0)), 0xFFFFFFFF);
  ASSERT_EQ(Color::ToIColor(Color(0.5, 0.5, 1.0, 1.0)), 0xFF8080FF);
}

TEST(GeometryTest, Gradient) {
  {
    // Simple 2 color gradient produces color buffer containing exactly those
    // values.
    std::vector<Color> colors = {Color::Red(), Color::Blue()};
    std::vector<Scalar> stops = {0.0, 1.0};

    auto gradient = CreateGradientBuffer(colors, stops);

    ASSERT_COLOR_BUFFER_NEAR(gradient.color_bytes, colors);
    ASSERT_EQ(gradient.texture_size, 2u);
  }

  {
    // Gradient with duplicate stops does not create an empty texture.
    std::vector<Color> colors = {Color::Red(), Color::Yellow(), Color::Black(),
                                 Color::Blue()};
    std::vector<Scalar> stops = {0.0, 0.25, 0.25, 1.0};

    auto gradient = CreateGradientBuffer(colors, stops);
    ASSERT_EQ(gradient.texture_size, 5u);
  }

  {
    // Simple N color gradient produces color buffer containing exactly those
    // values.
    std::vector<Color> colors = {Color::Red(), Color::Blue(), Color::Green(),
                                 Color::White()};
    std::vector<Scalar> stops = {0.0, 0.33, 0.66, 1.0};

    auto gradient = CreateGradientBuffer(colors, stops);

    ASSERT_COLOR_BUFFER_NEAR(gradient.color_bytes, colors);
    ASSERT_EQ(gradient.texture_size, 4u);
  }

  {
    // Gradient with color stops will lerp and scale buffer.
    std::vector<Color> colors = {Color::Red(), Color::Blue(), Color::Green()};
    std::vector<Scalar> stops = {0.0, 0.25, 1.0};

    auto gradient = CreateGradientBuffer(colors, stops);

    std::vector<Color> lerped_colors = {
        Color::Red(),
        Color::Blue(),
        Color::Lerp(Color::Blue(), Color::Green(), 0.3333),
        Color::Lerp(Color::Blue(), Color::Green(), 0.6666),
        Color::Green(),
    };
    ASSERT_COLOR_BUFFER_NEAR(gradient.color_bytes, lerped_colors);
    ASSERT_EQ(gradient.texture_size, 5u);
  }

  {
    // Gradient size is capped at 1024.
    std::vector<Color> colors = {};
    std::vector<Scalar> stops = {};
    for (auto i = 0u; i < 1025; i++) {
      colors.push_back(Color::Blue());
      stops.push_back(i / 1025.0);
    }

    auto gradient = CreateGradientBuffer(colors, stops);

    ASSERT_EQ(gradient.texture_size, 1024u);
    ASSERT_EQ(gradient.color_bytes.size(), 1024u * 4);
  }
}

TEST(GeometryTest, HalfConversions) {
#ifdef FML_OS_WIN
  GTEST_SKIP() << "Half-precision floats (IEEE 754) are not portable and "
                  "unavailable on Windows.";
#else
  ASSERT_EQ(ScalarToHalf(0.0), 0.0f16);
  ASSERT_EQ(ScalarToHalf(0.05), 0.05f16);
  ASSERT_EQ(ScalarToHalf(2.43), 2.43f16);
  ASSERT_EQ(ScalarToHalf(-1.45), -1.45f16);

  // 65504 is the largest possible half.
  ASSERT_EQ(ScalarToHalf(65504.0f), 65504.0f16);
  ASSERT_EQ(ScalarToHalf(65504.0f + 1), 65504.0f16);

  // Colors
  ASSERT_EQ(HalfVector4(Color::Red()),
            HalfVector4(1.0f16, 0.0f16, 0.0f16, 1.0f16));
  ASSERT_EQ(HalfVector4(Color::Green()),
            HalfVector4(0.0f16, 1.0f16, 0.0f16, 1.0f16));
  ASSERT_EQ(HalfVector4(Color::Blue()),
            HalfVector4(0.0f16, 0.0f16, 1.0f16, 1.0f16));
  ASSERT_EQ(HalfVector4(Color::Black().WithAlpha(0)),
            HalfVector4(0.0f16, 0.0f16, 0.0f16, 0.0f16));

  ASSERT_EQ(HalfVector3(Vector3(4.0, 6.0, -1.0)),
            HalfVector3(4.0f16, 6.0f16, -1.0f16));
  ASSERT_EQ(HalfVector2(Vector2(4.0, 6.0)), HalfVector2(4.0f16, 6.0f16));

  ASSERT_EQ(Half(0.5f), Half(0.5f16));
  ASSERT_EQ(Half(0.5), Half(0.5f16));
  ASSERT_EQ(Half(5), Half(5.0f16));
#endif  // FML_OS_WIN
}

TEST(GeometryTest, PathShifting) {
  PathBuilder builder{};
  auto path =
      builder.AddLine(Point(0, 0), Point(10, 10))
          .AddQuadraticCurve(Point(10, 10), Point(15, 15), Point(20, 20))
          .AddCubicCurve(Point(20, 20), Point(25, 25), Point(-5, -5),
                         Point(30, 30))
          .Close()
          .Shift(Point(1, 1))
          .TakePath();

  ContourComponent contour;
  LinearPathComponent linear;
  QuadraticPathComponent quad;
  CubicPathComponent cubic;

  ASSERT_TRUE(path.GetContourComponentAtIndex(0, contour));
  ASSERT_TRUE(path.GetLinearComponentAtIndex(1, linear));
  ASSERT_TRUE(path.GetQuadraticComponentAtIndex(3, quad));
  ASSERT_TRUE(path.GetCubicComponentAtIndex(5, cubic));

  ASSERT_EQ(contour.destination, Point(1, 1));

  ASSERT_EQ(linear.p1, Point(1, 1));
  ASSERT_EQ(linear.p2, Point(11, 11));

  ASSERT_EQ(quad.cp, Point(16, 16));
  ASSERT_EQ(quad.p1, Point(11, 11));
  ASSERT_EQ(quad.p2, Point(21, 21));

  ASSERT_EQ(cubic.cp1, Point(26, 26));
  ASSERT_EQ(cubic.cp2, Point(-4, -4));
  ASSERT_EQ(cubic.p1, Point(21, 21));
  ASSERT_EQ(cubic.p2, Point(31, 31));
}

TEST(GeometryTest, PathBuilderWillComputeBounds) {
  PathBuilder builder;
  auto path_1 = builder.AddLine({0, 0}, {1, 1}).TakePath();

  ASSERT_EQ(path_1.GetBoundingBox().value(), Rect::MakeLTRB(0, 0, 1, 1));

  auto path_2 = builder.AddLine({-1, -1}, {1, 1}).TakePath();

  // Verify that PathBuilder recomputes the bounds.
  ASSERT_EQ(path_2.GetBoundingBox().value(), Rect::MakeLTRB(-1, -1, 1, 1));

  // PathBuilder can set the bounds to whatever it wants
  auto path_3 = builder.AddLine({0, 0}, {1, 1})
                    .SetBounds(Rect::MakeLTRB(0, 0, 100, 100))
                    .TakePath();

  ASSERT_EQ(path_3.GetBoundingBox().value(), Rect::MakeLTRB(0, 0, 100, 100));
}

}  // namespace testing
}  // namespace impeller

// NOLINTEND(bugprone-unchecked-optional-access)

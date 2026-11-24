// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "gtest/gtest.h"

#include "flutter/impeller/geometry/wangs_formula.h"

namespace impeller {
namespace testing {

TEST(WangsFormulaTest, Cubic) {
  Point p0{300, 0};
  Point p1{0, 0};
  Point p2{0, 0};
  Point p3{0, 300};
  Scalar result = ComputeCubicSubdivisions(1.0, p0, p1, p2, p3);
  EXPECT_FLOAT_EQ(result, 30.f);
}

TEST(WangsFormulaTest, Quadratic) {
  Point p0{15, 0};
  Point p1{0, 0};
  Point p2{0, 20};
  Scalar result = ComputeQuadradicSubdivisions(1.0, p0, p1, p2);
  EXPECT_FLOAT_EQ(result, 5.f);
}

// Coordinates large enough that squared lengths overflow a float used to
// produce an infinite count, which hung the tessellators.
TEST(WangsFormulaTest, HugeCoordinatesAreClamped) {
  Point p0{-1.37565448e+21, 2.70277973e+20};
  Point p1{-1.37565448e+21, -7.48722031e+20};
  Point p2{-3.56654515e+20, -7.48722031e+20};
  Point p3{6.62345453e+20, -7.48722031e+20};

  EXPECT_EQ(ComputeConicSubdivisions(1.0f, p0, p1, p2, kSqrt2Over2),
            kMaxCurveSubdivisions);
  EXPECT_EQ(ComputeConicSubdivisions(1.0f, p0, p1, p2, 1.0f),
            kMaxCurveSubdivisions);
  EXPECT_EQ(ComputeQuadradicSubdivisions(1.0f, p0, p1, p2),
            kMaxCurveSubdivisions);
  EXPECT_EQ(ComputeCubicSubdivisions(1.0f, p0, p1, p2, p3),
            kMaxCurveSubdivisions);
}

// Large but finite coordinates that don't overflow still asked for an
// unbounded number of segments.
TEST(WangsFormulaTest, LargeCoordinatesAreClamped) {
  Point p0{1e12, 0};
  Point p1{1e12, 1e12};
  Point p2{0, 1e12};
  Point p3{0, 0};

  EXPECT_EQ(ComputeConicSubdivisions(1.0f, p0, p1, p2, kSqrt2Over2),
            kMaxCurveSubdivisions);
  EXPECT_EQ(ComputeQuadradicSubdivisions(1.0f, p0, p1, p2),
            kMaxCurveSubdivisions);
  EXPECT_EQ(ComputeCubicSubdivisions(1.0f, p0, p1, p2, p3),
            kMaxCurveSubdivisions);
}

TEST(WangsFormulaTest, NonFiniteInputsAreClamped) {
  constexpr Scalar kInf = std::numeric_limits<Scalar>::infinity();
  constexpr Scalar kNaN = std::numeric_limits<Scalar>::quiet_NaN();
  Point p1{0, 0};
  Point p2{10, 10};

  for (Point p0 : {Point{kInf, 0}, Point{0, -kInf}, Point{kNaN, 0}}) {
    EXPECT_EQ(ComputeConicSubdivisions(1.0f, p0, p1, p2, kSqrt2Over2),
              kMaxCurveSubdivisions);
    EXPECT_EQ(ComputeQuadradicSubdivisions(1.0f, p0, p1, p2),
              kMaxCurveSubdivisions);
    EXPECT_EQ(ComputeCubicSubdivisions(1.0f, p0, p1, p2, p2),
              kMaxCurveSubdivisions);
  }
}

}  // namespace testing
}  // namespace impeller

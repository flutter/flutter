// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

}  // namespace testing
}  // namespace impeller

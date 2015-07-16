// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/cubic_bezier.h"

#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gfx {
namespace {

TEST(CubicBezierTest, Basic) {
  CubicBezier function(0.25, 0.0, 0.75, 1.0);

  double epsilon = 0.00015;

  EXPECT_NEAR(function.Solve(0), 0, epsilon);
  EXPECT_NEAR(function.Solve(0.05), 0.01136, epsilon);
  EXPECT_NEAR(function.Solve(0.1), 0.03978, epsilon);
  EXPECT_NEAR(function.Solve(0.15), 0.079780, epsilon);
  EXPECT_NEAR(function.Solve(0.2), 0.12803, epsilon);
  EXPECT_NEAR(function.Solve(0.25), 0.18235, epsilon);
  EXPECT_NEAR(function.Solve(0.3), 0.24115, epsilon);
  EXPECT_NEAR(function.Solve(0.35), 0.30323, epsilon);
  EXPECT_NEAR(function.Solve(0.4), 0.36761, epsilon);
  EXPECT_NEAR(function.Solve(0.45), 0.43345, epsilon);
  EXPECT_NEAR(function.Solve(0.5), 0.5, epsilon);
  EXPECT_NEAR(function.Solve(0.6), 0.63238, epsilon);
  EXPECT_NEAR(function.Solve(0.65), 0.69676, epsilon);
  EXPECT_NEAR(function.Solve(0.7), 0.75884, epsilon);
  EXPECT_NEAR(function.Solve(0.75), 0.81764, epsilon);
  EXPECT_NEAR(function.Solve(0.8), 0.87196, epsilon);
  EXPECT_NEAR(function.Solve(0.85), 0.92021, epsilon);
  EXPECT_NEAR(function.Solve(0.9), 0.96021, epsilon);
  EXPECT_NEAR(function.Solve(0.95), 0.98863, epsilon);
  EXPECT_NEAR(function.Solve(1), 1, epsilon);
}

// Tests that solving the bezier works with knots with y not in (0, 1).
TEST(CubicBezierTest, UnclampedYValues) {
  CubicBezier function(0.5, -1.0, 0.5, 2.0);

  double epsilon = 0.00015;

  EXPECT_NEAR(function.Solve(0.0), 0.0, epsilon);
  EXPECT_NEAR(function.Solve(0.05), -0.08954, epsilon);
  EXPECT_NEAR(function.Solve(0.1), -0.15613, epsilon);
  EXPECT_NEAR(function.Solve(0.15), -0.19641, epsilon);
  EXPECT_NEAR(function.Solve(0.2), -0.20651, epsilon);
  EXPECT_NEAR(function.Solve(0.25), -0.18232, epsilon);
  EXPECT_NEAR(function.Solve(0.3), -0.11992, epsilon);
  EXPECT_NEAR(function.Solve(0.35), -0.01672, epsilon);
  EXPECT_NEAR(function.Solve(0.4), 0.12660, epsilon);
  EXPECT_NEAR(function.Solve(0.45), 0.30349, epsilon);
  EXPECT_NEAR(function.Solve(0.5), 0.50000, epsilon);
  EXPECT_NEAR(function.Solve(0.55), 0.69651, epsilon);
  EXPECT_NEAR(function.Solve(0.6), 0.87340, epsilon);
  EXPECT_NEAR(function.Solve(0.65), 1.01672, epsilon);
  EXPECT_NEAR(function.Solve(0.7), 1.11992, epsilon);
  EXPECT_NEAR(function.Solve(0.75), 1.18232, epsilon);
  EXPECT_NEAR(function.Solve(0.8), 1.20651, epsilon);
  EXPECT_NEAR(function.Solve(0.85), 1.19641, epsilon);
  EXPECT_NEAR(function.Solve(0.9), 1.15613, epsilon);
  EXPECT_NEAR(function.Solve(0.95), 1.08954, epsilon);
  EXPECT_NEAR(function.Solve(1.0), 1.0, epsilon);
}

TEST(CubicBezierTest, Range) {
  double epsilon = 0.00015;
  double min, max;

  // Derivative is a constant.
  scoped_ptr<CubicBezier> function(
      new CubicBezier(0.25, (1.0 / 3.0), 0.75, (2.0 / 3.0)));
  function->Range(&min, &max);
  EXPECT_EQ(0, min);
  EXPECT_EQ(1, max);

  // Derivative is linear.
  function.reset(new CubicBezier(0.25, -0.5, 0.75, (-1.0 / 6.0)));
  function->Range(&min, &max);
  EXPECT_NEAR(min, -0.225, epsilon);
  EXPECT_EQ(1, max);

  // Derivative has no real roots.
  function.reset(new CubicBezier(0.25, 0.25, 0.75, 0.5));
  function->Range(&min, &max);
  EXPECT_EQ(0, min);
  EXPECT_EQ(1, max);

  // Derivative has exactly one real root.
  function.reset(new CubicBezier(0.0, 1.0, 1.0, 0.0));
  function->Range(&min, &max);
  EXPECT_EQ(0, min);
  EXPECT_EQ(1, max);

  // Derivative has one root < 0 and one root > 1.
  function.reset(new CubicBezier(0.25, 0.1, 0.75, 0.9));
  function->Range(&min, &max);
  EXPECT_EQ(0, min);
  EXPECT_EQ(1, max);

  // Derivative has two roots in [0,1].
  function.reset(new CubicBezier(0.25, 2.5, 0.75, 0.5));
  function->Range(&min, &max);
  EXPECT_EQ(0, min);
  EXPECT_NEAR(max, 1.28818, epsilon);
  function.reset(new CubicBezier(0.25, 0.5, 0.75, -1.5));
  function->Range(&min, &max);
  EXPECT_NEAR(min, -0.28818, epsilon);
  EXPECT_EQ(1, max);

  // Derivative has one root < 0 and one root in [0,1].
  function.reset(new CubicBezier(0.25, 0.1, 0.75, 1.5));
  function->Range(&min, &max);
  EXPECT_EQ(0, min);
  EXPECT_NEAR(max, 1.10755, epsilon);

  // Derivative has one root in [0,1] and one root > 1.
  function.reset(new CubicBezier(0.25, -0.5, 0.75, 0.9));
  function->Range(&min, &max);
  EXPECT_NEAR(min, -0.10755, epsilon);
  EXPECT_EQ(1, max);

  // Derivative has two roots < 0.
  function.reset(new CubicBezier(0.25, 0.3, 0.75, 0.633));
  function->Range(&min, &max);
  EXPECT_EQ(0, min);
  EXPECT_EQ(1, max);

  // Derivative has two roots > 1.
  function.reset(new CubicBezier(0.25, 0.367, 0.75, 0.7));
  function->Range(&min, &max);
  EXPECT_EQ(0.f, min);
  EXPECT_EQ(1.f, max);
}

TEST(CubicBezierTest, Slope) {
  CubicBezier function(0.25, 0.0, 0.75, 1.0);

  double epsilon = 0.00015;

  EXPECT_NEAR(function.Slope(0), 0, epsilon);
  EXPECT_NEAR(function.Slope(0.05), 0.42170, epsilon);
  EXPECT_NEAR(function.Slope(0.1), 0.69778, epsilon);
  EXPECT_NEAR(function.Slope(0.15), 0.89121, epsilon);
  EXPECT_NEAR(function.Slope(0.2), 1.03184, epsilon);
  EXPECT_NEAR(function.Slope(0.25), 1.13576, epsilon);
  EXPECT_NEAR(function.Slope(0.3), 1.21239, epsilon);
  EXPECT_NEAR(function.Slope(0.35), 1.26751, epsilon);
  EXPECT_NEAR(function.Slope(0.4), 1.30474, epsilon);
  EXPECT_NEAR(function.Slope(0.45), 1.32628, epsilon);
  EXPECT_NEAR(function.Slope(0.5), 1.33333, epsilon);
  EXPECT_NEAR(function.Slope(0.55), 1.32628, epsilon);
  EXPECT_NEAR(function.Slope(0.6), 1.30474, epsilon);
  EXPECT_NEAR(function.Slope(0.65), 1.26751, epsilon);
  EXPECT_NEAR(function.Slope(0.7), 1.21239, epsilon);
  EXPECT_NEAR(function.Slope(0.75), 1.13576, epsilon);
  EXPECT_NEAR(function.Slope(0.8), 1.03184, epsilon);
  EXPECT_NEAR(function.Slope(0.85), 0.89121, epsilon);
  EXPECT_NEAR(function.Slope(0.9), 0.69778, epsilon);
  EXPECT_NEAR(function.Slope(0.95), 0.42170, epsilon);
  EXPECT_NEAR(function.Slope(1), 0, epsilon);
}

}  // namespace
}  // namespace gfx

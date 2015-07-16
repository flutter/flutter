// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/animation/tween.h"

#include <math.h>

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/test/gfx_util.h"

namespace gfx {
namespace {

double next_double(double d) {
  // Step two units of least precision towards positive infinity. On some 32
  // bit x86 compilers a single step was not enough due to loss of precision in
  // optimized code.
  return nextafter(nextafter(d, d + 1), d + 1);
}

// Validates that the same interpolations are made as in Blink.
TEST(TweenTest, ColorValueBetween) {
  // From blink's AnimatableColorTest.
  EXPECT_SKCOLOR_EQ(0xFF00FF00,
                  Tween::ColorValueBetween(-10.0, 0xFF00FF00, 0xFF00FF00));
  EXPECT_SKCOLOR_EQ(0xFF00FF00,
                  Tween::ColorValueBetween(-10.0, 0xFF00FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(0xFF00FF00,
                  Tween::ColorValueBetween(0.0, 0xFF00FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(0xFF01FE01,
                  Tween::ColorValueBetween(1.0 / 255, 0xFF00FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(0xFF808080,
                  Tween::ColorValueBetween(0.5, 0xFF00FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(
      0xFFFE01FE,
      Tween::ColorValueBetween(254.0 / 255.0, 0xFF00FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(0xFFFF00FF,
                  Tween::ColorValueBetween(1.0, 0xFF00FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(0xFFFF00FF,
                  Tween::ColorValueBetween(10.0, 0xFF00FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(0xFF0C253E,
                  Tween::ColorValueBetween(3.0 / 16.0, 0xFF001020, 0xFF4080C0));
  EXPECT_SKCOLOR_EQ(0x80FF00FF,
                  Tween::ColorValueBetween(0.5, 0x0000FF00, 0xFFFF00FF));
  EXPECT_SKCOLOR_EQ(0x60AA55AA,
                  Tween::ColorValueBetween(0.5, 0x4000FF00, 0x80FF00FF));
  EXPECT_SKCOLOR_EQ(0x60FFAAFF,
                  Tween::ColorValueBetween(0.5, 0x40FF00FF, 0x80FFFFFF));
  EXPECT_SKCOLOR_EQ(0x103060A0,
                  Tween::ColorValueBetween(0.5, 0x10204080, 0x104080C0));
}

// Ensures that each of the 3 integers in [0, 1, 2] ae selected with equal
// weight.
TEST(TweenTest, IntValueBetween) {
  EXPECT_EQ(0, Tween::IntValueBetween(0.0, 0, 2));
  EXPECT_EQ(0, Tween::IntValueBetween(0.5 / 3.0, 0, 2));
  EXPECT_EQ(0, Tween::IntValueBetween(1.0 / 3.0, 0, 2));

  EXPECT_EQ(1, Tween::IntValueBetween(next_double(1.0 / 3.0), 0, 2));
  EXPECT_EQ(1, Tween::IntValueBetween(1.5 / 3.0, 0, 2));
  EXPECT_EQ(1, Tween::IntValueBetween(2.0 / 3.0, 0, 2));

  EXPECT_EQ(2, Tween::IntValueBetween(next_double(2.0 / 3.0), 0, 2));
  EXPECT_EQ(2, Tween::IntValueBetween(2.5 / 3.0, 0, 2));
  EXPECT_EQ(2, Tween::IntValueBetween(3.0 / 3.0, 0, 2));
}

TEST(TweenTest, IntValueBetweenNegative) {
  EXPECT_EQ(-2, Tween::IntValueBetween(0.0, -2, 0));
  EXPECT_EQ(-2, Tween::IntValueBetween(0.5 / 3.0, -2, 0));
  EXPECT_EQ(-2, Tween::IntValueBetween(1.0 / 3.0, -2, 0));

  EXPECT_EQ(-1, Tween::IntValueBetween(next_double(1.0 / 3.0), -2, 0));
  EXPECT_EQ(-1, Tween::IntValueBetween(1.5 / 3.0, -2, 0));
  EXPECT_EQ(-1, Tween::IntValueBetween(2.0 / 3.0, -2, 0));

  EXPECT_EQ(0, Tween::IntValueBetween(next_double(2.0 / 3.0), -2, 0));
  EXPECT_EQ(0, Tween::IntValueBetween(2.5 / 3.0, -2, 0));
  EXPECT_EQ(0, Tween::IntValueBetween(3.0 / 3.0, -2, 0));
}

TEST(TweenTest, IntValueBetweenReverse) {
  EXPECT_EQ(2, Tween::IntValueBetween(0.0, 2, 0));
  EXPECT_EQ(2, Tween::IntValueBetween(0.5 / 3.0, 2, 0));
  EXPECT_EQ(2, Tween::IntValueBetween(1.0 / 3.0, 2, 0));

  EXPECT_EQ(1, Tween::IntValueBetween(next_double(1.0 / 3.0), 2, 0));
  EXPECT_EQ(1, Tween::IntValueBetween(1.5 / 3.0, 2, 0));
  EXPECT_EQ(1, Tween::IntValueBetween(2.0 / 3.0, 2, 0));

  EXPECT_EQ(0, Tween::IntValueBetween(next_double(2.0 / 3.0), 2, 0));
  EXPECT_EQ(0, Tween::IntValueBetween(2.5 / 3.0, 2, 0));
  EXPECT_EQ(0, Tween::IntValueBetween(3.0 / 3.0, 2, 0));
}

TEST(TweenTest, LinearIntValueBetween) {
  EXPECT_EQ(0, Tween::LinearIntValueBetween(0.0, 0, 2));
  EXPECT_EQ(0, Tween::LinearIntValueBetween(0.5 / 4.0, 0, 2));
  EXPECT_EQ(0, Tween::LinearIntValueBetween(0.99 / 4.0, 0, 2));

  EXPECT_EQ(1, Tween::LinearIntValueBetween(1.0 / 4.0, 0, 2));
  EXPECT_EQ(1, Tween::LinearIntValueBetween(1.5 / 4.0, 0, 2));
  EXPECT_EQ(1, Tween::LinearIntValueBetween(2.0 / 4.0, 0, 2));
  EXPECT_EQ(1, Tween::LinearIntValueBetween(2.5 / 4.0, 0, 2));
  EXPECT_EQ(1, Tween::LinearIntValueBetween(2.99 / 4.0, 0, 2));

  EXPECT_EQ(2, Tween::LinearIntValueBetween(3.0 / 4.0, 0, 2));
  EXPECT_EQ(2, Tween::LinearIntValueBetween(3.5 / 4.0, 0, 2));
  EXPECT_EQ(2, Tween::LinearIntValueBetween(4.0 / 4.0, 0, 2));
}

TEST(TweenTest, LinearIntValueBetweenNegative) {
  EXPECT_EQ(-2, Tween::LinearIntValueBetween(0.0, -2, 0));
  EXPECT_EQ(-2, Tween::LinearIntValueBetween(0.5 / 4.0, -2, 0));
  EXPECT_EQ(-2, Tween::LinearIntValueBetween(0.99 / 4.0, -2, 0));

  EXPECT_EQ(-1, Tween::LinearIntValueBetween(1.0 / 4.0, -2, 0));
  EXPECT_EQ(-1, Tween::LinearIntValueBetween(1.5 / 4.0, -2, 0));
  EXPECT_EQ(-1, Tween::LinearIntValueBetween(2.0 / 4.0, -2, 0));
  EXPECT_EQ(-1, Tween::LinearIntValueBetween(2.5 / 4.0, -2, 0));
  EXPECT_EQ(-1, Tween::LinearIntValueBetween(2.99 / 4.0, -2, 0));

  EXPECT_EQ(0, Tween::LinearIntValueBetween(3.0 / 4.0, -2, 0));
  EXPECT_EQ(0, Tween::LinearIntValueBetween(3.5 / 4.0, -2, 0));
  EXPECT_EQ(0, Tween::LinearIntValueBetween(4.0 / 4.0, -2, 0));
}

}  // namespace
}  // namespace gfx

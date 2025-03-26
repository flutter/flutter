// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/rational.h"

#include "gtest/gtest.h"

namespace impeller {

TEST(RationalTest, Make) {
  Rational value(1, 2);
  EXPECT_EQ(value.GetNumerator(), 1);
  EXPECT_EQ(value.GetDenominator(), 2u);
}

TEST(RationalTest, EqualsSameDen) {
  EXPECT_TRUE(Rational(1, 2) == Rational(1, 2));
}

TEST(RationalTest, NotEqualsSameDen) {
  EXPECT_FALSE(Rational(3, 2) == Rational(1, 2));
}

TEST(RationalTest, EqualsDifferentDen) {
  EXPECT_TRUE(Rational(1, 2) == Rational(2, 4));
}

TEST(RationalTest, NegationNotEquals) {
  EXPECT_FALSE(Rational(1, 2) == Rational(-1, 2));
}

TEST(RationalTest, LessThanSameDen) {
  EXPECT_TRUE(Rational(1, 2) < Rational(2, 2));
}

TEST(RationalTest, LessThanNegation) {
  EXPECT_TRUE(Rational(-1, 2) < Rational(2, 23));
}

TEST(RationalTest, LessThanDifferentDen) {
  EXPECT_TRUE(Rational(1, 2) < Rational(25, 23));
}

TEST(RationalTest, NotLessThanDifferentDen) {
  EXPECT_FALSE(Rational(25, 23) < Rational(1, 2));
}

TEST(RationalTest, SameHashes) {
  EXPECT_EQ(Rational(1, 2).GetHash(), Rational(2, 4).GetHash());
}

TEST(RationalTest, DifferentHashes) {
  EXPECT_NE(Rational(2, 2).GetHash(), Rational(2, 4).GetHash());
}

}  // namespace impeller

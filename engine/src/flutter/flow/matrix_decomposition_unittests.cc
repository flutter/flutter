// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/matrix_decomposition.h"

#include <cmath>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(MatrixDecomposition, Rotation) {
  SkM44 matrix;

  const auto angle = M_PI_4;
  matrix.setRotate({0.0, 0.0, 1.0}, angle);

  flutter::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  const auto sine = sin(angle * 0.5);

  ASSERT_FLOAT_EQ(0, decomposition.rotation().x);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().y);
  ASSERT_FLOAT_EQ(sine, decomposition.rotation().z);
  ASSERT_FLOAT_EQ(cos(angle * 0.5), decomposition.rotation().w);
}

TEST(MatrixDecomposition, Scale) {
  SkM44 matrix;

  const auto scale = 5.0;
  matrix.setScale(scale + 0, scale + 1, scale + 2);

  flutter::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  ASSERT_FLOAT_EQ(scale + 0, decomposition.scale().x);
  ASSERT_FLOAT_EQ(scale + 1, decomposition.scale().y);
  ASSERT_FLOAT_EQ(scale + 2, decomposition.scale().z);
}

TEST(MatrixDecomposition, Translate) {
  SkM44 matrix;

  const auto translate = 125.0;
  matrix.setTranslate(translate + 0, translate + 1, translate + 2);

  flutter::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  ASSERT_FLOAT_EQ(translate + 0, decomposition.translation().x);
  ASSERT_FLOAT_EQ(translate + 1, decomposition.translation().y);
  ASSERT_FLOAT_EQ(translate + 2, decomposition.translation().z);
}

TEST(MatrixDecomposition, Combination) {
  const auto rotation = M_PI_4;
  const auto scale = 5;
  const auto translate = 125.0;

  SkM44 m1;
  m1.setRotate({0, 0, 1}, rotation);

  SkM44 m2;
  m2.setScale(scale, scale, scale);

  SkM44 m3;
  m3.setTranslate(translate, translate, translate);

  SkM44 combined = m3 * m2 * m1;

  flutter::MatrixDecomposition decomposition(combined);
  ASSERT_TRUE(decomposition.IsValid());

  ASSERT_FLOAT_EQ(translate, decomposition.translation().x);
  ASSERT_FLOAT_EQ(translate, decomposition.translation().y);
  ASSERT_FLOAT_EQ(translate, decomposition.translation().z);

  ASSERT_FLOAT_EQ(scale, decomposition.scale().x);
  ASSERT_FLOAT_EQ(scale, decomposition.scale().y);
  ASSERT_FLOAT_EQ(scale, decomposition.scale().z);

  const auto sine = sin(rotation * 0.5);

  ASSERT_FLOAT_EQ(0, decomposition.rotation().x);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().y);
  ASSERT_FLOAT_EQ(sine, decomposition.rotation().z);
  ASSERT_FLOAT_EQ(cos(rotation * 0.5), decomposition.rotation().w);
}

TEST(MatrixDecomposition, ScaleFloatError) {
  constexpr float scale_increment = 0.00001f;
  float scale = 0.0001f;
  while (scale < 2.0f) {
    SkM44 matrix;
    matrix.setScale(scale, scale, 1.0f);

    flutter::MatrixDecomposition decomposition3(matrix);
    ASSERT_TRUE(decomposition3.IsValid());

    ASSERT_FLOAT_EQ(scale, decomposition3.scale().x);
    ASSERT_FLOAT_EQ(scale, decomposition3.scale().y);
    ASSERT_FLOAT_EQ(1.f, decomposition3.scale().z);
    ASSERT_FLOAT_EQ(0, decomposition3.rotation().x);
    ASSERT_FLOAT_EQ(0, decomposition3.rotation().y);
    ASSERT_FLOAT_EQ(0, decomposition3.rotation().z);
    scale += scale_increment;
  }

  SkM44 matrix;
  const auto scale1 = 1.7734375f;
  matrix.setScale(scale1, scale1, 1.f);

  // Bug upper bound (empirical)
  const auto scale2 = 1.773437559603f;
  SkM44 matrix2;
  matrix2.setScale(scale2, scale2, 1.f);

  // Bug lower bound (empirical)
  const auto scale3 = 1.7734374403954f;
  SkM44 matrix3;
  matrix3.setScale(scale3, scale3, 1.f);

  flutter::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  flutter::MatrixDecomposition decomposition2(matrix2);
  ASSERT_TRUE(decomposition2.IsValid());

  flutter::MatrixDecomposition decomposition3(matrix3);
  ASSERT_TRUE(decomposition3.IsValid());

  ASSERT_FLOAT_EQ(scale1, decomposition.scale().x);
  ASSERT_FLOAT_EQ(scale1, decomposition.scale().y);
  ASSERT_FLOAT_EQ(1.f, decomposition.scale().z);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().x);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().y);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().z);

  ASSERT_FLOAT_EQ(scale2, decomposition2.scale().x);
  ASSERT_FLOAT_EQ(scale2, decomposition2.scale().y);
  ASSERT_FLOAT_EQ(1.f, decomposition2.scale().z);
  ASSERT_FLOAT_EQ(0, decomposition2.rotation().x);
  ASSERT_FLOAT_EQ(0, decomposition2.rotation().y);
  ASSERT_FLOAT_EQ(0, decomposition2.rotation().z);

  ASSERT_FLOAT_EQ(scale3, decomposition3.scale().x);
  ASSERT_FLOAT_EQ(scale3, decomposition3.scale().y);
  ASSERT_FLOAT_EQ(1.f, decomposition3.scale().z);
  ASSERT_FLOAT_EQ(0, decomposition3.rotation().x);
  ASSERT_FLOAT_EQ(0, decomposition3.rotation().y);
  ASSERT_FLOAT_EQ(0, decomposition3.rotation().z);
}

}  // namespace testing
}  // namespace flutter

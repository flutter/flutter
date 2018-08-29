// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/build_config.h"

#if defined(OS_WIN)
#define _USE_MATH_DEFINES
#endif
#include <cmath>

#include "flutter/flow/matrix_decomposition.h"
#include "gtest/gtest.h"

TEST(MatrixDecomposition, Rotation) {
  SkMatrix44 matrix = SkMatrix44::I();

  const auto angle = M_PI_4;
  matrix.setRotateAbout(0.0, 0.0, 1.0, angle);

  flow::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  const auto sine = sin(angle * 0.5);

  ASSERT_FLOAT_EQ(0, decomposition.rotation().fData[0]);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().fData[1]);
  ASSERT_FLOAT_EQ(sine, decomposition.rotation().fData[2]);
  ASSERT_FLOAT_EQ(cos(angle * 0.5), decomposition.rotation().fData[3]);
}

TEST(MatrixDecomposition, Scale) {
  SkMatrix44 matrix = SkMatrix44::I();

  const auto scale = 5.0;
  matrix.setScale(scale + 0, scale + 1, scale + 2);

  flow::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  ASSERT_FLOAT_EQ(scale + 0, decomposition.scale().fX);
  ASSERT_FLOAT_EQ(scale + 1, decomposition.scale().fY);
  ASSERT_FLOAT_EQ(scale + 2, decomposition.scale().fZ);
}

TEST(MatrixDecomposition, Translate) {
  SkMatrix44 matrix = SkMatrix44::I();

  const auto translate = 125.0;
  matrix.setTranslate(translate + 0, translate + 1, translate + 2);

  flow::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  ASSERT_FLOAT_EQ(translate + 0, decomposition.translation().fX);
  ASSERT_FLOAT_EQ(translate + 1, decomposition.translation().fY);
  ASSERT_FLOAT_EQ(translate + 2, decomposition.translation().fZ);
}

TEST(MatrixDecomposition, Combination) {
  SkMatrix44 matrix = SkMatrix44::I();

  const auto rotation = M_PI_4;
  const auto scale = 5;
  const auto translate = 125.0;

  SkMatrix44 m1 = SkMatrix44::I();
  m1.setRotateAbout(0, 0, 1, rotation);

  SkMatrix44 m2 = SkMatrix44::I();
  m2.setScale(scale);

  SkMatrix44 m3 = SkMatrix44::I();
  m3.setTranslate(translate, translate, translate);

  SkMatrix44 combined = m3 * m2 * m1;

  flow::MatrixDecomposition decomposition(combined);
  ASSERT_TRUE(decomposition.IsValid());

  ASSERT_FLOAT_EQ(translate, decomposition.translation().fX);
  ASSERT_FLOAT_EQ(translate, decomposition.translation().fY);
  ASSERT_FLOAT_EQ(translate, decomposition.translation().fZ);

  ASSERT_FLOAT_EQ(scale, decomposition.scale().fX);
  ASSERT_FLOAT_EQ(scale, decomposition.scale().fY);
  ASSERT_FLOAT_EQ(scale, decomposition.scale().fZ);

  const auto sine = sin(rotation * 0.5);

  ASSERT_FLOAT_EQ(0, decomposition.rotation().fData[0]);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().fData[1]);
  ASSERT_FLOAT_EQ(sine, decomposition.rotation().fData[2]);
  ASSERT_FLOAT_EQ(cos(rotation * 0.5), decomposition.rotation().fData[3]);
}

TEST(MatrixDecomposition, ScaleFloatError) {
  for (float scale = 0.0001f; scale < 2.0f; scale += 0.000001f) {
    SkMatrix44 matrix = SkMatrix44::I();
    matrix.setScale(scale, scale, 1.0f);

    flow::MatrixDecomposition decomposition3(matrix);
    ASSERT_TRUE(decomposition3.IsValid());

    ASSERT_FLOAT_EQ(scale, decomposition3.scale().fX);
    ASSERT_FLOAT_EQ(scale, decomposition3.scale().fY);
    ASSERT_FLOAT_EQ(1.f, decomposition3.scale().fZ);
    ASSERT_FLOAT_EQ(0, decomposition3.rotation().fData[0]);
    ASSERT_FLOAT_EQ(0, decomposition3.rotation().fData[1]);
    ASSERT_FLOAT_EQ(0, decomposition3.rotation().fData[2]);
  }

  SkMatrix44 matrix = SkMatrix44::I();
  const auto scale = 1.7734375f;
  matrix.setScale(scale, scale, 1.f);

  // Bug upper bound (empirical)
  const auto scale2 = 1.773437559603f;
  SkMatrix44 matrix2 = SkMatrix44::I();
  matrix2.setScale(scale2, scale2, 1.f);

  // Bug lower bound (empirical)
  const auto scale3 = 1.7734374403954f;
  SkMatrix44 matrix3 = SkMatrix44::I();
  matrix3.setScale(scale3, scale3, 1.f);

  flow::MatrixDecomposition decomposition(matrix);
  ASSERT_TRUE(decomposition.IsValid());

  flow::MatrixDecomposition decomposition2(matrix2);
  ASSERT_TRUE(decomposition2.IsValid());

  flow::MatrixDecomposition decomposition3(matrix3);
  ASSERT_TRUE(decomposition3.IsValid());

  ASSERT_FLOAT_EQ(scale, decomposition.scale().fX);
  ASSERT_FLOAT_EQ(scale, decomposition.scale().fY);
  ASSERT_FLOAT_EQ(1.f, decomposition.scale().fZ);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().fData[0]);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().fData[1]);
  ASSERT_FLOAT_EQ(0, decomposition.rotation().fData[2]);

  ASSERT_FLOAT_EQ(scale2, decomposition2.scale().fX);
  ASSERT_FLOAT_EQ(scale2, decomposition2.scale().fY);
  ASSERT_FLOAT_EQ(1.f, decomposition2.scale().fZ);
  ASSERT_FLOAT_EQ(0, decomposition2.rotation().fData[0]);
  ASSERT_FLOAT_EQ(0, decomposition2.rotation().fData[1]);
  ASSERT_FLOAT_EQ(0, decomposition2.rotation().fData[2]);

  ASSERT_FLOAT_EQ(scale3, decomposition3.scale().fX);
  ASSERT_FLOAT_EQ(scale3, decomposition3.scale().fY);
  ASSERT_FLOAT_EQ(1.f, decomposition3.scale().fZ);
  ASSERT_FLOAT_EQ(0, decomposition3.rotation().fData[0]);
  ASSERT_FLOAT_EQ(0, decomposition3.rotation().fData[1]);
  ASSERT_FLOAT_EQ(0, decomposition3.rotation().fData[2]);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/matrix_decomposition.h"

namespace flutter {

static inline SkV3 SkV3Combine(const SkV3& a,
                               float a_scale,
                               const SkV3& b,
                               float b_scale) {
  return (a * a_scale) + (b * b_scale);
}

MatrixDecomposition::MatrixDecomposition(const SkMatrix& matrix)
    : MatrixDecomposition(SkM44{matrix}) {}

// Use custom normalize to avoid skia precision loss/normalize() privatization.
static inline void SkV3Normalize(SkV3* v) {
  double mag = sqrt(v->x * v->x + v->y * v->y + v->z * v->z);
  double scale = 1.0 / mag;
  v->x *= scale;
  v->y *= scale;
  v->z *= scale;
}

MatrixDecomposition::MatrixDecomposition(SkM44 matrix) : valid_(false) {
  if (matrix.rc(3, 3) == 0) {
    return;
  }

  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      matrix.setRC(j, i, matrix.rc(j, i) / matrix.rc(3, 3));
    }
  }

  SkM44 perpective_matrix = matrix;
  for (int i = 0; i < 3; i++) {
    perpective_matrix.setRC(3, i, 0.0);
  }

  perpective_matrix.setRC(3, 3, 1.0);

  SkM44 inverted(SkM44::Uninitialized_Constructor::kUninitialized_Constructor);
  if (!perpective_matrix.invert(&inverted)) {
    return;
  }

  if (matrix.rc(3, 0) != 0.0 || matrix.rc(3, 1) != 0.0 ||
      matrix.rc(3, 2) != 0.0) {
    const SkV4 right_hand_side = matrix.row(3);

    perspective_ = inverted.transpose() * right_hand_side;

    matrix.setRow(3, {0, 0, 0, 1});
  }

  translation_ = {matrix.rc(0, 3), matrix.rc(1, 3), matrix.rc(2, 3)};

  matrix.setRC(0, 3, 0.0);
  matrix.setRC(1, 3, 0.0);
  matrix.setRC(2, 3, 0.0);

  SkV3 row[3];
  for (int i = 0; i < 3; i++) {
    row[i] = {matrix.rc(0, i), matrix.rc(1, i), matrix.rc(2, i)};
  }

  scale_.x = row[0].length();

  SkV3Normalize(&row[0]);

  shear_.x = row[0].dot(row[1]);
  row[1] = SkV3Combine(row[1], 1.0, row[0], -shear_.x);

  scale_.y = row[1].length();

  SkV3Normalize(&row[1]);

  shear_.x /= scale_.y;

  shear_.y = row[0].dot(row[2]);
  row[2] = SkV3Combine(row[2], 1.0, row[0], -shear_.y);
  shear_.z = row[1].dot(row[2]);
  row[2] = SkV3Combine(row[2], 1.0, row[1], -shear_.z);

  scale_.z = row[2].length();

  SkV3Normalize(&row[2]);

  shear_.y /= scale_.z;
  shear_.z /= scale_.z;

  if (row[0].dot(row[1].cross(row[2])) < 0) {
    scale_ *= -1;

    for (int i = 0; i < 3; i++) {
      row[i] *= -1;
    }
  }

  rotation_.x = 0.5 * sqrt(fmax(1.0 + row[0].x - row[1].y - row[2].z, 0.0));
  rotation_.y = 0.5 * sqrt(fmax(1.0 - row[0].x + row[1].y - row[2].z, 0.0));
  rotation_.z = 0.5 * sqrt(fmax(1.0 - row[0].x - row[1].y + row[2].z, 0.0));
  rotation_.w = 0.5 * sqrt(fmax(1.0 + row[0].x + row[1].y + row[2].z, 0.0));

  if (row[2].y > row[1].z) {
    rotation_.x = -rotation_.x;
  }
  if (row[0].z > row[2].x) {
    rotation_.y = -rotation_.y;
  }
  if (row[1].x > row[0].y) {
    rotation_.z = -rotation_.z;
  }

  valid_ = true;
}

MatrixDecomposition::~MatrixDecomposition() = default;

bool MatrixDecomposition::IsValid() const {
  return valid_;
}

}  // namespace flutter

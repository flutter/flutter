// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/matrix_decomposition.h"

namespace flow {

static inline SkVector3 SkVector3Combine(const SkVector3& a,
                                         float a_scale,
                                         const SkVector3& b,
                                         float b_scale) {
  return {
      a_scale * a.fX + b_scale * b.fX,  //
      a_scale * a.fY + b_scale * b.fY,  //
      a_scale * a.fZ + b_scale * b.fZ,  //
  };
}

static inline SkVector3 SkVector3Cross(const SkVector3& a, const SkVector3& b) {
  return {
      (a.fY * b.fZ) - (a.fZ * b.fY),  //
      (a.fZ * b.fX) - (a.fX * b.fZ),  //
      (a.fX * b.fY) - (a.fY * b.fX)   //
  };
}

MatrixDecomposition::MatrixDecomposition(const SkMatrix& matrix)
    : MatrixDecomposition(SkMatrix44{matrix}) {}

// TODO(garyq): use skia row[x].normalize() when skia fixes it
static inline void SkVector3Normalize(SkVector3& v) {
  float mag = sqrt(v.fX * v.fX + v.fY * v.fY + v.fZ * v.fZ);
  v.fX /= mag;
  v.fY /= mag;
  v.fZ /= mag;
}

MatrixDecomposition::MatrixDecomposition(SkMatrix44 matrix) : valid_(false) {
  if (matrix.get(3, 3) == 0) {
    return;
  }

  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      matrix.set(j, i, matrix.get(j, i) / matrix.get(3, 3));
    }
  }

  SkMatrix44 perpective_matrix = matrix;
  for (int i = 0; i < 3; i++) {
    perpective_matrix.set(3, i, 0.0);
  }

  perpective_matrix.set(3, 3, 1.0);

  if (perpective_matrix.determinant() == 0.0) {
    return;
  }

  if (matrix.get(3, 0) != 0.0 || matrix.get(3, 1) != 0.0 ||
      matrix.get(3, 2) != 0.0) {
    const SkVector4 right_hand_side(matrix.get(3, 0), matrix.get(3, 1),
                                    matrix.get(3, 2), matrix.get(3, 3));

    SkMatrix44 inverted_transposed(
        SkMatrix44::Uninitialized_Constructor::kUninitialized_Constructor);
    if (!perpective_matrix.invert(&inverted_transposed)) {
      return;
    }
    inverted_transposed.transpose();

    perspective_ = inverted_transposed * right_hand_side;

    matrix.set(3, 0, 0);
    matrix.set(3, 1, 0);
    matrix.set(3, 2, 0);
    matrix.set(3, 3, 1);
  }

  translation_ = {matrix.get(0, 3), matrix.get(1, 3), matrix.get(2, 3)};

  matrix.set(0, 3, 0.0);
  matrix.set(1, 3, 0.0);
  matrix.set(2, 3, 0.0);

  SkVector3 row[3];
  for (int i = 0; i < 3; i++) {
    row[i].set(matrix.get(0, i), matrix.get(1, i), matrix.get(2, i));
  }

  scale_.fX = row[0].length();

  SkVector3Normalize(row[0]);

  shear_.fX = row[0].dot(row[1]);
  row[1] = SkVector3Combine(row[1], 1.0, row[0], -shear_.fX);

  scale_.fY = row[1].length();

  SkVector3Normalize(row[1]);

  shear_.fX /= scale_.fY;

  shear_.fY = row[0].dot(row[2]);
  row[2] = SkVector3Combine(row[2], 1.0, row[0], -shear_.fY);
  shear_.fZ = row[1].dot(row[2]);
  row[2] = SkVector3Combine(row[2], 1.0, row[1], -shear_.fZ);

  scale_.fZ = row[2].length();

  SkVector3Normalize(row[2]);

  shear_.fY /= scale_.fZ;
  shear_.fZ /= scale_.fZ;

  if (row[0].dot(SkVector3Cross(row[1], row[2])) < 0) {
    scale_.fX *= -1;
    scale_.fY *= -1;
    scale_.fZ *= -1;

    for (int i = 0; i < 3; i++) {
      row[i].fX *= -1;
      row[i].fY *= -1;
      row[i].fZ *= -1;
    }
  }

  rotation_.set(0.5 * sqrt(fmax(1.0 + row[0].fX - row[1].fY - row[2].fZ, 0.0)),
                0.5 * sqrt(fmax(1.0 - row[0].fX + row[1].fY - row[2].fZ, 0.0)),
                0.5 * sqrt(fmax(1.0 - row[0].fX - row[1].fY + row[2].fZ, 0.0)),
                0.5 * sqrt(fmax(1.0 + row[0].fX + row[1].fY + row[2].fZ, 0.0)));

  if (row[2].fY > row[1].fZ) {
    rotation_.fData[0] = -rotation_.fData[0];
  }
  if (row[0].fZ > row[2].fX) {
    rotation_.fData[1] = -rotation_.fData[1];
  }
  if (row[1].fX > row[0].fY) {
    rotation_.fData[2] = -rotation_.fData[2];
  }

  valid_ = true;
}

MatrixDecomposition::~MatrixDecomposition() = default;

bool MatrixDecomposition::IsValid() const {
  return valid_;
}

}  // namespace flow

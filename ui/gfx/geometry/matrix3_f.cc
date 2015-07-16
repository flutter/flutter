// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/matrix3_f.h"

#include <algorithm>
#include <cmath>
#include <limits>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace {

// This is only to make accessing indices self-explanatory.
enum MatrixCoordinates {
  M00,
  M01,
  M02,
  M10,
  M11,
  M12,
  M20,
  M21,
  M22,
  M_END
};

template<typename T>
double Determinant3x3(T data[M_END]) {
  // This routine is separated from the Matrix3F::Determinant because in
  // computing inverse we do want higher precision afforded by the explicit
  // use of 'double'.
  return
      static_cast<double>(data[M00]) * (
          static_cast<double>(data[M11]) * data[M22] -
          static_cast<double>(data[M12]) * data[M21]) +
      static_cast<double>(data[M01]) * (
          static_cast<double>(data[M12]) * data[M20] -
          static_cast<double>(data[M10]) * data[M22]) +
      static_cast<double>(data[M02]) * (
          static_cast<double>(data[M10]) * data[M21] -
          static_cast<double>(data[M11]) * data[M20]);
}

}  // namespace

namespace gfx {

Matrix3F::Matrix3F() {
}

Matrix3F::~Matrix3F() {
}

// static
Matrix3F Matrix3F::Zeros() {
  Matrix3F matrix;
  matrix.set(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
  return matrix;
}

// static
Matrix3F Matrix3F::Ones() {
  Matrix3F matrix;
  matrix.set(1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f);
  return matrix;
}

// static
Matrix3F Matrix3F::Identity() {
  Matrix3F matrix;
  matrix.set(1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f);
  return matrix;
}

// static
Matrix3F Matrix3F::FromOuterProduct(const Vector3dF& a, const Vector3dF& bt) {
  Matrix3F matrix;
  matrix.set(a.x() * bt.x(), a.x() * bt.y(), a.x() * bt.z(),
             a.y() * bt.x(), a.y() * bt.y(), a.y() * bt.z(),
             a.z() * bt.x(), a.z() * bt.y(), a.z() * bt.z());
  return matrix;
}

bool Matrix3F::IsEqual(const Matrix3F& rhs) const {
  return 0 == memcmp(data_, rhs.data_, sizeof(data_));
}

bool Matrix3F::IsNear(const Matrix3F& rhs, float precision) const {
  DCHECK(precision >= 0);
  for (int i = 0; i < M_END; ++i) {
    if (std::abs(data_[i] - rhs.data_[i]) > precision)
      return false;
  }
  return true;
}

Matrix3F Matrix3F::Inverse() const {
  Matrix3F inverse = Matrix3F::Zeros();
  double determinant = Determinant3x3(data_);
  if (std::numeric_limits<float>::epsilon() > std::abs(determinant))
    return inverse;  // Singular matrix. Return Zeros().

  inverse.set(
      (data_[M11] * data_[M22] - data_[M12] * data_[M21]) / determinant,
      (data_[M02] * data_[M21] - data_[M01] * data_[M22]) / determinant,
      (data_[M01] * data_[M12] - data_[M02] * data_[M11]) / determinant,
      (data_[M12] * data_[M20] - data_[M10] * data_[M22]) / determinant,
      (data_[M00] * data_[M22] - data_[M02] * data_[M20]) / determinant,
      (data_[M02] * data_[M10] - data_[M00] * data_[M12]) / determinant,
      (data_[M10] * data_[M21] - data_[M11] * data_[M20]) / determinant,
      (data_[M01] * data_[M20] - data_[M00] * data_[M21]) / determinant,
      (data_[M00] * data_[M11] - data_[M01] * data_[M10]) / determinant);
  return inverse;
}

float Matrix3F::Determinant() const {
  return static_cast<float>(Determinant3x3(data_));
}

Vector3dF Matrix3F::SolveEigenproblem(Matrix3F* eigenvectors) const {
  // The matrix must be symmetric.
  const float epsilon = std::numeric_limits<float>::epsilon();
  if (std::abs(data_[M01] - data_[M10]) > epsilon ||
      std::abs(data_[M02] - data_[M20]) > epsilon ||
      std::abs(data_[M12] - data_[M21]) > epsilon) {
    NOTREACHED();
    return Vector3dF();
  }

  float eigenvalues[3];
  float p =
      data_[M01] * data_[M01] +
      data_[M02] * data_[M02] +
      data_[M12] * data_[M12];

  bool diagonal = std::abs(p) < epsilon;
  if (diagonal) {
    eigenvalues[0] = data_[M00];
    eigenvalues[1] = data_[M11];
    eigenvalues[2] = data_[M22];
  } else {
    float q = Trace() / 3.0f;
    p = (data_[M00] - q) * (data_[M00] - q) +
        (data_[M11] - q) * (data_[M11] - q) +
        (data_[M22] - q) * (data_[M22] - q) +
        2 * p;
    p = std::sqrt(p / 6);

    // The computation below puts B as (A - qI) / p, where A is *this.
    Matrix3F matrix_b(*this);
    matrix_b.data_[M00] -= q;
    matrix_b.data_[M11] -= q;
    matrix_b.data_[M22] -= q;
    for (int i = 0; i < M_END; ++i)
      matrix_b.data_[i] /= p;

    double half_det_b = Determinant3x3(matrix_b.data_) / 2.0;
    // half_det_b should be in <-1, 1>, but beware of rounding error.
    double phi = 0.0f;
    if (half_det_b <= -1.0)
      phi = M_PI / 3;
    else if (half_det_b < 1.0)
      phi = acos(half_det_b) / 3;

    eigenvalues[0] = q + 2 * p * static_cast<float>(cos(phi));
    eigenvalues[2] = q + 2 * p *
        static_cast<float>(cos(phi + 2.0 * M_PI / 3.0));
    eigenvalues[1] = 3 * q - eigenvalues[0] - eigenvalues[2];
  }

  // Put eigenvalues in the descending order.
  int indices[3] = {0, 1, 2};
  if (eigenvalues[2] > eigenvalues[1]) {
    std::swap(eigenvalues[2], eigenvalues[1]);
    std::swap(indices[2], indices[1]);
  }

  if (eigenvalues[1] > eigenvalues[0]) {
    std::swap(eigenvalues[1], eigenvalues[0]);
    std::swap(indices[1], indices[0]);
  }

  if (eigenvalues[2] > eigenvalues[1]) {
    std::swap(eigenvalues[2], eigenvalues[1]);
    std::swap(indices[2], indices[1]);
  }

  if (eigenvectors != NULL && diagonal) {
    // Eigenvectors are e-vectors, just need to be sorted accordingly.
    *eigenvectors = Zeros();
    for (int i = 0; i < 3; ++i)
      eigenvectors->set(indices[i], i, 1.0f);
  } else if (eigenvectors != NULL) {
    // Consult the following for a detailed discussion:
    // Joachim Kopp
    // Numerical diagonalization of hermitian 3x3 matrices
    // arXiv.org preprint: physics/0610206
    // Int. J. Mod. Phys. C19 (2008) 523-548

    // TODO(motek): expand to handle correctly negative and multiple
    // eigenvalues.
    for (int i = 0; i < 3; ++i) {
      float l = eigenvalues[i];
      // B = A - l * I
      Matrix3F matrix_b(*this);
      matrix_b.data_[M00] -= l;
      matrix_b.data_[M11] -= l;
      matrix_b.data_[M22] -= l;
      Vector3dF e1 = CrossProduct(matrix_b.get_column(0),
                                  matrix_b.get_column(1));
      Vector3dF e2 = CrossProduct(matrix_b.get_column(1),
                                  matrix_b.get_column(2));
      Vector3dF e3 = CrossProduct(matrix_b.get_column(2),
                                  matrix_b.get_column(0));

      // e1, e2 and e3 should point in the same direction.
      if (DotProduct(e1, e2) < 0)
        e2 = -e2;

      if (DotProduct(e1, e3) < 0)
        e3 = -e3;

      Vector3dF eigvec = e1 + e2 + e3;
      // Normalize.
      eigvec.Scale(1.0f / eigvec.Length());
      eigenvectors->set_column(i, eigvec);
    }
  }

  return Vector3dF(eigenvalues[0], eigenvalues[1], eigenvalues[2]);
}

}  // namespace gfx

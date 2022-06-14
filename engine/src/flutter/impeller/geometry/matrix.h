// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cmath>
#include <optional>
#include <ostream>
#include <utility>

#include "impeller/geometry/matrix_decomposition.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/quaternion.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/shear.h"
#include "impeller/geometry/size.h"
#include "impeller/geometry/vector.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A 4x4 matrix using column-major storage.
///
///             Utility methods that need to make assumptions about normalized
///             device coordinates must use the following convention:
///               * Left-handed coordinate system. Positive rotation is
///                 clockwise about axis of rotation.
///               * Lower left corner is -1.0, -1.0.
///               * Upper right corner is  1.0,  1.0.
///               * Visible z-space is from 0.0 to 1.0.
///                 * This is NOT the same as OpenGL! Be careful.
///               * NDC origin is at (0.0, 0.0, 0.5).
struct Matrix {
  union {
    Scalar m[16];
    Scalar e[4][4];
    Vector4 vec[4];
  };

  //----------------------------------------------------------------------------
  /// Constructs a default identity matrix.
  ///
  constexpr Matrix()
      // clang-format off
      : vec{ Vector4(1.0,  0.0,  0.0,  0.0),
             Vector4(0.0,  1.0,  0.0,  0.0),
             Vector4(0.0,  0.0,  1.0,  0.0),
             Vector4(0.0,  0.0,  0.0,  1.0)} {}
  // clang-format on

  // clang-format off
  constexpr Matrix(Scalar m0,  Scalar m1,  Scalar m2,  Scalar m3,
                   Scalar m4,  Scalar m5,  Scalar m6,  Scalar m7,
                   Scalar m8,  Scalar m9,  Scalar m10, Scalar m11,
                   Scalar m12, Scalar m13, Scalar m14, Scalar m15)
      : vec{Vector4(m0,  m1,  m2,  m3),
            Vector4(m4,  m5,  m6,  m7),
            Vector4(m8,  m9,  m10, m11),
            Vector4(m12, m13, m14, m15)} {}
  // clang-format on

  Matrix(const MatrixDecomposition& decomposition);

  static constexpr Matrix MakeTranslation(const Vector3& t) {
    // clang-format off
    return Matrix(1.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  t.x, t.y, t.z, 1.0);
    // clang-format on
  }

  static constexpr Matrix MakeScale(const Vector3& s) {
    // clang-format off
    return Matrix(s.x, 0.0, 0.0, 0.0,
                  0.0, s.y, 0.0, 0.0,
                  0.0, 0.0, s.z, 0.0,
                  0.0, 0.0, 0.0, 1.0);
    // clang-format on
  }

  static constexpr Matrix MakeScale(const Vector2& s) {
    return MakeScale(Vector3(s.x, s.y, 1.0));
  }

  static constexpr Matrix MakeSkew(Scalar sx, Scalar sy) {
    // clang-format off
    return Matrix(1.0, sy , 0.0, 0.0,
                  sx , 1.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0,
                  0.0, 0.0, 0.0, 1.0);
    // clang-format on
  }

  static Matrix MakeRotation(Scalar radians, const Vector4& r) {
    const Vector4 v = r.Normalize();

    const Scalar cosine = cos(radians);
    const Scalar cosp = 1.0f - cosine;
    const Scalar sine = sin(radians);

    // clang-format off
    return Matrix(
      cosine + cosp * v.x * v.x,
      cosp * v.x * v.y + v.z * sine,
      cosp * v.x * v.z - v.y * sine,
      0.0,

      cosp * v.x * v.y - v.z * sine,
      cosine + cosp * v.y * v.y,
      cosp * v.y * v.z + v.x * sine,
      0.0,

      cosp * v.x * v.z + v.y * sine,
      cosp * v.y * v.z - v.x * sine,
      cosine + cosp * v.z * v.z,
      0.0,

      0.0,
      0.0,
      0.0,
      1.0);
    // clang-format on
  }

  static Matrix MakeRotationX(Radians r) {
    const Scalar cosine = cos(r.radians);
    const Scalar sine = sin(r.radians);
    // clang-format off
    return Matrix(
      1.0,  0.0,    0.0,    0.0,
      0.0,  cosine, sine,   0.0,
      0.0, -sine,   cosine, 0.0,
      0.0,  0.0,    0.0,    1.0
    );
    // clang-format on
  }

  static Matrix MakeRotationY(Radians r) {
    const Scalar cosine = cos(r.radians);
    const Scalar sine = sin(r.radians);

    // clang-format off
    return Matrix(
      cosine, 0.0, -sine,   0.0,
      0.0,    1.0,  0.0,    0.0,
      sine,   0.0,  cosine, 0.0,
      0.0,    0.0,  0.0,    1.0
    );
    // clang-format on
  }

  static Matrix MakeRotationZ(Radians r) {
    const Scalar cosine = cos(r.radians);
    const Scalar sine = sin(r.radians);

    // clang-format off
    return Matrix (
      cosine, sine,   0.0, 0.0,
      -sine,  cosine, 0.0, 0.0,
      0.0,    0.0,    1.0, 0.0,
      0.0,    0.0,    0.0, 1.0
    );
    // clang-format on
  }

  constexpr Matrix Basis() const {
    // clang-format off
    return Matrix(
      m[0], m[1], m[2],  0.0,
      m[4], m[5], m[6],  0.0,
      m[8], m[9], m[10], 0.0,
      0.0,  0.0,  0.0,   1.0
    );
    // clang-format on
  }

  constexpr Matrix Translate(const Vector3& t) const {
    // clang-format off
    return Matrix(m[0], m[1], m[2], m[3],
                  m[4], m[5], m[6], m[7],
                  m[8], m[9], m[10], m[11],
                  m[0] * t.x + m[4] * t.y + m[8]  * t.z + m[12],
                  m[1] * t.x + m[5] * t.y + m[9]  * t.z + m[13],
                  m[2] * t.x + m[6] * t.y + m[10] * t.z + m[14],
                  m[15]);
    // clang-format on
  }

  constexpr Matrix Scale(const Vector3& s) const {
    // clang-format off
    return Matrix(m[0] * s.x, m[1] * s.x, m[2]  * s.x, m[3]  * s.x,
                  m[4] * s.y, m[5] * s.y, m[6]  * s.y, m[7]  * s.y,
                  m[8] * s.z, m[9] * s.z, m[10] * s.z, m[11] * s.z,
                  m[12]     , m[13]     , m[14]      , m[15]       );
    // clang-format on
  }

  constexpr Matrix Multiply(const Matrix& o) const {
    // clang-format off
    return Matrix(
        m[0] * o.m[0]  + m[4] * o.m[1]  + m[8]  * o.m[2]  + m[12] * o.m[3],
        m[1] * o.m[0]  + m[5] * o.m[1]  + m[9]  * o.m[2]  + m[13] * o.m[3],
        m[2] * o.m[0]  + m[6] * o.m[1]  + m[10] * o.m[2]  + m[14] * o.m[3],
        m[3] * o.m[0]  + m[7] * o.m[1]  + m[11] * o.m[2]  + m[15] * o.m[3],
        m[0] * o.m[4]  + m[4] * o.m[5]  + m[8]  * o.m[6]  + m[12] * o.m[7],
        m[1] * o.m[4]  + m[5] * o.m[5]  + m[9]  * o.m[6]  + m[13] * o.m[7],
        m[2] * o.m[4]  + m[6] * o.m[5]  + m[10] * o.m[6]  + m[14] * o.m[7],
        m[3] * o.m[4]  + m[7] * o.m[5]  + m[11] * o.m[6]  + m[15] * o.m[7],
        m[0] * o.m[8]  + m[4] * o.m[9]  + m[8]  * o.m[10] + m[12] * o.m[11],
        m[1] * o.m[8]  + m[5] * o.m[9]  + m[9]  * o.m[10] + m[13] * o.m[11],
        m[2] * o.m[8]  + m[6] * o.m[9]  + m[10] * o.m[10] + m[14] * o.m[11],
        m[3] * o.m[8]  + m[7] * o.m[9]  + m[11] * o.m[10] + m[15] * o.m[11],
        m[0] * o.m[12] + m[4] * o.m[13] + m[8]  * o.m[14] + m[12] * o.m[15],
        m[1] * o.m[12] + m[5] * o.m[13] + m[9]  * o.m[14] + m[13] * o.m[15],
        m[2] * o.m[12] + m[6] * o.m[13] + m[10] * o.m[14] + m[14] * o.m[15],
        m[3] * o.m[12] + m[7] * o.m[13] + m[11] * o.m[14] + m[15] * o.m[15]);
    // clang-format on
  }

  constexpr Matrix Transpose() const {
    // clang-format off
    return {
        m[0], m[4], m[8],  m[12],
        m[1], m[5], m[9],  m[13],
        m[2], m[6], m[10], m[14],
        m[3], m[7], m[11], m[15],
    };
    // clang-format on
  }

  Matrix Invert() const;

  Scalar GetDeterminant() const;

  Scalar GetMaxBasisLength() const;

  constexpr Vector3 GetScale() const {
    return Vector3(Vector3(m[0], m[1], m[2]).Length(),
                   Vector3(m[4], m[5], m[6]).Length(),
                   Vector3(m[8], m[9], m[10]).Length());
  }

  constexpr bool IsAffine() const {
    return (m[2] == 0 && m[3] == 0 && m[6] == 0 && m[7] == 0 && m[8] == 0 &&
            m[9] == 0 && m[10] == 1 && m[11] == 0 && m[14] == 0 && m[15] == 1);
  }

  constexpr bool IsIdentity() const {
    return (
        // clang-format off
        m[0]  == 1.0 && m[1]  == 0.0 && m[2]  == 0.0 && m[3]  == 0.0 &&
        m[4]  == 0.0 && m[5]  == 1.0 && m[6]  == 0.0 && m[7]  == 0.0 &&
        m[8]  == 0.0 && m[9]  == 0.0 && m[10] == 1.0 && m[11] == 0.0 &&
        m[12] == 0.0 && m[13] == 0.0 && m[14] == 0.0 && m[15] == 1.0
        // clang-format on
    );
  }

  std::optional<MatrixDecomposition> Decompose() const;

  constexpr bool operator==(const Matrix& m) const {
    // clang-format off
    return vec[0] == m.vec[0]
        && vec[1] == m.vec[1]
        && vec[2] == m.vec[2]
        && vec[3] == m.vec[3];
    // clang-format on
  }

  constexpr bool operator!=(const Matrix& m) const {
    // clang-format off
    return vec[0] != m.vec[0]
        || vec[1] != m.vec[1]
        || vec[2] != m.vec[2]
        || vec[3] != m.vec[3];
    // clang-format on
  }

  Matrix operator+(const Vector3& t) const { return Translate(t); }

  Matrix operator-(const Vector3& t) const { return Translate(-t); }

  Matrix operator*(const Matrix& m) const { return Multiply(m); }

  Matrix operator+(const Matrix& m) const;

  constexpr Vector4 operator*(const Vector4& v) const {
    return Vector4(v.x * m[0] + v.y * m[4] + v.z * m[8] + v.w * m[12],
                   v.x * m[1] + v.y * m[5] + v.z * m[9] + v.w * m[13],
                   v.x * m[2] + v.y * m[6] + v.z * m[10] + v.w * m[14],
                   v.x * m[3] + v.y * m[7] + v.z * m[11] + v.w * m[15]);
  }

  constexpr Vector3 operator*(const Vector3& v) const {
    return Vector3(v.x * m[0] + v.y * m[4] + v.z * m[8] + m[12],
                   v.x * m[1] + v.y * m[5] + v.z * m[9] + m[13],
                   v.x * m[2] + v.y * m[6] + v.z * m[10] + m[14]);
  }

  constexpr Point operator*(const Point& v) const {
    return Point(v.x * m[0] + v.y * m[4] + m[12],
                 v.x * m[1] + v.y * m[5] + m[13]);
  }

  constexpr Vector4 TransformDirection(const Vector4& v) const {
    return Vector4(v.x * m[0] + v.y * m[4] + v.z * m[8],
                   v.x * m[1] + v.y * m[5] + v.z * m[9],
                   v.x * m[2] + v.y * m[6] + v.z * m[10], v.w);
  }

  constexpr Vector3 TransformDirection(const Vector3& v) const {
    return Vector3(v.x * m[0] + v.y * m[4] + v.z * m[8],
                   v.x * m[1] + v.y * m[5] + v.z * m[9],
                   v.x * m[2] + v.y * m[6] + v.z * m[10]);
  }

  constexpr Vector2 TransformDirection(const Vector2& v) const {
    return Vector2(v.x * m[0] + v.y * m[4], v.x * m[1] + v.y * m[5]);
  }

  template <class T>
  static constexpr Matrix MakeOrthographic(TSize<T> size) {
    // Per assumptions about NDC documented above.
    const auto scale =
        MakeScale({2.0f / static_cast<Scalar>(size.width),
                   -2.0f / static_cast<Scalar>(size.height), 1.0});
    const auto translate = MakeTranslation({-1.0, 1.0, 0.5});
    return translate * scale;
  }

  static constexpr Matrix MakePerspective(Radians fov_y,
                                          Scalar aspect_ratio,
                                          Scalar z_near,
                                          Scalar z_far) {
    Scalar height = std::tan(fov_y.radians * 0.5);
    Scalar width = height * aspect_ratio;
    Scalar z_diff = z_near - z_far;

    // clang-format off
    return {
      1.0f / width, 0.0f,          0.0f,                              0.0f,
      0.0f,         1.0f / height, 0.0f,                              0.0f,
      0.0f,         0.0f,          (z_near + z_far) / z_diff,        -1.0f,
      0.0f,         0.0f,          (2.0f * z_near * z_far) / z_diff,  0.0f
    };
    // clang-format on
  }

  template <class T>
  static constexpr Matrix MakePerspective(Radians fov_y,
                                          TSize<T> size,
                                          Scalar z_near,
                                          Scalar z_far) {
    return MakePerspective(fov_y, static_cast<Scalar>(size.width) / size.height,
                           z_near, z_far);
  }
};

static_assert(sizeof(struct Matrix) == sizeof(Scalar) * 16,
              "The matrix must be of consistent size.");

}  // namespace impeller

namespace std {
inline std::ostream& operator<<(std::ostream& out, const impeller::Matrix& m) {
  out << "(";
  for (size_t i = 0; i < 4u; i++) {
    for (size_t j = 0; j < 4u; j++) {
      out << m.e[i][j] << ",";
    }
    out << std::endl;
  }
  out << ")";
  return out;
}

}  // namespace std

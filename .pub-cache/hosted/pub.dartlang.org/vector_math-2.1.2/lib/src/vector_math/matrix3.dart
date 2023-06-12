// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math;

/// 3D Matrix.
/// Values are stored in column major order.
class Matrix3 {
  final Float32List _m3storage;

  /// The components of the matrix.
  Float32List get storage => _m3storage;

  /// Solve [A] * [x] = [b].
  static void solve2(Matrix3 A, Vector2 x, Vector2 b) {
    final a11 = A.entry(0, 0);
    final a12 = A.entry(0, 1);
    final a21 = A.entry(1, 0);
    final a22 = A.entry(1, 1);
    final bx = b.x - A.storage[6];
    final by = b.y - A.storage[7];
    var det = a11 * a22 - a12 * a21;

    if (det != 0.0) {
      det = 1.0 / det;
    }

    x
      ..x = det * (a22 * bx - a12 * by)
      ..y = det * (a11 * by - a21 * bx);
  }

  /// Solve [A] * [x] = [b].
  static void solve(Matrix3 A, Vector3 x, Vector3 b) {
    final A0x = A.entry(0, 0);
    final A0y = A.entry(1, 0);
    final A0z = A.entry(2, 0);
    final A1x = A.entry(0, 1);
    final A1y = A.entry(1, 1);
    final A1z = A.entry(2, 1);
    final A2x = A.entry(0, 2);
    final A2y = A.entry(1, 2);
    final A2z = A.entry(2, 2);
    double rx, ry, rz;
    double det;

    // Column1 cross Column 2
    rx = A1y * A2z - A1z * A2y;
    ry = A1z * A2x - A1x * A2z;
    rz = A1x * A2y - A1y * A2x;

    // A.getColumn(0).dot(x)
    det = A0x * rx + A0y * ry + A0z * rz;
    if (det != 0.0) {
      det = 1.0 / det;
    }

    // b dot [Column1 cross Column 2]
    final x_ = det * (b.x * rx + b.y * ry + b.z * rz);

    // Column2 cross b
    rx = -(A2y * b.z - A2z * b.y);
    ry = -(A2z * b.x - A2x * b.z);
    rz = -(A2x * b.y - A2y * b.x);
    // Column0 dot -[Column2 cross b (Column3)]
    final y_ = det * (A0x * rx + A0y * ry + A0z * rz);

    // b cross Column 1
    rx = -(b.y * A1z - b.z * A1y);
    ry = -(b.z * A1x - b.x * A1z);
    rz = -(b.x * A1y - b.y * A1x);
    // Column0 dot -[b cross Column 1]
    final z_ = det * (A0x * rx + A0y * ry + A0z * rz);

    x
      ..x = x_
      ..y = y_
      ..z = z_;
  }

  /// Return index in storage for [row], [col] value.
  int index(int row, int col) => (col * 3) + row;

  /// Value at [row], [col].
  double entry(int row, int col) {
    assert((row >= 0) && (row < dimension));
    assert((col >= 0) && (col < dimension));

    return _m3storage[index(row, col)];
  }

  /// Set value at [row], [col] to be [v].
  void setEntry(int row, int col, double v) {
    assert((row >= 0) && (row < dimension));
    assert((col >= 0) && (col < dimension));

    _m3storage[index(row, col)] = v;
  }

  /// New matrix with specified values.
  factory Matrix3(double arg0, double arg1, double arg2, double arg3,
          double arg4, double arg5, double arg6, double arg7, double arg8) =>
      Matrix3.zero()
        ..setValues(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);

  /// New matrix from [values].
  factory Matrix3.fromList(List<double> values) => Matrix3.zero()
    ..setValues(values[0], values[1], values[2], values[3], values[4],
        values[5], values[6], values[7], values[8]);

  /// Constructs a new [Matrix3] filled with zeros.
  Matrix3.zero() : _m3storage = Float32List(9);

  /// Identity matrix.
  factory Matrix3.identity() => Matrix3.zero()..setIdentity();

  /// Copes values from [other].
  factory Matrix3.copy(Matrix3 other) => Matrix3.zero()..setFrom(other);

  /// Constructs a new mat3 from columns.
  factory Matrix3.columns(Vector3 arg0, Vector3 arg1, Vector3 arg2) =>
      Matrix3.zero()..setColumns(arg0, arg1, arg2);

  /// Outer product of [u] and [v].
  factory Matrix3.outer(Vector3 u, Vector3 v) => Matrix3.zero()..setOuter(u, v);

  /// Rotation of [radians] around X axis.
  factory Matrix3.rotationX(double radians) =>
      Matrix3.zero()..setRotationX(radians);

  /// Rotation of [radians] around Y axis.
  factory Matrix3.rotationY(double radians) =>
      Matrix3.zero()..setRotationY(radians);

  /// Rotation of [radians] around Z axis.
  factory Matrix3.rotationZ(double radians) =>
      Matrix3.zero()..setRotationZ(radians);

  /// Sets the matrix with specified values.
  void setValues(double arg0, double arg1, double arg2, double arg3,
      double arg4, double arg5, double arg6, double arg7, double arg8) {
    _m3storage[8] = arg8;
    _m3storage[7] = arg7;
    _m3storage[6] = arg6;
    _m3storage[5] = arg5;
    _m3storage[4] = arg4;
    _m3storage[3] = arg3;
    _m3storage[2] = arg2;
    _m3storage[1] = arg1;
    _m3storage[0] = arg0;
  }

  /// Sets the entire matrix to the column values.
  void setColumns(Vector3 arg0, Vector3 arg1, Vector3 arg2) {
    final arg0Storage = arg0._v3storage;
    final arg1Storage = arg1._v3storage;
    final arg2Storage = arg2._v3storage;
    _m3storage[0] = arg0Storage[0];
    _m3storage[1] = arg0Storage[1];
    _m3storage[2] = arg0Storage[2];
    _m3storage[3] = arg1Storage[0];
    _m3storage[4] = arg1Storage[1];
    _m3storage[5] = arg1Storage[2];
    _m3storage[6] = arg2Storage[0];
    _m3storage[7] = arg2Storage[1];
    _m3storage[8] = arg2Storage[2];
  }

  /// Sets the entire matrix to the matrix in [arg].
  void setFrom(Matrix3 arg) {
    final argStorage = arg._m3storage;
    _m3storage[8] = argStorage[8];
    _m3storage[7] = argStorage[7];
    _m3storage[6] = argStorage[6];
    _m3storage[5] = argStorage[5];
    _m3storage[4] = argStorage[4];
    _m3storage[3] = argStorage[3];
    _m3storage[2] = argStorage[2];
    _m3storage[1] = argStorage[1];
    _m3storage[0] = argStorage[0];
  }

  /// Set this to the outer product of [u] and [v].
  void setOuter(Vector3 u, Vector3 v) {
    final uStorage = u._v3storage;
    final vStorage = v._v3storage;
    _m3storage[0] = uStorage[0] * vStorage[0];
    _m3storage[1] = uStorage[0] * vStorage[1];
    _m3storage[2] = uStorage[0] * vStorage[2];
    _m3storage[3] = uStorage[1] * vStorage[0];
    _m3storage[4] = uStorage[1] * vStorage[1];
    _m3storage[5] = uStorage[1] * vStorage[2];
    _m3storage[6] = uStorage[2] * vStorage[0];
    _m3storage[7] = uStorage[2] * vStorage[1];
    _m3storage[8] = uStorage[2] * vStorage[2];
  }

  /// Set the diagonal of the matrix.
  void splatDiagonal(double arg) {
    _m3storage[0] = arg;
    _m3storage[4] = arg;
    _m3storage[8] = arg;
  }

  /// Set the diagonal of the matrix.
  void setDiagonal(Vector3 arg) {
    _m3storage[0] = arg.storage[0];
    _m3storage[4] = arg.storage[1];
    _m3storage[8] = arg.storage[2];
  }

  /// Sets the upper 2x2 of the matrix to be [arg].
  void setUpper2x2(Matrix2 arg) {
    final argStorage = arg._m2storage;
    _m3storage[0] = argStorage[0];
    _m3storage[1] = argStorage[1];
    _m3storage[3] = argStorage[2];
    _m3storage[4] = argStorage[3];
  }

  /// Returns a printable string
  @override
  String toString() => '[0] ${getRow(0)}\n[1] ${getRow(1)}\n[2] ${getRow(2)}\n';

  /// Dimension of the matrix.
  int get dimension => 3;

  /// Access the element of the matrix at the index [i].
  double operator [](int i) => _m3storage[i];

  /// Set the element of the matrix at the index [i].
  void operator []=(int i, double v) {
    _m3storage[i] = v;
  }

  /// Check if two matrices are the same.
  @override
  bool operator ==(Object? other) =>
      (other is Matrix3) &&
      (_m3storage[0] == other._m3storage[0]) &&
      (_m3storage[1] == other._m3storage[1]) &&
      (_m3storage[2] == other._m3storage[2]) &&
      (_m3storage[3] == other._m3storage[3]) &&
      (_m3storage[4] == other._m3storage[4]) &&
      (_m3storage[5] == other._m3storage[5]) &&
      (_m3storage[6] == other._m3storage[6]) &&
      (_m3storage[7] == other._m3storage[7]) &&
      (_m3storage[8] == other._m3storage[8]);

  @override
  int get hashCode => Object.hashAll(_m3storage);

  /// Returns row 0
  Vector3 get row0 => getRow(0);

  /// Returns row 1
  Vector3 get row1 => getRow(1);

  /// Returns row 2
  Vector3 get row2 => getRow(2);

  /// Sets row 0 to [arg]
  set row0(Vector3 arg) => setRow(0, arg);

  /// Sets row 1 to [arg]
  set row1(Vector3 arg) => setRow(1, arg);

  /// Sets row 2 to [arg]
  set row2(Vector3 arg) => setRow(2, arg);

  /// Assigns the [row] of to [arg].
  void setRow(int row, Vector3 arg) {
    final argStorage = arg._v3storage;
    _m3storage[index(row, 0)] = argStorage[0];
    _m3storage[index(row, 1)] = argStorage[1];
    _m3storage[index(row, 2)] = argStorage[2];
  }

  /// Gets the [row] of the matrix
  Vector3 getRow(int row) {
    final r = Vector3.zero();
    final rStorage = r._v3storage;
    rStorage[0] = _m3storage[index(row, 0)];
    rStorage[1] = _m3storage[index(row, 1)];
    rStorage[2] = _m3storage[index(row, 2)];
    return r;
  }

  /// Assigns the [column] of the matrix [arg]
  void setColumn(int column, Vector3 arg) {
    final argStorage = arg._v3storage;
    final entry = column * 3;
    _m3storage[entry + 2] = argStorage[2];
    _m3storage[entry + 1] = argStorage[1];
    _m3storage[entry + 0] = argStorage[0];
  }

  /// Gets the [column] of the matrix
  Vector3 getColumn(int column) {
    final r = Vector3.zero();
    final rStorage = r._v3storage;
    final entry = column * 3;
    rStorage[2] = _m3storage[entry + 2];
    rStorage[1] = _m3storage[entry + 1];
    rStorage[0] = _m3storage[entry + 0];
    return r;
  }

  /// Clone of this.
  Matrix3 clone() => Matrix3.copy(this);

  /// Copy this into [arg].
  Matrix3 copyInto(Matrix3 arg) {
    final argStorage = arg._m3storage;
    argStorage[0] = _m3storage[0];
    argStorage[1] = _m3storage[1];
    argStorage[2] = _m3storage[2];
    argStorage[3] = _m3storage[3];
    argStorage[4] = _m3storage[4];
    argStorage[5] = _m3storage[5];
    argStorage[6] = _m3storage[6];
    argStorage[7] = _m3storage[7];
    argStorage[8] = _m3storage[8];
    return arg;
  }

  /// Returns a new vector or matrix by multiplying this with [arg].
  dynamic operator *(dynamic arg) {
    if (arg is double) {
      return scaled(arg);
    }
    if (arg is Vector3) {
      return transformed(arg);
    }
    if (arg is Matrix3) {
      return multiplied(arg);
    }
    throw ArgumentError(arg);
  }

  /// Returns new matrix after component wise this + [arg]
  Matrix3 operator +(Matrix3 arg) => clone()..add(arg);

  /// Returns new matrix after component wise this - [arg]
  Matrix3 operator -(Matrix3 arg) => clone()..sub(arg);

  /// Returns new matrix -this
  Matrix3 operator -() => clone()..negate();

  /// Zeros this.
  void setZero() {
    _m3storage[0] = 0.0;
    _m3storage[1] = 0.0;
    _m3storage[2] = 0.0;
    _m3storage[3] = 0.0;
    _m3storage[4] = 0.0;
    _m3storage[5] = 0.0;
    _m3storage[6] = 0.0;
    _m3storage[7] = 0.0;
    _m3storage[8] = 0.0;
  }

  /// Makes this into the identity matrix.
  void setIdentity() {
    _m3storage[0] = 1.0;
    _m3storage[1] = 0.0;
    _m3storage[2] = 0.0;
    _m3storage[3] = 0.0;
    _m3storage[4] = 1.0;
    _m3storage[5] = 0.0;
    _m3storage[6] = 0.0;
    _m3storage[7] = 0.0;
    _m3storage[8] = 1.0;
  }

  /// Returns the tranpose of this.
  Matrix3 transposed() => clone()..transpose();

  /// Transpose this.
  void transpose() {
    double temp;
    temp = _m3storage[3];
    _m3storage[3] = _m3storage[1];
    _m3storage[1] = temp;
    temp = _m3storage[6];
    _m3storage[6] = _m3storage[2];
    _m3storage[2] = temp;
    temp = _m3storage[7];
    _m3storage[7] = _m3storage[5];
    _m3storage[5] = temp;
  }

  /// Returns the component wise absolute value of this.
  Matrix3 absolute() {
    final r = Matrix3.zero();
    final rStorage = r._m3storage;
    rStorage[0] = _m3storage[0].abs();
    rStorage[1] = _m3storage[1].abs();
    rStorage[2] = _m3storage[2].abs();
    rStorage[3] = _m3storage[3].abs();
    rStorage[4] = _m3storage[4].abs();
    rStorage[5] = _m3storage[5].abs();
    rStorage[6] = _m3storage[6].abs();
    rStorage[7] = _m3storage[7].abs();
    rStorage[8] = _m3storage[8].abs();
    return r;
  }

  /// Returns the determinant of this matrix.
  double determinant() {
    final x = _m3storage[0] *
        ((_m3storage[4] * _m3storage[8]) - (_m3storage[5] * _m3storage[7]));
    final y = _m3storage[1] *
        ((_m3storage[3] * _m3storage[8]) - (_m3storage[5] * _m3storage[6]));
    final z = _m3storage[2] *
        ((_m3storage[3] * _m3storage[7]) - (_m3storage[4] * _m3storage[6]));
    return x - y + z;
  }

  /// Returns the dot product of row [i] and [v].
  double dotRow(int i, Vector3 v) {
    final vStorage = v._v3storage;
    return _m3storage[i] * vStorage[0] +
        _m3storage[3 + i] * vStorage[1] +
        _m3storage[6 + i] * vStorage[2];
  }

  /// Returns the dot product of column [j] and [v].
  double dotColumn(int j, Vector3 v) {
    final vStorage = v._v3storage;
    return _m3storage[j * 3] * vStorage[0] +
        _m3storage[j * 3 + 1] * vStorage[1] +
        _m3storage[j * 3 + 2] * vStorage[2];
  }

  /// Returns the trace of the matrix. The trace of a matrix is the sum of
  /// the diagonal entries.
  double trace() {
    var t = 0.0;
    t += _m3storage[0];
    t += _m3storage[4];
    t += _m3storage[8];
    return t;
  }

  /// Returns infinity norm of the matrix. Used for numerical analysis.
  double infinityNorm() {
    var norm = 0.0;
    {
      var row_norm = 0.0;
      row_norm += _m3storage[0].abs();
      row_norm += _m3storage[1].abs();
      row_norm += _m3storage[2].abs();
      norm = row_norm > norm ? row_norm : norm;
    }
    {
      var row_norm = 0.0;
      row_norm += _m3storage[3].abs();
      row_norm += _m3storage[4].abs();
      row_norm += _m3storage[5].abs();
      norm = row_norm > norm ? row_norm : norm;
    }
    {
      var row_norm = 0.0;
      row_norm += _m3storage[6].abs();
      row_norm += _m3storage[7].abs();
      row_norm += _m3storage[8].abs();
      norm = row_norm > norm ? row_norm : norm;
    }
    return norm;
  }

  /// Returns relative error between this and [correct]
  double relativeError(Matrix3 correct) {
    final diff = correct - this;
    final correct_norm = correct.infinityNorm();
    final diff_norm = diff.infinityNorm();
    return diff_norm / correct_norm;
  }

  /// Returns absolute error between this and [correct]
  double absoluteError(Matrix3 correct) {
    final this_norm = infinityNorm();
    final correct_norm = correct.infinityNorm();
    final diff_norm = (this_norm - correct_norm).abs();
    return diff_norm;
  }

  /// Invert the matrix. Returns the determinant.
  double invert() => copyInverse(this);

  /// Set this matrix to be the inverse of [arg]
  double copyInverse(Matrix3 arg) {
    final det = arg.determinant();
    if (det == 0.0) {
      setFrom(arg);
      return 0.0;
    }
    final invDet = 1.0 / det;
    final argStorage = arg._m3storage;
    final ix = invDet *
        (argStorage[4] * argStorage[8] - argStorage[5] * argStorage[7]);
    final iy = invDet *
        (argStorage[2] * argStorage[7] - argStorage[1] * argStorage[8]);
    final iz = invDet *
        (argStorage[1] * argStorage[5] - argStorage[2] * argStorage[4]);
    final jx = invDet *
        (argStorage[5] * argStorage[6] - argStorage[3] * argStorage[8]);
    final jy = invDet *
        (argStorage[0] * argStorage[8] - argStorage[2] * argStorage[6]);
    final jz = invDet *
        (argStorage[2] * argStorage[3] - argStorage[0] * argStorage[5]);
    final kx = invDet *
        (argStorage[3] * argStorage[7] - argStorage[4] * argStorage[6]);
    final ky = invDet *
        (argStorage[1] * argStorage[6] - argStorage[0] * argStorage[7]);
    final kz = invDet *
        (argStorage[0] * argStorage[4] - argStorage[1] * argStorage[3]);
    _m3storage[0] = ix;
    _m3storage[1] = iy;
    _m3storage[2] = iz;
    _m3storage[3] = jx;
    _m3storage[4] = jy;
    _m3storage[5] = jz;
    _m3storage[6] = kx;
    _m3storage[7] = ky;
    _m3storage[8] = kz;
    return det;
  }

  /// Set this matrix to be the normal matrix of [arg].
  void copyNormalMatrix(Matrix4 arg) {
    copyInverse(arg.getRotation());
    transpose();
  }

  /// Turns the matrix into a rotation of [radians] around X
  void setRotationX(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    _m3storage[0] = 1.0;
    _m3storage[1] = 0.0;
    _m3storage[2] = 0.0;
    _m3storage[3] = 0.0;
    _m3storage[4] = c;
    _m3storage[5] = s;
    _m3storage[6] = 0.0;
    _m3storage[7] = -s;
    _m3storage[8] = c;
  }

  /// Turns the matrix into a rotation of [radians] around Y
  void setRotationY(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    _m3storage[0] = c;
    _m3storage[1] = 0.0;
    _m3storage[2] = s;
    _m3storage[3] = 0.0;
    _m3storage[4] = 1.0;
    _m3storage[5] = 0.0;
    _m3storage[6] = -s;
    _m3storage[7] = 0.0;
    _m3storage[8] = c;
  }

  /// Turns the matrix into a rotation of [radians] around Z
  void setRotationZ(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    _m3storage[0] = c;
    _m3storage[1] = s;
    _m3storage[2] = 0.0;
    _m3storage[3] = -s;
    _m3storage[4] = c;
    _m3storage[5] = 0.0;
    _m3storage[6] = 0.0;
    _m3storage[7] = 0.0;
    _m3storage[8] = 1.0;
  }

  /// Converts into Adjugate matrix and scales by [scale]
  void scaleAdjoint(double scale) {
    final m00 = _m3storage[0];
    final m01 = _m3storage[3];
    final m02 = _m3storage[6];
    final m10 = _m3storage[1];
    final m11 = _m3storage[4];
    final m12 = _m3storage[7];
    final m20 = _m3storage[2];
    final m21 = _m3storage[5];
    final m22 = _m3storage[8];
    _m3storage[0] = (m11 * m22 - m12 * m21) * scale;
    _m3storage[1] = (m12 * m20 - m10 * m22) * scale;
    _m3storage[2] = (m10 * m21 - m11 * m20) * scale;
    _m3storage[3] = (m02 * m21 - m01 * m22) * scale;
    _m3storage[4] = (m00 * m22 - m02 * m20) * scale;
    _m3storage[5] = (m01 * m20 - m00 * m21) * scale;
    _m3storage[6] = (m01 * m12 - m02 * m11) * scale;
    _m3storage[7] = (m02 * m10 - m00 * m12) * scale;
    _m3storage[8] = (m00 * m11 - m01 * m10) * scale;
  }

  /// Rotates [arg] by the absolute rotation of this
  /// Returns [arg].
  /// Primarily used by AABB transformation code.
  Vector3 absoluteRotate(Vector3 arg) {
    final m00 = _m3storage[0].abs();
    final m01 = _m3storage[3].abs();
    final m02 = _m3storage[6].abs();
    final m10 = _m3storage[1].abs();
    final m11 = _m3storage[4].abs();
    final m12 = _m3storage[7].abs();
    final m20 = _m3storage[2].abs();
    final m21 = _m3storage[5].abs();
    final m22 = _m3storage[8].abs();
    final argStorage = arg._v3storage;
    final x = argStorage[0];
    final y = argStorage[1];
    final z = argStorage[2];
    argStorage[0] = x * m00 + y * m01 + z * m02;
    argStorage[1] = x * m10 + y * m11 + z * m12;
    argStorage[2] = x * m20 + y * m21 + z * m22;
    return arg;
  }

  /// Rotates [arg] by the absolute rotation of this
  /// Returns [arg].
  /// Primarily used by AABB transformation code.
  Vector2 absoluteRotate2(Vector2 arg) {
    final m00 = _m3storage[0].abs();
    final m01 = _m3storage[3].abs();
    final m10 = _m3storage[1].abs();
    final m11 = _m3storage[4].abs();
    final argStorage = arg._v2storage;
    final x = argStorage[0];
    final y = argStorage[1];
    argStorage[0] = x * m00 + y * m01;
    argStorage[1] = x * m10 + y * m11;
    return arg;
  }

  /// Transforms [arg] with this.
  Vector2 transform2(Vector2 arg) {
    final argStorage = arg._v2storage;
    final x_ = (_m3storage[0] * argStorage[0]) +
        (_m3storage[3] * argStorage[1]) +
        _m3storage[6];
    final y_ = (_m3storage[1] * argStorage[0]) +
        (_m3storage[4] * argStorage[1]) +
        _m3storage[7];
    argStorage[0] = x_;
    argStorage[1] = y_;
    return arg;
  }

  /// Scales this by [scale].
  void scale(double scale) {
    _m3storage[0] = _m3storage[0] * scale;
    _m3storage[1] = _m3storage[1] * scale;
    _m3storage[2] = _m3storage[2] * scale;
    _m3storage[3] = _m3storage[3] * scale;
    _m3storage[4] = _m3storage[4] * scale;
    _m3storage[5] = _m3storage[5] * scale;
    _m3storage[6] = _m3storage[6] * scale;
    _m3storage[7] = _m3storage[7] * scale;
    _m3storage[8] = _m3storage[8] * scale;
  }

  /// Create a copy of this and scale it by [scale].
  Matrix3 scaled(double scale) => clone()..scale(scale);

  /// Add [o] to this.
  void add(Matrix3 o) {
    final oStorage = o._m3storage;
    _m3storage[0] = _m3storage[0] + oStorage[0];
    _m3storage[1] = _m3storage[1] + oStorage[1];
    _m3storage[2] = _m3storage[2] + oStorage[2];
    _m3storage[3] = _m3storage[3] + oStorage[3];
    _m3storage[4] = _m3storage[4] + oStorage[4];
    _m3storage[5] = _m3storage[5] + oStorage[5];
    _m3storage[6] = _m3storage[6] + oStorage[6];
    _m3storage[7] = _m3storage[7] + oStorage[7];
    _m3storage[8] = _m3storage[8] + oStorage[8];
  }

  /// Subtract [o] from this.
  void sub(Matrix3 o) {
    final oStorage = o._m3storage;
    _m3storage[0] = _m3storage[0] - oStorage[0];
    _m3storage[1] = _m3storage[1] - oStorage[1];
    _m3storage[2] = _m3storage[2] - oStorage[2];
    _m3storage[3] = _m3storage[3] - oStorage[3];
    _m3storage[4] = _m3storage[4] - oStorage[4];
    _m3storage[5] = _m3storage[5] - oStorage[5];
    _m3storage[6] = _m3storage[6] - oStorage[6];
    _m3storage[7] = _m3storage[7] - oStorage[7];
    _m3storage[8] = _m3storage[8] - oStorage[8];
  }

  /// Negate this.
  void negate() {
    _m3storage[0] = -_m3storage[0];
    _m3storage[1] = -_m3storage[1];
    _m3storage[2] = -_m3storage[2];
    _m3storage[3] = -_m3storage[3];
    _m3storage[4] = -_m3storage[4];
    _m3storage[5] = -_m3storage[5];
    _m3storage[6] = -_m3storage[6];
    _m3storage[7] = -_m3storage[7];
    _m3storage[8] = -_m3storage[8];
  }

  /// Multiply this by [arg].
  void multiply(Matrix3 arg) {
    final m00 = _m3storage[0];
    final m01 = _m3storage[3];
    final m02 = _m3storage[6];
    final m10 = _m3storage[1];
    final m11 = _m3storage[4];
    final m12 = _m3storage[7];
    final m20 = _m3storage[2];
    final m21 = _m3storage[5];
    final m22 = _m3storage[8];
    final argStorage = arg._m3storage;
    final n00 = argStorage[0];
    final n01 = argStorage[3];
    final n02 = argStorage[6];
    final n10 = argStorage[1];
    final n11 = argStorage[4];
    final n12 = argStorage[7];
    final n20 = argStorage[2];
    final n21 = argStorage[5];
    final n22 = argStorage[8];
    _m3storage[0] = (m00 * n00) + (m01 * n10) + (m02 * n20);
    _m3storage[3] = (m00 * n01) + (m01 * n11) + (m02 * n21);
    _m3storage[6] = (m00 * n02) + (m01 * n12) + (m02 * n22);
    _m3storage[1] = (m10 * n00) + (m11 * n10) + (m12 * n20);
    _m3storage[4] = (m10 * n01) + (m11 * n11) + (m12 * n21);
    _m3storage[7] = (m10 * n02) + (m11 * n12) + (m12 * n22);
    _m3storage[2] = (m20 * n00) + (m21 * n10) + (m22 * n20);
    _m3storage[5] = (m20 * n01) + (m21 * n11) + (m22 * n21);
    _m3storage[8] = (m20 * n02) + (m21 * n12) + (m22 * n22);
  }

  /// Create a copy of this and multiply it by [arg].
  Matrix3 multiplied(Matrix3 arg) => clone()..multiply(arg);

  void transposeMultiply(Matrix3 arg) {
    final m00 = _m3storage[0];
    final m01 = _m3storage[1];
    final m02 = _m3storage[2];
    final m10 = _m3storage[3];
    final m11 = _m3storage[4];
    final m12 = _m3storage[5];
    final m20 = _m3storage[6];
    final m21 = _m3storage[7];
    final m22 = _m3storage[8];
    final argStorage = arg._m3storage;
    _m3storage[0] =
        (m00 * argStorage[0]) + (m01 * argStorage[1]) + (m02 * argStorage[2]);
    _m3storage[3] =
        (m00 * argStorage[3]) + (m01 * argStorage[4]) + (m02 * argStorage[5]);
    _m3storage[6] =
        (m00 * argStorage[6]) + (m01 * argStorage[7]) + (m02 * argStorage[8]);
    _m3storage[1] =
        (m10 * argStorage[0]) + (m11 * argStorage[1]) + (m12 * argStorage[2]);
    _m3storage[4] =
        (m10 * argStorage[3]) + (m11 * argStorage[4]) + (m12 * argStorage[5]);
    _m3storage[7] =
        (m10 * argStorage[6]) + (m11 * argStorage[7]) + (m12 * argStorage[8]);
    _m3storage[2] =
        (m20 * argStorage[0]) + (m21 * argStorage[1]) + (m22 * argStorage[2]);
    _m3storage[5] =
        (m20 * argStorage[3]) + (m21 * argStorage[4]) + (m22 * argStorage[5]);
    _m3storage[8] =
        (m20 * argStorage[6]) + (m21 * argStorage[7]) + (m22 * argStorage[8]);
  }

  void multiplyTranspose(Matrix3 arg) {
    final m00 = _m3storage[0];
    final m01 = _m3storage[3];
    final m02 = _m3storage[6];
    final m10 = _m3storage[1];
    final m11 = _m3storage[4];
    final m12 = _m3storage[7];
    final m20 = _m3storage[2];
    final m21 = _m3storage[5];
    final m22 = _m3storage[8];
    final argStorage = arg._m3storage;
    _m3storage[0] =
        (m00 * argStorage[0]) + (m01 * argStorage[3]) + (m02 * argStorage[6]);
    _m3storage[3] =
        (m00 * argStorage[1]) + (m01 * argStorage[4]) + (m02 * argStorage[7]);
    _m3storage[6] =
        (m00 * argStorage[2]) + (m01 * argStorage[5]) + (m02 * argStorage[8]);
    _m3storage[1] =
        (m10 * argStorage[0]) + (m11 * argStorage[3]) + (m12 * argStorage[6]);
    _m3storage[4] =
        (m10 * argStorage[1]) + (m11 * argStorage[4]) + (m12 * argStorage[7]);
    _m3storage[7] =
        (m10 * argStorage[2]) + (m11 * argStorage[5]) + (m12 * argStorage[8]);
    _m3storage[2] =
        (m20 * argStorage[0]) + (m21 * argStorage[3]) + (m22 * argStorage[6]);
    _m3storage[5] =
        (m20 * argStorage[1]) + (m21 * argStorage[4]) + (m22 * argStorage[7]);
    _m3storage[8] =
        (m20 * argStorage[2]) + (m21 * argStorage[5]) + (m22 * argStorage[8]);
  }

  /// Transform [arg] of type [Vector3] using the transformation defined by
  /// this.
  Vector3 transform(Vector3 arg) {
    final argStorage = arg._v3storage;
    final x_ = (_m3storage[0] * argStorage[0]) +
        (_m3storage[3] * argStorage[1]) +
        (_m3storage[6] * argStorage[2]);
    final y_ = (_m3storage[1] * argStorage[0]) +
        (_m3storage[4] * argStorage[1]) +
        (_m3storage[7] * argStorage[2]);
    final z_ = (_m3storage[2] * argStorage[0]) +
        (_m3storage[5] * argStorage[1]) +
        (_m3storage[8] * argStorage[2]);
    arg
      ..x = x_
      ..y = y_
      ..z = z_;
    return arg;
  }

  /// Transform a copy of [arg] of type [Vector3] using the transformation
  /// defined by this. If a [out] parameter is supplied, the copy is stored in
  /// [out].
  Vector3 transformed(Vector3 arg, [Vector3? out]) {
    if (out == null) {
      out = Vector3.copy(arg);
    } else {
      out.setFrom(arg);
    }
    return transform(out);
  }

  /// Copies this into [array] starting at [offset].
  void copyIntoArray(List<num> array, [int offset = 0]) {
    final i = offset;
    array[i + 8] = _m3storage[8];
    array[i + 7] = _m3storage[7];
    array[i + 6] = _m3storage[6];
    array[i + 5] = _m3storage[5];
    array[i + 4] = _m3storage[4];
    array[i + 3] = _m3storage[3];
    array[i + 2] = _m3storage[2];
    array[i + 1] = _m3storage[1];
    array[i + 0] = _m3storage[0];
  }

  /// Copies elements from [array] into this starting at [offset].
  void copyFromArray(List<double> array, [int offset = 0]) {
    final i = offset;
    _m3storage[8] = array[i + 8];
    _m3storage[7] = array[i + 7];
    _m3storage[6] = array[i + 6];
    _m3storage[5] = array[i + 5];
    _m3storage[4] = array[i + 4];
    _m3storage[3] = array[i + 3];
    _m3storage[2] = array[i + 2];
    _m3storage[1] = array[i + 1];
    _m3storage[0] = array[i + 0];
  }

  /// Multiply this to each set of xyz values in [array] starting at [offset].
  List<double> applyToVector3Array(List<double> array, [int offset = 0]) {
    for (var i = 0, j = offset; i < array.length; i += 3, j += 3) {
      final v = Vector3.array(array, j)..applyMatrix3(this);
      array[j] = v.storage[0];
      array[j + 1] = v.storage[1];
      array[j + 2] = v.storage[2];
    }

    return array;
  }

  Vector3 get right {
    final x = _m3storage[0];
    final y = _m3storage[1];
    final z = _m3storage[2];
    return Vector3(x, y, z);
  }

  Vector3 get up {
    final x = _m3storage[3];
    final y = _m3storage[4];
    final z = _m3storage[5];
    return Vector3(x, y, z);
  }

  Vector3 get forward {
    final x = _m3storage[6];
    final y = _m3storage[7];
    final z = _m3storage[8];
    return Vector3(x, y, z);
  }

  /// Is this the identity matrix?
  bool isIdentity() =>
      _m3storage[0] == 1.0 // col 1
      &&
      _m3storage[1] == 0.0 &&
      _m3storage[2] == 0.0 &&
      _m3storage[3] == 0.0 // col 2
      &&
      _m3storage[4] == 1.0 &&
      _m3storage[5] == 0.0 &&
      _m3storage[6] == 0.0 // col 3
      &&
      _m3storage[7] == 0.0 &&
      _m3storage[8] == 1.0;

  /// Is this the zero matrix?
  bool isZero() =>
      _m3storage[0] == 0.0 // col 1
      &&
      _m3storage[1] == 0.0 &&
      _m3storage[2] == 0.0 &&
      _m3storage[3] == 0.0 // col 2
      &&
      _m3storage[4] == 0.0 &&
      _m3storage[5] == 0.0 &&
      _m3storage[6] == 0.0 // col 3
      &&
      _m3storage[7] == 0.0 &&
      _m3storage[8] == 0.0;
}

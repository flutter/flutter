// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class Matrix4 {
  final Float32List _m4storage;

  /// The components of the matrix.
  Float32List get storage => _m4storage;

  /// Returns a matrix that is the inverse of [other] if [other] is invertible,
  /// otherwise `null`.
  static Matrix4 tryInvert(Matrix4 other) {
    final Matrix4 r = Matrix4.zero();
    final double determinant = r.copyInverse(other);
    if (determinant == 0.0) {
      return null;
    }
    return r;
  }

  /// Return index in storage for [row], [col] value.
  int index(int row, int col) => (col * 4) + row;

  /// Value at [row], [col].
  double entry(int row, int col) {
    assert((row >= 0) && (row < dimension));
    assert((col >= 0) && (col < dimension));

    return _m4storage[index(row, col)];
  }

  /// Set value at [row], [col] to be [v].
  void setEntry(int row, int col, double v) {
    assert((row >= 0) && (row < dimension));
    assert((col >= 0) && (col < dimension));

    _m4storage[index(row, col)] = v;
  }

  /// Constructs a new mat4.
  factory Matrix4(
          double arg0,
          double arg1,
          double arg2,
          double arg3,
          double arg4,
          double arg5,
          double arg6,
          double arg7,
          double arg8,
          double arg9,
          double arg10,
          double arg11,
          double arg12,
          double arg13,
          double arg14,
          double arg15) =>
      Matrix4.zero()
        ..setValues(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9,
            arg10, arg11, arg12, arg13, arg14, arg15);

  /// Zero matrix.
  Matrix4.zero() : _m4storage = Float32List(16);

  /// Identity matrix.
  factory Matrix4.identity() => Matrix4.zero()..setIdentity();

  /// Copies values from [other].
  factory Matrix4.copy(Matrix4 other) => Matrix4.zero()..setFrom(other);

  /// Constructs a matrix that is the inverse of [other].
  factory Matrix4.inverted(Matrix4 other) {
    final Matrix4 r = Matrix4.zero();
    final double determinant = r.copyInverse(other);
    if (determinant == 0.0) {
      throw ArgumentError.value(other, 'other', 'Matrix cannot be inverted');
    }
    return r;
  }

  /// Rotation of [radians_] around X.
  factory Matrix4.rotationX(double radians) => Matrix4.zero()
    .._m4storage[15] = 1.0
    ..setRotationX(radians);

  /// Rotation of [radians_] around Y.
  factory Matrix4.rotationY(double radians) => Matrix4.zero()
    .._m4storage[15] = 1.0
    ..setRotationY(radians);

  /// Rotation of [radians_] around Z.
  factory Matrix4.rotationZ(double radians) => Matrix4.zero()
    .._m4storage[15] = 1.0
    ..setRotationZ(radians);

  /// Translation matrix.
  factory Matrix4.translation(Vector3 translation) => Matrix4.zero()
    ..setIdentity()
    ..setTranslation(translation);

  /// Translation matrix.
  factory Matrix4.translationValues(double x, double y, double z) =>
      Matrix4.zero()
        ..setIdentity()
        ..setTranslationRaw(x, y, z);

  /// Scale matrix.
  factory Matrix4.diagonal3Values(double x, double y, double z) =>
      Matrix4.zero()
        .._m4storage[15] = 1.0
        .._m4storage[10] = z
        .._m4storage[5] = y
        .._m4storage[0] = x;

  /// Constructs Matrix4 with given [Float32List] as [storage].
  Matrix4.fromFloat32List(this._m4storage);

  /// Constructs Matrix4 with a [storage] that views given [buffer] starting at
  /// [offset]. [offset] has to be multiple of [Float32List.bytesPerElement].
  Matrix4.fromBuffer(ByteBuffer buffer, int offset)
      : _m4storage = Float32List.view(buffer, offset, 16);

  /// Sets the matrix with specified values.
  void setValues(
      double arg0,
      double arg1,
      double arg2,
      double arg3,
      double arg4,
      double arg5,
      double arg6,
      double arg7,
      double arg8,
      double arg9,
      double arg10,
      double arg11,
      double arg12,
      double arg13,
      double arg14,
      double arg15) {
    _m4storage[15] = arg15;
    _m4storage[14] = arg14;
    _m4storage[13] = arg13;
    _m4storage[12] = arg12;
    _m4storage[11] = arg11;
    _m4storage[10] = arg10;
    _m4storage[9] = arg9;
    _m4storage[8] = arg8;
    _m4storage[7] = arg7;
    _m4storage[6] = arg6;
    _m4storage[5] = arg5;
    _m4storage[4] = arg4;
    _m4storage[3] = arg3;
    _m4storage[2] = arg2;
    _m4storage[1] = arg1;
    _m4storage[0] = arg0;
  }

  /// Sets the entire matrix to the matrix in [arg].
  void setFrom(Matrix4 arg) {
    final Float32List argStorage = arg._m4storage;
    _m4storage[15] = argStorage[15];
    _m4storage[14] = argStorage[14];
    _m4storage[13] = argStorage[13];
    _m4storage[12] = argStorage[12];
    _m4storage[11] = argStorage[11];
    _m4storage[10] = argStorage[10];
    _m4storage[9] = argStorage[9];
    _m4storage[8] = argStorage[8];
    _m4storage[7] = argStorage[7];
    _m4storage[6] = argStorage[6];
    _m4storage[5] = argStorage[5];
    _m4storage[4] = argStorage[4];
    _m4storage[3] = argStorage[3];
    _m4storage[2] = argStorage[2];
    _m4storage[1] = argStorage[1];
    _m4storage[0] = argStorage[0];
  }

  /// Dimension of the matrix.
  int get dimension => 4;

  /// Access the element of the matrix at the index [i].
  double operator [](int i) => _m4storage[i];

  /// Set the element of the matrix at the index [i].
  void operator []=(int i, double v) {
    _m4storage[i] = v;
  }

  /// Clone matrix.
  Matrix4 clone() => Matrix4.copy(this);

  /// Copy into [arg].
  Matrix4 copyInto(Matrix4 arg) {
    final Float32List argStorage = arg._m4storage;
    argStorage[0] = _m4storage[0];
    argStorage[1] = _m4storage[1];
    argStorage[2] = _m4storage[2];
    argStorage[3] = _m4storage[3];
    argStorage[4] = _m4storage[4];
    argStorage[5] = _m4storage[5];
    argStorage[6] = _m4storage[6];
    argStorage[7] = _m4storage[7];
    argStorage[8] = _m4storage[8];
    argStorage[9] = _m4storage[9];
    argStorage[10] = _m4storage[10];
    argStorage[11] = _m4storage[11];
    argStorage[12] = _m4storage[12];
    argStorage[13] = _m4storage[13];
    argStorage[14] = _m4storage[14];
    argStorage[15] = _m4storage[15];
    return arg;
  }

  /// Translate this matrix by x, y, and z.
  void translate(double x, [double y = 0.0, double z = 0.0]) {
    const double tw = 1.0;
    final double t1 = _m4storage[0] * x +
        _m4storage[4] * y +
        _m4storage[8] * z +
        _m4storage[12] * tw;
    final double t2 = _m4storage[1] * x +
        _m4storage[5] * y +
        _m4storage[9] * z +
        _m4storage[13] * tw;
    final double t3 = _m4storage[2] * x +
        _m4storage[6] * y +
        _m4storage[10] * z +
        _m4storage[14] * tw;
    final double t4 = _m4storage[3] * x +
        _m4storage[7] * y +
        _m4storage[11] * z +
        _m4storage[15] * tw;
    _m4storage[12] = t1;
    _m4storage[13] = t2;
    _m4storage[14] = t3;
    _m4storage[15] = t4;
  }

  /// Scale this matrix by a [Vector3], [Vector4], or x,y,z
  void scale(double x, [double y, double z]) {
    final double sx = x;
    final double sy = y ?? x;
    final double sz = z ?? x;
    const double sw = 1.0;
    _m4storage[0] *= sx;
    _m4storage[1] *= sx;
    _m4storage[2] *= sx;
    _m4storage[3] *= sx;
    _m4storage[4] *= sy;
    _m4storage[5] *= sy;
    _m4storage[6] *= sy;
    _m4storage[7] *= sy;
    _m4storage[8] *= sz;
    _m4storage[9] *= sz;
    _m4storage[10] *= sz;
    _m4storage[11] *= sz;
    _m4storage[12] *= sw;
    _m4storage[13] *= sw;
    _m4storage[14] *= sw;
    _m4storage[15] *= sw;
  }

  /// Create a copy of [this] scaled by a [Vector3], [Vector4] or [x],[y], and
  /// [z].
  Matrix4 scaled(double x, [double y, double z]) => clone()..scale(x, y, z);

  /// Zeros [this].
  void setZero() {
    _m4storage[0] = 0.0;
    _m4storage[1] = 0.0;
    _m4storage[2] = 0.0;
    _m4storage[3] = 0.0;
    _m4storage[4] = 0.0;
    _m4storage[5] = 0.0;
    _m4storage[6] = 0.0;
    _m4storage[7] = 0.0;
    _m4storage[8] = 0.0;
    _m4storage[9] = 0.0;
    _m4storage[10] = 0.0;
    _m4storage[11] = 0.0;
    _m4storage[12] = 0.0;
    _m4storage[13] = 0.0;
    _m4storage[14] = 0.0;
    _m4storage[15] = 0.0;
  }

  /// Makes [this] into the identity matrix.
  void setIdentity() {
    _m4storage[0] = 1.0;
    _m4storage[1] = 0.0;
    _m4storage[2] = 0.0;
    _m4storage[3] = 0.0;
    _m4storage[4] = 0.0;
    _m4storage[5] = 1.0;
    _m4storage[6] = 0.0;
    _m4storage[7] = 0.0;
    _m4storage[8] = 0.0;
    _m4storage[9] = 0.0;
    _m4storage[10] = 1.0;
    _m4storage[11] = 0.0;
    _m4storage[12] = 0.0;
    _m4storage[13] = 0.0;
    _m4storage[14] = 0.0;
    _m4storage[15] = 1.0;
  }

  /// Returns the tranpose of this.
  Matrix4 transposed() => clone()..transpose();

  void transpose() {
    double temp;
    temp = _m4storage[4];
    _m4storage[4] = _m4storage[1];
    _m4storage[1] = temp;
    temp = _m4storage[8];
    _m4storage[8] = _m4storage[2];
    _m4storage[2] = temp;
    temp = _m4storage[12];
    _m4storage[12] = _m4storage[3];
    _m4storage[3] = temp;
    temp = _m4storage[9];
    _m4storage[9] = _m4storage[6];
    _m4storage[6] = temp;
    temp = _m4storage[13];
    _m4storage[13] = _m4storage[7];
    _m4storage[7] = temp;
    temp = _m4storage[14];
    _m4storage[14] = _m4storage[11];
    _m4storage[11] = temp;
  }

  /// Returns the determinant of this matrix.
  double determinant() {
    final double det2_01_01 =
        _m4storage[0] * _m4storage[5] - _m4storage[1] * _m4storage[4];
    final double det2_01_02 =
        _m4storage[0] * _m4storage[6] - _m4storage[2] * _m4storage[4];
    final double det2_01_03 =
        _m4storage[0] * _m4storage[7] - _m4storage[3] * _m4storage[4];
    final double det2_01_12 =
        _m4storage[1] * _m4storage[6] - _m4storage[2] * _m4storage[5];
    final double det2_01_13 =
        _m4storage[1] * _m4storage[7] - _m4storage[3] * _m4storage[5];
    final double det2_01_23 =
        _m4storage[2] * _m4storage[7] - _m4storage[3] * _m4storage[6];
    final double det3_201_012 = _m4storage[8] * det2_01_12 -
        _m4storage[9] * det2_01_02 +
        _m4storage[10] * det2_01_01;
    final double det3_201_013 = _m4storage[8] * det2_01_13 -
        _m4storage[9] * det2_01_03 +
        _m4storage[11] * det2_01_01;
    final double det3_201_023 = _m4storage[8] * det2_01_23 -
        _m4storage[10] * det2_01_03 +
        _m4storage[11] * det2_01_02;
    final double det3_201_123 = _m4storage[9] * det2_01_23 -
        _m4storage[10] * det2_01_13 +
        _m4storage[11] * det2_01_12;
    return -det3_201_123 * _m4storage[12] +
        det3_201_023 * _m4storage[13] -
        det3_201_013 * _m4storage[14] +
        det3_201_012 * _m4storage[15];
  }

  /// Returns a new vector or matrix by multiplying [this] with [arg].
  dynamic operator *(dynamic arg) {
    if (arg is double) {
      return scaled(arg);
    }
    if (arg is Vector3) {
      return transformed3(arg);
    }
    if (arg is Matrix4) {
      return multiplied(arg);
    }
    throw ArgumentError(arg);
  }

  /// Transform [arg] of type [Vector3] using the perspective transformation
  /// defined by [this].
  Vector3 perspectiveTransform(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    final double x = (_m4storage[0] * argStorage[0]) +
        (_m4storage[4] * argStorage[1]) +
        (_m4storage[8] * argStorage[2]) +
        _m4storage[12];
    final double y = (_m4storage[1] * argStorage[0]) +
        (_m4storage[5] * argStorage[1]) +
        (_m4storage[9] * argStorage[2]) +
        _m4storage[13];
    final double z = (_m4storage[2] * argStorage[0]) +
        (_m4storage[6] * argStorage[1]) +
        (_m4storage[10] * argStorage[2]) +
        _m4storage[14];
    final double w = 1.0 /
        ((_m4storage[3] * argStorage[0]) +
            (_m4storage[7] * argStorage[1]) +
            (_m4storage[11] * argStorage[2]) +
            _m4storage[15]);
    argStorage[0] = x * w;
    argStorage[1] = y * w;
    argStorage[2] = z * w;
    return arg;
  }

  bool isIdentity() =>
      _m4storage[0] == 1.0 // col 1
      &&
      _m4storage[1] == 0.0 &&
      _m4storage[2] == 0.0 &&
      _m4storage[3] == 0.0 &&
      _m4storage[4] == 0.0 // col 2
      &&
      _m4storage[5] == 1.0 &&
      _m4storage[6] == 0.0 &&
      _m4storage[7] == 0.0 &&
      _m4storage[8] == 0.0 // col 3
      &&
      _m4storage[9] == 0.0 &&
      _m4storage[10] == 1.0 &&
      _m4storage[11] == 0.0 &&
      _m4storage[12] == 0.0 // col 4
      &&
      _m4storage[13] == 0.0 &&
      _m4storage[14] == 0.0 &&
      _m4storage[15] == 1.0;

  /// Returns the translation vector from this homogeneous transformation matrix.
  Vector3 getTranslation() {
    final double z = _m4storage[14];
    final double y = _m4storage[13];
    final double x = _m4storage[12];
    return Vector3(x, y, z);
  }

  void rotate(Vector3 axis, double angle) {
    final double len = axis.length;
    final Float32List axisStorage = axis._v3storage;
    final double x = axisStorage[0] / len;
    final double y = axisStorage[1] / len;
    final double z = axisStorage[2] / len;
    final double c = math.cos(angle);
    final double s = math.sin(angle);
    final double C = 1.0 - c;
    final double m11 = x * x * C + c;
    final double m12 = x * y * C - z * s;
    final double m13 = x * z * C + y * s;
    final double m21 = y * x * C + z * s;
    final double m22 = y * y * C + c;
    final double m23 = y * z * C - x * s;
    final double m31 = z * x * C - y * s;
    final double m32 = z * y * C + x * s;
    final double m33 = z * z * C + c;
    final double t1 =
        _m4storage[0] * m11 + _m4storage[4] * m21 + _m4storage[8] * m31;
    final double t2 =
        _m4storage[1] * m11 + _m4storage[5] * m21 + _m4storage[9] * m31;
    final double t3 =
        _m4storage[2] * m11 + _m4storage[6] * m21 + _m4storage[10] * m31;
    final double t4 =
        _m4storage[3] * m11 + _m4storage[7] * m21 + _m4storage[11] * m31;
    final double t5 =
        _m4storage[0] * m12 + _m4storage[4] * m22 + _m4storage[8] * m32;
    final double t6 =
        _m4storage[1] * m12 + _m4storage[5] * m22 + _m4storage[9] * m32;
    final double t7 =
        _m4storage[2] * m12 + _m4storage[6] * m22 + _m4storage[10] * m32;
    final double t8 =
        _m4storage[3] * m12 + _m4storage[7] * m22 + _m4storage[11] * m32;
    final double t9 =
        _m4storage[0] * m13 + _m4storage[4] * m23 + _m4storage[8] * m33;
    final double t10 =
        _m4storage[1] * m13 + _m4storage[5] * m23 + _m4storage[9] * m33;
    final double t11 =
        _m4storage[2] * m13 + _m4storage[6] * m23 + _m4storage[10] * m33;
    final double t12 =
        _m4storage[3] * m13 + _m4storage[7] * m23 + _m4storage[11] * m33;
    _m4storage[0] = t1;
    _m4storage[1] = t2;
    _m4storage[2] = t3;
    _m4storage[3] = t4;
    _m4storage[4] = t5;
    _m4storage[5] = t6;
    _m4storage[6] = t7;
    _m4storage[7] = t8;
    _m4storage[8] = t9;
    _m4storage[9] = t10;
    _m4storage[10] = t11;
    _m4storage[11] = t12;
  }

  void rotateZ(double angle) {
    final double cosAngle = math.cos(angle);
    final double sinAngle = math.sin(angle);
    final double t1 = _m4storage[0] * cosAngle + _m4storage[4] * sinAngle;
    final double t2 = _m4storage[1] * cosAngle + _m4storage[5] * sinAngle;
    final double t3 = _m4storage[2] * cosAngle + _m4storage[6] * sinAngle;
    final double t4 = _m4storage[3] * cosAngle + _m4storage[7] * sinAngle;
    final double t5 = _m4storage[0] * -sinAngle + _m4storage[4] * cosAngle;
    final double t6 = _m4storage[1] * -sinAngle + _m4storage[5] * cosAngle;
    final double t7 = _m4storage[2] * -sinAngle + _m4storage[6] * cosAngle;
    final double t8 = _m4storage[3] * -sinAngle + _m4storage[7] * cosAngle;
    _m4storage[0] = t1;
    _m4storage[1] = t2;
    _m4storage[2] = t3;
    _m4storage[3] = t4;
    _m4storage[4] = t5;
    _m4storage[5] = t6;
    _m4storage[6] = t7;
    _m4storage[7] = t8;
  }

  /// Sets the translation vector in this homogeneous transformation matrix.
  void setTranslation(Vector3 t) {
    final Float32List tStorage = t._v3storage;
    final double z = tStorage[2];
    final double y = tStorage[1];
    final double x = tStorage[0];
    _m4storage[14] = z;
    _m4storage[13] = y;
    _m4storage[12] = x;
  }

  /// Sets the translation vector in this homogeneous transformation matrix.
  void setTranslationRaw(double x, double y, double z) {
    _m4storage[14] = z;
    _m4storage[13] = y;
    _m4storage[12] = x;
  }

  /// Transposes just the upper 3x3 rotation matrix.
  void transposeRotation() {
    double temp;
    temp = _m4storage[1];
    _m4storage[1] = _m4storage[4];
    _m4storage[4] = temp;
    temp = _m4storage[2];
    _m4storage[2] = _m4storage[8];
    _m4storage[8] = temp;
    temp = _m4storage[4];
    _m4storage[4] = _m4storage[1];
    _m4storage[1] = temp;
    temp = _m4storage[6];
    _m4storage[6] = _m4storage[9];
    _m4storage[9] = temp;
    temp = _m4storage[8];
    _m4storage[8] = _m4storage[2];
    _m4storage[2] = temp;
    temp = _m4storage[9];
    _m4storage[9] = _m4storage[6];
    _m4storage[6] = temp;
  }

  /// Invert [this].
  double invert() => copyInverse(this);

  /// Set this matrix to be the inverse of [arg]
  double copyInverse(Matrix4 arg) {
    final Float32List argStorage = arg._m4storage;
    final double a00 = argStorage[0];
    final double a01 = argStorage[1];
    final double a02 = argStorage[2];
    final double a03 = argStorage[3];
    final double a10 = argStorage[4];
    final double a11 = argStorage[5];
    final double a12 = argStorage[6];
    final double a13 = argStorage[7];
    final double a20 = argStorage[8];
    final double a21 = argStorage[9];
    final double a22 = argStorage[10];
    final double a23 = argStorage[11];
    final double a30 = argStorage[12];
    final double a31 = argStorage[13];
    final double a32 = argStorage[14];
    final double a33 = argStorage[15];
    final double b00 = a00 * a11 - a01 * a10;
    final double b01 = a00 * a12 - a02 * a10;
    final double b02 = a00 * a13 - a03 * a10;
    final double b03 = a01 * a12 - a02 * a11;
    final double b04 = a01 * a13 - a03 * a11;
    final double b05 = a02 * a13 - a03 * a12;
    final double b06 = a20 * a31 - a21 * a30;
    final double b07 = a20 * a32 - a22 * a30;
    final double b08 = a20 * a33 - a23 * a30;
    final double b09 = a21 * a32 - a22 * a31;
    final double b10 = a21 * a33 - a23 * a31;
    final double b11 = a22 * a33 - a23 * a32;
    final double det =
        b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
    if (det == 0.0) {
      setFrom(arg);
      return 0.0;
    }
    final double invDet = 1.0 / det;
    _m4storage[0] = (a11 * b11 - a12 * b10 + a13 * b09) * invDet;
    _m4storage[1] = (-a01 * b11 + a02 * b10 - a03 * b09) * invDet;
    _m4storage[2] = (a31 * b05 - a32 * b04 + a33 * b03) * invDet;
    _m4storage[3] = (-a21 * b05 + a22 * b04 - a23 * b03) * invDet;
    _m4storage[4] = (-a10 * b11 + a12 * b08 - a13 * b07) * invDet;
    _m4storage[5] = (a00 * b11 - a02 * b08 + a03 * b07) * invDet;
    _m4storage[6] = (-a30 * b05 + a32 * b02 - a33 * b01) * invDet;
    _m4storage[7] = (a20 * b05 - a22 * b02 + a23 * b01) * invDet;
    _m4storage[8] = (a10 * b10 - a11 * b08 + a13 * b06) * invDet;
    _m4storage[9] = (-a00 * b10 + a01 * b08 - a03 * b06) * invDet;
    _m4storage[10] = (a30 * b04 - a31 * b02 + a33 * b00) * invDet;
    _m4storage[11] = (-a20 * b04 + a21 * b02 - a23 * b00) * invDet;
    _m4storage[12] = (-a10 * b09 + a11 * b07 - a12 * b06) * invDet;
    _m4storage[13] = (a00 * b09 - a01 * b07 + a02 * b06) * invDet;
    _m4storage[14] = (-a30 * b03 + a31 * b01 - a32 * b00) * invDet;
    _m4storage[15] = (a20 * b03 - a21 * b01 + a22 * b00) * invDet;
    return det;
  }

  double invertRotation() {
    final double det = determinant();
    if (det == 0.0) {
      return 0.0;
    }
    final double invDet = 1.0 / det;
    double ix;
    double iy;
    double iz;
    double jx;
    double jy;
    double jz;
    double kx;
    double ky;
    double kz;
    ix = invDet *
        (_m4storage[5] * _m4storage[10] - _m4storage[6] * _m4storage[9]);
    iy = invDet *
        (_m4storage[2] * _m4storage[9] - _m4storage[1] * _m4storage[10]);
    iz = invDet *
        (_m4storage[1] * _m4storage[6] - _m4storage[2] * _m4storage[5]);
    jx = invDet *
        (_m4storage[6] * _m4storage[8] - _m4storage[4] * _m4storage[10]);
    jy = invDet *
        (_m4storage[0] * _m4storage[10] - _m4storage[2] * _m4storage[8]);
    jz = invDet *
        (_m4storage[2] * _m4storage[4] - _m4storage[0] * _m4storage[6]);
    kx = invDet *
        (_m4storage[4] * _m4storage[9] - _m4storage[5] * _m4storage[8]);
    ky = invDet *
        (_m4storage[1] * _m4storage[8] - _m4storage[0] * _m4storage[9]);
    kz = invDet *
        (_m4storage[0] * _m4storage[5] - _m4storage[1] * _m4storage[4]);
    _m4storage[0] = ix;
    _m4storage[1] = iy;
    _m4storage[2] = iz;
    _m4storage[4] = jx;
    _m4storage[5] = jy;
    _m4storage[6] = jz;
    _m4storage[8] = kx;
    _m4storage[9] = ky;
    _m4storage[10] = kz;
    return det;
  }

  /// Sets the upper 3x3 to a rotation of [radians] around X
  void setRotationX(double radians) {
    final double c = math.cos(radians);
    final double s = math.sin(radians);
    _m4storage[0] = 1.0;
    _m4storage[1] = 0.0;
    _m4storage[2] = 0.0;
    _m4storage[4] = 0.0;
    _m4storage[5] = c;
    _m4storage[6] = s;
    _m4storage[8] = 0.0;
    _m4storage[9] = -s;
    _m4storage[10] = c;
    _m4storage[3] = 0.0;
    _m4storage[7] = 0.0;
    _m4storage[11] = 0.0;
  }

  /// Sets the upper 3x3 to a rotation of [radians] around Y
  void setRotationY(double radians) {
    final double c = math.cos(radians);
    final double s = math.sin(radians);
    _m4storage[0] = c;
    _m4storage[1] = 0.0;
    _m4storage[2] = -s;
    _m4storage[4] = 0.0;
    _m4storage[5] = 1.0;
    _m4storage[6] = 0.0;
    _m4storage[8] = s;
    _m4storage[9] = 0.0;
    _m4storage[10] = c;
    _m4storage[3] = 0.0;
    _m4storage[7] = 0.0;
    _m4storage[11] = 0.0;
  }

  /// Sets the upper 3x3 to a rotation of [radians] around Z
  void setRotationZ(double radians) {
    final double c = math.cos(radians);
    final double s = math.sin(radians);
    _m4storage[0] = c;
    _m4storage[1] = s;
    _m4storage[2] = 0.0;
    _m4storage[4] = -s;
    _m4storage[5] = c;
    _m4storage[6] = 0.0;
    _m4storage[8] = 0.0;
    _m4storage[9] = 0.0;
    _m4storage[10] = 1.0;
    _m4storage[3] = 0.0;
    _m4storage[7] = 0.0;
    _m4storage[11] = 0.0;
  }

  /// Multiply [this] by [arg].
  void multiply(Matrix4 arg) {
    final double m00 = _m4storage[0];
    final double m01 = _m4storage[4];
    final double m02 = _m4storage[8];
    final double m03 = _m4storage[12];
    final double m10 = _m4storage[1];
    final double m11 = _m4storage[5];
    final double m12 = _m4storage[9];
    final double m13 = _m4storage[13];
    final double m20 = _m4storage[2];
    final double m21 = _m4storage[6];
    final double m22 = _m4storage[10];
    final double m23 = _m4storage[14];
    final double m30 = _m4storage[3];
    final double m31 = _m4storage[7];
    final double m32 = _m4storage[11];
    final double m33 = _m4storage[15];
    final Float32List argStorage = arg._m4storage;
    final double n00 = argStorage[0];
    final double n01 = argStorage[4];
    final double n02 = argStorage[8];
    final double n03 = argStorage[12];
    final double n10 = argStorage[1];
    final double n11 = argStorage[5];
    final double n12 = argStorage[9];
    final double n13 = argStorage[13];
    final double n20 = argStorage[2];
    final double n21 = argStorage[6];
    final double n22 = argStorage[10];
    final double n23 = argStorage[14];
    final double n30 = argStorage[3];
    final double n31 = argStorage[7];
    final double n32 = argStorage[11];
    final double n33 = argStorage[15];
    _m4storage[0] = (m00 * n00) + (m01 * n10) + (m02 * n20) + (m03 * n30);
    _m4storage[4] = (m00 * n01) + (m01 * n11) + (m02 * n21) + (m03 * n31);
    _m4storage[8] = (m00 * n02) + (m01 * n12) + (m02 * n22) + (m03 * n32);
    _m4storage[12] = (m00 * n03) + (m01 * n13) + (m02 * n23) + (m03 * n33);
    _m4storage[1] = (m10 * n00) + (m11 * n10) + (m12 * n20) + (m13 * n30);
    _m4storage[5] = (m10 * n01) + (m11 * n11) + (m12 * n21) + (m13 * n31);
    _m4storage[9] = (m10 * n02) + (m11 * n12) + (m12 * n22) + (m13 * n32);
    _m4storage[13] = (m10 * n03) + (m11 * n13) + (m12 * n23) + (m13 * n33);
    _m4storage[2] = (m20 * n00) + (m21 * n10) + (m22 * n20) + (m23 * n30);
    _m4storage[6] = (m20 * n01) + (m21 * n11) + (m22 * n21) + (m23 * n31);
    _m4storage[10] = (m20 * n02) + (m21 * n12) + (m22 * n22) + (m23 * n32);
    _m4storage[14] = (m20 * n03) + (m21 * n13) + (m22 * n23) + (m23 * n33);
    _m4storage[3] = (m30 * n00) + (m31 * n10) + (m32 * n20) + (m33 * n30);
    _m4storage[7] = (m30 * n01) + (m31 * n11) + (m32 * n21) + (m33 * n31);
    _m4storage[11] = (m30 * n02) + (m31 * n12) + (m32 * n22) + (m33 * n32);
    _m4storage[15] = (m30 * n03) + (m31 * n13) + (m32 * n23) + (m33 * n33);
  }

  /// Multiply a copy of [this] with [arg].
  Matrix4 multiplied(Matrix4 arg) => clone()..multiply(arg);

  /// Multiply a transposed [this] with [arg].
  void transposeMultiply(Matrix4 arg) {
    final double m00 = _m4storage[0];
    final double m01 = _m4storage[1];
    final double m02 = _m4storage[2];
    final double m03 = _m4storage[3];
    final double m10 = _m4storage[4];
    final double m11 = _m4storage[5];
    final double m12 = _m4storage[6];
    final double m13 = _m4storage[7];
    final double m20 = _m4storage[8];
    final double m21 = _m4storage[9];
    final double m22 = _m4storage[10];
    final double m23 = _m4storage[11];
    final double m30 = _m4storage[12];
    final double m31 = _m4storage[13];
    final double m32 = _m4storage[14];
    final double m33 = _m4storage[15];
    final Float32List argStorage = arg._m4storage;
    _m4storage[0] = (m00 * argStorage[0]) +
        (m01 * argStorage[1]) +
        (m02 * argStorage[2]) +
        (m03 * argStorage[3]);
    _m4storage[4] = (m00 * argStorage[4]) +
        (m01 * argStorage[5]) +
        (m02 * argStorage[6]) +
        (m03 * argStorage[7]);
    _m4storage[8] = (m00 * argStorage[8]) +
        (m01 * argStorage[9]) +
        (m02 * argStorage[10]) +
        (m03 * argStorage[11]);
    _m4storage[12] = (m00 * argStorage[12]) +
        (m01 * argStorage[13]) +
        (m02 * argStorage[14]) +
        (m03 * argStorage[15]);
    _m4storage[1] = (m10 * argStorage[0]) +
        (m11 * argStorage[1]) +
        (m12 * argStorage[2]) +
        (m13 * argStorage[3]);
    _m4storage[5] = (m10 * argStorage[4]) +
        (m11 * argStorage[5]) +
        (m12 * argStorage[6]) +
        (m13 * argStorage[7]);
    _m4storage[9] = (m10 * argStorage[8]) +
        (m11 * argStorage[9]) +
        (m12 * argStorage[10]) +
        (m13 * argStorage[11]);
    _m4storage[13] = (m10 * argStorage[12]) +
        (m11 * argStorage[13]) +
        (m12 * argStorage[14]) +
        (m13 * argStorage[15]);
    _m4storage[2] = (m20 * argStorage[0]) +
        (m21 * argStorage[1]) +
        (m22 * argStorage[2]) +
        (m23 * argStorage[3]);
    _m4storage[6] = (m20 * argStorage[4]) +
        (m21 * argStorage[5]) +
        (m22 * argStorage[6]) +
        (m23 * argStorage[7]);
    _m4storage[10] = (m20 * argStorage[8]) +
        (m21 * argStorage[9]) +
        (m22 * argStorage[10]) +
        (m23 * argStorage[11]);
    _m4storage[14] = (m20 * argStorage[12]) +
        (m21 * argStorage[13]) +
        (m22 * argStorage[14]) +
        (m23 * argStorage[15]);
    _m4storage[3] = (m30 * argStorage[0]) +
        (m31 * argStorage[1]) +
        (m32 * argStorage[2]) +
        (m33 * argStorage[3]);
    _m4storage[7] = (m30 * argStorage[4]) +
        (m31 * argStorage[5]) +
        (m32 * argStorage[6]) +
        (m33 * argStorage[7]);
    _m4storage[11] = (m30 * argStorage[8]) +
        (m31 * argStorage[9]) +
        (m32 * argStorage[10]) +
        (m33 * argStorage[11]);
    _m4storage[15] = (m30 * argStorage[12]) +
        (m31 * argStorage[13]) +
        (m32 * argStorage[14]) +
        (m33 * argStorage[15]);
  }

  /// Multiply [this] with a transposed [arg].
  void multiplyTranspose(Matrix4 arg) {
    final double m00 = _m4storage[0];
    final double m01 = _m4storage[4];
    final double m02 = _m4storage[8];
    final double m03 = _m4storage[12];
    final double m10 = _m4storage[1];
    final double m11 = _m4storage[5];
    final double m12 = _m4storage[9];
    final double m13 = _m4storage[13];
    final double m20 = _m4storage[2];
    final double m21 = _m4storage[6];
    final double m22 = _m4storage[10];
    final double m23 = _m4storage[14];
    final double m30 = _m4storage[3];
    final double m31 = _m4storage[7];
    final double m32 = _m4storage[11];
    final double m33 = _m4storage[15];
    final Float32List argStorage = arg._m4storage;
    _m4storage[0] = (m00 * argStorage[0]) +
        (m01 * argStorage[4]) +
        (m02 * argStorage[8]) +
        (m03 * argStorage[12]);
    _m4storage[4] = (m00 * argStorage[1]) +
        (m01 * argStorage[5]) +
        (m02 * argStorage[9]) +
        (m03 * argStorage[13]);
    _m4storage[8] = (m00 * argStorage[2]) +
        (m01 * argStorage[6]) +
        (m02 * argStorage[10]) +
        (m03 * argStorage[14]);
    _m4storage[12] = (m00 * argStorage[3]) +
        (m01 * argStorage[7]) +
        (m02 * argStorage[11]) +
        (m03 * argStorage[15]);
    _m4storage[1] = (m10 * argStorage[0]) +
        (m11 * argStorage[4]) +
        (m12 * argStorage[8]) +
        (m13 * argStorage[12]);
    _m4storage[5] = (m10 * argStorage[1]) +
        (m11 * argStorage[5]) +
        (m12 * argStorage[9]) +
        (m13 * argStorage[13]);
    _m4storage[9] = (m10 * argStorage[2]) +
        (m11 * argStorage[6]) +
        (m12 * argStorage[10]) +
        (m13 * argStorage[14]);
    _m4storage[13] = (m10 * argStorage[3]) +
        (m11 * argStorage[7]) +
        (m12 * argStorage[11]) +
        (m13 * argStorage[15]);
    _m4storage[2] = (m20 * argStorage[0]) +
        (m21 * argStorage[4]) +
        (m22 * argStorage[8]) +
        (m23 * argStorage[12]);
    _m4storage[6] = (m20 * argStorage[1]) +
        (m21 * argStorage[5]) +
        (m22 * argStorage[9]) +
        (m23 * argStorage[13]);
    _m4storage[10] = (m20 * argStorage[2]) +
        (m21 * argStorage[6]) +
        (m22 * argStorage[10]) +
        (m23 * argStorage[14]);
    _m4storage[14] = (m20 * argStorage[3]) +
        (m21 * argStorage[7]) +
        (m22 * argStorage[11]) +
        (m23 * argStorage[15]);
    _m4storage[3] = (m30 * argStorage[0]) +
        (m31 * argStorage[4]) +
        (m32 * argStorage[8]) +
        (m33 * argStorage[12]);
    _m4storage[7] = (m30 * argStorage[1]) +
        (m31 * argStorage[5]) +
        (m32 * argStorage[9]) +
        (m33 * argStorage[13]);
    _m4storage[11] = (m30 * argStorage[2]) +
        (m31 * argStorage[6]) +
        (m32 * argStorage[10]) +
        (m33 * argStorage[14]);
    _m4storage[15] = (m30 * argStorage[3]) +
        (m31 * argStorage[7]) +
        (m32 * argStorage[11]) +
        (m33 * argStorage[15]);
  }

  /// Rotate [arg] of type [Vector3] using the rotation defined by [this].
  Vector3 rotate3(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    final double x = (_m4storage[0] * argStorage[0]) +
        (_m4storage[4] * argStorage[1]) +
        (_m4storage[8] * argStorage[2]);
    final double y = (_m4storage[1] * argStorage[0]) +
        (_m4storage[5] * argStorage[1]) +
        (_m4storage[9] * argStorage[2]);
    final double z = (_m4storage[2] * argStorage[0]) +
        (_m4storage[6] * argStorage[1]) +
        (_m4storage[10] * argStorage[2]);
    argStorage[0] = x;
    argStorage[1] = y;
    argStorage[2] = z;
    return arg;
  }

  /// Rotate a copy of [arg] of type [Vector3] using the rotation defined by
  /// [this]. If a [out] parameter is supplied, the copy is stored in [out].
  Vector3 rotated3(Vector3 arg, [Vector3 out]) {
    if (out == null) {
      out = Vector3.copy(arg);
    } else {
      out.setFrom(arg);
    }
    return rotate3(out);
  }

  /// Transform [arg] of type [Vector3] using the transformation defined by
  /// [this].
  Vector3 transform3(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    final double x = (_m4storage[0] * argStorage[0]) +
        (_m4storage[4] * argStorage[1]) +
        (_m4storage[8] * argStorage[2]) +
        _m4storage[12];
    final double y = (_m4storage[1] * argStorage[0]) +
        (_m4storage[5] * argStorage[1]) +
        (_m4storage[9] * argStorage[2]) +
        _m4storage[13];
    final double z = (_m4storage[2] * argStorage[0]) +
        (_m4storage[6] * argStorage[1]) +
        (_m4storage[10] * argStorage[2]) +
        _m4storage[14];
    argStorage[0] = x;
    argStorage[1] = y;
    argStorage[2] = z;
    return arg;
  }

  /// Transform a copy of [arg] of type [Vector3] using the transformation
  /// defined by [this]. If a [out] parameter is supplied, the copy is stored in
  /// [out].
  Vector3 transformed3(Vector3 arg, [Vector3 out]) {
    if (out == null) {
      out = Vector3.copy(arg);
    } else {
      out.setFrom(arg);
    }
    return transform3(out);
  }

  /// Copies [this] into [array] starting at [offset].
  void copyIntoArray(List<num> array, [int offset = 0]) {
    final int i = offset;
    array[i + 15] = _m4storage[15];
    array[i + 14] = _m4storage[14];
    array[i + 13] = _m4storage[13];
    array[i + 12] = _m4storage[12];
    array[i + 11] = _m4storage[11];
    array[i + 10] = _m4storage[10];
    array[i + 9] = _m4storage[9];
    array[i + 8] = _m4storage[8];
    array[i + 7] = _m4storage[7];
    array[i + 6] = _m4storage[6];
    array[i + 5] = _m4storage[5];
    array[i + 4] = _m4storage[4];
    array[i + 3] = _m4storage[3];
    array[i + 2] = _m4storage[2];
    array[i + 1] = _m4storage[1];
    array[i + 0] = _m4storage[0];
  }

  /// Copies elements from [array] into [this] starting at [offset].
  void copyFromArray(List<double> array, [int offset = 0]) {
    final int i = offset;
    _m4storage[15] = array[i + 15];
    _m4storage[14] = array[i + 14];
    _m4storage[13] = array[i + 13];
    _m4storage[12] = array[i + 12];
    _m4storage[11] = array[i + 11];
    _m4storage[10] = array[i + 10];
    _m4storage[9] = array[i + 9];
    _m4storage[8] = array[i + 8];
    _m4storage[7] = array[i + 7];
    _m4storage[6] = array[i + 6];
    _m4storage[5] = array[i + 5];
    _m4storage[4] = array[i + 4];
    _m4storage[3] = array[i + 3];
    _m4storage[2] = array[i + 2];
    _m4storage[1] = array[i + 1];
    _m4storage[0] = array[i + 0];
  }

  /// Converts this matrix to a [Float64List].
  ///
  /// Generally we try to stick with 32-bit floats inside the engine code
  /// because it's faster (see [toMatrix32]). However, this method is handy
  /// in tests that use the public `dart:ui` surface.
  ///
  /// This method is not optimized, but also is not meant to be fast, only
  /// convenient.
  Float64List toFloat64() {
    return Float64List.fromList(_m4storage);
  }
}

/// 3D column vector.
class Vector3 {
  final Float32List _v3storage;

  /// The components of the vector.
  Float32List get storage => _v3storage;

  /// Set the values of [result] to the minimum of [a] and [b] for each line.
  static void min(Vector3 a, Vector3 b, Vector3 result) {
    result
      ..x = math.min(a.x, b.x)
      ..y = math.min(a.y, b.y)
      ..z = math.min(a.z, b.z);
  }

  /// Set the values of [result] to the maximum of [a] and [b] for each line.
  static void max(Vector3 a, Vector3 b, Vector3 result) {
    result
      ..x = math.max(a.x, b.x)
      ..y = math.max(a.y, b.y)
      ..z = math.max(a.z, b.z);
  }

  /// Interpolate between [min] and [max] with the amount of [a] using a linear
  /// interpolation and store the values in [result].
  static void mix(Vector3 min, Vector3 max, double a, Vector3 result) {
    result
      ..x = min.x + a * (max.x - min.x)
      ..y = min.y + a * (max.y - min.y)
      ..z = min.z + a * (max.z - min.z);
  }

  /// Construct a new vector with the specified values.
  factory Vector3(double x, double y, double z) =>
      Vector3.zero()..setValues(x, y, z);

  /// Zero vector.
  Vector3.zero() : _v3storage = Float32List(3);

  /// Splat [value] into all lanes of the vector.
  factory Vector3.all(double value) => Vector3.zero()..splat(value);

  /// Copy of [other].
  factory Vector3.copy(Vector3 other) => Vector3.zero()..setFrom(other);

  /// Constructs Vector3 with given Float32List as [storage].
  Vector3.fromFloat32List(this._v3storage);

  /// Constructs Vector3 with a [storage] that views given [buffer] starting at
  /// [offset]. [offset] has to be multiple of [Float32List.bytesPerElement].
  Vector3.fromBuffer(ByteBuffer buffer, int offset)
      : _v3storage = Float32List.view(buffer, offset, 3);

  /// Generate random vector in the range (0, 0, 0) to (1, 1, 1). You can
  /// optionally pass your own random number generator.
  factory Vector3.random([math.Random rng]) {
    rng ??= math.Random();
    return Vector3(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
  }

  /// Set the values of the vector.
  void setValues(double x, double y, double z) {
    _v3storage[0] = x;
    _v3storage[1] = y;
    _v3storage[2] = z;
  }

  /// Zero vector.
  void setZero() {
    _v3storage[2] = 0.0;
    _v3storage[1] = 0.0;
    _v3storage[0] = 0.0;
  }

  /// Set the values by copying them from [other].
  void setFrom(Vector3 other) {
    final Float32List otherStorage = other._v3storage;
    _v3storage[0] = otherStorage[0];
    _v3storage[1] = otherStorage[1];
    _v3storage[2] = otherStorage[2];
  }

  /// Splat [arg] into all lanes of the vector.
  void splat(double arg) {
    _v3storage[2] = arg;
    _v3storage[1] = arg;
    _v3storage[0] = arg;
  }

  /// Access the component of the vector at the index [i].
  double operator [](int i) => _v3storage[i];

  /// Set the component of the vector at the index [i].
  void operator []=(int i, double v) {
    _v3storage[i] = v;
  }

  /// Set the length of the vector. A negative [value] will change the vectors
  /// orientation and a [value] of zero will set the vector to zero.
  set length(double value) {
    if (value == 0.0) {
      setZero();
    } else {
      double l = length;
      if (l == 0.0) {
        return;
      }
      l = value / l;
      _v3storage[0] *= l;
      _v3storage[1] *= l;
      _v3storage[2] *= l;
    }
  }

  /// Length.
  double get length => math.sqrt(length2);

  /// Length squared.
  double get length2 {
    double sum;
    sum = _v3storage[0] * _v3storage[0];
    sum += _v3storage[1] * _v3storage[1];
    sum += _v3storage[2] * _v3storage[2];
    return sum;
  }

  /// Normalizes [this].
  double normalize() {
    final double l = length;
    if (l == 0.0) {
      return 0.0;
    }
    final double d = 1.0 / l;
    _v3storage[0] *= d;
    _v3storage[1] *= d;
    _v3storage[2] *= d;
    return l;
  }

  /// Normalizes copy of [this].
  Vector3 normalized() => Vector3.copy(this)..normalize();

  /// Normalize vector into [out].
  Vector3 normalizeInto(Vector3 out) {
    out
      ..setFrom(this)
      ..normalize();
    return out;
  }

  /// Distance from [this] to [arg]
  double distanceTo(Vector3 arg) => math.sqrt(distanceToSquared(arg));

  /// Squared distance from [this] to [arg]
  double distanceToSquared(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    final double dx = _v3storage[0] - argStorage[0];
    final double dy = _v3storage[1] - argStorage[1];
    final double dz = _v3storage[2] - argStorage[2];

    return dx * dx + dy * dy + dz * dz;
  }

  /// Returns the angle between [this] vector and [other] in radians.
  double angleTo(Vector3 other) {
    final Float32List otherStorage = other._v3storage;
    if (_v3storage[0] == otherStorage[0] &&
        _v3storage[1] == otherStorage[1] &&
        _v3storage[2] == otherStorage[2]) {
      return 0.0;
    }

    final double d = dot(other) / (length * other.length);

    return math.acos(d.clamp(-1.0, 1.0));
  }

  /// Inner product.
  double dot(Vector3 other) {
    final Float32List otherStorage = other._v3storage;
    double sum;
    sum = _v3storage[0] * otherStorage[0];
    sum += _v3storage[1] * otherStorage[1];
    sum += _v3storage[2] * otherStorage[2];
    return sum;
  }

  /// Projects [this] using the projection matrix [arg]
  void applyProjection(Matrix4 arg) {
    final Float32List argStorage = arg.storage;
    final double x = _v3storage[0];
    final double y = _v3storage[1];
    final double z = _v3storage[2];
    final double d = 1.0 /
        (argStorage[3] * x +
            argStorage[7] * y +
            argStorage[11] * z +
            argStorage[15]);
    _v3storage[0] = (argStorage[0] * x +
            argStorage[4] * y +
            argStorage[8] * z +
            argStorage[12]) *
        d;
    _v3storage[1] = (argStorage[1] * x +
            argStorage[5] * y +
            argStorage[9] * z +
            argStorage[13]) *
        d;
    _v3storage[2] = (argStorage[2] * x +
            argStorage[6] * y +
            argStorage[10] * z +
            argStorage[14]) *
        d;
  }

  /// True if any component is infinite.
  bool get isInfinite {
    bool isInfinite = false;
    isInfinite = isInfinite || _v3storage[0].isInfinite;
    isInfinite = isInfinite || _v3storage[1].isInfinite;
    isInfinite = isInfinite || _v3storage[2].isInfinite;
    return isInfinite;
  }

  /// True if any component is NaN.
  bool get isNaN {
    bool isNan = false;
    isNan = isNan || _v3storage[0].isNaN;
    isNan = isNan || _v3storage[1].isNaN;
    isNan = isNan || _v3storage[2].isNaN;
    return isNan;
  }

  /// Add [arg] to [this].
  void add(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] + argStorage[0];
    _v3storage[1] = _v3storage[1] + argStorage[1];
    _v3storage[2] = _v3storage[2] + argStorage[2];
  }

  /// Add [arg] scaled by [factor] to [this].
  void addScaled(Vector3 arg, double factor) {
    final Float32List argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] + argStorage[0] * factor;
    _v3storage[1] = _v3storage[1] + argStorage[1] * factor;
    _v3storage[2] = _v3storage[2] + argStorage[2] * factor;
  }

  /// Subtract [arg] from [this].
  void sub(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] - argStorage[0];
    _v3storage[1] = _v3storage[1] - argStorage[1];
    _v3storage[2] = _v3storage[2] - argStorage[2];
  }

  /// Multiply entries in [this] with entries in [arg].
  void multiply(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] * argStorage[0];
    _v3storage[1] = _v3storage[1] * argStorage[1];
    _v3storage[2] = _v3storage[2] * argStorage[2];
  }

  /// Divide entries in [this] with entries in [arg].
  void divide(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] / argStorage[0];
    _v3storage[1] = _v3storage[1] / argStorage[1];
    _v3storage[2] = _v3storage[2] / argStorage[2];
  }

  /// Scale [this].
  void scale(double arg) {
    _v3storage[2] = _v3storage[2] * arg;
    _v3storage[1] = _v3storage[1] * arg;
    _v3storage[0] = _v3storage[0] * arg;
  }

  /// Create a copy of [this] and scale it by [arg].
  Vector3 scaled(double arg) => clone()..scale(arg);

  /// Clone of [this].
  Vector3 clone() => Vector3.copy(this);

  /// Copy [this] into [arg].
  Vector3 copyInto(Vector3 arg) {
    final Float32List argStorage = arg._v3storage;
    argStorage[0] = _v3storage[0];
    argStorage[1] = _v3storage[1];
    argStorage[2] = _v3storage[2];
    return arg;
  }

  /// Copies [this] into [array] starting at [offset].
  void copyIntoArray(List<double> array, [int offset = 0]) {
    array[offset + 2] = _v3storage[2];
    array[offset + 1] = _v3storage[1];
    array[offset + 0] = _v3storage[0];
  }

  set x(double arg) => _v3storage[0] = arg;
  set y(double arg) => _v3storage[1] = arg;
  set z(double arg) => _v3storage[2] = arg;

  double get x => _v3storage[0];
  double get y => _v3storage[1];
  double get z => _v3storage[2];
}

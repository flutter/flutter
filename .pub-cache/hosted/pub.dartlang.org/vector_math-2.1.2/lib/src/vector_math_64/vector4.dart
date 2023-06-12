// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_64;

/// 4D column vector.
class Vector4 implements Vector {
  final Float64List _v4storage;

  /// Set the values of [result] to the minimum of [a] and [b] for each line.
  static void min(Vector4 a, Vector4 b, Vector4 result) {
    result
      ..x = math.min(a.x, b.x)
      ..y = math.min(a.y, b.y)
      ..z = math.min(a.z, b.z)
      ..w = math.min(a.w, b.w);
  }

  /// Set the values of [result] to the maximum of [a] and [b] for each line.
  static void max(Vector4 a, Vector4 b, Vector4 result) {
    result
      ..x = math.max(a.x, b.x)
      ..y = math.max(a.y, b.y)
      ..z = math.max(a.z, b.z)
      ..w = math.max(a.w, b.w);
  }

  /// Interpolate between [min] and [max] with the amount of [a] using a linear
  /// interpolation and store the values in [result].
  static void mix(Vector4 min, Vector4 max, double a, Vector4 result) {
    result
      ..x = min.x + a * (max.x - min.x)
      ..y = min.y + a * (max.y - min.y)
      ..z = min.z + a * (max.z - min.z)
      ..w = min.w + a * (max.w - min.w);
  }

  /// The components of the vector.
  @override
  Float64List get storage => _v4storage;

  /// Construct a new vector with the specified values.
  factory Vector4(double x, double y, double z, double w) =>
      Vector4.zero()..setValues(x, y, z, w);

  /// Initialized with values from [array] starting at [offset].
  factory Vector4.array(List<double> array, [int offset = 0]) =>
      Vector4.zero()..copyFromArray(array, offset);

  /// Zero vector.
  Vector4.zero() : _v4storage = Float64List(4);

  /// Constructs the identity vector.
  factory Vector4.identity() => Vector4.zero()..setIdentity();

  /// Splat [value] into all lanes of the vector.
  factory Vector4.all(double value) => Vector4.zero()..splat(value);

  /// Copy of [other].
  factory Vector4.copy(Vector4 other) => Vector4.zero()..setFrom(other);

  /// Constructs Vector4 with given Float64List as [storage].
  Vector4.fromFloat64List(this._v4storage);

  /// Constructs Vector4 with a [storage] that views given [buffer] starting at
  /// [offset]. [offset] has to be multiple of [Float64List.bytesPerElement].
  Vector4.fromBuffer(ByteBuffer buffer, int offset)
      : _v4storage = Float64List.view(buffer, offset, 4);

  /// Generate random vector in the range (0, 0, 0, 0) to (1, 1, 1, 1). You can
  /// optionally pass your own random number generator.
  factory Vector4.random([math.Random? rng]) {
    rng ??= math.Random();
    return Vector4(
        rng.nextDouble(), rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
  }

  /// Set the values of the vector.
  void setValues(double x_, double y_, double z_, double w_) {
    _v4storage[3] = w_;
    _v4storage[2] = z_;
    _v4storage[1] = y_;
    _v4storage[0] = x_;
  }

  /// Zero the vector.
  void setZero() {
    _v4storage[0] = 0.0;
    _v4storage[1] = 0.0;
    _v4storage[2] = 0.0;
    _v4storage[3] = 0.0;
  }

  /// Set to the identity vector.
  void setIdentity() {
    _v4storage[0] = 0.0;
    _v4storage[1] = 0.0;
    _v4storage[2] = 0.0;
    _v4storage[3] = 1.0;
  }

  /// Set the values by copying them from [other].
  void setFrom(Vector4 other) {
    final otherStorage = other._v4storage;
    _v4storage[3] = otherStorage[3];
    _v4storage[2] = otherStorage[2];
    _v4storage[1] = otherStorage[1];
    _v4storage[0] = otherStorage[0];
  }

  /// Splat [arg] into all lanes of the vector.
  void splat(double arg) {
    _v4storage[3] = arg;
    _v4storage[2] = arg;
    _v4storage[1] = arg;
    _v4storage[0] = arg;
  }

  /// Returns a printable string
  @override
  String toString() => '${_v4storage[0]},${_v4storage[1]},'
      '${_v4storage[2]},${_v4storage[3]}';

  /// Check if two vectors are the same.
  @override
  bool operator ==(Object? other) =>
      (other is Vector4) &&
      (_v4storage[0] == other._v4storage[0]) &&
      (_v4storage[1] == other._v4storage[1]) &&
      (_v4storage[2] == other._v4storage[2]) &&
      (_v4storage[3] == other._v4storage[3]);

  @override
  int get hashCode => Object.hashAll(_v4storage);

  /// Negate.
  Vector4 operator -() => clone()..negate();

  /// Subtract two vectors.
  Vector4 operator -(Vector4 other) => clone()..sub(other);

  /// Add two vectors.
  Vector4 operator +(Vector4 other) => clone()..add(other);

  /// Scale.
  Vector4 operator /(double scale) => clone()..scale(1.0 / scale);

  /// Scale.
  Vector4 operator *(double scale) => clone()..scale(scale);

  /// Access the component of the vector at the index [i].
  double operator [](int i) => _v4storage[i];

  /// Set the component of the vector at the index [i].
  void operator []=(int i, double v) {
    _v4storage[i] = v;
  }

  /// Set the length of the vector. A negative [value] will change the vectors
  /// orientation and a [value] of zero will set the vector to zero.
  set length(double value) {
    if (value == 0.0) {
      setZero();
    } else {
      var l = length;
      if (l == 0.0) {
        return;
      }
      l = value / l;
      _v4storage[0] *= l;
      _v4storage[1] *= l;
      _v4storage[2] *= l;
      _v4storage[3] *= l;
    }
  }

  /// Length.
  double get length => math.sqrt(length2);

  /// Length squared.
  double get length2 {
    double sum;
    sum = _v4storage[0] * _v4storage[0];
    sum += _v4storage[1] * _v4storage[1];
    sum += _v4storage[2] * _v4storage[2];
    sum += _v4storage[3] * _v4storage[3];
    return sum;
  }

  /// Normalizes this.
  double normalize() {
    final l = length;
    if (l == 0.0) {
      return 0.0;
    }
    final d = 1.0 / l;
    _v4storage[0] *= d;
    _v4storage[1] *= d;
    _v4storage[2] *= d;
    _v4storage[3] *= d;
    return l;
  }

  /// Normalizes this. Returns length of vector before normalization.
  /// DEPRCATED: Use [normalize].
  @Deprecated('Use normalize() insteaed.')
  double normalizeLength() => normalize();

  /// Normalizes copy of this.
  Vector4 normalized() => clone()..normalize();

  /// Normalize vector into [out].
  Vector4 normalizeInto(Vector4 out) {
    out
      ..setFrom(this)
      ..normalize();
    return out;
  }

  /// Distance from this to [arg]
  double distanceTo(Vector4 arg) => math.sqrt(distanceToSquared(arg));

  /// Squared distance from this to [arg]
  double distanceToSquared(Vector4 arg) {
    final argStorage = arg._v4storage;
    final dx = _v4storage[0] - argStorage[0];
    final dy = _v4storage[1] - argStorage[1];
    final dz = _v4storage[2] - argStorage[2];
    final dw = _v4storage[3] - argStorage[3];

    return dx * dx + dy * dy + dz * dz + dw * dw;
  }

  /// Inner product.
  double dot(Vector4 other) {
    final otherStorage = other._v4storage;
    double sum;
    sum = _v4storage[0] * otherStorage[0];
    sum += _v4storage[1] * otherStorage[1];
    sum += _v4storage[2] * otherStorage[2];
    sum += _v4storage[3] * otherStorage[3];
    return sum;
  }

  /// Multiplies this by [arg].
  void applyMatrix4(Matrix4 arg) {
    final v1 = _v4storage[0];
    final v2 = _v4storage[1];
    final v3 = _v4storage[2];
    final v4 = _v4storage[3];
    final argStorage = arg.storage;
    _v4storage[0] = argStorage[0] * v1 +
        argStorage[4] * v2 +
        argStorage[8] * v3 +
        argStorage[12] * v4;
    _v4storage[1] = argStorage[1] * v1 +
        argStorage[5] * v2 +
        argStorage[9] * v3 +
        argStorage[13] * v4;
    _v4storage[2] = argStorage[2] * v1 +
        argStorage[6] * v2 +
        argStorage[10] * v3 +
        argStorage[14] * v4;
    _v4storage[3] = argStorage[3] * v1 +
        argStorage[7] * v2 +
        argStorage[11] * v3 +
        argStorage[15] * v4;
  }

  /// Relative error between this and [correct]
  double relativeError(Vector4 correct) {
    final correct_norm = correct.length;
    final diff_norm = (this - correct).length;
    return diff_norm / correct_norm;
  }

  /// Absolute error between this and [correct]
  double absoluteError(Vector4 correct) => (this - correct).length;

  /// True if any component is infinite.
  bool get isInfinite {
    var is_infinite = false;
    is_infinite = is_infinite || _v4storage[0].isInfinite;
    is_infinite = is_infinite || _v4storage[1].isInfinite;
    is_infinite = is_infinite || _v4storage[2].isInfinite;
    is_infinite = is_infinite || _v4storage[3].isInfinite;
    return is_infinite;
  }

  /// True if any component is NaN.
  bool get isNaN {
    var is_nan = false;
    is_nan = is_nan || _v4storage[0].isNaN;
    is_nan = is_nan || _v4storage[1].isNaN;
    is_nan = is_nan || _v4storage[2].isNaN;
    is_nan = is_nan || _v4storage[3].isNaN;
    return is_nan;
  }

  void add(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = _v4storage[0] + argStorage[0];
    _v4storage[1] = _v4storage[1] + argStorage[1];
    _v4storage[2] = _v4storage[2] + argStorage[2];
    _v4storage[3] = _v4storage[3] + argStorage[3];
  }

  /// Add [arg] scaled by [factor] to this.
  void addScaled(Vector4 arg, double factor) {
    final argStorage = arg._v4storage;
    _v4storage[0] = _v4storage[0] + argStorage[0] * factor;
    _v4storage[1] = _v4storage[1] + argStorage[1] * factor;
    _v4storage[2] = _v4storage[2] + argStorage[2] * factor;
    _v4storage[3] = _v4storage[3] + argStorage[3] * factor;
  }

  /// Subtract [arg] from this.
  void sub(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = _v4storage[0] - argStorage[0];
    _v4storage[1] = _v4storage[1] - argStorage[1];
    _v4storage[2] = _v4storage[2] - argStorage[2];
    _v4storage[3] = _v4storage[3] - argStorage[3];
  }

  /// Multiply this by [arg].
  void multiply(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = _v4storage[0] * argStorage[0];
    _v4storage[1] = _v4storage[1] * argStorage[1];
    _v4storage[2] = _v4storage[2] * argStorage[2];
    _v4storage[3] = _v4storage[3] * argStorage[3];
  }

  /// Divide this by [arg].
  void div(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = _v4storage[0] / argStorage[0];
    _v4storage[1] = _v4storage[1] / argStorage[1];
    _v4storage[2] = _v4storage[2] / argStorage[2];
    _v4storage[3] = _v4storage[3] / argStorage[3];
  }

  /// Scale this by [arg].
  void scale(double arg) {
    _v4storage[0] = _v4storage[0] * arg;
    _v4storage[1] = _v4storage[1] * arg;
    _v4storage[2] = _v4storage[2] * arg;
    _v4storage[3] = _v4storage[3] * arg;
  }

  /// Create a copy of this scaled by [arg].
  Vector4 scaled(double arg) => clone()..scale(arg);

  /// Negate this.
  void negate() {
    _v4storage[0] = -_v4storage[0];
    _v4storage[1] = -_v4storage[1];
    _v4storage[2] = -_v4storage[2];
    _v4storage[3] = -_v4storage[3];
  }

  /// Set this to the absolute.
  void absolute() {
    _v4storage[3] = _v4storage[3].abs();
    _v4storage[2] = _v4storage[2].abs();
    _v4storage[1] = _v4storage[1].abs();
    _v4storage[0] = _v4storage[0].abs();
  }

  /// Clamp each entry n in this in the range [min[n]]-[max[n]].
  void clamp(Vector4 min, Vector4 max) {
    final minStorage = min.storage;
    final maxStorage = max.storage;
    _v4storage[0] =
        _v4storage[0].clamp(minStorage[0], maxStorage[0]).toDouble();
    _v4storage[1] =
        _v4storage[1].clamp(minStorage[1], maxStorage[1]).toDouble();
    _v4storage[2] =
        _v4storage[2].clamp(minStorage[2], maxStorage[2]).toDouble();
    _v4storage[3] =
        _v4storage[3].clamp(minStorage[3], maxStorage[3]).toDouble();
  }

  /// Clamp entries in this in the range [min]-[max].
  void clampScalar(double min, double max) {
    _v4storage[0] = _v4storage[0].clamp(min, max).toDouble();
    _v4storage[1] = _v4storage[1].clamp(min, max).toDouble();
    _v4storage[2] = _v4storage[2].clamp(min, max).toDouble();
    _v4storage[3] = _v4storage[3].clamp(min, max).toDouble();
  }

  /// Floor entries in this.
  void floor() {
    _v4storage[0] = _v4storage[0].floorToDouble();
    _v4storage[1] = _v4storage[1].floorToDouble();
    _v4storage[2] = _v4storage[2].floorToDouble();
    _v4storage[3] = _v4storage[3].floorToDouble();
  }

  /// Ceil entries in this.
  void ceil() {
    _v4storage[0] = _v4storage[0].ceilToDouble();
    _v4storage[1] = _v4storage[1].ceilToDouble();
    _v4storage[2] = _v4storage[2].ceilToDouble();
    _v4storage[3] = _v4storage[3].ceilToDouble();
  }

  /// Round entries in this.
  void round() {
    _v4storage[0] = _v4storage[0].roundToDouble();
    _v4storage[1] = _v4storage[1].roundToDouble();
    _v4storage[2] = _v4storage[2].roundToDouble();
    _v4storage[3] = _v4storage[3].roundToDouble();
  }

  /// Round entries in this towards zero.
  void roundToZero() {
    _v4storage[0] = _v4storage[0] < 0.0
        ? _v4storage[0].ceilToDouble()
        : _v4storage[0].floorToDouble();
    _v4storage[1] = _v4storage[1] < 0.0
        ? _v4storage[1].ceilToDouble()
        : _v4storage[1].floorToDouble();
    _v4storage[2] = _v4storage[2] < 0.0
        ? _v4storage[2].ceilToDouble()
        : _v4storage[2].floorToDouble();
    _v4storage[3] = _v4storage[3] < 0.0
        ? _v4storage[3].ceilToDouble()
        : _v4storage[3].floorToDouble();
  }

  /// Create a copy of this.
  Vector4 clone() => Vector4.copy(this);

  /// Copy this
  Vector4 copyInto(Vector4 arg) {
    final argStorage = arg._v4storage;
    argStorage[0] = _v4storage[0];
    argStorage[1] = _v4storage[1];
    argStorage[2] = _v4storage[2];
    argStorage[3] = _v4storage[3];
    return arg;
  }

  /// Copies this into [array] starting at [offset].
  void copyIntoArray(List<double> array, [int offset = 0]) {
    array[offset + 0] = _v4storage[0];
    array[offset + 1] = _v4storage[1];
    array[offset + 2] = _v4storage[2];
    array[offset + 3] = _v4storage[3];
  }

  /// Copies elements from [array] into this starting at [offset].
  void copyFromArray(List<double> array, [int offset = 0]) {
    _v4storage[0] = array[offset + 0];
    _v4storage[1] = array[offset + 1];
    _v4storage[2] = array[offset + 2];
    _v4storage[3] = array[offset + 3];
  }

  set xy(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[0] = argStorage[0];
    _v4storage[1] = argStorage[1];
  }

  set xz(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[0] = argStorage[0];
    _v4storage[2] = argStorage[1];
  }

  set xw(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[0] = argStorage[0];
    _v4storage[3] = argStorage[1];
  }

  set yx(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[1] = argStorage[0];
    _v4storage[0] = argStorage[1];
  }

  set yz(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[1] = argStorage[0];
    _v4storage[2] = argStorage[1];
  }

  set yw(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[1] = argStorage[0];
    _v4storage[3] = argStorage[1];
  }

  set zx(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[2] = argStorage[0];
    _v4storage[0] = argStorage[1];
  }

  set zy(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[2] = argStorage[0];
    _v4storage[1] = argStorage[1];
  }

  set zw(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[2] = argStorage[0];
    _v4storage[3] = argStorage[1];
  }

  set wx(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[3] = argStorage[0];
    _v4storage[0] = argStorage[1];
  }

  set wy(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[3] = argStorage[0];
    _v4storage[1] = argStorage[1];
  }

  set wz(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v4storage[3] = argStorage[0];
    _v4storage[2] = argStorage[1];
  }

  set xyz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[0] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[2] = argStorage[2];
  }

  set xyw(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[0] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[3] = argStorage[2];
  }

  set xzy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[0] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[1] = argStorage[2];
  }

  set xzw(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[0] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[3] = argStorage[2];
  }

  set xwy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[0] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[1] = argStorage[2];
  }

  set xwz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[0] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[2] = argStorage[2];
  }

  set yxz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[1] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[2] = argStorage[2];
  }

  set yxw(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[1] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[3] = argStorage[2];
  }

  set yzx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[1] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[0] = argStorage[2];
  }

  set yzw(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[1] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[3] = argStorage[2];
  }

  set ywx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[1] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[0] = argStorage[2];
  }

  set ywz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[1] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[2] = argStorage[2];
  }

  set zxy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[2] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[1] = argStorage[2];
  }

  set zxw(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[2] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[3] = argStorage[2];
  }

  set zyx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[2] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[0] = argStorage[2];
  }

  set zyw(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[2] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[3] = argStorage[2];
  }

  set zwx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[2] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[0] = argStorage[2];
  }

  set zwy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[2] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[1] = argStorage[2];
  }

  set wxy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[3] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[1] = argStorage[2];
  }

  set wxz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[3] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[2] = argStorage[2];
  }

  set wyx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[3] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[0] = argStorage[2];
  }

  set wyz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[3] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[2] = argStorage[2];
  }

  set wzx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[3] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[0] = argStorage[2];
  }

  set wzy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v4storage[3] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[1] = argStorage[2];
  }

  set xyzw(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[2] = argStorage[2];
    _v4storage[3] = argStorage[3];
  }

  set xywz(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[3] = argStorage[2];
    _v4storage[2] = argStorage[3];
  }

  set xzyw(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[1] = argStorage[2];
    _v4storage[3] = argStorage[3];
  }

  set xzwy(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[3] = argStorage[2];
    _v4storage[1] = argStorage[3];
  }

  set xwyz(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[1] = argStorage[2];
    _v4storage[2] = argStorage[3];
  }

  set xwzy(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[0] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[2] = argStorage[2];
    _v4storage[1] = argStorage[3];
  }

  set yxzw(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[1] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[2] = argStorage[2];
    _v4storage[3] = argStorage[3];
  }

  set yxwz(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[1] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[3] = argStorage[2];
    _v4storage[2] = argStorage[3];
  }

  set yzxw(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[1] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[0] = argStorage[2];
    _v4storage[3] = argStorage[3];
  }

  set yzwx(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[1] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[3] = argStorage[2];
    _v4storage[0] = argStorage[3];
  }

  set ywxz(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[1] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[0] = argStorage[2];
    _v4storage[2] = argStorage[3];
  }

  set ywzx(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[1] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[2] = argStorage[2];
    _v4storage[0] = argStorage[3];
  }

  set zxyw(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[2] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[1] = argStorage[2];
    _v4storage[3] = argStorage[3];
  }

  set zxwy(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[2] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[3] = argStorage[2];
    _v4storage[1] = argStorage[3];
  }

  set zyxw(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[2] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[0] = argStorage[2];
    _v4storage[3] = argStorage[3];
  }

  set zywx(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[2] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[3] = argStorage[2];
    _v4storage[0] = argStorage[3];
  }

  set zwxy(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[2] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[0] = argStorage[2];
    _v4storage[1] = argStorage[3];
  }

  set zwyx(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[2] = argStorage[0];
    _v4storage[3] = argStorage[1];
    _v4storage[1] = argStorage[2];
    _v4storage[0] = argStorage[3];
  }

  set wxyz(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[3] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[1] = argStorage[2];
    _v4storage[2] = argStorage[3];
  }

  set wxzy(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[3] = argStorage[0];
    _v4storage[0] = argStorage[1];
    _v4storage[2] = argStorage[2];
    _v4storage[1] = argStorage[3];
  }

  set wyxz(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[3] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[0] = argStorage[2];
    _v4storage[2] = argStorage[3];
  }

  set wyzx(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[3] = argStorage[0];
    _v4storage[1] = argStorage[1];
    _v4storage[2] = argStorage[2];
    _v4storage[0] = argStorage[3];
  }

  set wzxy(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[3] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[0] = argStorage[2];
    _v4storage[1] = argStorage[3];
  }

  set wzyx(Vector4 arg) {
    final argStorage = arg._v4storage;
    _v4storage[3] = argStorage[0];
    _v4storage[2] = argStorage[1];
    _v4storage[1] = argStorage[2];
    _v4storage[0] = argStorage[3];
  }

  set r(double arg) => x = arg;
  set g(double arg) => y = arg;
  set b(double arg) => z = arg;
  set a(double arg) => w = arg;
  set s(double arg) => x = arg;
  set t(double arg) => y = arg;
  set p(double arg) => z = arg;
  set q(double arg) => w = arg;
  set x(double arg) => _v4storage[0] = arg;
  set y(double arg) => _v4storage[1] = arg;
  set z(double arg) => _v4storage[2] = arg;
  set w(double arg) => _v4storage[3] = arg;
  set rg(Vector2 arg) => xy = arg;
  set rb(Vector2 arg) => xz = arg;
  set ra(Vector2 arg) => xw = arg;
  set gr(Vector2 arg) => yx = arg;
  set gb(Vector2 arg) => yz = arg;
  set ga(Vector2 arg) => yw = arg;
  set br(Vector2 arg) => zx = arg;
  set bg(Vector2 arg) => zy = arg;
  set ba(Vector2 arg) => zw = arg;
  set ar(Vector2 arg) => wx = arg;
  set ag(Vector2 arg) => wy = arg;
  set ab(Vector2 arg) => wz = arg;
  set rgb(Vector3 arg) => xyz = arg;
  set rga(Vector3 arg) => xyw = arg;
  set rbg(Vector3 arg) => xzy = arg;
  set rba(Vector3 arg) => xzw = arg;
  set rag(Vector3 arg) => xwy = arg;
  set rab(Vector3 arg) => xwz = arg;
  set grb(Vector3 arg) => yxz = arg;
  set gra(Vector3 arg) => yxw = arg;
  set gbr(Vector3 arg) => yzx = arg;
  set gba(Vector3 arg) => yzw = arg;
  set gar(Vector3 arg) => ywx = arg;
  set gab(Vector3 arg) => ywz = arg;
  set brg(Vector3 arg) => zxy = arg;
  set bra(Vector3 arg) => zxw = arg;
  set bgr(Vector3 arg) => zyx = arg;
  set bga(Vector3 arg) => zyw = arg;
  set bar(Vector3 arg) => zwx = arg;
  set bag(Vector3 arg) => zwy = arg;
  set arg(Vector3 arg) => wxy = arg;
  set arb(Vector3 arg) => wxz = arg;
  set agr(Vector3 arg) => wyx = arg;
  set agb(Vector3 arg) => wyz = arg;
  set abr(Vector3 arg) => wzx = arg;
  set abg(Vector3 arg) => wzy = arg;
  set rgba(Vector4 arg) => xyzw = arg;
  set rgab(Vector4 arg) => xywz = arg;
  set rbga(Vector4 arg) => xzyw = arg;
  set rbag(Vector4 arg) => xzwy = arg;
  set ragb(Vector4 arg) => xwyz = arg;
  set rabg(Vector4 arg) => xwzy = arg;
  set grba(Vector4 arg) => yxzw = arg;
  set grab(Vector4 arg) => yxwz = arg;
  set gbra(Vector4 arg) => yzxw = arg;
  set gbar(Vector4 arg) => yzwx = arg;
  set garb(Vector4 arg) => ywxz = arg;
  set gabr(Vector4 arg) => ywzx = arg;
  set brga(Vector4 arg) => zxyw = arg;
  set brag(Vector4 arg) => zxwy = arg;
  set bgra(Vector4 arg) => zyxw = arg;
  set bgar(Vector4 arg) => zywx = arg;
  set barg(Vector4 arg) => zwxy = arg;
  set bagr(Vector4 arg) => zwyx = arg;
  set argb(Vector4 arg) => wxyz = arg;
  set arbg(Vector4 arg) => wxzy = arg;
  set agrb(Vector4 arg) => wyxz = arg;
  set agbr(Vector4 arg) => wyzx = arg;
  set abrg(Vector4 arg) => wzxy = arg;
  set abgr(Vector4 arg) => wzyx = arg;
  set st(Vector2 arg) => xy = arg;
  set sp(Vector2 arg) => xz = arg;
  set sq(Vector2 arg) => xw = arg;
  set ts(Vector2 arg) => yx = arg;
  set tp(Vector2 arg) => yz = arg;
  set tq(Vector2 arg) => yw = arg;
  set ps(Vector2 arg) => zx = arg;
  set pt(Vector2 arg) => zy = arg;
  set pq(Vector2 arg) => zw = arg;
  set qs(Vector2 arg) => wx = arg;
  set qt(Vector2 arg) => wy = arg;
  set qp(Vector2 arg) => wz = arg;
  set stp(Vector3 arg) => xyz = arg;
  set stq(Vector3 arg) => xyw = arg;
  set spt(Vector3 arg) => xzy = arg;
  set spq(Vector3 arg) => xzw = arg;
  set sqt(Vector3 arg) => xwy = arg;
  set sqp(Vector3 arg) => xwz = arg;
  set tsp(Vector3 arg) => yxz = arg;
  set tsq(Vector3 arg) => yxw = arg;
  set tps(Vector3 arg) => yzx = arg;
  set tpq(Vector3 arg) => yzw = arg;
  set tqs(Vector3 arg) => ywx = arg;
  set tqp(Vector3 arg) => ywz = arg;
  set pst(Vector3 arg) => zxy = arg;
  set psq(Vector3 arg) => zxw = arg;
  set pts(Vector3 arg) => zyx = arg;
  set ptq(Vector3 arg) => zyw = arg;
  set pqs(Vector3 arg) => zwx = arg;
  set pqt(Vector3 arg) => zwy = arg;
  set qst(Vector3 arg) => wxy = arg;
  set qsp(Vector3 arg) => wxz = arg;
  set qts(Vector3 arg) => wyx = arg;
  set qtp(Vector3 arg) => wyz = arg;
  set qps(Vector3 arg) => wzx = arg;
  set qpt(Vector3 arg) => wzy = arg;
  set stpq(Vector4 arg) => xyzw = arg;
  set stqp(Vector4 arg) => xywz = arg;
  set sptq(Vector4 arg) => xzyw = arg;
  set spqt(Vector4 arg) => xzwy = arg;
  set sqtp(Vector4 arg) => xwyz = arg;
  set sqpt(Vector4 arg) => xwzy = arg;
  set tspq(Vector4 arg) => yxzw = arg;
  set tsqp(Vector4 arg) => yxwz = arg;
  set tpsq(Vector4 arg) => yzxw = arg;
  set tpqs(Vector4 arg) => yzwx = arg;
  set tqsp(Vector4 arg) => ywxz = arg;
  set tqps(Vector4 arg) => ywzx = arg;
  set pstq(Vector4 arg) => zxyw = arg;
  set psqt(Vector4 arg) => zxwy = arg;
  set ptsq(Vector4 arg) => zyxw = arg;
  set ptqs(Vector4 arg) => zywx = arg;
  set pqst(Vector4 arg) => zwxy = arg;
  set pqts(Vector4 arg) => zwyx = arg;
  set qstp(Vector4 arg) => wxyz = arg;
  set qspt(Vector4 arg) => wxzy = arg;
  set qtsp(Vector4 arg) => wyxz = arg;
  set qtps(Vector4 arg) => wyzx = arg;
  set qpst(Vector4 arg) => wzxy = arg;
  set qpts(Vector4 arg) => wzyx = arg;
  Vector2 get xx => Vector2(_v4storage[0], _v4storage[0]);
  Vector2 get xy => Vector2(_v4storage[0], _v4storage[1]);
  Vector2 get xz => Vector2(_v4storage[0], _v4storage[2]);
  Vector2 get xw => Vector2(_v4storage[0], _v4storage[3]);
  Vector2 get yx => Vector2(_v4storage[1], _v4storage[0]);
  Vector2 get yy => Vector2(_v4storage[1], _v4storage[1]);
  Vector2 get yz => Vector2(_v4storage[1], _v4storage[2]);
  Vector2 get yw => Vector2(_v4storage[1], _v4storage[3]);
  Vector2 get zx => Vector2(_v4storage[2], _v4storage[0]);
  Vector2 get zy => Vector2(_v4storage[2], _v4storage[1]);
  Vector2 get zz => Vector2(_v4storage[2], _v4storage[2]);
  Vector2 get zw => Vector2(_v4storage[2], _v4storage[3]);
  Vector2 get wx => Vector2(_v4storage[3], _v4storage[0]);
  Vector2 get wy => Vector2(_v4storage[3], _v4storage[1]);
  Vector2 get wz => Vector2(_v4storage[3], _v4storage[2]);
  Vector2 get ww => Vector2(_v4storage[3], _v4storage[3]);
  Vector3 get xxx => Vector3(_v4storage[0], _v4storage[0], _v4storage[0]);
  Vector3 get xxy => Vector3(_v4storage[0], _v4storage[0], _v4storage[1]);
  Vector3 get xxz => Vector3(_v4storage[0], _v4storage[0], _v4storage[2]);
  Vector3 get xxw => Vector3(_v4storage[0], _v4storage[0], _v4storage[3]);
  Vector3 get xyx => Vector3(_v4storage[0], _v4storage[1], _v4storage[0]);
  Vector3 get xyy => Vector3(_v4storage[0], _v4storage[1], _v4storage[1]);
  Vector3 get xyz => Vector3(_v4storage[0], _v4storage[1], _v4storage[2]);
  Vector3 get xyw => Vector3(_v4storage[0], _v4storage[1], _v4storage[3]);
  Vector3 get xzx => Vector3(_v4storage[0], _v4storage[2], _v4storage[0]);
  Vector3 get xzy => Vector3(_v4storage[0], _v4storage[2], _v4storage[1]);
  Vector3 get xzz => Vector3(_v4storage[0], _v4storage[2], _v4storage[2]);
  Vector3 get xzw => Vector3(_v4storage[0], _v4storage[2], _v4storage[3]);
  Vector3 get xwx => Vector3(_v4storage[0], _v4storage[3], _v4storage[0]);
  Vector3 get xwy => Vector3(_v4storage[0], _v4storage[3], _v4storage[1]);
  Vector3 get xwz => Vector3(_v4storage[0], _v4storage[3], _v4storage[2]);
  Vector3 get xww => Vector3(_v4storage[0], _v4storage[3], _v4storage[3]);
  Vector3 get yxx => Vector3(_v4storage[1], _v4storage[0], _v4storage[0]);
  Vector3 get yxy => Vector3(_v4storage[1], _v4storage[0], _v4storage[1]);
  Vector3 get yxz => Vector3(_v4storage[1], _v4storage[0], _v4storage[2]);
  Vector3 get yxw => Vector3(_v4storage[1], _v4storage[0], _v4storage[3]);
  Vector3 get yyx => Vector3(_v4storage[1], _v4storage[1], _v4storage[0]);
  Vector3 get yyy => Vector3(_v4storage[1], _v4storage[1], _v4storage[1]);
  Vector3 get yyz => Vector3(_v4storage[1], _v4storage[1], _v4storage[2]);
  Vector3 get yyw => Vector3(_v4storage[1], _v4storage[1], _v4storage[3]);
  Vector3 get yzx => Vector3(_v4storage[1], _v4storage[2], _v4storage[0]);
  Vector3 get yzy => Vector3(_v4storage[1], _v4storage[2], _v4storage[1]);
  Vector3 get yzz => Vector3(_v4storage[1], _v4storage[2], _v4storage[2]);
  Vector3 get yzw => Vector3(_v4storage[1], _v4storage[2], _v4storage[3]);
  Vector3 get ywx => Vector3(_v4storage[1], _v4storage[3], _v4storage[0]);
  Vector3 get ywy => Vector3(_v4storage[1], _v4storage[3], _v4storage[1]);
  Vector3 get ywz => Vector3(_v4storage[1], _v4storage[3], _v4storage[2]);
  Vector3 get yww => Vector3(_v4storage[1], _v4storage[3], _v4storage[3]);
  Vector3 get zxx => Vector3(_v4storage[2], _v4storage[0], _v4storage[0]);
  Vector3 get zxy => Vector3(_v4storage[2], _v4storage[0], _v4storage[1]);
  Vector3 get zxz => Vector3(_v4storage[2], _v4storage[0], _v4storage[2]);
  Vector3 get zxw => Vector3(_v4storage[2], _v4storage[0], _v4storage[3]);
  Vector3 get zyx => Vector3(_v4storage[2], _v4storage[1], _v4storage[0]);
  Vector3 get zyy => Vector3(_v4storage[2], _v4storage[1], _v4storage[1]);
  Vector3 get zyz => Vector3(_v4storage[2], _v4storage[1], _v4storage[2]);
  Vector3 get zyw => Vector3(_v4storage[2], _v4storage[1], _v4storage[3]);
  Vector3 get zzx => Vector3(_v4storage[2], _v4storage[2], _v4storage[0]);
  Vector3 get zzy => Vector3(_v4storage[2], _v4storage[2], _v4storage[1]);
  Vector3 get zzz => Vector3(_v4storage[2], _v4storage[2], _v4storage[2]);
  Vector3 get zzw => Vector3(_v4storage[2], _v4storage[2], _v4storage[3]);
  Vector3 get zwx => Vector3(_v4storage[2], _v4storage[3], _v4storage[0]);
  Vector3 get zwy => Vector3(_v4storage[2], _v4storage[3], _v4storage[1]);
  Vector3 get zwz => Vector3(_v4storage[2], _v4storage[3], _v4storage[2]);
  Vector3 get zww => Vector3(_v4storage[2], _v4storage[3], _v4storage[3]);
  Vector3 get wxx => Vector3(_v4storage[3], _v4storage[0], _v4storage[0]);
  Vector3 get wxy => Vector3(_v4storage[3], _v4storage[0], _v4storage[1]);
  Vector3 get wxz => Vector3(_v4storage[3], _v4storage[0], _v4storage[2]);
  Vector3 get wxw => Vector3(_v4storage[3], _v4storage[0], _v4storage[3]);
  Vector3 get wyx => Vector3(_v4storage[3], _v4storage[1], _v4storage[0]);
  Vector3 get wyy => Vector3(_v4storage[3], _v4storage[1], _v4storage[1]);
  Vector3 get wyz => Vector3(_v4storage[3], _v4storage[1], _v4storage[2]);
  Vector3 get wyw => Vector3(_v4storage[3], _v4storage[1], _v4storage[3]);
  Vector3 get wzx => Vector3(_v4storage[3], _v4storage[2], _v4storage[0]);
  Vector3 get wzy => Vector3(_v4storage[3], _v4storage[2], _v4storage[1]);
  Vector3 get wzz => Vector3(_v4storage[3], _v4storage[2], _v4storage[2]);
  Vector3 get wzw => Vector3(_v4storage[3], _v4storage[2], _v4storage[3]);
  Vector3 get wwx => Vector3(_v4storage[3], _v4storage[3], _v4storage[0]);
  Vector3 get wwy => Vector3(_v4storage[3], _v4storage[3], _v4storage[1]);
  Vector3 get wwz => Vector3(_v4storage[3], _v4storage[3], _v4storage[2]);
  Vector3 get www => Vector3(_v4storage[3], _v4storage[3], _v4storage[3]);
  Vector4 get xxxx =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[0], _v4storage[0]);
  Vector4 get xxxy =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[0], _v4storage[1]);
  Vector4 get xxxz =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[0], _v4storage[2]);
  Vector4 get xxxw =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[0], _v4storage[3]);
  Vector4 get xxyx =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[1], _v4storage[0]);
  Vector4 get xxyy =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[1], _v4storage[1]);
  Vector4 get xxyz =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[1], _v4storage[2]);
  Vector4 get xxyw =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[1], _v4storage[3]);
  Vector4 get xxzx =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[2], _v4storage[0]);
  Vector4 get xxzy =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[2], _v4storage[1]);
  Vector4 get xxzz =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[2], _v4storage[2]);
  Vector4 get xxzw =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[2], _v4storage[3]);
  Vector4 get xxwx =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[3], _v4storage[0]);
  Vector4 get xxwy =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[3], _v4storage[1]);
  Vector4 get xxwz =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[3], _v4storage[2]);
  Vector4 get xxww =>
      Vector4(_v4storage[0], _v4storage[0], _v4storage[3], _v4storage[3]);
  Vector4 get xyxx =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[0], _v4storage[0]);
  Vector4 get xyxy =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[0], _v4storage[1]);
  Vector4 get xyxz =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[0], _v4storage[2]);
  Vector4 get xyxw =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[0], _v4storage[3]);
  Vector4 get xyyx =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[1], _v4storage[0]);
  Vector4 get xyyy =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[1], _v4storage[1]);
  Vector4 get xyyz =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[1], _v4storage[2]);
  Vector4 get xyyw =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[1], _v4storage[3]);
  Vector4 get xyzx =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[2], _v4storage[0]);
  Vector4 get xyzy =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[2], _v4storage[1]);
  Vector4 get xyzz =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[2], _v4storage[2]);
  Vector4 get xyzw =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[2], _v4storage[3]);
  Vector4 get xywx =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[3], _v4storage[0]);
  Vector4 get xywy =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[3], _v4storage[1]);
  Vector4 get xywz =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[3], _v4storage[2]);
  Vector4 get xyww =>
      Vector4(_v4storage[0], _v4storage[1], _v4storage[3], _v4storage[3]);
  Vector4 get xzxx =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[0], _v4storage[0]);
  Vector4 get xzxy =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[0], _v4storage[1]);
  Vector4 get xzxz =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[0], _v4storage[2]);
  Vector4 get xzxw =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[0], _v4storage[3]);
  Vector4 get xzyx =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[1], _v4storage[0]);
  Vector4 get xzyy =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[1], _v4storage[1]);
  Vector4 get xzyz =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[1], _v4storage[2]);
  Vector4 get xzyw =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[1], _v4storage[3]);
  Vector4 get xzzx =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[2], _v4storage[0]);
  Vector4 get xzzy =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[2], _v4storage[1]);
  Vector4 get xzzz =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[2], _v4storage[2]);
  Vector4 get xzzw =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[2], _v4storage[3]);
  Vector4 get xzwx =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[3], _v4storage[0]);
  Vector4 get xzwy =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[3], _v4storage[1]);
  Vector4 get xzwz =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[3], _v4storage[2]);
  Vector4 get xzww =>
      Vector4(_v4storage[0], _v4storage[2], _v4storage[3], _v4storage[3]);
  Vector4 get xwxx =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[0], _v4storage[0]);
  Vector4 get xwxy =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[0], _v4storage[1]);
  Vector4 get xwxz =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[0], _v4storage[2]);
  Vector4 get xwxw =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[0], _v4storage[3]);
  Vector4 get xwyx =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[1], _v4storage[0]);
  Vector4 get xwyy =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[1], _v4storage[1]);
  Vector4 get xwyz =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[1], _v4storage[2]);
  Vector4 get xwyw =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[1], _v4storage[3]);
  Vector4 get xwzx =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[2], _v4storage[0]);
  Vector4 get xwzy =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[2], _v4storage[1]);
  Vector4 get xwzz =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[2], _v4storage[2]);
  Vector4 get xwzw =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[2], _v4storage[3]);
  Vector4 get xwwx =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[3], _v4storage[0]);
  Vector4 get xwwy =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[3], _v4storage[1]);
  Vector4 get xwwz =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[3], _v4storage[2]);
  Vector4 get xwww =>
      Vector4(_v4storage[0], _v4storage[3], _v4storage[3], _v4storage[3]);
  Vector4 get yxxx =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[0], _v4storage[0]);
  Vector4 get yxxy =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[0], _v4storage[1]);
  Vector4 get yxxz =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[0], _v4storage[2]);
  Vector4 get yxxw =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[0], _v4storage[3]);
  Vector4 get yxyx =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[1], _v4storage[0]);
  Vector4 get yxyy =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[1], _v4storage[1]);
  Vector4 get yxyz =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[1], _v4storage[2]);
  Vector4 get yxyw =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[1], _v4storage[3]);
  Vector4 get yxzx =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[2], _v4storage[0]);
  Vector4 get yxzy =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[2], _v4storage[1]);
  Vector4 get yxzz =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[2], _v4storage[2]);
  Vector4 get yxzw =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[2], _v4storage[3]);
  Vector4 get yxwx =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[3], _v4storage[0]);
  Vector4 get yxwy =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[3], _v4storage[1]);
  Vector4 get yxwz =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[3], _v4storage[2]);
  Vector4 get yxww =>
      Vector4(_v4storage[1], _v4storage[0], _v4storage[3], _v4storage[3]);
  Vector4 get yyxx =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[0], _v4storage[0]);
  Vector4 get yyxy =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[0], _v4storage[1]);
  Vector4 get yyxz =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[0], _v4storage[2]);
  Vector4 get yyxw =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[0], _v4storage[3]);
  Vector4 get yyyx =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[1], _v4storage[0]);
  Vector4 get yyyy =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[1], _v4storage[1]);
  Vector4 get yyyz =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[1], _v4storage[2]);
  Vector4 get yyyw =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[1], _v4storage[3]);
  Vector4 get yyzx =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[2], _v4storage[0]);
  Vector4 get yyzy =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[2], _v4storage[1]);
  Vector4 get yyzz =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[2], _v4storage[2]);
  Vector4 get yyzw =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[2], _v4storage[3]);
  Vector4 get yywx =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[3], _v4storage[0]);
  Vector4 get yywy =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[3], _v4storage[1]);
  Vector4 get yywz =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[3], _v4storage[2]);
  Vector4 get yyww =>
      Vector4(_v4storage[1], _v4storage[1], _v4storage[3], _v4storage[3]);
  Vector4 get yzxx =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[0], _v4storage[0]);
  Vector4 get yzxy =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[0], _v4storage[1]);
  Vector4 get yzxz =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[0], _v4storage[2]);
  Vector4 get yzxw =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[0], _v4storage[3]);
  Vector4 get yzyx =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[1], _v4storage[0]);
  Vector4 get yzyy =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[1], _v4storage[1]);
  Vector4 get yzyz =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[1], _v4storage[2]);
  Vector4 get yzyw =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[1], _v4storage[3]);
  Vector4 get yzzx =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[2], _v4storage[0]);
  Vector4 get yzzy =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[2], _v4storage[1]);
  Vector4 get yzzz =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[2], _v4storage[2]);
  Vector4 get yzzw =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[2], _v4storage[3]);
  Vector4 get yzwx =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[3], _v4storage[0]);
  Vector4 get yzwy =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[3], _v4storage[1]);
  Vector4 get yzwz =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[3], _v4storage[2]);
  Vector4 get yzww =>
      Vector4(_v4storage[1], _v4storage[2], _v4storage[3], _v4storage[3]);
  Vector4 get ywxx =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[0], _v4storage[0]);
  Vector4 get ywxy =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[0], _v4storage[1]);
  Vector4 get ywxz =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[0], _v4storage[2]);
  Vector4 get ywxw =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[0], _v4storage[3]);
  Vector4 get ywyx =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[1], _v4storage[0]);
  Vector4 get ywyy =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[1], _v4storage[1]);
  Vector4 get ywyz =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[1], _v4storage[2]);
  Vector4 get ywyw =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[1], _v4storage[3]);
  Vector4 get ywzx =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[2], _v4storage[0]);
  Vector4 get ywzy =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[2], _v4storage[1]);
  Vector4 get ywzz =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[2], _v4storage[2]);
  Vector4 get ywzw =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[2], _v4storage[3]);
  Vector4 get ywwx =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[3], _v4storage[0]);
  Vector4 get ywwy =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[3], _v4storage[1]);
  Vector4 get ywwz =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[3], _v4storage[2]);
  Vector4 get ywww =>
      Vector4(_v4storage[1], _v4storage[3], _v4storage[3], _v4storage[3]);
  Vector4 get zxxx =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[0], _v4storage[0]);
  Vector4 get zxxy =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[0], _v4storage[1]);
  Vector4 get zxxz =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[0], _v4storage[2]);
  Vector4 get zxxw =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[0], _v4storage[3]);
  Vector4 get zxyx =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[1], _v4storage[0]);
  Vector4 get zxyy =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[1], _v4storage[1]);
  Vector4 get zxyz =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[1], _v4storage[2]);
  Vector4 get zxyw =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[1], _v4storage[3]);
  Vector4 get zxzx =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[2], _v4storage[0]);
  Vector4 get zxzy =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[2], _v4storage[1]);
  Vector4 get zxzz =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[2], _v4storage[2]);
  Vector4 get zxzw =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[2], _v4storage[3]);
  Vector4 get zxwx =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[3], _v4storage[0]);
  Vector4 get zxwy =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[3], _v4storage[1]);
  Vector4 get zxwz =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[3], _v4storage[2]);
  Vector4 get zxww =>
      Vector4(_v4storage[2], _v4storage[0], _v4storage[3], _v4storage[3]);
  Vector4 get zyxx =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[0], _v4storage[0]);
  Vector4 get zyxy =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[0], _v4storage[1]);
  Vector4 get zyxz =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[0], _v4storage[2]);
  Vector4 get zyxw =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[0], _v4storage[3]);
  Vector4 get zyyx =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[1], _v4storage[0]);
  Vector4 get zyyy =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[1], _v4storage[1]);
  Vector4 get zyyz =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[1], _v4storage[2]);
  Vector4 get zyyw =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[1], _v4storage[3]);
  Vector4 get zyzx =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[2], _v4storage[0]);
  Vector4 get zyzy =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[2], _v4storage[1]);
  Vector4 get zyzz =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[2], _v4storage[2]);
  Vector4 get zyzw =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[2], _v4storage[3]);
  Vector4 get zywx =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[3], _v4storage[0]);
  Vector4 get zywy =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[3], _v4storage[1]);
  Vector4 get zywz =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[3], _v4storage[2]);
  Vector4 get zyww =>
      Vector4(_v4storage[2], _v4storage[1], _v4storage[3], _v4storage[3]);
  Vector4 get zzxx =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[0], _v4storage[0]);
  Vector4 get zzxy =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[0], _v4storage[1]);
  Vector4 get zzxz =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[0], _v4storage[2]);
  Vector4 get zzxw =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[0], _v4storage[3]);
  Vector4 get zzyx =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[1], _v4storage[0]);
  Vector4 get zzyy =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[1], _v4storage[1]);
  Vector4 get zzyz =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[1], _v4storage[2]);
  Vector4 get zzyw =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[1], _v4storage[3]);
  Vector4 get zzzx =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[2], _v4storage[0]);
  Vector4 get zzzy =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[2], _v4storage[1]);
  Vector4 get zzzz =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[2], _v4storage[2]);
  Vector4 get zzzw =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[2], _v4storage[3]);
  Vector4 get zzwx =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[3], _v4storage[0]);
  Vector4 get zzwy =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[3], _v4storage[1]);
  Vector4 get zzwz =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[3], _v4storage[2]);
  Vector4 get zzww =>
      Vector4(_v4storage[2], _v4storage[2], _v4storage[3], _v4storage[3]);
  Vector4 get zwxx =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[0], _v4storage[0]);
  Vector4 get zwxy =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[0], _v4storage[1]);
  Vector4 get zwxz =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[0], _v4storage[2]);
  Vector4 get zwxw =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[0], _v4storage[3]);
  Vector4 get zwyx =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[1], _v4storage[0]);
  Vector4 get zwyy =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[1], _v4storage[1]);
  Vector4 get zwyz =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[1], _v4storage[2]);
  Vector4 get zwyw =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[1], _v4storage[3]);
  Vector4 get zwzx =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[2], _v4storage[0]);
  Vector4 get zwzy =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[2], _v4storage[1]);
  Vector4 get zwzz =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[2], _v4storage[2]);
  Vector4 get zwzw =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[2], _v4storage[3]);
  Vector4 get zwwx =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[3], _v4storage[0]);
  Vector4 get zwwy =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[3], _v4storage[1]);
  Vector4 get zwwz =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[3], _v4storage[2]);
  Vector4 get zwww =>
      Vector4(_v4storage[2], _v4storage[3], _v4storage[3], _v4storage[3]);
  Vector4 get wxxx =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[0], _v4storage[0]);
  Vector4 get wxxy =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[0], _v4storage[1]);
  Vector4 get wxxz =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[0], _v4storage[2]);
  Vector4 get wxxw =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[0], _v4storage[3]);
  Vector4 get wxyx =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[1], _v4storage[0]);
  Vector4 get wxyy =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[1], _v4storage[1]);
  Vector4 get wxyz =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[1], _v4storage[2]);
  Vector4 get wxyw =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[1], _v4storage[3]);
  Vector4 get wxzx =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[2], _v4storage[0]);
  Vector4 get wxzy =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[2], _v4storage[1]);
  Vector4 get wxzz =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[2], _v4storage[2]);
  Vector4 get wxzw =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[2], _v4storage[3]);
  Vector4 get wxwx =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[3], _v4storage[0]);
  Vector4 get wxwy =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[3], _v4storage[1]);
  Vector4 get wxwz =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[3], _v4storage[2]);
  Vector4 get wxww =>
      Vector4(_v4storage[3], _v4storage[0], _v4storage[3], _v4storage[3]);
  Vector4 get wyxx =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[0], _v4storage[0]);
  Vector4 get wyxy =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[0], _v4storage[1]);
  Vector4 get wyxz =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[0], _v4storage[2]);
  Vector4 get wyxw =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[0], _v4storage[3]);
  Vector4 get wyyx =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[1], _v4storage[0]);
  Vector4 get wyyy =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[1], _v4storage[1]);
  Vector4 get wyyz =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[1], _v4storage[2]);
  Vector4 get wyyw =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[1], _v4storage[3]);
  Vector4 get wyzx =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[2], _v4storage[0]);
  Vector4 get wyzy =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[2], _v4storage[1]);
  Vector4 get wyzz =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[2], _v4storage[2]);
  Vector4 get wyzw =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[2], _v4storage[3]);
  Vector4 get wywx =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[3], _v4storage[0]);
  Vector4 get wywy =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[3], _v4storage[1]);
  Vector4 get wywz =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[3], _v4storage[2]);
  Vector4 get wyww =>
      Vector4(_v4storage[3], _v4storage[1], _v4storage[3], _v4storage[3]);
  Vector4 get wzxx =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[0], _v4storage[0]);
  Vector4 get wzxy =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[0], _v4storage[1]);
  Vector4 get wzxz =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[0], _v4storage[2]);
  Vector4 get wzxw =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[0], _v4storage[3]);
  Vector4 get wzyx =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[1], _v4storage[0]);
  Vector4 get wzyy =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[1], _v4storage[1]);
  Vector4 get wzyz =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[1], _v4storage[2]);
  Vector4 get wzyw =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[1], _v4storage[3]);
  Vector4 get wzzx =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[2], _v4storage[0]);
  Vector4 get wzzy =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[2], _v4storage[1]);
  Vector4 get wzzz =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[2], _v4storage[2]);
  Vector4 get wzzw =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[2], _v4storage[3]);
  Vector4 get wzwx =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[3], _v4storage[0]);
  Vector4 get wzwy =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[3], _v4storage[1]);
  Vector4 get wzwz =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[3], _v4storage[2]);
  Vector4 get wzww =>
      Vector4(_v4storage[3], _v4storage[2], _v4storage[3], _v4storage[3]);
  Vector4 get wwxx =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[0], _v4storage[0]);
  Vector4 get wwxy =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[0], _v4storage[1]);
  Vector4 get wwxz =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[0], _v4storage[2]);
  Vector4 get wwxw =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[0], _v4storage[3]);
  Vector4 get wwyx =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[1], _v4storage[0]);
  Vector4 get wwyy =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[1], _v4storage[1]);
  Vector4 get wwyz =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[1], _v4storage[2]);
  Vector4 get wwyw =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[1], _v4storage[3]);
  Vector4 get wwzx =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[2], _v4storage[0]);
  Vector4 get wwzy =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[2], _v4storage[1]);
  Vector4 get wwzz =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[2], _v4storage[2]);
  Vector4 get wwzw =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[2], _v4storage[3]);
  Vector4 get wwwx =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[3], _v4storage[0]);
  Vector4 get wwwy =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[3], _v4storage[1]);
  Vector4 get wwwz =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[3], _v4storage[2]);
  Vector4 get wwww =>
      Vector4(_v4storage[3], _v4storage[3], _v4storage[3], _v4storage[3]);
  double get r => x;
  double get g => y;
  double get b => z;
  double get a => w;
  double get s => x;
  double get t => y;
  double get p => z;
  double get q => w;
  double get x => _v4storage[0];
  double get y => _v4storage[1];
  double get z => _v4storage[2];
  double get w => _v4storage[3];
  Vector2 get rr => xx;
  Vector2 get rg => xy;
  Vector2 get rb => xz;
  Vector2 get ra => xw;
  Vector2 get gr => yx;
  Vector2 get gg => yy;
  Vector2 get gb => yz;
  Vector2 get ga => yw;
  Vector2 get br => zx;
  Vector2 get bg => zy;
  Vector2 get bb => zz;
  Vector2 get ba => zw;
  Vector2 get ar => wx;
  Vector2 get ag => wy;
  Vector2 get ab => wz;
  Vector2 get aa => ww;
  Vector3 get rrr => xxx;
  Vector3 get rrg => xxy;
  Vector3 get rrb => xxz;
  Vector3 get rra => xxw;
  Vector3 get rgr => xyx;
  Vector3 get rgg => xyy;
  Vector3 get rgb => xyz;
  Vector3 get rga => xyw;
  Vector3 get rbr => xzx;
  Vector3 get rbg => xzy;
  Vector3 get rbb => xzz;
  Vector3 get rba => xzw;
  Vector3 get rar => xwx;
  Vector3 get rag => xwy;
  Vector3 get rab => xwz;
  Vector3 get raa => xww;
  Vector3 get grr => yxx;
  Vector3 get grg => yxy;
  Vector3 get grb => yxz;
  Vector3 get gra => yxw;
  Vector3 get ggr => yyx;
  Vector3 get ggg => yyy;
  Vector3 get ggb => yyz;
  Vector3 get gga => yyw;
  Vector3 get gbr => yzx;
  Vector3 get gbg => yzy;
  Vector3 get gbb => yzz;
  Vector3 get gba => yzw;
  Vector3 get gar => ywx;
  Vector3 get gag => ywy;
  Vector3 get gab => ywz;
  Vector3 get gaa => yww;
  Vector3 get brr => zxx;
  Vector3 get brg => zxy;
  Vector3 get brb => zxz;
  Vector3 get bra => zxw;
  Vector3 get bgr => zyx;
  Vector3 get bgg => zyy;
  Vector3 get bgb => zyz;
  Vector3 get bga => zyw;
  Vector3 get bbr => zzx;
  Vector3 get bbg => zzy;
  Vector3 get bbb => zzz;
  Vector3 get bba => zzw;
  Vector3 get bar => zwx;
  Vector3 get bag => zwy;
  Vector3 get bab => zwz;
  Vector3 get baa => zww;
  Vector3 get arr => wxx;
  Vector3 get arg => wxy;
  Vector3 get arb => wxz;
  Vector3 get ara => wxw;
  Vector3 get agr => wyx;
  Vector3 get agg => wyy;
  Vector3 get agb => wyz;
  Vector3 get aga => wyw;
  Vector3 get abr => wzx;
  Vector3 get abg => wzy;
  Vector3 get abb => wzz;
  Vector3 get aba => wzw;
  Vector3 get aar => wwx;
  Vector3 get aag => wwy;
  Vector3 get aab => wwz;
  Vector3 get aaa => www;
  Vector4 get rrrr => xxxx;
  Vector4 get rrrg => xxxy;
  Vector4 get rrrb => xxxz;
  Vector4 get rrra => xxxw;
  Vector4 get rrgr => xxyx;
  Vector4 get rrgg => xxyy;
  Vector4 get rrgb => xxyz;
  Vector4 get rrga => xxyw;
  Vector4 get rrbr => xxzx;
  Vector4 get rrbg => xxzy;
  Vector4 get rrbb => xxzz;
  Vector4 get rrba => xxzw;
  Vector4 get rrar => xxwx;
  Vector4 get rrag => xxwy;
  Vector4 get rrab => xxwz;
  Vector4 get rraa => xxww;
  Vector4 get rgrr => xyxx;
  Vector4 get rgrg => xyxy;
  Vector4 get rgrb => xyxz;
  Vector4 get rgra => xyxw;
  Vector4 get rggr => xyyx;
  Vector4 get rggg => xyyy;
  Vector4 get rggb => xyyz;
  Vector4 get rgga => xyyw;
  Vector4 get rgbr => xyzx;
  Vector4 get rgbg => xyzy;
  Vector4 get rgbb => xyzz;
  Vector4 get rgba => xyzw;
  Vector4 get rgar => xywx;
  Vector4 get rgag => xywy;
  Vector4 get rgab => xywz;
  Vector4 get rgaa => xyww;
  Vector4 get rbrr => xzxx;
  Vector4 get rbrg => xzxy;
  Vector4 get rbrb => xzxz;
  Vector4 get rbra => xzxw;
  Vector4 get rbgr => xzyx;
  Vector4 get rbgg => xzyy;
  Vector4 get rbgb => xzyz;
  Vector4 get rbga => xzyw;
  Vector4 get rbbr => xzzx;
  Vector4 get rbbg => xzzy;
  Vector4 get rbbb => xzzz;
  Vector4 get rbba => xzzw;
  Vector4 get rbar => xzwx;
  Vector4 get rbag => xzwy;
  Vector4 get rbab => xzwz;
  Vector4 get rbaa => xzww;
  Vector4 get rarr => xwxx;
  Vector4 get rarg => xwxy;
  Vector4 get rarb => xwxz;
  Vector4 get rara => xwxw;
  Vector4 get ragr => xwyx;
  Vector4 get ragg => xwyy;
  Vector4 get ragb => xwyz;
  Vector4 get raga => xwyw;
  Vector4 get rabr => xwzx;
  Vector4 get rabg => xwzy;
  Vector4 get rabb => xwzz;
  Vector4 get raba => xwzw;
  Vector4 get raar => xwwx;
  Vector4 get raag => xwwy;
  Vector4 get raab => xwwz;
  Vector4 get raaa => xwww;
  Vector4 get grrr => yxxx;
  Vector4 get grrg => yxxy;
  Vector4 get grrb => yxxz;
  Vector4 get grra => yxxw;
  Vector4 get grgr => yxyx;
  Vector4 get grgg => yxyy;
  Vector4 get grgb => yxyz;
  Vector4 get grga => yxyw;
  Vector4 get grbr => yxzx;
  Vector4 get grbg => yxzy;
  Vector4 get grbb => yxzz;
  Vector4 get grba => yxzw;
  Vector4 get grar => yxwx;
  Vector4 get grag => yxwy;
  Vector4 get grab => yxwz;
  Vector4 get graa => yxww;
  Vector4 get ggrr => yyxx;
  Vector4 get ggrg => yyxy;
  Vector4 get ggrb => yyxz;
  Vector4 get ggra => yyxw;
  Vector4 get gggr => yyyx;
  Vector4 get gggg => yyyy;
  Vector4 get gggb => yyyz;
  Vector4 get ggga => yyyw;
  Vector4 get ggbr => yyzx;
  Vector4 get ggbg => yyzy;
  Vector4 get ggbb => yyzz;
  Vector4 get ggba => yyzw;
  Vector4 get ggar => yywx;
  Vector4 get ggag => yywy;
  Vector4 get ggab => yywz;
  Vector4 get ggaa => yyww;
  Vector4 get gbrr => yzxx;
  Vector4 get gbrg => yzxy;
  Vector4 get gbrb => yzxz;
  Vector4 get gbra => yzxw;
  Vector4 get gbgr => yzyx;
  Vector4 get gbgg => yzyy;
  Vector4 get gbgb => yzyz;
  Vector4 get gbga => yzyw;
  Vector4 get gbbr => yzzx;
  Vector4 get gbbg => yzzy;
  Vector4 get gbbb => yzzz;
  Vector4 get gbba => yzzw;
  Vector4 get gbar => yzwx;
  Vector4 get gbag => yzwy;
  Vector4 get gbab => yzwz;
  Vector4 get gbaa => yzww;
  Vector4 get garr => ywxx;
  Vector4 get garg => ywxy;
  Vector4 get garb => ywxz;
  Vector4 get gara => ywxw;
  Vector4 get gagr => ywyx;
  Vector4 get gagg => ywyy;
  Vector4 get gagb => ywyz;
  Vector4 get gaga => ywyw;
  Vector4 get gabr => ywzx;
  Vector4 get gabg => ywzy;
  Vector4 get gabb => ywzz;
  Vector4 get gaba => ywzw;
  Vector4 get gaar => ywwx;
  Vector4 get gaag => ywwy;
  Vector4 get gaab => ywwz;
  Vector4 get gaaa => ywww;
  Vector4 get brrr => zxxx;
  Vector4 get brrg => zxxy;
  Vector4 get brrb => zxxz;
  Vector4 get brra => zxxw;
  Vector4 get brgr => zxyx;
  Vector4 get brgg => zxyy;
  Vector4 get brgb => zxyz;
  Vector4 get brga => zxyw;
  Vector4 get brbr => zxzx;
  Vector4 get brbg => zxzy;
  Vector4 get brbb => zxzz;
  Vector4 get brba => zxzw;
  Vector4 get brar => zxwx;
  Vector4 get brag => zxwy;
  Vector4 get brab => zxwz;
  Vector4 get braa => zxww;
  Vector4 get bgrr => zyxx;
  Vector4 get bgrg => zyxy;
  Vector4 get bgrb => zyxz;
  Vector4 get bgra => zyxw;
  Vector4 get bggr => zyyx;
  Vector4 get bggg => zyyy;
  Vector4 get bggb => zyyz;
  Vector4 get bgga => zyyw;
  Vector4 get bgbr => zyzx;
  Vector4 get bgbg => zyzy;
  Vector4 get bgbb => zyzz;
  Vector4 get bgba => zyzw;
  Vector4 get bgar => zywx;
  Vector4 get bgag => zywy;
  Vector4 get bgab => zywz;
  Vector4 get bgaa => zyww;
  Vector4 get bbrr => zzxx;
  Vector4 get bbrg => zzxy;
  Vector4 get bbrb => zzxz;
  Vector4 get bbra => zzxw;
  Vector4 get bbgr => zzyx;
  Vector4 get bbgg => zzyy;
  Vector4 get bbgb => zzyz;
  Vector4 get bbga => zzyw;
  Vector4 get bbbr => zzzx;
  Vector4 get bbbg => zzzy;
  Vector4 get bbbb => zzzz;
  Vector4 get bbba => zzzw;
  Vector4 get bbar => zzwx;
  Vector4 get bbag => zzwy;
  Vector4 get bbab => zzwz;
  Vector4 get bbaa => zzww;
  Vector4 get barr => zwxx;
  Vector4 get barg => zwxy;
  Vector4 get barb => zwxz;
  Vector4 get bara => zwxw;
  Vector4 get bagr => zwyx;
  Vector4 get bagg => zwyy;
  Vector4 get bagb => zwyz;
  Vector4 get baga => zwyw;
  Vector4 get babr => zwzx;
  Vector4 get babg => zwzy;
  Vector4 get babb => zwzz;
  Vector4 get baba => zwzw;
  Vector4 get baar => zwwx;
  Vector4 get baag => zwwy;
  Vector4 get baab => zwwz;
  Vector4 get baaa => zwww;
  Vector4 get arrr => wxxx;
  Vector4 get arrg => wxxy;
  Vector4 get arrb => wxxz;
  Vector4 get arra => wxxw;
  Vector4 get argr => wxyx;
  Vector4 get argg => wxyy;
  Vector4 get argb => wxyz;
  Vector4 get arga => wxyw;
  Vector4 get arbr => wxzx;
  Vector4 get arbg => wxzy;
  Vector4 get arbb => wxzz;
  Vector4 get arba => wxzw;
  Vector4 get arar => wxwx;
  Vector4 get arag => wxwy;
  Vector4 get arab => wxwz;
  Vector4 get araa => wxww;
  Vector4 get agrr => wyxx;
  Vector4 get agrg => wyxy;
  Vector4 get agrb => wyxz;
  Vector4 get agra => wyxw;
  Vector4 get aggr => wyyx;
  Vector4 get aggg => wyyy;
  Vector4 get aggb => wyyz;
  Vector4 get agga => wyyw;
  Vector4 get agbr => wyzx;
  Vector4 get agbg => wyzy;
  Vector4 get agbb => wyzz;
  Vector4 get agba => wyzw;
  Vector4 get agar => wywx;
  Vector4 get agag => wywy;
  Vector4 get agab => wywz;
  Vector4 get agaa => wyww;
  Vector4 get abrr => wzxx;
  Vector4 get abrg => wzxy;
  Vector4 get abrb => wzxz;
  Vector4 get abra => wzxw;
  Vector4 get abgr => wzyx;
  Vector4 get abgg => wzyy;
  Vector4 get abgb => wzyz;
  Vector4 get abga => wzyw;
  Vector4 get abbr => wzzx;
  Vector4 get abbg => wzzy;
  Vector4 get abbb => wzzz;
  Vector4 get abba => wzzw;
  Vector4 get abar => wzwx;
  Vector4 get abag => wzwy;
  Vector4 get abab => wzwz;
  Vector4 get abaa => wzww;
  Vector4 get aarr => wwxx;
  Vector4 get aarg => wwxy;
  Vector4 get aarb => wwxz;
  Vector4 get aara => wwxw;
  Vector4 get aagr => wwyx;
  Vector4 get aagg => wwyy;
  Vector4 get aagb => wwyz;
  Vector4 get aaga => wwyw;
  Vector4 get aabr => wwzx;
  Vector4 get aabg => wwzy;
  Vector4 get aabb => wwzz;
  Vector4 get aaba => wwzw;
  Vector4 get aaar => wwwx;
  Vector4 get aaag => wwwy;
  Vector4 get aaab => wwwz;
  Vector4 get aaaa => wwww;
  Vector2 get ss => xx;
  Vector2 get st => xy;
  Vector2 get sp => xz;
  Vector2 get sq => xw;
  Vector2 get ts => yx;
  Vector2 get tt => yy;
  Vector2 get tp => yz;
  Vector2 get tq => yw;
  Vector2 get ps => zx;
  Vector2 get pt => zy;
  Vector2 get pp => zz;
  Vector2 get pq => zw;
  Vector2 get qs => wx;
  Vector2 get qt => wy;
  Vector2 get qp => wz;
  Vector2 get qq => ww;
  Vector3 get sss => xxx;
  Vector3 get sst => xxy;
  Vector3 get ssp => xxz;
  Vector3 get ssq => xxw;
  Vector3 get sts => xyx;
  Vector3 get stt => xyy;
  Vector3 get stp => xyz;
  Vector3 get stq => xyw;
  Vector3 get sps => xzx;
  Vector3 get spt => xzy;
  Vector3 get spp => xzz;
  Vector3 get spq => xzw;
  Vector3 get sqs => xwx;
  Vector3 get sqt => xwy;
  Vector3 get sqp => xwz;
  Vector3 get sqq => xww;
  Vector3 get tss => yxx;
  Vector3 get tst => yxy;
  Vector3 get tsp => yxz;
  Vector3 get tsq => yxw;
  Vector3 get tts => yyx;
  Vector3 get ttt => yyy;
  Vector3 get ttp => yyz;
  Vector3 get ttq => yyw;
  Vector3 get tps => yzx;
  Vector3 get tpt => yzy;
  Vector3 get tpp => yzz;
  Vector3 get tpq => yzw;
  Vector3 get tqs => ywx;
  Vector3 get tqt => ywy;
  Vector3 get tqp => ywz;
  Vector3 get tqq => yww;
  Vector3 get pss => zxx;
  Vector3 get pst => zxy;
  Vector3 get psp => zxz;
  Vector3 get psq => zxw;
  Vector3 get pts => zyx;
  Vector3 get ptt => zyy;
  Vector3 get ptp => zyz;
  Vector3 get ptq => zyw;
  Vector3 get pps => zzx;
  Vector3 get ppt => zzy;
  Vector3 get ppp => zzz;
  Vector3 get ppq => zzw;
  Vector3 get pqs => zwx;
  Vector3 get pqt => zwy;
  Vector3 get pqp => zwz;
  Vector3 get pqq => zww;
  Vector3 get qss => wxx;
  Vector3 get qst => wxy;
  Vector3 get qsp => wxz;
  Vector3 get qsq => wxw;
  Vector3 get qts => wyx;
  Vector3 get qtt => wyy;
  Vector3 get qtp => wyz;
  Vector3 get qtq => wyw;
  Vector3 get qps => wzx;
  Vector3 get qpt => wzy;
  Vector3 get qpp => wzz;
  Vector3 get qpq => wzw;
  Vector3 get qqs => wwx;
  Vector3 get qqt => wwy;
  Vector3 get qqp => wwz;
  Vector3 get qqq => www;
  Vector4 get ssss => xxxx;
  Vector4 get ssst => xxxy;
  Vector4 get sssp => xxxz;
  Vector4 get sssq => xxxw;
  Vector4 get ssts => xxyx;
  Vector4 get sstt => xxyy;
  Vector4 get sstp => xxyz;
  Vector4 get sstq => xxyw;
  Vector4 get ssps => xxzx;
  Vector4 get sspt => xxzy;
  Vector4 get sspp => xxzz;
  Vector4 get sspq => xxzw;
  Vector4 get ssqs => xxwx;
  Vector4 get ssqt => xxwy;
  Vector4 get ssqp => xxwz;
  Vector4 get ssqq => xxww;
  Vector4 get stss => xyxx;
  Vector4 get stst => xyxy;
  Vector4 get stsp => xyxz;
  Vector4 get stsq => xyxw;
  Vector4 get stts => xyyx;
  Vector4 get sttt => xyyy;
  Vector4 get sttp => xyyz;
  Vector4 get sttq => xyyw;
  Vector4 get stps => xyzx;
  Vector4 get stpt => xyzy;
  Vector4 get stpp => xyzz;
  Vector4 get stpq => xyzw;
  Vector4 get stqs => xywx;
  Vector4 get stqt => xywy;
  Vector4 get stqp => xywz;
  Vector4 get stqq => xyww;
  Vector4 get spss => xzxx;
  Vector4 get spst => xzxy;
  Vector4 get spsp => xzxz;
  Vector4 get spsq => xzxw;
  Vector4 get spts => xzyx;
  Vector4 get sptt => xzyy;
  Vector4 get sptp => xzyz;
  Vector4 get sptq => xzyw;
  Vector4 get spps => xzzx;
  Vector4 get sppt => xzzy;
  Vector4 get sppp => xzzz;
  Vector4 get sppq => xzzw;
  Vector4 get spqs => xzwx;
  Vector4 get spqt => xzwy;
  Vector4 get spqp => xzwz;
  Vector4 get spqq => xzww;
  Vector4 get sqss => xwxx;
  Vector4 get sqst => xwxy;
  Vector4 get sqsp => xwxz;
  Vector4 get sqsq => xwxw;
  Vector4 get sqts => xwyx;
  Vector4 get sqtt => xwyy;
  Vector4 get sqtp => xwyz;
  Vector4 get sqtq => xwyw;
  Vector4 get sqps => xwzx;
  Vector4 get sqpt => xwzy;
  Vector4 get sqpp => xwzz;
  Vector4 get sqpq => xwzw;
  Vector4 get sqqs => xwwx;
  Vector4 get sqqt => xwwy;
  Vector4 get sqqp => xwwz;
  Vector4 get sqqq => xwww;
  Vector4 get tsss => yxxx;
  Vector4 get tsst => yxxy;
  Vector4 get tssp => yxxz;
  Vector4 get tssq => yxxw;
  Vector4 get tsts => yxyx;
  Vector4 get tstt => yxyy;
  Vector4 get tstp => yxyz;
  Vector4 get tstq => yxyw;
  Vector4 get tsps => yxzx;
  Vector4 get tspt => yxzy;
  Vector4 get tspp => yxzz;
  Vector4 get tspq => yxzw;
  Vector4 get tsqs => yxwx;
  Vector4 get tsqt => yxwy;
  Vector4 get tsqp => yxwz;
  Vector4 get tsqq => yxww;
  Vector4 get ttss => yyxx;
  Vector4 get ttst => yyxy;
  Vector4 get ttsp => yyxz;
  Vector4 get ttsq => yyxw;
  Vector4 get ttts => yyyx;
  Vector4 get tttt => yyyy;
  Vector4 get tttp => yyyz;
  Vector4 get tttq => yyyw;
  Vector4 get ttps => yyzx;
  Vector4 get ttpt => yyzy;
  Vector4 get ttpp => yyzz;
  Vector4 get ttpq => yyzw;
  Vector4 get ttqs => yywx;
  Vector4 get ttqt => yywy;
  Vector4 get ttqp => yywz;
  Vector4 get ttqq => yyww;
  Vector4 get tpss => yzxx;
  Vector4 get tpst => yzxy;
  Vector4 get tpsp => yzxz;
  Vector4 get tpsq => yzxw;
  Vector4 get tpts => yzyx;
  Vector4 get tptt => yzyy;
  Vector4 get tptp => yzyz;
  Vector4 get tptq => yzyw;
  Vector4 get tpps => yzzx;
  Vector4 get tppt => yzzy;
  Vector4 get tppp => yzzz;
  Vector4 get tppq => yzzw;
  Vector4 get tpqs => yzwx;
  Vector4 get tpqt => yzwy;
  Vector4 get tpqp => yzwz;
  Vector4 get tpqq => yzww;
  Vector4 get tqss => ywxx;
  Vector4 get tqst => ywxy;
  Vector4 get tqsp => ywxz;
  Vector4 get tqsq => ywxw;
  Vector4 get tqts => ywyx;
  Vector4 get tqtt => ywyy;
  Vector4 get tqtp => ywyz;
  Vector4 get tqtq => ywyw;
  Vector4 get tqps => ywzx;
  Vector4 get tqpt => ywzy;
  Vector4 get tqpp => ywzz;
  Vector4 get tqpq => ywzw;
  Vector4 get tqqs => ywwx;
  Vector4 get tqqt => ywwy;
  Vector4 get tqqp => ywwz;
  Vector4 get tqqq => ywww;
  Vector4 get psss => zxxx;
  Vector4 get psst => zxxy;
  Vector4 get pssp => zxxz;
  Vector4 get pssq => zxxw;
  Vector4 get psts => zxyx;
  Vector4 get pstt => zxyy;
  Vector4 get pstp => zxyz;
  Vector4 get pstq => zxyw;
  Vector4 get psps => zxzx;
  Vector4 get pspt => zxzy;
  Vector4 get pspp => zxzz;
  Vector4 get pspq => zxzw;
  Vector4 get psqs => zxwx;
  Vector4 get psqt => zxwy;
  Vector4 get psqp => zxwz;
  Vector4 get psqq => zxww;
  Vector4 get ptss => zyxx;
  Vector4 get ptst => zyxy;
  Vector4 get ptsp => zyxz;
  Vector4 get ptsq => zyxw;
  Vector4 get ptts => zyyx;
  Vector4 get pttt => zyyy;
  Vector4 get pttp => zyyz;
  Vector4 get pttq => zyyw;
  Vector4 get ptps => zyzx;
  Vector4 get ptpt => zyzy;
  Vector4 get ptpp => zyzz;
  Vector4 get ptpq => zyzw;
  Vector4 get ptqs => zywx;
  Vector4 get ptqt => zywy;
  Vector4 get ptqp => zywz;
  Vector4 get ptqq => zyww;
  Vector4 get ppss => zzxx;
  Vector4 get ppst => zzxy;
  Vector4 get ppsp => zzxz;
  Vector4 get ppsq => zzxw;
  Vector4 get ppts => zzyx;
  Vector4 get pptt => zzyy;
  Vector4 get pptp => zzyz;
  Vector4 get pptq => zzyw;
  Vector4 get ppps => zzzx;
  Vector4 get pppt => zzzy;
  Vector4 get pppp => zzzz;
  Vector4 get pppq => zzzw;
  Vector4 get ppqs => zzwx;
  Vector4 get ppqt => zzwy;
  Vector4 get ppqp => zzwz;
  Vector4 get ppqq => zzww;
  Vector4 get pqss => zwxx;
  Vector4 get pqst => zwxy;
  Vector4 get pqsp => zwxz;
  Vector4 get pqsq => zwxw;
  Vector4 get pqts => zwyx;
  Vector4 get pqtt => zwyy;
  Vector4 get pqtp => zwyz;
  Vector4 get pqtq => zwyw;
  Vector4 get pqps => zwzx;
  Vector4 get pqpt => zwzy;
  Vector4 get pqpp => zwzz;
  Vector4 get pqpq => zwzw;
  Vector4 get pqqs => zwwx;
  Vector4 get pqqt => zwwy;
  Vector4 get pqqp => zwwz;
  Vector4 get pqqq => zwww;
  Vector4 get qsss => wxxx;
  Vector4 get qsst => wxxy;
  Vector4 get qssp => wxxz;
  Vector4 get qssq => wxxw;
  Vector4 get qsts => wxyx;
  Vector4 get qstt => wxyy;
  Vector4 get qstp => wxyz;
  Vector4 get qstq => wxyw;
  Vector4 get qsps => wxzx;
  Vector4 get qspt => wxzy;
  Vector4 get qspp => wxzz;
  Vector4 get qspq => wxzw;
  Vector4 get qsqs => wxwx;
  Vector4 get qsqt => wxwy;
  Vector4 get qsqp => wxwz;
  Vector4 get qsqq => wxww;
  Vector4 get qtss => wyxx;
  Vector4 get qtst => wyxy;
  Vector4 get qtsp => wyxz;
  Vector4 get qtsq => wyxw;
  Vector4 get qtts => wyyx;
  Vector4 get qttt => wyyy;
  Vector4 get qttp => wyyz;
  Vector4 get qttq => wyyw;
  Vector4 get qtps => wyzx;
  Vector4 get qtpt => wyzy;
  Vector4 get qtpp => wyzz;
  Vector4 get qtpq => wyzw;
  Vector4 get qtqs => wywx;
  Vector4 get qtqt => wywy;
  Vector4 get qtqp => wywz;
  Vector4 get qtqq => wyww;
  Vector4 get qpss => wzxx;
  Vector4 get qpst => wzxy;
  Vector4 get qpsp => wzxz;
  Vector4 get qpsq => wzxw;
  Vector4 get qpts => wzyx;
  Vector4 get qptt => wzyy;
  Vector4 get qptp => wzyz;
  Vector4 get qptq => wzyw;
  Vector4 get qpps => wzzx;
  Vector4 get qppt => wzzy;
  Vector4 get qppp => wzzz;
  Vector4 get qppq => wzzw;
  Vector4 get qpqs => wzwx;
  Vector4 get qpqt => wzwy;
  Vector4 get qpqp => wzwz;
  Vector4 get qpqq => wzww;
  Vector4 get qqss => wwxx;
  Vector4 get qqst => wwxy;
  Vector4 get qqsp => wwxz;
  Vector4 get qqsq => wwxw;
  Vector4 get qqts => wwyx;
  Vector4 get qqtt => wwyy;
  Vector4 get qqtp => wwyz;
  Vector4 get qqtq => wwyw;
  Vector4 get qqps => wwzx;
  Vector4 get qqpt => wwzy;
  Vector4 get qqpp => wwzz;
  Vector4 get qqpq => wwzw;
  Vector4 get qqqs => wwwx;
  Vector4 get qqqt => wwwy;
  Vector4 get qqqp => wwwz;
  Vector4 get qqqq => wwww;
}

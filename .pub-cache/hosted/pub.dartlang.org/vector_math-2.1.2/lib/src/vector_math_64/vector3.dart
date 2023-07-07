// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_64;

/// 3D column vector.
class Vector3 implements Vector {
  final Float64List _v3storage;

  /// The components of the vector.
  @override
  Float64List get storage => _v3storage;

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

  /// Initialized with values from [array] starting at [offset].
  factory Vector3.array(List<double> array, [int offset = 0]) =>
      Vector3.zero()..copyFromArray(array, offset);

  /// Zero vector.
  Vector3.zero() : _v3storage = Float64List(3);

  /// Splat [value] into all lanes of the vector.
  factory Vector3.all(double value) => Vector3.zero()..splat(value);

  /// Copy of [other].
  factory Vector3.copy(Vector3 other) => Vector3.zero()..setFrom(other);

  /// Constructs Vector3 with given Float64List as [storage].
  Vector3.fromFloat64List(this._v3storage);

  /// Constructs Vector3 with a [storage] that views given [buffer] starting at
  /// [offset]. [offset] has to be multiple of [Float64List.bytesPerElement].
  Vector3.fromBuffer(ByteBuffer buffer, int offset)
      : _v3storage = Float64List.view(buffer, offset, 3);

  /// Generate random vector in the range (0, 0, 0) to (1, 1, 1). You can
  /// optionally pass your own random number generator.
  factory Vector3.random([math.Random? rng]) {
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
    final otherStorage = other._v3storage;
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

  /// Returns a printable string
  @override
  String toString() => '[${storage[0]},${storage[1]},${storage[2]}]';

  /// Check if two vectors are the same.
  @override
  bool operator ==(Object? other) =>
      (other is Vector3) &&
      (_v3storage[0] == other._v3storage[0]) &&
      (_v3storage[1] == other._v3storage[1]) &&
      (_v3storage[2] == other._v3storage[2]);

  @override
  int get hashCode => Object.hashAll(_v3storage);

  /// Negate
  Vector3 operator -() => clone()..negate();

  /// Subtract two vectors.
  Vector3 operator -(Vector3 other) => clone()..sub(other);

  /// Add two vectors.
  Vector3 operator +(Vector3 other) => clone()..add(other);

  /// Scale.
  Vector3 operator /(double scale) => scaled(1.0 / scale);

  /// Scale by [scale].
  Vector3 operator *(double scale) => scaled(scale);

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
      var l = length;
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

  /// Normalizes this.
  double normalize() {
    final l = length;
    if (l == 0.0) {
      return 0.0;
    }
    final d = 1.0 / l;
    _v3storage[0] *= d;
    _v3storage[1] *= d;
    _v3storage[2] *= d;
    return l;
  }

  /// Normalize this. Returns length of vector before normalization.
  /// DEPRCATED: Use [normalize].
  @Deprecated('Use normalize() insteaed.')
  double normalizeLength() => normalize();

  /// Normalizes copy of this.
  Vector3 normalized() => Vector3.copy(this)..normalize();

  /// Normalize vector into [out].
  Vector3 normalizeInto(Vector3 out) {
    out
      ..setFrom(this)
      ..normalize();
    return out;
  }

  /// Distance from this to [arg]
  double distanceTo(Vector3 arg) => math.sqrt(distanceToSquared(arg));

  /// Squared distance from this to [arg]
  double distanceToSquared(Vector3 arg) {
    final argStorage = arg._v3storage;
    final dx = _v3storage[0] - argStorage[0];
    final dy = _v3storage[1] - argStorage[1];
    final dz = _v3storage[2] - argStorage[2];

    return dx * dx + dy * dy + dz * dz;
  }

  /// Returns the angle between this vector and [other] in radians.
  double angleTo(Vector3 other) {
    final otherStorage = other._v3storage;
    if (_v3storage[0] == otherStorage[0] &&
        _v3storage[1] == otherStorage[1] &&
        _v3storage[2] == otherStorage[2]) {
      return 0.0;
    }

    final d = dot(other) / (length * other.length);

    return math.acos(d.clamp(-1.0, 1.0));
  }

  /// Returns the signed angle between this and [other] around [normal]
  /// in radians.
  double angleToSigned(Vector3 other, Vector3 normal) {
    final angle = angleTo(other);
    final c = cross(other);
    final d = c.dot(normal);

    return d < 0.0 ? -angle : angle;
  }

  /// Inner product.
  double dot(Vector3 other) {
    final otherStorage = other._v3storage;
    double sum;
    sum = _v3storage[0] * otherStorage[0];
    sum += _v3storage[1] * otherStorage[1];
    sum += _v3storage[2] * otherStorage[2];
    return sum;
  }

  /// Transforms this into the product of this as a row vector,
  /// postmultiplied by matrix, [arg].
  /// If [arg] is a rotation matrix, this is a computational shortcut for applying,
  /// the inverse of the transformation.
  void postmultiply(Matrix3 arg) {
    final argStorage = arg.storage;
    final v0 = _v3storage[0];
    final v1 = _v3storage[1];
    final v2 = _v3storage[2];

    _v3storage[0] =
        v0 * argStorage[0] + v1 * argStorage[1] + v2 * argStorage[2];
    _v3storage[1] =
        v0 * argStorage[3] + v1 * argStorage[4] + v2 * argStorage[5];
    _v3storage[2] =
        v0 * argStorage[6] + v1 * argStorage[7] + v2 * argStorage[8];
  }

  /// Cross product.
  Vector3 cross(Vector3 other) {
    final _x = _v3storage[0];
    final _y = _v3storage[1];
    final _z = _v3storage[2];
    final otherStorage = other._v3storage;
    final ox = otherStorage[0];
    final oy = otherStorage[1];
    final oz = otherStorage[2];
    return Vector3(_y * oz - _z * oy, _z * ox - _x * oz, _x * oy - _y * ox);
  }

  /// Cross product. Stores result in [out].
  Vector3 crossInto(Vector3 other, Vector3 out) {
    final x = _v3storage[0];
    final y = _v3storage[1];
    final z = _v3storage[2];
    final otherStorage = other._v3storage;
    final ox = otherStorage[0];
    final oy = otherStorage[1];
    final oz = otherStorage[2];
    final outStorage = out._v3storage;
    outStorage[0] = y * oz - z * oy;
    outStorage[1] = z * ox - x * oz;
    outStorage[2] = x * oy - y * ox;
    return out;
  }

  /// Reflect this.
  void reflect(Vector3 normal) {
    sub(normal.scaled(2.0 * normal.dot(this)));
  }

  /// Reflected copy of this.
  Vector3 reflected(Vector3 normal) => clone()..reflect(normal);

  /// Projects this using the projection matrix [arg]
  void applyProjection(Matrix4 arg) {
    final argStorage = arg.storage;
    final x = _v3storage[0];
    final y = _v3storage[1];
    final z = _v3storage[2];
    final d = 1.0 /
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

  /// Applies a rotation specified by [axis] and [angle].
  void applyAxisAngle(Vector3 axis, double angle) {
    applyQuaternion(Quaternion.axisAngle(axis, angle));
  }

  /// Applies a quaternion transform.
  void applyQuaternion(Quaternion arg) {
    final argStorage = arg._qStorage;
    final v0 = _v3storage[0];
    final v1 = _v3storage[1];
    final v2 = _v3storage[2];
    final qx = argStorage[0];
    final qy = argStorage[1];
    final qz = argStorage[2];
    final qw = argStorage[3];
    final ix = qw * v0 + qy * v2 - qz * v1;
    final iy = qw * v1 + qz * v0 - qx * v2;
    final iz = qw * v2 + qx * v1 - qy * v0;
    final iw = -qx * v0 - qy * v1 - qz * v2;
    _v3storage[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy;
    _v3storage[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz;
    _v3storage[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx;
  }

  /// Multiplies this by [arg].
  void applyMatrix3(Matrix3 arg) {
    final argStorage = arg.storage;
    final v0 = _v3storage[0];
    final v1 = _v3storage[1];
    final v2 = _v3storage[2];
    _v3storage[0] =
        argStorage[0] * v0 + argStorage[3] * v1 + argStorage[6] * v2;
    _v3storage[1] =
        argStorage[1] * v0 + argStorage[4] * v1 + argStorage[7] * v2;
    _v3storage[2] =
        argStorage[2] * v0 + argStorage[5] * v1 + argStorage[8] * v2;
  }

  /// Multiplies this by a 4x3 subset of [arg]. Expects [arg] to be an affine
  /// transformation matrix.
  void applyMatrix4(Matrix4 arg) {
    final argStorage = arg.storage;
    final v0 = _v3storage[0];
    final v1 = _v3storage[1];
    final v2 = _v3storage[2];
    _v3storage[0] = argStorage[0] * v0 +
        argStorage[4] * v1 +
        argStorage[8] * v2 +
        argStorage[12];
    _v3storage[1] = argStorage[1] * v0 +
        argStorage[5] * v1 +
        argStorage[9] * v2 +
        argStorage[13];
    _v3storage[2] = argStorage[2] * v0 +
        argStorage[6] * v1 +
        argStorage[10] * v2 +
        argStorage[14];
  }

  /// Relative error between this and [correct]
  double relativeError(Vector3 correct) {
    final correct_norm = correct.length;
    final diff_norm = (this - correct).length;
    return diff_norm / correct_norm;
  }

  /// Absolute error between this and [correct]
  double absoluteError(Vector3 correct) => (this - correct).length;

  /// True if any component is infinite.
  bool get isInfinite {
    var is_infinite = false;
    is_infinite = is_infinite || _v3storage[0].isInfinite;
    is_infinite = is_infinite || _v3storage[1].isInfinite;
    is_infinite = is_infinite || _v3storage[2].isInfinite;
    return is_infinite;
  }

  /// True if any component is NaN.
  bool get isNaN {
    var isNan = false;
    isNan = isNan || _v3storage[0].isNaN;
    isNan = isNan || _v3storage[1].isNaN;
    isNan = isNan || _v3storage[2].isNaN;
    return isNan;
  }

  /// Add [arg] to this.
  void add(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] + argStorage[0];
    _v3storage[1] = _v3storage[1] + argStorage[1];
    _v3storage[2] = _v3storage[2] + argStorage[2];
  }

  /// Add [arg] scaled by [factor] to this.
  void addScaled(Vector3 arg, double factor) {
    final argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] + argStorage[0] * factor;
    _v3storage[1] = _v3storage[1] + argStorage[1] * factor;
    _v3storage[2] = _v3storage[2] + argStorage[2] * factor;
  }

  /// Subtract [arg] from this.
  void sub(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] - argStorage[0];
    _v3storage[1] = _v3storage[1] - argStorage[1];
    _v3storage[2] = _v3storage[2] - argStorage[2];
  }

  /// Multiply entries in this with entries in [arg].
  void multiply(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] * argStorage[0];
    _v3storage[1] = _v3storage[1] * argStorage[1];
    _v3storage[2] = _v3storage[2] * argStorage[2];
  }

  /// Divide entries in this with entries in [arg].
  void divide(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[0] = _v3storage[0] / argStorage[0];
    _v3storage[1] = _v3storage[1] / argStorage[1];
    _v3storage[2] = _v3storage[2] / argStorage[2];
  }

  /// Scale this.
  void scale(double arg) {
    _v3storage[2] = _v3storage[2] * arg;
    _v3storage[1] = _v3storage[1] * arg;
    _v3storage[0] = _v3storage[0] * arg;
  }

  /// Create a copy of this and scale it by [arg].
  Vector3 scaled(double arg) => clone()..scale(arg);

  /// Negate this.
  void negate() {
    _v3storage[2] = -_v3storage[2];
    _v3storage[1] = -_v3storage[1];
    _v3storage[0] = -_v3storage[0];
  }

  /// Absolute value.
  void absolute() {
    _v3storage[0] = _v3storage[0].abs();
    _v3storage[1] = _v3storage[1].abs();
    _v3storage[2] = _v3storage[2].abs();
  }

  /// Clamp each entry n in this in the range [min[n]]-[max[n]].
  void clamp(Vector3 min, Vector3 max) {
    final minStorage = min.storage;
    final maxStorage = max.storage;
    _v3storage[0] =
        _v3storage[0].clamp(minStorage[0], maxStorage[0]).toDouble();
    _v3storage[1] =
        _v3storage[1].clamp(minStorage[1], maxStorage[1]).toDouble();
    _v3storage[2] =
        _v3storage[2].clamp(minStorage[2], maxStorage[2]).toDouble();
  }

  /// Clamp entries in this in the range [min]-[max].
  void clampScalar(double min, double max) {
    _v3storage[0] = _v3storage[0].clamp(min, max).toDouble();
    _v3storage[1] = _v3storage[1].clamp(min, max).toDouble();
    _v3storage[2] = _v3storage[2].clamp(min, max).toDouble();
  }

  /// Floor entries in this.
  void floor() {
    _v3storage[0] = _v3storage[0].floorToDouble();
    _v3storage[1] = _v3storage[1].floorToDouble();
    _v3storage[2] = _v3storage[2].floorToDouble();
  }

  /// Ceil entries in this.
  void ceil() {
    _v3storage[0] = _v3storage[0].ceilToDouble();
    _v3storage[1] = _v3storage[1].ceilToDouble();
    _v3storage[2] = _v3storage[2].ceilToDouble();
  }

  /// Round entries in this.
  void round() {
    _v3storage[0] = _v3storage[0].roundToDouble();
    _v3storage[1] = _v3storage[1].roundToDouble();
    _v3storage[2] = _v3storage[2].roundToDouble();
  }

  /// Round entries in this towards zero.
  void roundToZero() {
    _v3storage[0] = _v3storage[0] < 0.0
        ? _v3storage[0].ceilToDouble()
        : _v3storage[0].floorToDouble();
    _v3storage[1] = _v3storage[1] < 0.0
        ? _v3storage[1].ceilToDouble()
        : _v3storage[1].floorToDouble();
    _v3storage[2] = _v3storage[2] < 0.0
        ? _v3storage[2].ceilToDouble()
        : _v3storage[2].floorToDouble();
  }

  /// Clone of this.
  Vector3 clone() => Vector3.copy(this);

  /// Copy this into [arg].
  Vector3 copyInto(Vector3 arg) {
    final argStorage = arg._v3storage;
    argStorage[0] = _v3storage[0];
    argStorage[1] = _v3storage[1];
    argStorage[2] = _v3storage[2];
    return arg;
  }

  /// Copies this into [array] starting at [offset].
  void copyIntoArray(List<double> array, [int offset = 0]) {
    array[offset + 2] = _v3storage[2];
    array[offset + 1] = _v3storage[1];
    array[offset + 0] = _v3storage[0];
  }

  /// Copies elements from [array] into this starting at [offset].
  void copyFromArray(List<double> array, [int offset = 0]) {
    _v3storage[2] = array[offset + 2];
    _v3storage[1] = array[offset + 1];
    _v3storage[0] = array[offset + 0];
  }

  set xy(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v3storage[0] = argStorage[0];
    _v3storage[1] = argStorage[1];
  }

  set xz(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v3storage[0] = argStorage[0];
    _v3storage[2] = argStorage[1];
  }

  set yx(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v3storage[1] = argStorage[0];
    _v3storage[0] = argStorage[1];
  }

  set yz(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v3storage[1] = argStorage[0];
    _v3storage[2] = argStorage[1];
  }

  set zx(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v3storage[2] = argStorage[0];
    _v3storage[0] = argStorage[1];
  }

  set zy(Vector2 arg) {
    final argStorage = arg._v2storage;
    _v3storage[2] = argStorage[0];
    _v3storage[1] = argStorage[1];
  }

  set xyz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[0] = argStorage[0];
    _v3storage[1] = argStorage[1];
    _v3storage[2] = argStorage[2];
  }

  set xzy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[0] = argStorage[0];
    _v3storage[2] = argStorage[1];
    _v3storage[1] = argStorage[2];
  }

  set yxz(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[1] = argStorage[0];
    _v3storage[0] = argStorage[1];
    _v3storage[2] = argStorage[2];
  }

  set yzx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[1] = argStorage[0];
    _v3storage[2] = argStorage[1];
    _v3storage[0] = argStorage[2];
  }

  set zxy(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[2] = argStorage[0];
    _v3storage[0] = argStorage[1];
    _v3storage[1] = argStorage[2];
  }

  set zyx(Vector3 arg) {
    final argStorage = arg._v3storage;
    _v3storage[2] = argStorage[0];
    _v3storage[1] = argStorage[1];
    _v3storage[0] = argStorage[2];
  }

  set r(double arg) => x = arg;
  set g(double arg) => y = arg;
  set b(double arg) => z = arg;
  set s(double arg) => x = arg;
  set t(double arg) => y = arg;
  set p(double arg) => z = arg;
  set x(double arg) => _v3storage[0] = arg;
  set y(double arg) => _v3storage[1] = arg;
  set z(double arg) => _v3storage[2] = arg;
  set rg(Vector2 arg) => xy = arg;
  set rb(Vector2 arg) => xz = arg;
  set gr(Vector2 arg) => yx = arg;
  set gb(Vector2 arg) => yz = arg;
  set br(Vector2 arg) => zx = arg;
  set bg(Vector2 arg) => zy = arg;
  set rgb(Vector3 arg) => xyz = arg;
  set rbg(Vector3 arg) => xzy = arg;
  set grb(Vector3 arg) => yxz = arg;
  set gbr(Vector3 arg) => yzx = arg;
  set brg(Vector3 arg) => zxy = arg;
  set bgr(Vector3 arg) => zyx = arg;
  set st(Vector2 arg) => xy = arg;
  set sp(Vector2 arg) => xz = arg;
  set ts(Vector2 arg) => yx = arg;
  set tp(Vector2 arg) => yz = arg;
  set ps(Vector2 arg) => zx = arg;
  set pt(Vector2 arg) => zy = arg;
  set stp(Vector3 arg) => xyz = arg;
  set spt(Vector3 arg) => xzy = arg;
  set tsp(Vector3 arg) => yxz = arg;
  set tps(Vector3 arg) => yzx = arg;
  set pst(Vector3 arg) => zxy = arg;
  set pts(Vector3 arg) => zyx = arg;
  Vector2 get xx => Vector2(_v3storage[0], _v3storage[0]);
  Vector2 get xy => Vector2(_v3storage[0], _v3storage[1]);
  Vector2 get xz => Vector2(_v3storage[0], _v3storage[2]);
  Vector2 get yx => Vector2(_v3storage[1], _v3storage[0]);
  Vector2 get yy => Vector2(_v3storage[1], _v3storage[1]);
  Vector2 get yz => Vector2(_v3storage[1], _v3storage[2]);
  Vector2 get zx => Vector2(_v3storage[2], _v3storage[0]);
  Vector2 get zy => Vector2(_v3storage[2], _v3storage[1]);
  Vector2 get zz => Vector2(_v3storage[2], _v3storage[2]);
  Vector3 get xxx => Vector3(_v3storage[0], _v3storage[0], _v3storage[0]);
  Vector3 get xxy => Vector3(_v3storage[0], _v3storage[0], _v3storage[1]);
  Vector3 get xxz => Vector3(_v3storage[0], _v3storage[0], _v3storage[2]);
  Vector3 get xyx => Vector3(_v3storage[0], _v3storage[1], _v3storage[0]);
  Vector3 get xyy => Vector3(_v3storage[0], _v3storage[1], _v3storage[1]);
  Vector3 get xyz => Vector3(_v3storage[0], _v3storage[1], _v3storage[2]);
  Vector3 get xzx => Vector3(_v3storage[0], _v3storage[2], _v3storage[0]);
  Vector3 get xzy => Vector3(_v3storage[0], _v3storage[2], _v3storage[1]);
  Vector3 get xzz => Vector3(_v3storage[0], _v3storage[2], _v3storage[2]);
  Vector3 get yxx => Vector3(_v3storage[1], _v3storage[0], _v3storage[0]);
  Vector3 get yxy => Vector3(_v3storage[1], _v3storage[0], _v3storage[1]);
  Vector3 get yxz => Vector3(_v3storage[1], _v3storage[0], _v3storage[2]);
  Vector3 get yyx => Vector3(_v3storage[1], _v3storage[1], _v3storage[0]);
  Vector3 get yyy => Vector3(_v3storage[1], _v3storage[1], _v3storage[1]);
  Vector3 get yyz => Vector3(_v3storage[1], _v3storage[1], _v3storage[2]);
  Vector3 get yzx => Vector3(_v3storage[1], _v3storage[2], _v3storage[0]);
  Vector3 get yzy => Vector3(_v3storage[1], _v3storage[2], _v3storage[1]);
  Vector3 get yzz => Vector3(_v3storage[1], _v3storage[2], _v3storage[2]);
  Vector3 get zxx => Vector3(_v3storage[2], _v3storage[0], _v3storage[0]);
  Vector3 get zxy => Vector3(_v3storage[2], _v3storage[0], _v3storage[1]);
  Vector3 get zxz => Vector3(_v3storage[2], _v3storage[0], _v3storage[2]);
  Vector3 get zyx => Vector3(_v3storage[2], _v3storage[1], _v3storage[0]);
  Vector3 get zyy => Vector3(_v3storage[2], _v3storage[1], _v3storage[1]);
  Vector3 get zyz => Vector3(_v3storage[2], _v3storage[1], _v3storage[2]);
  Vector3 get zzx => Vector3(_v3storage[2], _v3storage[2], _v3storage[0]);
  Vector3 get zzy => Vector3(_v3storage[2], _v3storage[2], _v3storage[1]);
  Vector3 get zzz => Vector3(_v3storage[2], _v3storage[2], _v3storage[2]);
  Vector4 get xxxx =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[0], _v3storage[0]);
  Vector4 get xxxy =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[0], _v3storage[1]);
  Vector4 get xxxz =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[0], _v3storage[2]);
  Vector4 get xxyx =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[1], _v3storage[0]);
  Vector4 get xxyy =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[1], _v3storage[1]);
  Vector4 get xxyz =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[1], _v3storage[2]);
  Vector4 get xxzx =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[2], _v3storage[0]);
  Vector4 get xxzy =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[2], _v3storage[1]);
  Vector4 get xxzz =>
      Vector4(_v3storage[0], _v3storage[0], _v3storage[2], _v3storage[2]);
  Vector4 get xyxx =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[0], _v3storage[0]);
  Vector4 get xyxy =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[0], _v3storage[1]);
  Vector4 get xyxz =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[0], _v3storage[2]);
  Vector4 get xyyx =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[1], _v3storage[0]);
  Vector4 get xyyy =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[1], _v3storage[1]);
  Vector4 get xyyz =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[1], _v3storage[2]);
  Vector4 get xyzx =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[2], _v3storage[0]);
  Vector4 get xyzy =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[2], _v3storage[1]);
  Vector4 get xyzz =>
      Vector4(_v3storage[0], _v3storage[1], _v3storage[2], _v3storage[2]);
  Vector4 get xzxx =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[0], _v3storage[0]);
  Vector4 get xzxy =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[0], _v3storage[1]);
  Vector4 get xzxz =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[0], _v3storage[2]);
  Vector4 get xzyx =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[1], _v3storage[0]);
  Vector4 get xzyy =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[1], _v3storage[1]);
  Vector4 get xzyz =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[1], _v3storage[2]);
  Vector4 get xzzx =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[2], _v3storage[0]);
  Vector4 get xzzy =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[2], _v3storage[1]);
  Vector4 get xzzz =>
      Vector4(_v3storage[0], _v3storage[2], _v3storage[2], _v3storage[2]);
  Vector4 get yxxx =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[0], _v3storage[0]);
  Vector4 get yxxy =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[0], _v3storage[1]);
  Vector4 get yxxz =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[0], _v3storage[2]);
  Vector4 get yxyx =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[1], _v3storage[0]);
  Vector4 get yxyy =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[1], _v3storage[1]);
  Vector4 get yxyz =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[1], _v3storage[2]);
  Vector4 get yxzx =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[2], _v3storage[0]);
  Vector4 get yxzy =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[2], _v3storage[1]);
  Vector4 get yxzz =>
      Vector4(_v3storage[1], _v3storage[0], _v3storage[2], _v3storage[2]);
  Vector4 get yyxx =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[0], _v3storage[0]);
  Vector4 get yyxy =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[0], _v3storage[1]);
  Vector4 get yyxz =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[0], _v3storage[2]);
  Vector4 get yyyx =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[1], _v3storage[0]);
  Vector4 get yyyy =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[1], _v3storage[1]);
  Vector4 get yyyz =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[1], _v3storage[2]);
  Vector4 get yyzx =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[2], _v3storage[0]);
  Vector4 get yyzy =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[2], _v3storage[1]);
  Vector4 get yyzz =>
      Vector4(_v3storage[1], _v3storage[1], _v3storage[2], _v3storage[2]);
  Vector4 get yzxx =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[0], _v3storage[0]);
  Vector4 get yzxy =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[0], _v3storage[1]);
  Vector4 get yzxz =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[0], _v3storage[2]);
  Vector4 get yzyx =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[1], _v3storage[0]);
  Vector4 get yzyy =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[1], _v3storage[1]);
  Vector4 get yzyz =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[1], _v3storage[2]);
  Vector4 get yzzx =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[2], _v3storage[0]);
  Vector4 get yzzy =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[2], _v3storage[1]);
  Vector4 get yzzz =>
      Vector4(_v3storage[1], _v3storage[2], _v3storage[2], _v3storage[2]);
  Vector4 get zxxx =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[0], _v3storage[0]);
  Vector4 get zxxy =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[0], _v3storage[1]);
  Vector4 get zxxz =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[0], _v3storage[2]);
  Vector4 get zxyx =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[1], _v3storage[0]);
  Vector4 get zxyy =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[1], _v3storage[1]);
  Vector4 get zxyz =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[1], _v3storage[2]);
  Vector4 get zxzx =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[2], _v3storage[0]);
  Vector4 get zxzy =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[2], _v3storage[1]);
  Vector4 get zxzz =>
      Vector4(_v3storage[2], _v3storage[0], _v3storage[2], _v3storage[2]);
  Vector4 get zyxx =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[0], _v3storage[0]);
  Vector4 get zyxy =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[0], _v3storage[1]);
  Vector4 get zyxz =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[0], _v3storage[2]);
  Vector4 get zyyx =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[1], _v3storage[0]);
  Vector4 get zyyy =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[1], _v3storage[1]);
  Vector4 get zyyz =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[1], _v3storage[2]);
  Vector4 get zyzx =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[2], _v3storage[0]);
  Vector4 get zyzy =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[2], _v3storage[1]);
  Vector4 get zyzz =>
      Vector4(_v3storage[2], _v3storage[1], _v3storage[2], _v3storage[2]);
  Vector4 get zzxx =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[0], _v3storage[0]);
  Vector4 get zzxy =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[0], _v3storage[1]);
  Vector4 get zzxz =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[0], _v3storage[2]);
  Vector4 get zzyx =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[1], _v3storage[0]);
  Vector4 get zzyy =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[1], _v3storage[1]);
  Vector4 get zzyz =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[1], _v3storage[2]);
  Vector4 get zzzx =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[2], _v3storage[0]);
  Vector4 get zzzy =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[2], _v3storage[1]);
  Vector4 get zzzz =>
      Vector4(_v3storage[2], _v3storage[2], _v3storage[2], _v3storage[2]);
  double get r => x;
  double get g => y;
  double get b => z;
  double get s => x;
  double get t => y;
  double get p => z;
  double get x => _v3storage[0];
  double get y => _v3storage[1];
  double get z => _v3storage[2];
  Vector2 get rr => xx;
  Vector2 get rg => xy;
  Vector2 get rb => xz;
  Vector2 get gr => yx;
  Vector2 get gg => yy;
  Vector2 get gb => yz;
  Vector2 get br => zx;
  Vector2 get bg => zy;
  Vector2 get bb => zz;
  Vector3 get rrr => xxx;
  Vector3 get rrg => xxy;
  Vector3 get rrb => xxz;
  Vector3 get rgr => xzx;
  Vector3 get rgg => xyy;
  Vector3 get rgb => xyz;
  Vector3 get rbr => xzx;
  Vector3 get rbg => xzy;
  Vector3 get rbb => xzz;
  Vector3 get grr => yxx;
  Vector3 get grg => yxy;
  Vector3 get grb => yxz;
  Vector3 get ggr => yyx;
  Vector3 get ggg => yyy;
  Vector3 get ggb => yyz;
  Vector3 get gbr => yxz;
  Vector3 get gbg => yzy;
  Vector3 get gbb => yzz;
  Vector3 get brr => zxx;
  Vector3 get brg => zxy;
  Vector3 get brb => zxz;
  Vector3 get bgr => zyx;
  Vector3 get bgg => zyy;
  Vector3 get bgb => zyz;
  Vector3 get bbr => zzx;
  Vector3 get bbg => zzy;
  Vector3 get bbb => zzz;
  Vector4 get rrrr => xxxx;
  Vector4 get rrrg => xxxy;
  Vector4 get rrrb => xxxz;
  Vector4 get rrgr => xxyx;
  Vector4 get rrgg => xxyy;
  Vector4 get rrgb => xxyz;
  Vector4 get rrbr => xxzx;
  Vector4 get rrbg => xxzy;
  Vector4 get rrbb => xxzz;
  Vector4 get rgrr => xyxx;
  Vector4 get rgrg => xyxy;
  Vector4 get rgrb => xyxz;
  Vector4 get rggr => xyyx;
  Vector4 get rggg => xyyy;
  Vector4 get rggb => xyyz;
  Vector4 get rgbr => xyzx;
  Vector4 get rgbg => xyzy;
  Vector4 get rgbb => xyzz;
  Vector4 get rbrr => xzxx;
  Vector4 get rbrg => xzxy;
  Vector4 get rbrb => xzxz;
  Vector4 get rbgr => xzyx;
  Vector4 get rbgg => xzyy;
  Vector4 get rbgb => xzyz;
  Vector4 get rbbr => xzzx;
  Vector4 get rbbg => xzzy;
  Vector4 get rbbb => xzzz;
  Vector4 get grrr => yxxx;
  Vector4 get grrg => yxxy;
  Vector4 get grrb => yxxz;
  Vector4 get grgr => yxyx;
  Vector4 get grgg => yxyy;
  Vector4 get grgb => yxyz;
  Vector4 get grbr => yxzx;
  Vector4 get grbg => yxzy;
  Vector4 get grbb => yxzz;
  Vector4 get ggrr => yyxx;
  Vector4 get ggrg => yyxy;
  Vector4 get ggrb => yyxz;
  Vector4 get gggr => yyyx;
  Vector4 get gggg => yyyy;
  Vector4 get gggb => yyyz;
  Vector4 get ggbr => yyzx;
  Vector4 get ggbg => yyzy;
  Vector4 get ggbb => yyzz;
  Vector4 get gbrr => yzxx;
  Vector4 get gbrg => yzxy;
  Vector4 get gbrb => yzxz;
  Vector4 get gbgr => yzyx;
  Vector4 get gbgg => yzyy;
  Vector4 get gbgb => yzyz;
  Vector4 get gbbr => yzzx;
  Vector4 get gbbg => yzzy;
  Vector4 get gbbb => yzzz;
  Vector4 get brrr => zxxx;
  Vector4 get brrg => zxxy;
  Vector4 get brrb => zxxz;
  Vector4 get brgr => zxyx;
  Vector4 get brgg => zxyy;
  Vector4 get brgb => zxyz;
  Vector4 get brbr => zxzx;
  Vector4 get brbg => zxzy;
  Vector4 get brbb => zxzz;
  Vector4 get bgrr => zyxx;
  Vector4 get bgrg => zyxy;
  Vector4 get bgrb => zyxz;
  Vector4 get bggr => zyyx;
  Vector4 get bggg => zyyy;
  Vector4 get bggb => zyyz;
  Vector4 get bgbr => zyzx;
  Vector4 get bgbg => zyzy;
  Vector4 get bgbb => zyzz;
  Vector4 get bbrr => zzxx;
  Vector4 get bbrg => zzxy;
  Vector4 get bbrb => zzxz;
  Vector4 get bbgr => zzyx;
  Vector4 get bbgg => zzyy;
  Vector4 get bbgb => zzyz;
  Vector4 get bbbr => zzzx;
  Vector4 get bbbg => zzzy;
  Vector4 get bbbb => zzzz;
  Vector2 get ss => xx;
  Vector2 get st => xy;
  Vector2 get sp => xz;
  Vector2 get ts => yx;
  Vector2 get tt => yy;
  Vector2 get tp => yz;
  Vector2 get ps => zx;
  Vector2 get pt => zy;
  Vector2 get pp => zz;
  Vector3 get sss => xxx;
  Vector3 get sst => xxy;
  Vector3 get ssp => xxz;
  Vector3 get sts => xyx;
  Vector3 get stt => xyy;
  Vector3 get stp => xyz;
  Vector3 get sps => xzx;
  Vector3 get spt => xzy;
  Vector3 get spp => xzz;
  Vector3 get tss => yxx;
  Vector3 get tst => yxy;
  Vector3 get tsp => yxz;
  Vector3 get tts => yyx;
  Vector3 get ttt => yyy;
  Vector3 get ttp => yyz;
  Vector3 get tps => yzx;
  Vector3 get tpt => yzy;
  Vector3 get tpp => yzz;
  Vector3 get pss => zxx;
  Vector3 get pst => zxy;
  Vector3 get psp => zxz;
  Vector3 get pts => zyx;
  Vector3 get ptt => zyy;
  Vector3 get ptp => zyz;
  Vector3 get pps => zzx;
  Vector3 get ppt => zzy;
  Vector3 get ppp => zzz;
  Vector4 get ssss => xxxx;
  Vector4 get ssst => xxxy;
  Vector4 get sssp => xxxz;
  Vector4 get ssts => xxyx;
  Vector4 get sstt => xxyy;
  Vector4 get sstp => xxyz;
  Vector4 get ssps => xxzx;
  Vector4 get sspt => xxzy;
  Vector4 get sspp => xxzz;
  Vector4 get stss => xyxx;
  Vector4 get stst => xyxy;
  Vector4 get stsp => xyxz;
  Vector4 get stts => xyyx;
  Vector4 get sttt => xyyy;
  Vector4 get sttp => xyyz;
  Vector4 get stps => xyzx;
  Vector4 get stpt => xyzy;
  Vector4 get stpp => xyzz;
  Vector4 get spss => xzxx;
  Vector4 get spst => xzxy;
  Vector4 get spsp => xzxz;
  Vector4 get spts => xzyx;
  Vector4 get sptt => xzyy;
  Vector4 get sptp => xzyz;
  Vector4 get spps => xzzx;
  Vector4 get sppt => xzzy;
  Vector4 get sppp => xzzz;
  Vector4 get tsss => yxxx;
  Vector4 get tsst => yxxy;
  Vector4 get tssp => yxxz;
  Vector4 get tsts => yxyx;
  Vector4 get tstt => yxyy;
  Vector4 get tstp => yxyz;
  Vector4 get tsps => yxzx;
  Vector4 get tspt => yxzy;
  Vector4 get tspp => yxzz;
  Vector4 get ttss => yyxx;
  Vector4 get ttst => yyxy;
  Vector4 get ttsp => yyxz;
  Vector4 get ttts => yyyx;
  Vector4 get tttt => yyyy;
  Vector4 get tttp => yyyz;
  Vector4 get ttps => yyzx;
  Vector4 get ttpt => yyzy;
  Vector4 get ttpp => yyzz;
  Vector4 get tpss => yzxx;
  Vector4 get tpst => yzxy;
  Vector4 get tpsp => yzxz;
  Vector4 get tpts => yzyx;
  Vector4 get tptt => yzyy;
  Vector4 get tptp => yzyz;
  Vector4 get tpps => yzzx;
  Vector4 get tppt => yzzy;
  Vector4 get tppp => yzzz;
  Vector4 get psss => zxxx;
  Vector4 get psst => zxxy;
  Vector4 get pssp => zxxz;
  Vector4 get psts => zxyx;
  Vector4 get pstt => zxyy;
  Vector4 get pstp => zxyz;
  Vector4 get psps => zxzx;
  Vector4 get pspt => zxzy;
  Vector4 get pspp => zxzz;
  Vector4 get ptss => zyxx;
  Vector4 get ptst => zyxy;
  Vector4 get ptsp => zyxz;
  Vector4 get ptts => zyyx;
  Vector4 get pttt => zyyy;
  Vector4 get pttp => zyyz;
  Vector4 get ptps => zyzx;
  Vector4 get ptpt => zyzy;
  Vector4 get ptpp => zyzz;
  Vector4 get ppss => zzxx;
  Vector4 get ppst => zzxy;
  Vector4 get ppsp => zzxz;
  Vector4 get ppts => zzyx;
  Vector4 get pptt => zzyy;
  Vector4 get pptp => zzyz;
  Vector4 get ppps => zzzx;
  Vector4 get pppt => zzzy;
  Vector4 get pppp => zzzz;
}

// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math;

/// Defines a 2-dimensional axis-aligned bounding box between a [min] and a
/// [max] position.
class Aabb2 {
  final Vector2 _min;
  final Vector2 _max;

  /// The minimum point defining the AABB.
  Vector2 get min => _min;

  /// The maximum point defining the AABB.
  Vector2 get max => _max;

  /// The center of the AABB.
  Vector2 get center => _min.clone()
    ..add(_max)
    ..scale(0.5);

  /// Create a new AABB with [min] and [max] set to the origin.
  Aabb2()
      : _min = Vector2.zero(),
        _max = Vector2.zero();

  /// Create a new AABB as a copy of [other].
  Aabb2.copy(Aabb2 other)
      : _min = Vector2.copy(other._min),
        _max = Vector2.copy(other._max);

  /// Create a new AABB with a [min] and [max].
  Aabb2.minMax(Vector2 min, Vector2 max)
      : _min = Vector2.copy(min),
        _max = Vector2.copy(max);

  /// Create a new AABB with a [center] and [halfExtents].
  factory Aabb2.centerAndHalfExtents(Vector2 center, Vector2 halfExtents) =>
      Aabb2()..setCenterAndHalfExtents(center, halfExtents);

  /// Constructs [Aabb2] with a min/max storage that views given [buffer]
  /// starting at [offset]. [offset] has to be multiple of
  /// [Float32List.bytesPerElement].
  Aabb2.fromBuffer(ByteBuffer buffer, int offset)
      : _min = Vector2.fromBuffer(buffer, offset),
        _max = Vector2.fromBuffer(
            buffer, offset + Float32List.bytesPerElement * 2);

  /// Set the AABB by a [center] and [halfExtents].
  void setCenterAndHalfExtents(Vector2 center, Vector2 halfExtents) {
    _min
      ..setFrom(center)
      ..sub(halfExtents);
    _max
      ..setFrom(center)
      ..add(halfExtents);
  }

  /// Copy the [center] and the [halfExtents] of this.
  void copyCenterAndHalfExtents(Vector2 center, Vector2 halfExtents) {
    center
      ..setFrom(_min)
      ..add(_max)
      ..scale(0.5);
    halfExtents
      ..setFrom(_max)
      ..sub(_min)
      ..scale(0.5);
  }

  /// Copy the [min] and [max] from [other] into this.
  void copyFrom(Aabb2 other) {
    _min.setFrom(other._min);
    _max.setFrom(other._max);
  }

  static final _center = Vector2.zero();
  static final _halfExtents = Vector2.zero();
  void _updateCenterAndHalfExtents() =>
      copyCenterAndHalfExtents(_center, _halfExtents);

  /// Transform this by the transform [t].
  void transform(Matrix3 t) {
    _updateCenterAndHalfExtents();
    t
      ..transform2(_center)
      ..absoluteRotate2(_halfExtents);
    _min
      ..setFrom(_center)
      ..sub(_halfExtents);
    _max
      ..setFrom(_center)
      ..add(_halfExtents);
  }

  /// Rotate this by the rotation matrix [t].
  void rotate(Matrix3 t) {
    _updateCenterAndHalfExtents();
    t.absoluteRotate2(_halfExtents);
    _min
      ..setFrom(_center)
      ..sub(_halfExtents);
    _max
      ..setFrom(_center)
      ..add(_halfExtents);
  }

  /// Create a copy of this that is transformed by the transform [t] and store
  /// it in [out].
  Aabb2 transformed(Matrix3 t, Aabb2 out) => out
    ..copyFrom(this)
    ..transform(t);

  /// Create a copy of this that is rotated by the rotation matrix [t] and
  /// store it in [out].
  Aabb2 rotated(Matrix3 t, Aabb2 out) => out
    ..copyFrom(this)
    ..rotate(t);

  /// Set the min and max of this so that this is a hull of this and
  /// [other].
  void hull(Aabb2 other) {
    Vector2.min(_min, other._min, _min);
    Vector2.max(_max, other._max, _max);
  }

  /// Set the min and max of this so that this contains [point].
  void hullPoint(Vector2 point) {
    Vector2.min(_min, point, _min);
    Vector2.max(_max, point, _max);
  }

  /// Return if this contains [other].
  bool containsAabb2(Aabb2 other) {
    final otherMax = other._max;
    final otherMin = other._min;

    return (_min.x < otherMin.x) &&
        (_min.y < otherMin.y) &&
        (_max.y > otherMax.y) &&
        (_max.x > otherMax.x);
  }

  /// Return if this contains [other].
  bool containsVector2(Vector2 other) =>
      (_min.x < other.x) &&
      (_min.y < other.y) &&
      (_max.x > other.x) &&
      (_max.y > other.y);

  /// Return if this intersects with [other].
  bool intersectsWithAabb2(Aabb2 other) {
    final otherMax = other._max;
    final otherMin = other._min;

    return (_min.x <= otherMax.x) &&
        (_min.y <= otherMax.y) &&
        (_max.x >= otherMin.x) &&
        (_max.y >= otherMin.y);
  }

  /// Return if this intersects with [other].
  bool intersectsWithVector2(Vector2 other) =>
      (_min.x <= other.x) &&
      (_min.y <= other.y) &&
      (_max.x >= other.x) &&
      (_max.y >= other.y);
}

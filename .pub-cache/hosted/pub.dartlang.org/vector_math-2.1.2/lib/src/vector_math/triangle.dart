// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math;

/// Defines a triangle by three points.
class Triangle {
  final Vector3 _point0;
  final Vector3 _point1;
  final Vector3 _point2;

  /// The first point of the triangle.
  Vector3 get point0 => _point0;

  /// The second point of the triangle.
  Vector3 get point1 => _point1;

  /// The third point of the triangle.
  Vector3 get point2 => _point2;

  /// Create a new, uninitialized triangle.
  Triangle()
      : _point0 = Vector3.zero(),
        _point1 = Vector3.zero(),
        _point2 = Vector3.zero();

  /// Create a triangle as a copy of [other].
  Triangle.copy(Triangle other)
      : _point0 = Vector3.copy(other._point0),
        _point1 = Vector3.copy(other._point1),
        _point2 = Vector3.copy(other._point2);

  /// Create a triangle by three points.
  Triangle.points(Vector3 point0, Vector3 point1, Vector3 point2)
      : _point0 = Vector3.copy(point0),
        _point1 = Vector3.copy(point1),
        _point2 = Vector3.copy(point2);

  /// Copy the triangle from [other] into this.
  void copyFrom(Triangle other) {
    _point0.setFrom(other._point0);
    _point1.setFrom(other._point1);
    _point2.setFrom(other._point2);
  }

  /// Copy the normal of this into [normal].
  void copyNormalInto(Vector3 normal) {
    final v0 = point0.clone()..sub(point1);
    normal
      ..setFrom(point2)
      ..sub(point1)
      ..crossInto(v0, normal)
      ..normalize();
  }

  /// Transform this by the transform [t].
  void transform(Matrix4 t) {
    t
      ..transform3(_point0)
      ..transform3(_point1)
      ..transform3(_point2);
  }

  /// Translate this by [offset].
  void translate(Vector3 offset) {
    _point0.add(offset);
    _point1.add(offset);
    _point2.add(offset);
  }
}

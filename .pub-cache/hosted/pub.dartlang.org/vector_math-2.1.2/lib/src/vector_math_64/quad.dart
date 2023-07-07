// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_64;

/// Defines a quad by four points.
class Quad {
  final Vector3 _point0;
  final Vector3 _point1;
  final Vector3 _point2;
  final Vector3 _point3;

  /// The first point of the quad.
  Vector3 get point0 => _point0;

  /// The second point of the quad.
  Vector3 get point1 => _point1;

  /// The third point of the quad.
  Vector3 get point2 => _point2;

  /// The third point of the quad.
  Vector3 get point3 => _point3;

  /// Create a new, uninitialized quad.
  Quad()
      : _point0 = Vector3.zero(),
        _point1 = Vector3.zero(),
        _point2 = Vector3.zero(),
        _point3 = Vector3.zero();

  /// Create a quad as a copy of [other].
  Quad.copy(Quad other)
      : _point0 = Vector3.copy(other._point0),
        _point1 = Vector3.copy(other._point1),
        _point2 = Vector3.copy(other._point2),
        _point3 = Vector3.copy(other._point3);

  /// Create a quad by four points.
  Quad.points(Vector3 point0, Vector3 point1, Vector3 point2, Vector3 point3)
      : _point0 = Vector3.copy(point0),
        _point1 = Vector3.copy(point1),
        _point2 = Vector3.copy(point2),
        _point3 = Vector3.copy(point3);

  /// Copy the quad from [other] into this.
  void copyFrom(Quad other) {
    _point0.setFrom(other._point0);
    _point1.setFrom(other._point1);
    _point2.setFrom(other._point2);
    _point3.setFrom(other._point3);
  }

  /// Copy the normal of this into [normal].
  void copyNormalInto(Vector3 normal) {
    final v0 = _point0.clone()..sub(_point1);
    normal
      ..setFrom(_point2)
      ..sub(_point1)
      ..crossInto(v0, normal)
      ..normalize();
  }

  /// Copies the two triangles that define this.
  void copyTriangles(Triangle triangle0, Triangle triangle1) {
    triangle0._point0.setFrom(_point0);
    triangle0._point1.setFrom(_point1);
    triangle0._point2.setFrom(_point2);
    triangle1._point0.setFrom(_point0);
    triangle1._point1.setFrom(_point3);
    triangle1._point2.setFrom(_point2);
  }

  /// Transform this by the transform [t].
  void transform(Matrix4 t) {
    t
      ..transform3(_point0)
      ..transform3(_point1)
      ..transform3(_point2)
      ..transform3(_point3);
  }

  /// Translate this by [offset].
  void translate(Vector3 offset) {
    _point0.add(offset);
    _point1.add(offset);
    _point2.add(offset);
    _point3.add(offset);
  }
}

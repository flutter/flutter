// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
part of vector_math_64;

/// Defines a 3-dimensional oriented bounding box defined with a [center],
/// [halfExtents] and axes.
class Obb3 {
  final Vector3 _center;
  final Vector3 _halfExtents;
  final Vector3 _axis0;
  final Vector3 _axis1;
  final Vector3 _axis2;

  /// The center of the OBB.
  Vector3 get center => _center;

  /// The half extends of the OBB.
  Vector3 get halfExtents => _halfExtents;

  /// The first axis of the OBB.
  Vector3 get axis0 => _axis0;

  /// The second axis of the OBB.
  Vector3 get axis1 => _axis1;

  /// The third axis of the OBB.
  Vector3 get axis2 => _axis2;

  /// Create a new OBB with erverything set to zero.
  Obb3()
      : _center = Vector3.zero(),
        _halfExtents = Vector3.zero(),
        _axis0 = Vector3(1.0, 0.0, 0.0),
        _axis1 = Vector3(0.0, 1.0, 0.0),
        _axis2 = Vector3(0.0, 0.0, 1.0);

  /// Create a new OBB as a copy of [other].
  Obb3.copy(Obb3 other)
      : _center = Vector3.copy(other._center),
        _halfExtents = Vector3.copy(other._halfExtents),
        _axis0 = Vector3.copy(other._axis0),
        _axis1 = Vector3.copy(other._axis1),
        _axis2 = Vector3.copy(other._axis2);

  /// Create a new OBB using [center], [halfExtents] and axis.
  Obb3.centerExtentsAxes(Vector3 center, Vector3 halfExtents, Vector3 axis0,
      Vector3 axis1, Vector3 axis2)
      : _center = Vector3.copy(center),
        _halfExtents = Vector3.copy(halfExtents),
        _axis0 = Vector3.copy(axis0),
        _axis1 = Vector3.copy(axis1),
        _axis2 = Vector3.copy(axis2);

  /// Copy from [other] into this.
  void copyFrom(Obb3 other) {
    _center.setFrom(other._center);
    _halfExtents.setFrom(other._halfExtents);
    _axis0.setFrom(other._axis0);
    _axis1.setFrom(other._axis1);
    _axis2.setFrom(other._axis2);
  }

  /// Copy from this into [other].
  void copyInto(Obb3 other) {
    other._center.setFrom(_center);
    other._halfExtents.setFrom(_halfExtents);
    other._axis0.setFrom(_axis0);
    other._axis1.setFrom(_axis1);
    other._axis2.setFrom(_axis2);
  }

  /// Reset the rotation of this.
  void resetRotation() {
    _axis0.setValues(1.0, 0.0, 0.0);
    _axis1.setValues(0.0, 1.0, 0.0);
    _axis2.setValues(0.0, 0.0, 1.0);
  }

  /// Translate this by [offset].
  void translate(Vector3 offset) {
    _center.add(offset);
  }

  /// Rotate this by the rotation matrix [t].
  void rotate(Matrix3 t) {
    t
      ..transform(_axis0..scale(_halfExtents.x))
      ..transform(_axis1..scale(_halfExtents.y))
      ..transform(_axis2..scale(_halfExtents.z));

    _halfExtents
      ..x = _axis0.normalize()
      ..y = _axis1.normalize()
      ..z = _axis2.normalize();
  }

  /// Transform this by the transform [t].
  void transform(Matrix4 t) {
    t
      ..transform3(_center)
      ..rotate3(_axis0..scale(_halfExtents.x))
      ..rotate3(_axis1..scale(_halfExtents.y))
      ..rotate3(_axis2..scale(_halfExtents.z));

    _halfExtents
      ..x = _axis0.normalize()
      ..y = _axis1.normalize()
      ..z = _axis2.normalize();
  }

  /// Store the corner with [cornerIndex] in [corner].
  void copyCorner(int cornerIndex, Vector3 corner) {
    assert(cornerIndex >= 0 || cornerIndex < 8);

    corner.setFrom(_center);

    switch (cornerIndex) {
      case 0:
        corner
          ..addScaled(_axis0, -_halfExtents.x)
          ..addScaled(_axis1, -_halfExtents.y)
          ..addScaled(_axis2, -_halfExtents.z);
        break;
      case 1:
        corner
          ..addScaled(_axis0, -_halfExtents.x)
          ..addScaled(_axis1, -_halfExtents.y)
          ..addScaled(_axis2, _halfExtents.z);
        break;
      case 2:
        corner
          ..addScaled(_axis0, -_halfExtents.x)
          ..addScaled(_axis1, _halfExtents.y)
          ..addScaled(_axis2, -_halfExtents.z);
        break;
      case 3:
        corner
          ..addScaled(_axis0, -_halfExtents.x)
          ..addScaled(_axis1, _halfExtents.y)
          ..addScaled(_axis2, _halfExtents.z);
        break;
      case 4:
        corner
          ..addScaled(_axis0, _halfExtents.x)
          ..addScaled(_axis1, -_halfExtents.y)
          ..addScaled(_axis2, -_halfExtents.z);
        break;
      case 5:
        corner
          ..addScaled(_axis0, _halfExtents.x)
          ..addScaled(_axis1, -_halfExtents.y)
          ..addScaled(_axis2, _halfExtents.z);
        break;
      case 6:
        corner
          ..addScaled(_axis0, _halfExtents.x)
          ..addScaled(_axis1, _halfExtents.y)
          ..addScaled(_axis2, -_halfExtents.z);
        break;
      case 7:
        corner
          ..addScaled(_axis0, _halfExtents.x)
          ..addScaled(_axis1, _halfExtents.y)
          ..addScaled(_axis2, _halfExtents.z);
        break;
    }
  }

  /// Find the closest point [q] on the OBB to the point [p] and store it in [q].
  void closestPointTo(Vector3 p, Vector3 q) {
    final d = p - _center;

    q.setFrom(_center);

    var dist = d.dot(_axis0);
    dist = dist.clamp(-_halfExtents.x, _halfExtents.x).toDouble();
    q.addScaled(_axis0, dist);

    dist = d.dot(_axis1);
    dist = dist.clamp(-_halfExtents.y, _halfExtents.y).toDouble();
    q.addScaled(_axis1, dist);

    dist = d.dot(_axis2);
    dist = dist.clamp(-_halfExtents.z, _halfExtents.z).toDouble();
    q.addScaled(_axis2, dist);
  }

  // Avoid allocating these instance on every call to intersectsWithObb3
  static final _r = Matrix3.zero();
  static final _absR = Matrix3.zero();
  static final _t = Vector3.zero();

  /// Check for intersection between this and [other].
  bool intersectsWithObb3(Obb3 other, [double epsilon = 1e-3]) {
    // Compute rotation matrix expressing other in this's coordinate frame
    _r
      ..setEntry(0, 0, _axis0.dot(other._axis0))
      ..setEntry(1, 0, _axis1.dot(other._axis0))
      ..setEntry(2, 0, _axis2.dot(other._axis0))
      ..setEntry(0, 1, _axis0.dot(other._axis1))
      ..setEntry(1, 1, _axis1.dot(other._axis1))
      ..setEntry(2, 1, _axis2.dot(other._axis1))
      ..setEntry(0, 2, _axis0.dot(other._axis2))
      ..setEntry(1, 2, _axis1.dot(other._axis2))
      ..setEntry(2, 2, _axis2.dot(other._axis2));

    // Compute translation vector t
    _t
      ..setFrom(other._center)
      ..sub(_center);

    // Bring translation into this's coordinate frame
    _t.setValues(_t.dot(_axis0), _t.dot(_axis1), _t.dot(_axis2));

    // Compute common subexpressions. Add in an epsilon term to
    // counteract arithmetic errors when two edges are parallel and
    // their cross product is (near) null.
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        _absR.setEntry(i, j, _r.entry(i, j).abs() + epsilon);
      }
    }

    double ra;
    double rb;

    // Test axes L = A0, L = A1, L = A2
    for (var i = 0; i < 3; i++) {
      ra = _halfExtents[i];
      rb = other._halfExtents[0] * _absR.entry(i, 0) +
          other._halfExtents[1] * _absR.entry(i, 1) +
          other._halfExtents[2] * _absR.entry(i, 2);

      if (_t[i].abs() > ra + rb) {
        return false;
      }
    }

    // Test axes L = B0, L = B1, L = B2
    for (var i = 0; i < 3; i++) {
      ra = _halfExtents[0] * _absR.entry(0, i) +
          _halfExtents[1] * _absR.entry(1, i) +
          _halfExtents[2] * _absR.entry(2, i);
      rb = other._halfExtents[i];

      if ((_t[0] * _r.entry(0, i) +
                  _t[1] * _r.entry(1, i) +
                  _t[2] * _r.entry(2, i))
              .abs() >
          ra + rb) {
        return false;
      }
    }

    // Test axis L = A0 x B0
    ra = _halfExtents[1] * _absR.entry(2, 0) +
        _halfExtents[2] * _absR.entry(1, 0);
    rb = other._halfExtents[1] * _absR.entry(0, 2) +
        other._halfExtents[2] * _absR.entry(0, 1);
    if ((_t[2] * _r.entry(1, 0) - _t[1] * _r.entry(2, 0)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A0 x B1
    ra = _halfExtents[1] * _absR.entry(2, 1) +
        _halfExtents[2] * _absR.entry(1, 1);
    rb = other._halfExtents[0] * _absR.entry(0, 2) +
        other._halfExtents[2] * _absR.entry(0, 0);
    if ((_t[2] * _r.entry(1, 1) - _t[1] * _r.entry(2, 1)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A0 x B2
    ra = _halfExtents[1] * _absR.entry(2, 2) +
        _halfExtents[2] * _absR.entry(1, 2);
    rb = other._halfExtents[0] * _absR.entry(0, 1) +
        other._halfExtents[1] * _absR.entry(0, 0);
    if ((_t[2] * _r.entry(1, 2) - _t[1] * _r.entry(2, 2)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A1 x B0
    ra = _halfExtents[0] * _absR.entry(2, 0) +
        _halfExtents[2] * _absR.entry(0, 0);
    rb = other._halfExtents[1] * _absR.entry(1, 2) +
        other._halfExtents[2] * _absR.entry(1, 1);
    if ((_t[0] * _r.entry(2, 0) - _t[2] * _r.entry(0, 0)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A1 x B1
    ra = _halfExtents[0] * _absR.entry(2, 1) +
        _halfExtents[2] * _absR.entry(0, 1);
    rb = other._halfExtents[0] * _absR.entry(1, 2) +
        other._halfExtents[2] * _absR.entry(1, 0);
    if ((_t[0] * _r.entry(2, 1) - _t[2] * _r.entry(0, 1)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A1 x B2
    ra = _halfExtents[0] * _absR.entry(2, 2) +
        _halfExtents[2] * _absR.entry(0, 2);
    rb = other._halfExtents[0] * _absR.entry(1, 1) +
        other._halfExtents[1] * _absR.entry(1, 0);
    if ((_t[0] * _r.entry(2, 2) - _t[2] * _r.entry(0, 2)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A2 x B0
    ra = _halfExtents[0] * _absR.entry(1, 0) +
        _halfExtents[1] * _absR.entry(0, 0);
    rb = other._halfExtents[1] * _absR.entry(2, 2) +
        other._halfExtents[2] * _absR.entry(2, 1);
    if ((_t[1] * _r.entry(0, 0) - _t[0] * _r.entry(1, 0)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A2 x B1
    ra = _halfExtents[0] * _absR.entry(1, 1) +
        _halfExtents[1] * _absR.entry(0, 1);
    rb = other._halfExtents[0] * _absR.entry(2, 2) +
        other._halfExtents[2] * _absR.entry(2, 0);
    if ((_t[1] * _r.entry(0, 1) - _t[0] * _r.entry(1, 1)).abs() > ra + rb) {
      return false;
    }

    // Test axis L = A2 x B2
    ra = _halfExtents[0] * _absR.entry(1, 2) +
        _halfExtents[1] * _absR.entry(0, 2);
    rb = other._halfExtents[0] * _absR.entry(2, 1) +
        other._halfExtents[1] * _absR.entry(2, 0);
    if ((_t[1] * _r.entry(0, 2) - _t[0] * _r.entry(1, 2)).abs() > ra + rb) {
      return false;
    }

    // Since no separating axis is found, the OBBs must be intersecting
    return true;
  }

  // Avoid allocating these instance on every call to intersectsWithTriangle
  static final _triangle = Triangle();
  static final _aabb3 = Aabb3();
  static final _zeroVector = Vector3.zero();

  /// Return if this intersects with [other]
  bool intersectsWithTriangle(Triangle other, {IntersectionResult? result}) {
    _triangle.copyFrom(other);

    _triangle.point0
      ..sub(_center)
      ..setValues(_triangle.point0.dot(axis0), _triangle.point0.dot(axis1),
          _triangle.point0.dot(axis2));
    _triangle.point1
      ..sub(_center)
      ..setValues(_triangle.point1.dot(axis0), _triangle.point1.dot(axis1),
          _triangle.point1.dot(axis2));
    _triangle.point2
      ..sub(_center)
      ..setValues(_triangle.point2.dot(axis0), _triangle.point2.dot(axis1),
          _triangle.point2.dot(axis2));

    _aabb3.setCenterAndHalfExtents(_zeroVector, _halfExtents);

    return _aabb3.intersectsWithTriangle(_triangle, result: result);
  }

  // Avoid allocating these instance on every call to intersectsWithVector3
  static final _vector = Vector3.zero();

  /// Return if this intersects with [other]
  bool intersectsWithVector3(Vector3 other) {
    _vector
      ..setFrom(other)
      ..sub(_center)
      ..setValues(_vector.dot(axis0), _vector.dot(axis1), _vector.dot(axis2));

    _aabb3.setCenterAndHalfExtents(_zeroVector, _halfExtents);

    return _aabb3.intersectsWithVector3(_vector);
  }

  // Avoid allocating these instance on every call to intersectsWithTriangle
  static final _quadTriangle0 = Triangle();
  static final _quadTriangle1 = Triangle();

  /// Return if this intersects with [other]
  bool intersectsWithQuad(Quad other, {IntersectionResult? result}) {
    other.copyTriangles(_quadTriangle0, _quadTriangle1);

    return intersectsWithTriangle(_quadTriangle0, result: result) ||
        intersectsWithTriangle(_quadTriangle1, result: result);
  }
}

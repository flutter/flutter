// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math;

/// Defines a 3-dimensional axis-aligned bounding box between a [min] and a
/// [max] position.
class Aabb3 {
  final Vector3 _min;
  final Vector3 _max;

  Vector3 get min => _min;
  Vector3 get max => _max;

  /// The center of the AABB.
  Vector3 get center => _min.clone()
    ..add(_max)
    ..scale(0.5);

  /// Create a new AABB with [min] and [max] set to the origin.
  Aabb3()
      : _min = Vector3.zero(),
        _max = Vector3.zero();

  /// Create a new AABB as a copy of [other].
  Aabb3.copy(Aabb3 other)
      : _min = Vector3.copy(other._min),
        _max = Vector3.copy(other._max);

  /// Create a new AABB with a [min] and [max].
  Aabb3.minMax(Vector3 min, Vector3 max)
      : _min = Vector3.copy(min),
        _max = Vector3.copy(max);

  /// Create a new AABB that encloses a [sphere].
  factory Aabb3.fromSphere(Sphere sphere) => Aabb3()..setSphere(sphere);

  /// Create a new AABB that encloses a [triangle].
  factory Aabb3.fromTriangle(Triangle triangle) =>
      Aabb3()..setTriangle(triangle);

  /// Create a new AABB that encloses a [quad].
  factory Aabb3.fromQuad(Quad quad) => Aabb3()..setQuad(quad);

  /// Create a new AABB that encloses a [obb].
  factory Aabb3.fromObb3(Obb3 obb) => Aabb3()..setObb3(obb);

  /// Create a new AABB that encloses a limited [ray] (or line segment) that has
  /// a minLimit and maxLimit.
  factory Aabb3.fromRay(Ray ray, double limitMin, double limitMax) =>
      Aabb3()..setRay(ray, limitMin, limitMax);

  /// Create a new AABB with a [center] and [halfExtents].
  factory Aabb3.centerAndHalfExtents(Vector3 center, Vector3 halfExtents) =>
      Aabb3()..setCenterAndHalfExtents(center, halfExtents);

  /// Constructs [Aabb3] with a min/max storage that views given [buffer]
  /// starting at [offset]. [offset] has to be multiple of
  /// [Float32List.bytesPerElement].
  Aabb3.fromBuffer(ByteBuffer buffer, int offset)
      : _min = Vector3.fromBuffer(buffer, offset),
        _max = Vector3.fromBuffer(
            buffer, offset + Float32List.bytesPerElement * 3);

  /// Set the AABB by a [center] and [halfExtents].
  void setCenterAndHalfExtents(Vector3 center, Vector3 halfExtents) {
    _min
      ..setFrom(center)
      ..sub(halfExtents);
    _max
      ..setFrom(center)
      ..add(halfExtents);
  }

  /// Set the AABB to enclose a [sphere].
  void setSphere(Sphere sphere) {
    _min
      ..splat(-sphere.radius)
      ..add(sphere._center);
    _max
      ..splat(sphere.radius)
      ..add(sphere._center);
  }

  /// Set the AABB to enclose a [triangle].
  void setTriangle(Triangle triangle) {
    _min.setValues(
        math.min(triangle._point0.x,
            math.min(triangle._point1.x, triangle._point2.x)),
        math.min(triangle._point0.y,
            math.min(triangle._point1.y, triangle._point2.y)),
        math.min(triangle._point0.z,
            math.min(triangle._point1.z, triangle._point2.z)));
    _max.setValues(
        math.max(triangle._point0.x,
            math.max(triangle._point1.x, triangle._point2.x)),
        math.max(triangle._point0.y,
            math.max(triangle._point1.y, triangle._point2.y)),
        math.max(triangle._point0.z,
            math.max(triangle._point1.z, triangle._point2.z)));
  }

  /// Set the AABB to enclose a [quad].
  void setQuad(Quad quad) {
    _min.setValues(
        math.min(quad._point0.x,
            math.min(quad._point1.x, math.min(quad._point2.x, quad._point3.x))),
        math.min(quad._point0.y,
            math.min(quad._point1.y, math.min(quad._point2.y, quad._point3.y))),
        math.min(
            quad._point0.z,
            math.min(
                quad._point1.z, math.min(quad._point2.z, quad._point3.z))));
    _max.setValues(
        math.max(quad._point0.x,
            math.max(quad._point1.x, math.max(quad._point2.x, quad._point3.x))),
        math.max(quad._point0.y,
            math.max(quad._point1.y, math.max(quad._point2.y, quad._point3.y))),
        math.max(
            quad._point0.z,
            math.max(
                quad._point1.z, math.max(quad._point2.z, quad._point3.z))));
  }

  /// Set the AABB to enclose a [obb].
  void setObb3(Obb3 obb) {
    final corner = Vector3.zero();

    obb.copyCorner(0, corner);
    _min.setFrom(corner);
    _max.setFrom(corner);

    obb.copyCorner(1, corner);
    hullPoint(corner);

    obb.copyCorner(2, corner);
    hullPoint(corner);

    obb.copyCorner(3, corner);
    hullPoint(corner);

    obb.copyCorner(4, corner);
    hullPoint(corner);

    obb.copyCorner(5, corner);
    hullPoint(corner);

    obb.copyCorner(6, corner);
    hullPoint(corner);

    obb.copyCorner(7, corner);
    hullPoint(corner);
  }

  /// Set the AABB to enclose a limited [ray] (or line segment) that is limited
  /// by [limitMin] and [limitMax].
  void setRay(Ray ray, double limitMin, double limitMax) {
    ray
      ..copyAt(_min, limitMin)
      ..copyAt(_max, limitMax);

    if (_max.x < _min.x) {
      final temp = _max.x;
      _max.x = _min.x;
      _min.x = temp;
    }

    if (_max.y < _min.y) {
      final temp = _max.y;
      _max.y = _min.y;
      _min.y = temp;
    }

    if (_max.z < _min.z) {
      final temp = _max.z;
      _max.z = _min.z;
      _min.z = temp;
    }
  }

  /// Copy the [center] and the [halfExtents] of this.
  void copyCenterAndHalfExtents(Vector3 center, Vector3 halfExtents) {
    center
      ..setFrom(_min)
      ..add(_max)
      ..scale(0.5);
    halfExtents
      ..setFrom(_max)
      ..sub(_min)
      ..scale(0.5);
  }

  /// Copy the [center] of this.
  void copyCenter(Vector3 center) {
    center
      ..setFrom(_min)
      ..add(_max)
      ..scale(0.5);
  }

  /// Copy the [min] and [max] from [other] into this.
  void copyFrom(Aabb3 other) {
    _min.setFrom(other._min);
    _max.setFrom(other._max);
  }

  static final _center = Vector3.zero();
  static final _halfExtents = Vector3.zero();
  void _updateCenterAndHalfExtents() =>
      copyCenterAndHalfExtents(_center, _halfExtents);

  /// Transform this by the transform [t].
  void transform(Matrix4 t) {
    _updateCenterAndHalfExtents();
    t
      ..transform3(_center)
      ..absoluteRotate(_halfExtents);
    _min
      ..setFrom(_center)
      ..sub(_halfExtents);
    _max
      ..setFrom(_center)
      ..add(_halfExtents);
  }

  /// Rotate this by the rotation matrix [t].
  void rotate(Matrix4 t) {
    _updateCenterAndHalfExtents();
    t.absoluteRotate(_halfExtents);
    _min
      ..setFrom(_center)
      ..sub(_halfExtents);
    _max
      ..setFrom(_center)
      ..add(_halfExtents);
  }

  /// Create a copy of this that is transformed by the transform [t] and store
  /// it in [out].
  Aabb3 transformed(Matrix4 t, Aabb3 out) => out
    ..copyFrom(this)
    ..transform(t);

  /// Create a copy of this that is rotated by the rotation matrix [t] and
  /// store it in [out].
  Aabb3 rotated(Matrix4 t, Aabb3 out) => out
    ..copyFrom(this)
    ..rotate(t);

  void getPN(Vector3 planeNormal, Vector3 outP, Vector3 outN) {
    if (planeNormal.x < 0.0) {
      outP.x = _min.x;
      outN.x = _max.x;
    } else {
      outP.x = _max.x;
      outN.x = _min.x;
    }

    if (planeNormal.y < 0.0) {
      outP.y = _min.y;
      outN.y = _max.y;
    } else {
      outP.y = _max.y;
      outN.y = _min.y;
    }

    if (planeNormal.z < 0.0) {
      outP.z = _min.z;
      outN.z = _max.z;
    } else {
      outP.z = _max.z;
      outN.z = _min.z;
    }
  }

  /// Set the min and max of this so that this is a hull of this and
  /// [other].
  void hull(Aabb3 other) {
    Vector3.min(_min, other._min, _min);
    Vector3.max(_max, other._max, _max);
  }

  /// Set the min and max of this so that this contains [point].
  void hullPoint(Vector3 point) {
    Vector3.min(_min, point, _min);
    Vector3.max(_max, point, _max);
  }

  /// Return if this contains [other].
  bool containsAabb3(Aabb3 other) {
    final otherMax = other._max;
    final otherMin = other._min;

    return (_min.x < otherMin.x) &&
        (_min.y < otherMin.y) &&
        (_min.z < otherMin.z) &&
        (_max.x > otherMax.x) &&
        (_max.y > otherMax.y) &&
        (_max.z > otherMax.z);
  }

  /// Return if this contains [other].
  bool containsSphere(Sphere other) {
    final boxExtends = Vector3.all(other.radius);
    final sphereBox = Aabb3.centerAndHalfExtents(other._center, boxExtends);

    return containsAabb3(sphereBox);
  }

  /// Return if this contains [other].
  bool containsVector3(Vector3 other) =>
      (_min.x < other.x) &&
      (_min.y < other.y) &&
      (_min.z < other.z) &&
      (_max.x > other.x) &&
      (_max.y > other.y) &&
      (_max.z > other.z);

  /// Return if this contains [other].
  bool containsTriangle(Triangle other) =>
      containsVector3(other._point0) &&
      containsVector3(other._point1) &&
      containsVector3(other._point2);

  /// Return if this intersects with [other].
  bool intersectsWithAabb3(Aabb3 other) {
    final otherMax = other._max;
    final otherMin = other._min;

    return (_min.x <= otherMax.x) &&
        (_min.y <= otherMax.y) &&
        (_min.z <= otherMax.z) &&
        (_max.x >= otherMin.x) &&
        (_max.y >= otherMin.y) &&
        (_max.z >= otherMin.z);
  }

  /// Return if this intersects with [other].
  bool intersectsWithSphere(Sphere other) {
    final center = other._center;
    final radius = other.radius;
    var d = 0.0;
    var e = 0.0;

    for (var i = 0; i < 3; ++i) {
      if ((e = center[i] - _min[i]) < 0.0) {
        if (e < -radius) {
          return false;
        }

        d = d + e * e;
      } else {
        if ((e = center[i] - _max[i]) > 0.0) {
          if (e > radius) {
            return false;
          }

          d = d + e * e;
        }
      }
    }

    return d <= radius * radius;
  }

  /// Return if this intersects with [other].
  bool intersectsWithVector3(Vector3 other) =>
      (_min.x <= other.x) &&
      (_min.y <= other.y) &&
      (_min.z <= other.z) &&
      (_max.x >= other.x) &&
      (_max.y >= other.y) &&
      (_max.z >= other.z);

  // Avoid allocating these instance on every call to intersectsWithTriangle
  static final _aabbCenter = Vector3.zero();
  static final _aabbHalfExtents = Vector3.zero();
  static final _v0 = Vector3.zero();
  static final _v1 = Vector3.zero();
  static final _v2 = Vector3.zero();
  static final _f0 = Vector3.zero();
  static final _f1 = Vector3.zero();
  static final _f2 = Vector3.zero();
  static final _trianglePlane = Plane();

  static final _u0 = Vector3(1.0, 0.0, 0.0);
  static final _u1 = Vector3(0.0, 1.0, 0.0);
  static final _u2 = Vector3(0.0, 0.0, 1.0);

  /// Return if this intersects with [other].
  /// [epsilon] allows the caller to specify a custum eplsilon value that should
  /// be used for the test. If [result] is specified and an intersection is
  /// found, result is modified to contain more details about the type of
  /// intersection.
  bool intersectsWithTriangle(Triangle other,
      {double epsilon = 1e-3, IntersectionResult? result}) {
    double p0, p1, p2, r, len;
    double a;

    // This line isn't required if we are using center and half extents to
    // define a aabb
    copyCenterAndHalfExtents(_aabbCenter, _aabbHalfExtents);

    // Translate triangle as conceptually moving AABB to origin
    _v0
      ..setFrom(other.point0)
      ..sub(_aabbCenter);
    _v1
      ..setFrom(other.point1)
      ..sub(_aabbCenter);
    _v2
      ..setFrom(other.point2)
      ..sub(_aabbCenter);

    // Translate triangle as conceptually moving AABB to origin
    _f0
      ..setFrom(_v1)
      ..sub(_v0);
    _f1
      ..setFrom(_v2)
      ..sub(_v1);
    _f2
      ..setFrom(_v0)
      ..sub(_v2);

    // Test axes a00..a22 (category 3)
    // Test axis a00
    len = _f0.y * _f0.y + _f0.z * _f0.z;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.z * _f0.y - _v0.y * _f0.z;
      p2 = _v2.z * _f0.y - _v2.y * _f0.z;
      r = _aabbHalfExtents[1] * _f0.z.abs() + _aabbHalfExtents[2] * _f0.y.abs();
      if (math.max(-math.max(p0, p2), math.min(p0, p2)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p2) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u0.crossInto(_f0, result.axis);
      }
    }

    // Test axis a01
    len = _f1.y * _f1.y + _f1.z * _f1.z;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.z * _f1.y - _v0.y * _f1.z;
      p1 = _v1.z * _f1.y - _v1.y * _f1.z;
      r = _aabbHalfExtents[1] * _f1.z.abs() + _aabbHalfExtents[2] * _f1.y.abs();
      if (math.max(-math.max(p0, p1), math.min(p0, p1)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p1) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u0.crossInto(_f1, result.axis);
      }
    }

    // Test axis a02
    len = _f2.y * _f2.y + _f2.z * _f2.z;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.z * _f2.y - _v0.y * _f2.z;
      p1 = _v1.z * _f2.y - _v1.y * _f2.z;
      r = _aabbHalfExtents[1] * _f2.z.abs() + _aabbHalfExtents[2] * _f2.y.abs();
      if (math.max(-math.max(p0, p1), math.min(p0, p1)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p1) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u0.crossInto(_f2, result.axis);
      }
    }

    // Test axis a10
    len = _f0.x * _f0.x + _f0.z * _f0.z;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.x * _f0.z - _v0.z * _f0.x;
      p2 = _v2.x * _f0.z - _v2.z * _f0.x;
      r = _aabbHalfExtents[0] * _f0.z.abs() + _aabbHalfExtents[2] * _f0.x.abs();
      if (math.max(-math.max(p0, p2), math.min(p0, p2)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p2) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u1.crossInto(_f0, result.axis);
      }
    }

    // Test axis a11
    len = _f1.x * _f1.x + _f1.z * _f1.z;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.x * _f1.z - _v0.z * _f1.x;
      p1 = _v1.x * _f1.z - _v1.z * _f1.x;
      r = _aabbHalfExtents[0] * _f1.z.abs() + _aabbHalfExtents[2] * _f1.x.abs();
      if (math.max(-math.max(p0, p1), math.min(p0, p1)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p1) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u1.crossInto(_f1, result.axis);
      }
    }

    // Test axis a12
    len = _f2.x * _f2.x + _f2.z * _f2.z;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.x * _f2.z - _v0.z * _f2.x;
      p1 = _v1.x * _f2.z - _v1.z * _f2.x;
      r = _aabbHalfExtents[0] * _f2.z.abs() + _aabbHalfExtents[2] * _f2.x.abs();
      if (math.max(-math.max(p0, p1), math.min(p0, p1)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p1) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u1.crossInto(_f2, result.axis);
      }
    }

    // Test axis a20
    len = _f0.x * _f0.x + _f0.y * _f0.y;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.y * _f0.x - _v0.x * _f0.y;
      p2 = _v2.y * _f0.x - _v2.x * _f0.y;
      r = _aabbHalfExtents[0] * _f0.y.abs() + _aabbHalfExtents[1] * _f0.x.abs();
      if (math.max(-math.max(p0, p2), math.min(p0, p2)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p2) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u2.crossInto(_f0, result.axis);
      }
    }

    // Test axis a21
    len = _f1.x * _f1.x + _f1.y * _f1.y;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.y * _f1.x - _v0.x * _f1.y;
      p1 = _v1.y * _f1.x - _v1.x * _f1.y;
      r = _aabbHalfExtents[0] * _f1.y.abs() + _aabbHalfExtents[1] * _f1.x.abs();
      if (math.max(-math.max(p0, p1), math.min(p0, p1)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p1) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u2.crossInto(_f1, result.axis);
      }
    }

    // Test axis a22
    len = _f2.x * _f2.x + _f2.y * _f2.y;
    if (len > epsilon) {
      // Ignore tests on degenerate axes.
      p0 = _v0.y * _f2.x - _v0.x * _f2.y;
      p1 = _v1.y * _f2.x - _v1.x * _f2.y;
      r = _aabbHalfExtents[0] * _f2.y.abs() + _aabbHalfExtents[1] * _f2.x.abs();
      if (math.max(-math.max(p0, p1), math.min(p0, p1)) > r + epsilon) {
        return false; // Axis is a separating axis
      }

      a = math.min(p0, p1) - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        _u2.crossInto(_f2, result.axis);
      }
    }

    // Test the three axes corresponding to the face normals of AABB b (category 1). // Exit if...
    // ... [-e0, e0] and [min(v0.x,v1.x,v2.x), max(v0.x,v1.x,v2.x)] do not overlap
    if (math.max(_v0.x, math.max(_v1.x, _v2.x)) < -_aabbHalfExtents[0] ||
        math.min(_v0.x, math.min(_v1.x, _v2.x)) > _aabbHalfExtents[0]) {
      return false;
    }
    a = math.min(_v0.x, math.min(_v1.x, _v2.x)) - _aabbHalfExtents[0];
    if (result != null && (result._depth == null || (result._depth!) < a)) {
      result._depth = a;
      result.axis.setFrom(_u0);
    }
    // ... [-e1, e1] and [min(v0.y,v1.y,v2.y), max(v0.y,v1.y,v2.y)] do not overlap
    if (math.max(_v0.y, math.max(_v1.y, _v2.y)) < -_aabbHalfExtents[1] ||
        math.min(_v0.y, math.min(_v1.y, _v2.y)) > _aabbHalfExtents[1]) {
      return false;
    }
    a = math.min(_v0.y, math.min(_v1.y, _v2.y)) - _aabbHalfExtents[1];
    if (result != null && (result._depth == null || (result._depth!) < a)) {
      result._depth = a;
      result.axis.setFrom(_u1);
    }
    // ... [-e2, e2] and [min(v0.z,v1.z,v2.z), max(v0.z,v1.z,v2.z)] do not overlap
    if (math.max(_v0.z, math.max(_v1.z, _v2.z)) < -_aabbHalfExtents[2] ||
        math.min(_v0.z, math.min(_v1.z, _v2.z)) > _aabbHalfExtents[2]) {
      return false;
    }
    a = math.min(_v0.z, math.min(_v1.z, _v2.z)) - _aabbHalfExtents[2];
    if (result != null && (result._depth == null || (result._depth!) < a)) {
      result._depth = a;
      result.axis.setFrom(_u2);
    }

    // It seems like that wee need to move the edges before creating the
    // plane
    _v0.add(_aabbCenter);

    // Test separating axis corresponding to triangle face normal (category 2)
    _f0.crossInto(_f1, _trianglePlane.normal);
    _trianglePlane.constant = _trianglePlane.normal.dot(_v0);
    return intersectsWithPlane(_trianglePlane, result: result);
  }

  /// Return if this intersects with [other]
  bool intersectsWithPlane(Plane other, {IntersectionResult? result}) {
    // This line is not necessary with a (center, extents) AABB representation
    copyCenterAndHalfExtents(_aabbCenter, _aabbHalfExtents);

    // Compute the projection interval radius of b onto L(t) = b.c + t * p.n
    final r = _aabbHalfExtents[0] * other.normal[0].abs() +
        _aabbHalfExtents[1] * other.normal[1].abs() +
        _aabbHalfExtents[2] * other.normal[2].abs();
    // Compute distance of box center from plane
    final s = other.normal.dot(_aabbCenter) - other.constant;
    // Intersection occurs when distance s falls within [-r,+r] interval
    if (s.abs() <= r) {
      final a = s - r;
      if (result != null && (result._depth == null || (result._depth!) < a)) {
        result._depth = a;
        result.axis.setFrom(other.normal);
      }
      return true;
    }

    return false;
  }

  // Avoid allocating these instance on every call to intersectsWithTriangle
  static final _quadTriangle0 = Triangle();
  static final _quadTriangle1 = Triangle();

  /// Return `true` if this intersects with [other].
  ///
  /// If [result] is specified and an intersection is
  /// found, result is modified to contain more details about the type of
  /// intersection.
  bool intersectsWithQuad(Quad other, {IntersectionResult? result}) {
    other.copyTriangles(_quadTriangle0, _quadTriangle1);

    return intersectsWithTriangle(_quadTriangle0, result: result) ||
        intersectsWithTriangle(_quadTriangle1, result: result);
  }
}

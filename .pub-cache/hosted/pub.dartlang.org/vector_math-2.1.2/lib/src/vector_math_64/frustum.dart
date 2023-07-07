// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_64;

/// Defines a frustum constructed out of six [Plane]s.
class Frustum {
  final Plane _plane0;
  final Plane _plane1;
  final Plane _plane2;
  final Plane _plane3;
  final Plane _plane4;
  final Plane _plane5;

  /// The first plane that defines the bounds of this frustum.
  Plane get plane0 => _plane0;

  /// The second plane that defines the bounds of this frustum.
  Plane get plane1 => _plane1;

  /// The third plane that defines the bounds of this frustum.
  Plane get plane2 => _plane2;

  /// The fourth plane that defines the bounds of this frustum.
  Plane get plane3 => _plane3;

  /// The fifth plane that defines the bounds of this frustum.
  Plane get plane4 => _plane4;

  /// The sixed plane that defines the bounds of this frustum.
  Plane get plane5 => _plane5;

  /// Create a new frustum without initializing its bounds.
  Frustum()
      : _plane0 = Plane(),
        _plane1 = Plane(),
        _plane2 = Plane(),
        _plane3 = Plane(),
        _plane4 = Plane(),
        _plane5 = Plane();

  /// Create a new frustum as a copy of [other].
  factory Frustum.copy(Frustum other) => Frustum()..copyFrom(other);

  /// Create a new furstum from a [matrix].
  factory Frustum.matrix(Matrix4 matrix) => Frustum()..setFromMatrix(matrix);

  /// Copy the [other] frustum into this.
  void copyFrom(Frustum other) {
    _plane0.copyFrom(other._plane0);
    _plane1.copyFrom(other._plane1);
    _plane2.copyFrom(other._plane2);
    _plane3.copyFrom(other._plane3);
    _plane4.copyFrom(other._plane4);
    _plane5.copyFrom(other._plane5);
  }

  /// Set this from [matrix].
  void setFromMatrix(Matrix4 matrix) {
    final me = matrix.storage;
    final me0 = me[0], me1 = me[1], me2 = me[2], me3 = me[3];
    final me4 = me[4], me5 = me[5], me6 = me[6], me7 = me[7];
    final me8 = me[8], me9 = me[9], me10 = me[10], me11 = me[11];
    final me12 = me[12], me13 = me[13], me14 = me[14], me15 = me[15];

    _plane0
      ..setFromComponents(me3 - me0, me7 - me4, me11 - me8, me15 - me12)
      ..normalize();
    _plane1
      ..setFromComponents(me3 + me0, me7 + me4, me11 + me8, me15 + me12)
      ..normalize();
    _plane2
      ..setFromComponents(me3 + me1, me7 + me5, me11 + me9, me15 + me13)
      ..normalize();
    _plane3
      ..setFromComponents(me3 - me1, me7 - me5, me11 - me9, me15 - me13)
      ..normalize();
    _plane4
      ..setFromComponents(me3 - me2, me7 - me6, me11 - me10, me15 - me14)
      ..normalize();
    _plane5
      ..setFromComponents(me3 + me2, me7 + me6, me11 + me10, me15 + me14)
      ..normalize();
  }

  /// Check if this contains a [point].
  bool containsVector3(Vector3 point) {
    if (_plane0.distanceToVector3(point) < 0.0) {
      return false;
    }

    if (_plane1.distanceToVector3(point) < 0.0) {
      return false;
    }

    if (_plane2.distanceToVector3(point) < 0.0) {
      return false;
    }

    if (_plane3.distanceToVector3(point) < 0.0) {
      return false;
    }

    if (_plane4.distanceToVector3(point) < 0.0) {
      return false;
    }

    if (_plane5.distanceToVector3(point) < 0.0) {
      return false;
    }

    return true;
  }

  /// Check if this intersects with [aabb].
  bool intersectsWithAabb3(Aabb3 aabb) {
    if (_intersectsWithAabb3CheckPlane(aabb, _plane0)) {
      return false;
    }

    if (_intersectsWithAabb3CheckPlane(aabb, _plane1)) {
      return false;
    }

    if (_intersectsWithAabb3CheckPlane(aabb, _plane2)) {
      return false;
    }

    if (_intersectsWithAabb3CheckPlane(aabb, _plane3)) {
      return false;
    }

    if (_intersectsWithAabb3CheckPlane(aabb, _plane4)) {
      return false;
    }

    if (_intersectsWithAabb3CheckPlane(aabb, _plane5)) {
      return false;
    }

    return true;
  }

  /// Check if this intersects with [sphere].
  bool intersectsWithSphere(Sphere sphere) {
    final negativeRadius = -sphere.radius;
    final center = sphere.center;

    if (_plane0.distanceToVector3(center) < negativeRadius) {
      return false;
    }

    if (_plane1.distanceToVector3(center) < negativeRadius) {
      return false;
    }

    if (_plane2.distanceToVector3(center) < negativeRadius) {
      return false;
    }

    if (_plane3.distanceToVector3(center) < negativeRadius) {
      return false;
    }

    if (_plane4.distanceToVector3(center) < negativeRadius) {
      return false;
    }

    if (_plane5.distanceToVector3(center) < negativeRadius) {
      return false;
    }

    return true;
  }

  /// Calculate the corners of this and write them into [corner0] to
  // [corner7].
  void calculateCorners(
      Vector3 corner0,
      Vector3 corner1,
      Vector3 corner2,
      Vector3 corner3,
      Vector3 corner4,
      Vector3 corner5,
      Vector3 corner6,
      Vector3 corner7) {
    Plane.intersection(_plane0, _plane2, _plane4, corner0);
    Plane.intersection(_plane0, _plane3, _plane4, corner1);
    Plane.intersection(_plane0, _plane3, _plane5, corner2);
    Plane.intersection(_plane0, _plane2, _plane5, corner3);
    Plane.intersection(_plane1, _plane2, _plane4, corner4);
    Plane.intersection(_plane1, _plane3, _plane4, corner5);
    Plane.intersection(_plane1, _plane3, _plane5, corner6);
    Plane.intersection(_plane1, _plane2, _plane5, corner7);
  }

  bool _intersectsWithAabb3CheckPlane(Aabb3 aabb, Plane plane) {
    double outPx, outPy, outPz, outNx, outNy, outNz;

    if (plane._normal.x < 0.0) {
      outPx = aabb.min.x;
      outNx = aabb.max.x;
    } else {
      outPx = aabb.max.x;
      outNx = aabb.min.x;
    }

    if (plane._normal.y < 0.0) {
      outPy = aabb.min.y;
      outNy = aabb.max.y;
    } else {
      outPy = aabb.max.y;
      outNy = aabb.min.y;
    }

    if (plane._normal.z < 0.0) {
      outPz = aabb.min.z;
      outNz = aabb.max.z;
    } else {
      outPz = aabb.max.z;
      outNz = aabb.min.z;
    }

    final d1 = plane._normal.x * outPx +
        plane._normal.y * outPy +
        plane._normal.z * outPz +
        plane.constant;
    final d2 = plane._normal.x * outNx +
        plane._normal.y * outNy +
        plane._normal.z * outNz +
        plane.constant;

    return d1 < 0 && d2 < 0;
  }
}

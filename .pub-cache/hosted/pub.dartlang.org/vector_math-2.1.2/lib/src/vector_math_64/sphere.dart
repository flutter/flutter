// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_64;

/// Defines a sphere with a [center] and a [radius].
class Sphere {
  final Vector3 _center;

  /// The [radius] of the sphere.
  double radius;

  /// The [center] of the sphere.
  Vector3 get center => _center;

  /// Create a new, uninitialized sphere.
  Sphere()
      : _center = Vector3.zero(),
        radius = 0.0;

  /// Create a sphere as a copy of [other].
  Sphere.copy(Sphere other)
      : _center = Vector3.copy(other._center),
        radius = other.radius;

  /// Create a sphere from a [center] and a [radius].
  Sphere.centerRadius(Vector3 center, this.radius)
      : _center = Vector3.copy(center);

  /// Copy the sphere from [other] into this.
  void copyFrom(Sphere other) {
    _center.setFrom(other._center);
    radius = other.radius;
  }

  /// Return if this contains [other].
  bool containsVector3(Vector3 other) =>
      other.distanceToSquared(center) < radius * radius;

  /// Return if this intersects with [other].
  bool intersectsWithVector3(Vector3 other) =>
      other.distanceToSquared(center) <= radius * radius;

  /// Return if this intersects with [other].
  bool intersectsWithSphere(Sphere other) {
    final radiusSum = radius + other.radius;

    return other.center.distanceToSquared(center) <= (radiusSum * radiusSum);
  }
}

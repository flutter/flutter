// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of vector_math_64;

class Plane {
  final Vector3 _normal;
  double constant;

  /// Find the intersection point between the three planes [a], [b] and [c] and
  /// copy it into [result].
  static void intersection(Plane a, Plane b, Plane c, Vector3 result) {
    final cross = Vector3.zero();

    b.normal.crossInto(c.normal, cross);

    final f = -a.normal.dot(cross);

    final v1 = cross.scaled(a.constant);

    c.normal.crossInto(a.normal, cross);

    final v2 = cross.scaled(b.constant);

    a.normal.crossInto(b.normal, cross);

    final v3 = cross.scaled(c.constant);

    result
      ..x = (v1.x + v2.x + v3.x) / f
      ..y = (v1.y + v2.y + v3.y) / f
      ..z = (v1.z + v2.z + v3.z) / f;
  }

  Vector3 get normal => _normal;

  Plane()
      : _normal = Vector3.zero(),
        constant = 0.0;

  Plane.copy(Plane other)
      : _normal = Vector3.copy(other._normal),
        constant = other.constant;

  Plane.components(double x, double y, double z, this.constant)
      : _normal = Vector3(x, y, z);

  Plane.normalconstant(Vector3 normal_, this.constant)
      : _normal = Vector3.copy(normal_);

  void copyFrom(Plane o) {
    _normal.setFrom(o._normal);
    constant = o.constant;
  }

  void setFromComponents(double x, double y, double z, double w) {
    _normal.setValues(x, y, z);
    constant = w;
  }

  void normalize() {
    final inverseLength = 1.0 / normal.length;
    _normal.scale(inverseLength);
    constant *= inverseLength;
  }

  double distanceToVector3(Vector3 point) => _normal.dot(point) + constant;
}

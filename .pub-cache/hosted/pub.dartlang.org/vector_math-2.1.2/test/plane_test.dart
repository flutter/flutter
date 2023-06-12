// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testPlaneNormalize() {
  final plane = Plane.normalconstant($v3(2.0, 0.0, 0.0), 2.0);

  plane.normalize();

  expect(plane.normal.x, equals(1.0));
  expect(plane.normal.y, equals(0.0));
  expect(plane.normal.z, equals(0.0));
  expect(plane.normal.length, equals(1.0));
  expect(plane.constant, equals(1.0));
}

void testPlaneDistanceToVector3() {
  final plane = Plane.normalconstant($v3(2.0, 0.0, 0.0), -2.0);

  plane.normalize();

  expect(plane.distanceToVector3($v3(4.0, 0.0, 0.0)), equals(3.0));
  expect(plane.distanceToVector3($v3(1.0, 0.0, 0.0)), equals(0.0));
}

void testPlaneIntersection() {
  final plane1 = Plane.normalconstant($v3(1.0, 0.0, 0.0), -2.0);
  final plane2 = Plane.normalconstant($v3(0.0, 1.0, 0.0), -3.0);
  final plane3 = Plane.normalconstant($v3(0.0, 0.0, 1.0), -4.0);

  plane1.normalize();
  plane2.normalize();
  plane3.normalize();

  final point = Vector3.zero();

  Plane.intersection(plane1, plane2, plane3, point);

  expect(point.x, equals(2.0));
  expect(point.y, equals(3.0));
  expect(point.z, equals(4.0));
}

void main() {
  group('Plane', () {
    test('Normalize', testPlaneNormalize);
    test('DistanceToVector3', testPlaneDistanceToVector3);
    test('Intersection', testPlaneIntersection);
  });
}

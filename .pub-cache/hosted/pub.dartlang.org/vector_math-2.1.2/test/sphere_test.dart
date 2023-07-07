// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testSphereContainsVector3() {
  final parent = Sphere.centerRadius($v3(1.0, 1.0, 1.0), 2.0);
  final child = $v3(1.0, 1.0, 2.0);
  final cutting = $v3(1.0, 3.0, 1.0);
  final outside = $v3(-10.0, 10.0, 10.0);

  expect(parent.containsVector3(child), isTrue);
  expect(parent.containsVector3(cutting), isFalse);
  expect(parent.containsVector3(outside), isFalse);
}

void testSphereIntersectionVector3() {
  final parent = Sphere.centerRadius($v3(1.0, 1.0, 1.0), 2.0);
  final child = $v3(1.0, 1.0, 2.0);
  final cutting = $v3(1.0, 3.0, 1.0);
  final outside = $v3(-10.0, 10.0, 10.0);

  expect(parent.intersectsWithVector3(child), isTrue);
  expect(parent.intersectsWithVector3(cutting), isTrue);
  expect(parent.intersectsWithVector3(outside), isFalse);
}

void testSphereIntersectionSphere() {
  final parent = Sphere.centerRadius($v3(1.0, 1.0, 1.0), 2.0);
  final child = Sphere.centerRadius($v3(1.0, 1.0, 2.0), 1.0);
  final cutting = Sphere.centerRadius($v3(1.0, 6.0, 1.0), 3.0);
  final outside = Sphere.centerRadius($v3(10.0, -1.0, 1.0), 1.0);

  expect(parent.intersectsWithSphere(child), isTrue);
  expect(parent.intersectsWithSphere(cutting), isTrue);
  expect(parent.intersectsWithSphere(outside), isFalse);
}

void main() {
  group('Sphere', () {
    test(' Contains Vector3', testSphereContainsVector3);
    test('Sphere Intersection Vector3', testSphereIntersectionVector3);
    test('Sphere Intersection Sphere', testSphereIntersectionSphere);
  });
}

// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testFrustumContainsVector3() {
  final frustum =
      Frustum.matrix(makeFrustumMatrix(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0));

  expect(frustum.containsVector3($v3(0.0, 0.0, 0.0)), isFalse);
  expect(frustum.containsVector3($v3(0.0, 0.0, -50.0)), isTrue);
  expect(frustum.containsVector3($v3(0.0, 0.0, -1.001)), isTrue);
  expect(frustum.containsVector3($v3(-1.0, -1.0, -1.001)), isTrue);
  expect(frustum.containsVector3($v3(-1.1, -1.1, -1.001)), isFalse);
  expect(frustum.containsVector3($v3(1.0, 1.0, -1.001)), isTrue);
  expect(frustum.containsVector3($v3(1.1, 1.1, -1.001)), isFalse);
  expect(frustum.containsVector3($v3(0.0, 0.0, -99.999)), isTrue);
  expect(frustum.containsVector3($v3(-99.999, -99.999, -99.999)), isTrue);
  expect(frustum.containsVector3($v3(-100.1, -100.1, -100.1)), isFalse);
  expect(frustum.containsVector3($v3(99.999, 99.999, -99.999)), isTrue);
  expect(frustum.containsVector3($v3(100.1, 100.1, -100.1)), isFalse);
  expect(frustum.containsVector3($v3(0.0, 0.0, -101.0)), isFalse);
}

void testFrustumIntersectsWithSphere() {
  final frustum =
      Frustum.matrix(makeFrustumMatrix(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0));

  expect(
      frustum
          .intersectsWithSphere(Sphere.centerRadius($v3(0.0, 0.0, 0.0), 0.0)),
      isFalse);
  expect(
      frustum
          .intersectsWithSphere(Sphere.centerRadius($v3(0.0, 0.0, 0.0), 0.9)),
      isFalse);
  expect(
      frustum
          .intersectsWithSphere(Sphere.centerRadius($v3(0.0, 0.0, 0.0), 1.1)),
      isTrue);
  expect(
      frustum
          .intersectsWithSphere(Sphere.centerRadius($v3(0.0, 0.0, -50.0), 0.0)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(0.0, 0.0, -1.001), 0.0)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(-1.0, -1.0, -1.001), 0.0)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(-1.1, -1.1, -1.001), 0.0)),
      isFalse);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(-1.1, -1.1, -1.001), 0.5)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(1.0, 1.0, -1.001), 0.0)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(1.1, 1.1, -1.001), 0.0)),
      isFalse);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(1.1, 1.1, -1.001), 0.5)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(0.0, 0.0, -99.999), 0.5)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(0.0, 0.0, -99.999), 0.0)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(-99.999, -99.999, -99.999), 0.0)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(-100.1, -100.1, -100.1), 0.0)),
      isFalse);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(-100.1, -100.1, -100.1), 0.5)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(99.999, 99.999, -99.999), 0.0)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(100.1, 100.1, -100.1), 0.0)),
      isFalse);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(100.1, 100.1, -100.1), 0.2)),
      isTrue);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(0.0, 0.0, -101.0), 0.0)),
      isFalse);
  expect(
      frustum.intersectsWithSphere(
          Sphere.centerRadius($v3(0.0, 0.0, -101.0), 1.1)),
      isTrue);
}

void testFrustumIntersectsWithAabb3() {
  final frustum =
      Frustum.matrix(makeFrustumMatrix(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0));

  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(500.0, 500.0, 500.0), $v3(1000.0, 1000.0, 1000.0))),
      isFalse);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(-150.0, -150.0, -150.0), $v3(150.0, 150.0, 150.0))),
      isTrue);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(-1.5, -1.5, -1.5), $v3(1.5, 1.5, 1.5))),
      isTrue);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(0.0, 0.0, -50.0), $v3(1.0, 1.0, -49.0))),
      isTrue);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(0.0, 0.0, 50.0), $v3(1.0, 1.0, 51.0))),
      isFalse);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(0.0, 0.0, -0.99), $v3(1.0, 1.0, 1.0))),
      isFalse);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(0.0, 0.0, -1.0), $v3(1.0, 1.0, 1.0))),
      isTrue);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(0.0, 1.0, -10.0), $v3(1.0, 2.0, 15.0))),
      isTrue);
  expect(
      frustum.intersectsWithAabb3(
          Aabb3.minMax($v3(1.1, 1.1, -1.0), $v3(2.0, 2.0, 0.0))),
      isFalse);
}

void testFrustumCalculateCorners() {
  final frustum =
      Frustum.matrix(makeFrustumMatrix(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0));

  final c0 = Vector3.zero();
  final c1 = Vector3.zero();
  final c2 = Vector3.zero();
  final c3 = Vector3.zero();
  final c4 = Vector3.zero();
  final c5 = Vector3.zero();
  final c6 = Vector3.zero();
  final c7 = Vector3.zero();

  frustum.calculateCorners(c0, c1, c2, c3, c4, c5, c6, c7);

  relativeTest(c0.x, 100.0);
  relativeTest(c0.y, -100.0);
  relativeTest(c0.z, -100.0);
  relativeTest(c1.x, 100.0);
  relativeTest(c1.y, 100.0);
  relativeTest(c1.z, -100.0);
  relativeTest(c2.x, 1.0);
  relativeTest(c2.y, 1.0);
  relativeTest(c2.z, -1.0);
  relativeTest(c3.x, 1.0);
  relativeTest(c3.y, -1.0);
  relativeTest(c3.z, -1.0);
  relativeTest(c4.x, -100.0);
  relativeTest(c4.y, -100.0);
  relativeTest(c4.z, -100.0);
  relativeTest(c5.x, -100.0);
  relativeTest(c5.y, 100.0);
  relativeTest(c5.z, -100.0);
  relativeTest(c6.x, -1.0);
  relativeTest(c6.y, 1.0);
  relativeTest(c6.z, -1.0);
  relativeTest(c7.x, -1.0);
  relativeTest(c7.y, -1.0);
  relativeTest(c7.z, -1.0);
}

void main() {
  group('Frustum', () {
    test('ContainsVector3', testFrustumContainsVector3);
    test('IntersectsWithSphere', testFrustumIntersectsWithSphere);
    test('IntersectsWithAabb3', testFrustumIntersectsWithAabb3);
    test('CalculateCorners', testFrustumCalculateCorners);
  });
}

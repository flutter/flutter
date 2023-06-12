// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testRayAt() {
  final parent = Ray.originDirection($v3(1.0, 1.0, 1.0), $v3(-1.0, 1.0, 1.0));

  final atOrigin = parent.at(0.0);
  final atPositive = parent.at(1.0);
  final atNegative = parent.at(-2.0);

  expect(atOrigin.x, equals(1.0));
  expect(atOrigin.y, equals(1.0));
  expect(atOrigin.z, equals(1.0));
  expect(atPositive.x, equals(0.0));
  expect(atPositive.y, equals(2.0));
  expect(atPositive.z, equals(2.0));
  expect(atNegative.x, equals(3.0));
  expect(atNegative.y, equals(-1.0));
  expect(atNegative.z, equals(-1.0));

  atOrigin.setZero();
  atPositive.setZero();
  atNegative.setZero();

  parent.copyAt(atOrigin, 0.0);
  parent.copyAt(atPositive, 1.0);
  parent.copyAt(atNegative, -2.0);

  expect(atOrigin.x, equals(1.0));
  expect(atOrigin.y, equals(1.0));
  expect(atOrigin.z, equals(1.0));
  expect(atPositive.x, equals(0.0));
  expect(atPositive.y, equals(2.0));
  expect(atPositive.z, equals(2.0));
  expect(atNegative.x, equals(3.0));
  expect(atNegative.y, equals(-1.0));
  expect(atNegative.z, equals(-1.0));
}

void testRayIntersectionSphere() {
  final parent = Ray.originDirection($v3(1.0, 1.0, 1.0), $v3(0.0, 1.0, 0.0));
  final inside = Sphere.centerRadius($v3(2.0, 1.0, 1.0), 2.0);
  final hitting = Sphere.centerRadius($v3(2.5, 4.5, 1.0), 2.0);
  final cutting = Sphere.centerRadius($v3(0.0, 5.0, 1.0), 1.0);
  final outside = Sphere.centerRadius($v3(-2.5, 1.0, 1.0), 1.0);
  final behind = Sphere.centerRadius($v3(1.0, -1.0, 1.0), 1.0);

  expect(parent.intersectsWithSphere(inside), equals(math.sqrt(3.0)));
  expect(parent.intersectsWithSphere(hitting), equals(3.5 - math.sqrt(1.75)));
  expect(parent.intersectsWithSphere(cutting), equals(4.0));
  expect(parent.intersectsWithSphere(outside), equals(null));
  expect(parent.intersectsWithSphere(behind), equals(null));
}

void testRayIntersectionTriangle() {
  final parent = Ray.originDirection($v3(1.0, 1.0, 1.0), $v3(0.0, 1.0, 0.0));
  final hitting = Triangle.points(
      $v3(2.0, 2.0, 0.0), $v3(0.0, 4.0, -1.0), $v3(0.0, 4.0, 3.0));
  final cutting = Triangle.points(
      $v3(0.0, 1.5, 1.0), $v3(2.0, 1.5, 1.0), $v3(1.0, 1.5, 3.0));
  final outside = Triangle.points(
      $v3(2.0, 2.0, 0.0), $v3(2.0, 6.0, 0.0), $v3(2.0, 2.0, 3.0));
  final behind = Triangle.points(
      $v3(0.0, 0.0, 0.0), $v3(0.0, 3.0, 0.0), $v3(0.0, 3.0, 4.0));

  absoluteTest(parent.intersectsWithTriangle(hitting), 2.0);
  absoluteTest(parent.intersectsWithTriangle(cutting), 0.5);
  expect(parent.intersectsWithTriangle(outside), equals(null));
  expect(parent.intersectsWithTriangle(behind), equals(null));

  // Test cases from real-world failures:
  // Just barely intersects, but gets rounded out
  final p2 = Ray.originDirection(
      $v3(0.0, -0.16833500564098358, 0.7677000164985657),
      $v3(-0.0, -0.8124330043792725, -0.5829949975013733));
  final t2 = Triangle.points(
      $v3(0.03430179879069328, -0.7268069982528687, 0.3532710075378418),
      $v3(0.0, -0.7817990183830261, 0.3641969859600067),
      $v3(0.0, -0.7293699979782104, 0.3516849875450134));
  expect(p2.intersectsWithTriangle(t2), closeTo(0.7078371874391822, 1e-10));
  // Ray is not quite perpendicular to triangle, but gets rounded out
  final p3 = Ray.originDirection(
      $v3(0.023712199181318283, -0.15045200288295746, 0.7751160264015198),
      $v3(0.6024960279464722, -0.739005982875824, -0.3013699948787689));
  final t3 = Triangle.points(
      $v3(0.16174300014972687, -0.3446039855480194, 0.7121580243110657),
      $v3(0.1857299953699112, -0.3468630015850067, 0.6926270127296448),
      $v3(0.18045000731945038, -0.3193660080432892, 0.6921690106391907));
  expect(p3.intersectsWithTriangle(t3), closeTo(0.2538471189773835, 1e-10));
}

void testRayIntersectionAabb3() {
  final parent = Ray.originDirection($v3(1.0, 1.0, 1.0), $v3(0.0, 1.0, 0.0));
  final hitting = Aabb3.minMax($v3(0.5, 3.5, -10.0), $v3(2.5, 5.5, 10.0));
  final cutting = Aabb3.minMax($v3(0.0, 2.0, 1.0), $v3(2.0, 3.0, 2.0));
  final outside = Aabb3.minMax($v3(2.0, 0.0, 0.0), $v3(6.0, 6.0, 6.0));
  final behind = Aabb3.minMax($v3(0.0, -2.0, 0.0), $v3(2.0, 0.0, 2.0));
  final inside = Aabb3.minMax($v3(0.0, 0.0, 0.0), $v3(2.0, 2.0, 2.0));

  expect(parent.intersectsWithAabb3(hitting), equals(2.5));
  expect(parent.intersectsWithAabb3(cutting), equals(1.0));
  expect(parent.intersectsWithAabb3(outside), equals(null));
  expect(parent.intersectsWithAabb3(behind), equals(null));
  expect(parent.intersectsWithAabb3(inside), equals(-1.0));
}

void main() {
  group('Ray', () {
    test('At', testRayAt);
    test('Intersection Sphere', testRayIntersectionSphere);
    test('Intersection Triangle', testRayIntersectionTriangle);
    test('Intersection Aabb3', testRayIntersectionAabb3);
  });
}

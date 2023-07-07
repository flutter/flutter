// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testAabb2Center() {
  final aabb = Aabb2.minMax($v2(1.0, 2.0), $v2(8.0, 16.0));
  final center = aabb.center;

  expect(center.x, equals(4.5));
  expect(center.y, equals(9.0));
}

void testAabb2CopyCenterAndHalfExtents() {
  final a1 = Aabb2.minMax($v2(10.0, 20.0), $v2(20.0, 40.0));
  final a2 = Aabb2.minMax($v2(-10.0, -20.0), $v2(0.0, 0.0));

  final center = Vector2.zero();
  final halfExtents = Vector2.zero();

  a1.copyCenterAndHalfExtents(center, halfExtents);

  relativeTest(center, $v2(15.0, 30.0));
  relativeTest(halfExtents, $v2(5.0, 10.0));

  a2.copyCenterAndHalfExtents(center, halfExtents);

  relativeTest(center, $v2(-5.0, -10.0));
  relativeTest(halfExtents, $v2(5.0, 10.0));
}

void testAabb2CenterAndHalfExtents() {
  final a1 = Aabb2.centerAndHalfExtents($v2(0.0, 0.0), $v2(10.0, 20.0));
  final a2 = Aabb2.centerAndHalfExtents($v2(-10.0, -20.0), $v2(10.0, 20.0));

  relativeTest(a1.min, $v2(-10.0, -20.0));
  relativeTest(a1.max, $v2(10.0, 20.0));

  relativeTest(a2.min, $v2(-20.0, -40.0));
  relativeTest(a2.max, $v2(0.0, 0.0));
}

void testAabb2SetCenterAndHalfExtents() {
  final a1 = Aabb2();
  final a2 = Aabb2();

  a1.setCenterAndHalfExtents($v2(0.0, 0.0), $v2(10.0, 20.0));

  relativeTest(a1.min, $v2(-10.0, -20.0));
  relativeTest(a1.max, $v2(10.0, 20.0));

  a2.setCenterAndHalfExtents($v2(-10.0, -20.0), $v2(10.0, 20.0));

  relativeTest(a2.min, $v2(-20.0, -40.0));
  relativeTest(a2.max, $v2(0.0, 0.0));
}

void testAabb2ContainsAabb2() {
  final parent = Aabb2.minMax($v2(1.0, 1.0), $v2(8.0, 8.0));
  final child = Aabb2.minMax($v2(2.0, 2.0), $v2(7.0, 7.0));
  final cutting = Aabb2.minMax($v2(0.0, 0.0), $v2(5.0, 5.0));
  final outside = Aabb2.minMax($v2(10.0, 10.0), $v2(20.0, 20.0));
  final grandParent = Aabb2.minMax($v2(0.0, 0.0), $v2(10.0, 10.0));

  expect(parent.containsAabb2(child), isTrue);
  expect(parent.containsAabb2(parent), isFalse);
  expect(parent.containsAabb2(cutting), isFalse);
  expect(parent.containsAabb2(outside), isFalse);
  expect(parent.containsAabb2(grandParent), isFalse);
}

void testAabb2ContainsVector2() {
  final parent = Aabb2.minMax($v2(1.0, 1.0), $v2(8.0, 8.0));
  final child = $v2(2.0, 2.0);
  final cutting = $v2(1.0, 8.0);
  final outside = $v2(-1.0, 0.0);

  expect(parent.containsVector2(child), isTrue);
  expect(parent.containsVector2(cutting), isFalse);
  expect(parent.containsVector2(outside), isFalse);
}

void testAabb2IntersectionAabb2() {
  final parent = Aabb2.minMax($v2(1.0, 1.0), $v2(8.0, 8.0));
  final child = Aabb2.minMax($v2(2.0, 2.0), $v2(7.0, 7.0));
  final cutting = Aabb2.minMax($v2(0.0, 0.0), $v2(5.0, 5.0));
  final outside = Aabb2.minMax($v2(10.0, 10.0), $v2(20.0, 20.0));
  final grandParent = Aabb2.minMax($v2(0.0, 0.0), $v2(10.0, 10.0));

  final siblingOne = Aabb2.minMax($v2(0.0, 0.0), $v2(3.0, 3.0));
  final siblingTwo = Aabb2.minMax($v2(3.0, 0.0), $v2(6.0, 3.0));
  final siblingThree = Aabb2.minMax($v2(3.0, 3.0), $v2(6.0, 6.0));

  expect(parent.intersectsWithAabb2(child), isTrue);
  expect(child.intersectsWithAabb2(parent), isTrue);

  expect(parent.intersectsWithAabb2(parent), isTrue);

  expect(parent.intersectsWithAabb2(cutting), isTrue);
  expect(cutting.intersectsWithAabb2(parent), isTrue);

  expect(parent.intersectsWithAabb2(outside), isFalse);
  expect(outside.intersectsWithAabb2(parent), isFalse);

  expect(parent.intersectsWithAabb2(grandParent), isTrue);
  expect(grandParent.intersectsWithAabb2(parent), isTrue);

  expect(siblingOne.intersectsWithAabb2(siblingTwo), isTrue,
      reason: 'Touching edges are counted as intersection.');
  expect(siblingOne.intersectsWithAabb2(siblingThree), isTrue,
      reason: 'Touching corners are counted as intersection.');
}

void testAabb2IntersectionVector2() {
  final parent = Aabb2.minMax($v2(1.0, 1.0), $v2(8.0, 8.0));
  final child = $v2(2.0, 2.0);
  final cutting = $v2(1.0, 8.0);
  final outside = $v2(-1.0, 0.0);

  expect(parent.intersectsWithVector2(child), isTrue);
  expect(parent.intersectsWithVector2(cutting), isTrue);
  expect(parent.intersectsWithVector2(outside), isFalse);
}

void testAabb2Hull() {
  final a = Aabb2.minMax($v2(1.0, 1.0), $v2(3.0, 4.0));
  final b = Aabb2.minMax($v2(3.0, 2.0), $v2(6.0, 2.0));

  a.hull(b);

  expect(a.min.x, equals(1.0));
  expect(a.min.y, equals(1.0));
  expect(a.max.x, equals(6.0));
  expect(a.max.y, equals(4.0));
}

void testAabb2HullPoint() {
  final a = Aabb2.minMax($v2(1.0, 1.0), $v2(3.0, 4.0));
  final b = $v2(6.0, 2.0);

  a.hullPoint(b);

  expect(a.min.x, equals(1.0));
  expect(a.min.y, equals(1.0));
  expect(a.max.x, equals(6.0));
  expect(a.max.y, equals(4.0));

  final c = $v2(0.0, 1.0);

  a.hullPoint(c);

  expect(a.min.x, equals(0.0));
  expect(a.min.y, equals(1.0));
  expect(a.max.x, equals(6.0));
  expect(a.max.y, equals(4.0));
}

void testAabb2Rotate() {
  final rotation = Matrix3.rotationZ(math.pi / 4);
  final input = Aabb2.minMax($v2(1.0, 1.0), $v2(3.0, 3.0));

  final result = input..rotate(rotation);

  relativeTest(result.min.x, 2 - math.sqrt(2));
  relativeTest(result.min.y, 2 - math.sqrt(2));
  relativeTest(result.max.x, 2 + math.sqrt(2));
  relativeTest(result.max.y, 2 + math.sqrt(2));
  relativeTest(result.center.x, 2.0);
  relativeTest(result.center.y, 2.0);
}

void testAabb2Transform() {
  final rotation = Matrix3.rotationZ(math.pi / 4);
  final input = Aabb2.minMax($v2(1.0, 1.0), $v2(3.0, 3.0));

  final result = input..transform(rotation);
  final newCenterY = math.sqrt(8);

  relativeTest(result.min.x, -math.sqrt(2));
  relativeTest(result.min.y, newCenterY - math.sqrt(2));
  relativeTest(result.max.x, math.sqrt(2));
  relativeTest(result.max.y, newCenterY + math.sqrt(2));
  relativeTest(result.center.x, 0.0);
  relativeTest(result.center.y, newCenterY);
}

void main() {
  group('Aabb2', () {
    test('Center', testAabb2Center);
    test('centerAndHalfExtents', testAabb2CenterAndHalfExtents);
    test('copyCenterAndHalfExtents', testAabb2CopyCenterAndHalfExtents);
    test('setCenterAndHalfExtents', testAabb2SetCenterAndHalfExtents);
    test('Contains Aabb2', testAabb2ContainsAabb2);
    test('Contains Vector2', testAabb2ContainsVector2);
    test('Intersection Aabb2', testAabb2IntersectionAabb2);
    test('Intersection Vector2', testAabb2IntersectionVector2);
    test('Hull', testAabb2Hull);
    test('Hull Point', testAabb2HullPoint);
    test('Rotate', testAabb2Rotate);
    test('Transform', testAabb2Transform);
  });
}

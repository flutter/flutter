// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testAabb3ByteBufferInstanciation() {
  final buffer =
      Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]).buffer;
  final aabb = Aabb3.fromBuffer(buffer, 0);
  final aabbOffest = Aabb3.fromBuffer(buffer, Float32List.bytesPerElement);

  expect(aabb.min.x, equals(1.0));
  expect(aabb.min.y, equals(2.0));
  expect(aabb.min.z, equals(3.0));
  expect(aabb.max.x, equals(4.0));
  expect(aabb.max.y, equals(5.0));
  expect(aabb.max.z, equals(6.0));

  expect(aabbOffest.min.x, equals(2.0));
  expect(aabbOffest.min.y, equals(3.0));
  expect(aabbOffest.min.z, equals(4.0));
  expect(aabbOffest.max.x, equals(5.0));
  expect(aabbOffest.max.y, equals(6.0));
  expect(aabbOffest.max.z, equals(7.0));
}

void testAabb3Center() {
  final aabb = Aabb3.minMax($v3(1.0, 2.0, 4.0), $v3(8.0, 16.0, 32.0));
  final center = aabb.center;

  expect(center.x, equals(4.5));
  expect(center.y, equals(9.0));
  expect(center.z, equals(18.0));
}

void testAabb3CopyCenterAndHalfExtents() {
  final a1 = Aabb3.minMax($v3(10.0, 20.0, 30.0), $v3(20.0, 40.0, 60.0));
  final a2 = Aabb3.minMax($v3(-10.0, -20.0, -30.0), $v3(0.0, 0.0, 0.0));

  final center = Vector3.zero();
  final halfExtents = Vector3.zero();

  a1.copyCenterAndHalfExtents(center, halfExtents);

  relativeTest(center, $v3(15.0, 30.0, 45.0));
  relativeTest(halfExtents, $v3(5.0, 10.0, 15.0));

  a2.copyCenterAndHalfExtents(center, halfExtents);

  relativeTest(center, $v3(-5.0, -10.0, -15.0));
  relativeTest(halfExtents, $v3(5.0, 10.0, 15.0));
}

void testAabb3setCenterAndHalfExtents() {
  final a1 =
      Aabb3.centerAndHalfExtents($v3(0.0, 0.0, 0.0), $v3(10.0, 20.0, 30.0));
  final a2 = Aabb3.centerAndHalfExtents(
      $v3(-10.0, -20.0, -30.0), $v3(10.0, 20.0, 30.0));

  relativeTest(a1.min, $v3(-10.0, -20.0, -30.0));
  relativeTest(a1.max, $v3(10.0, 20.0, 30.0));

  relativeTest(a2.min, $v3(-20.0, -40.0, -60.0));
  relativeTest(a2.max, $v3(0.0, 0.0, 0.0));
}

void testAabb3setSphere() {
  final s = Sphere.centerRadius($v3(10.0, 20.0, 30.0), 10.0);
  final a = Aabb3.fromSphere(s);

  expect(a.intersectsWithVector3(a.center), isTrue);
  expect(a.intersectsWithVector3($v3(20.0, 20.0, 30.0)), isTrue);
}

void testAabb3setRay() {
  final r =
      Ray.originDirection($v3(1.0, 2.0, 3.0), $v3(1.0, 5.0, -1.0)..normalize());
  final a = Aabb3.fromRay(r, 0.0, 10.0);

  expect(a.intersectsWithVector3(r.at(0.0)), isTrue);
  expect(a.intersectsWithVector3(r.at(10.0)), isTrue);
}

void testAabb3setTriangle() {
  final t = Triangle.points(
      $v3(2.0, 0.0, 0.0), $v3(0.0, 2.0, 0.0), $v3(0.0, 0.0, 2.0));
  final a = Aabb3.fromTriangle(t);

  expect(a.intersectsWithVector3(t.point0), isTrue);
  expect(a.intersectsWithVector3(t.point1), isTrue);
  expect(a.intersectsWithVector3(t.point2), isTrue);
}

void testAabb3setQuad() {
  final q = Quad.points($v3(2.0, 0.0, 0.0), $v3(0.0, 2.0, 0.0),
      $v3(0.0, 0.0, 2.0), $v3(0.0, 0.0, -2.0));
  final a = Aabb3.fromQuad(q);

  expect(a.intersectsWithVector3(q.point0), isTrue);
  expect(a.intersectsWithVector3(q.point1), isTrue);
  expect(a.intersectsWithVector3(q.point2), isTrue);
  expect(a.intersectsWithVector3(q.point3), isTrue);
}

void testAabb3ContainsAabb3() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = Aabb3.minMax($v3(2.0, 2.0, 2.0), $v3(7.0, 7.0, 7.0));
  final cutting = Aabb3.minMax($v3(0.0, 0.0, 0.0), $v3(5.0, 5.0, 5.0));
  final outside = Aabb3.minMax($v3(10.0, 10.0, 10.0), $v3(20.0, 20.0, 20.0));
  final grandParent = Aabb3.minMax($v3(0.0, 0.0, 0.0), $v3(10.0, 10.0, 10.0));

  expect(parent.containsAabb3(child), isTrue);
  expect(parent.containsAabb3(parent), isFalse);
  expect(parent.containsAabb3(cutting), isFalse);
  expect(parent.containsAabb3(outside), isFalse);
  expect(parent.containsAabb3(grandParent), isFalse);
}

void testAabb3ContainsSphere() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = Sphere.centerRadius($v3(3.0, 3.0, 3.0), 1.5);
  final cutting = Sphere.centerRadius($v3(0.0, 0.0, 0.0), 6.0);
  final outside = Sphere.centerRadius($v3(-10.0, -10.0, -10.0), 5.0);

  expect(parent.containsSphere(child), isTrue);
  expect(parent.containsSphere(cutting), isFalse);
  expect(parent.containsSphere(outside), isFalse);
}

void testAabb3ContainsVector3() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = $v3(7.0, 7.0, 7.0);
  final cutting = $v3(1.0, 2.0, 1.0);
  final outside = $v3(-10.0, 10.0, 10.0);

  expect(parent.containsVector3(child), isTrue);
  expect(parent.containsVector3(cutting), isFalse);
  expect(parent.containsVector3(outside), isFalse);
}

void testAabb3ContainsTriangle() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = Triangle.points(
      $v3(2.0, 2.0, 2.0), $v3(3.0, 3.0, 3.0), $v3(4.0, 4.0, 4.0));
  final edge = Triangle.points(
      $v3(1.0, 1.0, 1.0), $v3(3.0, 3.0, 3.0), $v3(4.0, 4.0, 4.0));
  final cutting = Triangle.points(
      $v3(2.0, 2.0, 2.0), $v3(3.0, 3.0, 3.0), $v3(14.0, 14.0, 14.0));
  final outside = Triangle.points(
      $v3(0.0, 0.0, 0.0), $v3(-3.0, -3.0, -3.0), $v3(-4.0, -4.0, -4.0));

  expect(parent.containsTriangle(child), isTrue);
  expect(parent.containsTriangle(edge), isFalse);
  expect(parent.containsTriangle(cutting), isFalse);
  expect(parent.containsTriangle(outside), isFalse);
}

void testAabb3IntersectionAabb3() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = Aabb3.minMax($v3(2.0, 2.0, 2.0), $v3(7.0, 7.0, 7.0));
  final cutting = Aabb3.minMax($v3(0.0, 0.0, 0.0), $v3(5.0, 5.0, 5.0));
  final outside = Aabb3.minMax($v3(10.0, 10.0, 10.0), $v3(20.0, 20.0, 10.0));
  final grandParent = Aabb3.minMax($v3(0.0, 0.0, 0.0), $v3(10.0, 10.0, 10.0));

  final siblingOne = Aabb3.minMax($v3(0.0, 0.0, 0.0), $v3(3.0, 3.0, 3.0));
  final siblingTwo = Aabb3.minMax($v3(3.0, 0.0, 0.0), $v3(6.0, 3.0, 3.0));
  final siblingThree = Aabb3.minMax($v3(3.0, 3.0, 3.0), $v3(6.0, 6.0, 6.0));

  expect(parent.intersectsWithAabb3(child), isTrue);
  expect(child.intersectsWithAabb3(parent), isTrue);

  expect(parent.intersectsWithAabb3(parent), isTrue);

  expect(parent.intersectsWithAabb3(cutting), isTrue);
  expect(cutting.intersectsWithAabb3(parent), isTrue);

  expect(parent.intersectsWithAabb3(outside), isFalse);
  expect(outside.intersectsWithAabb3(parent), isFalse);

  expect(parent.intersectsWithAabb3(grandParent), isTrue);
  expect(grandParent.intersectsWithAabb3(parent), isTrue);

  expect(siblingOne.intersectsWithAabb3(siblingTwo), isTrue,
      reason: 'Touching edges are counted as intersection.');
  expect(siblingOne.intersectsWithAabb3(siblingThree), isTrue,
      reason: 'Touching corners are counted as intersection.');
}

void testAabb3IntersectionSphere() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = Sphere.centerRadius($v3(3.0, 3.0, 3.0), 1.5);
  final cutting = Sphere.centerRadius($v3(0.0, 0.0, 0.0), 6.0);
  final outside = Sphere.centerRadius($v3(-10.0, -10.0, -10.0), 5.0);

  expect(parent.intersectsWithSphere(child), isTrue);
  expect(parent.intersectsWithSphere(cutting), isTrue);
  expect(parent.intersectsWithSphere(outside), isFalse);
}

void testIntersectionTriangle() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = Triangle.points(
      $v3(2.0, 2.0, 2.0), $v3(3.0, 3.0, 3.0), $v3(4.0, 4.0, 4.0));
  final edge = Triangle.points(
      $v3(1.0, 1.0, 1.0), $v3(3.0, 3.0, 3.0), $v3(4.0, 4.0, 4.0));
  final cutting = Triangle.points(
      $v3(2.0, 2.0, 2.0), $v3(3.0, 3.0, 3.0), $v3(14.0, 14.0, 14.0));
  final outside = Triangle.points(
      $v3(0.0, 0.0, 0.0), $v3(-3.0, -3.0, -3.0), $v3(-4.0, -4.0, -4.0));

  expect(parent.intersectsWithTriangle(child), isTrue);
  expect(parent.intersectsWithTriangle(edge), isTrue);
  expect(parent.intersectsWithTriangle(cutting), isTrue);
  expect(parent.intersectsWithTriangle(outside), isFalse);

  // Special tests
  final testAabb = Aabb3.minMax(
      $v3(20.458911895751953, -36.607460021972656, 2.549999952316284),
      $v3(21.017810821533203, -36.192543029785156, 3.049999952316284));
  final testTriangle = Triangle.points(
      $v3(20.5, -36.5, 3.5), $v3(21.5, -36.5, 2.5), $v3(20.5, -36.5, 2.5));
  expect(testAabb.intersectsWithTriangle(testTriangle), isTrue);

  final aabb = Aabb3.minMax(
      $v3(19.07674217224121, -39.46818161010742, 2.299999952316284),
      $v3(19.40754508972168, -38.9503288269043, 2.799999952316284));
  final triangle4 = Triangle.points(
      $v3(18.5, -39.5, 2.5), $v3(19.5, -39.5, 2.5), $v3(19.5, -38.5, 2.5));
  final triangle4_1 = Triangle.points(
      $v3(19.5, -38.5, 2.5), $v3(19.5, -39.5, 2.5), $v3(18.5, -39.5, 2.5));
  final triangle4_2 = Triangle.points(
      $v3(18.5, -39.5, 2.5), $v3(19.5, -38.5, 2.5), $v3(18.5, -38.5, 2.5));
  final triangle4_3 = Triangle.points(
      $v3(18.5, -38.5, 2.5), $v3(19.5, -38.5, 2.5), $v3(18.5, -39.5, 2.5));

  expect(aabb.intersectsWithTriangle(triangle4), isTrue);
  expect(aabb.intersectsWithTriangle(triangle4_1), isTrue);
  expect(aabb.intersectsWithTriangle(triangle4_2), isFalse);
  expect(aabb.intersectsWithTriangle(triangle4_3), isFalse);
}

void testIntersectionPlane() {
  final plane = Plane.normalconstant($v3(1.0, 0.0, 0.0), 10.0);

  final left = Aabb3.minMax($v3(-5.0, -5.0, -5.0), $v3(5.0, 5.0, 5.0));
  final right = Aabb3.minMax($v3(15.0, 15.0, 15.0), $v3(30.0, 30.0, 30.0));
  final intersect = Aabb3.minMax($v3(5.0, 5.0, 5.0), $v3(15.0, 15.0, 15.0));

  expect(left.intersectsWithPlane(plane), isFalse);
  expect(right.intersectsWithPlane(plane), isFalse);

  final result = IntersectionResult();

  expect(intersect.intersectsWithPlane(plane, result: result), isTrue);

  relativeError(result.axis, $v3(1.0, 0.0, 0.0));
  expect(result.depth, equals(-5.0));
}

void testAabb3IntersectionVector3() {
  final parent = Aabb3.minMax($v3(1.0, 1.0, 1.0), $v3(8.0, 8.0, 8.0));
  final child = $v3(7.0, 7.0, 7.0);
  final cutting = $v3(1.0, 2.0, 1.0);
  final outside = $v3(-10.0, 10.0, 10.0);

  expect(parent.intersectsWithVector3(child), isTrue);
  expect(parent.intersectsWithVector3(cutting), isTrue);
  expect(parent.intersectsWithVector3(outside), isFalse);
}

void testAabb3Hull() {
  final a = Aabb3.minMax($v3(1.0, 1.0, 4.0), $v3(3.0, 4.0, 10.0));
  final b = Aabb3.minMax($v3(3.0, 2.0, 3.0), $v3(6.0, 2.0, 8.0));

  a.hull(b);

  expect(a.min.x, equals(1.0));
  expect(a.min.y, equals(1.0));
  expect(a.min.z, equals(3.0));
  expect(a.max.x, equals(6.0));
  expect(a.max.y, equals(4.0));
  expect(a.max.z, equals(10.0));
}

void testAabb3HullPoint() {
  final a = Aabb3.minMax($v3(1.0, 1.0, 4.0), $v3(3.0, 4.0, 10.0));
  final b = $v3(6.0, 2.0, 8.0);

  a.hullPoint(b);

  expect(a.min.x, equals(1.0));
  expect(a.min.y, equals(1.0));
  expect(a.min.z, equals(4.0));
  expect(a.max.x, equals(6.0));
  expect(a.max.y, equals(4.0));
  expect(a.max.z, equals(10.0));

  final c = $v3(6.0, 0.0, 2.0);

  a.hullPoint(c);

  expect(a.min.x, equals(1.0));
  expect(a.min.y, equals(0.0));
  expect(a.min.z, equals(2.0));
  expect(a.max.x, equals(6.0));
  expect(a.max.y, equals(4.0));
  expect(a.max.z, equals(10.0));
}

void main() {
  group('Aabb3', () {
    test('ByteBuffer instanciation', testAabb3ByteBufferInstanciation);
    test('Center', testAabb3Center);
    test('copyCenterAndHalfExtents', testAabb3CopyCenterAndHalfExtents);
    test('copyCenterAndHalfExtents', testAabb3setCenterAndHalfExtents);
    test('setSphere', testAabb3setSphere);
    test('setRay', testAabb3setRay);
    test('setTriangle', testAabb3setTriangle);
    test('setQuad', testAabb3setQuad);
    test('Contains Aabb3', testAabb3ContainsAabb3);
    test('Contains Vector3', testAabb3ContainsVector3);
    test('Contains Triangle', testAabb3ContainsTriangle);
    test('Contains Sphere', testAabb3ContainsSphere);
    test('Intersection Aabb3', testAabb3IntersectionAabb3);
    test('Intersection Vector3', testAabb3IntersectionVector3);
    test('Intersection Sphere', testAabb3IntersectionSphere);
    test('Intersection Triangle', testIntersectionTriangle);
    test('Intersection Plane', testIntersectionPlane);
    test('Hull', testAabb3Hull);
    test('Hull Point', testAabb3HullPoint);
  });
}

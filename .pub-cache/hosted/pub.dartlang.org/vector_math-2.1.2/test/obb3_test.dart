// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testCorners() {
  final a = Obb3()
    ..center.setValues(0.0, 0.0, 0.0)
    ..halfExtents.setValues(5.0, 5.0, 5.0);
  final corner = Vector3.zero();

  a.copyCorner(0, corner);
  absoluteTest(corner, Vector3(-5.0, -5.0, -5.0));

  a.copyCorner(1, corner);
  absoluteTest(corner, Vector3(-5.0, -5.0, 5.0));

  a.copyCorner(2, corner);
  absoluteTest(corner, Vector3(-5.0, 5.0, -5.0));

  a.copyCorner(3, corner);
  absoluteTest(corner, Vector3(-5.0, 5.0, 5.0));

  a.copyCorner(4, corner);
  absoluteTest(corner, Vector3(5.0, -5.0, -5.0));

  a.copyCorner(5, corner);
  absoluteTest(corner, Vector3(5.0, -5.0, 5.0));

  a.copyCorner(6, corner);
  absoluteTest(corner, Vector3(5.0, 5.0, -5.0));

  a.copyCorner(7, corner);
  absoluteTest(corner, Vector3(5.0, 5.0, 5.0));
}

void testTranslate() {
  final a = Obb3()
    ..center.setValues(0.0, 0.0, 0.0)
    ..halfExtents.setValues(5.0, 5.0, 5.0);
  final corner = Vector3.zero();

  a.translate(Vector3(-1.0, 2.0, 3.0));

  a.copyCorner(0, corner);
  absoluteTest(corner, Vector3(-5.0 - 1.0, -5.0 + 2.0, -5.0 + 3.0));

  a.copyCorner(1, corner);
  absoluteTest(corner, Vector3(-5.0 - 1.0, -5.0 + 2.0, 5.0 + 3.0));

  a.copyCorner(2, corner);
  absoluteTest(corner, Vector3(-5.0 - 1.0, 5.0 + 2.0, -5.0 + 3.0));

  a.copyCorner(3, corner);
  absoluteTest(corner, Vector3(-5.0 - 1.0, 5.0 + 2.0, 5.0 + 3.0));

  a.copyCorner(4, corner);
  absoluteTest(corner, Vector3(5.0 - 1.0, -5.0 + 2.0, -5.0 + 3.0));

  a.copyCorner(5, corner);
  absoluteTest(corner, Vector3(5.0 - 1.0, -5.0 + 2.0, 5.0 + 3.0));

  a.copyCorner(6, corner);
  absoluteTest(corner, Vector3(5.0 - 1.0, 5.0 + 2.0, -5.0 + 3.0));

  a.copyCorner(7, corner);
  absoluteTest(corner, Vector3(5.0 - 1.0, 5.0 + 2.0, 5.0 + 3.0));
}

void testRotate() {
  final a = Obb3()
    ..center.setValues(0.0, 0.0, 0.0)
    ..halfExtents.setValues(5.0, 5.0, 5.0);
  final corner = Vector3.zero();
  final matrix = Matrix3.rotationY(radians(45.0));

  a.rotate(matrix);

  a.copyCorner(0, corner);
  absoluteTest(corner, Vector3(0.0, -5.0, -7.071067810058594));

  a.copyCorner(1, corner);
  absoluteTest(corner, Vector3(-7.071067810058594, -5.0, 0.0));

  a.copyCorner(2, corner);
  absoluteTest(corner, Vector3(0.0, 5.0, -7.071067810058594));

  a.copyCorner(3, corner);
  absoluteTest(corner, Vector3(-7.071067810058594, 5.0, 0.0));

  a.copyCorner(4, corner);
  absoluteTest(corner, Vector3(7.071067810058594, -5.0, 0.0));

  a.copyCorner(5, corner);
  absoluteTest(corner, Vector3(0.0, -5.0, 7.071067810058594));

  a.copyCorner(6, corner);
  absoluteTest(corner, Vector3(7.071067810058594, 5.0, 0.0));

  a.copyCorner(7, corner);
  absoluteTest(corner, Vector3(0.0, 5.0, 7.071067810058594));
}

void testTransform() {
  final a = Obb3()
    ..center.setValues(0.0, 0.0, 0.0)
    ..halfExtents.setValues(5.0, 5.0, 5.0);
  final corner = Vector3.zero();
  final matrix = Matrix4.diagonal3Values(3.0, 3.0, 3.0);

  a.transform(matrix);

  a.copyCorner(0, corner);
  absoluteTest(corner, Vector3(-15.0, -15.0, -15.0));

  a.copyCorner(1, corner);
  absoluteTest(corner, Vector3(-15.0, -15.0, 15.0));

  a.copyCorner(2, corner);
  absoluteTest(corner, Vector3(-15.0, 15.0, -15.0));

  a.copyCorner(3, corner);
  absoluteTest(corner, Vector3(-15.0, 15.0, 15.0));

  a.copyCorner(4, corner);
  absoluteTest(corner, Vector3(15.0, -15.0, -15.0));

  a.copyCorner(5, corner);
  absoluteTest(corner, Vector3(15.0, -15.0, 15.0));

  a.copyCorner(6, corner);
  absoluteTest(corner, Vector3(15.0, 15.0, -15.0));

  a.copyCorner(7, corner);
  absoluteTest(corner, Vector3(15.0, 15.0, 15.0));
}

void testClosestPointTo() {
  final a = Obb3()
    ..center.setValues(0.0, 0.0, 0.0)
    ..halfExtents.setValues(2.0, 2.0, 2.0);
  final b = Vector3(3.0, 3.0, 3.0);
  final c = Vector3(3.0, 3.0, -3.0);
  final closestPoint = Vector3.zero();

  a.closestPointTo(b, closestPoint);

  absoluteTest(closestPoint, Vector3(2.0, 2.0, 2.0));

  a.closestPointTo(c, closestPoint);

  absoluteTest(closestPoint, Vector3(2.0, 2.0, -2.0));

  a.rotate(Matrix3.rotationZ(radians(45.0)));

  a.closestPointTo(b, closestPoint);

  absoluteTest(closestPoint, Vector3(math.sqrt2, math.sqrt2, 2.0));

  a.closestPointTo(c, closestPoint);

  absoluteTest(closestPoint, Vector3(math.sqrt2, math.sqrt2, -2.0));
}

void testIntersectionObb3() {
  final a = Obb3()
    ..center.setValues(0.0, 0.0, 0.0)
    ..halfExtents.setValues(2.0, 2.0, 2.0);

  final b = Obb3()
    ..center.setValues(3.0, 0.0, 0.0)
    ..halfExtents.setValues(0.5, 0.5, 0.5);

  final c = Obb3()
    ..center.setValues(0.0, 3.0, 0.0)
    ..halfExtents.setValues(0.5, 0.5, 0.5);

  final d = Obb3()
    ..center.setValues(0.0, 0.0, 3.0)
    ..halfExtents.setValues(0.5, 0.5, 0.5);

  final e = Obb3()
    ..center.setValues(-3.0, 0.0, 0.0)
    ..halfExtents.setValues(0.5, 0.5, 0.5);

  final f = Obb3()
    ..center.setValues(0.0, -3.0, 0.0)
    ..halfExtents.setValues(0.5, 0.5, 0.5);

  final g = Obb3()
    ..center.setValues(0.0, 0.0, -3.0)
    ..halfExtents.setValues(0.5, 0.5, 0.5);

  final u = Obb3()
    ..center.setValues(1.0, 1.0, 1.0)
    ..halfExtents.setValues(0.5, 0.5, 0.5);

  final v = Obb3()
    ..center.setValues(10.0, 10.0, -10.0)
    ..halfExtents.setValues(2.0, 2.0, 2.0);

  final w = Obb3()
    ..center.setValues(10.0, 0.0, 0.0)
    ..halfExtents.setValues(1.0, 1.0, 1.0);

  // a - b
  expect(a.intersectsWithObb3(b), isFalse);

  b.halfExtents.scale(2.0);

  expect(a.intersectsWithObb3(b), isTrue);

  b.rotate(Matrix3.rotationZ(radians(45.0)));

  expect(a.intersectsWithObb3(b), isTrue);

  // a - c
  expect(a.intersectsWithObb3(c), isFalse);

  c.halfExtents.scale(2.0);

  expect(a.intersectsWithObb3(c), isTrue);

  c.rotate(Matrix3.rotationZ(radians(45.0)));

  expect(a.intersectsWithObb3(c), isTrue);

  // a - d
  expect(a.intersectsWithObb3(d), isFalse);

  d.halfExtents.scale(2.0);

  expect(a.intersectsWithObb3(d), isTrue);

  d.rotate(Matrix3.rotationZ(radians(45.0)));

  expect(a.intersectsWithObb3(d), isTrue);

  // a - e
  expect(a.intersectsWithObb3(e), isFalse);

  e.halfExtents.scale(2.0);

  expect(a.intersectsWithObb3(e), isTrue);

  e.rotate(Matrix3.rotationZ(radians(45.0)));

  expect(a.intersectsWithObb3(e), isTrue);

  // a - f
  expect(a.intersectsWithObb3(f), isFalse);

  f.halfExtents.scale(2.0);

  expect(a.intersectsWithObb3(f), isTrue);

  f.rotate(Matrix3.rotationZ(radians(45.0)));

  expect(a.intersectsWithObb3(f), isTrue);

  // a - g
  expect(a.intersectsWithObb3(g), isFalse);

  g.halfExtents.scale(2.0);

  expect(a.intersectsWithObb3(g), isTrue);

  g.rotate(Matrix3.rotationZ(radians(45.0)));

  expect(a.intersectsWithObb3(g), isTrue);

  // u
  expect(a.intersectsWithObb3(u), isTrue);

  expect(b.intersectsWithObb3(u), isFalse);

  u.halfExtents.scale(10.0);

  expect(b.intersectsWithObb3(u), isTrue);

  // v
  expect(a.intersectsWithObb3(v), isFalse);

  expect(b.intersectsWithObb3(v), isFalse);

  // w
  expect(a.intersectsWithObb3(w), isFalse);

  w.rotate(Matrix3.rotationZ(radians(22.0)));

  expect(a.intersectsWithObb3(w), isFalse);

  expect(b.intersectsWithObb3(w), isFalse);
}

void testIntersectionVector3() {
  //final parent = new Aabb3.minMax(_v(1.0,1.0,1.0), _v(8.0,8.0,8.0));
  final parent = Obb3()
    ..center.setValues(4.5, 4.5, 4.5)
    ..halfExtents.setValues(3.5, 3.5, 3.5);
  final child = $v3(7.0, 7.0, 7.0);
  final cutting = $v3(1.0, 2.0, 1.0);
  final outside1 = $v3(-10.0, 10.0, 10.0);
  final outside2 = $v3(4.5, 4.5, 9.0);

  expect(parent.intersectsWithVector3(child), isTrue);
  expect(parent.intersectsWithVector3(cutting), isTrue);
  expect(parent.intersectsWithVector3(outside1), isFalse);
  expect(parent.intersectsWithVector3(outside2), isFalse);

  final rotationX = Matrix3.rotationX(radians(45.0));
  parent.rotate(rotationX);

  expect(parent.intersectsWithVector3(child), isFalse);
  expect(parent.intersectsWithVector3(cutting), isFalse);
  expect(parent.intersectsWithVector3(outside1), isFalse);
  expect(parent.intersectsWithVector3(outside2), isTrue);
}

void testIntersectionTriangle() {
  final parent = Obb3();
  parent.center.setValues(4.5, 4.5, 4.5);
  parent.halfExtents.setValues(3.5, 3.5, 3.5);
  final child = Triangle.points(
      $v3(2.0, 2.0, 2.0), $v3(3.0, 3.0, 3.0), $v3(4.0, 4.0, 4.0));
  final edge = Triangle.points(
      $v3(1.0, 1.0, 1.0), $v3(3.0, 3.0, 3.0), $v3(4.0, 4.0, 4.0));
  final cutting = Triangle.points(
      $v3(2.0, 2.0, 2.0), $v3(3.0, 3.0, 3.0), $v3(14.0, 14.0, 14.0));
  final outside = Triangle.points(
      $v3(0.0, 0.0, 0.0), $v3(-3.0, -3.0, -3.0), $v3(-4.0, -4.0, -4.0));
  final parallel0 = Triangle.points(
      $v3(1.0, 0.0, 1.0), $v3(1.0, 10.0, 1.0), $v3(1.0, 0.0, 10.0));
  final parallel1 = Triangle.points(
      $v3(1.0, 4.5, 0.0), $v3(1.0, -1.0, 9.0), $v3(1.0, 10.0, 9.0));
  final parallel2 = Triangle.points(
      $v3(1.0, 10.0, 9.0), $v3(1.0, -1.0, 9.0), $v3(1.0, 4.5, 0.0));

  expect(parent.intersectsWithTriangle(child), isTrue);
  expect(parent.intersectsWithTriangle(edge), isTrue);
  expect(parent.intersectsWithTriangle(cutting), isTrue);
  expect(parent.intersectsWithTriangle(outside), isFalse);
  expect(parent.intersectsWithTriangle(parallel0), isTrue);
  expect(parent.intersectsWithTriangle(parallel1), isTrue);
  expect(parent.intersectsWithTriangle(parallel2), isTrue);

  final rotationX = Matrix3.rotationX(radians(0.01));
  parent.rotate(rotationX);

  expect(parent.intersectsWithTriangle(child), isTrue);
  expect(parent.intersectsWithTriangle(edge), isTrue);
  expect(parent.intersectsWithTriangle(cutting), isTrue);
  expect(parent.intersectsWithTriangle(outside), isFalse);
  expect(parent.intersectsWithTriangle(parallel0), isTrue);
  expect(parent.intersectsWithTriangle(parallel1), isTrue);
  expect(parent.intersectsWithTriangle(parallel2), isTrue);

  final rotationY = Matrix3.rotationY(radians(45.0));
  parent.rotate(rotationY);

  expect(parent.intersectsWithTriangle(child), isTrue);
  expect(parent.intersectsWithTriangle(edge), isTrue);
  expect(parent.intersectsWithTriangle(cutting), isTrue);
  expect(parent.intersectsWithTriangle(outside), isFalse);
  expect(parent.intersectsWithTriangle(parallel0), isTrue);
  expect(parent.intersectsWithTriangle(parallel1), isTrue);
  expect(parent.intersectsWithTriangle(parallel2), isTrue);

  final rotationZ = Matrix3.rotationZ(radians(45.0));
  parent.rotate(rotationZ);

  expect(parent.intersectsWithTriangle(child), isTrue);
  expect(parent.intersectsWithTriangle(edge), isTrue);
  expect(parent.intersectsWithTriangle(cutting), isTrue);
  expect(parent.intersectsWithTriangle(outside), isFalse);
  expect(parent.intersectsWithTriangle(parallel0), isTrue);
  expect(parent.intersectsWithTriangle(parallel1), isTrue);
  expect(parent.intersectsWithTriangle(parallel2), isTrue);

  final obb = Obb3.centerExtentsAxes(
      $v3(21.0, -36.400001525878906, 2.799999952316284),
      $v3(0.25, 0.15000000596046448, 0.25),
      $v3(0.0, 1.0, 0.0),
      $v3(-1.0, 0.0, 0.0),
      $v3(0.0, 0.0, 1.0));
  final triangle = Triangle.points(
      $v3(20.5, -36.5, 3.5), $v3(21.5, -36.5, 2.5), $v3(20.5, -36.5, 2.5));

  expect(obb.intersectsWithTriangle(triangle), isTrue);

  final obb2 = Obb3.centerExtentsAxes(
      $v3(25.15829086303711, -36.27009201049805, 3.0299079418182373),
      $v3(0.25, 0.15000000596046448, 0.25),
      $v3(-0.7071067690849304, 0.7071067690849304, 0.0),
      $v3(-0.7071067690849304, -0.7071067690849304, 0.0),
      $v3(0.0, 0.0, 1.0));
  final triangle2 = Triangle.points(
      $v3(25.5, -36.5, 2.5), $v3(25.5, -35.5, 3.5), $v3(24.5, -36.5, 2.5));
  final triangle2_1 = Triangle.points($v3(24.5, -36.5, 2.5),
      $v3(25.5, -35.5, 3.5), $v3(25.5, -36.5, 2.5)); // reverse normal direction

  expect(obb2.intersectsWithTriangle(triangle2), isTrue);
  expect(obb2.intersectsWithTriangle(triangle2_1), isTrue);

  final obb3 = Obb3.centerExtentsAxes(
      $v3(20.937196731567383, -37.599998474121094, 2.799999952316284),
      $v3(0.25, 0.15000000596046448, 0.25),
      $v3(0.0, -1.0, 0.0),
      $v3(1.0, 0.0, 0.0),
      $v3(0.0, 0.0, 1.0));
  final triangle3 = Triangle.points(
      $v3(20.5, -37.5, 3.5), $v3(20.5, -37.5, 2.5), $v3(21.5, -37.5, 2.5));
  final triangle3_1 = Triangle.points($v3(21.5, -37.5, 2.5),
      $v3(20.5, -37.5, 2.5), $v3(20.5, -37.5, 3.5)); // reverse normal direction

  expect(obb3.intersectsWithTriangle(triangle3), isTrue);
  expect(obb3.intersectsWithTriangle(triangle3_1), isTrue);

  final obb4 = Obb3.centerExtentsAxes(
      $v3(19.242143630981445, -39.20925521850586, 2.549999952316284),
      $v3(0.25, 0.15000000596046448, 0.25),
      $v3(0.0, 1.0, 0.0),
      $v3(-1.0, 0.0, 0.0),
      $v3(0.0, 0.0, 1.0));
  final triangle4 = Triangle.points(
      $v3(18.5, -39.5, 2.5), $v3(19.5, -39.5, 2.5), $v3(19.5, -38.5, 2.5));
  final triangle4_1 = Triangle.points($v3(19.5, -38.5, 2.5),
      $v3(19.5, -39.5, 2.5), $v3(18.5, -39.5, 2.5)); // reverse normal direction
  final triangle4_2 = Triangle.points(
      $v3(18.5, -39.5, 2.5), $v3(19.5, -38.5, 2.5), $v3(18.5, -38.5, 2.5));
  final triangle4_3 = Triangle.points($v3(18.5, -38.5, 2.5),
      $v3(19.5, -38.5, 2.5), $v3(18.5, -39.5, 2.5)); // reverse normal direction

  expect(obb4.intersectsWithTriangle(triangle4), isTrue);
  expect(obb4.intersectsWithTriangle(triangle4_1), isTrue);
  expect(obb4.intersectsWithTriangle(triangle4_2), isFalse);
  expect(obb4.intersectsWithTriangle(triangle4_3), isFalse);
}

void main() {
  group('Obb3', () {
    test('Corners', testCorners);
    test('Translate', testTranslate);
    test('Rotate', testRotate);
    test('Transforn', testTransform);
    test('Closest Point To', testClosestPointTo);
    test('Intersection Obb3', testIntersectionObb3);
    test('Intersection Triangle', testIntersectionTriangle);
    test('Intersection Vector3', testIntersectionVector3);
  });
}

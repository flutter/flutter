// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testVector4InstacinfFromFloat32List() {
  final float32List = Float32List.fromList([1.0, 2.0, 3.0, 4.0]);
  final input = Vector4.fromFloat32List(float32List);

  expect(input.x, equals(1.0));
  expect(input.y, equals(2.0));
  expect(input.z, equals(3.0));
  expect(input.w, equals(4.0));
}

void testVector4InstacingFromByteBuffer() {
  final float32List = Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0]);
  final buffer = float32List.buffer;
  final zeroOffset = Vector4.fromBuffer(buffer, 0);
  final offsetVector = Vector4.fromBuffer(buffer, Float32List.bytesPerElement);

  expect(zeroOffset.x, equals(1.0));
  expect(zeroOffset.y, equals(2.0));
  expect(zeroOffset.z, equals(3.0));
  expect(zeroOffset.w, equals(4.0));

  expect(offsetVector.x, equals(2.0));
  expect(offsetVector.y, equals(3.0));
  expect(offsetVector.z, equals(4.0));
  expect(offsetVector.w, equals(5.0));
}

void testVector4Add() {
  final a = Vector4(5.0, 7.0, 3.0, 10.0);
  final b = Vector4(3.0, 8.0, 2.0, 2.0);

  a.add(b);
  expect(a.x, equals(8.0));
  expect(a.y, equals(15.0));
  expect(a.z, equals(5.0));
  expect(a.w, equals(12.0));

  b.addScaled(a, 0.5);
  expect(b.x, equals(7.0));
  expect(b.y, equals(15.5));
  expect(b.z, equals(4.5));
  expect(b.w, equals(8.0));
}

void testVector4MinMax() {
  final a = Vector4(5.0, 7.0, -3.0, 10.0);
  final b = Vector4(3.0, 8.0, 2.0, 2.0);

  final result = Vector4.zero();

  Vector4.min(a, b, result);
  expect(result.x, equals(3.0));
  expect(result.y, equals(7.0));
  expect(result.z, equals(-3.0));
  expect(result.w, equals(2.0));

  Vector4.max(a, b, result);
  expect(result.x, equals(5.0));
  expect(result.y, equals(8.0));
  expect(result.z, equals(2.0));
  expect(result.w, equals(10.0));
}

void testVector4Mix() {
  final a = Vector4(5.0, 7.0, 3.0, 10.0);
  final b = Vector4(3.0, 8.0, 2.0, 2.0);

  final result = Vector4.zero();

  Vector4.mix(a, b, 0.5, result);
  expect(result.x, equals(4.0));
  expect(result.y, equals(7.5));
  expect(result.z, equals(2.5));
  expect(result.w, equals(6.0));

  Vector4.mix(a, b, 0.0, result);
  expect(result.x, equals(5.0));
  expect(result.y, equals(7.0));
  expect(result.z, equals(3.0));
  expect(result.w, equals(10.0));

  Vector4.mix(a, b, 1.0, result);
  expect(result.x, equals(3.0));
  expect(result.y, equals(8.0));
  expect(result.z, equals(2.0));
  expect(result.w, equals(2.0));
}

void testVector4Constructor() {
  final v1 = Vector4(2.0, 4.0, -1.5, 10.0);
  expect(v1.x, equals(2.0));
  expect(v1.y, equals(4.0));
  expect(v1.z, equals(-1.5));
  expect(v1.w, equals(10.0));

  final v2 = Vector4.all(2.0);
  expect(v2.x, equals(2.0));
  expect(v2.y, equals(2.0));
  expect(v2.z, equals(2.0));
  expect(v2.w, equals(2.0));

  final v3 = Vector4.random(math.Random());
  expect(v3.x, greaterThanOrEqualTo(0.0));
  expect(v3.x, lessThanOrEqualTo(1.0));
  expect(v3.y, greaterThanOrEqualTo(0.0));
  expect(v3.y, lessThanOrEqualTo(1.0));
  expect(v3.z, greaterThanOrEqualTo(0.0));
  expect(v3.z, lessThanOrEqualTo(1.0));
  expect(v3.w, greaterThanOrEqualTo(0.0));
  expect(v3.w, lessThanOrEqualTo(1.0));
}

void testVector4Length() {
  final a = Vector4(5.0, 7.0, 3.0, 10.0);

  relativeTest(a.length, 13.5277);
  relativeTest(a.length2, 183.0);

  relativeTest(a.normalize(), 13.5277);
  relativeTest(a.x, 0.3696);
  relativeTest(a.y, 0.5174);
  relativeTest(a.z, 0.2217);
  relativeTest(a.w, 0.7392);
}

void testVector4SetLength() {
  final v0 = Vector4(1.0, 2.0, 1.0, 1.0);
  final v1 = Vector4(3.0, -2.0, 2.0, 1.0);
  final v2 = Vector4(-1.0, 2.0, -2.0, -3.0);
  final v3 = Vector4(1.0, 0.0, 0.0, 0.0);

  v0.length = 0.0;
  relativeTest(v0, Vector4.zero());
  relativeTest(v0.length, 0.0);

  v1.length = 2.0;
  relativeTest(
      v1,
      Vector4(1.4142135381698608, -0.9428090453147888, 0.9428090453147888,
          0.4714045226573944));
  relativeTest(v1.length, 2.0);

  v2.length = 0.5;
  relativeTest(
      v2,
      Vector4(-0.1178511306643486, 0.2357022613286972, -0.2357022613286972,
          -0.3535533845424652));
  relativeTest(v2.length, 0.5);

  v3.length = -1.0;
  relativeTest(v3, Vector4(-1.0, 0.0, 0.0, 0.0));
  relativeTest(v3.length, 1.0);
}

void testVector4Negate() {
  final vec3 = Vector4(1.0, 2.0, 3.0, 4.0);
  vec3.negate();
  expect(vec3.x, equals(-1.0));
  expect(vec3.y, equals(-2.0));
  expect(vec3.z, equals(-3.0));
  expect(vec3.w, equals(-4.0));
}

void testVector4Equals() {
  final v4 = Vector4(1.0, 2.0, 3.0, 4.0);
  expect(v4 == Vector4(1.0, 2.0, 3.0, 4.0), isTrue);
  expect(v4 == Vector4(0.0, 2.0, 3.0, 4.0), isFalse);
  expect(v4 == Vector4(1.0, 0.0, 3.0, 4.0), isFalse);
  expect(v4 == Vector4(1.0, 2.0, 0.0, 4.0), isFalse);
  expect(v4 == Vector4(1.0, 2.0, 3.0, 0.0), isFalse);
  expect(Vector4(1.0, 2.0, 3.0, 4.0).hashCode,
      equals(Vector4(1.0, 2.0, 3.0, 4.0).hashCode));
}

void testVector4DistanceTo() {
  final a = Vector4(1.0, 1.0, 1.0, 0.0);
  final b = Vector4(1.0, 3.0, 1.0, 0.0);
  final c = Vector4(1.0, 1.0, -1.0, 0.0);

  expect(a.distanceTo(b), equals(2.0));
  expect(a.distanceTo(c), equals(2.0));
}

void testVector4DistanceToSquared() {
  final a = Vector4(1.0, 1.0, 1.0, 0.0);
  final b = Vector4(1.0, 3.0, 1.0, 0.0);
  final c = Vector4(1.0, 1.0, -1.0, 0.0);

  expect(a.distanceToSquared(b), equals(4.0));
  expect(a.distanceToSquared(c), equals(4.0));
}

void testVector4Clamp() {
  final x = 2.0, y = 3.0, z = 4.0, w = 5.0;
  final v0 = Vector4(x, y, z, w);
  final v1 = Vector4(-x, -y, -z, -w);
  final v2 = Vector4(-2.0 * x, 2.0 * y, -2.0 * z, 2.0 * w)..clamp(v1, v0);

  expect(v2.storage, orderedEquals(<double>[-x, y, -z, w]));
}

void testVector4ClampScalar() {
  final x = 2.0;
  final v0 = Vector4(-2.0 * x, 2.0 * x, -2.0 * x, 2.0 * x)..clampScalar(-x, x);

  expect(v0.storage, orderedEquals(<double>[-x, x, -x, x]));
}

void testVector4Floor() {
  final v0 = Vector4(-0.1, 0.1, -0.1, 0.1)..floor();
  final v1 = Vector4(-0.5, 0.5, -0.5, 0.5)..floor();
  final v2 = Vector4(-0.9, 0.9, -0.5, 0.9)..floor();

  expect(v0.storage, orderedEquals(<double>[-1.0, 0.0, -1.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[-1.0, 0.0, -1.0, 0.0]));
  expect(v2.storage, orderedEquals(<double>[-1.0, 0.0, -1.0, 0.0]));
}

void testVector4Ceil() {
  final v0 = Vector4(-0.1, 0.1, -0.1, 0.1)..ceil();
  final v1 = Vector4(-0.5, 0.5, -0.5, 0.5)..ceil();
  final v2 = Vector4(-0.9, 0.9, -0.9, 0.9)..ceil();

  expect(v0.storage, orderedEquals(<double>[0.0, 1.0, 0.0, 1.0]));
  expect(v1.storage, orderedEquals(<double>[0.0, 1.0, 0.0, 1.0]));
  expect(v2.storage, orderedEquals(<double>[0.0, 1.0, 0.0, 1.0]));
}

void testVector4Round() {
  final v0 = Vector4(-0.1, 0.1, -0.1, 0.1)..round();
  final v1 = Vector4(-0.5, 0.5, -0.5, 0.5)..round();
  final v2 = Vector4(-0.9, 0.9, -0.9, 0.9)..round();

  expect(v0.storage, orderedEquals(<double>[0.0, 0.0, 0.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[-1.0, 1.0, -1.0, 1.0]));
  expect(v2.storage, orderedEquals(<double>[-1.0, 1.0, -1.0, 1.0]));
}

void testVector4RoundToZero() {
  final v0 = Vector4(-0.1, 0.1, -0.1, 0.1)..roundToZero();
  final v1 = Vector4(-0.5, 0.5, -0.5, 0.5)..roundToZero();
  final v2 = Vector4(-0.9, 0.9, -0.9, 0.9)..roundToZero();
  final v3 = Vector4(-1.1, 1.1, -1.1, 1.1)..roundToZero();
  final v4 = Vector4(-1.5, 1.5, -1.5, 1.5)..roundToZero();
  final v5 = Vector4(-1.9, 1.9, -1.9, 1.9)..roundToZero();

  expect(v0.storage, orderedEquals(<double>[0.0, 0.0, 0.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[0.0, 0.0, 0.0, 0.0]));
  expect(v2.storage, orderedEquals(<double>[0.0, 0.0, 0.0, 0.0]));
  expect(v3.storage, orderedEquals(<double>[-1.0, 1.0, -1.0, 1.0]));
  expect(v4.storage, orderedEquals(<double>[-1.0, 1.0, -1.0, 1.0]));
  expect(v5.storage, orderedEquals(<double>[-1.0, 1.0, -1.0, 1.0]));
}

void main() {
  group('Vector4', () {
    test('length', testVector4Length);
    test('equals', testVector4Equals);
    test('set length', testVector4SetLength);
    test('Negate', testVector4Negate);
    test('Constructor', testVector4Constructor);
    test('add', testVector4Add);
    test('min/max', testVector4MinMax);
    test('mix', testVector4Mix);
    test('distanceTo', testVector4DistanceTo);
    test('distanceToSquared', testVector4DistanceToSquared);
    test('instancing from Float32List', testVector4InstacinfFromFloat32List);
    test('instancing from ByteBuffer', testVector4InstacingFromByteBuffer);
    test('clamp', testVector4Clamp);
    test('clampScalar', testVector4ClampScalar);
    test('floor', testVector4Floor);
    test('ceil', testVector4Ceil);
    test('round', testVector4Round);
    test('roundToZero', testVector4RoundToZero);
  });
}

// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testVector2InstacinfFromFloat32List() {
  final float32List = Float32List.fromList([1.0, 2.0]);
  final input = Vector2.fromFloat32List(float32List);

  expect(input.x, equals(1.0));
  expect(input.y, equals(2.0));
}

void testVector2InstacingFromByteBuffer() {
  final float32List = Float32List.fromList([1.0, 2.0, 3.0, 4.0]);
  final buffer = float32List.buffer;
  final zeroOffset = Vector2.fromBuffer(buffer, 0);
  final offsetVector = Vector2.fromBuffer(buffer, Float32List.bytesPerElement);

  expect(zeroOffset.x, equals(1.0));
  expect(zeroOffset.y, equals(2.0));

  expect(offsetVector.x, equals(2.0));
  expect(offsetVector.y, equals(3.0));
}

void testVector2Add() {
  final a = Vector2(5.0, 7.0);
  final b = Vector2(3.0, 8.0);

  a.add(b);
  expect(a.x, equals(8.0));
  expect(a.y, equals(15.0));

  b.addScaled(a, 0.5);
  expect(b.x, equals(7.0));
  expect(b.y, equals(15.5));
}

void testVector2MinMax() {
  final a = Vector2(5.0, 7.0);
  final b = Vector2(3.0, 8.0);

  final result = Vector2.zero();

  Vector2.min(a, b, result);
  expect(result.x, equals(3.0));
  expect(result.y, equals(7.0));

  Vector2.max(a, b, result);
  expect(result.x, equals(5.0));
  expect(result.y, equals(8.0));
}

void testVector2Mix() {
  final a = Vector2(5.0, 7.0);
  final b = Vector2(3.0, 8.0);

  final result = Vector2.zero();

  Vector2.mix(a, b, 0.5, result);
  expect(result.x, equals(4.0));
  expect(result.y, equals(7.5));

  Vector2.mix(a, b, 0.0, result);
  expect(result.x, equals(5.0));
  expect(result.y, equals(7.0));

  Vector2.mix(a, b, 1.0, result);
  expect(result.x, equals(3.0));
  expect(result.y, equals(8.0));
}

void testVector2DotProduct() {
  final inputA = Vector2(0.417267069084370, 0.049654430325742);
  final inputB = Vector2(0.944787189721646, 0.490864092468080);
  final expectedOutput = 0.418602158442475;
  relativeTest(dot2(inputA, inputB), expectedOutput);
  relativeTest(dot2(inputB, inputA), expectedOutput);
}

void testVector2Postmultiplication() {
  final inputMatrix = Matrix2.rotation(.2);
  final inputVector = Vector2(1.0, 0.0);
  final inputInv = Matrix2.copy(inputMatrix);
  inputInv.invert();
  // print("input $inputMatrix");
  // print("input $inputInv");
  final resultOld = inputMatrix.transposed() * inputVector as Vector2;
  final resultOldvInv = inputInv * inputVector as Vector2;
  final resultNew = inputVector..postmultiply(inputMatrix);
  expect(resultNew.x, equals(resultOld.x));
  expect(resultNew.y, equals(resultOld.y));
  //matrix inversion can introduce a small error
  assert((resultNew - resultOldvInv).length < .00001);
}

void testVector2CrossProduct() {
  final inputA = Vector2(0.417267069084370, 0.049654430325742);
  final inputB = Vector2(0.944787189721646, 0.490864092468080);
  final expectedOutputCross = inputA.x * inputB.y - inputA.y * inputB.x;
  dynamic result;
  result = cross2(inputA, inputB);
  relativeTest(result, expectedOutputCross);
  result = Vector2.zero();
  cross2A(1.0, inputA, result as Vector2);
  relativeTest(result, Vector2(-inputA.y, inputA.x));
  cross2B(inputA, 1.0, result);
  relativeTest(result, Vector2(inputA.y, -inputA.x));
  cross2B(inputA, 1.0, result);
  relativeTest(result, Vector2(inputA.y, -inputA.x));
}

void testVector2OrthogonalScale() {
  final input = Vector2(0.5, 0.75);
  final output = Vector2.zero();

  input.scaleOrthogonalInto(2.0, output);
  expect(output.x, equals(-1.5));
  expect(output.y, equals(1.0));

  input.scaleOrthogonalInto(-2.0, output);
  expect(output.x, equals(1.5));
  expect(output.y, equals(-1.0));

  expect(0.0, equals(input.dot(output)));
}

void testVector2Constructor() {
  final v1 = Vector2(2.0, 4.0);
  expect(v1.x, equals(2.0));
  expect(v1.y, equals(4.0));

  final v2 = Vector2.all(2.0);
  expect(v2.x, equals(2.0));
  expect(v2.y, equals(2.0));

  final v3 = Vector2.random(math.Random());
  expect(v3.x, greaterThanOrEqualTo(0.0));
  expect(v3.x, lessThanOrEqualTo(1.0));
  expect(v3.y, greaterThanOrEqualTo(0.0));
  expect(v3.y, lessThanOrEqualTo(1.0));
}

void testVector2Length() {
  final a = Vector2(5.0, 7.0);

  relativeTest(a.length, 8.6);
  relativeTest(a.length2, 74.0);

  relativeTest(a.normalize(), 8.6);
  relativeTest(a.x, 0.5812);
  relativeTest(a.y, 0.8137);
}

void testVector2SetLength() {
  final v0 = Vector2(1.0, 2.0);
  final v1 = Vector2(3.0, -2.0);
  final v2 = Vector2(-1.0, 2.0);
  final v3 = Vector2(1.0, 0.0);

  v0.length = 0.0;
  relativeTest(v0, Vector2.zero());
  relativeTest(v0.length, 0.0);

  v1.length = 2.0;
  relativeTest(v1, Vector2(1.6641006469726562, -1.1094003915786743));
  relativeTest(v1.length, 2.0);

  v2.length = 0.5;
  relativeTest(v2, Vector2(-0.22360679507255554, 0.4472135901451111));
  relativeTest(v2.length, 0.5);

  v3.length = -1.0;
  relativeTest(v3, Vector2(-1.0, 0.0));
  relativeTest(v3.length, 1.0);
}

void testVector2Negate() {
  final vec1 = Vector2(1.0, 2.0);
  vec1.negate();
  expect(vec1.x, equals(-1.0));
  expect(vec1.y, equals(-2.0));
}

void testVector2Equals() {
  final v2 = Vector2(1.0, 2.0);
  expect(v2 == Vector2(1.0, 2.0), isTrue);
  expect(v2 == Vector2(1.0, 0.0), isFalse);
  expect(v2 == Vector2(0.0, 2.0), isFalse);
  expect(Vector2(1.0, 2.0).hashCode, equals(Vector2(1.0, 2.0).hashCode));
}

void testVector2Reflect() {
  var v = Vector2(0.0, 5.0);
  v.reflect(Vector2(0.0, -1.0));
  expect(v.x, equals(0.0));
  expect(v.y, equals(-5.0));

  v = Vector2(0.0, -5.0);
  v.reflect(Vector2(0.0, 1.0));
  expect(v.x, equals(0.0));
  expect(v.y, equals(5.0));

  v = Vector2(3.0, 0.0);
  v.reflect(Vector2(-1.0, 0.0));
  expect(v.x, equals(-3.0));
  expect(v.y, equals(0.0));

  v = Vector2(-3.0, 0.0);
  v.reflect(Vector2(1.0, 0.0));
  expect(v.x, equals(3.0));
  expect(v.y, equals(0.0));

  v = Vector2(4.0, 4.0);
  v.reflect(Vector2(-1.0, -1.0).normalized());
  relativeTest(v.x, -4.0);
  relativeTest(v.y, -4.0);

  v = Vector2(-4.0, -4.0);
  v.reflect(Vector2(1.0, 1.0).normalized());
  relativeTest(v.x, 4.0);
  relativeTest(v.y, 4.0);
}

void testVector2DistanceTo() {
  final a = Vector2(1.0, 1.0);
  final b = Vector2(3.0, 1.0);
  final c = Vector2(1.0, -1.0);

  expect(a.distanceTo(b), equals(2.0));
  expect(a.distanceTo(c), equals(2.0));
}

void testVector2DistanceToSquared() {
  final a = Vector2(1.0, 1.0);
  final b = Vector2(3.0, 1.0);
  final c = Vector2(1.0, -1.0);

  expect(a.distanceToSquared(b), equals(4.0));
  expect(a.distanceToSquared(c), equals(4.0));
}

void testVector2AngleTo() {
  final v0 = Vector2(1.0, 0.0);
  final v1 = Vector2(0.0, 1.0);
  final v2 = Vector2(1.0, 1.0);
  final v3 = v2.normalized();
  final tol = 1e-8;

  expect(v0.angleTo(v0), equals(0.0));
  expect(v0.angleTo(v1), equals(math.pi / 2.0));
  expect(v0.angleTo(v2), closeTo(math.pi / 4.0, tol));
  expect(v0.angleTo(v3), closeTo(math.pi / 4.0, tol));
}

void testVector2AngleToSigned() {
  final v0 = Vector2(1.0, 0.0);
  final v1 = Vector2(0.0, 1.0);
  final v2 = Vector2(-1.0, 0.0);

  expect(v0.angleToSigned(v0), equals(0.0));
  expect(v0.angleToSigned(v1), equals(math.pi / 2.0));
  expect(v1.angleToSigned(v0), equals(-math.pi / 2.0));
  expect(v0.angleToSigned(v2), equals(math.pi));
}

void testVector2Clamp() {
  final x = 2.0, y = 3.0;
  final v0 = Vector2(x, y);
  final v1 = Vector2(-x, -y);
  final v2 = Vector2(-2.0 * x, 2.0 * y)..clamp(v1, v0);

  expect(v2.storage, orderedEquals(<double>[-x, y]));
}

void testVector2ClampScalar() {
  final x = 2.0;
  final v0 = Vector2(-2.0 * x, 2.0 * x)..clampScalar(-x, x);
  expect(v0.storage, orderedEquals(<double>[-x, x]));
}

void testVector2Floor() {
  final v0 = Vector2(-0.1, 0.1)..floor();
  final v1 = Vector2(-0.5, 0.5)..floor();
  final v2 = Vector2(-0.9, 0.9)..floor();

  expect(v0.storage, orderedEquals(<double>[-1.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[-1.0, 0.0]));
  expect(v2.storage, orderedEquals(<double>[-1.0, 0.0]));
}

void testVector2Ceil() {
  final v0 = Vector2(-0.1, 0.1)..ceil();
  final v1 = Vector2(-0.5, 0.5)..ceil();
  final v2 = Vector2(-0.9, 0.9)..ceil();

  expect(v0.storage, orderedEquals(<double>[0.0, 1.0]));
  expect(v1.storage, orderedEquals(<double>[0.0, 1.0]));
  expect(v2.storage, orderedEquals(<double>[0.0, 1.0]));
}

void testVector2Round() {
  final v0 = Vector2(-0.1, 0.1)..round();
  final v1 = Vector2(-0.5, 0.5)..round();
  final v2 = Vector2(-0.9, 0.9)..round();

  expect(v0.storage, orderedEquals(<double>[0.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[-1.0, 1.0]));
  expect(v2.storage, orderedEquals(<double>[-1.0, 1.0]));
}

void testVector2RoundToZero() {
  final v0 = Vector2(-0.1, 0.1)..roundToZero();
  final v1 = Vector2(-0.5, 0.5)..roundToZero();
  final v2 = Vector2(-0.9, 0.9)..roundToZero();
  final v3 = Vector2(-1.1, 1.1)..roundToZero();
  final v4 = Vector2(-1.5, 1.5)..roundToZero();
  final v5 = Vector2(-1.9, 1.9)..roundToZero();

  expect(v0.storage, orderedEquals(<double>[0.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[0.0, 0.0]));
  expect(v2.storage, orderedEquals(<double>[0.0, 0.0]));
  expect(v3.storage, orderedEquals(<double>[-1.0, 1.0]));
  expect(v4.storage, orderedEquals(<double>[-1.0, 1.0]));
  expect(v5.storage, orderedEquals(<double>[-1.0, 1.0]));
}

void main() {
  group('Vector2', () {
    test('dot product', testVector2DotProduct);
    test('postmultiplication', testVector2Postmultiplication);
    test('cross product', testVector2CrossProduct);
    test('orhtogonal scale', testVector2OrthogonalScale);
    test('reflect', testVector2Reflect);
    test('length', testVector2Length);
    test('equals', testVector2Equals);
    test('set length', testVector2SetLength);
    test('Negate', testVector2Negate);
    test('Constructor', testVector2Constructor);
    test('add', testVector2Add);
    test('min/max', testVector2MinMax);
    test('mix', testVector2Mix);
    test('distanceTo', testVector2DistanceTo);
    test('distanceToSquared', testVector2DistanceToSquared);
    test('instancing from Float32List', testVector2InstacinfFromFloat32List);
    test('instancing from ByteBuffer', testVector2InstacingFromByteBuffer);
    test('angleTo', testVector2AngleTo);
    test('angleToSinged', testVector2AngleToSigned);
    test('clamp', testVector2Clamp);
    test('clampScalar', testVector2ClampScalar);
    test('floor', testVector2Floor);
    test('ceil', testVector2Ceil);
    test('round', testVector2Round);
    test('roundToZero', testVector2RoundToZero);
  });
}

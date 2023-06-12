// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testVector3InstacinfFromFloat32List() {
  final float32List = Float32List.fromList([1.0, 2.0, 3.0]);
  final input = Vector3.fromFloat32List(float32List);

  expect(input.x, equals(1.0));
  expect(input.y, equals(2.0));
  expect(input.z, equals(3.0));
}

void testVector3InstacingFromByteBuffer() {
  final float32List = Float32List.fromList([1.0, 2.0, 3.0, 4.0]);
  final buffer = float32List.buffer;
  final zeroOffset = Vector3.fromBuffer(buffer, 0);
  final offsetVector = Vector3.fromBuffer(buffer, Float32List.bytesPerElement);

  expect(zeroOffset.x, equals(1.0));
  expect(zeroOffset.y, equals(2.0));
  expect(zeroOffset.z, equals(3.0));

  expect(offsetVector.x, equals(2.0));
  expect(offsetVector.y, equals(3.0));
  expect(offsetVector.z, equals(4.0));
}

void testVector3Add() {
  final a = Vector3(5.0, 7.0, 3.0);
  final b = Vector3(3.0, 8.0, 2.0);

  a.add(b);
  expect(a.x, equals(8.0));
  expect(a.y, equals(15.0));
  expect(a.z, equals(5.0));

  b.addScaled(a, 0.5);
  expect(b.x, equals(7.0));
  expect(b.y, equals(15.5));
  expect(b.z, equals(4.5));
}

void testVector3MinMax() {
  final a = Vector3(5.0, 7.0, -3.0);
  final b = Vector3(3.0, 8.0, 2.0);

  final result = Vector3.zero();

  Vector3.min(a, b, result);
  expect(result.x, equals(3.0));
  expect(result.y, equals(7.0));
  expect(result.z, equals(-3.0));

  Vector3.max(a, b, result);
  expect(result.x, equals(5.0));
  expect(result.y, equals(8.0));
  expect(result.z, equals(2.0));
}

void testVector3Mix() {
  final a = Vector3(5.0, 7.0, 3.0);
  final b = Vector3(3.0, 8.0, 2.0);

  final result = Vector3.zero();

  Vector3.mix(a, b, 0.5, result);
  expect(result.x, equals(4.0));
  expect(result.y, equals(7.5));
  expect(result.z, equals(2.5));

  Vector3.mix(a, b, 0.0, result);
  expect(result.x, equals(5.0));
  expect(result.y, equals(7.0));
  expect(result.z, equals(3.0));

  Vector3.mix(a, b, 1.0, result);
  expect(result.x, equals(3.0));
  expect(result.y, equals(8.0));
  expect(result.z, equals(2.0));
}

void testVector3DotProduct() {
  final inputA = <Vector3>[];
  final inputB = <Vector3>[];
  final expectedOutput = <double>[];
  inputA.add(parseVector<Vector3>('''0.417267069084370
                                     0.049654430325742
                                     0.902716109915281'''));
  inputB.add(parseVector<Vector3>('''0.944787189721646
                                     0.490864092468080
                                     0.489252638400019'''));
  expectedOutput.add(0.860258396944727);
  assert(inputA.length == inputB.length);
  assert(inputB.length == expectedOutput.length);
  for (var i = 0; i < inputA.length; i++) {
    final output1 = dot3(inputA[i], inputB[i]);
    final output2 = dot3(inputB[i], inputA[i]);
    relativeTest(output1, expectedOutput[i]);
    relativeTest(output2, expectedOutput[i]);
  }
}

void testVector3Postmultiplication() {
  final inputMatrix =
      (Matrix3.rotationX(.4)) * (Matrix3.rotationZ(.5)) as Matrix3;
  final inputVector = Vector3(1.0, 2.0, 3.0);
  final inputInv = Matrix3.copy(inputMatrix);
  inputInv.invert();
  final resultOld = inputMatrix.transposed() * inputVector as Vector3;
  final resultOldvInv = inputInv * inputVector as Vector3;
  final resultNew = inputVector..postmultiply(inputMatrix);

  expect(resultNew.x, equals(resultOld.x));
  expect(resultNew.y, equals(resultOld.y));
  expect(resultNew.z, equals(resultOld.z));
  expect(resultNew.x, equals(resultOldvInv.x));
  expect(resultNew.y, equals(resultOldvInv.y));
  expect(resultNew.z, equals(resultOldvInv.z));
}

void testVector3CrossProduct() {
  final inputA = <Vector3>[];
  final inputB = <Vector3>[];
  final expectedOutput = <Vector3>[];

  inputA.add(parseVector<Vector3>('''0.417267069084370
                                     0.049654430325742
                                     0.902716109915281'''));
  inputB.add(parseVector<Vector3>('''0.944787189721646
                                     0.490864092468080
                                     0.489252638400019'''));
  expectedOutput.add(parseVector<Vector3>(''' -0.418817363004761
                                               0.648725602136344
                                               0.157908551498227'''));

  inputA.add(parseVector<Vector3>('''0.944787189721646
                                     0.490864092468080
                                     0.489252638400019'''));
  inputB.add(parseVector<Vector3>('''0.417267069084370
                                     0.049654430325742
                                     0.902716109915281'''));
  expectedOutput.add(parseVector<Vector3>(''' 0.418817363004761
                                             -0.648725602136344
                                             -0.157908551498227'''));

  assert(inputA.length == inputB.length);
  assert(inputB.length == expectedOutput.length);

  for (var i = 0; i < inputA.length; i++) {
    final output = Vector3.zero();
    cross3(inputA[i], inputB[i], output);
    relativeTest(output, expectedOutput[i]);
  }

  {
    final x = Vector3(1.0, 0.0, 0.0);
    final y = Vector3(0.0, 1.0, 0.0);
    final z = Vector3(0.0, 0.0, 1.0);
    Vector3 output;

    output = x.cross(y);
    relativeTest(output, Vector3(0.0, 0.0, 1.0));
    output = y.cross(x);
    relativeTest(output, Vector3(0.0, 0.0, -1.0));

    output = x.cross(z);
    relativeTest(output, Vector3(0.0, -1.0, 0.0));
    output = z.cross(x);
    relativeTest(output, Vector3(0.0, 1.0, 0.0));

    output = y.cross(z);
    relativeTest(output, Vector3(1.0, 0.0, 0.0));
    output = z.cross(y);
    relativeTest(output, Vector3(-1.0, 0.0, 0.0));
  }
}

void testVector3Constructor() {
  final v1 = Vector3(2.0, 4.0, -1.5);
  expect(v1.x, equals(2.0));
  expect(v1.y, equals(4.0));
  expect(v1.z, equals(-1.5));

  final v2 = Vector3.all(2.0);
  expect(v2.x, equals(2.0));
  expect(v2.y, equals(2.0));
  expect(v2.z, equals(2.0));

  final v3 = Vector3.random(math.Random());
  expect(v3.x, greaterThanOrEqualTo(0.0));
  expect(v3.x, lessThanOrEqualTo(1.0));
  expect(v3.y, greaterThanOrEqualTo(0.0));
  expect(v3.y, lessThanOrEqualTo(1.0));
  expect(v3.z, greaterThanOrEqualTo(0.0));
  expect(v3.z, lessThanOrEqualTo(1.0));
}

void testVector3Length() {
  final a = Vector3(5.0, 7.0, 3.0);

  relativeTest(a.length, 9.1104);
  relativeTest(a.length2, 83.0);

  relativeTest(a.normalize(), 9.1104);
  relativeTest(a.x, 0.5488);
  relativeTest(a.y, 0.7683);
  relativeTest(a.z, 0.3292);
}

void testVector3SetLength() {
  final v0 = Vector3(1.0, 2.0, 1.0);
  final v1 = Vector3(3.0, -2.0, 2.0);
  final v2 = Vector3(-1.0, 2.0, -2.0);
  final v3 = Vector3(1.0, 0.0, 0.0);

  v0.length = 0.0;
  relativeTest(v0, Vector3.zero());
  relativeTest(v0.length, 0.0);

  v1.length = 2.0;
  relativeTest(
      v1, Vector3(1.4552137851715088, -0.9701424837112427, 0.9701424837112427));
  relativeTest(v1.length, 2.0);

  v2.length = 0.5;
  relativeTest(v2,
      Vector3(-0.1666666716337204, 0.3333333432674408, -0.3333333432674408));
  relativeTest(v2.length, 0.5);

  v3.length = -1.0;
  relativeTest(v3, Vector3(-1.0, 0.0, 0.0));
  relativeTest(v3.length, 1.0);
}

void testVector3Negate() {
  final vec3 = Vector4(1.0, 2.0, 3.0, 4.0);
  vec3.negate();
  expect(vec3.x, equals(-1.0));
  expect(vec3.y, equals(-2.0));
  expect(vec3.z, equals(-3.0));
  expect(vec3.w, equals(-4.0));
}

void testVector3Equals() {
  final v3 = Vector3(1.0, 2.0, 3.0);
  expect(v3 == Vector3(1.0, 2.0, 3.0), isTrue);
  expect(v3 == Vector3(0.0, 2.0, 3.0), isFalse);
  expect(v3 == Vector3(1.0, 0.0, 3.0), isFalse);
  expect(v3 == Vector3(1.0, 2.0, 0.0), isFalse);
  expect(
      Vector3(1.0, 2.0, 3.0).hashCode, equals(Vector3(1.0, 2.0, 3.0).hashCode));
}

void testVector3Reflect() {
  var v = Vector3(5.0, 0.0, 0.0);
  v.reflect(Vector3(-1.0, 0.0, 0.0));
  expect(v.x, equals(-5.0));
  expect(v.y, equals(0.0));
  expect(v.y, equals(0.0));

  v = Vector3(0.0, 5.0, 0.0);
  v.reflect(Vector3(0.0, -1.0, 0.0));
  expect(v.x, equals(0.0));
  expect(v.y, equals(-5.0));
  expect(v.z, equals(0.0));

  v = Vector3(0.0, 0.0, 5.0);
  v.reflect(Vector3(0.0, 0.0, -1.0));
  expect(v.x, equals(0.0));
  expect(v.y, equals(0.0));
  expect(v.z, equals(-5.0));

  v = Vector3(-5.0, 0.0, 0.0);
  v.reflect(Vector3(1.0, 0.0, 0.0));
  expect(v.x, equals(5.0));
  expect(v.y, equals(0.0));
  expect(v.y, equals(0.0));

  v = Vector3(0.0, -5.0, 0.0);
  v.reflect(Vector3(0.0, 1.0, 0.0));
  expect(v.x, equals(0.0));
  expect(v.y, equals(5.0));
  expect(v.z, equals(0.0));

  v = Vector3(0.0, 0.0, -5.0);
  v.reflect(Vector3(0.0, 0.0, 1.0));
  expect(v.x, equals(0.0));
  expect(v.y, equals(0.0));
  expect(v.z, equals(5.0));

  v = Vector3(4.0, 4.0, 4.0);
  v.reflect(Vector3(-1.0, -1.0, -1.0).normalized());
  relativeTest(v.x, -4.0);
  relativeTest(v.y, -4.0);
  relativeTest(v.z, -4.0);

  v = Vector3(-4.0, -4.0, -4.0);
  v.reflect(Vector3(1.0, 1.0, 1.0).normalized());
  relativeTest(v.x, 4.0);
  relativeTest(v.y, 4.0);
  relativeTest(v.z, 4.0);

  v = Vector3(10.0, 20.0, 2.0);
  v.reflect(Vector3(-10.0, -20.0, -2.0).normalized());
  relativeTest(v.x, -10.0);
  relativeTest(v.y, -20.0);
  relativeTest(v.z, -2.0);
}

void testVector3Projection() {
  final v = Vector3(1.0, 1.0, 1.0);
  final a = 2.0 / 3.0;
  final b = 1.0 / 3.0;
  final m =
      Matrix4(a, b, -b, 0.0, b, a, b, 0.0, -b, b, a, 0.0, 0.0, 0.0, 0.0, 1.0);

  v.applyProjection(m);
  relativeTest(v.x, a);
  relativeTest(v.y, 4.0 / 3.0);
  relativeTest(v.z, a);
}

void testVector3DistanceTo() {
  final a = Vector3(1.0, 1.0, 1.0);
  final b = Vector3(1.0, 3.0, 1.0);
  final c = Vector3(1.0, 1.0, -1.0);

  expect(a.distanceTo(b), equals(2.0));
  expect(a.distanceTo(c), equals(2.0));
}

void testVector3DistanceToSquared() {
  final a = Vector3(1.0, 1.0, 1.0);
  final b = Vector3(1.0, 3.0, 1.0);
  final c = Vector3(1.0, 1.0, -1.0);

  expect(a.distanceToSquared(b), equals(4.0));
  expect(a.distanceToSquared(c), equals(4.0));
}

void testVector3AngleTo() {
  final v0 = Vector3(1.0, 0.0, 0.0);
  final v1 = Vector3(0.0, 1.0, 0.0);
  final v2 = Vector3(1.0, 1.0, 0.0);
  final v3 = v2.normalized();
  final tol = 1e-8;

  expect(v0.angleTo(v0), equals(0.0));
  expect(v0.angleTo(v1), equals(math.pi / 2.0));
  expect(v0.angleTo(v2), closeTo(math.pi / 4.0, tol));
  expect(v0.angleTo(v3), closeTo(math.pi / 4.0, tol));
}

void testVector3AngleToSigned() {
  final v0 = Vector3(1.0, 0.0, 0.0);
  final v1 = Vector3(0.0, 1.0, 0.0);
  final n = Vector3(0.0, 0.0, 1.0);

  expect(v0.angleToSigned(v0, n), equals(0.0));
  expect(v0.angleToSigned(v1, n), equals(math.pi / 2.0));
  expect(v1.angleToSigned(v0, n), equals(-math.pi / 2.0));
}

void testVector3Clamp() {
  final x = 2.0, y = 3.0, z = 4.0;
  final v0 = Vector3(x, y, z);
  final v1 = Vector3(-x, -y, -z);
  final v2 = Vector3(-2.0 * x, 2.0 * y, -2.0 * z)..clamp(v1, v0);

  expect(v2.storage, orderedEquals(<double>[-x, y, -z]));
}

void testVector3ClampScalar() {
  final x = 2.0;
  final v0 = Vector3(-2.0 * x, 2.0 * x, -2.0 * x)..clampScalar(-x, x);

  expect(v0.storage, orderedEquals(<double>[-x, x, -x]));
}

void testVector3Floor() {
  final v0 = Vector3(-0.1, 0.1, -0.1)..floor();
  final v1 = Vector3(-0.5, 0.5, -0.5)..floor();
  final v2 = Vector3(-0.9, 0.9, -0.5)..floor();

  expect(v0.storage, orderedEquals(<double>[-1.0, 0.0, -1.0]));
  expect(v1.storage, orderedEquals(<double>[-1.0, 0.0, -1.0]));
  expect(v2.storage, orderedEquals(<double>[-1.0, 0.0, -1.0]));
}

void testVector3Ceil() {
  final v0 = Vector3(-0.1, 0.1, -0.1)..ceil();
  final v1 = Vector3(-0.5, 0.5, -0.5)..ceil();
  final v2 = Vector3(-0.9, 0.9, -0.9)..ceil();

  expect(v0.storage, orderedEquals(<double>[0.0, 1.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[0.0, 1.0, 0.0]));
  expect(v2.storage, orderedEquals(<double>[0.0, 1.0, 0.0]));
}

void testVector3Round() {
  final v0 = Vector3(-0.1, 0.1, -0.1)..round();
  final v1 = Vector3(-0.5, 0.5, -0.5)..round();
  final v2 = Vector3(-0.9, 0.9, -0.9)..round();

  expect(v0.storage, orderedEquals(<double>[0.0, 0.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[-1.0, 1.0, -1.0]));
  expect(v2.storage, orderedEquals(<double>[-1.0, 1.0, -1.0]));
}

void testVector3RoundToZero() {
  final v0 = Vector3(-0.1, 0.1, -0.1)..roundToZero();
  final v1 = Vector3(-0.5, 0.5, -0.5)..roundToZero();
  final v2 = Vector3(-0.9, 0.9, -0.9)..roundToZero();
  final v3 = Vector3(-1.1, 1.1, -1.1)..roundToZero();
  final v4 = Vector3(-1.5, 1.5, -1.5)..roundToZero();
  final v5 = Vector3(-1.9, 1.9, -1.9)..roundToZero();

  expect(v0.storage, orderedEquals(<double>[0.0, 0.0, 0.0]));
  expect(v1.storage, orderedEquals(<double>[0.0, 0.0, 0.0]));
  expect(v2.storage, orderedEquals(<double>[0.0, 0.0, 0.0]));
  expect(v3.storage, orderedEquals(<double>[-1.0, 1.0, -1.0]));
  expect(v4.storage, orderedEquals(<double>[-1.0, 1.0, -1.0]));
  expect(v5.storage, orderedEquals(<double>[-1.0, 1.0, -1.0]));
}

void testVector3ApplyQuaternion() {
  final q = Quaternion(0.0, 0.9238795292366128, 0.0, 0.38268342717215614);
  final v = Vector3(0.417267069084370, 0.049654430325742, 0.753423475845592)
    ..applyQuaternion(q);

  relativeTest(v,
      Vector3(0.23769846558570862, 0.04965442791581154, -0.8278031349182129));
}

void main() {
  group('Vector3', () {
    test('dot product', testVector3DotProduct);
    test('postmultiplication', testVector3Postmultiplication);
    test('cross product', testVector3CrossProduct);
    test('reflect', testVector3Reflect);
    test('projection', testVector3Projection);
    test('length', testVector3Length);
    test('equals', testVector3Equals);
    test('set length', testVector3SetLength);
    test('Negate', testVector3Negate);
    test('Constructor', testVector3Constructor);
    test('add', testVector3Add);
    test('min/max', testVector3MinMax);
    test('mix', testVector3Mix);
    test('distanceTo', testVector3DistanceTo);
    test('distanceToSquared', testVector3DistanceToSquared);
    test('angleTo', testVector3AngleTo);
    test('angleToSinged', testVector3AngleToSigned);
    test('instancing from Float32List', testVector3InstacinfFromFloat32List);
    test('instancing from ByteBuffer', testVector3InstacingFromByteBuffer);
    test('clamp', testVector3Clamp);
    test('clampScalar', testVector3ClampScalar);
    test('floor', testVector3Floor);
    test('ceil', testVector3Ceil);
    test('round', testVector3Round);
    test('roundToZero', testVector3RoundToZero);
    test('applyQuaternion', testVector3ApplyQuaternion);
  });
}

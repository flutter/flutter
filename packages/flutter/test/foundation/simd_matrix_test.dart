// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/simd_matrix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

const double epsilon = 0.01;

void main() {
  test('matrix multiplication', () {
    final Random random = Random();
    matrixEqualWithinTolerance(Matrix4.identity().multiplied(Matrix4.identity()), SimdMatrix4.identity * SimdMatrix4.identity);
    for (int i = 0; i < 1000; i++) {
      final Matrix4 a = randomMatrix(random);
      final Matrix4 b = randomMatrix(random);
      matrixEqualWithinTolerance(a.multiplied(b), SimdMatrix4.fromVectorMath(a) * SimdMatrix4.fromVectorMath(b));
    }
  });

  test('matrix invert', () {
    final Random random = Random();
    matrixEqualWithinTolerance(Matrix4.identity()..copyInverse(Matrix4.identity()), SimdMatrix4.identity.invert());
    for (int i = 0; i < 1000; i++) {
      final Matrix4 a = randomMatrix(random);
      final Matrix4 inverse = Matrix4.zero();
      final double det = a.copyInverse(inverse);
      if (det == 0.0) {
        continue;
      }
      matrixEqualWithinTolerance(inverse, SimdMatrix4.fromVectorMath(a).invert());
    }
  });

  test('Offset transform', () {
    final Random random = Random();
    offsetEqualWithinTolerance(
      MatrixUtils.transformPoint(Matrix4.identity(), Offset.zero),
      SimdMatrixUtils.transformPoint(SimdMatrix4.identity, Offset.zero),
    );

    for (int i = 0; i < 1000; i++) {
      final Matrix4 transform = randomMatrix(random);
      final Offset point = randomOffset(random);
      offsetEqualWithinTolerance(
        MatrixUtils.transformPoint(transform, point),
        SimdMatrixUtils.transformPoint(SimdMatrix4.fromVectorMath(transform), point),
      );
    }
  });

  test('Matrix equals', () {
    final Random random = Random();
    expect(
      MatrixUtils.matrixEquals(Matrix4.identity(), Matrix4.identity()),
      SimdMatrixUtils.matrixEquals(SimdMatrix4.identity, SimdMatrix4.identity),
    );

    for (int i = 0; i < 1000; i++) {
      final Matrix4 transform = randomMatrix(random);
      expect(
        MatrixUtils.matrixEquals(transform, transform),
        SimdMatrixUtils.matrixEquals(SimdMatrix4.fromVectorMath(transform), SimdMatrix4.fromVectorMath(transform)),
        reason: transform.toString(),
      );
    }
    for (int i = 0; i < 1000; i++) {
      final Matrix4 transformA = randomMatrix(random);
      final Matrix4 transformB = randomMatrix(random);
      expect(
        MatrixUtils.matrixEquals(transformA, transformB),
        SimdMatrixUtils.matrixEquals(SimdMatrix4.fromVectorMath(transformA), SimdMatrix4.fromVectorMath(transformB)),
      );
    }
  });
}

Matrix4 randomMatrix(Random random) {
  final double scale = random.nextDouble() * 100;
  final Matrix4 matrix4 = Matrix4(
    random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5,
    random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5,
    random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5,
    random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5, random.nextDouble() - 0.5,
  );
  return matrix4..scale(scale);
}

Rect randomRect(Random random) {
  return Rect.fromPoints(randomOffset(random), randomOffset(random));
}

Offset randomOffset(Random random) {
  final double scale = random.nextDouble() * 100;
  return Offset(
    (random.nextDouble() - 0.5) * scale,
    (random.nextDouble() - 0.5) * scale,
  );
}

void offsetEqualWithinTolerance(Offset a, Offset b) {
  expect(a.dx, moreOrLessEquals(b.dx, epsilon: 0.5));
  expect(a.dy, moreOrLessEquals(b.dy, epsilon: 0.5));
}

void rectEqualWithinTolerance(Rect a, Rect b) {
  expect(a.left, moreOrLessEquals(b.left, epsilon: 0.5));
  expect(a.top, moreOrLessEquals(b.top, epsilon: 0.5));
  expect(a.bottom, moreOrLessEquals(b.bottom, epsilon: 0.5));
  expect(a.right, moreOrLessEquals(b.right, epsilon: 0.5));
}

void matrixEqualWithinTolerance(Matrix4 matrix4, SimdMatrix4 simdMatrix4) {
  final Float32List simdValues = simdMatrix4.toFloatList();
  expect(matrix4.storage[0], moreOrLessEquals(simdValues[0], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[1], moreOrLessEquals(simdValues[1], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[2], moreOrLessEquals(simdValues[2], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[3], moreOrLessEquals(simdValues[3], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[4], moreOrLessEquals(simdValues[4], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[5], moreOrLessEquals(simdValues[5], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[6], moreOrLessEquals(simdValues[6], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[7], moreOrLessEquals(simdValues[7], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[8], moreOrLessEquals(simdValues[8], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[9], moreOrLessEquals(simdValues[9], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[10], moreOrLessEquals(simdValues[10], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[11], moreOrLessEquals(simdValues[11], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[12], moreOrLessEquals(simdValues[12], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[13], moreOrLessEquals(simdValues[13], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[14], moreOrLessEquals(simdValues[14], epsilon: epsilon), reason: matrix4.toString());
  expect(matrix4.storage[15], moreOrLessEquals(simdValues[15], epsilon: epsilon), reason: matrix4.toString());
}

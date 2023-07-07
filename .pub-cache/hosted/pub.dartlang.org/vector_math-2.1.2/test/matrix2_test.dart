// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testMatrix2Adjoint() {
  final input = <Matrix2>[];
  final expectedOutput = <Matrix2>[];

  input.add(parseMatrix<Matrix2>('''0.830828627896291   0.549723608291140
                                    0.585264091152724   0.917193663829810'''));
  expectedOutput
      .add(parseMatrix<Matrix2>(''' 0.917193663829810  -0.549723608291140
                                   -0.585264091152724   0.830828627896291'''));
  input.add(parseMatrix<Matrix2>(''' 1     0
                                     0     1'''));
  expectedOutput.add(parseMatrix<Matrix2>(''' 1     0
                                              0     1'''));

  assert(input.length == expectedOutput.length);

  for (var i = 0; i < input.length; i++) {
    final output = input[i].clone();
    output.scaleAdjoint(1.0);
    relativeTest(output, expectedOutput[i]);
  }
}

void testMatrix2Determinant() {
  final input = <Matrix2>[];
  final expectedOutput = <double>[];

  input.add(parseMatrix<Matrix2>('''0.830828627896291   0.549723608291140
                                    0.585264091152724   0.917193663829810'''));
  expectedOutput.add(0.440297265243183);

  assert(input.length == expectedOutput.length);

  for (var i = 0; i < input.length; i++) {
    final output = input[i].determinant();
    //print('${input[i].cols}x${input[i].rows} = $output');
    relativeTest(output, expectedOutput[i]);
  }
}

void testMatrix2Transform() {
  final rot = Matrix2.rotation(math.pi / 4);
  final input = Vector2(0.234245234259, 0.890723489233);

  final expected = Vector2(
      rot.entry(0, 0) * input.x + rot.entry(0, 1) * input.y,
      rot.entry(1, 0) * input.x + rot.entry(1, 1) * input.y);

  final transExpected = Vector2(
      rot.entry(0, 0) * input.x + rot.entry(1, 0) * input.y,
      rot.entry(0, 1) * input.x + rot.entry(1, 1) * input.y);

  relativeTest(rot.transformed(input), expected);
  relativeTest(rot.transposed().transformed(input), transExpected);
}

void testMatrix2Inversion() {
  final m = Matrix2(4.0, 3.0, 3.0, 2.0);
  final result = Matrix2.zero();
  final det = result.copyInverse(m);
  expect(det, -1.0);
  expect(result.entry(0, 0), -2.0);
  expect(result.entry(1, 0), 3.0);
  expect(result.entry(0, 1), 3.0);
  expect(result.entry(1, 1), -4.0);
}

void testMatrix2Dot() {
  final matrix = Matrix2(1.0, 2.0, 3.0, 4.0);

  final v = Vector2(3.0, 4.0);

  expect(matrix.dotRow(0, v), equals(15.0));
  expect(matrix.dotRow(1, v), equals(22.0));
  expect(matrix.dotColumn(0, v), equals(11.0));
  expect(matrix.dotColumn(1, v), equals(25.0));
}

void testMatrix2Scale() {
  final m = Matrix2(1.0, 2.0, 3.0, 4.0);
  final n = m.scaled(2.0);

  expect(n.storage[0], equals(2.0));
  expect(n.storage[1], equals(4.0));
  expect(n.storage[2], equals(6.0));
  expect(n.storage[3], equals(8.0));
}

void testMatrix2Solving() {
  final A = Matrix2(2.0, 2.0, 8.0, 20.0);
  final AA = Matrix2.fromList([2.0, 2.0, 8.0, 20.0]);
  expect(A, equals(AA));
  final b = Vector2(20.0, 64.0);
  final result = Vector2.zero();

  Matrix2.solve(A, result, b);

  final backwards = A.transform(Vector2.copy(result));

  expect(backwards.x, equals(b.x));
  expect(backwards.y, equals(b.y));
}

void testMatrix2Equals() {
  expect(Matrix2.identity(), equals(Matrix2.identity()));
  expect(Matrix2.zero(), isNot(equals(Matrix2.identity())));
  expect(Matrix2.zero(), isNot(equals(5)));
  expect(Matrix2.identity().hashCode, equals(Matrix2.identity().hashCode));
}

void main() {
  group('Matrix2', () {
    test('Determinant', testMatrix2Determinant);
    test('Adjoint', testMatrix2Adjoint);
    test('transform 2D', testMatrix2Transform);
    test('inversion', testMatrix2Inversion);
    test('dot product', testMatrix2Dot);
    test('Scale', testMatrix2Scale);
    test('solving', testMatrix2Solving);
    test('equals', testMatrix2Equals);
  });
}

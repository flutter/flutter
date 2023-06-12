// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';

import 'test_utils.dart';

void testMatrix3Adjoint() {
  final input = <dynamic>[];
  final expectedOutput = <dynamic>[];

  input.add(parseMatrix<Matrix3>(
      ''' 0.285839018820374   0.380445846975357   0.053950118666607
          0.757200229110721   0.567821640725221   0.530797553008973
          0.753729094278495   0.075854289563064   0.779167230102011'''));
  expectedOutput.add(parseMatrix<Matrix3>(
      ''' 0.402164743710542  -0.292338588868304   0.171305679728352
          -0.189908046274114   0.182052622470548  -0.110871609529434
          -0.370546805539367   0.265070987960728  -0.125768101844091'''));
  input.add(parseMatrix<Matrix3>('''1     0     0
                                    0     1     0
                                    0     0     1'''));
  expectedOutput.add(parseMatrix<Matrix3>('''1     0     0
                                             0     1     0
                                             0     0     1'''));
  input.add(parseMatrix<Matrix4>('''1     0     0     0
                                    0     1     0     0
                                    0     0     1     0
                                    0     0     0     1'''));
  expectedOutput.add(parseMatrix<Matrix4>('''1     0     0     0
                                             0     1     0     0
                                             0     0     1     0
                                             0     0     0     1'''));

  assert(input.length == expectedOutput.length);

  for (var i = 0; i < input.length; i++) {
    final dynamic output = input[i].clone();
    output.scaleAdjoint(1.0);
    relativeTest(output, expectedOutput[i]);
  }
}

void testMatrix3Determinant() {
  final input = <Matrix3>[];
  final expectedOutput = <double>[];

  input.add(parseMatrix<Matrix3>(
      '''0.285839018820374   0.380445846975357   0.053950118666607
         0.757200229110721   0.567821640725221   0.530797553008973
         0.753729094278495   0.075854289563064   0.779167230102011'''));
  expectedOutput.add(0.022713604103796);

  assert(input.length == expectedOutput.length);

  for (var i = 0; i < input.length; i++) {
    final output = input[i].determinant();
    //print('${input[i].cols}x${input[i].rows} = $output');
    relativeTest(output, expectedOutput[i]);
  }
}

void testMatrix3SelfTransposeMultiply() {
  final inputA = <Matrix3>[];
  final inputB = <Matrix3>[];
  final expectedOutput = <Matrix3>[];

  inputA.add(parseMatrix<Matrix3>(
      '''0.084435845510910   0.800068480224308   0.181847028302852
         0.399782649098896   0.431413827463545   0.263802916521990
         0.259870402850654   0.910647594429523   0.145538980384717'''));
  inputB.add(parseMatrix<Matrix3>(
      '''0.136068558708664   0.549860201836332   0.622055131485066
         0.869292207640089   0.144954798223727   0.350952380892271
         0.579704587365570   0.853031117721894   0.513249539867053'''));
  expectedOutput.add(parseMatrix<Matrix3>(
      '''0.509665070066463   0.326055864494860   0.326206788210183
         1.011795431418814   1.279272055656899   1.116481872383158
         0.338435097301446   0.262379221330899   0.280398953455993'''));

  inputA.add(parseMatrix<Matrix3>(
      '''0.136068558708664   0.549860201836332   0.622055131485066
         0.869292207640089   0.144954798223727   0.350952380892271
         0.579704587365570   0.853031117721894   0.513249539867053'''));
  inputB.add(parseMatrix<Matrix3>(
      '''0.084435845510910   0.800068480224308   0.181847028302852
         0.399782649098896   0.431413827463545   0.263802916521990
         0.259870402850654   0.910647594429523   0.145538980384717'''));
  expectedOutput.add(parseMatrix<Matrix3>(
      '''0.509665070066463   1.011795431418814   0.338435097301446
         0.326055864494860   1.279272055656899   0.262379221330899
         0.326206788210183   1.116481872383158   0.280398953455993'''));
  assert(inputA.length == inputB.length);
  assert(inputB.length == expectedOutput.length);

  for (var i = 0; i < inputA.length; i++) {
    final output = inputA[i].clone();
    output.transposeMultiply(inputB[i]);
    relativeTest(output, expectedOutput[i]);
  }
}

void testMatrix3SelfMultiply() {
  final inputA = <Matrix3>[];
  final inputB = <Matrix3>[];
  final expectedOutput = <Matrix3>[];

  inputA.add(parseMatrix<Matrix3>(
      '''0.084435845510910   0.800068480224308   0.181847028302852
         0.399782649098896   0.431413827463545   0.263802916521990
         0.259870402850654   0.910647594429523   0.145538980384717'''));
  inputB.add(parseMatrix<Matrix3>(
      '''0.136068558708664   0.549860201836332   0.622055131485066
         0.869292207640089   0.144954798223727   0.350952380892271
         0.579704587365570   0.853031117721894   0.513249539867053'''));
  expectedOutput.add(parseMatrix<Matrix3>(
      '''0.812399915745417   0.317522849978516   0.426642592595554
         0.582350288210078   0.507392169174135   0.535489283769338
         0.911348663480233   0.399044409575883   0.555945473748377'''));

  inputA.add(parseMatrix<Matrix3>(
      '''0.136068558708664   0.549860201836332   0.622055131485066
         0.869292207640089   0.144954798223727   0.350952380892271
         0.579704587365570   0.853031117721894   0.513249539867053'''));
  inputB.add(parseMatrix<Matrix3>(
      '''0.084435845510910   0.800068480224308   0.181847028302852
         0.399782649098896   0.431413827463545   0.263802916521990
         0.259870402850654   0.910647594429523   0.145538980384717'''));
  expectedOutput.add(parseMatrix<Matrix3>(
      '''0.392967349540540   0.912554468305858   0.260331657549835
         0.222551972385485   1.077622741167203   0.247394954900102
         0.523353251675581   1.299202246456530   0.405147467960185'''));
  assert(inputA.length == inputB.length);
  assert(inputB.length == expectedOutput.length);

  for (var i = 0; i < inputA.length; i++) {
    final output = inputA[i].clone();
    output.multiply(inputB[i]);
    relativeTest(output, expectedOutput[i]);
  }
}

void testMatrix3SelfMultiplyTranspose() {
  final inputA = <Matrix3>[];
  final inputB = <Matrix3>[];
  final expectedOutput = <Matrix3>[];

  inputA.add(parseMatrix<Matrix3>(
      '''0.084435845510910   0.800068480224308   0.181847028302852
         0.399782649098896   0.431413827463545   0.263802916521990
         0.259870402850654   0.910647594429523   0.145538980384717'''));
  inputB.add(parseMatrix<Matrix3>(
      '''0.136068558708664   0.549860201836332   0.622055131485066
         0.869292207640089   0.144954798223727   0.350952380892271
         0.579704587365570   0.853031117721894   0.513249539867053'''));
  expectedOutput.add(parseMatrix<Matrix3>(
      '''0.564533756922142   0.253192835205285   0.824764060523193
         0.455715101026938   0.502645707562004   0.735161980594196
         0.626622330821134   0.408983306176468   1.002156614695209'''));

  inputA.add(parseMatrix<Matrix3>(
      '''0.136068558708664   0.549860201836332   0.622055131485066
         0.869292207640089   0.144954798223727   0.350952380892271
         0.579704587365570   0.853031117721894   0.513249539867053'''));
  inputB.add(parseMatrix<Matrix3>(
      '''0.084435845510910   0.800068480224308   0.181847028302852
         0.399782649098896   0.431413827463545   0.263802916521990
         0.259870402850654   0.910647594429523   0.145538980384717'''));
  expectedOutput.add(parseMatrix<Matrix3>(
      '''0.564533756922142   0.455715101026938   0.626622330821134
         0.253192835205285   0.502645707562004   0.408983306176468
         0.824764060523193   0.735161980594196   1.002156614695209'''));
  assert(inputA.length == inputB.length);
  assert(inputB.length == expectedOutput.length);

  for (var i = 0; i < inputA.length; i++) {
    final output = inputA[i].clone();
    output.multiplyTranspose(inputB[i]);
    relativeTest(output, expectedOutput[i]);
  }
}

void testMatrix3Transform() {
  final rotX = Matrix3.rotationX(math.pi / 4);
  final rotY = Matrix3.rotationY(math.pi / 4);
  final rotZ = Matrix3.rotationZ(math.pi / 4);
  final input = Vector3(1.0, 0.0, 0.0);

  relativeTest(rotX.transformed(input), input);
  relativeTest(rotY.transformed(input),
      Vector3(1.0 / math.sqrt(2.0), 0.0, 1.0 / math.sqrt(2.0)));
  relativeTest(rotZ.transformed(input),
      Vector3(1.0 / math.sqrt(2.0), 1.0 / math.sqrt(2.0), 0.0));
}

void testMatrix3Transform2() {
  final rotZ = Matrix3.rotationZ(math.pi / 4);
  final trans = Matrix3(1.0, 0.0, 3.0, 0.0, 1.0, 2.0, 3.0, 2.0, 1.0);
  final transB =
      Matrix3.fromList([1.0, 0.0, 3.0, 0.0, 1.0, 2.0, 3.0, 2.0, 1.0]);
  expect(trans, equals(transB));

  final input = Vector2(1.0, 0.0);

  relativeTest(
      rotZ.transform2(input.clone()), Vector2(math.sqrt(0.5), math.sqrt(0.5)));

  relativeTest(trans.transform2(input.clone()), Vector2(4.0, 2.0));
}

void testMatrix3AbsoluteRotate2() {
  final rotZ = Matrix3.rotationZ(-math.pi / 4);
  final rotZcw = Matrix3.rotationZ(math.pi / 4);
  // Add translation
  rotZ.setEntry(2, 0, 3.0);
  rotZ.setEntry(2, 1, 2.0);

  final input = Vector2(1.0, 0.0);

  relativeTest(rotZ.absoluteRotate2(input.clone()),
      Vector2(math.sqrt(0.5), math.sqrt(0.5)));

  relativeTest(rotZcw.absoluteRotate2(input.clone()),
      Vector2(math.sqrt(0.5), math.sqrt(0.5)));
}

void testMatrix3ConstructorCopy() {
  final a = Vector3(1.0, 2.0, 3.0);
  final b = Vector3(4.0, 5.0, 6.0);
  final c = Vector3(7.0, 8.0, 9.0);
  final m = Matrix3.columns(a, b, c);
  expect(m.entry(0, 0), 1.0);
  expect(m.entry(2, 2), 9.0);
  c.z = 5.0;
  a.x = 2.0;
  expect(m.entry(0, 0), 1.0);
  expect(m.entry(2, 2), 9.0);
}

void testMatrix3Inversion() {
  final m = Matrix3(1.0, 0.0, 5.0, 2.0, 1.0, 6.0, 3.0, 4.0, 0.0);
  final result = Matrix3.zero();
  final det = result.copyInverse(m);
  expect(det, 1.0);
  expect(result.entry(0, 0), -24.0);
  expect(result.entry(1, 0), 20.0);
  expect(result.entry(2, 0), -5.0);
  expect(result.entry(0, 1), 18.0);
  expect(result.entry(1, 1), -15.0);
  expect(result.entry(2, 1), 4.0);
  expect(result.entry(0, 2), 5.0);
  expect(result.entry(1, 2), -4.0);
  expect(result.entry(2, 2), 1.0);
}

void testMatrix3Dot() {
  final matrix = Matrix3(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0);

  final v = Vector3(2.0, 3.0, 4.0);

  expect(matrix.dotRow(0, v), equals(42.0));
  expect(matrix.dotRow(1, v), equals(51.0));
  expect(matrix.dotRow(2, v), equals(60.0));
  expect(matrix.dotColumn(0, v), equals(20.0));
  expect(matrix.dotColumn(1, v), equals(47.0));
  expect(matrix.dotColumn(2, v), equals(74.0));
}

void testMatrix3Scale() {
  final m = Matrix3(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0);
  final n = m.scaled(2.0);

  expect(n.storage[0], equals(2.0));
  expect(n.storage[1], equals(4.0));
  expect(n.storage[2], equals(6.0));
  expect(n.storage[3], equals(8.0));
  expect(n.storage[4], equals(10.0));
  expect(n.storage[5], equals(12.0));
  expect(n.storage[6], equals(14.0));
  expect(n.storage[7], equals(16.0));
  expect(n.storage[8], equals(18.0));
}

void testMatrix3Solving() {
  final A = Matrix3(2.0, 12.0, 8.0, 20.0, 24.0, 26.0, 8.0, 4.0, 60.0);

  final b = Vector3(32.0, 64.0, 72.0);
  final result = Vector3.zero();

  final b2 = Vector2(32.0, 64.0);
  final result2 = Vector2.zero();

  Matrix3.solve(A, result, b);
  Matrix3.solve2(A, result2, b2);

  final backwards = A.transform(Vector3.copy(result));
  final backwards2 = A.transform2(Vector2.copy(result2));

  expect(backwards.x, equals(b.x));
  expect(backwards.y, equals(b.y));
  expect(backwards.z, equals(b.z));

  expect(backwards2.x, equals(b2.x));
  expect(backwards2.y, equals(b2.y));
}

void testMatrix3Equals() {
  expect(Matrix3.identity(), equals(Matrix3.identity()));
  expect(Matrix3.zero(), isNot(equals(Matrix3.identity())));
  expect(Matrix3.zero(), isNot(equals(5)));
  expect(Matrix3.identity().hashCode, equals(Matrix3.identity().hashCode));
}

void testMatrixClassifiers() {
  expect(Matrix3.zero().isIdentity(), false);
  expect(Matrix3.zero().isZero(), true);
  expect(Matrix3.identity().isIdentity(), true);
  expect(Matrix3.identity().isZero(), false);
}

void main() {
  group('Matrix3', () {
    test('Determinant', testMatrix3Determinant);
    test('Adjoint', testMatrix3Adjoint);
    test('Self multiply', testMatrix3SelfMultiply);
    test('Self transpose', testMatrix3SelfTransposeMultiply);
    test('Self multiply tranpose', testMatrix3SelfMultiplyTranspose);
    test('transform 2D', testMatrix3Transform2);
    test('rotation 2D', testMatrix3AbsoluteRotate2);
    test('transform', testMatrix3Transform);
    test('constructor', testMatrix3ConstructorCopy);
    test('inversion', testMatrix3Inversion);
    test('dot product', testMatrix3Dot);
    test('Scale', testMatrix3Scale);
    test('solving', testMatrix3Solving);
    test('equals', testMatrix3Equals);
    test('matrix classifiers', testMatrixClassifiers);
  });
}

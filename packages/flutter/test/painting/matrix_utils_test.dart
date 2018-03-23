// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('MatrixUtils.getAsTranslation()', () {
    Matrix4 test;
    test = new Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test = new Matrix4.zero();
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = new Matrix4.rotationX(1.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = new Matrix4.rotationZ(1.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = new Matrix4.translationValues(1.0, 2.0, 0.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(1.0, 2.0)));
    // Rotate matrix and then rotate it back to introduce tiny rounding errors.
    test.rotateZ(3.0);
    test.rotateZ(-3.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(1.0, 2.0)));

    test = new Matrix4.translationValues(1.0, 2.0, 3.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = new Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.rotateX(2.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = new Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.scale(2.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = new Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.translate(2.0, -2.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(2.0, -2.0)));
    test.translate(4.0, 8.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(6.0, 6.0)));
  });

  test('MatrixUtils.getAsScale()', () {
    Matrix4 test = new Matrix4.identity();
    expect(MatrixUtils.getAsScale(test), equals(1.0));
    test.scale(3.0, 3.0, 1.0);
    expect(MatrixUtils.getAsScale(test), equals(3.0));
    // Rotate matrix and then rotate it back to introduce tiny rounding errors.
    test.rotateZ(3.0);
    test.rotateZ(-3.0);
    expect(MatrixUtils.getAsScale(test), equals(3.0));
  });

  test('MatrixUtils.isIdentity()', () {
    Matrix4 test = new Matrix4.identity();
    expect(MatrixUtils.isIdentity(test), isTrue);

    // Rotate matrix and then rotate it back to introduce tiny rounding errors.
    test.rotateZ(3.0);
    test.rotateZ(-3.0);
    expect(MatrixUtils.isIdentity(test), isTrue);
  });

  test('cylindricalProjectionTransform identity', () {
    final Matrix4 initialState = MatrixUtils.createCylindricalProjectionTransform(
      radius: 0.0,
      angle: 0.0,
      perspective: 0.0,
    );

    expect(initialState, new Matrix4.identity());
  });

  test('cylindricalProjectionTransform rotate with no radius', () {
    final Matrix4 simpleRotate = MatrixUtils.createCylindricalProjectionTransform(
      radius: 0.0,
      angle: pi / 2.0,
      perspective: 0.0,
    );

    expect(simpleRotate, new Matrix4.rotationX(pi / 2.0));
  });

  test('cylindricalProjectionTransform radius does not change scale', () {
    final Matrix4 noRotation = MatrixUtils.createCylindricalProjectionTransform(
      radius: 1000000.0,
      angle: 0.0,
      perspective: 0.0,
    );

    expect(noRotation, new Matrix4.identity());
  });

  test('cylindricalProjectionTransform calculation spot check', () {
    final Matrix4 actual = MatrixUtils.createCylindricalProjectionTransform(
      radius: 100.0,
      angle: pi / 3.0,
      perspective: 0.001,
    );

    expect(actual.storage, <dynamic>[
      1.0, 0.0, 0.0, 0.0,
      0.0, moreOrLessEquals(0.5), moreOrLessEquals(0.8660254037844386), moreOrLessEquals(-0.0008660254037844386),
      0.0, moreOrLessEquals(-0.8660254037844386), moreOrLessEquals(0.5), moreOrLessEquals(-0.0005),
      0.0, moreOrLessEquals(-86.60254037844386), moreOrLessEquals(-50.0), 1.05,
    ]);
  });

  test('TransformProperty', () {
    expect(new TransformProperty('transform', new Matrix4.identity()).toString(), equals('transform: identity'));
    expect(new TransformProperty('transform', new Matrix4.identity()..scale(3.0, 3.0, 1.0)).toString(), equals('transform: scale(3.0)'));
    expect(new TransformProperty('transform', new Matrix4.identity()..translate(42.0, 10.5)).toString(), equals('transform: translate(42.0, 10.5)'));
    expect(new TransformProperty('transform', new Matrix4.identity()..rotateX(pi/4)).toString(), equals(
        'transform:\n'
        '  [0] 1.0,0.0,0.0,0.0\n'
        '  [1] 0.0,0.7071067811865476,-0.7071067811865475,0.0\n'
        '  [2] 0.0,0.7071067811865475,0.7071067811865476,0.0\n'
        '  [3] 0.0,0.0,0.0,1.0'
    ));
  });
}

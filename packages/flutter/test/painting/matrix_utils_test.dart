// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('MatrixUtils.transformRect handles very small values', () {
    const Rect evilRect = Rect.fromLTRB(0.0, -1.7976931348623157e+308, 800.0, 1.7976931348623157e+308);
    final Matrix4 transform = Matrix4.identity()..translate(10.0, 0.0);
    final Rect transformedRect = MatrixUtils.transformRect(transform, evilRect);
    expect(transformedRect.isFinite, true);
  });

  test('MatrixUtils.getAsTranslation()', () {
    Matrix4 test;
    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test = Matrix4.zero();
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = Matrix4.rotationX(1.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = Matrix4.rotationZ(1.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);
    test = Matrix4.translationValues(1.0, 2.0, 0.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(1.0, 2.0)));
    test = Matrix4.translationValues(1.0, 2.0, 3.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.rotateX(2.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.scale(2.0);
    expect(MatrixUtils.getAsTranslation(test), isNull);

    test = Matrix4.identity();
    expect(MatrixUtils.getAsTranslation(test), equals(Offset.zero));
    test.translate(2.0, -2.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(2.0, -2.0)));
    test.translate(4.0, 8.0);
    expect(MatrixUtils.getAsTranslation(test), equals(const Offset(6.0, 6.0)));
  });

  test('cylindricalProjectionTransform identity', () {
    final Matrix4 initialState = MatrixUtils.createCylindricalProjectionTransform(
      radius: 0.0,
      angle: 0.0,
      perspective: 0.0,
    );

    expect(initialState, Matrix4.identity());
  });

  test('cylindricalProjectionTransform rotate with no radius', () {
    final Matrix4 simpleRotate = MatrixUtils.createCylindricalProjectionTransform(
      radius: 0.0,
      angle: pi / 2.0,
      perspective: 0.0,
    );

    expect(simpleRotate, Matrix4.rotationX(pi / 2.0));
  });

  test('cylindricalProjectionTransform radius does not change scale', () {
    final Matrix4 noRotation = MatrixUtils.createCylindricalProjectionTransform(
      radius: 1000000.0,
      angle: 0.0,
      perspective: 0.0,
    );

    expect(noRotation, Matrix4.identity());
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

  test('forceToPoint', () {
    const Offset forcedOffset = Offset(20, -30);
    final Matrix4 forcedTransform = MatrixUtils.forceToPoint(forcedOffset);

    expect(
      MatrixUtils.transformPoint(forcedTransform, forcedOffset),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, Offset.zero),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(1, 1)),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(-1, -1)),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(-20, 30)),
      forcedOffset,
    );

    expect(
      MatrixUtils.transformPoint(forcedTransform, const Offset(-1.2344, 1422434.23)),
      forcedOffset,
    );
  });
}

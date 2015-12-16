// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test("MatrixUtils.getAsTranslation()", () {
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
}

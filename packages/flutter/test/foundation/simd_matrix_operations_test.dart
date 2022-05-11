// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('multiplied - identity', () {
    final Matrix4 left = Matrix4.identity();
    final Matrix4 right = Matrix4.identity();
    final Matrix4 result = multiplied(left, right);

    // verify storage was not re-used.
    expect(identical(left, result), isFalse);
    expect(identical(right, result), isFalse);

    expect(result.storage.toList(), Matrix4.identity().storage);
  });

  test('multiply - identity', () {
    final Matrix4 left = Matrix4.identity();
    final Matrix4 right = Matrix4.identity();
    multiply(left, right);

    expect(left.storage, Matrix4.identity().storage);
  });

  test('multiplied - transpose', () {
    final Matrix4 left = Matrix4.identity()
      ..translate(3.0, 4.0, 5.0);
    final Matrix4 right = Matrix4.identity()
      ..translate(6.0, 7.0, 8.0);
    final Matrix4 result = multiplied(left, right);

    expect(result.storage, left.multiplied(right).storage);
  });

  test('multiplied - rotated', () {
    final Matrix4 left = Matrix4.identity()
      ..rotateX(0.5)
      ..rotateY(1);
    final Matrix4 right = Matrix4.identity()
      ..translate(2.0, 3.0, 4.0);
    final Matrix4 result = multiplied(left, right);

    expect(result.storage, equals(left.multiplied(right).storage.map((double value) => closeTo(value, 0.1))));
  });
}

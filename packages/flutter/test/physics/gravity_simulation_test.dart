// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gravity simulation 1', () {
    expect(GravitySimulation(9.81, 10.0, 0.0, 0.0), hasOneLineDescription);
    expect(GravitySimulation(9.81, 10.0, 0.0, 0.0).x(10.0), moreOrLessEquals(50.0 * 9.81 + 10.0));
  });

  test('Gravity simulation 2', () {
    final gravity = GravitySimulation(-10, 0.0, 6.0, 10.0);

    expect(gravity.x(0.0), equals(0.0));
    expect(gravity.dx(0.0), equals(10.0));
    expect(gravity.isDone(0.0), isFalse);

    expect(gravity.x(1.0), equals(5.0));
    expect(gravity.dx(1.0), equals(0.0));
    expect(gravity.isDone(0.2), isFalse);

    expect(gravity.x(2.0), equals(0.0));
    expect(gravity.dx(2.0), equals(-10.0));
    expect(gravity.isDone(2.0), isFalse);

    expect(gravity.x(3.0), equals(-15.0));
    expect(gravity.dx(3.0), equals(-20.0));
    expect(gravity.isDone(3.0), isTrue);
  });
}

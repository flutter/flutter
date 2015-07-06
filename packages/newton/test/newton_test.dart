// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library simple_physics.test;

import 'package:test/test.dart';

import 'package:newton/newton.dart';

void main() {
  test('test_friction', () {
    var friction = new Friction(0.3, 100.0, 400.0);

    expect(friction.isDone(0.0), false);
    expect(friction.x(0.0), 100);
    expect(friction.dx(0.0), 400.0);

    expect(friction.x(1.0) > 330 && friction.x(1.0) < 335, true);

    expect(friction.dx(1.0), 120.0);
    expect(friction.dx(2.0), 36.0);
    expect(friction.dx(3.0), 10.8);
    expect(friction.dx(4.0) < 3.5, true);

    expect(friction.isDone(5.0), true);
    expect(friction.x(5.0) > 431 && friction.x(5.0) < 432, true);
  });

  test('test_gravity', () {
    var gravity = new Gravity(200.0, 100.0, 600.0, 0.0);

    expect(gravity.isDone(0.0), false);
    expect(gravity.x(0.0), 100.0);
    expect(gravity.dx(0.0), 0.0);

    // Starts at 100
    expect(gravity.x(0.25), 106.25);
    expect(gravity.x(0.50), 125);
    expect(gravity.x(0.75), 156.25);
    expect(gravity.x(1.00), 200);
    expect(gravity.x(1.25), 256.25);
    expect(gravity.x(1.50), 325);
    expect(gravity.x(1.75), 406.25);

    // Starts at 0.0
    expect(gravity.dx(0.25), 50.0);
    expect(gravity.dx(0.50), 100);
    expect(gravity.dx(0.75), 150.00);
    expect(gravity.dx(1.00), 200.0);
    expect(gravity.dx(1.25), 250.0);
    expect(gravity.dx(1.50), 300);
    expect(gravity.dx(1.75), 350);

    expect(gravity.isDone(2.5), true);
    expect(gravity.x(2.5), 725);
    expect(gravity.dx(2.5), 500.0);
  });
}

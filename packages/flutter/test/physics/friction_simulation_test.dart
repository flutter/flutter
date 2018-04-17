// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

const double _kEpsilon = .00001;

void main() {
  test('Friction simulation positive velocity', () {
    final FrictionSimulation friction = new FrictionSimulation(0.135, 100.0, 100.0);

    expect(friction.x(0.0), closeTo(100.0, _kEpsilon));
    expect(friction.dx(0.0), closeTo(100.0, _kEpsilon));

    expect(friction.x(0.1), closeTo(110.0, 1.0));
    expect(friction.x(0.5), closeTo(131.0, 1.0));
    expect(friction.x(2.0), closeTo(149.0, 1.0));

    expect(friction.finalX, closeTo(149.0, 1.0));

    expect(friction.timeAtX(100.0), 0.0);
    expect(friction.timeAtX(friction.x(0.1)), closeTo(0.1, _kEpsilon));
    expect(friction.timeAtX(friction.x(0.5)), closeTo(0.5, _kEpsilon));
    expect(friction.timeAtX(friction.x(2.0)), closeTo(2.0, _kEpsilon));

    expect(friction.timeAtX(-1.0), double.infinity);
    expect(friction.timeAtX(200.0), double.infinity);
  });

  test('Friction simulation negative velocity', () {
    final FrictionSimulation friction = new FrictionSimulation(0.135, 100.0, -100.0);

    expect(friction.x(0.0), closeTo(100.0, _kEpsilon));
    expect(friction.dx(0.0), closeTo(-100.0, _kEpsilon));

    expect(friction.x(0.1), closeTo(91.0, 1.0));
    expect(friction.x(0.5), closeTo(68.0, 1.0));
    expect(friction.x(2.0), closeTo(51.0, 1.0));

    expect(friction.finalX, closeTo(50, 1.0));

    expect(friction.timeAtX(100.0), 0.0);
    expect(friction.timeAtX(friction.x(0.1)), closeTo(0.1, _kEpsilon));
    expect(friction.timeAtX(friction.x(0.5)), closeTo(0.5, _kEpsilon));
    expect(friction.timeAtX(friction.x(2.0)), closeTo(2.0, _kEpsilon));

    expect(friction.timeAtX(101.0), double.infinity);
    expect(friction.timeAtX(40.0), double.infinity);
  });
}

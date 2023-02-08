// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InertialSimulation', () {
    expect(InertialSimulation(position: 12.3, velocity: 45.6), hasOneLineDescription);
    expect(InertialSimulation(position: 12.3, velocity: 45.6).x(0),   12.3);
    expect(InertialSimulation(position: 12.3, velocity: 45.6).x(1),   12.3 + 45.6);
    expect(InertialSimulation(position: 12.3, velocity: 45.6).x(1e3), 45612.3);
    expect(InertialSimulation(position: 12.3, velocity: 45.6).dx(0), 45.6);
    expect(InertialSimulation(position: 12.3, velocity: 45.6).dx(1), 45.6);
    expect(InertialSimulation(position: 12.3, velocity: 45.6).isDone(0),   false);
    expect(InertialSimulation(position: 12.3, velocity: 45.6).isDone(1e9), false);
    expect(InertialSimulation(velocity: 0.0001).isDone(0),   false);
    expect(InertialSimulation(velocity: 0.0001).isDone(1e9), false);
    expect(InertialSimulation().isDone(0), true);
  });

  test('InertialSimulation.zero', () {
    expect(InertialSimulation.zero.x(0),    0.0);
    expect(InertialSimulation.zero.x(1e9),  0.0);
    expect(InertialSimulation.zero.dx(0),   0.0);
    expect(InertialSimulation.zero.dx(1e9), 0.0);
    expect(InertialSimulation.zero.isDone(0),   true);
    expect(InertialSimulation.zero.isDone(1e9), true);
  });
}

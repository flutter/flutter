// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Clamped simulation', () {
    final GravitySimulation gravity = GravitySimulation(9.81, 10.0, 0.0, 0.0);
    final ClampedSimulation clamped = ClampedSimulation(gravity, xMin: 20.0, xMax: 100.0, dxMin: 7.0, dxMax: 11.0);

    expect(clamped.x(0.0), equals(20.0));
    expect(clamped.dx(0.0), equals(7.0));

    expect(clamped.x(100.0), equals(100.0));
    expect(clamped.dx(100.0), equals(11.0));
  });
}

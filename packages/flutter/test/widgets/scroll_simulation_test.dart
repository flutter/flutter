// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('ClampingScrollSimulation has a stable initial conditions', () {
    void checkInitialConditions(double position, double velocity) {
      final ClampingScrollSimulation simulation = ClampingScrollSimulation(position: position, velocity: velocity);
      expect(simulation.x(0.0), closeTo(position, 0.00001));
      expect(simulation.dx(0.0), closeTo(velocity, 0.00001));
    }

    checkInitialConditions(51.0, 2866.91537);
    checkInitialConditions(584.0, 2617.294734);
    checkInitialConditions(345.0, 1982.785934);
    checkInitialConditions(0.0, 1831.366634);
    checkInitialConditions(-156.2, 1541.57665);
    checkInitialConditions(4.0, 1139.250439);
    checkInitialConditions(4534.0, 1073.553798);
    checkInitialConditions(75.0, 614.2093);
    checkInitialConditions(5469.0, 182.114534);
  });
}

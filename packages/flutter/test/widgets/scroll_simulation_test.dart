// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ClampingScrollSimulation has a stable initial conditions', () {
    void checkInitialConditions(double position, double velocity) {
      final ClampingScrollSimulation simulation = ClampingScrollSimulation(position: position, velocity: velocity);
      expect(simulation.x(0.0), moreOrLessEquals(position));
      expect(simulation.dx(0.0), moreOrLessEquals(velocity));
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

  test('ClampingScrollSimulation velocity eventually reaches zero', () {
    void checkFinalConditions(double position, double velocity) {
      final ClampingScrollSimulation simulation = ClampingScrollSimulation(position: position, velocity: velocity);
      expect(simulation.dx(10.0), equals(0.0));
    }

    checkFinalConditions(51.0, 2000.0);
    checkFinalConditions(584.0, 2617.294734);
    checkFinalConditions(345.0, 1982.785934);
    checkFinalConditions(0.0, 1831.366634);
    checkFinalConditions(-156.2, 1541.57665);
    checkFinalConditions(4.0, 1139.250439);
    checkFinalConditions(4534.0, 1073.553798);
    checkFinalConditions(75.0, 614.2093);
    checkFinalConditions(5469.0, 182.114534);
  });
}

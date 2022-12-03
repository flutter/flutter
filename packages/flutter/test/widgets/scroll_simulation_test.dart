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

  test('PageScrollSimulation', () {
    void checkSimulation(double position, double target, double duration) {
      final double delta = target - position;
      final PageScrollSimulation simulation = PageScrollSimulation(position: position, target: target, duration: duration);
      late double lastX;
      late double lastDx;
      void expectX(double t, dynamic expectedValue) {
        final double x = simulation.x(t);
        expect(x, expectedValue);
        lastX = x;
      }
      void expectDx(double t, dynamic expectedValue) {
        final double dx = simulation.dx(t);
        expect(dx, expectedValue);
        lastDx = dx;
      }

      // verify start values
      expectX(0.0, position);
      expectDx(0.0, moreOrLessEquals(5 * delta));
      expect(simulation.isDone(0.0), false);

      // verify intermediate values change monotonically
      for (double t = 0.01; t < duration; t += 1) {
        expectX(t, target > position ? greaterThan(lastX) : lessThan(lastX));
        expectDx(t, target > position ? lessThan(lastDx) : greaterThan(lastDx));
        expect(simulation.isDone(t), false);
      }

      // verify end values
      expectX(duration, target);
      expectDx(duration, 0.0);
      expect(simulation.isDone(duration), true);
    }

    checkSimulation(0, 500, 1000);
    checkSimulation(0, -500, 1000);
    checkSimulation(1000, 5000, 100);
    checkSimulation(100, -5000, 100);
  });
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'velocity_tracker_data.dart';

bool _withinTolerance(double actual, double expected) {
  const double kTolerance = 0.001; // Within .1% of expected value
  final double diff = (actual - expected)/expected;
  return diff.abs() < kTolerance;
}

bool _checkVelocity(Velocity actual, Offset expected) {
  return (actual != null)
      && _withinTolerance(actual.pixelsPerSecond.dx, expected.dx)
      && _withinTolerance(actual.pixelsPerSecond.dy, expected.dy);
}

void main() {
  const List<Offset> expected = <Offset>[
    Offset(219.5762939453125, 1304.6705322265625),
    Offset(355.6900939941406, 967.1700439453125),
    Offset(12.651158332824707, -36.9227180480957),
    Offset(714.1383056640625, -2561.540283203125),
    Offset(-19.658065795898438, -2910.080322265625),
    Offset(646.8700561523438, 2976.982421875),
    Offset(396.6878967285156, 2106.204833984375),
    Offset(298.3150634765625, -3660.821044921875),
    Offset(-1.7460877895355225, -3288.16162109375),
    Offset(384.6415710449219, -2645.6484375),
    Offset(176.3752899169922, 2711.24609375),
    Offset(396.9254455566406, 4280.640625),
    Offset(-71.51288604736328, 3716.74560546875),
  ];

  test('Velocity tracker gives expected results', () {
    final VelocityTracker tracker = VelocityTracker();
    int i = 0;
    for (PointerEvent event in velocityEventData) {
      if (event is PointerDownEvent || event is PointerMoveEvent)
        tracker.addPosition(event.timeStamp, event.position);
      if (event is PointerUpEvent) {
        _checkVelocity(tracker.getVelocity(), expected[i]);
        i += 1;
      }
    }
  });

  test('Velocity control test', () {
    const Velocity velocity1 = Velocity(pixelsPerSecond: Offset(7.0, 0.0));
    const Velocity velocity2 = Velocity(pixelsPerSecond: Offset(12.0, 0.0));
    expect(velocity1, equals(const Velocity(pixelsPerSecond: Offset(7.0, 0.0))));
    expect(velocity1, isNot(equals(velocity2)));
    expect(velocity2 - velocity1, equals(const Velocity(pixelsPerSecond: Offset(5.0, 0.0))));
    expect((-velocity1).pixelsPerSecond, const Offset(-7.0, 0.0));
    expect(velocity1 + velocity2, equals(const Velocity(pixelsPerSecond: Offset(19.0, 0.0))));
    expect(velocity1.hashCode, isNot(equals(velocity2.hashCode)));
    expect(velocity1, hasOneLineDescription);
  });

  test('Interrupted velocity estimation', () {
    // Regression test for https://github.com/flutter/flutter/pull/7510
    final VelocityTracker tracker = VelocityTracker();
    for (PointerEvent event in interruptedVelocityEventData) {
      if (event is PointerDownEvent || event is PointerMoveEvent)
        tracker.addPosition(event.timeStamp, event.position);
      if (event is PointerUpEvent) {
        _checkVelocity(tracker.getVelocity(), const Offset(649.5, 3890.3));
      }
    }
  });

  test('No data velocity estimation', () {
    final VelocityTracker tracker = VelocityTracker();
    expect(tracker.getVelocity(), Velocity.zero);
  });
}

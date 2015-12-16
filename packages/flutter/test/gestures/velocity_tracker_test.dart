// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:test/test.dart';
import 'velocity_tracker_data.dart';

bool _withinTolerance(double actual, double expected) {
  const double kTolerance = 0.001; // Within .1% of expected value
  double diff = (actual - expected)/expected;
  return diff.abs() < kTolerance;
}

bool _checkVelocity(Offset actual, Offset expected) {
  return (actual != null)
      && _withinTolerance(actual.dx, expected.dx)
      && _withinTolerance(actual.dy, expected.dy);
}

void main() {
  List<Offset> expected = const <Offset>[
    const Offset(219.5762939453125, 1304.6705322265625),
    const Offset(355.6900939941406, 967.1700439453125),
    const Offset(12.651158332824707, -36.9227180480957),
    const Offset(714.1383056640625, -2561.540283203125),
    const Offset(-19.658065795898438, -2910.080322265625),
    const Offset(646.8700561523438, 2976.982421875),
    const Offset(396.6878967285156, 2106.204833984375),
    const Offset(298.3150634765625, -3660.821044921875),
    const Offset(-1.7460877895355225, -3288.16162109375),
    const Offset(384.6415710449219, -2645.6484375),
    const Offset(176.3752899169922, 2711.24609375),
    const Offset(396.9254455566406, 4280.640625),
    const Offset(-71.51288604736328, 3716.74560546875),
  ];

  test('Velocity tracker gives expected results', () {
    VelocityTracker tracker = new VelocityTracker();
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
}

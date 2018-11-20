// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'gesture_tester.dart';

void main() {
  setUp(ensureGestureBinding);

  testGesture('A force press can be recognized', (GestureTester tester) {
    final ForcePressGestureRecognizer force = ForcePressGestureRecognizer();

    // Device specific constants that represent those from the iPhone X
    const double pressureMin = 0;
    const double pressureMax = 6.66;

    // Interpolated Flutter pressure values.
    const double startPressure = 0.4; // = Device pressure of 2.66.
    const double peakPressure = 0.85; // = Device pressure of 5.66.

    int started = 0;
    int peaked = 0;
    int updated = 0;
    int ended = 0;

    force.onStart = (_) => started += 1;
    force.onPeak = (_) => peaked += 1;
    force.onUpdate = (_) => updated += 1;
    force.onEnd = (_) => ended += 1;
    force.startPressure = startPressure;
    force.peakPressure = peakPressure;

    final TestPointer pointer = TestPointer(1);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0), pressure: 0, pressureMin: pressureMin, pressureMax: pressureMax);

    force.addPointer(down);
    tester.closeArena(1);

    expect(started, 0);
    expect(peaked, 0);
    expect(updated, 0);
    expect(ended, 0);

    // Pressure fed into the test environment simulates the values received directly from the device.
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 2.5, pressureMin: pressureMin, pressureMax: pressureMax));

    // We have not hit the start pressure, so no events should be true.
    expect(started, 0);
    expect(peaked, 0);
    expect(updated, 0);
    expect(ended, 0);

    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 2.8, pressureMin: pressureMin, pressureMax: pressureMax));

    // We have just hit the start pressure so just the start event should be triggered and one update call should have occurred.
    expect(started, 1);
    expect(peaked, 0);
    expect(updated, 1);
    expect(ended, 0);

    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 3.3, pressureMin: pressureMin, pressureMax: pressureMax));
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 4.0, pressureMin: pressureMin, pressureMax: pressureMax));
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 5.0, pressureMin: pressureMin, pressureMax: pressureMax));
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 1.0, pressureMin: pressureMin, pressureMax: pressureMax));

    // We have exceeded the start pressure so update should be greater than 0.
    expect(started, 1);
    expect(updated, 5);
    expect(peaked, 0);
    expect(ended, 0);

    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 6.0, pressureMin: pressureMin, pressureMax: pressureMax));

    // We have exceeded the peak pressure so peak pressure should be true.
    expect(started, 1);
    expect(updated, 6);
    expect(peaked, 1);
    expect(ended, 0);

    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 3.3, pressureMin: pressureMin, pressureMax: pressureMax));
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 4.0, pressureMin: pressureMin, pressureMax: pressureMax));
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 5.0, pressureMin: pressureMin, pressureMax: pressureMax));
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 1.0, pressureMin: pressureMin, pressureMax: pressureMax));

    // Update is still called.
    expect(started, 1);
    expect(updated, 10);
    expect(peaked, 1);
    expect(ended, 0);

    tester.route(pointer.up());

    // We have ended the gesture so ended should be true.
    expect(started, 1);
    expect(updated, 10);
    expect(peaked, 1);
    expect(ended, 1);
  });

  testGesture('If minimum pressure is not reached, start and end callbacks are not called', (GestureTester tester) {
    final ForcePressGestureRecognizer force = ForcePressGestureRecognizer();

    // Device specific constants that represent those from the iPhone X
    const double pressureMin = 0;
    const double pressureMax = 6.66;

    // Interpolated Flutter pressure values.
    const double startPressure = 0.4; // = Device pressure of 2.66.
    const double peakPressure = 0.85; // = Device pressure of 5.66.

    int started = 0;
    int peaked = 0;
    int updated = 0;
    int ended = 0;

    force.onStart = (_) => started += 1;
    force.onPeak = (_) => peaked += 1;
    force.onUpdate = (_) => updated += 1;
    force.onEnd = (_) => ended += 1;
    force.startPressure = startPressure;
    force.peakPressure = peakPressure;

    final TestPointer pointer = TestPointer(1);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0), pressure: 0, pressureMin: pressureMin, pressureMax: pressureMax);

    force.addPointer(down);
    tester.closeArena(1);

    expect(started, 0);
    expect(peaked, 0);
    expect(updated, 0);
    expect(ended, 0);

    // Pressure fed into the test environment simulates the values received directly from the device.
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 2.5, pressureMin: pressureMin, pressureMax: pressureMax));

    // We have not hit the start pressure, so no events should be true.
    expect(started, 0);
    expect(peaked, 0);
    expect(updated, 0);
    expect(ended, 0);

    tester.route(pointer.up());

    expect(started, 0);
    expect(peaked, 0);
    expect(updated, 0);
    expect(ended, 0);
  });

  testGesture('Should recognize drag and not force touch if there is a drag recognizer', (GestureTester tester) {
    final ForcePressGestureRecognizer force = ForcePressGestureRecognizer();
    final PanGestureRecognizer drag = PanGestureRecognizer();

    // Device specific constants that represent those from the iPhone X
    const double pressureMin = 0;
    const double pressureMax = 6.66;

    // Interpolated Flutter pressure values.
    const double startPressure = 0.4; // = Device pressure of 2.66.
    const double peakPressure = 0.85; // = Device pressure of 5.66.

    bool started = false;
    bool peaked = false;
    int updated = 0;
    bool ended = false;

    force.onStart = (_) => started = true;
    force.onPeak = (_) => peaked = true;
    force.onUpdate = (_) => updated += 1;
    force.onEnd = (_) => ended = true;
    force.startPressure = startPressure;
    force.peakPressure = peakPressure;

    bool didStartPan = false;
    drag.onStart = (_) => didStartPan = true;

    final TestPointer pointer = TestPointer(1);
    final PointerDownEvent down = pointer.down(const Offset(10.0, 10.0), pressure: 1.0, pressureMin: pressureMin, pressureMax: pressureMax);

    force.addPointer(down);
    drag.addPointer(down);
    tester.closeArena(1);

    expect(started, false);
    expect(peaked, false);
    expect(updated, 0);
    expect(ended, false);
    expect(didStartPan, false);

    tester.route(pointer.move(const Offset(30.0, 30.0))); // moved 20 horizontally and 20 vertically which is 28 total

    expect(started, false);
    expect(peaked, false);
    expect(updated, 0);
    expect(ended, false);
    expect(didStartPan, true);

    // Pressure fed into the test environment simulates the values received directly from the device.
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 2.5, pressureMin: pressureMin, pressureMax: pressureMax));

    // We have not hit the start pressure, so no events should be true.
    expect(started, false);
    expect(peaked, false);
    expect(updated, 0);
    expect(ended, false);
    expect(didStartPan, true);

    // We don't expect any events from the force press recognizer.
    tester.route(pointer.move(const Offset(10.0, 10.0), pressure: 4.0, pressureMin: pressureMin, pressureMax: pressureMax));

    expect(started, false);
    expect(peaked, false);
    expect(updated, 0);
    expect(ended, false);
    expect(didStartPan, true);

    tester.route(pointer.up());

    expect(started, false);
    expect(peaked, false);
    expect(updated, 0);
    expect(ended, false);
    expect(didStartPan, true);
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Use different timebases to flush ongoing event', (WidgetTester tester) async {
    Duration currentTestFrameTime() => SchedulerBinding.instance!.currentSystemFrameTimeStamp;
    void requestFrame() => SchedulerBinding.instance!.scheduleFrameCallback((_) {});
    final Duration systemUpTime = currentTestFrameTime();

    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.down,
          timeStamp: systemUpTime + const Duration(milliseconds: 20),
        ),
      ],
    );

    // An event should have been dispatched when resampling successfully.
    final List<PointerEvent> events = <PointerEvent>[];
    GestureBinding.instance!.pointerRouter.addGlobalRoute((PointerEvent event) {
      events.add(event);
    });

    GestureBinding.instance!.resamplingEnabled = true;

    // Send a down event to mock ongoing event.
    await tester.pump(const Duration(milliseconds: 20));
    ui.window.onPointerDataPacket!(packet);

    // Send a cancel event with since epoch timebase to flush the ongoing event.
    requestFrame();
    await tester.pump(const Duration(milliseconds: 20));
    events.clear();
    final ui.PointerDataPacket sinceEpochPacket = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          timeStamp: Duration(microseconds: DateTime.now().microsecondsSinceEpoch),
        ),
      ],
    );
    ui.window.onPointerDataPacket!(sinceEpochPacket);

    // Flush failed, no events dispatched, the timer has not yet been canceled.
    requestFrame();
    await tester.pump(const Duration(milliseconds: 100));
    expect(events.isEmpty , true);

    // Stop resampling, cancel the resampling timer.
    GestureBinding.instance!.resamplingEnabled = false;
    requestFrame();
    await tester.pump(const Duration(milliseconds: 20));

    GestureBinding.instance!.resamplingEnabled = true;

    // Send a down event to mock ongoing event again.
    await tester.pump(const Duration(milliseconds: 20));
    ui.window.onPointerDataPacket!(packet);

    // Send a cancel event with system startup timebase to flush the ongoing event.
    requestFrame();
    await tester.pump(const Duration(milliseconds: 20));
    events.clear();
    final Duration timeStamp = systemUpTime + const Duration(milliseconds: 40);
    final ui.PointerDataPacket systemUpPacket = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          timeStamp: timeStamp,
        ),
      ],
    );
    ui.window.onPointerDataPacket!(systemUpPacket);

    // Flush successfully, and a resampling event has been dispatched.
    requestFrame();
    await tester.pump(const Duration(milliseconds: 100));
    expect(events.length == 1, true);
    expect(events[0].timeStamp.inMicroseconds >= timeStamp.inMicroseconds, true);

    GestureBinding.instance!.resamplingEnabled = false;
  });
}

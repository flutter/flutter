// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = AutomatedTestWidgetsFlutterBinding();
  testWidgets('An event with system startup timestamp canceled the down event successfully', (WidgetTester tester) async {
    assert(WidgetsBinding.instance == binding);
    Duration currentTestFrameTime() => SchedulerBinding.instance!.currentSystemFrameTimeStamp;
    void requestFrame() => SchedulerBinding.instance!.scheduleFrameCallback((_) {});

    GestureBinding.instance!.resamplingEnabled = true;

    // Send a down event
    await tester.pump(const Duration(milliseconds: 10));
    final Duration systemUpTime = currentTestFrameTime();
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(
            change: ui.PointerChange.down,
            timeStamp: systemUpTime + const Duration(milliseconds: 10),
          ),
        ]);
    ui.window.onPointerDataPacket!(packet);

    // Send a cancel event
    requestFrame();
    await tester.pump(const Duration(milliseconds: 10));
    PointerEvent? sampleEvent;
    GestureBinding.instance!.pointerRouter.addGlobalRoute((PointerEvent event) {
      sampleEvent = event;
    });
    final Duration timeStamp = systemUpTime + const Duration(milliseconds: 20);
    ui.window.onPointerDataPacket!(ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          timeStamp: timeStamp,
        ),
      ],),);

    // The down event has been canceled successfully
    requestFrame();
    await tester.pump(const Duration(milliseconds: 200));
    expect(sampleEvent != null && sampleEvent!.timeStamp.inMicroseconds > timeStamp.inMicroseconds, true);

    GestureBinding.instance!.resamplingEnabled = false;
  });

  testWidgets('An event with since epoch timestamp failed to cancle the down event', (WidgetTester tester) async {
    assert(WidgetsBinding.instance == binding);
    Duration currentTestFrameTime() => SchedulerBinding.instance!.currentSystemFrameTimeStamp;
    void requestFrame() => SchedulerBinding.instance!.scheduleFrameCallback((_) {});

    GestureBinding.instance!.resamplingEnabled = true;

    // Send a down event
    await tester.pump(const Duration(milliseconds: 10));
    final Duration systemUpTime = currentTestFrameTime();
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(
            change: ui.PointerChange.down,
            timeStamp: systemUpTime + const Duration(milliseconds: 10),
          ),
        ]);
    ui.window.onPointerDataPacket!(packet);

    // Send a cancel event
    requestFrame();
    await tester.pump(const Duration(milliseconds: 10));
    PointerEvent? sampleEvent;
    GestureBinding.instance!.pointerRouter.addGlobalRoute((PointerEvent event) {
      sampleEvent = event;
    });
    final Duration timeStamp = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    ui.window.onPointerDataPacket!(ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          timeStamp: timeStamp,
        ),
      ],),);

    // The down event cancel failed
    requestFrame();
    await tester.pump(const Duration(milliseconds: 200));
    expect(sampleEvent == null , true);

    GestureBinding.instance!.resamplingEnabled = false;
  });
}

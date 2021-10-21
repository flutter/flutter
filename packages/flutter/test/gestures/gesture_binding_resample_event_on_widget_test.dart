// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestResampleEventFlutterBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  SamplingClock? get debugSamplingClock => TestSamplingClock(this.clock);
}

class TestSamplingClock implements SamplingClock {
  TestSamplingClock(this._clock);

  @override
  DateTime now() => _clock.now();

  @override
  Stopwatch stopwatch() => _clock.stopwatch();

  final Clock _clock;
}

void main() {
  final TestWidgetsFlutterBinding binding = TestResampleEventFlutterBinding();
  testWidgets('PointerEvent resampling on a widget', (WidgetTester tester) async {
    assert(WidgetsBinding.instance == binding);
    Duration currentTestFrameTime() => Duration(milliseconds: binding.clock.now().millisecondsSinceEpoch);
    void requestFrame() => SchedulerBinding.instance!.scheduleFrameCallback((_) {});
    final Duration epoch = currentTestFrameTime();
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
            change: ui.PointerChange.add,
            timeStamp: epoch,
        ),
        ui.PointerData(
            change: ui.PointerChange.down,
            timeStamp: epoch,
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 15.0,
            timeStamp: epoch + const Duration(milliseconds: 10),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 30.0,
            timeStamp: epoch + const Duration(milliseconds: 20),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 45.0,
            timeStamp: epoch + const Duration(milliseconds: 30),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 50.0,
            timeStamp: epoch + const Duration(milliseconds: 40),
        ),
        ui.PointerData(
            change: ui.PointerChange.up,
            physicalX: 60.0,
            timeStamp: epoch + const Duration(milliseconds: 40),
        ),
        ui.PointerData(
            change: ui.PointerChange.remove,
            physicalX: 60.0,
            timeStamp: epoch + const Duration(milliseconds: 40),
        ),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Listener(
          onPointerDown: (PointerDownEvent event) => events.add(event),
          onPointerMove: (PointerMoveEvent event) => events.add(event),
          onPointerUp: (PointerUpEvent event) => events.add(event),
          child: const Text('test'),
        ),
      ),
    );

    GestureBinding.instance!.resamplingEnabled = true;
    const Duration kSamplingOffset = Duration(milliseconds: -5);
    GestureBinding.instance!.samplingOffset = kSamplingOffset;
    ui.window.onPointerDataPacket!(packet);
    expect(events.length, 0);

    requestFrame();
    await tester.pump(const Duration(milliseconds: 10));
    expect(events.length, 1);
    expect(events[0], isA<PointerDownEvent>());
    expect(events[0].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[0].position, Offset(7.5 / ui.window.devicePixelRatio, 0.0));

    // Now the system time is epoch + 20ms
    requestFrame();
    await tester.pump(const Duration(milliseconds: 10));
    expect(events.length, 2);
    expect(events[1].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[1], isA<PointerMoveEvent>());
    expect(events[1].position, Offset(22.5 / ui.window.devicePixelRatio, 0.0));
    expect(events[1].delta, Offset(15.0 / ui.window.devicePixelRatio, 0.0));

    // Now the system time is epoch + 30ms
    requestFrame();
    await tester.pump(const Duration(milliseconds: 10));
    expect(events.length, 4);
    expect(events[2].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[2], isA<PointerMoveEvent>());
    expect(events[2].position, Offset(37.5 / ui.window.devicePixelRatio, 0.0));
    expect(events[2].delta, Offset(15.0 / ui.window.devicePixelRatio, 0.0));
    expect(events[3].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[3], isA<PointerUpEvent>());
  });
}

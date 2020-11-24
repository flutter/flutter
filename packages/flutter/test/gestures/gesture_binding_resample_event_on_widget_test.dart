// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logically this file should be part of `gesture_binding_test.dart` but is here
// due to conflict of `flutter_test` and `package:test`.
// See https://github.com/dart-lang/matcher/issues/98
// TODO(CareF): Consider combine this file back to `gesture_binding_test.dart`
// after #98 is fixed.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = AutomatedTestWidgetsFlutterBinding();
  testWidgets('PointerEvent resampling on a widget', (WidgetTester tester) async {
    assert(WidgetsBinding.instance == binding);
    Duration currentTestFrameTime() => Duration(milliseconds: binding.clock.now().millisecondsSinceEpoch);
    final Duration epoch = currentTestFrameTime();
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
            change: ui.PointerChange.add,
            physicalX: 0.0,
            timeStamp: epoch + const Duration(milliseconds: 0),
        ),
        ui.PointerData(
            change: ui.PointerChange.down,
            physicalX: 0.0,
            timeStamp: epoch + const Duration(milliseconds: 10),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 10.0,
            timeStamp: epoch + const Duration(milliseconds: 20),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 20.0,
            timeStamp: epoch + const Duration(milliseconds: 30),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 30.0,
            timeStamp: epoch + const Duration(milliseconds: 40),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 40.0,
            timeStamp: epoch + const Duration(milliseconds: 50),
        ),
        ui.PointerData(
            change: ui.PointerChange.up,
            physicalX: 40.0,
            timeStamp: epoch + const Duration(milliseconds: 60),
        ),
        ui.PointerData(
            change: ui.PointerChange.remove,
            physicalX: 40.0,
            timeStamp: epoch + const Duration(milliseconds: 70),
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

    await tester.pump(const Duration(milliseconds: 20));
    expect(events.length, 1);
    expect(events[0], isA<PointerDownEvent>());
    expect(events[0].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[0].position, Offset(5.0 / ui.window.devicePixelRatio, 0.0));

    // Now the system time is epoch + 40ms
    await tester.pump(const Duration(milliseconds: 20));
    expect(events.length, 2);
    expect(events[1].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[1], isA<PointerMoveEvent>());
    expect(events[1].position, Offset(25.0 / ui.window.devicePixelRatio, 0.0));
    expect(events[1].delta, Offset(20.0 / ui.window.devicePixelRatio, 0.0));

    // Now the system time is epoch + 60ms
    await tester.pump(const Duration(milliseconds: 20));
    expect(events.length, 4);
    expect(events[2].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[2], isA<PointerMoveEvent>());
    expect(events[2].position, Offset(40.0 / ui.window.devicePixelRatio, 0.0));
    expect(events[2].delta, Offset(15.0 / ui.window.devicePixelRatio, 0.0));
    expect(events[3].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[3], isA<PointerUpEvent>());
    expect(events[3].position, Offset(40.0 / ui.window.devicePixelRatio, 0.0));
  });
}

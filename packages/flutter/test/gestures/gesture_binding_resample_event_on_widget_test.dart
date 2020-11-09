// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

// Logically this file should be part of `gesture_binding_test.dart` but is here
// due to conflict of `flutter_test` and `package:test`.
// See https://github.com/dart-lang/matcher/issues/98
// TODO(CareF): Consider combine this file back to `gesture_binding_test.dart`
// after #98 is fixed.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class PointerDataAutomatedTestWidgetsFlutterBinding extends AutomatedTestWidgetsFlutterBinding {
  // PointerData injection would usually considerred device input and therefore
  // blocked by [AutomatedTestWidgetsFlutterBinding]. Override this behavior
  // to help events go into widget tree.
  @override
  void dispatchEvent(
    PointerEvent event,
    HitTestResult hitTestResult, {
    TestBindingEventSource source = TestBindingEventSource.device,
  }) {
    super.dispatchEvent(event, hitTestResult, source: TestBindingEventSource.test);
  }
}

void main() {
  final TestWidgetsFlutterBinding binding = PointerDataAutomatedTestWidgetsFlutterBinding();
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
            timeStamp: epoch + const Duration(milliseconds: 1),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 10.0,
            timeStamp: epoch + const Duration(milliseconds: 2),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 20.0,
            timeStamp: epoch + const Duration(milliseconds: 3),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 30.0,
            timeStamp: epoch + const Duration(milliseconds: 4),
        ),
        ui.PointerData(
            change: ui.PointerChange.up,
            physicalX: 40.0,
            timeStamp: epoch + const Duration(milliseconds: 5),
        ),
        ui.PointerData(
            change: ui.PointerChange.remove,
            physicalX: 40.0,
            timeStamp: epoch + const Duration(milliseconds: 6),
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

    GestureBinding.instance.resamplingEnabled = true;
    const Duration kSamplingOffset = Duration(microseconds: -5500);
    GestureBinding.instance.samplingOffset = kSamplingOffset;
    ui.window.onPointerDataPacket(packet);
    expect(events.length, 0);

    await tester.pump(const Duration(milliseconds: 7));
    expect(events.length, 1);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[0].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[0].position, Offset(5.0 / ui.window.devicePixelRatio, 0.0));

    // Now the system time is epoch + 9ms
    await tester.pump(const Duration(milliseconds: 2));
    expect(events.length, 2);
    expect(events[1].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[1].position, Offset(25.0 / ui.window.devicePixelRatio, 0.0));
    expect(events[1].delta, Offset(20.0 / ui.window.devicePixelRatio, 0.0));

    // Now the system time is epoch + 11ms
    await tester.pump(const Duration(milliseconds: 2));
    expect(events.length, 3);
    expect(events[2].timeStamp, currentTestFrameTime() + kSamplingOffset);
    expect(events[2].runtimeType, equals(PointerUpEvent));
    expect(events[2].position, Offset(40.0 / ui.window.devicePixelRatio, 0.0));
  });
}

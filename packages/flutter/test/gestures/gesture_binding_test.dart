// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding, SchedulerBinding {
  HandleEventCallback callback;
  FrameCallback frameCallback;
  Duration frameTime;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (callback != null)
      callback(event);
  }

  @override
  Duration get currentSystemFrameTimeStamp {
    assert(frameTime != null);
    return frameTime;
  }

  @override
  int scheduleFrameCallback(FrameCallback callback, {bool rescheduling = false}) {
    frameCallback = callback;
    return 0;
  }
}

TestGestureFlutterBinding _binding = TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  _binding ??= TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
  assert(SchedulerBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  test('Pointer tap events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.up),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer move events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.move),
        ui.PointerData(change: ui.PointerChange.up),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 3);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[2].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer hover events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add),
          ui.PointerData(change: ui.PointerChange.hover),
          ui.PointerData(change: ui.PointerChange.hover),
          ui.PointerData(change: ui.PointerChange.remove),
          ui.PointerData(change: ui.PointerChange.add),
          ui.PointerData(change: ui.PointerChange.hover),
        ],
    );

    final List<PointerEvent> pointerRouterEvents = <PointerEvent>[];
    GestureBinding.instance.pointerRouter.addGlobalRoute(pointerRouterEvents.add);

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 0);
    expect(pointerRouterEvents.length, 6,
        reason: 'pointerRouterEvents contains: $pointerRouterEvents');
    expect(pointerRouterEvents[0].runtimeType, equals(PointerAddedEvent));
    expect(pointerRouterEvents[1].runtimeType, equals(PointerHoverEvent));
    expect(pointerRouterEvents[2].runtimeType, equals(PointerHoverEvent));
    expect(pointerRouterEvents[3].runtimeType, equals(PointerRemovedEvent));
    expect(pointerRouterEvents[4].runtimeType, equals(PointerAddedEvent));
    expect(pointerRouterEvents[5].runtimeType, equals(PointerHoverEvent));
  });

  test('Pointer cancel events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.cancel),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });

  test('Can cancel pointers', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.up),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = (PointerEvent event) {
      events.add(event);
      if (event is PointerDownEvent)
        _binding.cancelPointer(event.pointer);
    };

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerCancelEvent));
  });

  test('Can expand add and hover pointers', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.add, device: 24),
        ui.PointerData(change: ui.PointerChange.hover, device: 24),
        ui.PointerData(change: ui.PointerChange.remove, device: 24),
        ui.PointerData(change: ui.PointerChange.add, device: 24),
        ui.PointerData(change: ui.PointerChange.hover, device: 24),
      ],
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 5);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[2].runtimeType, equals(PointerRemovedEvent));
    expect(events[3].runtimeType, equals(PointerAddedEvent));
    expect(events[4].runtimeType, equals(PointerHoverEvent));
  });

  test('Can expand pointer scroll events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add),
          ui.PointerData(change: ui.PointerChange.hover, signalKind: ui.PointerSignalKind.scroll),
        ],
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerScrollEvent));
  });

  test('Should synthesize kPrimaryButton for touch', () {
    final Offset location = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    const PointerDeviceKind kind = PointerDeviceKind.touch;
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.add, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.hover, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.down, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.move, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.up, kind: kind, physicalX: location.dx, physicalY: location.dy),
      ],
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 5);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[0].buttons, equals(0));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[1].buttons, equals(0));
    expect(events[2].runtimeType, equals(PointerDownEvent));
    expect(events[2].buttons, equals(kPrimaryButton));
    expect(events[3].runtimeType, equals(PointerMoveEvent));
    expect(events[3].buttons, equals(kPrimaryButton));
    expect(events[4].runtimeType, equals(PointerUpEvent));
    expect(events[4].buttons, equals(0));
  });

  test('Should synthesize kPrimaryButton for stylus', () {
    final Offset location = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    for (final PointerDeviceKind kind in <PointerDeviceKind>[
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
    ]) {

      final ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.hover, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.down, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.move, buttons: kSecondaryStylusButton, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.up, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ],
      );

      final List<PointerEvent> events = PointerEventConverter.expand(
        packet.data, ui.window.devicePixelRatio).toList();

      expect(events.length, 5);
      expect(events[0].runtimeType, equals(PointerAddedEvent));
      expect(events[0].buttons, equals(0));
      expect(events[1].runtimeType, equals(PointerHoverEvent));
      expect(events[1].buttons, equals(0));
      expect(events[2].runtimeType, equals(PointerDownEvent));
      expect(events[2].buttons, equals(kPrimaryButton));
      expect(events[3].runtimeType, equals(PointerMoveEvent));
      expect(events[3].buttons, equals(kPrimaryButton | kSecondaryStylusButton));
      expect(events[4].runtimeType, equals(PointerUpEvent));
      expect(events[4].buttons, equals(0));
    }
  });

  test('Should synthesize kPrimaryButton for unknown devices', () {
    final Offset location = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    const PointerDeviceKind kind = PointerDeviceKind.unknown;
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.add, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.hover, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.down, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.move, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.up, kind: kind, physicalX: location.dx, physicalY: location.dy),
      ],
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 5);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[0].buttons, equals(0));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[1].buttons, equals(0));
    expect(events[2].runtimeType, equals(PointerDownEvent));
    expect(events[2].buttons, equals(kPrimaryButton));
    expect(events[3].runtimeType, equals(PointerMoveEvent));
    expect(events[3].buttons, equals(kPrimaryButton));
    expect(events[4].runtimeType, equals(PointerUpEvent));
    expect(events[4].buttons, equals(0));
  });

  test('Should not synthesize kPrimaryButton for mouse', () {
    final Offset location = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    for (final PointerDeviceKind kind in <PointerDeviceKind>[
      PointerDeviceKind.mouse,
    ]) {
      final ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.hover, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.down, kind: kind, buttons: kMiddleMouseButton, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.move, kind: kind, buttons: kMiddleMouseButton | kSecondaryMouseButton, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.up, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ],
      );

      final List<PointerEvent> events = PointerEventConverter.expand(
        packet.data, ui.window.devicePixelRatio).toList();

      expect(events.length, 5);
      expect(events[0].runtimeType, equals(PointerAddedEvent));
      expect(events[0].buttons, equals(0));
      expect(events[1].runtimeType, equals(PointerHoverEvent));
      expect(events[1].buttons, equals(0));
      expect(events[2].runtimeType, equals(PointerDownEvent));
      expect(events[2].buttons, equals(kMiddleMouseButton));
      expect(events[3].runtimeType, equals(PointerMoveEvent));
      expect(events[3].buttons, equals(kMiddleMouseButton | kSecondaryMouseButton));
      expect(events[4].runtimeType, equals(PointerUpEvent));
      expect(events[4].buttons, equals(0));
    }
  });

  test('Pointer event resampling', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
            change: ui.PointerChange.add,
            physicalX: 0.0,
            timeStamp: Duration(milliseconds: 0),
        ),
        ui.PointerData(
            change: ui.PointerChange.down,
            physicalX: 0.0,
            timeStamp: Duration(milliseconds: 1),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 10.0,
            timeStamp: Duration(milliseconds: 2),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 20.0,
            timeStamp: Duration(milliseconds: 3),
        ),
        ui.PointerData(
            change: ui.PointerChange.move,
            physicalX: 30.0,
            timeStamp: Duration(milliseconds: 4),
        ),
        ui.PointerData(
            change: ui.PointerChange.up,
            physicalX: 40.0,
            timeStamp: Duration(milliseconds: 5),
        ),
        ui.PointerData(
            change: ui.PointerChange.remove,
            physicalX: 40.0,
            timeStamp: Duration(milliseconds: 6),
        ),
      ],
    );

    final List<PointerEvent> pointerRouterEvents = <PointerEvent>[];
    GestureBinding.instance.pointerRouter.addGlobalRoute(pointerRouterEvents.add);

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    GestureBinding.instance.resamplingEnabled = true;
    GestureBinding.instance.samplingOffset = const Duration(microseconds: -5500);

    ui.window.onPointerDataPacket(packet);

    // No pointer events should have been dispatched yet.
    expect(events.length, 0);

    // Frame callback should have been requested.
    FrameCallback callback = _binding.frameCallback;
    _binding.frameCallback = null;
    expect(callback, isNotNull);

    _binding.frameTime = const Duration(milliseconds: 7);
    callback(Duration.zero);

    // One pointer event should have been dispatched.
    expect(events.length, 1);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[0].timeStamp, _binding.frameTime + GestureBinding.instance.samplingOffset);
    expect(events[0].position, Offset(5.0 / ui.window.devicePixelRatio, 0.0));

    // Second frame callback should have been requested.
    callback = _binding.frameCallback;
    _binding.frameCallback = null;
    expect(callback, isNotNull);

    _binding.frameTime = const Duration(milliseconds: 9);
    callback(Duration.zero);

    // Second pointer event should have been dispatched.
    expect(events.length, 2);
    expect(events[1].timeStamp, _binding.frameTime + GestureBinding.instance.samplingOffset);
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[1].position, Offset(25.0 / ui.window.devicePixelRatio, 0.0));
    expect(events[1].delta, Offset(20.0 / ui.window.devicePixelRatio, 0.0));

    // Third frame callback should have been requested.
    callback = _binding.frameCallback;
    _binding.frameCallback = null;
    expect(callback, isNotNull);

    _binding.frameTime = const Duration(milliseconds: 11);
    callback(Duration.zero);

    // Third pointer event should have been dispatched.
    expect(events.length, 3);
    expect(events[2].timeStamp, _binding.frameTime + GestureBinding.instance.samplingOffset);
    expect(events[2].runtimeType, equals(PointerUpEvent));
    expect(events[2].position, Offset(40.0 / ui.window.devicePixelRatio, 0.0));

    // No frame callback should have been requested.
    callback = _binding.frameCallback;
    expect(callback, isNull);
  });
}

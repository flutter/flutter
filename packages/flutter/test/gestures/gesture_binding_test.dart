// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (callback != null)
      callback(event);
  }
}

TestGestureFlutterBinding _binding = TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  _binding ??= TestGestureFlutterBinding();
  PointerEventConverter.clearPointers();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  test('Pointer tap events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.up),
      ]
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
      ]
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
          ui.PointerData(change: ui.PointerChange.hover),
          ui.PointerData(change: ui.PointerChange.hover),
          ui.PointerData(change: ui.PointerChange.remove),
          ui.PointerData(change: ui.PointerChange.hover),
        ]
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

  test('Synthetic move events', () {
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.down,
          physicalX: 1.0 * ui.window.devicePixelRatio,
          physicalY: 3.0 * ui.window.devicePixelRatio,
        ),
        ui.PointerData(
          change: ui.PointerChange.up,
          physicalX: 10.0 * ui.window.devicePixelRatio,
          physicalY: 15.0 * ui.window.devicePixelRatio,
        ),
      ]
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding.callback = events.add;

    ui.window.onPointerDataPacket(packet);
    expect(events.length, 3);
    expect(events[0].runtimeType, equals(PointerDownEvent));
    expect(events[1].runtimeType, equals(PointerMoveEvent));
    expect(events[1].delta, equals(const Offset(9.0, 12.0)));
    expect(events[2].runtimeType, equals(PointerUpEvent));
  });

  test('Pointer cancel events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.cancel),
      ]
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
      ]
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
        ui.PointerData(change: ui.PointerChange.hover, device: 24),
      ]
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

  test('Synthetic hover and cancel for misplaced down and remove', () {
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.add, device: 25, physicalX: 10.0 * ui.window.devicePixelRatio, physicalY: 10.0 * ui.window.devicePixelRatio),
        ui.PointerData(change: ui.PointerChange.down, device: 25, physicalX: 15.0 * ui.window.devicePixelRatio, physicalY: 17.0 * ui.window.devicePixelRatio),
        const ui.PointerData(change: ui.PointerChange.remove, device: 25),
      ]
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 6);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[1].delta, equals(const Offset(5.0, 7.0)));
    expect(events[2].runtimeType, equals(PointerDownEvent));
    expect(events[3].runtimeType, equals(PointerCancelEvent));
    expect(events[4].runtimeType, equals(PointerHoverEvent));
    expect(events[5].runtimeType, equals(PointerRemovedEvent));
  });

  test('Can expand pointer scroll events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add),
          ui.PointerData(change: ui.PointerChange.hover, signalKind: ui.PointerSignalKind.scroll),
        ]
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 2);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerScrollEvent));
  });

  test('Synthetic hover/move for misplaced scrolls', () {
    final Offset lastLocation = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    const Offset unexpectedOffset = Offset(5.0, 7.0);
    final Offset scrollLocation = lastLocation + unexpectedOffset * ui.window.devicePixelRatio;
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.add, physicalX: lastLocation.dx, physicalY: lastLocation.dy),
        ui.PointerData(change: ui.PointerChange.hover, physicalX: scrollLocation.dx, physicalY: scrollLocation.dy, signalKind: ui.PointerSignalKind.scroll),
        // Move back to starting location, click, and repeat to test mouse-down version.
        ui.PointerData(change: ui.PointerChange.hover, physicalX: lastLocation.dx, physicalY: lastLocation.dy),
        ui.PointerData(change: ui.PointerChange.down, physicalX: lastLocation.dx, physicalY: lastLocation.dy),
        ui.PointerData(change: ui.PointerChange.hover, physicalX: scrollLocation.dx, physicalY: scrollLocation.dy, signalKind: ui.PointerSignalKind.scroll),
      ]
    );

    final List<PointerEvent> events = PointerEventConverter.expand(
      packet.data, ui.window.devicePixelRatio).toList();

    expect(events.length, 7);
    expect(events[0].runtimeType, equals(PointerAddedEvent));
    expect(events[1].runtimeType, equals(PointerHoverEvent));
    expect(events[1].delta, equals(unexpectedOffset));
    expect(events[2].runtimeType, equals(PointerScrollEvent));
    expect(events[3].runtimeType, equals(PointerHoverEvent));
    expect(events[4].runtimeType, equals(PointerDownEvent));
    expect(events[5].runtimeType, equals(PointerMoveEvent));
    expect(events[5].delta, equals(unexpectedOffset));
    expect(events[6].runtimeType, equals(PointerScrollEvent));
  });

  test('Should synthesise kPrimaryButton for touch', () {
    final Offset location = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    const PointerDeviceKind kind = PointerDeviceKind.touch;
    final ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.add, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.hover, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.down, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.move, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ui.PointerData(change: ui.PointerChange.up, kind: kind, physicalX: location.dx, physicalY: location.dy),
      ]
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

    PointerEventConverter.clearPointers();
  });

  test('Should synthesise kPrimaryButton for stylus', () {
    final Offset location = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    for (PointerDeviceKind kind in <PointerDeviceKind>[
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
        ]
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

      PointerEventConverter.clearPointers();
    }
  });

  test('Should not synthesise kPrimaryButton for certain devices', () {
    final Offset location = const Offset(10.0, 10.0) * ui.window.devicePixelRatio;
    for (PointerDeviceKind kind in <PointerDeviceKind>[
      PointerDeviceKind.mouse,
    ]) {
      final ui.PointerDataPacket packet = ui.PointerDataPacket(
        data: <ui.PointerData>[
          ui.PointerData(change: ui.PointerChange.add, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.hover, kind: kind, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.down, kind: kind, buttons: kMiddleMouseButton, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.move, kind: kind, buttons: kMiddleMouseButton | kSecondaryMouseButton, physicalX: location.dx, physicalY: location.dy),
          ui.PointerData(change: ui.PointerChange.up, kind: kind, physicalX: location.dx, physicalY: location.dy),
        ]
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

      PointerEventConverter.clearPointers();
    }
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with GestureBinding, SchedulerBinding {
  HandleEventCallback? callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (callback != null)
      callback?.call(event);
  }
}

TestGestureFlutterBinding? _binding;

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
    _binding!.callback = events.add;

    ui.window.onPointerDataPacket?.call(packet);
    expect(events.length, 2);
    expect(events[0], isA<PointerDownEvent>());
    expect(events[1], isA<PointerUpEvent>());
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
    _binding!.callback = events.add;

    ui.window.onPointerDataPacket?.call(packet);
    expect(events.length, 3);
    expect(events[0], isA<PointerDownEvent>());
    expect(events[1], isA<PointerMoveEvent>());
    expect(events[2], isA<PointerUpEvent>());
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
    GestureBinding.instance!.pointerRouter.addGlobalRoute(pointerRouterEvents.add);

    final List<PointerEvent> events = <PointerEvent>[];
    _binding!.callback = events.add;

    ui.window.onPointerDataPacket?.call(packet);
    expect(events.length, 3);
    expect(events[0], isA<PointerHoverEvent>());
    expect(events[1], isA<PointerHoverEvent>());
    expect(events[2], isA<PointerHoverEvent>());
    expect(pointerRouterEvents.length, 6,
        reason: 'pointerRouterEvents contains: $pointerRouterEvents');
    expect(pointerRouterEvents[0], isA<PointerAddedEvent>());
    expect(pointerRouterEvents[1], isA<PointerHoverEvent>());
    expect(pointerRouterEvents[2], isA<PointerHoverEvent>());
    expect(pointerRouterEvents[3], isA<PointerRemovedEvent>());
    expect(pointerRouterEvents[4], isA<PointerAddedEvent>());
    expect(pointerRouterEvents[5], isA<PointerHoverEvent>());
  });

  test('Pointer cancel events', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.cancel),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding!.callback = events.add;

    ui.window.onPointerDataPacket?.call(packet);
    expect(events.length, 2);
    expect(events[0], isA<PointerDownEvent>());
    expect(events[1], isA<PointerCancelEvent>());
  });

  test('Can cancel pointers', () {
    const ui.PointerDataPacket packet = ui.PointerDataPacket(
      data: <ui.PointerData>[
        ui.PointerData(change: ui.PointerChange.down),
        ui.PointerData(change: ui.PointerChange.up),
      ],
    );

    final List<PointerEvent> events = <PointerEvent>[];
    _binding!.callback = (PointerEvent event) {
      events.add(event);
      if (event is PointerDownEvent)
        _binding!.cancelPointer(event.pointer);
    };

    ui.window.onPointerDataPacket?.call(packet);
    expect(events.length, 2);
    expect(events[0], isA<PointerDownEvent>());
    expect(events[1], isA<PointerCancelEvent>());
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
    expect(events[0], isA<PointerAddedEvent>());
    expect(events[1], isA<PointerHoverEvent>());
    expect(events[2], isA<PointerRemovedEvent>());
    expect(events[3], isA<PointerAddedEvent>());
    expect(events[4], isA<PointerHoverEvent>());
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
    expect(events[0], isA<PointerAddedEvent>());
    expect(events[1], isA<PointerScrollEvent>());
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
    expect(events[0], isA<PointerAddedEvent>());
    expect(events[0].buttons, equals(0));
    expect(events[1], isA<PointerHoverEvent>());
    expect(events[1].buttons, equals(0));
    expect(events[2], isA<PointerDownEvent>());
    expect(events[2].buttons, equals(kPrimaryButton));
    expect(events[3], isA<PointerMoveEvent>());
    expect(events[3].buttons, equals(kPrimaryButton));
    expect(events[4], isA<PointerUpEvent>());
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
      expect(events[0], isA<PointerAddedEvent>());
      expect(events[0].buttons, equals(0));
      expect(events[1], isA<PointerHoverEvent>());
      expect(events[1].buttons, equals(0));
      expect(events[2], isA<PointerDownEvent>());
      expect(events[2].buttons, equals(kPrimaryButton));
      expect(events[3], isA<PointerMoveEvent>());
      expect(events[3].buttons, equals(kPrimaryButton | kSecondaryStylusButton));
      expect(events[4], isA<PointerUpEvent>());
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
    expect(events[0], isA<PointerAddedEvent>());
    expect(events[0].buttons, equals(0));
    expect(events[1], isA<PointerHoverEvent>());
    expect(events[1].buttons, equals(0));
    expect(events[2], isA<PointerDownEvent>());
    expect(events[2].buttons, equals(kPrimaryButton));
    expect(events[3], isA<PointerMoveEvent>());
    expect(events[3].buttons, equals(kPrimaryButton));
    expect(events[4], isA<PointerUpEvent>());
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
      expect(events[0], isA<PointerAddedEvent>());
      expect(events[0].buttons, equals(0));
      expect(events[1], isA<PointerHoverEvent>());
      expect(events[1].buttons, equals(0));
      expect(events[2], isA<PointerDownEvent>());
      expect(events[2].buttons, equals(kMiddleMouseButton));
      expect(events[3], isA<PointerMoveEvent>());
      expect(events[3].buttons, equals(kMiddleMouseButton | kSecondaryMouseButton));
      expect(events[4], isA<PointerUpEvent>());
      expect(events[4].buttons, equals(0));
    }
  });
}

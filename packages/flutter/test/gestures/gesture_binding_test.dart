// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';
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
  assert(GestureBinding.instance != null);
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

  test('Serialize and deserialize PointerData', () {
    void compare(final ui.PointerData original, final ui.PointerData restored) {
      expect(restored.timeStamp, original.timeStamp);
      expect(restored.change, original.change);
      expect(restored.kind, original.kind);
      expect(restored.signalKind, original.signalKind);
      expect(restored.device, original.device);
      expect(restored.pointerIdentifier, original.pointerIdentifier);
      expect(restored.physicalX, original.physicalX);
      expect(restored.physicalY, original.physicalY);
      expect(restored.physicalDeltaX, original.physicalDeltaX);
      expect(restored.physicalDeltaY, original.physicalDeltaY);
      expect(restored.buttons, original.buttons);
      expect(restored.obscured, original.obscured);
      expect(restored.synthesized, original.synthesized);
      expect(restored.pressure, original.pressure);
      expect(restored.pressureMin, original.pressureMin);
      expect(restored.pressureMax, original.pressureMax);
      expect(restored.distance, original.distance);
      expect(restored.distanceMax, original.distanceMax);
      expect(restored.size, original.size);
      expect(restored.radiusMajor, original.radiusMajor);
      expect(restored.radiusMinor, original.radiusMinor);
      expect(restored.radiusMin, original.radiusMin);
      expect(restored.radiusMax, original.radiusMax);
      expect(restored.orientation, original.orientation);
      expect(restored.tilt, original.tilt);
      expect(restored.platformData, original.platformData);
      expect(restored.scrollDeltaX, original.scrollDeltaX);
      expect(restored.scrollDeltaY, original.scrollDeltaY);
    }

    const ui.PointerData defaultData = ui.PointerData();
    final String defaultDataString = json.encode(
      serializePointerData(defaultData));
    expect(defaultDataString, '{}');
    compare(defaultData, pointerDataFromJson(defaultDataString));

    const ui.PointerData customizeData = ui.PointerData(
      timeStamp: Duration(hours: 1),
      change: ui.PointerChange.move,
      kind: ui.PointerDeviceKind.invertedStylus,
      signalKind: ui.PointerSignalKind.scroll,
      device: 3,
      pointerIdentifier: 42,
      physicalX: 3.14,
      physicalY: 2.718,
      physicalDeltaX: 1.414,
      physicalDeltaY: 1.732,
      buttons: 4,
      obscured: true,
      synthesized: true,
      pressure: 101.325,
      pressureMin: 0.132,
      pressureMax: 760.0,
      distance: 1.609,
      distanceMax: 3.28,
      size: 0.618,
      radiusMajor: 1.123,
      radiusMinor: 4.567,
      orientation: 1.257,
      tilt: 0.628,
      platformData: 137,
      scrollDeltaX: 273.15,
      scrollDeltaY: 195.42
    );
    compare(customizeData, pointerDataFromJson(json.encode(
      serializePointerData(customizeData))));
  });
}

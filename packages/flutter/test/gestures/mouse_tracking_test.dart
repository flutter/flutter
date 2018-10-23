// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase
    with ServicesBinding, SchedulerBinding, GestureBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (callback != null) {
      callback(event);
    }
  }
}

TestGestureFlutterBinding _binding = TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  _binding ??= TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  group(MouseTracker, () {
    final List<MouseEnterDetails> enter = <MouseEnterDetails>[];
    final List<MouseExitDetails> exit = <MouseExitDetails>[];
    final List<MouseMoveDetails> move = <MouseMoveDetails>[];
    final MouseDetectorAnnotation annotation = MouseDetectorAnnotation(
      onEnter: (MouseEnterDetails details) => enter.add(details),
      onExit: (MouseExitDetails details) => exit.add(details),
      onMove: (MouseMoveDetails details) => move.add(details),
    );
    bool isInHitRegion = true;
    MouseTracker tracker;

    void clear() {
      enter.clear();
      exit.clear();
      move.clear();
    }

    setUp(() {
      clear();
      tracker = MouseTracker(
        GestureBinding.instance.pointerRouter,
        (Offset _) => isInHitRegion ? annotation : null,
      );
    });

    test('receives and processes mouse hover events', () {
      final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 0.0 * ui.window.devicePixelRatio,
          physicalY: 0.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 1.0 * ui.window.devicePixelRatio,
          physicalY: 101.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      const ui.PointerDataPacket packet3 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.remove,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      final ui.PointerDataPacket packet4 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 1.0 * ui.window.devicePixelRatio,
          physicalY: 201.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      tracker.attachAnnotation(annotation);
      isInHitRegion = true;
      ui.window.onPointerDataPacket(packet1);
      tracker.collectMousePositions();
      expect(enter.length, equals(1), reason: 'enter contains $enter');
      expect(
        enter.first,
        equals(MouseEnterDetails(
          globalPosition: const Offset(0.0, 0.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      expect(exit.length, equals(0), reason: 'exit contains $exit');
      expect(move.length, equals(1), reason: 'move contains $move');
      expect(
        move.first,
        equals(MouseMoveDetails(
          globalPosition: const Offset(0.0, 0.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      clear();

      ui.window.onPointerDataPacket(packet2);
      tracker.collectMousePositions();
      expect(enter.length, equals(0), reason: 'enter contains $enter');
      expect(exit.length, equals(0), reason: 'exit contains $exit');
      expect(move.length, equals(1), reason: 'move contains $move');
      expect(
        move.first,
        equals(MouseMoveDetails(
          globalPosition: const Offset(1.0, 101.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      clear();

      ui.window.onPointerDataPacket(packet3);
      tracker.collectMousePositions();
      expect(enter.length, equals(0), reason: 'enter contains $enter');
      expect(move.length, equals(0), reason: 'move contains $move');
      expect(exit.length, equals(1), reason: 'exit contains $exit');
      expect(
        exit.first,
        equals(MouseExitDetails(
          globalPosition: null,
          sourceTimeStamp: null,
        )),
      );

      clear();
      ui.window.onPointerDataPacket(packet4);
      tracker.collectMousePositions();
      expect(enter.length, equals(1), reason: 'enter contains $enter');
      expect(
        enter.first,
        equals(MouseEnterDetails(
          globalPosition: const Offset(1.0, 201.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      expect(exit.length, equals(0), reason: 'exit contains $exit');
      expect(move.length, equals(1), reason: 'move contains $move');
      expect(
        move.first,
        equals(MouseMoveDetails(
          globalPosition: const Offset(1.0, 201.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
    });
    test('detects exit when annotated layer no longer hit', () {
      final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 0.0 * ui.window.devicePixelRatio,
          physicalY: 0.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 1.0 * ui.window.devicePixelRatio,
          physicalY: 101.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 1.0 * ui.window.devicePixelRatio,
          physicalY: 201.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      isInHitRegion = true;
      tracker.attachAnnotation(annotation);

      ui.window.onPointerDataPacket(packet1);
      tracker.collectMousePositions();
      expect(enter.length, equals(1), reason: 'enter contains $enter');
      expect(
        enter.first,
        equals(MouseEnterDetails(
          globalPosition: const Offset(1.0, 101.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      expect(move.length, equals(1), reason: 'move contains $move');
      expect(
        move.first,
        equals(MouseMoveDetails(
          globalPosition: const Offset(1.0, 101.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      expect(exit.length, equals(0), reason: 'exit contains $exit');
      // Simulate layer going away by detaching it.
      clear();
      isInHitRegion = false;

      ui.window.onPointerDataPacket(packet2);
      tracker.collectMousePositions();
      expect(enter.length, equals(0), reason: 'enter contains $enter');
      expect(move.length, equals(0), reason: 'enter contains $move');
      expect(exit.length, equals(1), reason: 'enter contains $exit');
      expect(
        exit.first,
        equals(MouseExitDetails(
          globalPosition: const Offset(1.0, 201.0),
          sourceTimeStamp: Duration.zero,
        )),
        reason: 'move contains $move',
      );
    });
    test('detects exit when mouse goes away', () {
      final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 0.0 * ui.window.devicePixelRatio,
          physicalY: 0.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
        ui.PointerData(
          change: ui.PointerChange.hover,
          physicalX: 1.0 * ui.window.devicePixelRatio,
          physicalY: 101.0 * ui.window.devicePixelRatio,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      const ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
        ui.PointerData(
          change: ui.PointerChange.remove,
          kind: PointerDeviceKind.mouse,
        ),
      ]);
      isInHitRegion = true;
      tracker.attachAnnotation(annotation);
      ui.window.onPointerDataPacket(packet1);
      tracker.collectMousePositions();
      ui.window.onPointerDataPacket(packet2);
      tracker.collectMousePositions();
      expect(enter.length, equals(1), reason: 'enter contains $enter');
      expect(
        enter.first,
        equals(MouseEnterDetails(
          globalPosition: const Offset(1.0, 101.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      expect(move.length, equals(1), reason: 'move contains $move');
      expect(
        move.first,
        equals(MouseMoveDetails(
          globalPosition: const Offset(1.0, 101.0),
          sourceTimeStamp: Duration.zero,
        )),
      );
      expect(exit.length, equals(1), reason: 'exit contains $exit');
      expect(
        exit.first,
        equals(MouseExitDetails(
          globalPosition: null,
          sourceTimeStamp: null,
        )),
      );
    });
  });
}

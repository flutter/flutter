// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

class TestGestureRecognizer extends GestureRecognizer {
  TestGestureRecognizer({
    Object? debugOwner,
    PointerDeviceKind? kind,
    Set<PointerDeviceKind>? kindSet,
    this.onAllowedPointer,
    this.onNotAllowedPointer,
  }) : super(debugOwner: debugOwner, kind: kind, kindSet: kindSet);

  final ValueChanged<PointerDownEvent>? onAllowedPointer;
  final ValueChanged<PointerDownEvent>? onNotAllowedPointer;

  @override
  String get debugDescription => 'debugDescription content';

  @override
  void acceptGesture(int pointer) { }

  @override
  void rejectGesture(int pointer) {}

  @override
  void addAllowedPointer(PointerDownEvent event) {
    onAllowedPointer?.call(event);
  }

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    onNotAllowedPointer?.call(event);
  }
}

void main() {
  setUp(ensureGestureBinding);

  test('GestureRecognizer smoketest', () {
    final TestGestureRecognizer recognizer =
        TestGestureRecognizer(debugOwner: 0);
    expect(recognizer, hasAGoodToStringDeep);
  });

  test('OffsetPair', () {
    const OffsetPair offset1 = OffsetPair(
      local: Offset(10, 20),
      global: Offset(30, 40),
    );

    expect(offset1.local, const Offset(10, 20));
    expect(offset1.global, const Offset(30, 40));

    const OffsetPair offset2 = OffsetPair(
      local: Offset(50, 60),
      global: Offset(70, 80),
    );

    final OffsetPair sum = offset2 + offset1;
    expect(sum.local, const Offset(60, 80));
    expect(sum.global, const Offset(100, 120));

    final OffsetPair difference = offset2 - offset1;
    expect(difference.local, const Offset(40, 40));
    expect(difference.global, const Offset(40, 40));
  });

  group('GestureRecognizer', () {
    test('isPointerAllowed for a single kind', () {
      PointerDownEvent? lastAllowedEvent;
      PointerDownEvent? lastNotAllowedEvent;

      final TestGestureRecognizer stylusOnlyGestureRecognizer =
          TestGestureRecognizer(
        kind: PointerDeviceKind.stylus,
        onAllowedPointer: (PointerDownEvent event) {
          lastAllowedEvent = event;
        },
        onNotAllowedPointer: (PointerDownEvent event) {
          lastNotAllowedEvent = event;
        },
      );

      final PointerDownEvent stylusPointerEvent = TestPointer(
        0,
        PointerDeviceKind.stylus,
      ).down(Offset.zero);
      stylusOnlyGestureRecognizer.addPointer(stylusPointerEvent);
      expect(lastAllowedEvent, stylusPointerEvent);

      final PointerDownEvent mousePointerEvent = TestPointer(
        0,
        PointerDeviceKind.mouse,
      ).down(Offset.zero);
      stylusOnlyGestureRecognizer.addPointer(mousePointerEvent);
      expect(lastAllowedEvent, stylusPointerEvent);
      expect(lastNotAllowedEvent, mousePointerEvent);
    });

    test('isPointerAllowed for a set of kinds', () {
      PointerDownEvent? lastAllowedEvent;
      PointerDownEvent? lastNotAllowedEvent;

      final TestGestureRecognizer stylusOnlyGestureRecognizer =
          TestGestureRecognizer(
        kindSet: <PointerDeviceKind>{
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
        },
        onAllowedPointer: (PointerDownEvent event) {
          lastAllowedEvent = event;
        },
        onNotAllowedPointer: (PointerDownEvent event) {
          lastNotAllowedEvent = event;
        },
      );

      final PointerDownEvent stylusPointerEvent =
          TestPointer(0, PointerDeviceKind.stylus).down(Offset.zero);
      stylusOnlyGestureRecognizer.addPointer(stylusPointerEvent);
      expect(lastNotAllowedEvent, stylusPointerEvent);

      final PointerDownEvent mousePointerEvent = TestPointer(
        0,
        PointerDeviceKind.mouse,
      ).down(Offset.zero);
      stylusOnlyGestureRecognizer.addPointer(mousePointerEvent);
      expect(lastNotAllowedEvent, stylusPointerEvent);
      expect(lastAllowedEvent, mousePointerEvent);

      final PointerDownEvent touchPointerEvent = TestPointer(
        0,
        PointerDeviceKind.touch,
      ).down(Offset.zero);
      stylusOnlyGestureRecognizer.addPointer(touchPointerEvent);
      expect(lastNotAllowedEvent, stylusPointerEvent);
      expect(lastAllowedEvent, touchPointerEvent);
    });
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugPrintGestureArenaDiagnostics', (WidgetTester tester) async {
    PointerEvent event;
    debugPrintGestureArenaDiagnostics = true;
    final DebugPrintCallback oldCallback = debugPrint;
    final List<String> log = <String>[];
    debugPrint = (String? s, {int? wrapWidth}) {
      log.add(s ?? '');
    };

    final TapGestureRecognizer tap = TapGestureRecognizer()
      ..onTapDown = (TapDownDetails details) {}
      ..onTapUp = (TapUpDetails details) {}
      ..onTap = () {}
      ..onTapCancel = () {};
    expect(log, isEmpty);

    event = const PointerDownEvent(pointer: 1, position: Offset(10.0, 10.0));
    tap.addPointer(event as PointerDownEvent);
    expect(log, hasLength(2));
    expect(log[0], equalsIgnoringHashCodes('Gesture arena 1    ❙ ★ Opening new gesture arena.'));
    expect(
      log[1],
      equalsIgnoringHashCodes(
        'Gesture arena 1    ❙ Adding: TapGestureRecognizer#00000(state: ready, button: 1)',
      ),
    );
    log.clear();

    GestureBinding.instance.gestureArena.close(1);
    expect(log, hasLength(1));
    expect(log[0], equalsIgnoringHashCodes('Gesture arena 1    ❙ Closing with 1 member.'));
    log.clear();

    GestureBinding.instance.pointerRouter.route(event);
    expect(log, isEmpty);

    event = const PointerUpEvent(pointer: 1, position: Offset(12.0, 8.0));
    GestureBinding.instance.pointerRouter.route(event);
    expect(log, isEmpty);

    GestureBinding.instance.gestureArena.sweep(1);
    expect(log, hasLength(2));
    expect(log[0], equalsIgnoringHashCodes('Gesture arena 1    ❙ Sweeping with 1 member.'));
    expect(
      log[1],
      equalsIgnoringHashCodes(
        'Gesture arena 1    ❙ Winner: TapGestureRecognizer#00000(state: ready, finalPosition: Offset(12.0, 8.0), button: 1)',
      ),
    );
    log.clear();

    tap.dispose();
    expect(log, isEmpty);

    debugPrintGestureArenaDiagnostics = false;
    debugPrint = oldCallback;
  });

  testWidgets('debugPrintRecognizerCallbacksTrace', (WidgetTester tester) async {
    PointerEvent event;
    debugPrintRecognizerCallbacksTrace = true;
    final DebugPrintCallback oldCallback = debugPrint;
    final List<String> log = <String>[];
    debugPrint = (String? s, {int? wrapWidth}) {
      log.add(s ?? '');
    };

    final TapGestureRecognizer tap = TapGestureRecognizer()
      ..onTapDown = (TapDownDetails details) {}
      ..onTapUp = (TapUpDetails details) {}
      ..onTap = () {}
      ..onTapCancel = () {};
    expect(log, isEmpty);

    event = const PointerDownEvent(pointer: 1, position: Offset(10.0, 10.0));
    tap.addPointer(event as PointerDownEvent);
    expect(log, isEmpty);

    GestureBinding.instance.gestureArena.close(1);
    expect(log, isEmpty);

    GestureBinding.instance.pointerRouter.route(event);
    expect(log, isEmpty);

    event = const PointerUpEvent(pointer: 1, position: Offset(12.0, 8.0));
    GestureBinding.instance.pointerRouter.route(event);
    expect(log, isEmpty);

    GestureBinding.instance.gestureArena.sweep(1);
    expect(log, hasLength(3));
    expect(
      log[0],
      equalsIgnoringHashCodes(
        'TapGestureRecognizer#00000(state: ready, finalPosition: Offset(12.0, 8.0), button: 1) calling onTapDown callback.',
      ),
    );
    expect(
      log[1],
      equalsIgnoringHashCodes(
        'TapGestureRecognizer#00000(state: ready, won arena, finalPosition: Offset(12.0, 8.0), button: 1, sent tap down) calling onTapUp callback.',
      ),
    );
    expect(
      log[2],
      equalsIgnoringHashCodes(
        'TapGestureRecognizer#00000(state: ready, won arena, finalPosition: Offset(12.0, 8.0), button: 1, sent tap down) calling onTap callback.',
      ),
    );
    log.clear();

    tap.dispose();
    expect(log, isEmpty);

    debugPrintRecognizerCallbacksTrace = false;
    debugPrint = oldCallback;
  });

  testWidgets('debugPrintGestureArenaDiagnostics and debugPrintRecognizerCallbacksTrace', (
    WidgetTester tester,
  ) async {
    PointerEvent event;
    debugPrintGestureArenaDiagnostics = true;
    debugPrintRecognizerCallbacksTrace = true;
    final DebugPrintCallback oldCallback = debugPrint;
    final List<String> log = <String>[];
    debugPrint = (String? s, {int? wrapWidth}) {
      log.add(s ?? '');
    };

    final TapGestureRecognizer tap = TapGestureRecognizer()
      ..onTapDown = (TapDownDetails details) {}
      ..onTapUp = (TapUpDetails details) {}
      ..onTap = () {}
      ..onTapCancel = () {};
    expect(log, isEmpty);

    event = const PointerDownEvent(pointer: 1, position: Offset(10.0, 10.0));
    tap.addPointer(event as PointerDownEvent);
    expect(log, hasLength(2));
    expect(log[0], equalsIgnoringHashCodes('Gesture arena 1    ❙ ★ Opening new gesture arena.'));
    expect(
      log[1],
      equalsIgnoringHashCodes(
        'Gesture arena 1    ❙ Adding: TapGestureRecognizer#00000(state: ready, button: 1)',
      ),
    );
    log.clear();

    GestureBinding.instance.gestureArena.close(1);
    expect(log, hasLength(1));
    expect(log[0], equalsIgnoringHashCodes('Gesture arena 1    ❙ Closing with 1 member.'));
    log.clear();

    GestureBinding.instance.pointerRouter.route(event);
    expect(log, isEmpty);

    event = const PointerUpEvent(pointer: 1, position: Offset(12.0, 8.0));
    GestureBinding.instance.pointerRouter.route(event);
    expect(log, isEmpty);

    GestureBinding.instance.gestureArena.sweep(1);
    expect(log, hasLength(5));
    expect(log[0], equalsIgnoringHashCodes('Gesture arena 1    ❙ Sweeping with 1 member.'));
    expect(
      log[1],
      equalsIgnoringHashCodes(
        'Gesture arena 1    ❙ Winner: TapGestureRecognizer#00000(state: ready, finalPosition: Offset(12.0, 8.0), button: 1)',
      ),
    );
    expect(
      log[2],
      equalsIgnoringHashCodes(
        '                   ❙ TapGestureRecognizer#00000(state: ready, finalPosition: Offset(12.0, 8.0), button: 1) calling onTapDown callback.',
      ),
    );
    expect(
      log[3],
      equalsIgnoringHashCodes(
        '                   ❙ TapGestureRecognizer#00000(state: ready, won arena, finalPosition: Offset(12.0, 8.0), button: 1, sent tap down) calling onTapUp callback.',
      ),
    );
    expect(
      log[4],
      equalsIgnoringHashCodes(
        '                   ❙ TapGestureRecognizer#00000(state: ready, won arena, finalPosition: Offset(12.0, 8.0), button: 1, sent tap down) calling onTap callback.',
      ),
    );
    log.clear();

    tap.dispose();
    expect(log, isEmpty);

    debugPrintGestureArenaDiagnostics = false;
    debugPrintRecognizerCallbacksTrace = false;
    debugPrint = oldCallback;
  });

  test('TapGestureRecognizer _sentTapDown toString', () {
    final TapGestureRecognizer tap = TapGestureRecognizer()
      ..onTap = () {}; // Add a callback so that event can be added
    expect(tap.toString(), equalsIgnoringHashCodes('TapGestureRecognizer#00000(state: ready)'));
    const PointerDownEvent event = PointerDownEvent(pointer: 1, position: Offset(10.0, 10.0));
    tap.addPointer(event);
    tap.didExceedDeadline();
    expect(
      tap.toString(),
      equalsIgnoringHashCodes(
        'TapGestureRecognizer#00000(state: possible, button: 1, sent tap down)',
      ),
    );
    GestureBinding.instance.gestureArena.close(1);
    tap.dispose();
  });

  test('Gesture details debugFillProperties', () {
    final List<(Diagnosticable, List<String>)> pairs = <(Diagnosticable, List<String>)>[
      (
        DragDownDetails(),
        <String>['globalPosition: Offset(0.0, 0.0)', 'localPosition: Offset(0.0, 0.0)'],
      ),
      (
        DragStartDetails(),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'sourceTimeStamp: null',
          'kind: null',
        ],
      ),
      (
        DragUpdateDetails(globalPosition: Offset.zero),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'sourceTimeStamp: null',
          'delta: Offset(0.0, 0.0)',
          'primaryDelta: null',
        ],
      ),
      (
        DragEndDetails(),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'velocity: Velocity(0.0, 0.0)',
          'primaryVelocity: null',
        ],
      ),
      (
        ForcePressDetails(globalPosition: Offset.zero, pressure: 1.0),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'pressure: 1.0',
        ],
      ),
      (
        const LongPressDownDetails(),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'kind: null',
        ],
      ),
      (
        const LongPressStartDetails(),
        <String>['globalPosition: Offset(0.0, 0.0)', 'localPosition: Offset(0.0, 0.0)'],
      ),
      (
        const LongPressMoveUpdateDetails(),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'offsetFromOrigin: Offset(0.0, 0.0)',
          'localOffsetFromOrigin: Offset(0.0, 0.0)',
        ],
      ),
      (
        const LongPressEndDetails(),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'velocity: Velocity(0.0, 0.0)',
        ],
      ),
      (
        SerialTapDownDetails(kind: PointerDeviceKind.unknown),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'kind: unknown',
          'buttons: 0',
          'count: 1',
        ],
      ),
      (SerialTapCancelDetails(), <String>['count: 1']),
      (
        SerialTapUpDetails(),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'kind: null',
          'count: 1',
        ],
      ),
      (
        ScaleStartDetails(),
        <String>[
          'focalPoint: Offset(0.0, 0.0)',
          'localFocalPoint: Offset(0.0, 0.0)',
          'pointerCount: 0',
          'sourceTimeStamp: null',
        ],
      ),
      (
        ScaleUpdateDetails(),
        <String>[
          'focalPointDelta: Offset(0.0, 0.0)',
          'focalPoint: Offset(0.0, 0.0)',
          'localFocalPoint: Offset(0.0, 0.0)',
          'scale: 1.0',
          'horizontalScale: 1.0',
          'verticalScale: 1.0',
          'rotation: 0.0',
          'pointerCount: 0',
          'sourceTimeStamp: null',
        ],
      ),
      (
        ScaleEndDetails(),
        <String>['velocity: Velocity(0.0, 0.0)', 'scaleVelocity: 0.0', 'pointerCount: 0'],
      ),
      (
        TapDownDetails(kind: PointerDeviceKind.unknown),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'kind: unknown',
        ],
      ),
      (
        TapUpDetails(kind: PointerDeviceKind.unknown),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'kind: unknown',
        ],
      ),
      (
        TapDragDownDetails(
          globalPosition: Offset.zero,
          localPosition: Offset.zero,
          consecutiveTapCount: 1,
        ),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'kind: null',
          'consecutiveTapCount: 1',
        ],
      ),
      (
        TapDragUpDetails(
          globalPosition: Offset.zero,
          localPosition: Offset.zero,
          kind: PointerDeviceKind.unknown,
          consecutiveTapCount: 1,
        ),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'kind: unknown',
          'consecutiveTapCount: 1',
        ],
      ),
      (
        TapDragStartDetails(
          globalPosition: Offset.zero,
          localPosition: Offset.zero,
          consecutiveTapCount: 1,
        ),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'sourceTimeStamp: null',
          'kind: null',
          'consecutiveTapCount: 1',
        ],
      ),
      (
        TapDragUpdateDetails(
          globalPosition: Offset.zero,
          localPosition: Offset.zero,
          offsetFromOrigin: Offset.zero,
          localOffsetFromOrigin: Offset.zero,
          consecutiveTapCount: 1,
        ),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'sourceTimeStamp: null',
          'delta: Offset(0.0, 0.0)',
          'primaryDelta: null',
          'kind: null',
          'offsetFromOrigin: Offset(0.0, 0.0)',
          'localOffsetFromOrigin: Offset(0.0, 0.0)',
          'consecutiveTapCount: 1',
        ],
      ),
      (
        TapDragEndDetails(consecutiveTapCount: 1),
        <String>[
          'globalPosition: Offset(0.0, 0.0)',
          'localPosition: Offset(0.0, 0.0)',
          'velocity: Velocity(0.0, 0.0)',
          'primaryVelocity: null',
          'consecutiveTapCount: 1',
        ],
      ),
    ];

    for (final (Diagnosticable detail, List<String> expected) in pairs) {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      // ignore: invalid_use_of_protected_member
      detail.debugFillProperties(builder);
      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();
      expect(description, expected);
    }
  });
}

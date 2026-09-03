// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGesture('GestureArenaTeam rejection test', (GestureTester tester) {
    final team = GestureArenaTeam();
    final horizontalDrag = HorizontalDragGestureRecognizer()..team = team;
    final verticalDrag = VerticalDragGestureRecognizer()..team = team;
    final tap = TapGestureRecognizer();

    expect(horizontalDrag.team, equals(team));
    expect(verticalDrag.team, equals(team));
    expect(tap.team, isNull);

    final log = <String>[];

    horizontalDrag.onStart = (DragStartDetails details) {
      log.add('horizontal-drag-start');
    };
    verticalDrag.onStart = (DragStartDetails details) {
      log.add('vertical-drag-start');
    };
    tap.onTap = () {
      log.add('tap');
    };

    void test(Offset delta) {
      const origin = Offset(10.0, 10.0);
      final pointer = TestPointer(5);
      final PointerDownEvent down = pointer.down(origin);
      horizontalDrag.addPointer(down);
      verticalDrag.addPointer(down);
      tap.addPointer(down);
      expect(log, isEmpty);
      tester.closeArena(5);
      expect(log, isEmpty);
      tester.route(down);
      expect(log, isEmpty);
      tester.route(pointer.move(origin + delta));
      tester.route(pointer.up());
    }

    test(Offset.zero);
    expect(log, <String>['tap']);
    log.clear();

    test(const Offset(0.0, 30.0));
    expect(log, <String>['vertical-drag-start']);
    log.clear();

    horizontalDrag.dispose();
    verticalDrag.dispose();
    tap.dispose();
  });

  testGesture('GestureArenaTeam captain', (GestureTester tester) {
    final team = GestureArenaTeam();
    final captain = PassiveGestureRecognizer()..team = team;
    final horizontalDrag = HorizontalDragGestureRecognizer()..team = team;
    final verticalDrag = VerticalDragGestureRecognizer()..team = team;
    final tap = TapGestureRecognizer();

    team.captain = captain;

    final log = <String>[];

    captain.onGestureAccepted = () {
      log.add('captain accepted gesture');
    };
    horizontalDrag.onStart = (DragStartDetails details) {
      log.add('horizontal-drag-start');
    };
    verticalDrag.onStart = (DragStartDetails details) {
      log.add('vertical-drag-start');
    };
    tap.onTap = () {
      log.add('tap');
    };

    void test(Offset delta) {
      const origin = Offset(10.0, 10.0);
      final pointer = TestPointer(5);
      final PointerDownEvent down = pointer.down(origin);
      captain.addPointer(down);
      horizontalDrag.addPointer(down);
      verticalDrag.addPointer(down);
      tap.addPointer(down);
      expect(log, isEmpty);
      tester.closeArena(5);
      expect(log, isEmpty);
      tester.route(down);
      expect(log, isEmpty);
      tester.route(pointer.move(origin + delta));
      tester.route(pointer.up());
    }

    test(Offset.zero);
    expect(log, <String>['tap']);
    log.clear();

    test(const Offset(0.0, 30.0));
    expect(log, <String>['captain accepted gesture']);
    log.clear();

    horizontalDrag.dispose();
    verticalDrag.dispose();
    tap.dispose();
    captain.dispose();
  });

  testGesture('losing team member cleans up per-pointer state', (GestureTester tester) {
    final team = GestureArenaTeam();
    final first = _TrackingCleanupRecognizer()..team = team;
    final second = _TrackingCleanupRecognizer()..team = team;
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    const PointerDownEvent down = PointerDownEvent(pointer: 5, position: Offset(10, 10));
    first.addPointer(down);
    second.addPointer(down);

    // Both recognizers are tracking pointer 5.
    expect(first.didStopTracking, false);
    expect(second.didStopTracking, false);

    // Close the arena. With no other competitors, the team combiner is the sole
    // member. The microtask resolves by default: the combiner wins and picks
    // the first member as winner. The second member is rejected.
    tester.closeArena(5);
    tester.async.flushMicrotasks();

    // The winning recognizer (first) was not rejected — its state is intact.
    expect(first.didStopTracking, false);
    // The losing recognizer (second) was rejected by the combiner. Its
    // rejectGesture should have called stopTrackingPointer, which in turn
    // calls didStopTrackingLastPointer.
    expect(second.didStopTracking, true);
  });
}

typedef GestureAcceptedCallback = void Function();

class PassiveGestureRecognizer extends OneSequenceGestureRecognizer {
  GestureAcceptedCallback? onGestureAccepted;

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
  }

  @override
  String get debugDescription => 'passive';

  @override
  void didStopTrackingLastPointer(int pointer) {
    resolve(GestureDisposition.rejected);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    onGestureAccepted?.call();
  }
}

class _TrackingCleanupRecognizer extends OneSequenceGestureRecognizer {
  bool didStopTracking = false;

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    didStopTracking = true;
  }

  @override
  void handleEvent(PointerEvent event) {}

  @override
  String get debugDescription => 'TrackingCleanup';
}

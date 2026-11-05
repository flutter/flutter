// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test targets flutter/flutter#195472.
//
// On Windows, when a native modal dialog (file picker, etc.) swallows the
// pointer up/cancel events for an active tap, the TapGestureRecognizer is
// left tracking a stale primaryPointer with state == possible. Subsequent
// taps with new pointer ids are silently ignored because addAllowedPointer
// only accepts new pointers when state == ready.
//
// The fix force-resolves the stale pointer sequence before the guarded
// path, so the state machine returns to [GestureRecognizerState.ready] and
// accepts the new pointer normally.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGesture(
    'TapGestureRecognizer recovers from stale pointer when a new pointer arrives',
    (GestureTester tester) {
      final TapGestureRecognizer tap = TapGestureRecognizer();
      addTearDown(tap.dispose);

      var tapRecognized = false;
      tap.onTap = () {
        tapRecognized = true;
      };

      // --- Simulate pointer 1 down, but its up is swallowed by a native dialog ---
      const Duration t0 = Duration.zero;
      const PointerDownEvent staleDown = PointerDownEvent(
        pointer: 1,
        position: Offset(10.0, 10.0),
        timeStamp: t0,
      );

      tap.addPointer(staleDown);
      tester.closeArena(1);
      tester.route(staleDown);
      // Recognizer is now tracking pointer 1 in state == possible.
      // Pointer up/cancel is NEVER dispatched — simulating the dialog swallow.

      // --- Advance clock past the 1-second staleness threshold ---
      // FakeAsync is the default clock; advance by 2 seconds.
      tester.async.elapse(const Duration(seconds: 2));

      // --- Now the user taps again with a fresh pointer id ---
      final PointerDownEvent freshDown = PointerDownEvent(
        pointer: 2,
        position: const Offset(30.0, 30.0),
        timeStamp: const Duration(seconds: 2),
      );

      final PointerUpEvent freshUp = PointerUpEvent(
        pointer: 2,
        position: const Offset(31.0, 29.0),
        timeStamp: const Duration(seconds: 2) + const Duration(milliseconds: 100),
      );

      // Before the fix: addAllowedPointer guards with `if (state == ready)`.
      // Since the stale pointer left state == possible, this new pointer is
      // ignored. The recognizer keeps tracking the dead pointer 1 forever.
      //
      // After the fix: the stale sequence (older than 1s) is force-resolved,
      // state returns to ready, and pointer 2 is accepted normally.

      tap.addPointer(freshDown);
      tester.closeArena(2);
      tester.route(freshDown);

      tester.route(freshUp);
      GestureBinding.instance.gestureArena.sweep(2);

      // This expect FAILS on master (before the fix) because pointer 2's
      // up was never processed — tapRecognized remains false.
      // It PASSES after the fix, because the stale pointer 1 was force-resolved
      // before pointer 2 was accepted.
      expect(tapRecognized, isTrue);
    },
  );
}

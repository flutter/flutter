// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gesture_tester.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const down1 = PointerDownEvent(pointer: 1, position: Offset(10.0, 10.0));
  const up1 = PointerUpEvent(pointer: 1, position: Offset(11.0, 9.0));

  const down2 = PointerDownEvent(pointer: 2, position: Offset(12.0, 12.0));
  const up2 = PointerUpEvent(pointer: 2, position: Offset(13.0, 11.0));

  group('TapGestureRecognizer', () {
    testGesture(
      'On Android, tap triggers on the release of the last pointer (down1, down2, up1, up2)',
      (tester) {
        final tap = TapGestureRecognizer();
        addTearDown(tap.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;

          var tapRecognizedCount = 0;
          tap.onTap = () {
            tapRecognizedCount++;
          };

          var tapUpRecognizedCount = 0;
          tap.onTapUp = (details) {
            tapUpRecognizedCount++;
          };

          // First pointer down
          tap.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          tap.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final tapCountBeforeUp = tapRecognizedCount;
          final tapUpCountBeforeUp = tapUpRecognizedCount;

          // First pointer up
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final tapCountOnUp1 = tapRecognizedCount;
          final tapUpCountOnUp1 = tapUpRecognizedCount;

          // Second pointer up
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final tapCountOnUp2 = tapRecognizedCount;
          final tapUpCountOnUp2 = tapUpRecognizedCount;

          // Run assertions
          expect(tapCountBeforeUp, 0);
          expect(tapUpCountBeforeUp, 0);
          expect(tapCountOnUp1, 0);
          expect(tapUpCountOnUp1, 0);
          expect(tapCountOnUp2, 1);
          expect(tapUpCountOnUp2, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testGesture(
      'On Android, tap triggers on the release of the last pointer (down1, down2, up2, up1)',
      (tester) {
        final tap = TapGestureRecognizer();
        addTearDown(tap.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;

          var tapRecognizedCount = 0;
          tap.onTap = () {
            tapRecognizedCount++;
          };

          var tapUpRecognizedCount = 0;
          tap.onTapUp = (details) {
            tapUpRecognizedCount++;
          };

          // First pointer down
          tap.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          tap.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final tapCountBeforeUp = tapRecognizedCount;
          final tapUpCountBeforeUp = tapUpRecognizedCount;

          // Second pointer up
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final tapCountOnUp2 = tapRecognizedCount;
          final tapUpCountOnUp2 = tapUpRecognizedCount;

          // First pointer up
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final tapCountOnUp1 = tapRecognizedCount;
          final tapUpCountOnUp1 = tapUpRecognizedCount;

          // Run assertions
          expect(tapCountBeforeUp, 0);
          expect(tapUpCountBeforeUp, 0);
          expect(tapCountOnUp2, 0);
          expect(tapUpCountOnUp2, 0);
          expect(tapCountOnUp1, 1);
          expect(tapUpCountOnUp1, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testGesture(
      'On iOS, tap triggers on the release of the first pointer (down1, down2, up1, up2)',
      (tester) {
        final tap = TapGestureRecognizer();
        addTearDown(tap.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

          var tapRecognizedCount = 0;
          tap.onTap = () {
            tapRecognizedCount++;
          };

          var tapUpRecognizedCount = 0;
          tap.onTapUp = (details) {
            tapUpRecognizedCount++;
          };

          // First pointer down
          tap.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          tap.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final tapCountBeforeUp = tapRecognizedCount;
          final tapUpCountBeforeUp = tapUpRecognizedCount;

          // First pointer up
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final tapCountOnUp1 = tapRecognizedCount;
          final tapUpCountOnUp1 = tapUpRecognizedCount;

          // Second pointer up
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final tapCountOnUp2 = tapRecognizedCount;
          final tapUpCountOnUp2 = tapUpRecognizedCount;

          // Run assertions
          expect(tapCountBeforeUp, 0);
          expect(tapUpCountBeforeUp, 0);
          expect(tapCountOnUp1, 1);
          expect(tapUpCountOnUp1, 1);
          expect(tapCountOnUp2, 1);
          expect(tapUpCountOnUp2, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testGesture(
      'On iOS, tap triggers on the release of the first pointer (down1, down2, up2, up1)',
      (tester) {
        final tap = TapGestureRecognizer();
        addTearDown(tap.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

          var tapRecognizedCount = 0;
          tap.onTap = () {
            tapRecognizedCount++;
          };

          var tapUpRecognizedCount = 0;
          tap.onTapUp = (details) {
            tapUpRecognizedCount++;
          };

          // First pointer down
          tap.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          tap.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final tapCountBeforeUp = tapRecognizedCount;
          final tapUpCountBeforeUp = tapUpRecognizedCount;

          // Second pointer up (non-primary pointer)
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final tapCountOnUp2 = tapRecognizedCount;
          final tapUpCountOnUp2 = tapUpRecognizedCount;

          // First pointer up (primary pointer)
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final tapCountOnUp1 = tapRecognizedCount;
          final tapUpCountOnUp1 = tapUpRecognizedCount;

          // Run assertions
          expect(tapCountBeforeUp, 0);
          expect(tapUpCountBeforeUp, 0);
          expect(tapCountOnUp2, 0);
          expect(tapUpCountOnUp2, 0);
          expect(tapCountOnUp1, 1);
          expect(tapUpCountOnUp1, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });

  group('LongPressGestureRecognizer', () {
    testGesture(
      'On Android, long press triggers on the release of the last pointer (down1, down2, up1, up2)',
      (tester) {
        final longPress = LongPressGestureRecognizer();
        addTearDown(longPress.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;

          var longPressRecognizedCount = 0;
          longPress.onLongPress = () {
            longPressRecognizedCount++;
          };

          var longPressUpRecognizedCount = 0;
          longPress.onLongPressUp = () {
            longPressUpRecognizedCount++;
          };

          // First pointer down
          longPress.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          longPress.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final countBeforeTimeout = longPressRecognizedCount;
          final upCountBeforeTimeout = longPressUpRecognizedCount;

          // Wait for the long press deadline to trigger the long press gesture.
          tester.async.elapse(kLongPressTimeout);

          final countAfterTimeout = longPressRecognizedCount;
          final upCountAfterTimeout = longPressUpRecognizedCount;

          // First pointer up
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final upCountOnUp1 = longPressUpRecognizedCount;

          // Second pointer up
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final upCountOnUp2 = longPressUpRecognizedCount;

          // Run assertions
          expect(countBeforeTimeout, 0);
          expect(upCountBeforeTimeout, 0);
          expect(countAfterTimeout, 1);
          expect(upCountAfterTimeout, 0);
          expect(upCountOnUp1, 0);
          expect(upCountOnUp2, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testGesture(
      'On Android, long press triggers on the release of the last pointer (down1, down2, up2, up1)',
      (tester) {
        final longPress = LongPressGestureRecognizer();
        addTearDown(longPress.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;

          var longPressRecognizedCount = 0;
          longPress.onLongPress = () {
            longPressRecognizedCount++;
          };

          var longPressUpRecognizedCount = 0;
          longPress.onLongPressUp = () {
            longPressUpRecognizedCount++;
          };

          // First pointer down
          longPress.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          longPress.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final countBeforeTimeout = longPressRecognizedCount;
          final upCountBeforeTimeout = longPressUpRecognizedCount;

          // Wait for the long press deadline.
          tester.async.elapse(kLongPressTimeout);

          final countAfterTimeout = longPressRecognizedCount;
          final upCountAfterTimeout = longPressUpRecognizedCount;

          // Second pointer up
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final upCountOnUp2 = longPressUpRecognizedCount;

          // First pointer up
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final upCountOnUp1 = longPressUpRecognizedCount;

          // Run assertions
          expect(countBeforeTimeout, 0);
          expect(upCountBeforeTimeout, 0);
          expect(countAfterTimeout, 1);
          expect(upCountAfterTimeout, 0);
          expect(upCountOnUp2, 0);
          expect(upCountOnUp1, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testGesture(
      'On iOS, long press triggers on the release of the first pointer (down1, down2, up1, up2)',
      (tester) {
        final longPress = LongPressGestureRecognizer();
        addTearDown(longPress.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

          var longPressRecognizedCount = 0;
          longPress.onLongPress = () {
            longPressRecognizedCount++;
          };

          var longPressUpRecognizedCount = 0;
          longPress.onLongPressUp = () {
            longPressUpRecognizedCount++;
          };

          // First pointer down
          longPress.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          longPress.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final countBeforeTimeout = longPressRecognizedCount;
          final upCountBeforeTimeout = longPressUpRecognizedCount;

          // Wait for the long press deadline.
          tester.async.elapse(kLongPressTimeout);

          final countAfterTimeout = longPressRecognizedCount;
          final upCountAfterTimeout = longPressUpRecognizedCount;

          // First pointer up (primary pointer)
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final upCountOnUp1 = longPressUpRecognizedCount;

          // Second pointer up
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final upCountOnUp2 = longPressUpRecognizedCount;

          // Run assertions
          expect(countBeforeTimeout, 0);
          expect(upCountBeforeTimeout, 0);
          expect(countAfterTimeout, 1);
          expect(upCountAfterTimeout, 0);
          expect(upCountOnUp1, 1);
          expect(upCountOnUp2, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testGesture(
      'On iOS, long press triggers on the release of the first pointer (down1, down2, up2, up1)',
      (tester) {
        final longPress = LongPressGestureRecognizer();
        addTearDown(longPress.dispose);

        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

          var longPressRecognizedCount = 0;
          longPress.onLongPress = () {
            longPressRecognizedCount++;
          };

          var longPressUpRecognizedCount = 0;
          longPress.onLongPressUp = () {
            longPressUpRecognizedCount++;
          };

          // First pointer down
          longPress.addPointer(down1);
          tester.closeArena(1);
          tester.route(down1);

          // Second pointer down
          longPress.addPointer(down2);
          tester.closeArena(2);
          tester.route(down2);

          final countBeforeTimeout = longPressRecognizedCount;
          final upCountBeforeTimeout = longPressUpRecognizedCount;

          // Wait for the long press deadline.
          tester.async.elapse(kLongPressTimeout);

          final countAfterTimeout = longPressRecognizedCount;
          final upCountAfterTimeout = longPressUpRecognizedCount;

          // Second pointer up (non-primary pointer)
          tester.route(up2);
          GestureBinding.instance.gestureArena.sweep(2);

          final upCountOnUp2 = longPressUpRecognizedCount;

          // First pointer up (primary pointer)
          tester.route(up1);
          GestureBinding.instance.gestureArena.sweep(1);

          final upCountOnUp1 = longPressUpRecognizedCount;

          // Run assertions
          expect(countBeforeTimeout, 0);
          expect(upCountBeforeTimeout, 0);
          expect(countAfterTimeout, 1);
          expect(upCountAfterTimeout, 0);
          expect(upCountOnUp2, 0);
          expect(upCountOnUp1, 1);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}

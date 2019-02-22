// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  int tapCount;
  int singleTapUpCount;
  int singleTapCancelCount;
  int singleLongTapDownCount;
  int doubleTapDownCount;
  int forcePressStartCount;
  int forcePressEndCount;
  const Offset forcePressOffset = Offset(400.0, 50.0);


  void _handleTapDown(TapDownDetails details) { tapCount++; }
  void _handleSingleTapUp(TapUpDetails details) { singleTapUpCount++; }
  void _handleSingleTapCancel() { singleTapCancelCount++; }
  void _handleSingleLongTapDown() { singleLongTapDownCount++; }
  void _handleDoubleTapDown(TapDownDetails details) { doubleTapDownCount++; }
  void _handleForcePressStart(ForcePressDetails details) { forcePressStartCount++; }
  void _handleForcePressEnd(ForcePressDetails details) { forcePressEndCount++; }

  setUp(() {
    tapCount = 0;
    singleTapUpCount = 0;
    singleTapCancelCount = 0;
    singleLongTapDownCount = 0;
    doubleTapDownCount = 0;
    forcePressStartCount = 0;
    forcePressEndCount = 0;
  });

  Future<void> pumpGestureDetector(WidgetTester tester) async {
    await tester.pumpWidget(
      TextSelectionGestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onSingleTapUp: _handleSingleTapUp,
        onSingleTapCancel: _handleSingleTapCancel,
        onSingleLongTapDown: _handleSingleLongTapDown,
        onDoubleTapDown: _handleDoubleTapDown,
        onForcePressStart: _handleForcePressStart,
        onForcePressEnd: _handleForcePressEnd,
        child: Container(),
      ),
    );
  }

  testWidgets('a series of taps all call onTaps', (WidgetTester tester) async {
    await pumpGestureDetector(tester);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tapAt(const Offset(200, 200));
    expect(tapCount, 6);
  });

  testWidgets('in a series of rapid taps, onTapDown and onDoubleTapDown alternate', (WidgetTester tester) async {
    await pumpGestureDetector(tester);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 50));
    expect(singleTapUpCount, 1);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 50));
    expect(singleTapUpCount, 1);
    expect(doubleTapDownCount, 1);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 50));
    expect(singleTapUpCount, 2);
    expect(doubleTapDownCount, 1);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 50));
    expect(singleTapUpCount, 2);
    expect(doubleTapDownCount, 2);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 50));
    expect(singleTapUpCount, 3);
    expect(doubleTapDownCount, 2);
    await tester.tapAt(const Offset(200, 200));
    expect(singleTapUpCount, 3);
    expect(doubleTapDownCount, 3);
    expect(tapCount, 6);
  });

  testWidgets('quick tap-tap-hold is a double tap down', (WidgetTester tester) async {
    await pumpGestureDetector(tester);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 50));
    expect(singleTapUpCount, 1);
    final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(singleTapUpCount, 1);
    // Every down is counted.
    expect(tapCount, 2);
    // No cancels because the second tap of the double tap is a second successful
    // single tap behind the scene.
    expect(singleTapCancelCount, 0);
    expect(doubleTapDownCount, 1);
    // The double tap down hold supersedes the single tap down.
    expect(singleLongTapDownCount, 0);

    await gesture.up();
    // Nothing else happens on up.
    expect(singleTapUpCount, 1);
    expect(tapCount, 2);
    expect(singleTapCancelCount, 0);
    expect(doubleTapDownCount, 1);
    expect(singleLongTapDownCount, 0);
  });

  testWidgets('a very quick swipe is just a canceled tap', (WidgetTester tester) async {
    await pumpGestureDetector(tester);
    final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    expect(singleTapUpCount, 0);
    expect(tapCount, 0);
    expect(singleTapCancelCount, 1);
    expect(doubleTapDownCount, 0);
    expect(singleLongTapDownCount, 0);

    await gesture.up();
    // Nothing else happens on up.
    expect(singleTapUpCount, 0);
    expect(tapCount, 0);
    expect(singleTapCancelCount, 1);
    expect(doubleTapDownCount, 0);
    expect(singleLongTapDownCount, 0);
  });

  testWidgets('a slower swipe has a tap down and a canceled tap', (WidgetTester tester) async {
    await pumpGestureDetector(tester);
    final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    expect(singleTapUpCount, 0);
    expect(tapCount, 1);
    expect(singleTapCancelCount, 1);
    expect(doubleTapDownCount, 0);
    expect(singleLongTapDownCount, 0);
  });

  testWidgets('a force press intiates a force press', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    const int pointerValue = 1;

    final TestGesture gesture = await tester.createGesture();

    await gesture.downWithCustomEvent(
      forcePressOffset,
      const PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0
      ),
    );

    await gesture.updateWithCustomEvent(const PointerMoveEvent(pointer: pointerValue, position: Offset(0.0, 0.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));
    await gesture.up();
    await tester.pumpAndSettle();

    await gesture.downWithCustomEvent(
      forcePressOffset,
      const PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0
      ),
    );
    await gesture.updateWithCustomEvent(const PointerMoveEvent(pointer: pointerValue, position: Offset(0.0, 0.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 20));

     await gesture.downWithCustomEvent(
      forcePressOffset,
      const PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0
      ),
    );
    await gesture.updateWithCustomEvent(const PointerMoveEvent(pointer: pointerValue, position: Offset(0.0, 0.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 20));

    await gesture.downWithCustomEvent(
      forcePressOffset,
      const PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0
      ),
    );
    await gesture.updateWithCustomEvent(const PointerMoveEvent(pointer: pointerValue, position: Offset(0.0, 0.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));
    await gesture.up();

    expect(forcePressStartCount, 4);
  });

  testWidgets('a tap and then force press intiates a force press and not a double tap', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    const int pointerValue = 1;
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      forcePressOffset,
      const PointerDownEvent(
          pointer: pointerValue,
          position: forcePressOffset,
          pressure: 0.0,
          pressureMax: 6.0,
          pressureMin: 0.0
      ),

    );
    // Initiate a quick tap.
    await gesture.updateWithCustomEvent(
      const PointerMoveEvent(
        pointer: pointerValue,
        position: Offset(0.0, 0.0),
        pressure: 0.0,
        pressureMin: 0,
        pressureMax: 1
      )
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();

    // Initiate a force tap.
    await gesture.downWithCustomEvent(
      forcePressOffset,
      const PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0
      ),
    );
    await gesture.updateWithCustomEvent(const PointerMoveEvent(
      pointer: pointerValue,
      position: Offset(0.0, 0.0),
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1
    ));
    expect(forcePressStartCount, 1);

    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(forcePressEndCount, 1);
    expect(doubleTapDownCount, 0);
  });
}

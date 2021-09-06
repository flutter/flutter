// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'clipboard_utils.dart';

void main() {
  late int tapCount;
  late int singleTapUpCount;
  late int singleTapCancelCount;
  late int singleLongTapStartCount;
  late int doubleTapDownCount;
  late int forcePressStartCount;
  late int forcePressEndCount;
  late int dragStartCount;
  late int dragUpdateCount;
  late int dragEndCount;
  const Offset forcePressOffset = Offset(400.0, 50.0);

  void _handleTapDown(TapDownDetails details) { tapCount++; }
  void _handleSingleTapUp(TapUpDetails details) { singleTapUpCount++; }
  void _handleSingleTapCancel() { singleTapCancelCount++; }
  void _handleSingleLongTapStart(LongPressStartDetails details) { singleLongTapStartCount++; }
  void _handleDoubleTapDown(TapDownDetails details) { doubleTapDownCount++; }
  void _handleForcePressStart(ForcePressDetails details) { forcePressStartCount++; }
  void _handleForcePressEnd(ForcePressDetails details) { forcePressEndCount++; }
  void _handleDragSelectionStart(DragStartDetails details) { dragStartCount++; }
  void _handleDragSelectionUpdate(DragStartDetails _, DragUpdateDetails details) { dragUpdateCount++; }
  void _handleDragSelectionEnd(DragEndDetails details) { dragEndCount++; }

  setUp(() {
    tapCount = 0;
    singleTapUpCount = 0;
    singleTapCancelCount = 0;
    singleLongTapStartCount = 0;
    doubleTapDownCount = 0;
    forcePressStartCount = 0;
    forcePressEndCount = 0;
    dragStartCount = 0;
    dragUpdateCount = 0;
    dragEndCount = 0;
  });

  Future<void> pumpGestureDetector(WidgetTester tester) async {
    await tester.pumpWidget(
      TextSelectionGestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onSingleTapUp: _handleSingleTapUp,
        onSingleTapCancel: _handleSingleTapCancel,
        onSingleLongTapStart: _handleSingleLongTapStart,
        onDoubleTapDown: _handleDoubleTapDown,
        onForcePressStart: _handleForcePressStart,
        onForcePressEnd: _handleForcePressEnd,
        onDragSelectionStart: _handleDragSelectionStart,
        onDragSelectionUpdate: _handleDragSelectionUpdate,
        onDragSelectionEnd: _handleDragSelectionEnd,
        child: Container(),
      ),
    );
  }

  Future<void> pumpTextSelectionGestureDetectorBuilder(
    WidgetTester tester, {
    bool forcePressEnabled = true,
    bool selectionEnabled = true,
  }) async {
    final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();
    final FakeTextSelectionGestureDetectorBuilderDelegate delegate = FakeTextSelectionGestureDetectorBuilderDelegate(
      editableTextKey: editableTextKey,
      forcePressEnabled: forcePressEnabled,
      selectionEnabled: selectionEnabled,
    );
    final TextSelectionGestureDetectorBuilder provider =
    TextSelectionGestureDetectorBuilder(delegate: delegate);

    await tester.pumpWidget(
      MaterialApp(
        home: provider.buildGestureDetector(
          behavior: HitTestBehavior.translucent,
          child: FakeEditableText(key: editableTextKey),
        ),
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
    expect(singleLongTapStartCount, 0);

    await gesture.up();
    // Nothing else happens on up.
    expect(singleTapUpCount, 1);
    expect(tapCount, 2);
    expect(singleTapCancelCount, 0);
    expect(doubleTapDownCount, 1);
    expect(singleLongTapStartCount, 0);
  });

  testWidgets('a very quick swipe is ignored', (WidgetTester tester) async {
    await pumpGestureDetector(tester);
    final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    expect(singleTapUpCount, 0);
    expect(tapCount, 0);
    expect(singleTapCancelCount, 0);
    expect(doubleTapDownCount, 0);
    expect(singleLongTapStartCount, 0);

    await gesture.up();
    // Nothing else happens on up.
    expect(singleTapUpCount, 0);
    expect(tapCount, 0);
    expect(singleTapCancelCount, 0);
    expect(doubleTapDownCount, 0);
    expect(singleLongTapStartCount, 0);
  });

  testWidgets('a slower swipe has a tap down and a canceled tap', (WidgetTester tester) async {
    await pumpGestureDetector(tester);
    final TestGesture gesture = await tester.startGesture(const Offset(200, 200));
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    expect(singleTapUpCount, 0);
    expect(tapCount, 1);
    expect(singleTapCancelCount, 1);
    expect(doubleTapDownCount, 0);
    expect(singleLongTapStartCount, 0);
  });

  testWidgets('a force press initiates a force press', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    final int pointerValue = tester.nextPointer;

    final TestGesture gesture = await tester.createGesture();

    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );

    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: Offset.zero,
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1,
    ));
    await gesture.up();
    await tester.pumpAndSettle();

    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: Offset.zero,
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1,
    ));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 20));

    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: Offset.zero,
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1,
    ));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 20));

    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: Offset.zero,
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1,
    ));
    await gesture.up();

    expect(forcePressStartCount, 4);
  });

  testWidgets('a tap and then force press initiates a force press and not a double tap', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    final int pointerValue = tester.nextPointer;
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
          pointer: pointerValue,
          position: forcePressOffset,
          pressure: 0.0,
          pressureMax: 6.0,
          pressureMin: 0.0,
      ),

    );
    // Initiate a quick tap.
    await gesture.updateWithCustomEvent(
      PointerMoveEvent(
        pointer: pointerValue,
        position: Offset.zero,
        pressure: 0.0,
        pressureMin: 0,
        pressureMax: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();

    // Initiate a force tap.
    await gesture.downWithCustomEvent(
      forcePressOffset,
      PointerDownEvent(
        pointer: pointerValue,
        position: forcePressOffset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await gesture.updateWithCustomEvent(PointerMoveEvent(
      pointer: pointerValue,
      position: Offset.zero,
      pressure: 0.5,
      pressureMin: 0,
      pressureMax: 1,
    ));
    expect(forcePressStartCount, 1);

    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(forcePressEndCount, 1);
    expect(doubleTapDownCount, 0);
  });

  testWidgets('a long press from a touch device is recognized as a long single tap', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    final int pointerValue = tester.nextPointer;
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: pointerValue,
      kind: PointerDeviceKind.touch,
    );
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tapCount, 1);
    expect(singleTapUpCount, 0);
    expect(singleLongTapStartCount, 1);
  });

  testWidgets('a long press from a mouse is just a tap', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    final int pointerValue = tester.nextPointer;
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: pointerValue,
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tapCount, 1);
    expect(singleTapUpCount, 1);
    expect(singleLongTapStartCount, 0);
  });

  testWidgets('a touch drag is not recognized for text selection', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    final int pointerValue = tester.nextPointer;
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: pointerValue,
      kind: PointerDeviceKind.touch,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveBy(const Offset(210.0, 200.0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tapCount, 0);
    expect(singleTapUpCount, 0);
    expect(dragStartCount, 0);
    expect(dragUpdateCount, 0);
    expect(dragEndCount, 0);
  });

  testWidgets('a mouse drag is recognized for text selection', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    final int pointerValue = tester.nextPointer;
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: pointerValue,
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveBy(const Offset(210.0, 200.0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tapCount, 0);
    expect(singleTapUpCount, 0);
    expect(dragStartCount, 1);
    expect(dragUpdateCount, 1);
    expect(dragEndCount, 1);
  });

  testWidgets('a slow mouse drag is still recognized for text selection', (WidgetTester tester) async {
    await pumpGestureDetector(tester);

    final int pointerValue = tester.nextPointer;
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: pointerValue,
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.moveBy(const Offset(210.0, 200.0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(dragStartCount, 1);
    expect(dragUpdateCount, 1);
    expect(dragEndCount, 1);
  });

  testWidgets('test TextSelectionGestureDetectorBuilder long press', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester);
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: 0,
      kind: PointerDeviceKind.touch,
    );
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pumpAndSettle();

    final FakeEditableTextState state = tester.state(find.byType(FakeEditableText));
    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    expect(state.showToolbarCalled, isTrue);
    expect(renderEditable.selectPositionAtCalled, isTrue);
  });

  testWidgets('TextSelectionGestureDetectorBuilder right click', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/80119
    await pumpTextSelectionGestureDetectorBuilder(tester);

    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    renderEditable.text = const TextSpan(text: 'one two three four five six seven');
    await tester.pump();

    final TestGesture gesture = await tester.createGesture(
      pointer: 0,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    addTearDown(gesture.removePointer);

    // Get the location of the 10th character
    final Offset charLocation = renderEditable
        .getLocalRectForCaret(const TextPosition(offset: 10)).center;
    final Offset globalCharLocation = charLocation + tester.getTopLeft(find.byType(FakeEditable));

    // Right clicking on a word should select it
    await gesture.down(globalCharLocation);
    await gesture.up();
    await tester.pump();
    expect(renderEditable.selectWordCalled, isTrue);

    // Right clicking on a word within a selection shouldn't change the selection
    renderEditable.selectWordCalled = false;
    renderEditable.selection = const TextSelection(baseOffset: 3, extentOffset: 20);
    await gesture.down(globalCharLocation);
    await gesture.up();
    await tester.pump();
    expect(renderEditable.selectWordCalled, isFalse);

    // Right clicking on a word within a reverse (right-to-left) selection shouldn't change the selection
    renderEditable.selectWordCalled = false;
    renderEditable.selection = const TextSelection(baseOffset: 20, extentOffset: 3);
    await gesture.down(globalCharLocation);
    await gesture.up();
    await tester.pump();
    expect(renderEditable.selectWordCalled, isFalse);
  });

  testWidgets('test TextSelectionGestureDetectorBuilder tap', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester);
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: 0,
      kind: PointerDeviceKind.touch,
    );
    addTearDown(gesture.removePointer);
    await gesture.up();
    await tester.pumpAndSettle();

    final FakeEditableTextState state = tester.state(find.byType(FakeEditableText));
    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    expect(state.showToolbarCalled, isFalse);
    expect(renderEditable.selectWordEdgeCalled, isTrue);
  });

  testWidgets('test TextSelectionGestureDetectorBuilder double tap', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester);
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: 0,
      kind: PointerDeviceKind.touch,
    );
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await gesture.down(const Offset(200.0, 200.0));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    final FakeEditableTextState state = tester.state(find.byType(FakeEditableText));
    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    expect(state.showToolbarCalled, isTrue);
    expect(renderEditable.selectWordCalled, isTrue);
  });

  testWidgets('test TextSelectionGestureDetectorBuilder forcePress enabled', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester);
    final TestGesture gesture = await tester.createGesture();
    addTearDown(gesture.removePointer);
    await gesture.downWithCustomEvent(
      const Offset(200.0, 200.0),
      const PointerDownEvent(
        pointer: 0,
        position: Offset(200.0, 200.0),
        pressure: 3.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await gesture.updateWithCustomEvent(
      const PointerUpEvent(
        pointer: 0,
        position: Offset(200.0, 200.0),
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await tester.pump();

    final FakeEditableTextState state = tester.state(find.byType(FakeEditableText));
    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    expect(state.showToolbarCalled, isTrue);
    expect(renderEditable.selectWordsInRangeCalled, isTrue);
  });

  testWidgets('Mouse drag does not show handles nor toolbar', (WidgetTester tester) async {
    // Regressing test for https://github.com/flutter/flutter/issues/69001
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectableText('I love Flutter!'),
        ),
      ),
    );

    final Offset textFieldStart = tester.getTopLeft(find.byType(SelectableText));

    final TestGesture gesture = await tester.startGesture(textFieldStart, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(textFieldStart + const Offset(50.0, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.selectionOverlay!.handlesAreVisible, isFalse);
    expect(editableText.selectionOverlay!.toolbarIsVisible, isFalse);
  });

  testWidgets('test TextSelectionGestureDetectorBuilder drag with RenderEditable viewport offset change', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester);
    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));

    // Reconfigure the RenderEditable for multi-line.
    renderEditable.maxLines = null;
    renderEditable.offset = ViewportOffset.fixed(20.0);
    renderEditable.layout(const BoxConstraints.tightFor(width: 400, height: 300.0));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();
    expect(renderEditable.selectPositionAtCalled, isFalse);

    await gesture.moveTo(const Offset(300.0, 200.0));
    await tester.pumpAndSettle();
    expect(renderEditable.selectPositionAtCalled, isTrue);
    expect(renderEditable.selectPositionAtFrom, const Offset(200.0, 200.0));
    expect(renderEditable.selectPositionAtTo, const Offset(300.0, 200.0));

    // Move the viewport offset (scroll).
    renderEditable.offset = ViewportOffset.fixed(150.0);
    renderEditable.layout(const BoxConstraints.tightFor(width: 400, height: 300.0));
    await tester.pumpAndSettle();

    await gesture.moveTo(const Offset(300.0, 400.0));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(renderEditable.selectPositionAtCalled, isTrue);
    expect(renderEditable.selectPositionAtFrom, const Offset(200.0, 70.0));
    expect(renderEditable.selectPositionAtTo, const Offset(300.0, 400.0));
  });

  testWidgets('test TextSelectionGestureDetectorBuilder selection disabled', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester, selectionEnabled: false);
    final TestGesture gesture = await tester.startGesture(
      const Offset(200.0, 200.0),
      pointer: 0,
      kind: PointerDeviceKind.touch,
    );
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pumpAndSettle();

    final FakeEditableTextState state = tester.state(find.byType(FakeEditableText));
    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    expect(state.showToolbarCalled, isTrue);
    expect(renderEditable.selectWordsInRangeCalled, isFalse);
  });

  testWidgets('test TextSelectionGestureDetectorBuilder mouse drag disabled', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester, selectionEnabled: false);
    final TestGesture gesture = await tester.startGesture(
      Offset.zero,
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(const Offset(50.0, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    expect(renderEditable.selectPositionAtCalled, isFalse);
  });

  testWidgets('test TextSelectionGestureDetectorBuilder forcePress disabled', (WidgetTester tester) async {
    await pumpTextSelectionGestureDetectorBuilder(tester, forcePressEnabled: false);
    final TestGesture gesture = await tester.createGesture();
    addTearDown(gesture.removePointer);
    await gesture.downWithCustomEvent(
      const Offset(200.0, 200.0),
      const PointerDownEvent(
        pointer: 0,
        position: Offset(200.0, 200.0),
        pressure: 3.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );
    await gesture.up();
    await tester.pump();

    final FakeEditableTextState state = tester.state(find.byType(FakeEditableText));
    final FakeRenderEditable renderEditable = tester.renderObject(find.byType(FakeEditable));
    expect(state.showToolbarCalled, isFalse);
    expect(renderEditable.selectWordsInRangeCalled, isFalse);
  });

  // Regression test for https://github.com/flutter/flutter/issues/37032.
  testWidgets("selection handle's GestureDetector should not cover the entire screen", (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'a');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            autofocus: true,
            controller: controller,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder gestureDetector = find.descendant(
      of: find.byType(Visibility),
      matching: find.descendant(
        of: find.byType(FadeTransition),
        matching: find.byType(GestureDetector),
      ),
    );

    expect(gestureDetector, findsOneWidget);
    // The GestureDetector's size should not exceed that of the TextField.
    final Rect hitRect = tester.getRect(gestureDetector);
    final Rect textFieldRect = tester.getRect(find.byType(TextField));

    expect(hitRect.size.width, lessThan(textFieldRect.size.width));
    expect(hitRect.size.height, lessThan(textFieldRect.size.height));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

  group('ClipboardStatusNotifier', () {
    group('when Clipboard fails', () {
      setUp(() {
        final MockClipboard mockClipboard = MockClipboard(hasStringsThrows: true);
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      test('Clipboard API failure is gracefully recovered from', () async {
        final ClipboardStatusNotifier notifier = ClipboardStatusNotifier();
        expect(notifier.value, ClipboardStatus.unknown);

        await expectLater(notifier.update(), completes);
        expect(notifier.value, ClipboardStatus.unknown);
      });
    });

    group('when Clipboard succeeds', () {
      final MockClipboard mockClipboard = MockClipboard();

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      test('update sets value based on clipboard contents', () async {
        final ClipboardStatusNotifier notifier = ClipboardStatusNotifier();
        expect(notifier.value, ClipboardStatus.unknown);

        await expectLater(notifier.update(), completes);
        expect(notifier.value, ClipboardStatus.notPasteable);

        mockClipboard.handleMethodCall(const MethodCall(
          'Clipboard.setData',
          <String, dynamic>{
            'text': 'pasteablestring',
          },
        ));
        await expectLater(notifier.update(), completes);
        expect(notifier.value, ClipboardStatus.pasteable);
      });
    });
  });
}

class FakeTextSelectionGestureDetectorBuilderDelegate implements TextSelectionGestureDetectorBuilderDelegate {
  FakeTextSelectionGestureDetectorBuilderDelegate({
    required this.editableTextKey,
    required this.forcePressEnabled,
    required this.selectionEnabled,
  });

  @override
  final GlobalKey<EditableTextState> editableTextKey;

  @override
  final bool forcePressEnabled;

  @override
  final bool selectionEnabled;
}

class FakeEditableText extends EditableText {
  FakeEditableText({Key? key}): super(
    key: key,
    controller: TextEditingController(),
    focusNode: FocusNode(),
    backgroundCursorColor: Colors.white,
    cursorColor: Colors.white,
    style: const TextStyle(),
  );

  @override
  FakeEditableTextState createState() => FakeEditableTextState();
}

class FakeEditableTextState extends EditableTextState {
  final GlobalKey _editableKey = GlobalKey();
  bool showToolbarCalled = false;

  @override
  RenderEditable get renderEditable => _editableKey.currentContext!.findRenderObject()! as RenderEditable;

  @override
  bool showToolbar() {
    showToolbarCalled = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FakeEditable(this, key: _editableKey);
  }
}

class FakeEditable extends LeafRenderObjectWidget {
  const FakeEditable(
    this.delegate, {
    Key? key,
  }) : super(key: key);
  final EditableTextState delegate;

  @override
  RenderEditable createRenderObject(BuildContext context) {
    return FakeRenderEditable(delegate);
  }
}

class FakeRenderEditable extends RenderEditable {
  FakeRenderEditable(EditableTextState delegate) : super(
    text: const TextSpan(
      style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
      text: 'placeholder',
    ),
    startHandleLayerLink: LayerLink(),
    endHandleLayerLink: LayerLink(),
    ignorePointer: true,
    textAlign: TextAlign.start,
    textDirection: TextDirection.ltr,
    locale: const Locale('en', 'US'),
    offset: ViewportOffset.fixed(10.0),
    textSelectionDelegate: delegate,
    selection: const TextSelection.collapsed(
      offset: 0,
    ),
  );

  bool selectWordsInRangeCalled = false;
  @override
  void selectWordsInRange({ required Offset from, Offset? to, required SelectionChangedCause cause }) {
    selectWordsInRangeCalled = true;
  }

  bool selectWordEdgeCalled = false;
  @override
  void selectWordEdge({ required SelectionChangedCause cause }) {
    selectWordEdgeCalled = true;
  }

  bool selectPositionAtCalled = false;
  Offset? selectPositionAtFrom;
  Offset? selectPositionAtTo;
  @override
  void selectPositionAt({ required Offset from, Offset? to, required SelectionChangedCause cause }) {
    selectPositionAtCalled = true;
    selectPositionAtFrom = from;
    selectPositionAtTo = to;
  }

  bool selectWordCalled = false;
  @override
  void selectWord({ required SelectionChangedCause cause }) {
    selectWordCalled = true;
  }
}

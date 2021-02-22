// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/recording_canvas.dart';
import 'rendering_tester.dart';

class FakeEditableTextState with TextSelectionDelegate {
  @override
  TextEditingValue textEditingValue = TextEditingValue.empty;

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) { }

  @override
  void hideToolbar() { }

  @override
  void bringIntoView(TextPosition position) { }
}

void main() {
  test('RenderEditable respects clipBehavior', () {
    const BoxConstraints viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    final TestClipPaintingContext context = TestClipPaintingContext();

    final String longString = 'a' * 10000;

    // By default, clipBehavior should be Clip.none
    final RenderEditable defaultEditable = RenderEditable(
      text: TextSpan(text: longString),
      textDirection: TextDirection.ltr,
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      offset: ViewportOffset.zero(),
      textSelectionDelegate: FakeEditableTextState(),
      selection: const TextSelection(baseOffset: 0, extentOffset: 0),
    );
    layout(defaultEditable, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
    defaultEditable.paint(context, Offset.zero);
    expect(context.clipBehavior, equals(Clip.hardEdge));

    context.clipBehavior = Clip.none; // Reset as Clip.none won't write into clipBehavior.
    for (final Clip clip in Clip.values) {
      final RenderEditable editable = RenderEditable(
        text: TextSpan(text: longString),
        textDirection: TextDirection.ltr,
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        offset: ViewportOffset.zero(),
        textSelectionDelegate: FakeEditableTextState(),
        selection: const TextSelection(baseOffset: 0, extentOffset: 0),
        clipBehavior: clip,
      );
      layout(editable, constraints: viewport, phase: EnginePhase.composite, onErrors: expectOverflowedErrors);
      editable.paint(context, Offset.zero);
      expect(context.clipBehavior, equals(clip));
    }
  });

  test('editable intrinsics', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      text: const TextSpan(
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: '12345',
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: const Locale('ja', 'JP'),
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
    );
    expect(editable.getMinIntrinsicWidth(double.infinity), 50.0);
    // The width includes the width of the cursor (1.0).
    expect(editable.getMaxIntrinsicWidth(double.infinity), 51.0);
    expect(editable.getMinIntrinsicHeight(double.infinity), 10.0);
    expect(editable.getMaxIntrinsicHeight(double.infinity), 10.0);

    expect(
      editable.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderEditable#00000 NEEDS-LAYOUT NEEDS-PAINT NEEDS-COMPOSITING-BITS-UPDATE DETACHED\n'
        ' │ parentData: MISSING\n'
        ' │ constraints: MISSING\n'
        ' │ size: MISSING\n'
        ' │ cursorColor: null\n'
        ' │ showCursor: ValueNotifier<bool>#00000(false)\n'
        ' │ maxLines: 1\n'
        ' │ minLines: null\n'
        ' │ selectionColor: null\n'
        ' │ textScaleFactor: 1.0\n'
        ' │ locale: ja_JP\n'
        ' │ selection: null\n'
        ' │ offset: _FixedViewportOffset#00000(offset: 0.0)\n'
        ' ╘═╦══ text ═══\n'
        '   ║ TextSpan:\n'
        '   ║   inherit: true\n'
        '   ║   family: Ahem\n'
        '   ║   size: 10.0\n'
        '   ║   height: 1.0x\n'
        '   ║   "12345"\n'
        '   ╚═══════════\n'
      ),
    );
  });

  // Test that clipping will be used even when the text fits within the visible
  // region if the start position of the text is offset (e.g. during scrolling
  // animation).
  test('correct clipping', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      text: const TextSpan(
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: 'A',
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: const Locale('en', 'US'),
      offset: ViewportOffset.fixed(10.0),
      textSelectionDelegate: delegate,
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );
    layout(editable, constraints: BoxConstraints.loose(const Size(500.0, 500.0)));
    // Prepare for painting after layout.
    pumpFrame(phase: EnginePhase.compositingBits);
    expect(
      (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
      paints..clipRect(rect: const Rect.fromLTRB(0.0, 0.0, 500.0, 10.0)),
    );
  });

  test('Can change cursor color, radius, visibility', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ValueNotifier<bool> showCursor = ValueNotifier<bool>(true);
    EditableText.debugDeterministicCursor = true;

    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      textDirection: TextDirection.ltr,
      cursorColor: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection.collapsed(
        offset: 4,
        affinity: TextAffinity.upstream,
      ),
    );

    layout(editable);

    editable.layout(BoxConstraints.loose(const Size(100, 100)));
    // Prepare for painting after layout.
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(
      editable,
      // Draw no cursor by default.
      paintsExactlyCountTimes(#drawRect, 0),
    );

    editable.showCursor = showCursor;
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(editable, paints..rect(
      color: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
      rect: const Rect.fromLTWH(40, 0, 1, 10),
    ));

    // Now change to a rounded caret.
    editable.cursorColor = const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF);
    editable.cursorWidth = 4;
    editable.cursorRadius = const Radius.circular(3);
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(editable, paints..rrect(
      color: const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF),
      rrect: RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 0, 4, 10),
        const Radius.circular(3),
      ),
    ));

    editable.textScaleFactor = 2;
    pumpFrame(phase: EnginePhase.compositingBits);

    // Now the caret height is much bigger due to the bigger font scale.
    expect(editable, paints..rrect(
      color: const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF),
      rrect: RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 0, 4, 20),
        const Radius.circular(3),
      ),
    ));

    // Can turn off caret.
    showCursor.value = false;
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(editable, paintsExactlyCountTimes(#drawRRect, 0));
  });

  test('Can change textAlign', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();

    final RenderEditable editable = RenderEditable(
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(text: 'test'),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
    );

    layout(editable);

    editable.layout(BoxConstraints.loose(const Size(100, 100)));
    expect(editable.textAlign, TextAlign.start);
    expect(editable.debugNeedsLayout, isFalse);

    editable.textAlign = TextAlign.center;
    expect(editable.textAlign, TextAlign.center);
    expect(editable.debugNeedsLayout, isTrue);
  });

  test('Cursor with ideographic script', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ValueNotifier<bool> showCursor = ValueNotifier<bool>(true);
    EditableText.debugDeterministicCursor = true;

    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      textDirection: TextDirection.ltr,
      cursorColor: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(
        text: '中文测试文本是否正确',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection.collapsed(
        offset: 4,
        affinity: TextAffinity.upstream,
      ),
    );

    layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));
    pumpFrame(phase: EnginePhase.compositingBits);
    expect(
      editable,
      // Draw no cursor by default.
      paintsExactlyCountTimes(#drawRect, 0),
    );

    editable.showCursor = showCursor;
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(editable, paints..rect(
      color: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
      rect: const Rect.fromLTWH(40, 0, 1, 10),
    ));

    // Now change to a rounded caret.
    editable.cursorColor = const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF);
    editable.cursorWidth = 4;
    editable.cursorRadius = const Radius.circular(3);
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(editable, paints..rrect(
      color: const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF),
      rrect: RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 0, 4, 10),
        const Radius.circular(3),
      ),
    ));

    editable.textScaleFactor = 2;
    pumpFrame(phase: EnginePhase.compositingBits);

    // Now the caret height is much bigger due to the bigger font scale.
    expect(editable, paints..rrect(
      color: const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF),
      rrect: RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 0, 4, 20),
        const Radius.circular(3),
      ),
    ));

    // Can turn off caret.
    showCursor.value = false;
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(editable, paintsExactlyCountTimes(#drawRRect, 0));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61024

  test('text is painted above selection', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection(
        baseOffset: 0,
        extentOffset: 3,
        affinity: TextAffinity.upstream,
      ),
    );

    layout(editable);

    expect(
      editable,
      paints
        // Check that it's the black selection box, not the red cursor.
        ..rect(color: Colors.black)
        ..paragraph(),
    );

    // There is exactly one rect paint (1 selection, 0 cursor).
    expect(editable, paintsExactlyCountTimes(#drawRect, 1));
  });

  test('cursor can paint above or below the text', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ValueNotifier<bool> showCursor = ValueNotifier<bool>(true);
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      paintCursorAboveText: true,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      showCursor: showCursor,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection.collapsed(
        offset: 2,
        affinity: TextAffinity.upstream,
      ),
    );

    layout(editable);

    expect(
      editable,
      paints
        ..paragraph()
        // Red collapsed cursor is painted, not a selection box.
        ..rect(color: Colors.red[500]),
    );

    // There is exactly one rect paint (0 selection, 1 cursor).
    expect(editable, paintsExactlyCountTimes(#drawRect, 1));

    editable.paintCursorAboveText = false;
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(
      editable,
      // The paint order is now flipped.
      paints
        ..rect(color: Colors.red[500])
        ..paragraph(),
    );
    expect(editable, paintsExactlyCountTimes(#drawRect, 1));
  });

  test('ignore key event from web platform', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      // This makes the scroll axis vertical.
      maxLines: 2,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: 'test\ntest',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 4,
      ),
    );

    layout(editable);
    editable.hasFocus = true;

    expect(
      editable,
      paints..paragraph(offset: Offset.zero),
    );

    editable.selectPositionAt(from: Offset.zero, cause: SelectionChangedCause.tap);
    editable.selection = const TextSelection.collapsed(offset: 0);
    pumpFrame();

    if(kIsWeb) {
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'web');
      expect(currentSelection.isCollapsed, true);
      expect(currentSelection.baseOffset, 0);
    } else {
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
      expect(currentSelection.isCollapsed, true);
      expect(currentSelection.baseOffset, 1);
    }
  });

  test('selects correct place with offsets', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      // This makes the scroll axis vertical.
      maxLines: 2,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: 'test\ntest',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 4,
      ),
    );

    layout(editable);

    expect(
      editable,
      paints..paragraph(offset: Offset.zero),
    );

    editable.selectPositionAt(from: const Offset(0, 2), cause: SelectionChangedCause.tap);
    pumpFrame();

    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);

    viewportOffset.correctBy(10);

    pumpFrame(phase: EnginePhase.compositingBits);

    expect(
      editable,
      paints..paragraph(offset: const Offset(0, -10)),
    );

    // Tap the same place. But because the offset is scrolled up, the second line
    // gets tapped instead.
    editable.selectPositionAt(from: const Offset(0, 2), cause: SelectionChangedCause.tap);
    pumpFrame();

    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 5);

    // Test the other selection methods.
    // Move over by one character.
    editable.handleTapDown(TapDownDetails(globalPosition: const Offset(10, 2)));
    pumpFrame();
    editable.selectPosition(cause:SelectionChangedCause.tap);
    pumpFrame();
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 6);

    editable.handleTapDown(TapDownDetails(globalPosition: const Offset(20, 2)));
    pumpFrame();
    editable.selectWord(cause:SelectionChangedCause.longPress);
    pumpFrame();
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 5);
    expect(currentSelection.extentOffset, 9);

    // Select one more character down but since it's still part of the same
    // word, the same word is selected.
    editable.selectWordsInRange(from: const Offset(30, 2), cause:SelectionChangedCause.longPress);
    pumpFrame();
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 5);
    expect(currentSelection.extentOffset, 9);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61026

  test('selects correct place when offsets are flipped', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      text: const TextSpan(
        text: 'abc def ghi',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
    );

    layout(editable);

    editable.selectPositionAt(from: const Offset(30, 2), to: const Offset(10, 2), cause: SelectionChangedCause.drag);
    pumpFrame();

    expect(currentSelection.isCollapsed, isFalse);
    expect(currentSelection.baseOffset, 3);
    expect(currentSelection.extentOffset, 1);
  });

  test('selection does not flicker as user is dragging', () {
    int selectionChangedCount = 0;
    TextSelection? updatedSelection;
    final TextSelectionDelegate delegate = FakeEditableTextState();
    const TextSpan text = TextSpan(
      text: 'abc def ghi',
      style: TextStyle(
        height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
      ),
    );

    final RenderEditable editable1 = RenderEditable(
      textSelectionDelegate: delegate,
      textDirection: TextDirection.ltr,
      offset: ViewportOffset.zero(),
      selection: const TextSelection(baseOffset: 3, extentOffset: 4),
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        selectionChangedCount++;
        updatedSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: text,
    );

    layout(editable1);

    // Shouldn't cause a selection change.
    editable1.selectPositionAt(from: const Offset(30, 2), to: const Offset(42, 2), cause: SelectionChangedCause.drag);
    pumpFrame();

    expect(updatedSelection, isNull);
    expect(selectionChangedCount, 0);

    final RenderEditable editable2 = RenderEditable(
      textSelectionDelegate: delegate,
      textDirection: TextDirection.ltr,
      offset: ViewportOffset.zero(),
      selection: const TextSelection(baseOffset: 3, extentOffset: 4),
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        selectionChangedCount++;
        updatedSelection = selection;
      },
      text: text,
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
    );

    layout(editable2);

    // Now this should cause a selection change.
    editable2.selectPositionAt(from: const Offset(30, 2), to: const Offset(48, 2), cause: SelectionChangedCause.drag);
    pumpFrame();

    expect(updatedSelection!.baseOffset, 3);
    expect(updatedSelection!.extentOffset, 5);
    expect(selectionChangedCount, 1);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61028

  test('promptRect disappears when promptRectColor is set to null', () {
    const Color promptRectColor = Color(0x12345678);
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      text: const TextSpan(
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: 'ABCDEFG',
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: const Locale('en', 'US'),
      offset: ViewportOffset.fixed(10.0),
      textSelectionDelegate: delegate,
      selection: const TextSelection.collapsed(offset: 0),
      promptRectColor: promptRectColor,
      promptRectRange: const TextRange(start: 0, end: 1),
    );

    layout(editable, constraints: BoxConstraints.loose(const Size(1000.0, 1000.0)));
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(
      (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
      paints..rect(color: promptRectColor),
    );

    editable.promptRectColor = null;

    editable.layout(BoxConstraints.loose(const Size(1000.0, 1000.0)));
    pumpFrame(phase: EnginePhase.compositingBits);

    expect(editable.promptRectColor, null);
    expect(
      (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
      isNot(paints..rect(color: promptRectColor)),
    );
  });

  test('editable hasFocus correctly initialized', () {
    // Regression test for https://github.com/flutter/flutter/issues/21640
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      text: const TextSpan(
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: '12345',
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: const Locale('en', 'US'),
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      hasFocus: true,
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
    );

    expect(editable.hasFocus, true);
    editable.hasFocus = false;
    expect(editable.hasFocus, false);
  });

  test('has correct maxScrollExtent', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    EditableText.debugDeterministicCursor = true;

    final RenderEditable editable = RenderEditable(
      maxLines: 2,
      backgroundCursorColor: Colors.grey,
      textDirection: TextDirection.ltr,
      cursorColor: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(
        text: '撒地方加咖啡哈金凤凰卡号方式剪坏算法发挥福建垃\nasfjafjajfjaslfjaskjflasjfksajf撒分开建安路口附近拉设\n计费可使肌肤撒附近埃里克圾房卡设计费"',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Roboto',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection.collapsed(
        offset: 4,
        affinity: TextAffinity.upstream,
      ),
    );

    editable.layout(BoxConstraints.loose(const Size(100.0, 1000.0)));
    expect(editable.size, equals(const Size(100, 20)));
    expect(editable.maxLines, equals(2));
    expect(editable.maxScrollExtent, equals(90));

    editable.layout(BoxConstraints.loose(const Size(150.0, 1000.0)));
    expect(editable.maxScrollExtent, equals(50));

    editable.layout(BoxConstraints.loose(const Size(200.0, 1000.0)));
    expect(editable.maxScrollExtent, equals(40));

    editable.layout(BoxConstraints.loose(const Size(500.0, 1000.0)));
    expect(editable.maxScrollExtent, equals(10));

    editable.layout(BoxConstraints.loose(const Size(1000.0, 1000.0)));
    expect(editable.maxScrollExtent, equals(10));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/42772

  test('arrow keys and delete handle simple text correctly', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(
          text: 'test',
          selection: TextSelection.collapsed(offset: 0),
        );
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    layout(editable);
    editable.hasFocus = true;

    editable.selectPositionAt(from: Offset.zero, cause: SelectionChangedCause.tap);
    editable.selection = const TextSelection.collapsed(offset: 0);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 1);

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);

    await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');
    expect(delegate.textEditingValue.text, 'est');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle surrogate pairs correctly', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(
          text: '0123😆6789',
          selection: TextSelection.collapsed(offset: 0),
        );
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: '0123😆6789',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    layout(editable);
    editable.hasFocus = true;

    editable.selection = const TextSelection.collapsed(offset: 4);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 6);
    editable.selection = currentSelection;

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);
    editable.selection = currentSelection;

    await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');
    expect(delegate.textEditingValue.text, '01236789');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle grapheme clusters correctly', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(
          text: '0123👨‍👩‍👦2345',
          selection: TextSelection.collapsed(offset: 0),
        );
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: '0123👨‍👩‍👦2345',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    layout(editable);
    editable.hasFocus = true;

    editable.selection = const TextSelection.collapsed(offset: 4);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 12);
    editable.selection = currentSelection;

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);
    editable.selection = currentSelection;

    await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');
    expect(delegate.textEditingValue.text, '01232345');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle surrogate pairs correctly', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: '\u{1F44D}',  // Thumbs up
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    layout(editable);
    editable.hasFocus = true;

    editable.selectPositionAt(from: Offset.zero, cause: SelectionChangedCause.tap);
    editable.selection = const TextSelection.collapsed(offset: 0);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);

    await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');
    expect(delegate.textEditingValue.text, '');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys work after detaching the widget and attaching it again', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(
          text: 'W Szczebrzeszynie chrząszcz brzmi w trzcinie',
          selection: TextSelection.collapsed(offset: 0),
        );
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        renderObject.selection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: 'W Szczebrzeszynie chrząszcz brzmi w trzcinie',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    editable.attach(pipelineOwner);
    editable.hasFocus = true;
    editable.detach();
    layout(editable);
    editable.hasFocus = true;
    editable.selectPositionAt(from: Offset.zero, cause: SelectionChangedCause.tap);
    editable.selection = const TextSelection.collapsed(offset: 0);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
    expect(editable.selection?.isCollapsed, true);
    expect(editable.selection?.baseOffset, 4);

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft, platform: 'android');
    expect(editable.selection?.isCollapsed, true);
    expect(editable.selection?.baseOffset, 3);

    await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
    await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');
    expect(delegate.textEditingValue.text, 'W Sczebrzeszynie chrząszcz brzmi w trzcinie');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys with selection text', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: '012345',  // Thumbs up
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    layout(editable);
    editable.hasFocus = true;

    editable.selection = const TextSelection(baseOffset: 2, extentOffset: 4);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);

    editable.selection = const TextSelection(baseOffset: 2, extentOffset: 4);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  test('arrow keys with selection text and shift', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: '012345',  // Thumbs up
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );

    layout(editable);
    editable.hasFocus = true;

    editable.selection = const TextSelection(baseOffset: 2, extentOffset: 4);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.shift);
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 2);
    expect(currentSelection.extentOffset, 5);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.shift);
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 4);
    expect(currentSelection.extentOffset, 3);

    editable.selection = const TextSelection(baseOffset: 2, extentOffset: 4);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.shift);
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 2);
    expect(currentSelection.extentOffset, 3);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.shift);
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 4);
    expect(currentSelection.extentOffset, 1);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  test('respects enableInteractiveSelection', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: '012345',  // Thumbs up
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
      enableInteractiveSelection: false,
    );

    layout(editable);
    editable.hasFocus = true;

    editable.selection = const TextSelection.collapsed(offset: 2);
    pumpFrame();

    await simulateKeyDownEvent(LogicalKeyboardKey.shift);

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 3);
    editable.selection = currentSelection;

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);
    editable.selection = currentSelection;

    final LogicalKeyboardKey wordModifier =
        Platform.isMacOS ? LogicalKeyboardKey.alt : LogicalKeyboardKey.control;

    await simulateKeyDownEvent(wordModifier);

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowRight);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 6);
    editable.selection = currentSelection;

    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await simulateKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);
    editable.selection = currentSelection;

    await simulateKeyUpEvent(wordModifier);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  group('delete', () {
    test('handles selection', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection(baseOffset: 1, extentOffset: 3),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: 'test',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection(baseOffset: 1, extentOffset: 3),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');
      expect(delegate.textEditingValue.text, 'tt');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 1);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('is a no-op at the end of the text', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 4),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: 'test',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: 4),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');
      expect(delegate.textEditingValue.text, 'test');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 4);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('handles obscured text', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
          text: 'test',
          selection: TextSelection.collapsed(offset: 0),
        );

      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        obscureText: true,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: 0),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.delete, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.delete, platform: 'android');

      expect(delegate.textEditingValue.text, 'est');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);
  });

  group('backspace', () {
    test('handles selection', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection(baseOffset: 1, extentOffset: 3),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: 'test',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection(baseOffset: 1, extentOffset: 3),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.backspace, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.backspace, platform: 'android');
      expect(delegate.textEditingValue.text, 'tt');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 1);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('handles simple text', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: 'test',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: 3),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.backspace, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.backspace, platform: 'android');
      expect(delegate.textEditingValue.text, 'tet');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 2);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('handles surrogate pairs', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: '\u{1F44D}',
            selection: TextSelection.collapsed(offset: 2),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: '\u{1F44D}',  // Thumbs up
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: 2),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.backspace, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.backspace, platform: 'android');
      expect(delegate.textEditingValue.text, '');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('handles grapheme clusters', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: '0123👨‍👩‍👦2345',
            selection: TextSelection.collapsed(offset: 12),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: '0123👨‍👩‍👦2345',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: 12),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.backspace, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.backspace, platform: 'android');
      expect(delegate.textEditingValue.text, '01232345');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 4);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('is a no-op at the start of the text', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 0),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: 'test',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: 0),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.backspace, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.backspace, platform: 'android');
      expect(delegate.textEditingValue.text, 'test');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('handles obscured text', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
          text: 'test',
          selection: TextSelection.collapsed(offset: 4),
        );

      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.ltr,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        obscureText: true,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: '****',
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: 4),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      await simulateKeyDownEvent(LogicalKeyboardKey.backspace, platform: 'android');
      await simulateKeyUpEvent(LogicalKeyboardKey.backspace, platform: 'android');

      expect(delegate.textEditingValue.text, 'tes');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 3);
    }, skip: isBrowser);
  });

  test('getEndpointsForSelection handles empty characters', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      // This is a Unicode left-to-right mark character that will not render
      // any glyphs.
      text: const TextSpan(text: '\u200e'),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
    );
    editable.layout(BoxConstraints.loose(const Size(100, 100)));
    final List<TextSelectionPoint> endpoints = editable.getEndpointsForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1));
    expect(endpoints[0].point.dx, 0);
  });

  group('nextCharacter', () {
    test('handles normal strings correctly', () {
      expect(RenderEditable.nextCharacter(0, '01234567'), 1);
      expect(RenderEditable.nextCharacter(3, '01234567'), 4);
      expect(RenderEditable.nextCharacter(7, '01234567'), 8);
      expect(RenderEditable.nextCharacter(8, '01234567'), 8);
    });

    test('throws for invalid indices', () {
      expect(() => RenderEditable.nextCharacter(-1, '01234567'), throwsAssertionError);
      expect(() => RenderEditable.nextCharacter(9, '01234567'), throwsAssertionError);
    });

    test('skips spaces in normal strings when includeWhitespace is false', () {
      expect(RenderEditable.nextCharacter(3, '0123 5678', false), 5);
      expect(RenderEditable.nextCharacter(4, '0123 5678', false), 5);
      expect(RenderEditable.nextCharacter(3, '0123      0123', false), 10);
      expect(RenderEditable.nextCharacter(2, '0123      0123', false), 3);
      expect(RenderEditable.nextCharacter(4, '0123      0123', false), 10);
      expect(RenderEditable.nextCharacter(9, '0123      0123', false), 10);
      expect(RenderEditable.nextCharacter(10, '0123      0123', false), 11);
      // If the subsequent characters are all whitespace, it returns the length
      // of the string.
      expect(RenderEditable.nextCharacter(5, '0123      ', false), 10);
    });

    test('handles surrogate pairs correctly', () {
      expect(RenderEditable.nextCharacter(3, '0123👨👩👦0123'), 4);
      expect(RenderEditable.nextCharacter(4, '0123👨👩👦0123'), 6);
      expect(RenderEditable.nextCharacter(5, '0123👨👩👦0123'), 6);
      expect(RenderEditable.nextCharacter(6, '0123👨👩👦0123'), 8);
      expect(RenderEditable.nextCharacter(7, '0123👨👩👦0123'), 8);
      expect(RenderEditable.nextCharacter(8, '0123👨👩👦0123'), 10);
      expect(RenderEditable.nextCharacter(9, '0123👨👩👦0123'), 10);
      expect(RenderEditable.nextCharacter(10, '0123👨👩👦0123'), 11);
    });

    test('handles extended grapheme clusters correctly', () {
      expect(RenderEditable.nextCharacter(3, '0123👨‍👩‍👦2345'), 4);
      expect(RenderEditable.nextCharacter(4, '0123👨‍👩‍👦2345'), 12);
      // Even when extent falls within an extended grapheme cluster, it still
      // identifies the whole grapheme cluster.
      expect(RenderEditable.nextCharacter(5, '0123👨‍👩‍👦2345'), 12);
      expect(RenderEditable.nextCharacter(12, '0123👨‍👩‍👦2345'), 13);
    });
  });

  group('getRectForComposingRange', () {
    const TextSpan emptyTextSpan = TextSpan(text: '\u200e');
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      maxLines: null,
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
    );

    test('returns null when no composing range', () {
      editable.text = const TextSpan(text: '123');
      editable.layout(const BoxConstraints.tightFor(width: 200));

      // Invalid range.
      expect(editable.getRectForComposingRange(const TextRange(start: -1, end: 2)), isNull);
      // Collapsed range.
      expect(editable.getRectForComposingRange(const TextRange.collapsed(2)), isNull);

      // Empty Editable.
      editable.text = emptyTextSpan;
      editable.layout(const BoxConstraints.tightFor(width: 200));

      expect(
        editable.getRectForComposingRange(const TextRange(start: 0, end: 1)),
        // On web this evaluates to a zero-width Rect.
        anyOf(isNull, (Rect rect) => rect.width == 0));
    });

    test('more than 1 run on the same line', () {
      const TextStyle tinyText = TextStyle(fontSize: 1, fontFamily: 'Ahem');
      const TextStyle normalText = TextStyle(fontSize: 10, fontFamily: 'Ahem');
      editable.text = TextSpan(
        children: <TextSpan>[
          const TextSpan(text: 'A', style: tinyText),
          TextSpan(text: 'A' * 20, style: normalText),
          const TextSpan(text: 'A', style: tinyText)
        ],
      );
      // Give it a width that forces the editable to wrap.
      editable.layout(const BoxConstraints.tightFor(width: 200));

      final Rect composingRect = editable.getRectForComposingRange(const TextRange(start: 0, end: 20 + 2))!;

      // Since the range covers an entire line, the Rect should also be almost
      // as wide as the entire paragraph (give or take 1 character).
      expect(composingRect.width, greaterThan(200 - 10));
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/66089
  });

  group('previousCharacter', () {
    test('handles normal strings correctly', () {
      expect(RenderEditable.previousCharacter(8, '01234567'), 7);
      expect(RenderEditable.previousCharacter(0, '01234567'), 0);
      expect(RenderEditable.previousCharacter(1, '01234567'), 0);
      expect(RenderEditable.previousCharacter(5, '01234567'), 4);
      expect(RenderEditable.previousCharacter(8, '01234567'), 7);
    });

    test('throws for invalid indices', () {
      expect(() => RenderEditable.previousCharacter(-1, '01234567'), throwsAssertionError);
      expect(() => RenderEditable.previousCharacter(9, '01234567'), throwsAssertionError);
    });

    test('skips spaces in normal strings when includeWhitespace is false', () {
      expect(RenderEditable.previousCharacter(10, '0123      0123', false), 3);
      expect(RenderEditable.previousCharacter(11, '0123      0123', false), 10);
      expect(RenderEditable.previousCharacter(9, '0123      0123', false), 3);
      expect(RenderEditable.previousCharacter(4, '0123      0123', false), 3);
      expect(RenderEditable.previousCharacter(3, '0123      0123', false), 2);
      // If the previous characters are all whitespace, it returns zero.
      expect(RenderEditable.previousCharacter(3, '          0123', false), 0);
    });

    test('handles surrogate pairs correctly', () {
      expect(RenderEditable.previousCharacter(11, '0123👨👩👦0123'), 10);
      expect(RenderEditable.previousCharacter(10, '0123👨👩👦0123'), 8);
      expect(RenderEditable.previousCharacter(9, '0123👨👩👦0123'), 8);
      expect(RenderEditable.previousCharacter(8, '0123👨👩👦0123'), 6);
      expect(RenderEditable.previousCharacter(7, '0123👨👩👦0123'), 6);
      expect(RenderEditable.previousCharacter(6, '0123👨👩👦0123'), 4);
      expect(RenderEditable.previousCharacter(5, '0123👨👩👦0123'), 4);
      expect(RenderEditable.previousCharacter(4, '0123👨👩👦0123'), 3);
      expect(RenderEditable.previousCharacter(3, '0123👨👩👦0123'), 2);
    });

    test('handles extended grapheme clusters correctly', () {
      expect(RenderEditable.previousCharacter(13, '0123👨‍👩‍👦2345'), 12);
      // Even when extent falls within an extended grapheme cluster, it still
      // identifies the whole grapheme cluster.
      expect(RenderEditable.previousCharacter(12, '0123👨‍👩‍👦2345'), 4);
      expect(RenderEditable.previousCharacter(11, '0123👨‍👩‍👦2345'), 4);
      expect(RenderEditable.previousCharacter(5, '0123👨‍👩‍👦2345'), 4);
      expect(RenderEditable.previousCharacter(4, '0123👨‍👩‍👦2345'), 3);
    });
  });

  group('custom painters', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();

    final _TestRenderEditable editable = _TestRenderEditable(
      textDirection: TextDirection.ltr,
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
      text: const TextSpan(
        text: 'test',
        style: TextStyle(
          height: 1.0,
          fontSize: 10.0,
          fontFamily: 'Ahem',
        ),
      ),
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      selection: const TextSelection.collapsed(
        offset: 4,
        affinity: TextAffinity.upstream,
      ),
    );

    setUp(() { EditableText.debugDeterministicCursor = true; });
    tearDown(() {
      EditableText.debugDeterministicCursor = false;
      _TestRenderEditablePainter.paintHistory.clear();
      editable.foregroundPainter = null;
      editable.painter = null;
      editable.paintCount = 0;

      final AbstractNode? parent = editable.parent;
      if (parent is RenderConstrainedBox)
        parent.child = null;
    });

    test('paints in the correct order', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));
      // Prepare for painting after layout.

      // Foreground painter.
      editable.foregroundPainter = _TestRenderEditablePainter();
      pumpFrame(phase: EnginePhase.compositingBits);

      expect(
        (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
        paints
          ..paragraph()
          ..rect(rect: const Rect.fromLTRB(1, 1, 1, 1), color: const Color(0x12345678)),
      );

      // Background painter.
      editable.foregroundPainter = null;
      editable.painter = _TestRenderEditablePainter();

      expect(
        (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
        paints
          ..rect(rect: const Rect.fromLTRB(1, 1, 1, 1), color: const Color(0x12345678))
          ..paragraph(),
      );

      editable.foregroundPainter = _TestRenderEditablePainter();
      editable.painter = _TestRenderEditablePainter();

      expect(
        (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
        paints
          ..rect(rect: const Rect.fromLTRB(1, 1, 1, 1), color: const Color(0x12345678))
          ..paragraph()
          ..rect(rect: const Rect.fromLTRB(1, 1, 1, 1), color: const Color(0x12345678)),
      );
    });

    test('changing foreground painter', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));
      // Prepare for painting after layout.

      _TestRenderEditablePainter currentPainter = _TestRenderEditablePainter();
      // Foreground painter.
      editable.foregroundPainter = currentPainter;
      pumpFrame(phase: EnginePhase.paint);
      expect(currentPainter.paintCount, 1);

      editable.foregroundPainter = (currentPainter = _TestRenderEditablePainter()..repaint = false);
      pumpFrame(phase: EnginePhase.paint);
      expect(currentPainter.paintCount, 0);

      editable.foregroundPainter = (currentPainter = _TestRenderEditablePainter()..repaint = true);
      pumpFrame(phase: EnginePhase.paint);
      expect(currentPainter.paintCount, 1);
    });

    test('changing background painter', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));
      // Prepare for painting after layout.

      _TestRenderEditablePainter currentPainter = _TestRenderEditablePainter();
      // Foreground painter.
      editable.painter = currentPainter;
      pumpFrame(phase: EnginePhase.paint);
      expect(currentPainter.paintCount, 1);

      editable.painter = (currentPainter = _TestRenderEditablePainter()..repaint = false);
      pumpFrame(phase: EnginePhase.paint);
      expect(currentPainter.paintCount, 0);

      editable.painter = (currentPainter = _TestRenderEditablePainter()..repaint = true);
      pumpFrame(phase: EnginePhase.paint);
      expect(currentPainter.paintCount, 1);
    });

    test('swapping painters', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));

      final _TestRenderEditablePainter painter1 = _TestRenderEditablePainter();
      final _TestRenderEditablePainter painter2 = _TestRenderEditablePainter();

      editable.painter = painter1;
      editable.foregroundPainter = painter2;
      pumpFrame(phase: EnginePhase.paint);
      expect(
        _TestRenderEditablePainter.paintHistory,
        <_TestRenderEditablePainter>[painter1, painter2],
      );

      _TestRenderEditablePainter.paintHistory.clear();
      editable.painter = painter2;
      editable.foregroundPainter = painter1;
      pumpFrame(phase: EnginePhase.paint);
      expect(
        _TestRenderEditablePainter.paintHistory,
        <_TestRenderEditablePainter>[painter2, painter1],
      );
    });

    test('reusing the same painter', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));

      final _TestRenderEditablePainter painter = _TestRenderEditablePainter();
      FlutterErrorDetails? errorDetails;
      editable.painter = painter;
      editable.foregroundPainter = painter;
      pumpFrame(phase: EnginePhase.paint, onErrors: () {
        errorDetails = renderer.takeFlutterErrorDetails();
      });
      expect(errorDetails, isNull);

      expect(
        _TestRenderEditablePainter.paintHistory,
        <_TestRenderEditablePainter>[painter, painter],
      );
      expect(
        (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
        paints
          ..rect(rect: const Rect.fromLTRB(1, 1, 1, 1), color: const Color(0x12345678))
          ..paragraph()
          ..rect(rect: const Rect.fromLTRB(1, 1, 1, 1), color: const Color(0x12345678)),
      );
    });
    test('does not repaint the render editable when custom painters need repaint', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));

      final _TestRenderEditablePainter painter = _TestRenderEditablePainter();
      editable.painter = painter;
      pumpFrame(phase: EnginePhase.paint);
      editable.paintCount = 0;
      painter.paintCount = 0;

      painter.markNeedsPaint();

      pumpFrame(phase: EnginePhase.paint);
      expect(editable.paintCount, 0);
      expect(painter.paintCount, 1);
    });

    test('repaints when its RenderEditable repaints', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));

      final _TestRenderEditablePainter painter = _TestRenderEditablePainter();
      editable.painter = painter;
      pumpFrame(phase: EnginePhase.paint);
      editable.paintCount = 0;
      painter.paintCount = 0;

      editable.markNeedsPaint();

      pumpFrame(phase: EnginePhase.paint);
      expect(editable.paintCount, 1);
      expect(painter.paintCount, 1);
    });

    test('correct coordinate space', () {
      layout(editable, constraints: BoxConstraints.loose(const Size(100, 100)));

      final _TestRenderEditablePainter painter = _TestRenderEditablePainter();
      editable.painter = painter;
      editable.offset = ViewportOffset.fixed(1000);

      pumpFrame(phase: EnginePhase.compositingBits);
      expect(
        (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
        paints
          ..rect(rect: const Rect.fromLTRB(1, 1, 1, 1), color: const Color(0x12345678))
          ..paragraph()
      );
    });
  });
}

class _TestRenderEditable extends RenderEditable {
  _TestRenderEditable({
    required TextDirection textDirection,
    required ViewportOffset offset,
    required TextSelectionDelegate textSelectionDelegate,
    TextSpan? text,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    TextSelection? selection,
  }) : super(
      textDirection: textDirection,
      offset: offset,
      textSelectionDelegate: textSelectionDelegate,
      text: text,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      selection: selection,
    );

  int paintCount = 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    paintCount += 1;
  }
}

class _TestRenderEditablePainter extends RenderEditablePainter {
  bool repaint = true;
  int paintCount = 0;
  static final List<_TestRenderEditablePainter> paintHistory = <_TestRenderEditablePainter>[];

  @override
  void paint(Canvas canvas, Size size, RenderEditable renderEditable) {
    paintCount += 1;
    canvas.drawRect(const Rect.fromLTRB(1, 1, 1, 1), Paint()..color = const Color(0x12345678));
    paintHistory.add(this);
  }

  @override
  bool shouldRepaint(RenderEditablePainter? oldDelegate) => repaint;

  void markNeedsPaint() {
    notifyListeners();
  }
}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/recording_canvas.dart';
import 'rendering_tester.dart';

class FakeEditableTextState extends TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue { return const TextEditingValue(); }

  @override
  set textEditingValue(TextEditingValue value) { }

  @override
  void hideToolbar() { }

  @override
  void bringIntoView(TextPosition position) { }
}

void main() {
  test('editable intrinsics', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      text: const TextSpan(
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: '12345',
      ),
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
        'RenderEditable#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
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
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: const Locale('en', 'US'),
      offset: ViewportOffset.fixed(10.0),
      textSelectionDelegate: delegate,
    );
    editable.layout(BoxConstraints.loose(const Size(1000.0, 1000.0)));
    expect(
      (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
      paints..clipRect(rect: Rect.fromLTRB(0.0, 0.0, 1000.0, 10.0)),
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
      selection: const TextSelection.collapsed(
        offset: 4,
        affinity: TextAffinity.upstream,
      ),
    );

    layout(editable);

    editable.layout(BoxConstraints.loose(const Size(100, 100)));
    expect(
      editable,
      // Draw no cursor by default.
      paintsExactlyCountTimes(#drawRect, 0),
    );

    editable.showCursor = showCursor;
    pumpFrame();

    expect(editable, paints..rect(
      color: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
      rect: Rect.fromLTWH(40, 2, 1, 6),
    ));

    // Now change to a rounded caret.
    editable.cursorColor = const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF);
    editable.cursorWidth = 4;
    editable.cursorRadius = const Radius.circular(3);
    pumpFrame();

    expect(editable, paints..rrect(
      color: const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF),
      rrect: RRect.fromRectAndRadius(
        Rect.fromLTWH(40, 2, 4, 6),
        const Radius.circular(3),
      ),
    ));

    editable.textScaleFactor = 2;
    pumpFrame();

    // Now the caret height is much bigger due to the bigger font scale.
    expect(editable, paints..rrect(
      color: const Color.fromARGB(0xFF, 0x00, 0x00, 0xFF),
      rrect: RRect.fromRectAndRadius(
        Rect.fromLTWH(80, 2, 4, 16),
        const Radius.circular(3),
      ),
    ));

    // Can turn off caret.
    showCursor.value = false;
    pumpFrame();

    expect(editable, paintsExactlyCountTimes(#drawRRect, 0));
  });

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
    pumpFrame();

    expect(
      editable,
      // The paint order is now flipped.
      paints
        ..rect(color: Colors.red[500])
        ..paragraph(),
    );
    expect(editable, paintsExactlyCountTimes(#drawRect, 1));
  });

  test('selects correct place with offsets', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    TextSelection currentSelection;
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
      text: const TextSpan(
        text: 'test\ntest',
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
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

    pumpFrame();

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
  });

  test('selects correct place when offsets are flipped', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    TextSelection currentSelection;
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
    );

    layout(editable);

    editable.selectPositionAt(from: const Offset(30, 2), to: const Offset(10, 2), cause: SelectionChangedCause.drag);
    pumpFrame();

    expect(currentSelection.isCollapsed, isFalse);
    expect(currentSelection.baseOffset, 1);
    expect(currentSelection.extentOffset, 3);
  });

  test('selection does not flicker as user is dragging', () {
    int selectionChangedCount = 0;
    TextSelection updatedSelection;
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
    );

    layout(editable2);

    // Now this should cause a selection change.
    editable2.selectPositionAt(from: const Offset(30, 2), to: const Offset(48, 2), cause: SelectionChangedCause.drag);
    pumpFrame();

    expect(updatedSelection.baseOffset, 3);
    expect(updatedSelection.extentOffset, 5);
    expect(selectionChangedCount, 1);
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
    );

    expect(editable.hasFocus, true);
    editable.hasFocus = false;
    expect(editable.hasFocus, false);
  });
}

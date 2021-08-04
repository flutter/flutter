// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=20210704"
@Tags(<String>['no-shuffle'])

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

// The test_api package is not for general use... it's literally for our use.
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as test_package;

import '../rendering/mock_canvas.dart';
import '../rendering/recording_canvas.dart';
import 'rendering_tester.dart';

class FakeEditableTextState with TextSelectionDelegate {
  @override
  TextEditingValue textEditingValue = TextEditingValue.empty;

  @override
  void hideToolbar([bool hideHandles = true]) { }

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) { }

  @override
  void bringIntoView(TextPosition position) { }
}

@isTest
void testVariants(
  String description,
  AsyncValueGetter<void> callback, {
  bool? skip,
  test_package.Timeout? timeout,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
}) {
  assert(variant != null);
  assert(variant.values.isNotEmpty, 'There must be at least one value to test in the testing variant.');
  for (final dynamic value in variant.values) {
    final String variationDescription = variant.describeValue(value);
    final String combinedDescription = variationDescription.isNotEmpty ? '$description ($variationDescription)' : description;
    test(
      combinedDescription,
      () async {
        Object? memento;
        try {
          memento = await variant.setUp(value);
          await callback();
        } finally {
          await variant.tearDown(value, memento);
        }
      },
      skip: skip,
      timeout: timeout,
      tags: tags,
    );
  }
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
    context.paintChild(defaultEditable, Offset.zero);
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
      context.paintChild(editable, Offset.zero);
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
    expect(editable.getMaxIntrinsicWidth(double.infinity), 52.0);
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
        '   ╚═══════════\n',
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

    // TODO(yjbanov): ahem.ttf doesn't have Chinese glyphs, making this test
    //                sensitive to browser/OS when running in web mode:
    //                https://github.com/flutter/flutter/issues/83129
  }, skip: kIsWeb);

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

  test('selects correct place with offsets', () {
    const String text = 'test\ntest';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        text: text,
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

  test('selects readonly renderEditable matches native behavior for android', () {
    // Regression test for https://github.com/flutter/flutter/issues/79166.
    final TargetPlatform? previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const String text = '  test';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    late TextSelection currentSelection;
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      readOnly: true,
      offset: viewportOffset,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 4,
      ),
    );

    layout(editable);

    // Select the second white space, where the text position = 1.
    editable.selectWordsInRange(from: const Offset(10, 2), cause:SelectionChangedCause.longPress);
    pumpFrame();
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 1);
    expect(currentSelection.extentOffset, 2);
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  test('selects renderEditable matches native behavior for iOS case 1', () {
    // Regression test for https://github.com/flutter/flutter/issues/79166.
    final TargetPlatform? previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const String text = '  test';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 4,
      ),
    );

    layout(editable);

    // Select the second white space, where the text position = 1.
    editable.selectWordsInRange(from: const Offset(10, 2), cause:SelectionChangedCause.longPress);
    pumpFrame();
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 1);
    expect(currentSelection.extentOffset, 6);
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  test('selects renderEditable matches native behavior for iOS case 2', () {
    // Regression test for https://github.com/flutter/flutter/issues/79166.
    final TargetPlatform? previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const String text = '   ';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        text: text,
        style: TextStyle(
          height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
        ),
      ),
      selection: const TextSelection.collapsed(
        offset: 4,
      ),
    );

    layout(editable);

    // Select the second white space, where the text position = 1.
    editable.selectWordsInRange(from: const Offset(10, 2), cause:SelectionChangedCause.longPress);
    pumpFrame();
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 1);
    expect(currentSelection.extentOffset, 1);
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  test('selects correct place when offsets are flipped', () {
    const String text = 'abc def ghi';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        text: text,
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
    const String text = 'abc def ghi';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
    const TextSpan span = TextSpan(
      text: text,
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
      text: span,
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
      text: span,
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

  test('moveSelectionLeft/RightByLine stays on the current line', () async {
    const String text = 'one two three\n\nfour five six';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(
          text: text,
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
        renderObject.selection = selection;
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: text,
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

    // Move to the end of the first line.
    editable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 13);
    expect(currentSelection.affinity, TextAffinity.upstream);
    // RenderEditable relies on its parent that passes onSelectionChanged to set
    // the selection.

    // Try moveSelectionRightByLine again and nothing happens because we're
    // already at the end of a line.
    editable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 13);
    expect(currentSelection.affinity, TextAffinity.upstream);

    // Move back to the start of the line.
    editable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);
    expect(currentSelection.affinity, TextAffinity.downstream);

    // Trying moveSelectionLeftByLine does nothing at the leftmost of the field.
    editable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);
    expect(currentSelection.affinity, TextAffinity.downstream);

    // Move the selection to the empty line.
    editable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 13);
    expect(currentSelection.affinity, TextAffinity.upstream);
    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 14);

    // Neither moveSelectionLeftByLine nor moveSelectionRightByLine do anything
    // here, because we're at both the beginning and end of the line.
    editable.moveSelectionLeftByLine(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 14);
    expect(currentSelection.affinity, TextAffinity.downstream);
    editable.moveSelectionRightByLine(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 14);
    expect(currentSelection.affinity, TextAffinity.downstream);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

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
        renderObject.selection = selection;
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

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 1);

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);

    editable.deleteForward(SelectionChangedCause.keyboard);
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
        renderObject.selection = selection;
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

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 6);

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);

    editable.deleteForward(SelectionChangedCause.keyboard);
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
        renderObject.selection = selection;
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

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 12);

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);

    editable.deleteForward(SelectionChangedCause.keyboard);
    expect(delegate.textEditingValue.text, '01232345');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys and delete handle surrogate pairs correctly case 2', () async {
    const String text = '\u{1F44D}';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        renderObject.selection = selection;
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: text,  // Thumbs up
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

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);

    editable.deleteForward(SelectionChangedCause.keyboard);
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

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(editable.selection?.isCollapsed, true);
    expect(editable.selection?.baseOffset, 4);

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(editable.selection?.isCollapsed, true);
    expect(editable.selection?.baseOffset, 3);

     editable.deleteForward(SelectionChangedCause.keyboard);
    expect(delegate.textEditingValue.text, 'W Sczebrzeszynie chrząszcz brzmi w trzcinie');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('RenderEditable registers and unregisters raw keyboard listener correctly', () async {
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(
        text: 'how are you',
        selection: TextSelection.collapsed(offset: 0),
      );
    final ViewportOffset viewportOffset = ViewportOffset.zero();
    final RenderEditable editable = RenderEditable(
      backgroundCursorColor: Colors.grey,
      selectionColor: Colors.black,
      textDirection: TextDirection.ltr,
      cursorColor: Colors.red,
      offset: viewportOffset,
      hasFocus: true,
      textSelectionDelegate: delegate,
      onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {
        renderObject.selection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: 'how are you',
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

    editable.deleteForward(SelectionChangedCause.keyboard);
    expect(delegate.textEditingValue.text, 'ow are you');
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

  test('arrow keys with selection text', () async {
    const String text = '012345';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        renderObject.selection = selection;
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: text,  // Thumbs up
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

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 4);

    editable.selection = const TextSelection(baseOffset: 2, extentOffset: 4);
    pumpFrame();

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  test('arrow keys with selection text and shift', () async {
    const String text = '012345';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        renderObject.selection = selection;
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: text,  // Thumbs up
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

    editable.extendSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 2);
    expect(currentSelection.extentOffset, 5);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    editable.extendSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 4);
    expect(currentSelection.extentOffset, 3);

    editable.selection = const TextSelection(baseOffset: 2, extentOffset: 4);
    pumpFrame();

    editable.extendSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 2);
    expect(currentSelection.extentOffset, 3);

    editable.selection = const TextSelection(baseOffset: 4, extentOffset: 2);
    pumpFrame();

    editable.extendSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, false);
    expect(currentSelection.baseOffset, 4);
    expect(currentSelection.extentOffset, 1);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/58068

  testVariants('respects enableInteractiveSelection', () async {
    const String text = '012345';
    final TextSelectionDelegate delegate = FakeEditableTextState()
      ..textEditingValue = const TextEditingValue(text: text);
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
        renderObject.selection = selection;
        currentSelection = selection;
      },
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      text: const TextSpan(
        text: text,  // Thumbs up
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

    editable.moveSelectionRight(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 3);

    editable.moveSelectionLeft(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 2);

    final LogicalKeyboardKey wordModifier =
        Platform.isMacOS ? LogicalKeyboardKey.alt : LogicalKeyboardKey.control;

    await simulateKeyDownEvent(wordModifier);

    editable.moveSelectionRightByWord(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 6);

    editable.moveSelectionLeftByWord(SelectionChangedCause.keyboard);
    expect(currentSelection.isCollapsed, true);
    expect(currentSelection.baseOffset, 0);

    await simulateKeyUpEvent(wordModifier);
    await simulateKeyUpEvent(LogicalKeyboardKey.shift);
  }, skip: isBrowser, variant: KeySimulatorTransitModeVariant.all()); // https://github.com/flutter/flutter/issues/58068

  group('delete', () {
    test('when as a non-collapsed selection, it should delete a selection', () async {
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

      editable.delete(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'tt');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 1);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when as simple text, it should delete the character to the left', () async {
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

      editable.delete(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'tet');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 2);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when has surrogate pairs, it should delete the pair', () async {
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

      editable.delete(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, '');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when has grapheme clusters, it should delete the grapheme cluster', () async {
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

      editable.delete(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, '01232345');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 4);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when is at the start of the text, it should be a no-op', () async {
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

      editable.delete(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when input has obscured text, it should delete the character to the left', () async {
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

      editable.delete(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'tes');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 3);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
        const String text = '用多個塊測試';
        const int offset = 4;
        final TextSelectionDelegate delegate = FakeEditableTextState()
          ..textEditingValue = const TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: offset),
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
            text: text,
            style: TextStyle(
              height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
            ),
          ),
          selection: const TextSelection.collapsed(offset: offset),
        );

        layout(editable);
        editable.hasFocus = true;
        pumpFrame();

        editable.delete(SelectionChangedCause.keyboard);
        expect(delegate.textEditingValue.text, '用多個測試');
        expect(delegate.textEditingValue.selection.isCollapsed, true);
        expect(delegate.textEditingValue.selection.baseOffset, 3);
      }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = text.length;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.rtl,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.delete(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'برنامج أهلا بالعال');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, text.length - 1);
    }, skip: isBrowser);
  });

  group('deleteByWord', () {
    test('when cursor is on the middle of a word, it should delete the left part of the word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 8;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test h multiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when includeWhiteSpace is true, it should treat a whiteSpace as a single word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 10;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test withmultiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 9);
    }, skip: isBrowser);

    test('when cursor is after a word, it should delete the whole word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 9;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test  multiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when cursor is preceeded by white spaces, it should delete the spaces and the next word to the left', () async {
      const String text = 'test with   multiple blocks';
      const int offset = 12;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test multiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when cursor is preceeded by tabs spaces', () async {
      const String text = 'test with\t\t\tmultiple blocks';
      const int offset = 12;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test multiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when cursor is preceeded by break line, it should delete the breaking line and the word right before it', () async {
      const String text = 'test with\nmultiple blocks';
      const int offset = 10;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test multiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 5);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
        const String text = '用多個塊測試';
        const int offset = 4;
        final TextSelectionDelegate delegate = FakeEditableTextState()
          ..textEditingValue = const TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: offset),
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
            text: text,
            style: TextStyle(
              height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
            ),
          ),
          selection: const TextSelection.collapsed(offset: offset),
        );

        layout(editable);
        editable.hasFocus = true;
        pumpFrame();

        editable.deleteByWord(SelectionChangedCause.keyboard, false);
        expect(delegate.textEditingValue.text, '用多個測試');
        expect(delegate.textEditingValue.selection.isCollapsed, true);
        expect(delegate.textEditingValue.selection.baseOffset, 3);
      }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = text.length;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.rtl,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'برنامج أهلا ');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 12);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything before the selection', () async {
      const int offset = 21;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
          text: 'test with multiple\n\n words',
          selection: TextSelection.collapsed(offset: offset),
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
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'words');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);
  });

  group('deleteByLine', () {
    test('when cursor is on last character of a line, it should delete everything to the left', () async {
      const String text = 'test with multiple blocks';
      const int offset = text.length;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, '');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

    test('when cursor is on the middle of a word, it should delete delete everything to the left', () async {
      const String text = 'test with multiple blocks';
      const int offset = 8;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'h multiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

    test('when previous character is a breakline, it should preserve it', () async {
      const String text = 'test with\nmultiple blocks';
      const int offset = 10;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, text);
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when text is multiline, it should delete until the first line break it finds', () async {
      const String text = 'test with\n\nMore stuff right here.\nmultiple blocks';
      const int offset = 22;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test with\n\nright here.\nmultiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 11);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything before the selection', () async {
      const int offset = 21;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
          text: 'test with multiple\n\n words',
          selection: TextSelection.collapsed(offset: offset),
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
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'words');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);
  });

  group('deleteForward', () {
    test('when as a non-collapsed selection, it should delete a selection', () async {
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

      editable.deleteForward(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'tt');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 1);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when includeWhiteSpace is true, it should treat a whiteSpace as a single word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 9;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test withmultiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 9);
    }, skip: isBrowser);

    test('when at the end of a text, it should be a no-op', () async {
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

      editable.deleteForward(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 4);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('when the input has obscured text, it should delete the forward character', () async {
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

      editable.deleteForward(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'est');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
        const String text = '用多個塊測試';
        const int offset = 0;
        final TextSelectionDelegate delegate = FakeEditableTextState()
          ..textEditingValue = const TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: offset),
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
            text: text,
            style: TextStyle(
              height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
            ),
          ),
          selection: const TextSelection.collapsed(offset: offset),
        );

        layout(editable);
        editable.hasFocus = true;
        pumpFrame();

        editable.deleteForward(SelectionChangedCause.keyboard);
        expect(delegate.textEditingValue.text, '多個塊測試');
        expect(delegate.textEditingValue.selection.isCollapsed, true);
        expect(delegate.textEditingValue.selection.baseOffset, 0);
      }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = 0;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.rtl,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForward(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'رنامج أهلا بالعالم');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, 0);
    }, skip: isBrowser);

  });

  group('deleteForwardByWord', () {
    test('when cursor is on the middle of a word, it should delete the next part of the word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 6;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test w multiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is before a word, it should delete the whole word', () async {
      const String text = 'test with multiple blocks';
      const int offset = 10;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test with  blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is preceeded by white spaces, it should delete the spaces and the next word', () async {
      const String text = 'test with   multiple blocks';
      const int offset = 9;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test with blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is before tabs, it should delete the tabs and the next word', () async {
      const String text = 'test with\t\t\tmultiple blocks';
      const int offset = 9;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test with blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is followed by break line, it should delete the next word', () async {
      const String text = 'test with\n\n\nmultiple blocks';
      const int offset = 9;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test with blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when using cjk characters', () async {
        const String text = '用多個塊測試';
        const int offset = 0;
        final TextSelectionDelegate delegate = FakeEditableTextState()
          ..textEditingValue = const TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: offset),
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
            text: text,
            style: TextStyle(
              height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
            ),
          ),
          selection: const TextSelection.collapsed(offset: offset),
        );

        layout(editable);
        editable.hasFocus = true;
        pumpFrame();

        editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
        expect(delegate.textEditingValue.text, '多個塊測試');
        expect(delegate.textEditingValue.selection.isCollapsed, true);
        expect(delegate.textEditingValue.selection.baseOffset, offset);
      }, skip: isBrowser);

    test('when using rtl', () async {
      const String text = 'برنامج أهلا بالعالم';
      const int offset = 0;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
          );
      final ViewportOffset viewportOffset = ViewportOffset.zero();
      final RenderEditable editable = RenderEditable(
        backgroundCursorColor: Colors.grey,
        selectionColor: Colors.black,
        textDirection: TextDirection.rtl,
        cursorColor: Colors.red,
        offset: viewportOffset,
        textSelectionDelegate: delegate,
        onSelectionChanged: (TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause) {},
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        text: const TextSpan(
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, ' أهلا بالعالم');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything after the selection', () async {
      const int offset = 4;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
          text: 'test with multiple\n\n words',
          selection: TextSelection.collapsed(offset: offset),
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
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByWord(SelectionChangedCause.keyboard, false);
      expect(delegate.textEditingValue.text, 'test');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);
  });

  group('deleteForwardByLine', () {
    test('when cursor is on first character of a line, it should delete everything that follows', () async {
      const String text = 'test with multiple blocks';
      const int offset = 4;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when cursor is on the middle of a word, it should delete delete everything that follows', () async {
      const String text = 'test with multiple blocks';
      const int offset = 8;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test wit');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when next character is a breakline, it should preserve it', () async {
      const String text = 'test with\n\n\nmultiple blocks';
      const int offset = 9;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, text);
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when text is multiline, it should delete until the first line break it finds', () async {
      const String text = 'test with\n\nMore stuff right here.\nmultiple blocks';
      const int offset = 2;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: offset),
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
          text: text,
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
        ),
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'te\n\nMore stuff right here.\nmultiple blocks');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
    }, skip: isBrowser);

    test('when input has obscured text, it should delete everything after the selection', () async {
      const int offset = 4;
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
          text: 'test with multiple\n\n words',
          selection: TextSelection.collapsed(offset: offset),
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
        selection: const TextSelection.collapsed(offset: offset),
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      editable.deleteForwardByLine(SelectionChangedCause.keyboard);
      expect(delegate.textEditingValue.text, 'test');
      expect(delegate.textEditingValue.selection.isCollapsed, true);
      expect(delegate.textEditingValue.selection.baseOffset, offset);
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
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
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
        anyOf(isNull, (Rect rect) => rect.width == 0),
      );
    });

    test('more than 1 run on the same line', () {
      const TextStyle tinyText = TextStyle(fontSize: 1, fontFamily: 'Ahem');
      const TextStyle normalText = TextStyle(fontSize: 10, fontFamily: 'Ahem');
      editable.text = TextSpan(
        children: <TextSpan>[
          const TextSpan(text: 'A', style: tinyText),
          TextSpan(text: 'A' * 20, style: normalText),
          const TextSpan(text: 'A', style: tinyText),
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
          ..paragraph(),
      );
    });

    group('hit testing', () {
      test('hits correct TextSpan when not scrolled', () {
        final TextSelectionDelegate delegate = FakeEditableTextState();
        final RenderEditable editable = RenderEditable(
          text: const TextSpan(
            style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
            children: <InlineSpan>[
              TextSpan(text: 'A'),
              TextSpan(text: 'B'),
            ],
          ),
          startHandleLayerLink: LayerLink(),
          endHandleLayerLink: LayerLink(),
          textDirection: TextDirection.ltr,
          offset: ViewportOffset.fixed(0.0),
          textSelectionDelegate: delegate,
          selection: const TextSelection.collapsed(
            offset: 0,
          ),
        );
        layout(editable, constraints: BoxConstraints.loose(const Size(500.0, 500.0)));
        // Prepare for painting after layout.
        pumpFrame(phase: EnginePhase.compositingBits);

        BoxHitTestResult result = BoxHitTestResult();
        editable.hitTest(result, position: Offset.zero);
        // We expect two hit test entries in the path because the RenderEditable
        // will add itself as well.
        expect(result.path, hasLength(2));
        HitTestTarget target = result.path.first.target;
        expect(target, isA<TextSpan>());
        expect((target as TextSpan).text, 'A');
        // Only testing the RenderEditable entry here once, not anymore below.
        expect(result.path.last.target, isA<RenderEditable>());

        result = BoxHitTestResult();
        editable.hitTest(result, position: const Offset(15.0, 0.0));
        expect(result.path, hasLength(2));
        target = result.path.first.target;
        expect(target, isA<TextSpan>());
        expect((target as TextSpan).text, 'B');
      });

      test('hits correct TextSpan when scrolled vertically', () {
        final TextSelectionDelegate delegate = FakeEditableTextState();
        final RenderEditable editable = RenderEditable(
          text: const TextSpan(
            style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
            children: <InlineSpan>[
              TextSpan(text: 'A'),
              TextSpan(text: 'B\n'),
              TextSpan(text: 'C'),
            ],
          ),
          startHandleLayerLink: LayerLink(),
          endHandleLayerLink: LayerLink(),
          textDirection: TextDirection.ltr,
          // Given maxLines of null and an offset of 5, the editable will be
          // scrolled vertically by 5 pixels.
          maxLines: null,
          offset: ViewportOffset.fixed(5.0),
          textSelectionDelegate: delegate,
          selection: const TextSelection.collapsed(
            offset: 0,
          ),
        );
        layout(editable, constraints: BoxConstraints.loose(const Size(500.0, 500.0)));
        // Prepare for painting after layout.
        pumpFrame(phase: EnginePhase.compositingBits);

        BoxHitTestResult result = BoxHitTestResult();
        editable.hitTest(result, position: Offset.zero);
        expect(result.path, hasLength(2));
        HitTestTarget target = result.path.first.target;
        expect(target, isA<TextSpan>());
        expect((target as TextSpan).text, 'A');

        result = BoxHitTestResult();
        editable.hitTest(result, position: const Offset(15.0, 0.0));
        expect(result.path, hasLength(2));
        target = result.path.first.target;
        expect(target, isA<TextSpan>());
        expect((target as TextSpan).text, 'B\n');

        result = BoxHitTestResult();
        // When we hit at y=6 and are scrolled by -5 vertically, we expect "C"
        // to be hit because the font size is 10.
        editable.hitTest(result, position: const Offset(0.0, 6.0));
        expect(result.path, hasLength(2));
        target = result.path.first.target;
        expect(target, isA<TextSpan>());
        expect((target as TextSpan).text, 'C');
      });

      test('hits correct TextSpan when scrolled horizontally', () {
        final TextSelectionDelegate delegate = FakeEditableTextState();
        final RenderEditable editable = RenderEditable(
          text: const TextSpan(
            style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
            children: <InlineSpan>[
              TextSpan(text: 'A'),
              TextSpan(text: 'B'),
            ],
          ),
          startHandleLayerLink: LayerLink(),
          endHandleLayerLink: LayerLink(),
          textDirection: TextDirection.ltr,
          // Given maxLines of 1 and an offset of 5, the editable will be
          // scrolled by 5 pixels to the left.
          maxLines: 1,
          offset: ViewportOffset.fixed(5.0),
          textSelectionDelegate: delegate,
          selection: const TextSelection.collapsed(
            offset: 0,
          ),
        );
        layout(editable, constraints: BoxConstraints.loose(const Size(500.0, 500.0)));
        // Prepare for painting after layout.
        pumpFrame(phase: EnginePhase.compositingBits);

        final BoxHitTestResult result = BoxHitTestResult();
        // At x=6, we should hit "B" as we are scrolled to the left by 6
        // pixels.
        editable.hitTest(result, position: const Offset(6.0, 0));
        expect(result.path, hasLength(2));
        final HitTestTarget target = result.path.first.target;
        expect(target, isA<TextSpan>());
        expect((target as TextSpan).text, 'B');
      });
    });
  });

  group('delete API implementations', () {
    // Regression test for: https://github.com/flutter/flutter/issues/80226.
    //
    // This textSelectionDelegate has different text and selection from the
    // render editable.
    final FakeEditableTextState delegate = FakeEditableTextState();

    late RenderEditable editable;

    setUp(() {
      editable = RenderEditable(
        text: TextSpan(
          text: 'A ' * 50,
        ),
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        textDirection: TextDirection.ltr,
        offset: ViewportOffset.fixed(0),
        textSelectionDelegate: delegate,
        selection: const TextSelection(baseOffset: 0, extentOffset: 50),
      );

      delegate.textEditingValue = const TextEditingValue(
        text: 'BBB',
        selection: TextSelection.collapsed(offset: 0),
      );
    });

    void verifyDoesNotCrashWithInconsistentTextEditingValue(void Function(SelectionChangedCause) method) {
      editable = RenderEditable(
        text: TextSpan(
          text: 'A ' * 50,
        ),
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        textDirection: TextDirection.ltr,
        offset: ViewportOffset.fixed(0),
        textSelectionDelegate: delegate,
        selection: const TextSelection(baseOffset: 0, extentOffset: 50),
      );

      layout(editable, constraints: BoxConstraints.loose(const Size(500.0, 500.0)));
      dynamic error;
      try {
        method(SelectionChangedCause.tap);
      } catch (e) {
        error = e;
      }
      expect(error, isNull);
    }

    test('delete is not racy and handles composing region correctly', () {
      delegate.textEditingValue = const TextEditingValue(
        text: 'ABCDEF',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 6),
      );
      verifyDoesNotCrashWithInconsistentTextEditingValue(editable.delete);
      final TextEditingValue textEditingValue = editable.textSelectionDelegate.textEditingValue;
      expect(textEditingValue.text, 'ACDEF');
      expect(textEditingValue.selection.isCollapsed, isTrue);
      expect(textEditingValue.selection.baseOffset, 1);
      expect(textEditingValue.composing, const TextRange(start: 1, end: 5));
    });

    test('deleteForward is not racy and handles composing region correctly', () {
      delegate.textEditingValue = const TextEditingValue(
        text: 'ABCDEF',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 2, end: 6),
      );
      verifyDoesNotCrashWithInconsistentTextEditingValue(editable.deleteForward);
      final TextEditingValue textEditingValue = editable.textSelectionDelegate.textEditingValue;
      expect(textEditingValue.text, 'ABDEF');
      expect(textEditingValue.selection.isCollapsed, isTrue);
      expect(textEditingValue.selection.baseOffset, 2);
      expect(textEditingValue.composing, const TextRange(start: 2, end: 5));
    });
  });

  group('WidgetSpan support', () {
    test('able to render basic WidgetSpan', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final List<RenderBox> renderBoxes = <RenderBox>[
        RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      ];
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
        text: TextSpan(
          style: const TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
          children: <InlineSpan>[
            const TextSpan(text: 'test'),
            WidgetSpan(child: Container(width: 10, height: 10, color: Colors.blue)),
          ],
        ),
        selection: const TextSelection.collapsed(offset: 3),
        children: renderBoxes,
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      final Rect composingRect = editable.getRectForComposingRange(const TextRange(start: 4, end: 5))!;
      expect(composingRect, const Rect.fromLTRB(40.0, 0.0, 54.0, 14.0));
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('able to render multiple WidgetSpans', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final List<RenderBox> renderBoxes = <RenderBox>[
        RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'c'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'd'), textDirection: TextDirection.ltr),
      ];
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
        text: TextSpan(
          style: const TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
          children: <InlineSpan>[
            const TextSpan(text: 'test'),
            WidgetSpan(child: Container(width: 10, height: 10, color: Colors.blue)),
            WidgetSpan(child: Container(width: 10, height: 10, color: Colors.blue)),
            WidgetSpan(child: Container(width: 10, height: 10, color: Colors.blue)),
          ],
        ),
        selection: const TextSelection.collapsed(offset: 3),
        children: renderBoxes,
      );

      layout(editable);
      editable.hasFocus = true;
      pumpFrame();

      final Rect composingRect = editable.getRectForComposingRange(const TextRange(start: 4, end: 7))!;
      expect(composingRect, const Rect.fromLTRB(40.0, 0.0, 82.0, 14.0));
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('able to render WidgetSpans with line wrap', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final List<RenderBox> renderBoxes = <RenderBox>[
        RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'c'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'd'), textDirection: TextDirection.ltr),
      ];
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
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
          children: <InlineSpan>[
            TextSpan(text: 'test'),
            WidgetSpan(child: Text('b')),
            WidgetSpan(child: Text('c')),
            WidgetSpan(child: Text('d')),
          ],
        ),
        selection: const TextSelection.collapsed(offset: 3),
        maxLines: 2,
        minLines: 2,
        children: renderBoxes,
      );

      // Force a line wrap
      layout(editable, constraints: const BoxConstraints(maxWidth: 75));
      editable.hasFocus = true;
      pumpFrame();

      Rect composingRect = editable.getRectForComposingRange(const TextRange(start: 4, end: 6))!;
      expect(composingRect, const Rect.fromLTRB(40.0, 0.0, 68.0, 14.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 6, end: 7))!;
      expect(composingRect, const Rect.fromLTRB(0.0, 14.0, 14.0, 28.0));
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('able to render WidgetSpans with line wrap alternating spans', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final List<RenderBox> renderBoxes = <RenderBox>[
        RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'c'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'd'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'e'), textDirection: TextDirection.ltr),
      ];
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
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
          children: <InlineSpan>[
            TextSpan(text: 'test'),
            WidgetSpan(child: Text('b')),
            WidgetSpan(child: Text('c')),
            WidgetSpan(child: Text('d')),
            TextSpan(text: 'HI'),
            WidgetSpan(child: Text('e')),
          ],
        ),
        selection: const TextSelection.collapsed(offset: 3),
        maxLines: 2,
        minLines: 2,
        children: renderBoxes,
      );

      // Force a line wrap
      layout(editable, constraints: const BoxConstraints(maxWidth: 75));
      editable.hasFocus = true;
      pumpFrame();

      Rect composingRect = editable.getRectForComposingRange(const TextRange(start: 4, end: 6))!;
      expect(composingRect, const Rect.fromLTRB(40.0, 0.0, 68.0, 14.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 6, end: 7))!;
      expect(composingRect, const Rect.fromLTRB(0.0, 14.0, 14.0, 28.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 7, end: 8))!; // H
      expect(composingRect, const Rect.fromLTRB(14.0, 18.0, 24.0, 28.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 8, end: 9))!; // I
      expect(composingRect, const Rect.fromLTRB(24.0, 18.0, 34.0, 28.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 9, end: 10))!;
      expect(composingRect, const Rect.fromLTRB(34.0, 14.0, 48.0, 28.0));
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('able to render WidgetSpans nested spans', () async {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final List<RenderBox> renderBoxes = <RenderBox>[
        RenderParagraph(const TextSpan(text: 'a'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'c'), textDirection: TextDirection.ltr),
      ];
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
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
          children: <InlineSpan>[
            TextSpan(text: 'test'),
            WidgetSpan(child: Text('a')),
            TextSpan(children: <InlineSpan>[
                WidgetSpan(child: Text('b')),
                WidgetSpan(child: Text('c')),
              ],
            ),
          ],
        ),
        selection: const TextSelection.collapsed(offset: 3),
        maxLines: 2,
        minLines: 2,
        children: renderBoxes,
      );

      // Force a line wrap
      layout(editable, constraints: const BoxConstraints(maxWidth: 75));
      editable.hasFocus = true;
      pumpFrame();

      Rect? composingRect = editable.getRectForComposingRange(const TextRange(start: 4, end: 5));
      expect(composingRect, const Rect.fromLTRB(40.0, 0.0, 54.0, 14.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 5, end: 6));
      expect(composingRect, const Rect.fromLTRB(54.0, 0.0, 68.0, 14.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 6, end: 7));
      expect(composingRect, const Rect.fromLTRB(0.0, 14.0, 14.0, 28.0));
      composingRect = editable.getRectForComposingRange(const TextRange(start: 7, end: 8));
      expect(composingRect, null);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61021

    test('can compute IntrinsicWidth for WidgetSpans', () {
      // Regression test for https://github.com/flutter/flutter/issues/59316
      const double screenWidth = 1000.0;
      const double fixedHeight = 1000.0;
      const String sentence = 'one two';
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final List<RenderBox> renderBoxes = <RenderBox>[
        RenderParagraph(const TextSpan(text: sentence), textDirection: TextDirection.ltr),
      ];
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
          style: TextStyle(
            height: 1.0, fontSize: 10.0, fontFamily: 'Ahem',
          ),
          children: <InlineSpan>[
            TextSpan(text: 'test'),
            WidgetSpan(child: Text('a')),
          ],
        ),
        selection: const TextSelection.collapsed(offset: 3),
        maxLines: 2,
        minLines: 2,
        textScaleFactor: 2.0,
        children: renderBoxes,
      );
      layout(editable, constraints: const BoxConstraints(maxWidth: screenWidth));
      editable.hasFocus = true;
      final double maxIntrinsicWidth = editable.computeMaxIntrinsicWidth(fixedHeight);
      pumpFrame();

      expect(maxIntrinsicWidth, 278);
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

    test('hits correct WidgetSpan when not scrolled', () {
      final TextSelectionDelegate delegate = FakeEditableTextState()
        ..textEditingValue = const TextEditingValue(
            text: 'test',
            selection: TextSelection.collapsed(offset: 3),
          );
      final List<RenderBox> renderBoxes = <RenderBox>[
        RenderParagraph(const TextSpan(text: 'a'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
        RenderParagraph(const TextSpan(text: 'c'), textDirection: TextDirection.ltr),
      ];
      final RenderEditable editable = RenderEditable(
        text: const TextSpan(
          style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
          children: <InlineSpan>[
            TextSpan(text: 'test'),
            WidgetSpan(child: Text('a')),
            TextSpan(children: <InlineSpan>[
                WidgetSpan(child: Text('b')),
                WidgetSpan(child: Text('c')),
              ],
            ),
          ],
        ),
        startHandleLayerLink: LayerLink(),
        endHandleLayerLink: LayerLink(),
        textDirection: TextDirection.ltr,
        offset: ViewportOffset.fixed(0.0),
        textSelectionDelegate: delegate,
        selection: const TextSelection.collapsed(
          offset: 0,
        ),
        children: renderBoxes,
      );
      layout(editable, constraints: BoxConstraints.loose(const Size(500.0, 500.0)));
      // Prepare for painting after layout.
      pumpFrame(phase: EnginePhase.compositingBits);
      BoxHitTestResult result = BoxHitTestResult();
      editable.hitTest(result, position: Offset.zero);
      // We expect two hit test entries in the path because the RenderEditable
      // will add itself as well.
      expect(result.path, hasLength(2));
      HitTestTarget target = result.path.first.target;
      expect(target, isA<TextSpan>());
      expect((target as TextSpan).text, 'test');
      // Only testing the RenderEditable entry here once, not anymore below.
      expect(result.path.last.target, isA<RenderEditable>());
      result = BoxHitTestResult();
      editable.hitTest(result, position: const Offset(15.0, 0.0));
      expect(result.path, hasLength(2));
      target = result.path.first.target;
      expect(target, isA<TextSpan>());
      expect((target as TextSpan).text, 'test');

      result = BoxHitTestResult();
      editable.hitTest(result, position: const Offset(41.0, 0.0));
      expect(result.path, hasLength(3));
      target = result.path.first.target;
      expect(target, isA<TextSpan>());
      expect((target as TextSpan).text, 'a');

      result = BoxHitTestResult();
      editable.hitTest(result, position: const Offset(55.0, 0.0));
      expect(result.path, hasLength(3));
      target = result.path.first.target;
      expect(target, isA<TextSpan>());
      expect((target as TextSpan).text, 'b');

      result = BoxHitTestResult();
      editable.hitTest(result, position: const Offset(69.0, 5.0));
      expect(result.path, hasLength(3));
      target = result.path.first.target;
      expect(target, isA<TextSpan>());
      expect((target as TextSpan).text, 'c');

      result = BoxHitTestResult();
      editable.hitTest(result, position: const Offset(5.0, 15.0));
      expect(result.path, hasLength(0));
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020
  });

  test('does not skip TextPainter.layout because of invalid cache', () {
    // Regression test for https://github.com/flutter/flutter/issues/84896.
    final TextSelectionDelegate delegate = FakeEditableTextState();
    const BoxConstraints constraints = BoxConstraints(minWidth: 100, maxWidth: 500);
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
      forceLine: true,
      offset: ViewportOffset.fixed(10.0),
      textSelectionDelegate: delegate,
      selection: const TextSelection.collapsed(offset: 0),
      cursorColor: const Color(0xFFFFFFFF),
      showCursor: ValueNotifier<bool>(true),
    );
    layout(editable, constraints: constraints);

    final double initialWidth = editable.computeDryLayout(constraints).width;
    expect(initialWidth, 500);

    // Turn off forceLine. Now the width should be significantly smaller.
    editable.forceLine = false;
    expect(editable.computeDryLayout(constraints).width, lessThan(initialWidth));
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

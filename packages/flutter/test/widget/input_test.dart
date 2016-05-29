// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sky_services/editing/editing.mojom.dart' as mojom;

class MockKeyboard extends mojom.KeyboardProxy {
  MockKeyboard() : super.unbound();

  mojom.KeyboardClient client;

  @override
  void setClient(mojom.KeyboardClientStub client, mojom.KeyboardConfiguration configuraiton) {
    this.client = client.impl;
  }

  @override
  void show() {}

  @override
  void hide() {}

  @override
  void setEditingState(mojom.EditingState state) {}
}

class MockClipboard extends mojom.ClipboardProxy {
  MockClipboard() : super.unbound();

  mojom.ClipboardData _clip;

  @override
  void setClipboardData(mojom.ClipboardData clip) {
    _clip = clip;
  }

  @override
  dynamic getClipboardData(String format,[Function responseFactory = null]) {
    return new mojom.ClipboardGetClipboardDataResponseParams()..clip = _clip;
  }
}

void main() {
  MockKeyboard mockKeyboard = new MockKeyboard();
  serviceMocker.registerMockService(mockKeyboard);
  MockClipboard mockClipboard = new MockClipboard();
  serviceMocker.registerMockService(mockClipboard);

  void enterText(String testValue) {
    // Simulate entry of text through the keyboard.
    expect(mockKeyboard.client, isNotNull);
    mockKeyboard.client.updateEditingState(new mojom.EditingState()
      ..text = testValue
      ..composingBase = 0
      ..composingExtent = testValue.length);
  }

  testWidgets('Editable text has consistent size', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    InputValue inputValue = InputValue.empty;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Input(
            value: inputValue,
            key: inputKey,
            hintText: 'Placeholder',
            onChanged: (InputValue value) { inputValue = value; }
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    RenderBox findInputBox() => tester.renderObject(find.byKey(inputKey));

    RenderBox inputBox = findInputBox();
    Size emptyInputSize = inputBox.size;

    Future<Null> checkText(String testValue) {
      enterText(testValue);

      // Check that the onChanged event handler fired.
      expect(inputValue.text, equals(testValue));

      return tester.pumpWidget(builder());
    }

    await checkText(' ');
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    await checkText('Test');
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));
  });

  testWidgets('Cursor blinks', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Input(
            key: inputKey,
            hintText: 'Placeholder'
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    RawInputLineState editableText = tester.state(find.byType(RawInputLine));

    // Check that the cursor visibility toggles after each blink interval.
    Future<Null> checkCursorToggle() async {
      bool initialShowCursor = editableText.cursorCurrentlyVisible;
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval ~/ 10);
      expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
      await tester.pump(editableText.cursorBlinkInterval);
      expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
    }

    await checkCursorToggle();

    // Try the test again with a nonempty EditableText.
    mockKeyboard.client.updateEditingState(new mojom.EditingState()
      ..text = 'X'
      ..selectionBase = 1
      ..selectionExtent = 1);
    await checkCursorToggle();
  });

  testWidgets('hideText control test', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Input(
            key: inputKey,
            hideText: true,
            hintText: 'Placeholder'
          )
        )
      );
    }

    await tester.pumpWidget(builder());

    const String testValue = 'ABC';
    mockKeyboard.client.updateEditingState(new mojom.EditingState()
      ..text = testValue
      ..selectionBase = testValue.length
      ..selectionExtent = testValue.length);

    await tester.pump();
  });

  // Returns the first RenderEditableLine.
  RenderEditableLine findRenderEditableLine(WidgetTester tester) {
    RenderObject root = tester.renderObject(find.byType(RawInputLine));
    expect(root, isNotNull);

    RenderEditableLine renderLine;
    void recursiveFinder(RenderObject child) {
      if (child is RenderEditableLine) {
        renderLine = child;
        return;
      }
      child.visitChildren(recursiveFinder);
    }
    root.visitChildren(recursiveFinder);
    expect(renderLine, isNotNull);
    return renderLine;
  }

  Point textOffsetToPosition(WidgetTester tester, int offset) {
    RenderEditableLine renderLine = findRenderEditableLine(tester);
    List<TextSelectionPoint> endpoints = renderLine.getEndpointsForSelection(
        new TextSelection.collapsed(offset: offset));
    expect(endpoints.length, 1);
    return endpoints[0].point;
  }

  testWidgets('Can long press to select', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    InputValue inputValue = InputValue.empty;

    Widget builder() {
      return new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) {
              return new Center(
                child: new Material(
                  child: new Input(
                    value: inputValue,
                    key: inputKey,
                    onChanged: (InputValue value) { inputValue = value; }
                  )
                )
              );
            }
          )
        ]
      );
    }

    await tester.pumpWidget(builder());

    String testValue = 'abc def ghi';
    enterText(testValue);
    expect(inputValue.text, testValue);

    await tester.pumpWidget(builder());

    expect(inputValue.selection.isCollapsed, true);

    // Long press the 'e' to select 'def'.
    Point ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    // 'def' is selected.
    expect(inputValue.selection.baseOffset, testValue.indexOf('d'));
    expect(inputValue.selection.extentOffset, testValue.indexOf('f')+1);
  });

  testWidgets('Can drag handles to change selection', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    InputValue inputValue = InputValue.empty;

    Widget builder() {
      return new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) {
              return new Center(
                child: new Material(
                  child: new Input(
                    value: inputValue,
                    key: inputKey,
                    onChanged: (InputValue value) { inputValue = value; }
                  )
                )
              );
            }
          )
        ]
      );
    }

    await tester.pumpWidget(builder());

    String testValue = 'abc def ghi';
    enterText(testValue);

    await tester.pumpWidget(builder());

    // Long press the 'e' to select 'def'.
    Point ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    TextSelection selection = inputValue.selection;

    RenderEditableLine renderLine = findRenderEditableLine(tester);
    List<TextSelectionPoint> endpoints = renderLine.getEndpointsForSelection(
        selection);
    expect(endpoints.length, 2);

    // Drag the right handle 2 letters to the right.
    // Note: use a small offset because the endpoint is on the very corner
    // of the handle.
    Point handlePos = endpoints[1].point + new Offset(1.0, 1.0);
    Point newHandlePos = textOffsetToPosition(tester, selection.extentOffset+2);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(inputValue.selection.baseOffset, selection.baseOffset);
    expect(inputValue.selection.extentOffset, selection.extentOffset+2);

    // Drag the left handle 2 letters to the left.
    handlePos = endpoints[0].point + new Offset(-1.0, 1.0);
    newHandlePos = textOffsetToPosition(tester, selection.baseOffset-2);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(builder());

    expect(inputValue.selection.baseOffset, selection.baseOffset-2);
    expect(inputValue.selection.extentOffset, selection.extentOffset+2);
  });

  testWidgets('Can use selection toolbar', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    InputValue inputValue = InputValue.empty;

    Widget builder() {
      return new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) {
              return new Center(
                child: new Material(
                  child: new Input(
                    value: inputValue,
                    key: inputKey,
                    onChanged: (InputValue value) { inputValue = value; }
                  )
                )
              );
            }
          )
        ]
      );
    }

    await tester.pumpWidget(builder());

    String testValue = 'abc def ghi';
    enterText(testValue);
    await tester.pumpWidget(builder());

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    RenderEditableLine renderLine = findRenderEditableLine(tester);
    List<TextSelectionPoint> endpoints = renderLine.getEndpointsForSelection(
        inputValue.selection);
    await tester.tapAt(endpoints[0].point + new Offset(1.0, 1.0));
    await tester.pumpWidget(builder());

    // SELECT ALL should select all the text.
    await tester.tap(find.text('SELECT ALL'));
    await tester.pumpWidget(builder());
    expect(inputValue.selection.baseOffset, 0);
    expect(inputValue.selection.extentOffset, testValue.length);

    // COPY should reset the selection.
    await tester.tap(find.text('COPY'));
    await tester.pumpWidget(builder());
    expect(inputValue.selection.isCollapsed, true);

    // Tap again to bring back the menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    renderLine = findRenderEditableLine(tester);
    endpoints = renderLine.getEndpointsForSelection(inputValue.selection);
    await tester.tapAt(endpoints[0].point + new Offset(1.0, 1.0));
    await tester.pumpWidget(builder());

    // PASTE right before the 'e'.
    await tester.tap(find.text('PASTE'));
    await tester.pumpWidget(builder());
    expect(inputValue.text, 'abc d${testValue}ef ghi');
  });
}

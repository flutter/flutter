// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sky_services/editing/editing.mojom.dart' as mojom;
import 'package:test/test.dart';

class MockKeyboard implements mojom.Keyboard {
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

void main() {
  MockKeyboard mockKeyboard = new MockKeyboard();
  serviceMocker.registerMockService(mojom.Keyboard.serviceName, mockKeyboard);

  void enterText(String testValue) {
    // Simulate entry of text through the keyboard.
    expect(mockKeyboard.client, isNotNull);
    mockKeyboard.client.updateEditingState(new mojom.EditingState()
      ..text = testValue
      ..composingBase = 0
      ..composingExtent = testValue.length);
  }

  testWidgets('Editable text has consistent size', (WidgetTester tester) {
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

      tester.pumpWidget(builder());

      RenderBox findInputBox() => tester.renderObject(find.byKey(inputKey));

      RenderBox inputBox = findInputBox();
      Size emptyInputSize = inputBox.size;

      void checkText(String testValue) {
        enterText(testValue);

        // Check that the onChanged event handler fired.
        expect(inputValue.text, equals(testValue));

        tester.pumpWidget(builder());
      }

      checkText(' ');
      expect(findInputBox(), equals(inputBox));
      expect(inputBox.size, equals(emptyInputSize));

      checkText('Test');
      expect(findInputBox(), equals(inputBox));
      expect(inputBox.size, equals(emptyInputSize));
  });

  testWidgets('Cursor blinks', (WidgetTester tester) {
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

      tester.pumpWidget(builder());

      RawInputLineState editableText = tester.state(find.byType(RawInputLine));

      // Check that the cursor visibility toggles after each blink interval.
      void checkCursorToggle() {
        bool initialShowCursor = editableText.cursorCurrentlyVisible;
        tester.pump(editableText.cursorBlinkInterval);
        expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
        tester.pump(editableText.cursorBlinkInterval);
        expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
        tester.pump(editableText.cursorBlinkInterval ~/ 10);
        expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
        tester.pump(editableText.cursorBlinkInterval);
        expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
        tester.pump(editableText.cursorBlinkInterval);
        expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
      }

      checkCursorToggle();

      // Try the test again with a nonempty EditableText.
      mockKeyboard.client.updateEditingState(new mojom.EditingState()
        ..text = 'X'
        ..selectionBase = 1
        ..selectionExtent = 1);
      checkCursorToggle();
  });

  testWidgets('hideText control test', (WidgetTester tester) {
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

      tester.pumpWidget(builder());

      const String testValue = 'ABC';
      mockKeyboard.client.updateEditingState(new mojom.EditingState()
        ..text = testValue
        ..selectionBase = testValue.length
        ..selectionExtent = testValue.length);

      tester.pump();
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

  testWidgets('Can long press to select', (WidgetTester tester) {
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

      tester.pumpWidget(builder());

      String testValue = 'abc def ghi';
      enterText(testValue);
      expect(inputValue.text, testValue);

      tester.pumpWidget(builder());

      expect(inputValue.selection.isCollapsed, true);

      // Long press the 'e' to select 'def'.
      Point ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
      TestGesture gesture = tester.startGesture(ePos, pointer: 7);
      tester.pump(const Duration(seconds: 2));
      gesture.up();
      tester.pump();

      // 'def' is selected.
      expect(inputValue.selection.baseOffset, testValue.indexOf('d'));
      expect(inputValue.selection.extentOffset, testValue.indexOf('f')+1);
  });

  testWidgets('Can drag handles to change selection', (WidgetTester tester) {
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

      tester.pumpWidget(builder());

      String testValue = 'abc def ghi';
      enterText(testValue);

      tester.pumpWidget(builder());

      // Long press the 'e' to select 'def'.
      Point ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
      TestGesture gesture = tester.startGesture(ePos, pointer: 7);
      tester.pump(const Duration(seconds: 2));
      gesture.up();
      tester.pump();

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
      gesture = tester.startGesture(handlePos, pointer: 7);
      tester.pump();
      gesture.moveTo(newHandlePos);
      tester.pump();
      gesture.up();
      tester.pump();

      expect(inputValue.selection.baseOffset, selection.baseOffset);
      expect(inputValue.selection.extentOffset, selection.extentOffset+2);

      // Drag the left handle 2 letters to the left.
      handlePos = endpoints[0].point + new Offset(-1.0, 1.0);
      newHandlePos = textOffsetToPosition(tester, selection.baseOffset-2);
      gesture = tester.startGesture(handlePos, pointer: 7);
      tester.pump();
      gesture.moveTo(newHandlePos);
      tester.pump();
      gesture.up();
      tester.pumpWidget(builder());

      expect(inputValue.selection.baseOffset, selection.baseOffset-2);
      expect(inputValue.selection.extentOffset, selection.extentOffset+2);
  });

}

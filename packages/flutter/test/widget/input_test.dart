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
  WidgetFlutterBinding.ensureInitialized(); // for serviceMocker
  MockKeyboard mockKeyboard = new MockKeyboard();
  serviceMocker.registerMockService(mojom.Keyboard.serviceName, mockKeyboard);

  test('Editable text has consistent size', () {
    testWidgets((WidgetTester tester) {
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

      RenderBox findInputBox() => tester.renderObjectOf(find.byKey(inputKey));

      RenderBox inputBox = findInputBox();
      Size emptyInputSize = inputBox.size;

      void enterText(String testValue) {
        // Simulate entry of text through the keyboard.
        expect(mockKeyboard.client, isNotNull);
        mockKeyboard.client.updateEditingState(new mojom.EditingState()
          ..text = testValue
          ..composingBase = 0
          ..composingExtent = testValue.length);

        // Check that the onChanged event handler fired.
        expect(inputValue.text, equals(testValue));

        tester.pumpWidget(builder());
      }

      enterText(' ');
      expect(findInputBox(), equals(inputBox));
      expect(inputBox.size, equals(emptyInputSize));

      enterText('Test');
      expect(findInputBox(), equals(inputBox));
      expect(inputBox.size, equals(emptyInputSize));
    });
  });

  test('Cursor blinks', () {
    testWidgets((WidgetTester tester) {
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

      RawInputLineState editableText = tester.stateOf(find.byType(RawInputLine));

      // Check that the cursor visibility toggles after each blink interval.
      void checkCursorToggle() {
        bool initialShowCursor = editableText.cursorCurrentlyVisible;
        tester.async.elapse(editableText.cursorBlinkInterval);
        expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
        tester.async.elapse(editableText.cursorBlinkInterval);
        expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
        tester.async.elapse(editableText.cursorBlinkInterval ~/ 10);
        expect(editableText.cursorCurrentlyVisible, equals(initialShowCursor));
        tester.async.elapse(editableText.cursorBlinkInterval);
        expect(editableText.cursorCurrentlyVisible, equals(!initialShowCursor));
        tester.async.elapse(editableText.cursorBlinkInterval);
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
  });

  test('hideText control test', () {
    testWidgets((WidgetTester tester) {
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
  });
}

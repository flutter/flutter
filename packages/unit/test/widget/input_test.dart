// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mojo_services/keyboard/keyboard.mojom.dart';
import 'package:test/test.dart';

import '../services/mock_services.dart';

class MockKeyboard implements KeyboardService {
  KeyboardClient client;

  void show(KeyboardClientStub client, KeyboardType type) {
    this.client = client.impl;
  }

  void showByRequest() {}

  void hide() {}

  void setText(String text) {}

  void setSelection(int start, int end) {}
}

void main() {
  MockKeyboard mockKeyboard = new MockKeyboard();
  serviceMocker.registerMockService(KeyboardServiceName, mockKeyboard);

  test('Editable text has consistent width', () {
    testWidgets((WidgetTester tester) {
      GlobalKey inputKey = new GlobalKey();
      String inputValue;

      Widget builder() {
        return new Center(
          child: new Input(
            key: inputKey,
            placeholder: 'Placeholder',
            onChanged: (String value) { inputValue = value; }
          )
        );
      }

      tester.pumpWidget(builder());

      Element input = tester.findElementByKey(inputKey);
      Size emptyInputSize = (input.renderObject as RenderBox).size;

      // Simulate entry of text through the keyboard.
      expect(mockKeyboard.client, isNotNull);
      const String testValue = 'Test';
      mockKeyboard.client.setComposingText(testValue, testValue.length);

      // Check that the onChanged event handler fired.
      expect(inputValue, equals(testValue));

      tester.pumpWidget(builder());

      // Check that the Input with text has the same size as the empty Input.
      expect((input.renderObject as RenderBox).size, equals(emptyInputSize));
    });
  });

  test('Cursor blinks', () {
    testWidgets((WidgetTester tester) {
      GlobalKey inputKey = new GlobalKey();

      Widget builder() {
        return new Center(
          child: new Input(
            key: inputKey,
            placeholder: 'Placeholder'
          )
        );
      }

      tester.pumpWidget(builder());

      EditableTextState editableText = tester.findStateOfType(EditableTextState);

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
      mockKeyboard.client.setComposingText('X', 1);
      checkCursorToggle();
    });
  });

  test('Selection remains valid', () {
    testWidgets((WidgetTester tester) {
      GlobalKey inputKey = new GlobalKey();

      Widget builder() {
        return new Center(
          child: new Input(
            key: inputKey,
            placeholder: 'Placeholder'
          )
        );
      }

      tester.pumpWidget(builder());

      const String testValue = 'ABC';
      mockKeyboard.client.commitText(testValue, testValue.length);
      InputState input = tester.findStateOfType(InputState);

      // Delete characters and verify that the selection follows the length
      // of the text.
      for (int i = 0; i < testValue.length; i++) {
        mockKeyboard.client.deleteSurroundingText(1, 0);
        expect(input.editableValue.selection.start, equals(testValue.length - i - 1));
      }

      // Delete a characters when the text is empty.  The selection should
      // remain at zero.
      mockKeyboard.client.deleteSurroundingText(1, 0);
      expect(input.editableValue.selection.start, equals(0));
    });
  });

  test('hideText control test', () {
    testWidgets((WidgetTester tester) {
      GlobalKey inputKey = new GlobalKey();

      Widget builder() {
        return new Center(
          child: new Input(
            key: inputKey,
            hideText: true,
            placeholder: 'Placeholder'
          )
        );
      }

      tester.pumpWidget(builder());

      const String testValue = 'ABC';
      mockKeyboard.client.commitText(testValue, testValue.length);

      tester.pump();
    });
  });
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_services/editing.dart' as mojom;
import 'package:meta/meta.dart';

class MockKeyboard extends mojom.KeyboardProxy {
  MockKeyboard() : super.unbound();

  mojom.KeyboardClient client;

  @override
  void setClient(@checked mojom.KeyboardClientStub client, mojom.KeyboardConfiguration configuraiton) {
    this.client = client.impl;
  }

  @override
  void show() {}

  @override
  void hide() {}

  @override
  void setEditingState(mojom.EditingState state) {}
}

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null
  };

  Future<dynamic> handleJSONMessage(dynamic json) async {
    final String method = json['method'];
    final List<dynamic> args= json['args'];
    switch (method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = args[0];
        break;
    }
  }
}

void main() {
  MockKeyboard mockKeyboard = new MockKeyboard();
  serviceMocker.registerMockService(mockKeyboard);

  MockClipboard mockClipboard = new MockClipboard();
  PlatformMessages.setMockJSONMessageHandler('flutter/platform', mockClipboard.handleJSONMessage);

  const String kThreeLines =
    'First line of text is here abcdef ghijkl mnopqrst. ' +
    'Second line of text goes until abcdef ghijkl mnopq. ' +
    'Third line of stuff keeps going until abcdef ghijk. ';
  const String kFourLines =
    kThreeLines +
    'Fourth line won\'t display and ends at abcdef ghi. ';

  void enterText(String testValue) {
    // Simulate entry of text through the keyboard.
    expect(mockKeyboard.client, isNotNull);
    mockKeyboard.client.updateEditingState(new mojom.EditingState()
      ..text = testValue
      ..composingBase = 0
      ..composingExtent = testValue.length);
  }

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
    return endpoints[0].point + new Offset(0.0, -2.0);
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

  testWidgets('Selection toolbar fades in', (WidgetTester tester) async {
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

    // Toolbar should fade in. Starting at 0% opacity.
    Element target = tester.element(find.text('SELECT ALL'));
    Opacity opacity = target.ancestorWidgetOfExactType(Opacity);
    expect(opacity, isNotNull);
    expect(opacity.opacity, equals(0.0));

    // Still fading in.
    await tester.pump(const Duration(milliseconds: 50));
    opacity = target.ancestorWidgetOfExactType(Opacity);
    expect(opacity.opacity, greaterThan(0.0));
    expect(opacity.opacity, lessThan(1.0));

    // End the test here to ensure the animation is properly disposed of.
  });

  testWidgets('Multiline text will wrap up to maxLines', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    InputValue inputValue = InputValue.empty;

    Widget builder(int maxLines) {
      return new Center(
        child: new Material(
          child: new Input(
            value: inputValue,
            key: inputKey,
            style: const TextStyle(color: Colors.black, fontSize: 34.0),
            maxLines: maxLines,
            hintText: 'Placeholder',
            onChanged: (InputValue value) { inputValue = value; }
          )
        )
      );
    }

    await tester.pumpWidget(builder(3));

    RenderBox findInputBox() => tester.renderObject(find.byKey(inputKey));

    RenderBox inputBox = findInputBox();
    Size emptyInputSize = inputBox.size;

    enterText('No wrapping here.');
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    enterText(kThreeLines);
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(emptyInputSize));

    Size threeLineInputSize = inputBox.size;

    // An extra line won't increase the size because we max at 3.
    enterText(kFourLines);
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);

    // But now it will.
    enterText(kFourLines);
    await tester.pumpWidget(builder(4));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(threeLineInputSize));
  });

  testWidgets('Can drag handles to change selection in multiline', (WidgetTester tester) async {
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
                    style: const TextStyle(color: Colors.black, fontSize: 34.0),
                    maxLines: 3,
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

    String testValue = kThreeLines;
    String cutValue = 'First line of stuff keeps going until abcdef ghijk. ';
    enterText(testValue);

    await tester.pumpWidget(builder());

    // Check that the text spans multiple lines.
    Point firstPos = textOffsetToPosition(tester, testValue.indexOf('First'));
    Point secondPos = textOffsetToPosition(tester, testValue.indexOf('Second'));
    Point thirdPos = textOffsetToPosition(tester, testValue.indexOf('Third'));
    expect(firstPos.x, secondPos.x);
    expect(firstPos.x, thirdPos.x);
    expect(firstPos.y, lessThan(secondPos.y));
    expect(secondPos.y, lessThan(thirdPos.y));

    // Long press the 'n' in 'until' to select the word.
    Point untilPos = textOffsetToPosition(tester, testValue.indexOf('until')+1);
    TestGesture gesture = await tester.startGesture(untilPos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    expect(inputValue.selection.baseOffset, 76);
    expect(inputValue.selection.extentOffset, 81);

    RenderEditableLine renderLine = findRenderEditableLine(tester);
    List<TextSelectionPoint> endpoints = renderLine.getEndpointsForSelection(
        inputValue.selection);
    expect(endpoints.length, 2);

    // Drag the right handle to the third line, just after 'Third'.
    Point handlePos = endpoints[1].point + new Offset(1.0, 1.0);
    Point newHandlePos = textOffsetToPosition(tester, testValue.indexOf('Third') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(inputValue.selection.baseOffset, 76);
    expect(inputValue.selection.extentOffset, 108);

    // Drag the left handle to the first line, just after 'First'.
    handlePos = endpoints[0].point + new Offset(-1.0, 1.0);
    newHandlePos = textOffsetToPosition(tester, testValue.indexOf('First') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(builder());

    expect(inputValue.selection.baseOffset, 5);
    expect(inputValue.selection.extentOffset, 108);

    await tester.tap(find.text('CUT'));
    await tester.pumpWidget(builder());
    expect(inputValue.selection.isCollapsed, true);
    expect(inputValue.text, cutValue);
  });

  testWidgets('Can scroll multiline input', (WidgetTester tester) async {
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
                    style: const TextStyle(color: Colors.black, fontSize: 34.0),
                    maxLines: 2,
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

    enterText(kFourLines);

    await tester.pumpWidget(builder());

    RenderBox findInputBox() => tester.renderObject(find.byKey(inputKey));
    RenderBox inputBox = findInputBox();

    // Check that the last line of text is not displayed.
    Point firstPos = textOffsetToPosition(tester, kFourLines.indexOf('First'));
    Point fourthPos = textOffsetToPosition(tester, kFourLines.indexOf('Fourth'));
    expect(firstPos.x, fourthPos.x);
    expect(firstPos.y, lessThan(fourthPos.y));
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(firstPos)), isTrue);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(fourthPos)), isFalse);

    TestGesture gesture = await tester.startGesture(firstPos, pointer: 7);
    await tester.pump();
    await gesture.moveBy(new Offset(0.0, -1000.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // Now the first line is scrolled up, and the fourth line is visible.
    Point newFirstPos = textOffsetToPosition(tester, kFourLines.indexOf('First'));
    Point newFourthPos = textOffsetToPosition(tester, kFourLines.indexOf('Fourth'));
    expect(newFirstPos.y, lessThan(firstPos.y));
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isFalse);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isTrue);

    // Now try scrolling by dragging the selection handle.

    // Long press the 'i' in 'Fourth line' to select the word.
    await tester.pump(const Duration(seconds: 2));
    Point untilPos = textOffsetToPosition(tester, kFourLines.indexOf('Fourth line')+8);
    gesture = await tester.startGesture(untilPos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    RenderEditableLine renderLine = findRenderEditableLine(tester);
    List<TextSelectionPoint> endpoints = renderLine.getEndpointsForSelection(
        inputValue.selection);
    expect(endpoints.length, 2);

    // Drag the left handle to the first line, just after 'First'.
    Point handlePos = endpoints[0].point + new Offset(-1.0, 1.0);
    Point newHandlePos = textOffsetToPosition(tester, kFourLines.indexOf('First') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos + new Offset(0.0, -10.0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // The text should have scrolled up with the handle to keep the active
    // cursor visible, back to its original position.
    newFirstPos = textOffsetToPosition(tester, kFourLines.indexOf('First'));
    newFourthPos = textOffsetToPosition(tester, kFourLines.indexOf('Fourth'));
    expect(newFirstPos.y, firstPos.y);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isTrue);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isFalse);
  });

}

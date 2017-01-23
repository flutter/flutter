// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'mock_text_input.dart';

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null
  };

  Future<dynamic> handleJSONMessage(dynamic message) async {
    final String method = message['method'];
    final List<dynamic> args= message['args'];
    switch (method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = args[0];
        break;
    }
  }
}

Widget overlay(Widget child) {
  return new Overlay(
    initialEntries: <OverlayEntry>[
      new OverlayEntry(
        builder: (BuildContext context) => child
      )
    ]
  );
}

void main() {
  MockTextInput mockTextInput = new MockTextInput()..register();
  MockClipboard mockClipboard = new MockClipboard();
  PlatformMessages.setMockJSONMessageHandler('flutter/platform', mockClipboard.handleJSONMessage);

  const String kThreeLines =
    'First line of text is here abcdef ghijkl mnopqrst. ' +
    'Second line of text goes until abcdef ghijkl mnopq. ' +
    'Third line of stuff keeps going until abcdef ghijk. ';
  const String kFourLines =
    kThreeLines +
    'Fourth line won\'t display and ends at abcdef ghi. ';

  void updateEditingState(TextEditingState state) {
    mockTextInput.updateEditingState(state);
  }

  void enterText(String text) {
    mockTextInput.enterText(text);
  }

  Future<Null> showKeyboard(WidgetTester tester) async {
    EditableTextState editable = tester.state(find.byType(EditableText).first);
    editable.requestKeyboard();
    await tester.pump();
  }

  // Returns the first RenderEditable.
  RenderEditable findRenderEditable(WidgetTester tester) {
    RenderObject root = tester.renderObject(find.byType(EditableText));
    expect(root, isNotNull);

    RenderEditable renderEditable;
    void recursiveFinder(RenderObject child) {
      if (child is RenderEditable) {
        renderEditable = child;
        return;
      }
      child.visitChildren(recursiveFinder);
    }
    root.visitChildren(recursiveFinder);
    expect(renderEditable, isNotNull);
    return renderEditable;
  }

  Point textOffsetToPosition(WidgetTester tester, int offset) {
    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        new TextSelection.collapsed(offset: offset));
    expect(endpoints.length, 1);
    return endpoints[0].point + const Offset(0.0, -2.0);
  }

  testWidgets('Editable text has consistent size', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    InputValue inputValue = InputValue.empty;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Input(
            autofocus: true,
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

    Future<Null> checkText(String testValue) async {
      enterText(testValue);
      await tester.idle();

      // Check that the onChanged event handler fired.
      expect(inputValue.text, equals(testValue));

      return await tester.pumpWidget(builder());
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
    await showKeyboard(tester);

    EditableTextState editableText = tester.state(find.byType(EditableText));

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
    updateEditingState(const TextEditingState(
      text: 'X',
      selectionBase: 1,
      selectionExtent: 1,
    ));
    await checkCursorToggle();
  });

  testWidgets('obscureText control test', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();

    Widget builder() {
      return new Center(
        child: new Material(
          child: new Input(
            key: inputKey,
            obscureText: true,
            hintText: 'Placeholder'
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    await showKeyboard(tester);

    const String testValue = 'ABC';
    updateEditingState(const TextEditingState(
      text: testValue,
      selectionBase: testValue.length,
      selectionExtent: testValue.length,
    ));

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
    await showKeyboard(tester);

    String testValue = 'abc def ghi';
    enterText(testValue);
    await tester.idle();
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
    await showKeyboard(tester);

    String testValue = 'abc def ghi';
    enterText(testValue);
    await tester.idle();

    await tester.pumpWidget(builder());

    // Long press the 'e' to select 'def'.
    Point ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    TextSelection selection = inputValue.selection;

    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        selection);
    expect(endpoints.length, 2);

    // Drag the right handle 2 letters to the right.
    // Note: use a small offset because the endpoint is on the very corner
    // of the handle.
    Point handlePos = endpoints[1].point + const Offset(1.0, 1.0);
    Point newHandlePos = textOffsetToPosition(tester, selection.extentOffset+2);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(builder());

    expect(inputValue.selection.baseOffset, selection.baseOffset);
    expect(inputValue.selection.extentOffset, selection.extentOffset+2);

    // Drag the left handle 2 letters to the left.
    handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
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
    await showKeyboard(tester);

    String testValue = 'abc def ghi';
    enterText(testValue);
    await tester.idle();
    await tester.pumpWidget(builder());

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        inputValue.selection);
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
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
    renderEditable = findRenderEditable(tester);
    endpoints = renderEditable.getEndpointsForSelection(inputValue.selection);
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
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
    await showKeyboard(tester);

    String testValue = 'abc def ghi';
    enterText(testValue);
    await tester.idle();
    await tester.pumpWidget(builder());

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        inputValue.selection);
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
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
    await showKeyboard(tester);

    RenderBox findInputBox() => tester.renderObject(find.byKey(inputKey));

    RenderBox inputBox = findInputBox();
    Size emptyInputSize = inputBox.size;

    enterText('No wrapping here.');
    await tester.idle();
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    enterText(kThreeLines);
    await tester.idle();
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(emptyInputSize));

    Size threeLineInputSize = inputBox.size;

    // An extra line won't increase the size because we max at 3.
    enterText(kFourLines);
    await tester.idle();
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);

    // But now it will.
    enterText(kFourLines);
    await tester.idle();
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
    await showKeyboard(tester);

    String testValue = kThreeLines;
    String cutValue = 'First line of stuff keeps going until abcdef ghijk. ';
    enterText(testValue);
    await tester.idle();

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

    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        inputValue.selection);
    expect(endpoints.length, 2);

    // Drag the right handle to the third line, just after 'Third'.
    Point handlePos = endpoints[1].point + const Offset(1.0, 1.0);
    Point newHandlePos = textOffsetToPosition(tester, testValue.indexOf('Third') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(builder());

    expect(inputValue.selection.baseOffset, 76);
    expect(inputValue.selection.extentOffset, 108);

    // Drag the left handle to the first line, just after 'First'.
    handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
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
  }, skip: Platform.isMacOS); // Skip due to https://github.com/flutter/flutter/issues/6961


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
    await showKeyboard(tester);

    enterText(kFourLines);
    await tester.idle();

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
    await gesture.moveBy(const Offset(0.0, -1000.0));
    await tester.pump(const Duration(seconds: 2));
    // Wait and drag again to trigger https://github.com/flutter/flutter/issues/6329
    // (No idea why this is necessary, but the bug wouldn't repro without it.)
    await gesture.moveBy(const Offset(0.0, -1000.0));
    await tester.pump(const Duration(seconds: 2));
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

    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        inputValue.selection);
    expect(endpoints.length, 2);

    // Drag the left handle to the first line, just after 'First'.
    Point handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
    Point newHandlePos = textOffsetToPosition(tester, kFourLines.indexOf('First') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos + const Offset(0.0, -10.0));
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
  }, skip: Platform.isMacOS); // Skip due to https://github.com/flutter/flutter/issues/6961

  testWidgets('InputField smoke test', (WidgetTester tester) async {
    InputValue inputValue = InputValue.empty;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new InputField(
            value: inputValue,
            hintText: 'Placeholder',
            onChanged: (InputValue value) { inputValue = value; }
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    await showKeyboard(tester);

    Future<Null> checkText(String testValue) async {
      enterText(testValue);
      await tester.idle();

      // Check that the onChanged event handler fired.
      expect(inputValue.text, equals(testValue));

      return await tester.pumpWidget(builder());
    }

    checkText('Hello World');
  });

  testWidgets('InputField with global key', (WidgetTester tester) async {
    GlobalKey inputFieldKey = new GlobalKey(debugLabel: 'inputFieldKey');
    InputValue inputValue = InputValue.empty;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new InputField(
            key: inputFieldKey,
            value: inputValue,
            hintText: 'Placeholder',
            onChanged: (InputValue value) { inputValue = value; }
          )
        )
      );
    }

    await tester.pumpWidget(builder());
    await showKeyboard(tester);

    Future<Null> checkText(String testValue) async {
      enterText(testValue);
      await tester.idle();

      // Check that the onChanged event handler fired.
      expect(inputValue.text, equals(testValue));

      return await tester.pumpWidget(builder());
    }

    checkText('Hello World');
  });

  testWidgets('Input label text animates', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    GlobalKey focusKey = new GlobalKey();

    Widget innerBuilder() {
      return new Center(
        child: new Material(
          child: new Focus(
            key: focusKey,
            child: new Column(
              children: <Widget>[
                new Input(
                  labelText: 'First'
                ),
                new Input(
                  key: inputKey,
                  labelText: 'Second'
                ),
              ]
            )
          )
        )
      );
    }
    Widget builder() => overlay(innerBuilder());

    await tester.pumpWidget(builder());

    Point pos = tester.getTopLeft(find.text('Second'));

    // Focus the Input. The label should start animating upwards.
    await tester.tap(find.byKey(inputKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    Point newPos = tester.getTopLeft(find.text('Second'));
    expect(newPos.y, lessThan(pos.y));

    // Label should still be sliding upward.
    await tester.pump(const Duration(milliseconds: 50));
    pos = newPos;
    newPos = tester.getTopLeft(find.text('Second'));
    expect(newPos.y, lessThan(pos.y));
  });

  testWidgets('No space between Input icon and text', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new Material(
          child: new Input(
            icon: new Icon(Icons.phone),
            labelText: 'label',
            value: InputValue.empty,
          ),
        ),
      ),
    );

    final double iconRight = tester.getTopRight(find.byType(Icon)).x;
    expect(iconRight, equals(tester.getTopLeft(find.text('label')).x));
    expect(iconRight, equals(tester.getTopLeft(find.byType(InputField)).x));
  });

}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments;
        break;
    }
  }
}

Widget overlay(Widget child) {
  return new Overlay(
    initialEntries: <OverlayEntry>[
      new OverlayEntry(
        builder: (BuildContext context) => child,
      ),
    ],
  );
}

void main() {
  final MockClipboard mockClipboard = new MockClipboard();
  SystemChannels.platform.setMockMethodCallHandler(mockClipboard.handleMethodCall);

  const String kThreeLines =
    'First line of text is here abcdef ghijkl mnopqrst. ' +
    'Second line of text goes until abcdef ghijkl mnopq. ' +
    'Third line of stuff keeps going until abcdef ghijk. ';
  const String kFourLines =
    kThreeLines +
    'Fourth line won\'t display and ends at abcdef ghi. ';

  // Returns the first RenderEditable.
  RenderEditable findRenderEditable(WidgetTester tester) {
    final RenderObject root = tester.renderObject(find.byType(EditableText));
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
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        new TextSelection.collapsed(offset: offset));
    expect(endpoints.length, 1);
    return endpoints[0].point + const Offset(0.0, -2.0);
  }

  testWidgets('TextField has consistent size', (WidgetTester tester) async {
    final Key textFieldKey = new UniqueKey();
    String textFieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            key: textFieldKey,
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
            onChanged: (String value) {
              textFieldValue = value;
            }
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    RenderBox findTextFieldBox() => tester.renderObject(find.byKey(textFieldKey));

    final RenderBox inputBox = findTextFieldBox();
    final Size emptyInputSize = inputBox.size;

    Future<Null> checkText(String testValue) async {
      await tester.enterText(find.byType(EditableText), testValue);

      // Check that the onChanged event handler fired.
      expect(textFieldValue, equals(testValue));

      return await tester.pumpWidget(builder());
    }

    await checkText(' ');
    expect(findTextFieldBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    await checkText('Test');
    expect(findTextFieldBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));
  });

  testWidgets('Cursor blinks', (WidgetTester tester) async {

    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(EditableText));

    final EditableTextState editableText = tester.state(find.byType(EditableText));

    // Check that the cursor visibility toggles after each blink interval.
    Future<Null> checkCursorToggle() async {
      final bool initialShowCursor = editableText.cursorCurrentlyVisible;
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
    await tester.showKeyboard(find.byType(EditableText));

    // Try the test again with a nonempty EditableText.
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'X',
      selection: const TextSelection.collapsed(offset: 1),
    ));
    await checkCursorToggle();
  });

  testWidgets('obscureText control test', (WidgetTester tester) async {
    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(EditableText));

    const String testValue = 'ABC';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue,
      selection: const TextSelection.collapsed(offset: testValue.length),
    ));

    await tester.pump();
  });

  testWidgets('Caret position is updated on tap', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return overlay(new Center(
        child: new Material(
          child: new TextField(
            controller: controller,
          ),
        ),
      ));
    }

    await tester.pumpWidget(builder());
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);

    final String testValue = 'abc def ghi';
    await tester.enterText(find.byType(EditableText), testValue);

    await tester.pumpWidget(builder());

    // Tap to reposition the caret.
    final int tapIndex = testValue.indexOf('e');
    final Point ePos = textOffsetToPosition(tester, tapIndex);
    await tester.tapAt(ePos);
    await tester.pump();

    expect(controller.selection.baseOffset, tapIndex);
    expect(controller.selection.extentOffset, tapIndex);
  });

  testWidgets('Can long press to select', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) {
              return new Center(
                child: new Material(
                  child: new TextField(
                    controller: controller,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    await tester.pumpWidget(builder());

    final String testValue = 'abc def ghi';
    await tester.enterText(find.byType(EditableText), testValue);
    expect(controller.value.text, testValue);

    await tester.pumpWidget(builder());

    expect(controller.selection.isCollapsed, true);

    // Long press the 'e' to select 'def'.
    final Point ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    final TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    // 'def' is selected.
    expect(controller.selection.baseOffset, testValue.indexOf('d'));
    expect(controller.selection.extentOffset, testValue.indexOf('f')+1);
  });

  testWidgets('Can drag handles to change selection', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return overlay(new Center(
        child: new Material(
          child: new TextField(
            controller: controller,
          ),
        ),
      ));
    }

    await tester.pumpWidget(builder());

    final String testValue = 'abc def ghi';
    await tester.enterText(find.byType(EditableText), testValue);

    await tester.pumpWidget(builder());

    // Long press the 'e' to select 'def'.
    final Point ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    final TextSelection selection = controller.selection;

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
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

    expect(controller.selection.baseOffset, selection.baseOffset);
    expect(controller.selection.extentOffset, selection.extentOffset+2);

    // Drag the left handle 2 letters to the left.
    handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
    newHandlePos = textOffsetToPosition(tester, selection.baseOffset-2);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(builder());

    expect(controller.selection.baseOffset, selection.baseOffset-2);
    expect(controller.selection.extentOffset, selection.extentOffset+2);
  });

  testWidgets('Can use selection toolbar', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return overlay(new Center(
        child: new Material(
          child: new TextField(
            controller: controller,
          ),
        ),
      ));
    }

    await tester.pumpWidget(builder());

    final String testValue = 'abc def ghi';
    await tester.enterText(find.byType(EditableText), testValue);
    await tester.pumpWidget(builder());

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        controller.selection);
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pumpWidget(builder());

    // SELECT ALL should select all the text.
    await tester.tap(find.text('SELECT ALL'));
    await tester.pumpWidget(builder());
    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, testValue.length);

    // COPY should reset the selection.
    await tester.tap(find.text('COPY'));
    await tester.pumpWidget(builder());
    expect(controller.selection.isCollapsed, true);

    // Tap again to bring back the menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    renderEditable = findRenderEditable(tester);
    endpoints = renderEditable.getEndpointsForSelection(controller.selection);
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pumpWidget(builder());

    // PASTE right before the 'e'.
    await tester.tap(find.text('PASTE'));
    await tester.pumpWidget(builder());
    expect(controller.text, 'abc d${testValue}ef ghi');
  });

  testWidgets('Selection toolbar fades in', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return overlay(new Center(
        child: new Material(
          child: new TextField(
            controller: controller,
          ),
        ),
      ));
    }

    await tester.pumpWidget(builder());

    final String testValue = 'abc def ghi';
    await tester.enterText(find.byType(EditableText), testValue);
    await tester.pumpWidget(builder());

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        controller.selection);
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pumpWidget(builder());

    // Toolbar should fade in. Starting at 0% opacity.
    final Element target = tester.element(find.text('SELECT ALL'));
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
    final Key textFieldKey = new UniqueKey();

    Widget builder(int maxLines) {
      return new Center(
        child: new Material(
          child: new TextField(
            key: textFieldKey,
            style: const TextStyle(color: Colors.black, fontSize: 34.0),
            maxLines: maxLines,
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder(3));

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

    final RenderBox inputBox = findInputBox();
    final Size emptyInputSize = inputBox.size;

    await tester.enterText(find.byType(EditableText), 'No wrapping here.');
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    await tester.enterText(find.byType(EditableText), kThreeLines);
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(emptyInputSize));

    final Size threeLineInputSize = inputBox.size;

    // An extra line won't increase the size because we max at 3.
    await tester.enterText(find.byType(EditableText), kFourLines);
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);

    // But now it will.
    await tester.enterText(find.byType(EditableText), kFourLines);
    await tester.pumpWidget(builder(4));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(threeLineInputSize));
  });

  testWidgets('Can drag handles to change selection in multiline', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return overlay(new Center(
        child: new Material(
          child: new TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black, fontSize: 34.0),
            maxLines: 3,
          ),
        ),
      ));
    }

    await tester.pumpWidget(builder());

    final String testValue = kThreeLines;
    final String cutValue = 'First line of stuff keeps going until abcdef ghijk. ';
    await tester.enterText(find.byType(EditableText), testValue);

    await tester.pumpWidget(builder());

    // Check that the text spans multiple lines.
    final Point firstPos = textOffsetToPosition(tester, testValue.indexOf('First'));
    final Point secondPos = textOffsetToPosition(tester, testValue.indexOf('Second'));
    final Point thirdPos = textOffsetToPosition(tester, testValue.indexOf('Third'));
    expect(firstPos.x, secondPos.x);
    expect(firstPos.x, thirdPos.x);
    expect(firstPos.y, lessThan(secondPos.y));
    expect(secondPos.y, lessThan(thirdPos.y));

    // Long press the 'n' in 'until' to select the word.
    final Point untilPos = textOffsetToPosition(tester, testValue.indexOf('until')+1);
    TestGesture gesture = await tester.startGesture(untilPos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    expect(controller.selection.baseOffset, 76);
    expect(controller.selection.extentOffset, 81);

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        controller.selection);
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

    expect(controller.selection.baseOffset, 76);
    expect(controller.selection.extentOffset, 108);

    // Drag the left handle to the first line, just after 'First'.
    handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
    newHandlePos = textOffsetToPosition(tester, testValue.indexOf('First') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(builder());

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 108);

    await tester.tap(find.text('CUT'));
    await tester.pumpWidget(builder());
    expect(controller.selection.isCollapsed, true);
    expect(controller.text, cutValue);
  }, skip: Platform.isMacOS); // Skip due to https://github.com/flutter/flutter/issues/6961

  testWidgets('Can scroll multiline input', (WidgetTester tester) async {
    final Key textFieldKey = new UniqueKey();
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return overlay(new Center(
        child: new Material(
          child: new TextField(
            key: textFieldKey,
            controller: controller,
            style: const TextStyle(color: Colors.black, fontSize: 34.0),
            maxLines: 2,
          ),
        ),
      ));
    }

    await tester.pumpWidget(builder());

    await tester.enterText(find.byType(EditableText), kFourLines);

    await tester.pumpWidget(builder());

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));
    final RenderBox inputBox = findInputBox();

    // Check that the last line of text is not displayed.
    final Point firstPos = textOffsetToPosition(tester, kFourLines.indexOf('First'));
    final Point fourthPos = textOffsetToPosition(tester, kFourLines.indexOf('Fourth'));
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
    final Point untilPos = textOffsetToPosition(tester, kFourLines.indexOf('Fourth line')+8);
    gesture = await tester.startGesture(untilPos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
        controller.selection);
    expect(endpoints.length, 2);

    // Drag the left handle to the first line, just after 'First'.
    final Point handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
    final Point newHandlePos = textOffsetToPosition(tester, kFourLines.indexOf('First') + 5);
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
    String textFieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            decoration: null,
            onChanged: (String value) {
              textFieldValue = value;
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    Future<Null> checkText(String testValue) async {
      await tester.enterText(find.byType(EditableText), testValue);

      // Check that the onChanged event handler fired.
      expect(textFieldValue, equals(testValue));

      return await tester.pumpWidget(builder());
    }

    checkText('Hello World');
  });

  testWidgets('InputField with global key', (WidgetTester tester) async {
    final GlobalKey textFieldKey = new GlobalKey(debugLabel: 'textFieldKey');
    String textFieldValue;

    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            key: textFieldKey,
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
            onChanged: (String value) { textFieldValue = value; },
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    Future<Null> checkText(String testValue) async {
      await tester.enterText(find.byType(EditableText), testValue);

      // Check that the onChanged event handler fired.
      expect(textFieldValue, equals(testValue));

      return await tester.pumpWidget(builder());
    }

    checkText('Hello World');
  });

  testWidgets('TextField with default hintStyle', (WidgetTester tester) async {
    final TextStyle style = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final ThemeData themeData = new ThemeData(
      hintColor: Colors.blue[500],
    );

    Widget builder() {
      return new Center(
        child: new Theme(
          data: themeData,
          child: new Material(
            child: new TextField(
              decoration: const InputDecoration(
                hintText: 'Placeholder',
              ),
              style: style,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    final Text hintText = tester.widget(find.text('Placeholder'));
    expect(hintText.style.color, themeData.hintColor);
    expect(hintText.style.fontSize, style.fontSize);
  });

  testWidgets('TextField with specified hintStyle', (WidgetTester tester) async {
    final TextStyle hintStyle = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            decoration: new InputDecoration(
              hintText: 'Placeholder',
              hintStyle: hintStyle,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    final Text hintText = tester.widget(find.text('Placeholder'));
    expect(hintText.style, hintStyle);
  });

  testWidgets('TextField label text animates', (WidgetTester tester) async {
    final Key secondKey = new UniqueKey();

    Widget innerBuilder() {
      return new Center(
        child: new Material(
          child: new Column(
            children: <Widget>[
              new TextField(
                decoration: const InputDecoration(
                  labelText: 'First',
                ),
              ),
              new TextField(
                key: secondKey,
                decoration: const InputDecoration(
                  labelText: 'Second',
                ),
              ),
            ],
          ),
        ),
      );
    }
    Widget builder() => overlay(innerBuilder());

    await tester.pumpWidget(builder());

    Point pos = tester.getTopLeft(find.text('Second'));

    // Focus the Input. The label should start animating upwards.
    await tester.tap(find.byKey(secondKey));
    await tester.idle();
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
          child: new TextField(
            decoration: const InputDecoration(
              icon: const Icon(Icons.phone),
              labelText: 'label',
            ),
          ),
        ),
      ),
    );

    final double iconRight = tester.getTopRight(find.byType(Icon)).x;
    expect(iconRight, equals(tester.getTopLeft(find.text('label')).x));
    expect(iconRight, equals(tester.getTopLeft(find.byType(EditableText)).x));
  });

  testWidgets('Collapsed hint text placement', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(new Center(
        child: new Material(
          child: new TextField(
            decoration: const InputDecoration.collapsed(
              hintText: 'hint',
            ),
          ),
        ),
      )),
    );

    expect(tester.getTopLeft(find.text('hint')), equals(tester.getTopLeft(find.byType(TextField))));
  });

  testWidgets('Can align to center', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(new Center(
        child: new Material(
          child: new Container(
            width: 300.0,
            child: new TextField(
              textAlign: TextAlign.center,
              decoration: null,
            ),
          ),
        ),
      )),
    );

    final RenderEditable editable = findRenderEditable(tester);
    Point topLeft = editable.localToGlobal(
        editable.getLocalRectForCaret(const TextPosition(offset: 0)).topLeft
    );

    expect(topLeft.x, equals(399.0));

    await tester.enterText(find.byType(EditableText), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
        editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft
    );

    expect(topLeft.x, equals(399.0));
  });

  testWidgets('Can align to center within center', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(new Center(
        child: new Material(
          child: new Container(
            width: 300.0,
            child: new Center(
              child: new TextField(
                textAlign: TextAlign.center,
                decoration: null,
              ),
            ),
          ),
        ),
      )),
    );

    final RenderEditable editable = findRenderEditable(tester);
    Point topLeft = editable.localToGlobal(
        editable.getLocalRectForCaret(const TextPosition(offset: 0)).topLeft
    );

    expect(topLeft.x, equals(399.0));

    await tester.enterText(find.byType(EditableText), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
        editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft
    );

    expect(topLeft.x, equals(399.0));
  });

  testWidgets('Controller can update server', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController(
      text: 'Initial Text',
    );
    final TextEditingController controller2 = new TextEditingController(
      text: 'More Text',
    );

    TextEditingController currentController = controller;
    StateSetter setState;

    await tester.pumpWidget(
      overlay(new Center(
        child: new Material(
          child: new StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              return new TextField(controller: currentController);
            }
          ),
        ),
      ),
    ));

    expect(tester.testTextInput.editingState['text'], isEmpty);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(tester.testTextInput.editingState['text'], equals('Initial Text'));

    controller.text = 'Updated Text';
    await tester.idle();

    expect(tester.testTextInput.editingState['text'], equals('Updated Text'));

    setState(() {
      currentController = controller2;
    });

    await tester.pump();

    expect(tester.testTextInput.editingState['text'], equals('More Text'));

    controller.text = 'Ignored Text';
    await tester.idle();

    expect(tester.testTextInput.editingState['text'], equals('More Text'));

    controller2.text = 'Final Text';
    await tester.idle();

    expect(tester.testTextInput.editingState['text'], equals('Final Text'));
  });
}

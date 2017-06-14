// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  return new MediaQuery(
    data: const MediaQueryData(),
    child: new Overlay(
      initialEntries: <OverlayEntry>[
        new OverlayEntry(
          builder: (BuildContext context) => child,
        ),
      ],
    ),
  );
}

void main() {
  final MockClipboard mockClipboard = new MockClipboard();
  SystemChannels.platform.setMockMethodCallHandler(mockClipboard.handleMethodCall);

  const String kThreeLines =
    'First line of text is '
    'Second line goes until '
    'Third line of stuff ';
  const String kMoreThanFourLines =
    kThreeLines +
    'Fourth line won\'t display and ends at';

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

  Offset textOffsetToPosition(WidgetTester tester, int offset) {
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
      new TextSelection.collapsed(offset: offset),
    );
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
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(TextField), testValue);

        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));

        await tester.pumpWidget(builder());
        // skip past scrolling animation
        await tester.pump(const Duration(milliseconds: 200));
      });
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
      return const Center(
        child: const Material(
          child: const TextField(
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextField));

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
    await tester.showKeyboard(find.byType(TextField));

    // Try the test again with a nonempty EditableText.
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'X',
      selection: const TextSelection.collapsed(offset: 1),
    ));
    await checkCursorToggle();
  });

  testWidgets('obscureText control test', (WidgetTester tester) async {
    Widget builder() {
      return const Center(
        child: const Material(
          child: const TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(TextField));

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
    await tester.enterText(find.byType(TextField), testValue);

    await tester.pumpWidget(builder());
    // skip past scrolling animation
    await tester.pump(const Duration(milliseconds: 200));

    // Tap to reposition the caret.
    final int tapIndex = testValue.indexOf('e');
    final Offset ePos = textOffsetToPosition(tester, tapIndex);
    await tester.tapAt(ePos);
    await tester.pump();

    expect(controller.selection.baseOffset, tapIndex);
    expect(controller.selection.extentOffset, tapIndex);
  });

  testWidgets('Can long press to select', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    Widget builder() {
      return new MediaQuery(
        data: const MediaQueryData(),
        child: new Overlay(
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
        ),
      );
    }

    await tester.pumpWidget(builder());

    final String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    expect(controller.value.text, testValue);

    await tester.pumpWidget(builder());
    // skip past scrolling animation
    await tester.pump(const Duration(milliseconds: 200));

    expect(controller.selection.isCollapsed, true);

    // Long press the 'e' to select 'def'.
    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
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
    await tester.enterText(find.byType(TextField), testValue);

    await tester.pumpWidget(builder());
    // skip past scrolling animation
    await tester.pump(const Duration(milliseconds: 200));

    // Long press the 'e' to select 'def'.
    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    final TextSelection selection = controller.selection;

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(selection);
    expect(endpoints.length, 2);

    // Drag the right handle 2 letters to the right.
    // Note: use a small offset because the endpoint is on the very corner
    // of the handle.
    Offset handlePos = endpoints[1].point + const Offset(1.0, 1.0);
    Offset newHandlePos = textOffsetToPosition(tester, selection.extentOffset+2);
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
    await tester.enterText(find.byType(TextField), testValue);
    await tester.pumpWidget(builder());
    // skip past scrolling animation
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(controller.selection);
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
    // skip past scrolling animation
    await tester.pump(const Duration(milliseconds: 200));
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
    await tester.enterText(find.byType(TextField), testValue);
    await tester.pumpWidget(builder());
    // skip past scrolling animation
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pumpWidget(builder());
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(controller.selection);
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

    await tester.pumpWidget(builder(null));

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

    final RenderBox inputBox = findInputBox();
    final Size emptyInputSize = inputBox.size;

    await tester.enterText(find.byType(TextField), 'No wrapping here.');
    await tester.pumpWidget(builder(null));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(emptyInputSize));

    final Size threeLineInputSize = inputBox.size;

    await tester.enterText(find.byType(TextField), kThreeLines);
    await tester.pumpWidget(builder(null));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(emptyInputSize));

    await tester.enterText(find.byType(TextField), kThreeLines);
    await tester.pumpWidget(builder(null));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);

    // An extra line won't increase the size because we max at 3.
    await tester.enterText(find.byType(TextField), kMoreThanFourLines);
    await tester.pumpWidget(builder(3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);

    // But now it will... but it will max at four
    await tester.enterText(find.byType(TextField), kMoreThanFourLines);
    await tester.pumpWidget(builder(4));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(threeLineInputSize));

    final Size fourLineInputSize = inputBox.size;

    // Now it won't max out until the end
    await tester.pumpWidget(builder(null));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, greaterThan(fourLineInputSize));
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
    final String cutValue = 'First line of stuff ';
    await tester.enterText(find.byType(TextField), testValue);

    await tester.pumpWidget(builder());
    // skip past scrolling animation
    await tester.pump(const Duration(milliseconds: 200));

    // Check that the text spans multiple lines.
    final Offset firstPos = textOffsetToPosition(tester, testValue.indexOf('First'));
    final Offset secondPos = textOffsetToPosition(tester, testValue.indexOf('Second'));
    final Offset thirdPos = textOffsetToPosition(tester, testValue.indexOf('Third'));
    expect(firstPos.dx, secondPos.dx);
    expect(firstPos.dx, thirdPos.dx);
    expect(firstPos.dy, lessThan(secondPos.dy));
    expect(secondPos.dy, lessThan(thirdPos.dy));

    // Long press the 'n' in 'until' to select the word.
    final Offset untilPos = textOffsetToPosition(tester, testValue.indexOf('until')+1);
    TestGesture gesture = await tester.startGesture(untilPos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    expect(controller.selection.baseOffset, 39);
    expect(controller.selection.extentOffset, 44);

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(controller.selection);
    expect(endpoints.length, 2);

    // Drag the right handle to the third line, just after 'Third'.
    Offset handlePos = endpoints[1].point + const Offset(1.0, 1.0);
    Offset newHandlePos = textOffsetToPosition(tester, testValue.indexOf('Third') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpWidget(builder());

    expect(controller.selection.baseOffset, 39);
    expect(controller.selection.extentOffset, 50);

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
    expect(controller.selection.extentOffset, 50);

    await tester.tap(find.text('CUT'));
    await tester.pumpWidget(builder());
    expect(controller.selection.isCollapsed, true);
    expect(controller.text, cutValue);
  });

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
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), kMoreThanFourLines);

    await tester.pumpWidget(builder());
    await tester.pump(const Duration(seconds: 1));

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));
    final RenderBox inputBox = findInputBox();

    // Check that the last line of text is not displayed.
    final Offset firstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
    final Offset fourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));
    expect(firstPos.dx, fourthPos.dx);
    expect(firstPos.dy, lessThan(fourthPos.dy));
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(firstPos)), isTrue);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(fourthPos)), isFalse);

    TestGesture gesture = await tester.startGesture(firstPos, pointer: 7);
    await tester.pump();
    await gesture.moveBy(const Offset(0.0, -1000.0));
    await tester.pump(const Duration(seconds: 1));
    // Wait and drag again to trigger https://github.com/flutter/flutter/issues/6329
    // (No idea why this is necessary, but the bug wouldn't repro without it.)
    await gesture.moveBy(const Offset(0.0, -1000.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump();

    // Now the first line is scrolled up, and the fourth line is visible.
    Offset newFirstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
    Offset newFourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));

    expect(newFirstPos.dy, lessThan(firstPos.dy));
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isFalse);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isTrue);

    // Now try scrolling by dragging the selection handle.

    // Long press the 'i' in 'Fourth line' to select the word.
    await tester.pump(const Duration(seconds: 1));
    final Offset untilPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth line')+8);
    gesture = await tester.startGesture(untilPos, pointer: 7);
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(controller.selection);
    expect(endpoints.length, 2);

    // Drag the left handle to the first line, just after 'First'.
    final Offset handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
    final Offset newHandlePos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveTo(newHandlePos + const Offset(0.0, -10.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    // The text should have scrolled up with the handle to keep the active
    // cursor visible, back to its original position.
    newFirstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
    newFourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));
    expect(newFirstPos.dy, firstPos.dy);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isTrue);
    expect(inputBox.hitTest(new HitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isFalse);
  });

  testWidgets('TextField smoke test', (WidgetTester tester) async {
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

    Future<Null> checkText(String testValue) {
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(TextField), testValue);

        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));

        await tester.pumpWidget(builder());
      });
    }

    await checkText('Hello World');
  });

  testWidgets('TextField with global key', (WidgetTester tester) async {
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
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(TextField), testValue);

        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));

        await tester.pumpWidget(builder());
      });
    }

    await checkText('Hello World');
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

  testWidgets('TextField with specified prefixStyle', (WidgetTester tester) async {
    final TextStyle prefixStyle = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            decoration: new InputDecoration(
              prefixText: 'Prefix:',
              prefixStyle: prefixStyle,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    final Text prefixText = tester.widget(find.text('Prefix:'));
    expect(prefixText.style, prefixStyle);
  });

  testWidgets('TextField with specified suffixStyle', (WidgetTester tester) async {
    final TextStyle suffixStyle = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    Widget builder() {
      return new Center(
        child: new Material(
          child: new TextField(
            decoration: new InputDecoration(
              suffixText: '.com',
              suffixStyle: suffixStyle,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(builder());

    final Text suffixText = tester.widget(find.text('.com'));
    expect(suffixText.style, suffixStyle);
  });

  testWidgets('TextField prefix and suffix appear correctly with no hint or label',
          (WidgetTester tester) async {
    final Key secondKey = new UniqueKey();

    Widget innerBuilder() {
      return new Center(
        child: new Material(
          child: new Column(
            children: <Widget>[
              const TextField(
                decoration: const InputDecoration(
                  labelText: 'First',
                ),
              ),
              new TextField(
                key: secondKey,
                decoration: const InputDecoration(
                  prefixText: 'Prefix',
                  suffixText: 'Suffix',
                ),
              ),
            ],
          ),
        ),
      );
    }
    Widget builder() => overlay(innerBuilder());

    await tester.pumpWidget(builder());

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);

    // Focus the Input. The prefix should still display.
    await tester.tap(find.byKey(secondKey));
    await tester.pump();

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);

    // Enter some text, and the prefix should still display.
    await tester.enterText(find.byKey(secondKey), "Hi");
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);
  });

  testWidgets('TextField prefix and suffix appear correctly with hint text',
          (WidgetTester tester) async {
    final TextStyle hintStyle = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final Key secondKey = new UniqueKey();

    Widget innerBuilder() {
      return new Center(
        child: new Material(
          child: new Column(
            children: <Widget>[
              const TextField(
                decoration: const InputDecoration(
                  labelText: 'First',
                ),
              ),
              new TextField(
                key: secondKey,
                decoration: new InputDecoration(
                  hintText: 'Hint',
                  hintStyle: hintStyle,
                  prefixText: 'Prefix',
                  suffixText: 'Suffix',
                ),
              ),
            ],
          ),
        ),
      );
    }
    Widget builder() => overlay(innerBuilder());

    await tester.pumpWidget(builder());

    // Neither the prefix or the suffix should initially be visible, only the hint.
    expect(find.text('Prefix'), findsNothing);
    expect(find.text('Suffix'), findsNothing);
    expect(find.text('Hint'), findsOneWidget);

    await tester.tap(find.byKey(secondKey));
    await tester.pump();

    // Focus the Input. The hint should display, but not the prefix and suffix.
    expect(find.text('Prefix'), findsNothing);
    expect(find.text('Suffix'), findsNothing);
    expect(find.text('Hint'), findsOneWidget);

    // Enter some text, and the hint should disappear and the prefix and suffix
    // should appear.
    await tester.enterText(find.byKey(secondKey), "Hi");
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);

    // It's onstage, but animated to zero opacity.
    expect(find.text('Hint'), findsOneWidget);
    final Element target = tester.element(find.text('Hint'));
    final Opacity opacity = target.ancestorWidgetOfExactType(Opacity);
    expect(opacity, isNotNull);
    expect(opacity.opacity, equals(0.0));

    // Check and make sure that the right styles were applied.
    final Text prefixText = tester.widget(find.text('Prefix'));
    expect(prefixText.style, hintStyle);
    final Text suffixText = tester.widget(find.text('Suffix'));
    expect(suffixText.style, hintStyle);
  });

  testWidgets('TextField prefix and suffix appear correctly with label text',
          (WidgetTester tester) async {
    final TextStyle prefixStyle = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final TextStyle suffixStyle = new TextStyle(
      color: Colors.green[500],
      fontSize: 12.0,
    );
    final Key secondKey = new UniqueKey();

    Widget innerBuilder() {
      return new Center(
        child: new Material(
          child: new Column(
            children: <Widget>[
              const TextField(
                decoration: const InputDecoration(
                  labelText: 'First',
                ),
              ),
              new TextField(
                key: secondKey,
                decoration: new InputDecoration(
                  labelText: 'Label',
                  prefixText: 'Prefix',
                  prefixStyle: prefixStyle,
                  suffixText: 'Suffix',
                  suffixStyle: suffixStyle,
                ),
              ),
            ],
          ),
        ),
      );
    }
    Widget builder() => overlay(innerBuilder());

    await tester.pumpWidget(builder());

    // Not focused.  The prefix should not display, but the label should.
    expect(find.text('Prefix'), findsNothing);
    expect(find.text('Suffix'), findsNothing);
    expect(find.text('Label'), findsOneWidget);

    await tester.tap(find.byKey(secondKey));
    await tester.pump();

    // Focus the input. The label should display, and also the prefix.
    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);
    expect(find.text('Label'), findsOneWidget);

    // Enter some text, and the label should stay and the prefix should
    // remain.
    await tester.enterText(find.byKey(secondKey), "Hi");
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);
    expect(find.text('Label'), findsOneWidget);

    // Check and make sure that the right styles were applied.
    final Text prefixText = tester.widget(find.text('Prefix'));
    expect(prefixText.style, prefixStyle);
    final Text suffixText = tester.widget(find.text('Suffix'));
    expect(suffixText.style, suffixStyle);
  });

  testWidgets('TextField label text animates', (WidgetTester tester) async {
    final Key secondKey = new UniqueKey();

    Widget innerBuilder() {
      return new Center(
        child: new Material(
          child: new Column(
            children: <Widget>[
              const TextField(
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

    Offset pos = tester.getTopLeft(find.text('Second'));

    // Focus the Input. The label should start animating upwards.
    await tester.tap(find.byKey(secondKey));
    await tester.idle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    Offset newPos = tester.getTopLeft(find.text('Second'));
    expect(newPos.dy, lessThan(pos.dy));

    // Label should still be sliding upward.
    await tester.pump(const Duration(milliseconds: 50));
    pos = newPos;
    newPos = tester.getTopLeft(find.text('Second'));
    expect(newPos.dy, lessThan(pos.dy));
  });

  testWidgets('No space between Input icon and text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const Material(
          child: const TextField(
            decoration: const InputDecoration(
              icon: const Icon(Icons.phone),
              labelText: 'label',
            ),
          ),
        ),
      ),
    );

    final double iconRight = tester.getTopRight(find.byType(Icon)).dx;
    expect(iconRight, equals(tester.getTopLeft(find.text('label')).dx));
    expect(iconRight, equals(tester.getTopLeft(find.byType(EditableText)).dx));
  });

  testWidgets('Collapsed hint text placement', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(const Center(
        child: const Material(
          child: const TextField(
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
            child: const TextField(
              textAlign: TextAlign.center,
              decoration: null,
            ),
          ),
        ),
      )),
    );

    final RenderEditable editable = findRenderEditable(tester);
    Offset topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 0)).topLeft,
    );

    expect(topLeft.dx, equals(399.0));

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );

    expect(topLeft.dx, equals(399.0));
  });

  testWidgets('Can align to center within center', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(new Center(
        child: new Material(
          child: new Container(
            width: 300.0,
            child: const Center(
              child: const TextField(
                textAlign: TextAlign.center,
                decoration: null,
              ),
            ),
          ),
        ),
      )),
    );

    final RenderEditable editable = findRenderEditable(tester);
    Offset topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 0)).topLeft,
    );

    expect(topLeft.dx, equals(399.0));

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );

    expect(topLeft.dx, equals(399.0));
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

    controller2.text = 'Additional Text';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('Additional Text'));

    controller2.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.idle();
    expect(tester.testTextInput.editingState['selectionBase'], equals(0));
    expect(tester.testTextInput.editingState['selectionExtent'], equals(5));

    controller2.clear();
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals(''));
  });

  testWidgets(
    'Cannot enter new lines onto single line TextField',
    (WidgetTester tester) async {
      final TextEditingController textController = new TextEditingController();

      await tester.pumpWidget(new Material(
        child: new TextField(controller: textController, decoration: null),
      ));

      await tester.enterText(find.byType(TextField), 'abc\ndef');

      expect(textController.text, 'abcdef');
    }
  );

  testWidgets(
    'Injected formatters are chained',
    (WidgetTester tester) async {
      final TextEditingController textController = new TextEditingController();

      await tester.pumpWidget(new Material(
        child: new TextField(
          controller: textController,
          decoration: null,
          inputFormatters: <TextInputFormatter> [
            new BlacklistingTextInputFormatter(
              new RegExp(r'[a-z]'),
              replacementString: '#',
            ),
          ],
        ),
      ));

      await tester.enterText(find.byType(TextField), 'a一b二c三\nd四e五f六');
      // The default single line formatter replaces \n with empty string.
      expect(textController.text, '#一#二#三#四#五#六');
    }
  );

  testWidgets(
    'Chained formatters are in sequence',
    (WidgetTester tester) async {
      final TextEditingController textController = new TextEditingController();

      await tester.pumpWidget(new Material(
        child: new TextField(
          controller: textController,
          decoration: null,
          maxLines: 2,
          inputFormatters: <TextInputFormatter> [
            new BlacklistingTextInputFormatter(
              new RegExp(r'[a-z]'),
              replacementString: '12\n',
            ),
            new WhitelistingTextInputFormatter(new RegExp(r'\n[0-9]')),
          ],
        ),
      ));

      await tester.enterText(find.byType(TextField), 'a1b2c3');
      // The first formatter turns it into
      // 12\n112\n212\n3
      // The second formatter turns it into
      // \n1\n2\n3
      // Multiline is allowed since maxLine != 1.
      expect(textController.text, '\n1\n2\n3');
    }
  );

  testWidgets(
    'Pasted values are formatted',
    (WidgetTester tester) async {
      final TextEditingController textController = new TextEditingController();

      Widget builder() {
        return overlay(new Center(
          child: new Material(
            child: new TextField(
              controller: textController,
              decoration: null,
              inputFormatters: <TextInputFormatter> [
                WhitelistingTextInputFormatter.digitsOnly,
              ],
            ),
          ),
        ));
      }

      await tester.pumpWidget(builder());

      await tester.enterText(find.byType(TextField), 'a1b\n2c3');
      expect(textController.text, '123');
      await tester.pumpWidget(builder());
      // skip past scrolling animation
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tapAt(textOffsetToPosition(tester, '123'.indexOf('2')));
      await tester.pumpWidget(builder());
      final RenderEditable renderEditable = findRenderEditable(tester);
      final List<TextSelectionPoint> endpoints =
          renderEditable.getEndpointsForSelection(textController.selection);
      await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
      await tester.pumpWidget(builder());

      Clipboard.setData(const ClipboardData(text: '一4二\n5三6'));
      await tester.tap(find.text('PASTE'));
      await tester.pumpWidget(builder());
      // Puts 456 before the 2 in 123.
      expect(textController.text, '145623');
    }
  );

  testWidgets(
    'Text field scrolls the caret into view',
    (WidgetTester tester) async {
      final TextEditingController controller = new TextEditingController();

      Widget builder() {
        return overlay(new Center(
          child: new Material(
            child: new Container(
              width: 100.0,
              child: new TextField(
                controller: controller,
              ),
            ),
          ),
        ));
      }

      await tester.pumpWidget(builder());

      final String longText = 'a' * 20;
      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpWidget(builder());
      // skip past scrolling animation
      await tester.pump(const Duration(milliseconds: 200));

      ScrollableState scrollableState = tester.firstState(find.byType(Scrollable));
      expect(scrollableState.position.pixels, equals(0.0));

      // Move the caret to the end of the text and check that the text field
      // scrolls to make the caret visible.
      controller.selection = new TextSelection.collapsed(offset: longText.length);
      await tester.pumpWidget(builder());
      // skip past scrolling animation
      await tester.pump(const Duration(milliseconds: 200));

      scrollableState = tester.firstState(find.byType(Scrollable));
      expect(scrollableState.position.pixels, isNot(equals(0.0)));
    }
  );
}

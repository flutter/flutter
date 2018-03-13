// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

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

class MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) => DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(MaterialLocalizationsDelegate old) => false;
}

class WidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) => DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(WidgetsLocalizationsDelegate old) => false;
}

Widget overlay({ Widget child }) {
  return new Localizations(
    locale: const Locale('en', 'US'),
    delegates: <LocalizationsDelegate<dynamic>>[
      new WidgetsLocalizationsDelegate(),
      new MaterialLocalizationsDelegate(),
    ],
    child: new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(size: const Size(800.0, 600.0)),
        child: new Overlay(
          initialEntries: <OverlayEntry>[
            new OverlayEntry(
              builder: (BuildContext context) => new Center(
                child: new Material(
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget boilerplate({ Widget child }) {
  return new Localizations(
    locale: const Locale('en', 'US'),
    delegates: <LocalizationsDelegate<dynamic>>[
      new WidgetsLocalizationsDelegate(),
      new MaterialLocalizationsDelegate(),
    ],
    child: new Directionality(
      textDirection: TextDirection.ltr,
      child: new MediaQuery(
        data: const MediaQueryData(size: const Size(800.0, 600.0)),
        child: new Center(
          child: new Material(
            child: child,
          ),
        ),
      ),
    ),
  );
}

Future<Null> skipPastScrollingAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

double getOpacity(WidgetTester tester, Finder finder) {
  return tester.widget<Opacity>(
    find.ancestor(
      of: finder,
      matching: find.byType(Opacity),
    )
  ).opacity;
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

  List<TextSelectionPoint> globalize(Iterable<TextSelectionPoint> points, RenderBox box) {
    return points.map((TextSelectionPoint point) {
      return new TextSelectionPoint(
        box.localToGlobal(point.point),
        point.direction,
      );
    }).toList();
  }

  Offset textOffsetToPosition(WidgetTester tester, int offset) {
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(
        new TextSelection.collapsed(offset: offset),
      ),
      renderEditable,
    );
    expect(endpoints.length, 1);
    return endpoints[0].point + const Offset(0.0, -2.0);
  }

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('TextField has consistent size', (WidgetTester tester) async {
    final Key textFieldKey = new UniqueKey();
    String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          key: textFieldKey,
          decoration: const InputDecoration(
            hintText: 'Placeholder',
          ),
          onChanged: (String value) {
            textFieldValue = value;
          }
        ),
      )
    );

    RenderBox findTextFieldBox() => tester.renderObject(find.byKey(textFieldKey));

    final RenderBox inputBox = findTextFieldBox();
    final Size emptyInputSize = inputBox.size;

    Future<Null> checkText(String testValue) async {
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(TextField), testValue);
        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));
        await skipPastScrollingAnimation(tester);
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
    await tester.pumpWidget(
      overlay(
        child: const TextField(
          decoration: const InputDecoration(
            hintText: 'Placeholder',
          ),
        ),
      ),
    );
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
    await tester.pumpWidget(
      overlay(
        child: const TextField(
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Placeholder',
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(TextField));

    const String testValue = 'ABC';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue,
      selection: const TextSelection.collapsed(offset: testValue.length),
    ));

    await tester.pump();

    // Enter a character into the obscured field and verify that the character
    // is temporarily shown to the user and then changed to a bullet.
    const String newChar = 'X';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue + newChar,
      selection: const TextSelection.collapsed(offset: testValue.length + 1),
    ));

    await tester.pump();

    String editText = findRenderEditable(tester).text.text;
    expect(editText.substring(editText.length - 1), newChar);

    await tester.pump(const Duration(seconds: 2));

    editText = findRenderEditable(tester).text.text;
    expect(editText.substring(editText.length - 1), '\u2022');
  });

  testWidgets('Caret position is updated on tap', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: controller,
        ),
      )
    );
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

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

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: controller,
        ),
      )
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    expect(controller.value.text, testValue);
    await skipPastScrollingAnimation(tester);

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

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Long press the 'e' to select 'def'.
    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

    final TextSelection selection = controller.selection;

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(selection),
      renderEditable,
    );
    expect(endpoints.length, 2);

    // Drag the right handle 2 letters to the right.
    // We use a small offset because the endpoint is on the very corner
    // of the handle.
    Offset handlePos = endpoints[1].point + const Offset(1.0, 1.0);
    Offset newHandlePos = textOffsetToPosition(tester, selection.extentOffset+2);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

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
    await tester.pump();

    expect(controller.selection.baseOffset, selection.baseOffset-2);
    expect(controller.selection.extentOffset, selection.extentOffset+2);
  });

  testWidgets('Can use selection toolbar', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
    RenderEditable renderEditable = findRenderEditable(tester);
    List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

    // SELECT ALL should select all the text.
    await tester.tap(find.text('SELECT ALL'));
    await tester.pump();
    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, testValue.length);

    // COPY should reset the selection.
    await tester.tap(find.text('COPY'));
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.isCollapsed, true);

    // Tap again to bring back the menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
    renderEditable = findRenderEditable(tester);
    endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

    // PASTE right before the 'e'.
    await tester.tap(find.text('PASTE'));
    await tester.pump();
    expect(controller.text, 'abc d${testValue}ef ghi');
  });

  testWidgets('Selection toolbar fades in', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('e')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pump();

    // Toolbar should fade in. Starting at 0% opacity.
    final Element target = tester.element(find.text('SELECT ALL'));
    final FadeTransition opacity = target.ancestorWidgetOfExactType(FadeTransition);
    expect(opacity, isNotNull);
    expect(opacity.opacity.value, equals(0.0));

    // Still fading in.
    await tester.pump(const Duration(milliseconds: 50));
    final FadeTransition opacity2 = target.ancestorWidgetOfExactType(FadeTransition);
    expect(opacity, same(opacity2));
    expect(opacity.opacity.value, greaterThan(0.0));
    expect(opacity.opacity.value, lessThan(1.0));

    // End the test here to ensure the animation is properly disposed of.
  });

  testWidgets('Multiline text will wrap up to maxLines', (WidgetTester tester) async {
    final Key textFieldKey = new UniqueKey();

    Widget builder(int maxLines) {
      return boilerplate(
        child: new TextField(
          key: textFieldKey,
          style: const TextStyle(color: Colors.black, fontSize: 34.0),
          maxLines: maxLines,
          decoration: const InputDecoration(
            hintText: 'Placeholder',
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

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 34.0),
          maxLines: 3,
        ),
      ),
    );

    const String testValue = kThreeLines;
    const String cutValue = 'First line of stuff ';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

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
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

    expect(controller.selection.baseOffset, 39);
    expect(controller.selection.extentOffset, 44);

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    expect(endpoints.length, 2);

    // Drag the right handle to the third line, just after 'Third'.
    Offset handlePos = endpoints[1].point + const Offset(1.0, 1.0);
    Offset newHandlePos = textOffsetToPosition(tester, testValue.indexOf('Third') + 5);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

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
    await tester.pump();

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 50);

    await tester.tap(find.text('CUT'));
    await tester.pump();
    expect(controller.selection.isCollapsed, true);
    expect(controller.text, cutValue);
  });

  testWidgets('Can scroll multiline input', (WidgetTester tester) async {
    final Key textFieldKey = new UniqueKey();
    final TextEditingController controller = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          key: textFieldKey,
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 34.0),
          maxLines: 2,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), kMoreThanFourLines);

    await tester.pump();
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
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
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
  },
  // This test fails on some Mac environments when libtxt is enabled.
  skip: Platform.isMacOS);

  testWidgets('TextField smoke test', (WidgetTester tester) async {
    String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          decoration: null,
          onChanged: (String value) {
            textFieldValue = value;
          },
        ),
      ),
    );

    Future<Null> checkText(String testValue) {
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(TextField), testValue);

        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));

        await tester.pump();
      });
    }

    await checkText('Hello World');
  });

  testWidgets('TextField with global key', (WidgetTester tester) async {
    final GlobalKey textFieldKey = new GlobalKey(debugLabel: 'textFieldKey');
    String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          key: textFieldKey,
          decoration: const InputDecoration(
            hintText: 'Placeholder',
          ),
          onChanged: (String value) { textFieldValue = value; },
        ),
      ),
    );

    Future<Null> checkText(String testValue) async {
      return TestAsyncUtils.guard(() async {
        await tester.enterText(find.byType(TextField), testValue);

        // Check that the onChanged event handler fired.
        expect(textFieldValue, equals(testValue));

        await tester.pump();
      });
    }

    await checkText('Hello World');
  });

  testWidgets('TextField errorText trumps helperText', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(
        child: const TextField(
          decoration: const InputDecoration(
            errorText: 'error text',
            helperText: 'helper text',
          ),
        ),
      ),
    );
    expect(find.text('helper text'), findsNothing);
    expect(find.text('error text'), findsOneWidget);
  });

  testWidgets('TextField with default helperStyle', (WidgetTester tester) async {
    final ThemeData themeData = new ThemeData(hintColor: Colors.blue[500]);
    await tester.pumpWidget(
      overlay(
        child: new Theme(
          data: themeData,
          child: const TextField(
            decoration: const InputDecoration(
              helperText: 'helper text',
            ),
          ),
        ),
      ),
    );
    final Text helperText = tester.widget(find.text('helper text'));
    expect(helperText.style.color, themeData.hintColor);
    expect(helperText.style.fontSize, MaterialTextGeometry.englishLike.caption.fontSize);
  });

  testWidgets('TextField with specified helperStyle', (WidgetTester tester) async {
    final TextStyle style = new TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          decoration: new InputDecoration(
            helperText: 'helper text',
            helperStyle: style,
          ),
        ),
      ),
    );
    final Text helperText = tester.widget(find.text('helper text'));
    expect(helperText.style, style);
  });

  testWidgets('TextField with default hintStyle', (WidgetTester tester) async {
    final TextStyle style = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final ThemeData themeData = new ThemeData(
      hintColor: Colors.blue[500],
    );

    await tester.pumpWidget(
      overlay(
        child: new Theme(
          data: themeData,
          child: new TextField(
            decoration: const InputDecoration(
              hintText: 'Placeholder',
            ),
            style: style,
          ),
        ),
      ),
    );

    final Text hintText = tester.widget(find.text('Placeholder'));
    expect(hintText.style.color, themeData.hintColor);
    expect(hintText.style.fontSize, style.fontSize);
  });

  testWidgets('TextField with specified hintStyle', (WidgetTester tester) async {
    final TextStyle hintStyle = new TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          decoration: new InputDecoration(
            hintText: 'Placeholder',
            hintStyle: hintStyle,
          ),
        ),
      ),
    );

    final Text hintText = tester.widget(find.text('Placeholder'));
    expect(hintText.style, hintStyle);
  });

  testWidgets('TextField with specified prefixStyle', (WidgetTester tester) async {
    final TextStyle prefixStyle = new TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          decoration: new InputDecoration(
            prefixText: 'Prefix:',
            prefixStyle: prefixStyle,
          ),
        ),
      ),
    );

    final Text prefixText = tester.widget(find.text('Prefix:'));
    expect(prefixText.style, prefixStyle);
  });

  testWidgets('TextField with specified suffixStyle', (WidgetTester tester) async {
    final TextStyle suffixStyle = new TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          decoration: new InputDecoration(
            suffixText: '.com',
            suffixStyle: suffixStyle,
          ),
        ),
      ),
    );

    final Text suffixText = tester.widget(find.text('.com'));
    expect(suffixText.style, suffixStyle);
  });

  testWidgets('TextField prefix and suffix appear correctly with no hint or label',
          (WidgetTester tester) async {
    final Key secondKey = new UniqueKey();

    await tester.pumpWidget(
      overlay(
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

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);

    // Focus the Input. The prefix should still display.
    await tester.tap(find.byKey(secondKey));
    await tester.pump();

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);

    // Enter some text, and the prefix should still display.
    await tester.enterText(find.byKey(secondKey), 'Hi');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Prefix'), findsOneWidget);
    expect(find.text('Suffix'), findsOneWidget);
  });

  testWidgets('TextField prefix and suffix appear correctly with hint text',
          (WidgetTester tester) async {
    final TextStyle hintStyle = new TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final Key secondKey = new UniqueKey();

    await tester.pumpWidget(
      overlay(
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

    // Neither the prefix or the suffix should initially be visible, only the hint.
    expect(getOpacity(tester, find.text('Prefix')), 0.0);
    expect(getOpacity(tester, find.text('Suffix')), 0.0);
    expect(getOpacity(tester, find.text('Hint')), 1.0);

    await tester.tap(find.byKey(secondKey));
    await tester.pumpAndSettle();

    // Focus the Input. The hint, prefix, and suffix should appear
    expect(getOpacity(tester, find.text('Prefix')), 1.0);
    expect(getOpacity(tester, find.text('Suffix')), 1.0);
    expect(getOpacity(tester, find.text('Hint')), 1.0);

    // Enter some text, and the hint should disappear and the prefix and suffix
    // should continue to be visible
    await tester.enterText(find.byKey(secondKey), 'Hi');
    await tester.pumpAndSettle();

    expect(getOpacity(tester, find.text('Prefix')), 1.0);
    expect(getOpacity(tester, find.text('Suffix')), 1.0);
    expect(getOpacity(tester, find.text('Hint')), 0.0);

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

    await tester.pumpWidget(
      overlay(
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

    // Not focused. The prefix and suffix should not appear, but the label should.
    expect(getOpacity(tester, find.text('Prefix')), 0.0);
    expect(getOpacity(tester, find.text('Suffix')), 0.0);
    expect(find.text('Label'), findsOneWidget);

    // Focus the input. The label, prefix, and suffix should appear.
    await tester.tap(find.byKey(secondKey));
    await tester.pumpAndSettle();

    expect(getOpacity(tester, find.text('Prefix')), 1.0);
    expect(getOpacity(tester, find.text('Suffix')), 1.0);
    expect(find.text('Label'), findsOneWidget);

    // Enter some text. The label, prefix, and suffix should remain visible.
    await tester.enterText(find.byKey(secondKey), 'Hi');
    await tester.pumpAndSettle();

    expect(getOpacity(tester, find.text('Prefix')), 1.0);
    expect(getOpacity(tester, find.text('Suffix')), 1.0);
    expect(find.text('Label'), findsOneWidget);

    // Check and make sure that the right styles were applied.
    final Text prefixText = tester.widget(find.text('Prefix'));
    expect(prefixText.style, prefixStyle);
    final Text suffixText = tester.widget(find.text('Suffix'));
    expect(suffixText.style, suffixStyle);
  });

  testWidgets('TextField label text animates', (WidgetTester tester) async {
    final Key secondKey = new UniqueKey();

    await tester.pumpWidget(
      overlay(
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

  testWidgets('Icon is separated from input/label by 16+12', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(
        child: const TextField(
          decoration: const InputDecoration(
            icon: const Icon(Icons.phone),
            labelText: 'label',
            filled: true,
          ),
        ),
      ),
    );
    final double iconRight = tester.getTopRight(find.byType(Icon)).dx;
    // Per https://material.io/guidelines/components/text-fields.html#text-fields-layout
    // There's a 16 dps gap between the right edge of the icon and the text field's
    // container, and the 12dps more padding between the left edge of the container
    // and the left edge of the input and label.
    expect(iconRight + 28.0, equals(tester.getTopLeft(find.text('label')).dx));
    expect(iconRight + 28.0, equals(tester.getTopLeft(find.byType(EditableText)).dx));
  });

  testWidgets('Collapsed hint text placement', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(
        child: const TextField(
          decoration: const InputDecoration.collapsed(
            hintText: 'hint',
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('hint')), equals(tester.getTopLeft(find.byType(TextField))));
  });

  testWidgets('Can align to center', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(
        child: new Container(
          width: 300.0,
          child: const TextField(
            textAlign: TextAlign.center,
            decoration: null,
          ),
        ),
      ),
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
      overlay(
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
    final TextEditingController controller1 = new TextEditingController(
      text: 'Initial Text',
    );
    final TextEditingController controller2 = new TextEditingController(
      text: 'More Text',
    );

    TextEditingController currentController;
    StateSetter setState;

    await tester.pumpWidget(
      overlay(
        child: new StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return new TextField(controller: currentController);
          }
        ),
      ),
    );
    expect(tester.testTextInput.editingState['text'], isEmpty);

    // Initial state with null controller.
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.editingState['text'], isEmpty);

    // Update the controller from null to controller1.
    setState(() {
      currentController = controller1;
    });
    await tester.pump();
    expect(tester.testTextInput.editingState['text'], equals('Initial Text'));

    // Verify that updates to controller1 are handled.
    controller1.text = 'Updated Text';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('Updated Text'));

    // Verify that switching from controller1 to controller2 is handled.
    setState(() {
      currentController = controller2;
    });
    await tester.pump();
    expect(tester.testTextInput.editingState['text'], equals('More Text'));

    // Verify that updates to controller1 are ignored.
    controller1.text = 'Ignored Text';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('More Text'));

    // Verify that updates to controller text are handled.
    controller2.text = 'Additional Text';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('Additional Text'));

    // Verify that updates to controller selection are handled.
    controller2.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.idle();
    expect(tester.testTextInput.editingState['selectionBase'], equals(0));
    expect(tester.testTextInput.editingState['selectionExtent'], equals(5));

    // Verify that calling clear() clears the text.
    controller2.clear();
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals(''));

    // Verify that switching from controller2 to null preserves current text.
    controller2.text = 'The Final Cut';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('The Final Cut'));
    setState(() {
      currentController = null;
    });
    await tester.pump();
    expect(tester.testTextInput.editingState['text'], equals('The Final Cut'));

    // Verify that changes to controller2 are ignored.
    controller2.text = 'Goodbye Cruel World';
    expect(tester.testTextInput.editingState['text'], equals('The Final Cut'));
  });

  testWidgets('Cannot enter new lines onto single line TextField', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: new TextField(controller: textController, decoration: null),
    ));

    await tester.enterText(find.byType(TextField), 'abc\ndef');

    expect(textController.text, 'abcdef');
  });

  testWidgets('Injected formatters are chained', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(boilerplate(
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
  });

  testWidgets('Chained formatters are in sequence', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(boilerplate(
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
  });

  testWidgets('Pasted values are formatted', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: textController,
          decoration: null,
          inputFormatters: <TextInputFormatter> [
            WhitelistingTextInputFormatter.digitsOnly,
          ],
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a1b\n2c3');
    expect(textController.text, '123');
    await skipPastScrollingAnimation(tester);

    await tester.tapAt(textOffsetToPosition(tester, '123'.indexOf('2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(textController.selection),
      renderEditable,
    );
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

    Clipboard.setData(const ClipboardData(text: '一4二\n5三6'));
    await tester.tap(find.text('PASTE'));
    await tester.pump();
    // Puts 456 before the 2 in 123.
    expect(textController.text, '145623');
  });

  testWidgets('Text field scrolls the caret into view', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new Container(
          width: 100.0,
          child: new TextField(
            controller: controller,
          ),
        ),
      ),
    );

    final String longText = 'a' * 20;
    await tester.enterText(find.byType(TextField), longText);
    await skipPastScrollingAnimation(tester);

    ScrollableState scrollableState = tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, equals(0.0));

    // Move the caret to the end of the text and check that the text field
    // scrolls to make the caret visible.
    controller.selection = new TextSelection.collapsed(offset: longText.length);
    await tester.pump(); // TODO(ianh): Figure out why this extra pump is needed.
    await skipPastScrollingAnimation(tester);

    scrollableState = tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, isNot(equals(0.0)));
  });

  testWidgets('haptic feedback', (WidgetTester tester) async {
    final FeedbackTester feedback = new FeedbackTester();
    final TextEditingController controller = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new Container(
          width: 100.0,
          child: new TextField(
            controller: controller,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 0);
    expect(feedback.hapticCount, 0);

    await tester.longPress(find.byType(TextField));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 0);
    expect(feedback.hapticCount, 1);

    feedback.dispose();
  });

  testWidgets('Text field drops selection when losing focus', (WidgetTester tester) async {
    final Key key1 = new UniqueKey();
    final TextEditingController controller1 = new TextEditingController();
    final Key key2 = new UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: new Column(
          children: <Widget>[
            new TextField(
              key: key1,
              controller: controller1
            ),
            new TextField(key: key2),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(key1));
    await tester.enterText(find.byKey(key1), 'abcd');
    await tester.pump();
    controller1.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
    await tester.pump();
    expect(controller1.selection, isNot(equals(TextRange.empty)));

    await tester.tap(find.byKey(key2));
    await tester.pump();
    expect(controller1.selection, equals(TextRange.empty));
  });

  testWidgets('Selection is consistent with text length', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    controller.text = 'abcde';
    controller.selection = const TextSelection.collapsed(offset: 5);

    controller.text = '';
    expect(controller.selection.start, lessThanOrEqualTo(0));
    expect(controller.selection.end, lessThanOrEqualTo(0));

    expect(() {
      controller.selection = const TextSelection.collapsed(offset: 10);
    }, throwsFlutterError);
  });

  testWidgets('maxLength limits input.', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: new TextField(
        controller: textController,
        maxLength: 10,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    expect(textController.text, '0123456789');
  });

  testWidgets('maxLength limits input length even if decoration is null.', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: new TextField(
        controller: textController,
        decoration: null,
        maxLength: 10,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    expect(textController.text, '0123456789');
  });

  testWidgets('maxLength still works with other formatters.', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: new TextField(
        controller: textController,
        maxLength: 10,
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
    expect(textController.text, '#一#二#三#四#五');
  });

  testWidgets("maxLength isn't enforced when maxLengthEnforced is false.", (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: new TextField(
        controller: textController,
        maxLength: 10,
        maxLengthEnforced: false,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    expect(textController.text, '0123456789101112');
  });

  testWidgets('maxLength shows warning when maxLengthEnforced is false.', (WidgetTester tester) async {
    final TextEditingController textController = new TextEditingController();
    const TextStyle testStyle = const TextStyle(color: Colors.deepPurpleAccent);

    await tester.pumpWidget(boilerplate(
      child: new TextField(
        decoration: const InputDecoration(errorStyle: testStyle),
        controller: textController,
        maxLength: 10,
        maxLengthEnforced: false,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    await tester.pump();

    expect(textController.text, '0123456789101112');
    expect(find.text('16 / 10'), findsOneWidget);
    Text counterTextWidget = tester.widget(find.text('16 / 10'));
    expect(counterTextWidget.style.color, equals(Colors.deepPurpleAccent));

    await tester.enterText(find.byType(TextField), '0123456789');
    await tester.pump();

    expect(textController.text, '0123456789');
    expect(find.text('10 / 10'), findsOneWidget);
    counterTextWidget = tester.widget(find.text('10 / 10'));
    expect(counterTextWidget.style.color, isNot(equals(Colors.deepPurpleAccent)));
  });

  testWidgets('setting maxLength shows counter', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: const Material(
        child: const DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
          child: const Center(
            child: const TextField(
              maxLength: 10,
            ),
          ),
        ),
      ),
    ));

    expect(find.text('0 / 10'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '01234');
    await tester.pump();

    expect(find.text('5 / 10'), findsOneWidget);
  });

  testWidgets('TextField identifies as text field in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: const DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
            child: const Center(
              child: const TextField(
                maxLength: 10,
              ),
            ),
          ),
        ),
      ),
    );

    expect(semantics, includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.isTextField]));
  });

  testWidgets('Caret works when maxLines is null', (WidgetTester tester) async {
    final TextEditingController controller = new TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          controller: controller,
          maxLines: null,
        ),
      )
    );

    const String testValue = 'x';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.baseOffset, -1);

    // Tap the selection handle to bring up the "paste / select all" menu.
    await tester.tapAt(textOffsetToPosition(tester, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is

    // Confirm that the selection was updated.
    expect(controller.selection.baseOffset, 0);
  });

  testWidgets('TextField baseline alignment', (WidgetTester tester) async {
    final TextEditingController controllerA = new TextEditingController(text: 'A');
    final TextEditingController controllerB = new TextEditingController(text: 'B');
    final Key keyA = new UniqueKey();
    final Key keyB = new UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            new Expanded(
              child: new TextField(
                key: keyA,
                decoration: null,
                controller: controllerA,
                style: const TextStyle(fontSize: 10.0),
              )
            ),
            const Text(
              'abc',
              style: const TextStyle(fontSize: 20.0),
            ),
            new Expanded(
              child: new TextField(
                key: keyB,
                decoration: null,
                controller: controllerB,
                style: const TextStyle(fontSize: 30.0),
              ),
            ),
          ],
        ),
      ),
    );

    // The Ahem font extends 0.2 * fontSize below the baseline.
    // So the three row elements line up like this:
    //
    //  A  abc  B
    //  ---------   baseline
    //  2  4    6   space below the baseline = 0.2 * fontSize
    //  ---------   rowBottomY

    final double rowBottomY = tester.getBottomLeft(find.byType(Row)).dy;
    expect(tester.getBottomLeft(find.byKey(keyA)).dy, closeTo(rowBottomY - 4.0, 0.001));
    expect(tester.getBottomLeft(find.text('abc')).dy, closeTo(rowBottomY - 2.0, 0.001));
    expect(tester.getBottomLeft(find.byKey(keyB)).dy, rowBottomY);
  });

  testWidgets('TextField semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    final TextEditingController controller = new TextEditingController();
    final Key key = new UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          key: key,
          controller: controller,
        ),
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    controller.text = 'Guten Tag';
    await tester.pump();

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          textDirection: TextDirection.ltr,
          value: 'Guten Tag',
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    await tester.tap(find.byKey(key));
    await tester.pump();

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          textDirection: TextDirection.ltr,
          value: 'Guten Tag',
          textSelection: const TextSelection.collapsed(offset: 9),
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    controller.selection = const TextSelection.collapsed(offset: 4);
    await tester.pump();

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          textDirection: TextDirection.ltr,
          textSelection: const TextSelection.collapsed(offset: 4),
          value: 'Guten Tag',
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    controller.text = 'Schönen Feierabend';
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          textDirection: TextDirection.ltr,
          textSelection: const TextSelection.collapsed(offset: 0),
          value: 'Schönen Feierabend',
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('TextField semantics for selections', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    final TextEditingController controller = new TextEditingController()
      ..text = 'Hello';
    final Key key = new UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          key: key,
          controller: controller,
        ),
      ),
    );

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          value: 'Hello',
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    // Focus the text field
    await tester.tap(find.byKey(key));
    await tester.pump();

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          value: 'Hello',
          textSelection: const TextSelection.collapsed(offset: 5),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    controller.selection = const TextSelection(baseOffset: 5, extentOffset: 3);
    await tester.pump();

    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 2,
          value: 'Hello',
          textSelection: const TextSelection(baseOffset: 5, extentOffset: 3),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
            SemanticsAction.cut,
            SemanticsAction.copy,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('TextField change selection with semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;
    final TextEditingController controller = new TextEditingController()
      ..text = 'Hello';
    final Key key = new UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: new TextField(
          key: key,
          controller: controller,
        ),
      ),
    );

    // Focus the text field
    await tester.tap(find.byKey(key));
    await tester.pump();

    const int inputFieldId = 2;

    expect(controller.selection, const TextSelection.collapsed(offset: 5, affinity: TextAffinity.upstream));
    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: inputFieldId,
          value: 'Hello',
          textSelection: const TextSelection.collapsed(offset: 5),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    // move cursor back once
    semanticsOwner.performAction(inputFieldId, SemanticsAction.setSelection, <String, int>{
      'base': 4,
      'extent': 4,
    });
    await tester.pump();
    expect(controller.selection, const TextSelection.collapsed(offset: 4));

    // move cursor to front
    semanticsOwner.performAction(inputFieldId, SemanticsAction.setSelection, <String, int>{
      'base': 0,
      'extent': 0,
    });
    await tester.pump();
    expect(controller.selection, const TextSelection.collapsed(offset: 0));

    // select all
    semanticsOwner.performAction(inputFieldId, SemanticsAction.setSelection, <String, int>{
      'base': 0,
      'extent': 5,
    });
    await tester.pump();
    expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
    expect(semantics, hasSemantics(new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: inputFieldId,
          value: 'Hello',
          textSelection: const TextSelection(baseOffset: 0, extentOffset: 5),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
            SemanticsAction.cut,
            SemanticsAction.copy,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  });


}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui show window;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;

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
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: <LocalizationsDelegate<dynamic>>[
      WidgetsLocalizationsDelegate(),
      MaterialLocalizationsDelegate(),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                return Center(
                  child: Material(
                    child: child,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget boilerplate({ Widget child }) {
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: <LocalizationsDelegate<dynamic>>[
      WidgetsLocalizationsDelegate(),
      MaterialLocalizationsDelegate(),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: Center(
          child: Material(
            child: child,
          ),
        ),
      ),
    ),
  );
}

Future<void> skipPastScrollingAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

double getOpacity(WidgetTester tester, Finder finder) {
  return tester.widget<FadeTransition>(
    find.ancestor(
      of: finder,
      matching: find.byType(FadeTransition),
    )
  ).opacity.value;
}

void main() {
  final MockClipboard mockClipboard = MockClipboard();
  SystemChannels.platform.setMockMethodCallHandler(mockClipboard.handleMethodCall);

  const String kThreeLines =
    'First line of text is\n'
    'Second line goes until\n'
    'Third line of stuff';
  const String kMoreThanFourLines =
    kThreeLines +
    '\nFourth line won\'t display and ends at';

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
    return points.map<TextSelectionPoint>((TextSelectionPoint point) {
      return TextSelectionPoint(
        box.localToGlobal(point.point),
        point.direction,
      );
    }).toList();
  }

  Offset textOffsetToPosition(WidgetTester tester, int offset) {
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(
        TextSelection.collapsed(offset: offset),
      ),
      renderEditable,
    );
    expect(endpoints.length, 1);
    return endpoints[0].point + const Offset(0.0, -2.0);
  }

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('TextField passes onEditingComplete to EditableText', (WidgetTester tester) async {
    final VoidCallback onEditingComplete = () {};

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            onEditingComplete: onEditingComplete,
          ),
        ),
      ),
    );

    final Finder editableTextFinder = find.byType(EditableText);
    expect(editableTextFinder, findsOneWidget);

    final EditableText editableTextWidget = tester.widget(editableTextFinder);
    expect(editableTextWidget.onEditingComplete, onEditingComplete);
  });

  testWidgets('TextField has consistent size', (WidgetTester tester) async {
    final Key textFieldKey = UniqueKey();
    String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: TextField(
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

    Future<void> checkText(String testValue) async {
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
          decoration: InputDecoration(
            hintText: 'Placeholder',
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(TextField));

    final EditableTextState editableText = tester.state(find.byType(EditableText));

    // Check that the cursor visibility toggles after each blink interval.
    Future<void> checkCursorToggle() async {
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
      selection: TextSelection.collapsed(offset: 1),
    ));
    await checkCursorToggle();
  });

  testWidgets('Cursor animates on iOS', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TextField(),
        ),
      ),
    );

    final Finder textFinder = find.byType(TextField);
    await tester.tap(textFinder);
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorColor.alpha, 255);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(renderEditable.cursorColor.alpha, 255);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 100));

    expect(renderEditable.cursorColor.alpha, 110);

    await tester.pump(const Duration(milliseconds: 100));

    expect(renderEditable.cursorColor.alpha, 16);
    await tester.pump(const Duration(milliseconds: 50));

    expect(renderEditable.cursorColor.alpha, 0);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Cursor radius is 2.0 on iOS', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TextField(),
        ),
      ),
    );

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorRadius, const Radius.circular(2.0));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('cursor has expected defaults', (WidgetTester tester) async {
    await tester.pumpWidget(
        overlay(
          child: const TextField(
          ),
        )
    );

    final TextField textField = tester.firstWidget(find.byType(TextField));
    expect(textField.cursorWidth, 2.0);
    expect(textField.cursorRadius, null);
  });

  testWidgets('cursor has expected radius value', (WidgetTester tester) async {
    await tester.pumpWidget(
        overlay(
          child: const TextField(
            cursorRadius: Radius.circular(3.0),
          ),
        )
    );

    final TextField textField = tester.firstWidget(find.byType(TextField));
    expect(textField.cursorWidth, 2.0);
    expect(textField.cursorRadius, const Radius.circular(3.0));
  });

  testWidgets('cursor layout has correct width', (WidgetTester tester) async {
    EditableText.debugDeterministicCursor = true;
    await tester.pumpWidget(
        overlay(
          child: const RepaintBoundary(
            child: TextField(
              cursorWidth: 15.0,
            ),
          ),
        )
    );
    await tester.enterText(find.byType(TextField), ' ');
    await skipPastScrollingAnimation(tester);

    await expectLater(
      find.byType(TextField),
      matchesGoldenFile('text_field_test.0.0.png'),
    );
    EditableText.debugDeterministicCursor = false;
  }, skip: !Platform.isLinux);

  testWidgets('cursor layout has correct radius', (WidgetTester tester) async {
    EditableText.debugDeterministicCursor = true;
    await tester.pumpWidget(
        overlay(
          child: const RepaintBoundary(
            child: TextField(
              cursorWidth: 15.0,
              cursorRadius: Radius.circular(3.0),
            ),
          ),
        )
    );
    await tester.enterText(find.byType(TextField), ' ');
    await skipPastScrollingAnimation(tester);

    await expectLater(
      find.byType(TextField),
      matchesGoldenFile('text_field_test.1.0.png'),
    );
    EditableText.debugDeterministicCursor = false;
  }, skip: !Platform.isLinux);

  testWidgets('obscureText control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(
        child: const TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Placeholder',
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(TextField));

    const String testValue = 'ABC';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue,
      selection: TextSelection.collapsed(offset: testValue.length),
    ));

    await tester.pump();

    // Enter a character into the obscured field and verify that the character
    // is temporarily shown to the user and then changed to a bullet.
    const String newChar = 'X';
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: testValue + newChar,
      selection: TextSelection.collapsed(offset: testValue.length + 1),
    ));

    await tester.pump();

    String editText = findRenderEditable(tester).text.text;
    expect(editText.substring(editText.length - 1), newChar);

    await tester.pump(const Duration(seconds: 2));

    editText = findRenderEditable(tester).text.text;
    expect(editText.substring(editText.length - 1), '\u2022');
  });

  testWidgets('Caret position is updated on tap', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
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

  testWidgets('enableInteractiveSelection = false, tap', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          controller: controller,
          enableInteractiveSelection: false,
        ),
      )
    );
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Tap would ordinarily reposition the caret.
    final int tapIndex = testValue.indexOf('e');
    final Offset ePos = textOffsetToPosition(tester, tapIndex);
    await tester.tapAt(ePos);
    await tester.pump();

    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);
  });

  testWidgets('Can long press to select', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
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

  testWidgets('enableInteractiveSelection = false, long-press', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          controller: controller,
          enableInteractiveSelection: false,
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

    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);
  });

  testWidgets('Can drag handles to change selection', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            dragStartBehavior: DragStartBehavior.down,
            controller: controller,
          ),
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
    expect(controller.selection.extentOffset, selection.extentOffset);

    // Drag the left handle 2 letters to the left.
    handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
    newHandlePos = textOffsetToPosition(tester, selection.baseOffset-2);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.selection.baseOffset, selection.baseOffset);
    expect(controller.selection.extentOffset, selection.extentOffset);
  });

  testWidgets('Can use selection toolbar', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
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
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
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

  testWidgets('An obscured TextField is not selectable by default', (WidgetTester tester) async {
    // This is a regression test for
    // https://github.com/flutter/flutter/issues/24100

    final TextEditingController controller = TextEditingController();
    Widget buildFrame(bool obscureText, bool enableInteractiveSelection) {
      return overlay(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          enableInteractiveSelection: enableInteractiveSelection,
        ),
      );
    }

    // Obscure text and don't enable or disable selection
    await tester.pumpWidget(buildFrame(true, null));
    await tester.enterText(find.byType(TextField), 'abcdefghi');
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.isCollapsed, true);

    // Long press doesn't select anything
    final Offset ePos = textOffsetToPosition(tester, 1);
    final TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();
    expect(controller.selection.isCollapsed, true);
  });

  testWidgets('An obscured TextField is selectable when enabled', (WidgetTester tester) async {
    // This is a regression test for
    // https://github.com/flutter/flutter/issues/24100

    final TextEditingController controller = TextEditingController();
    Widget buildFrame(bool obscureText, bool enableInteractiveSelection) {
      return overlay(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          enableInteractiveSelection: enableInteractiveSelection,
        ),
      );
    }

    // Explicitly allow selection on obscured text
    await tester.pumpWidget(buildFrame(true, true));
    await tester.enterText(find.byType(TextField), 'abcdefghi');
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.isCollapsed, true);

    // Long press does select text
    final Offset ePos2 = textOffsetToPosition(tester, 1);
    final TestGesture gesture2 = await tester.startGesture(ePos2, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture2.up();
    await tester.pump();
    expect(controller.selection.isCollapsed, false);
  });

  testWidgets('Multiline text will wrap up to maxLines', (WidgetTester tester) async {
    final Key textFieldKey = UniqueKey();

    Widget builder(int maxLines) {
      return boilerplate(
        child: TextField(
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


  testWidgets('Multiline hint text will wrap up to maxLines', (WidgetTester tester) async {
    final Key textFieldKey = UniqueKey();

    Widget builder(int maxLines, final String hintMsg) {
      return boilerplate(
        child: TextField(
          key: textFieldKey,
          style: const TextStyle(color: Colors.black, fontSize: 34.0),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintMsg,
          ),
        ),
      );
    }

    const String hintPlaceholder = 'Placeholder';
    const String multipleLineText = 'Here\'s a text, which is more than one line, to demostrate the multiple line hint text';
    await tester.pumpWidget(builder(null, hintPlaceholder));

    RenderBox findHintText(String hint) => tester.renderObject(find.text(hint));

    final RenderBox hintTextBox = findHintText(hintPlaceholder);
    final Size oneLineHintSize = hintTextBox.size;

    await tester.pumpWidget(builder(null, hintPlaceholder));
    expect(findHintText(hintPlaceholder), equals(hintTextBox));
    expect(hintTextBox.size, equals(oneLineHintSize));

    const int maxLines = 3;
    await tester.pumpWidget(builder(maxLines, multipleLineText));
    final Text hintTextWidget = tester.widget(find.text(multipleLineText));
    expect(hintTextWidget.maxLines, equals(maxLines));
    expect(findHintText(multipleLineText).size, greaterThan(oneLineHintSize));
  });

  testWidgets('Can drag handles to change selection in multiline', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          dragStartBehavior: DragStartBehavior.down,
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 34.0),
          maxLines: 3,
        ),
      ),
    );

    const String testValue = kThreeLines;
    const String cutValue = 'First line of stuff';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Check that the text spans multiple lines.
    final Offset firstPos = textOffsetToPosition(tester, testValue.indexOf('First'));
    final Offset secondPos = textOffsetToPosition(tester, testValue.indexOf('Second'));
    final Offset thirdPos = textOffsetToPosition(tester, testValue.indexOf('Third'));
    final Offset middleStringPos = textOffsetToPosition(tester, testValue.indexOf('irst'));
    expect(firstPos.dx, 0);
    expect(secondPos.dx, 0);
    expect(thirdPos.dx, 0);
    expect(middleStringPos.dx, 34);
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
    final Key textFieldKey = UniqueKey();
    final TextEditingController controller = TextEditingController(
      text: kMoreThanFourLines,
    );

    await tester.pumpWidget(
      overlay(
        child: TextField(
          dragStartBehavior: DragStartBehavior.down,
          key: textFieldKey,
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 34.0),
          maxLines: 2,
        ),
      ),
    );

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));
    final RenderBox inputBox = findInputBox();

    // Check that the last line of text is not displayed.
    final Offset firstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
    final Offset fourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));
    expect(firstPos.dx, 0);
    expect(fourthPos.dx, 0);
    expect(firstPos.dx, fourthPos.dx);
    expect(firstPos.dy, lessThan(fourthPos.dy));
    expect(inputBox.hitTest(HitTestResult(), position: inputBox.globalToLocal(firstPos)), isTrue);
    expect(inputBox.hitTest(HitTestResult(), position: inputBox.globalToLocal(fourthPos)), isFalse);

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
    await tester.pump(const Duration(seconds: 1));

    // Now the first line is scrolled up, and the fourth line is visible.
    Offset newFirstPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('First'));
    Offset newFourthPos = textOffsetToPosition(tester, kMoreThanFourLines.indexOf('Fourth'));

    expect(newFirstPos.dy, lessThan(firstPos.dy));
    expect(inputBox.hitTest(HitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isFalse);
    expect(inputBox.hitTest(HitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isTrue);

    // Now try scrolling by dragging the selection handle.
    // Long press the 'i' in 'Fourth line' to select the word.
    final Offset selectedWordPos = textOffsetToPosition(
      tester,
      kMoreThanFourLines.indexOf('Fourth line') + 8,
    );

    gesture = await tester.startGesture(selectedWordPos, pointer: 7);
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(controller.selection.base.offset, 91);
    expect(controller.selection.extent.offset, 94);

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    expect(endpoints.length, 2);

    // Drag the left handle to the first line, just after 'First'.
    final Offset handlePos = endpoints[0].point + const Offset(-1, 1);
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
    expect(inputBox.hitTest(HitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isTrue);
    expect(inputBox.hitTest(HitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isFalse);
  });

  testWidgets('TextField smoke test', (WidgetTester tester) async {
    String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: TextField(
          decoration: null,
          onChanged: (String value) {
            textFieldValue = value;
          },
        ),
      ),
    );

    Future<void> checkText(String testValue) {
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
    final GlobalKey textFieldKey = GlobalKey(debugLabel: 'textFieldKey');
    String textFieldValue;

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: textFieldKey,
          decoration: const InputDecoration(
            hintText: 'Placeholder',
          ),
          onChanged: (String value) { textFieldValue = value; },
        ),
      ),
    );

    Future<void> checkText(String testValue) async {
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
          decoration: InputDecoration(
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
    final ThemeData themeData = ThemeData(hintColor: Colors.blue[500]);
    await tester.pumpWidget(
      overlay(
        child: Theme(
          data: themeData,
          child: const TextField(
            decoration: InputDecoration(
              helperText: 'helper text',
            ),
          ),
        ),
      ),
    );
    final Text helperText = tester.widget(find.text('helper text'));
    expect(helperText.style.color, themeData.hintColor);
    expect(helperText.style.fontSize, Typography.englishLike2014.caption.fontSize);
  });

  testWidgets('TextField with specified helperStyle', (WidgetTester tester) async {
    final TextStyle style = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: TextField(
          decoration: InputDecoration(
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
    final TextStyle style = TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final ThemeData themeData = ThemeData(
      hintColor: Colors.blue[500],
    );

    await tester.pumpWidget(
      overlay(
        child: Theme(
          data: themeData,
          child: TextField(
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
    final TextStyle hintStyle = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: TextField(
          decoration: InputDecoration(
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
    final TextStyle prefixStyle = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: TextField(
          decoration: InputDecoration(
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
    final TextStyle suffixStyle = TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );

    await tester.pumpWidget(
      overlay(
        child: TextField(
          decoration: InputDecoration(
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
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Column(
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            TextField(
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
    final TextStyle hintStyle = TextStyle(
      inherit: false,
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Column(
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            TextField(
              key: secondKey,
              decoration: InputDecoration(
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
    final TextStyle prefixStyle = TextStyle(
      color: Colors.pink[500],
      fontSize: 10.0,
    );
    final TextStyle suffixStyle = TextStyle(
      color: Colors.green[500],
      fontSize: 12.0,
    );
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Column(
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            TextField(
              key: secondKey,
              decoration: InputDecoration(
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
    final Key secondKey = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Column(
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(
                labelText: 'First',
              ),
            ),
            TextField(
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
          decoration: InputDecoration(
            icon: Icon(Icons.phone),
            labelText: 'label',
            filled: true,
          ),
        ),
      ),
    );
    final double iconRight = tester.getTopRight(find.byType(Icon)).dx;
    // Per https://material.io/go/design-text-fields#text-fields-layout
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
          decoration: InputDecoration.collapsed(
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
        child: Container(
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

    expect(topLeft.dx, equals(401.0));

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );

    expect(topLeft.dx, equals(401.0));
  });

  testWidgets('Can align to center within center', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(
        child: Container(
          width: 300.0,
          child: const Center(
            child: TextField(
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

    expect(topLeft.dx, equals(401.0));

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );

    expect(topLeft.dx, equals(401.0));
  });

  testWidgets('Controller can update server', (WidgetTester tester) async {
    final TextEditingController controller1 = TextEditingController(
      text: 'Initial Text',
    );
    final TextEditingController controller2 = TextEditingController(
      text: 'More Text',
    );

    TextEditingController currentController;
    StateSetter setState;

    await tester.pumpWidget(
      overlay(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return TextField(controller: currentController);
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
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: TextField(controller: textController, decoration: null),
    ));

    await tester.enterText(find.byType(TextField), 'abc\ndef');

    expect(textController.text, 'abcdef');
  });

  testWidgets('Injected formatters are chained', (WidgetTester tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: TextField(
        controller: textController,
        decoration: null,
        inputFormatters: <TextInputFormatter> [
          BlacklistingTextInputFormatter(
            RegExp(r'[a-z]'),
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
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: TextField(
        controller: textController,
        decoration: null,
        maxLines: 2,
        inputFormatters: <TextInputFormatter> [
          BlacklistingTextInputFormatter(
            RegExp(r'[a-z]'),
            replacementString: '12\n',
          ),
          WhitelistingTextInputFormatter(RegExp(r'\n[0-9]')),
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
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
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
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: Container(
          width: 100.0,
          child: TextField(
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
    controller.selection = TextSelection.collapsed(offset: longText.length);
    await tester.pump(); // TODO(ianh): Figure out why this extra pump is needed.
    await skipPastScrollingAnimation(tester);

    scrollableState = tester.firstState(find.byType(Scrollable));
    // For a horizontal input, scrolls to the exact position of the caret.
    expect(scrollableState.position.pixels, equals(223.0));
  });

  testWidgets('Multiline text field scrolls the caret into view', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: Container(
          child: TextField(
            controller: controller,
            maxLines: 6,
          ),
        ),
      ),
    );

    const String tallText = 'a\nb\nc\nd\ne\nf\ng'; // One line over max
    await tester.enterText(find.byType(TextField), tallText);
    await skipPastScrollingAnimation(tester);

    ScrollableState scrollableState = tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, equals(0.0));

    // Move the caret to the end of the text and check that the text field
    // scrolls to make the caret visible.
    controller.selection = const TextSelection.collapsed(offset: tallText.length);
    await tester.pump();
    await skipPastScrollingAnimation(tester);

    // Should have scrolled down exactly one line height (7 lines of text in 6
    // line text field).
    final double lineHeight = findRenderEditable(tester).preferredLineHeight;
    scrollableState = tester.firstState(find.byType(Scrollable));
    expect(scrollableState.position.pixels, closeTo(lineHeight, 0.1));
  });

  testWidgets('haptic feedback', (WidgetTester tester) async {
    final FeedbackTester feedback = FeedbackTester();
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: Container(
          width: 100.0,
          child: TextField(
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
    final Key key1 = UniqueKey();
    final TextEditingController controller1 = TextEditingController();
    final Key key2 = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Column(
          children: <Widget>[
            TextField(
              key: key1,
              controller: controller1
            ),
            TextField(key: key2),
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
    final TextEditingController controller = TextEditingController();

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
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: TextField(
        controller: textController,
        maxLength: 10,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    expect(textController.text, '0123456789');
  });

  testWidgets('maxLength limits input length even if decoration is null.', (WidgetTester tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: TextField(
        controller: textController,
        decoration: null,
        maxLength: 10,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    expect(textController.text, '0123456789');
  });

  testWidgets('maxLength still works with other formatters.', (WidgetTester tester) async {
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: TextField(
        controller: textController,
        maxLength: 10,
        inputFormatters: <TextInputFormatter> [
          BlacklistingTextInputFormatter(
            RegExp(r'[a-z]'),
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
    final TextEditingController textController = TextEditingController();

    await tester.pumpWidget(boilerplate(
      child: TextField(
        controller: textController,
        maxLength: 10,
        maxLengthEnforced: false,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    expect(textController.text, '0123456789101112');
  });

  testWidgets('maxLength shows warning when maxLengthEnforced is false.', (WidgetTester tester) async {
    final TextEditingController textController = TextEditingController();
    const TextStyle testStyle = TextStyle(color: Colors.deepPurpleAccent);

    await tester.pumpWidget(boilerplate(
      child: TextField(
        decoration: const InputDecoration(errorStyle: testStyle),
        controller: textController,
        maxLength: 10,
        maxLengthEnforced: false,
      ),
    ));

    await tester.enterText(find.byType(TextField), '0123456789101112');
    await tester.pump();

    expect(textController.text, '0123456789101112');
    expect(find.text('16/10'), findsOneWidget);
    Text counterTextWidget = tester.widget(find.text('16/10'));
    expect(counterTextWidget.style.color, equals(Colors.deepPurpleAccent));

    await tester.enterText(find.byType(TextField), '0123456789');
    await tester.pump();

    expect(textController.text, '0123456789');
    expect(find.text('10/10'), findsOneWidget);
    counterTextWidget = tester.widget(find.text('10/10'));
    expect(counterTextWidget.style.color, isNot(equals(Colors.deepPurpleAccent)));
  });

  testWidgets('setting maxLength shows counter', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: Center(
            child: TextField(
              maxLength: 10,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0/10'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '01234');
    await tester.pump();

    expect(find.text('5/10'), findsOneWidget);
  });

  testWidgets(
      'setting maxLength to TextField.noMaxLength shows only entered length',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: Center(
            child: TextField(
              maxLength: TextField.noMaxLength,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '01234');
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('passing a buildCounter shows returned widget', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
            child: TextField(
              buildCounter: (BuildContext context, {int currentLength, int maxLength, bool isFocused}) {
                return Text('${currentLength.toString()} of ${maxLength.toString()}');
              },
              maxLength: 10,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0 of 10'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '01234');
    await tester.pump();

    expect(find.text('5 of 10'), findsOneWidget);
  });

  testWidgets('TextField identifies as text field in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
              child: TextField(
                maxLength: 10,
              ),
            ),
          ),
        ),
    );

    expect(semantics, includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.isTextField]));

    semantics.dispose();
  });

  void sendFakeKeyEvent(Map<String, dynamic> data) {
    BinaryMessages.handlePlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(data),
          (ByteData data) { },
    );
  }

  void sendKeyEventWithCode(int code, bool down, bool shiftDown, bool ctrlDown) {

    int metaState = shiftDown ? 1 : 0;
    if (ctrlDown)
      metaState |= 1 << 12;

    sendFakeKeyEvent(<String, dynamic>{
      'type': down ? 'keydown' : 'keyup',
      'keymap': 'android',
      'keyCode' : code,
      'hidUsage': 0x04,
      'codePoint': 0x64,
      'metaState': metaState,
    });
  }

  group('Keyboard Tests', (){
    TextEditingController controller;

    setUp( () {
      controller = TextEditingController();
    });

    MaterialApp setupWidget() {

      final FocusNode focusNode = FocusNode();
      controller = TextEditingController();

      return MaterialApp(
        home:  Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: null,
            child: TextField(
              controller: controller,
              maxLines: 3,
            ),
          ) ,
        ),
      );
    }

    testWidgets('Shift test 1', (WidgetTester tester) async{

      await tester.pumpWidget(setupWidget());
      const String testValue = 'a big house';
      await tester.enterText(find.byType(TextField), testValue);

      await tester.idle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      sendKeyEventWithCode(22, true, true, false);     // RIGHT_ARROW keydown, SHIFT_ON
      expect(controller.selection.extentOffset - controller.selection.baseOffset, 1);
    });

    testWidgets('Control Shift test', (WidgetTester tester) async{
      await tester.pumpWidget(setupWidget());
      const String testValue = 'their big house';
      await tester.enterText(find.byType(TextField), testValue);

      await tester.idle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      sendKeyEventWithCode(22, true, true, true);         // RIGHT_ARROW keydown SHIFT_ON, CONTROL_ON

      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 5);
    });

    testWidgets('Down and up test', (WidgetTester tester) async{
      await tester.pumpWidget(setupWidget());
      const String testValue = 'a big house';
      await tester.enterText(find.byType(TextField), testValue);

      await tester.idle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      sendKeyEventWithCode(20, true, true, false);         // DOWN_ARROW keydown
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 11);

      sendKeyEventWithCode(20, false, true, false);          // DOWN_ARROW keyup
      await tester.pumpAndSettle();
      sendKeyEventWithCode(19, true, true, false);           // UP_ARROW keydown
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 0);
    });


    testWidgets('Down and up test 2', (WidgetTester tester) async{
      await tester.pumpWidget(setupWidget());
      const String testValue = 'a big house\njumped over a mouse\nOne more line yay'; // 11 \n 19
      await tester.enterText(find.byType(TextField), testValue);

      await tester.idle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i += 1) {
        sendKeyEventWithCode(22, true, false, false);             // RIGHT_ARROW keydown
        await tester.pumpAndSettle();
        sendKeyEventWithCode(22, false, false, false);            // RIGHT_ARROW keyup
        await tester.pumpAndSettle();
      }
      sendKeyEventWithCode(20, true, true, false);               // DOWN_ARROW keydown
      await tester.pumpAndSettle();
      sendKeyEventWithCode(20, false, true, false);              // DOWN_ARROW keyup
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 12);

      sendKeyEventWithCode(20, true, true, false);                 // DOWN_ARROW keydown
      await tester.pumpAndSettle();
      sendKeyEventWithCode(20, false, true, false);                // DOWN_ARROW keyup
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 32);

      sendKeyEventWithCode(19, true, true, false);               // UP_ARROW keydown
      await tester.pumpAndSettle();
      sendKeyEventWithCode(19, false, true, false);              // UP_ARROW keyup
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 12);

      sendKeyEventWithCode(19, true, true, false);               // UP_ARROW keydown
      await tester.pumpAndSettle();
      sendKeyEventWithCode(19, false, true, false);              // UP_ARROW keyup
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 0);

      sendKeyEventWithCode(19, true, true, false);               // UP_ARROW keydown
      await tester.pumpAndSettle();
      sendKeyEventWithCode(19, false, true, false);              // UP_ARROW keyup
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 5);
    });
  });

  const int _kXKeyCode = 52;
  const int _kCKeyCode = 31;
  const int _kVKeyCode = 50;
  const int _kAKeyCode = 29;
  const int _kDelKeyCode = 112;

  testWidgets('Copy paste test', (WidgetTester tester) async{
    final FocusNode focusNode = FocusNode();
    final TextEditingController controller = TextEditingController();
    final TextField textField =
      TextField(
        controller: controller,
        maxLines: 3,
      );

    String clipboardContent = '';
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData')
        clipboardContent = methodCall.arguments['text'];
      else if (methodCall.method == 'Clipboard.getData')
        return <String, dynamic>{'text': clipboardContent};
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: null,
            child: textField,
          ),
        ),
      ),
    );

    const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
    await tester.enterText(find.byType(TextField), testValue);

    await tester.idle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Select the first 5 characters
    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(22, true, true, false);             // RIGHT_ARROW keydown shift
      await tester.pumpAndSettle();
      sendKeyEventWithCode(22, false, false, false);           // RIGHT_ARROW keyup
      await tester.pumpAndSettle();
    }

    // Copy them
    sendKeyEventWithCode(_kCKeyCode, true, false, true);    // keydown control
    await tester.pumpAndSettle();
    sendKeyEventWithCode(_kCKeyCode, false, false, false);  // keyup control
    await tester.pumpAndSettle();

    expect(clipboardContent, 'a big');

    sendKeyEventWithCode(22, true, false, false);              // RIGHT_ARROW keydown
    await tester.pumpAndSettle();
    sendKeyEventWithCode(22, false, false, false);             // RIGHT_ARROW keyup
    await tester.pumpAndSettle();

    // Paste them
    sendKeyEventWithCode(_kVKeyCode, true, false, true);     // Control V keydown
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    sendKeyEventWithCode(_kVKeyCode, false, false, false);   // Control V keyup
    await tester.pumpAndSettle();

    const String expected = 'a biga big house\njumped over a mouse';
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets('Cut test', (WidgetTester tester) async{
    final FocusNode focusNode = FocusNode();
    final TextEditingController controller = TextEditingController();
    final TextField textField =
      TextField(
        controller: controller,
        maxLines: 3,
      );
    String clipboardContent = '';
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData')
        clipboardContent = methodCall.arguments['text'];
      else if (methodCall.method == 'Clipboard.getData')
        return <String, dynamic>{'text': clipboardContent};
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: null,
            child: textField,
          ),
        ),
      ),
    );

    const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
    await tester.enterText(find.byType(TextField), testValue);

    await tester.idle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Select the first 5 characters
    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(22, true, true, false);             // RIGHT_ARROW keydown shift
      await tester.pumpAndSettle();
      sendKeyEventWithCode(22, false, false, false);           // RIGHT_ARROW keyup
      await tester.pumpAndSettle();
    }

    // Cut them
    sendKeyEventWithCode(_kXKeyCode, true, false, true);    // keydown control X
    await tester.pumpAndSettle();
    sendKeyEventWithCode(_kXKeyCode, false, false, false);  // keyup control X
    await tester.pumpAndSettle();

    expect(clipboardContent, 'a big');

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(22, true, false, false);  // RIGHT_ARROW keydown
      await tester.pumpAndSettle();
      sendKeyEventWithCode(22, false, false, false); // RIGHT_ARROW keyup
      await tester.pumpAndSettle();
    }

    // Paste them
    sendKeyEventWithCode(_kVKeyCode, true, false, true);     // Control V keydown
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    sendKeyEventWithCode(_kVKeyCode, false, false, false);    // Control V keyup
    await tester.pumpAndSettle();

    const String expected = ' housa bige\njumped over a mouse';
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets('Select all test', (WidgetTester tester) async{
    final FocusNode focusNode = FocusNode();
    final TextEditingController controller = TextEditingController();
    final TextField textField =
      TextField(
        controller: controller,
        maxLines: 3,
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: null,
            child: textField,
          ),
        ),
      ),
    );

    const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
    await tester.enterText(find.byType(TextField), testValue);

    await tester.idle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Select All
    sendKeyEventWithCode(_kAKeyCode, true, false, true);    // keydown control A
    await tester.pumpAndSettle();
    sendKeyEventWithCode(_kAKeyCode, false, false, true);   // keyup control A
    await tester.pumpAndSettle();

    // Delete them
    sendKeyEventWithCode(_kDelKeyCode, true, false, false);     // DEL keydown
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    sendKeyEventWithCode(_kDelKeyCode, false, false, false);     // DEL keyup
    await tester.pumpAndSettle();

    const String expected = '';
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets('Delete test', (WidgetTester tester) async{
    final FocusNode focusNode = FocusNode();
    final TextEditingController controller = TextEditingController();
    final TextField textField =
      TextField(
        controller: controller,
        maxLines: 3,
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: null,
            child: textField,
          ),
        ),
      ),
    );

    const String testValue = 'a big house\njumped over a mouse'; // 11 \n 19
    await tester.enterText(find.byType(TextField), testValue);

    await tester.idle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // Delete
    for (int i = 0; i < 6; i += 1) {
      sendKeyEventWithCode(_kDelKeyCode, true, false, false); // keydown DEL
      await tester.pumpAndSettle();
      sendKeyEventWithCode(_kDelKeyCode, false, false, false); // keyup DEL
      await tester.pumpAndSettle();
    }

    const String expected = 'house\njumped over a mouse';
    expect(find.text(expected), findsOneWidget);

    sendKeyEventWithCode(_kAKeyCode, true, false, true);    // keydown control A
    await tester.pumpAndSettle();
    sendKeyEventWithCode(_kAKeyCode, false, false, true);   // keyup control A
    await tester.pumpAndSettle();


    sendKeyEventWithCode(_kDelKeyCode, true, false, false); // keydown DEL
    await tester.pumpAndSettle();
    sendKeyEventWithCode(_kDelKeyCode, false, false, false); // keyup DEL
    await tester.pumpAndSettle();

    const String expected2 = '';
    expect(find.text(expected2), findsOneWidget);
  });

  testWidgets('Changing positions of text fields', (WidgetTester tester) async{

    final FocusNode focusNode = FocusNode();
    final List<RawKeyEvent> events = <RawKeyEvent>[];

    final TextEditingController c1 = TextEditingController();
    final TextEditingController c2 = TextEditingController();
    final Key key1 = UniqueKey();
    final Key key2 = UniqueKey();

   await tester.pumpWidget(
      MaterialApp(
        home:
        Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: events.add,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  key: key1,
                  controller: c1,
                  maxLines: 3,
                ),
                TextField(
                  key: key2,
                  controller: c2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    const String testValue = 'a big house';
    await tester.enterText(find.byType(TextField).first, testValue);

    await tester.idle();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(22, true, true, false); // RIGHT_ARROW keydown
      await tester.pumpAndSettle();
    }

    expect(c1.selection.extentOffset - c1.selection.baseOffset, 5);

    await tester.pumpWidget(
      MaterialApp(
        home:
        Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: events.add,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  key: key2,
                  controller: c2,
                  maxLines: 3,
                ),
                TextField(
                  key: key1,
                  controller: c1,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(22, true, true, false); // RIGHT_ARROW keydown
      await tester.pumpAndSettle();
    }

    expect(c1.selection.extentOffset - c1.selection.baseOffset, 10);
  });


  testWidgets('Changing focus test', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final List<RawKeyEvent> events = <RawKeyEvent>[];

    final TextEditingController c1 = TextEditingController();
    final TextEditingController c2 = TextEditingController();
    final Key key1 = UniqueKey();
    final Key key2 = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home:
        Material(
          child: RawKeyboardListener(
            focusNode: focusNode,
            onKey: events.add,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  key: key1,
                  controller: c1,
                  maxLines: 3,
                ),
                TextField(
                  key: key2,
                  controller: c2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.idle();
    await tester.tap(find.byType(TextField).first);

    const String testValue = 'a big house';
    await tester.enterText(find.byType(TextField).first, testValue);

    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(22, true, true, false); // RIGHT_ARROW keydown
      await tester.pumpAndSettle();
    }

    expect(c1.selection.extentOffset - c1.selection.baseOffset, 5);
    expect(c2.selection.extentOffset - c2.selection.baseOffset, 0);

    await tester.idle();
    await tester.tap(find.byType(TextField).last);

    await tester.enterText(find.byType(TextField).last, testValue);

    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(22, true, true, false); // RIGHT_ARROW keydown
      await tester.pumpAndSettle();
    }

    expect(c1.selection.extentOffset - c1.selection.baseOffset, 0);
    expect(c2.selection.extentOffset - c2.selection.baseOffset, 5);
  });

  testWidgets('Caret works when maxLines is null', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
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
    final TextEditingController controllerA = TextEditingController(text: 'A');
    final TextEditingController controllerB = TextEditingController(text: 'B');
    final Key keyA = UniqueKey();
    final Key keyB = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: TextField(
                key: keyA,
                decoration: null,
                controller: controllerA,
                style: const TextStyle(fontSize: 10.0),
              )
            ),
            const Text(
              'abc',
              style: TextStyle(fontSize: 20.0),
            ),
            Expanded(
              child: TextField(
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
    final SemanticsTester semantics = SemanticsTester(tester);
    final TextEditingController controller = TextEditingController();
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
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

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
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

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          textDirection: TextDirection.ltr,
          value: 'Guten Tag',
          textSelection: const TextSelection.collapsed(offset: 9),
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
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

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          textDirection: TextDirection.ltr,
          textSelection: const TextSelection.collapsed(offset: 4),
          value: 'Guten Tag',
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.moveCursorForwardByWord,
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

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          textDirection: TextDirection.ltr,
          textSelection: const TextSelection.collapsed(offset: 0),
          value: 'Schönen Feierabend',
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorForwardByWord,
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

  testWidgets('TextField semantics, enableInteractiveSelection = false', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final TextEditingController controller = TextEditingController();
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
          enableInteractiveSelection: false,
        ),
      ),
    );

    await tester.tap(find.byKey(key));
    await tester.pump();

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            // Absent the following because enableInteractiveSelection: false
            // SemanticsAction.moveCursorBackwardByCharacter,
            // SemanticsAction.moveCursorBackwardByWord,
            // SemanticsAction.setSelection,
            // SemanticsAction.paste,
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
    final SemanticsTester semantics = SemanticsTester(tester);
    final TextEditingController controller = TextEditingController()
      ..text = 'Hello';
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
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

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          value: 'Hello',
          textSelection: const TextSelection.collapsed(offset: 5),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
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

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          value: 'Hello',
          textSelection: const TextSelection(baseOffset: 5, extentOffset: 3),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.moveCursorForwardByWord,
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
    final SemanticsTester semantics = SemanticsTester(tester);
    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;
    final TextEditingController controller = TextEditingController()
      ..text = 'Hello';
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
        ),
      ),
    );

    // Focus the text field
    await tester.tap(find.byKey(key));
    await tester.pump();

    const int inputFieldId = 1;

    expect(controller.selection, const TextSelection.collapsed(offset: 5, affinity: TextAffinity.upstream));
    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: inputFieldId,
          value: 'Hello',
          textSelection: const TextSelection.collapsed(offset: 5),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
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
    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: inputFieldId,
          value: 'Hello',
          textSelection: const TextSelection(baseOffset: 0, extentOffset: 5),
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
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

  testWidgets('Can activate TextField with explicit controller via semantics ', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17801

    const String textInTextField = 'Hello';

    final SemanticsTester semantics = SemanticsTester(tester);
    final SemanticsOwner semanticsOwner = tester.binding.pipelineOwner.semanticsOwner;
    final TextEditingController controller = TextEditingController()
      ..text = textInTextField;
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
        ),
      ),
    );

    const int inputFieldId = 1;

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: inputFieldId,
            flags: <SemanticsFlag>[SemanticsFlag.isTextField],
            actions: <SemanticsAction>[SemanticsAction.tap],
            value: textInTextField,
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
      ignoreRect: true, ignoreTransform: true,
    ));

    semanticsOwner.performAction(inputFieldId, SemanticsAction.tap);
    await tester.pump();

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: inputFieldId,
            flags: <SemanticsFlag>[
              SemanticsFlag.isTextField,
              SemanticsFlag.isFocused,
            ],
            actions: <SemanticsAction>[
              SemanticsAction.tap,
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
              SemanticsAction.setSelection,
              SemanticsAction.paste,
            ],
            value: textInTextField,
            textDirection: TextDirection.ltr,
            textSelection: const TextSelection(
              baseOffset: textInTextField.length,
              extentOffset: textInTextField.length,
            ),
          ),
        ],
      ),
      ignoreRect: true, ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('TextField throws when not descended from a Material widget', (WidgetTester tester) async {
    const Widget textField = TextField();
    await tester.pumpWidget(textField);
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.toString(), startsWith('No Material widget found.'));
    expect(exception.toString(), endsWith(':\n  $textField\nThe ancestors of this widget were:\n  [root]'));
  });

  testWidgets('TextField loses focus when disabled', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      boilerplate(
        child: TextField(
          focusNode: focusNode,
          autofocus: true,
          enabled: true,
        ),
      ),
    );
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(
      boilerplate(
        child: TextField(
          focusNode: focusNode,
          autofocus: true,
          enabled: false,
        ),
      ),
    );
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('TextField displays text with text direction', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TextField(
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );

    RenderEditable editable = findRenderEditable(tester);

    await tester.enterText(find.byType(TextField), '0123456789101112');
    await tester.pumpAndSettle();
    Offset topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 10)).topLeft,
    );

    expect(topLeft.dx, equals(701.6666870117188));

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TextField(
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );

    editable = findRenderEditable(tester);

    await tester.enterText(find.byType(TextField), '0123456789101112');
    await tester.pumpAndSettle();
    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 10)).topLeft,
    );

    expect(topLeft.dx, equals(160.6666717529297));
  });

  testWidgets('TextField semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final TextEditingController controller = TextEditingController();
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'label',
            hintText: 'hint',
            helperText: 'helper',
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'label',
          id: 1,
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
          ],
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              label: 'helper',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              id: 3,
              label: '10 characters remaining',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'hint',
          id: 1,
          textDirection: TextDirection.ltr,
          textSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
          actions: <SemanticsAction>[
            SemanticsAction.tap,
            SemanticsAction.setSelection,
            SemanticsAction.paste,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
            SemanticsFlag.isFocused,
          ],
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              label: 'helper',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              id: 3,
              label: '10 characters remaining',
              flags: <SemanticsFlag>[
                SemanticsFlag.isLiveRegion,
              ],
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true));

    controller.text = 'hello';
    await tester.pump();
    semantics.dispose();
  });

  testWidgets('InputDecoration counterText can have a semanticCounterText', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final TextEditingController controller = TextEditingController();
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'label',
            hintText: 'hint',
            helperText: 'helper',
            counterText: '0/10',
            semanticCounterText: '0 out of 10',
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'label',
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
          ],
          children: <TestSemantics>[
            TestSemantics(
              label: 'helper',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: '0 out of 10',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true, ignoreId: true));

    semantics.dispose();
  });

  testWidgets('InputDecoration errorText semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final TextEditingController controller = TextEditingController();
    final Key key = UniqueKey();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: key,
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'label',
            hintText: 'hint',
            errorText: 'oh no!',
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'label',
          textDirection: TextDirection.ltr,
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.isTextField,
          ],
          children: <TestSemantics>[
            TestSemantics(
              label: 'oh no!',
              flags: <SemanticsFlag>[
                SemanticsFlag.isLiveRegion,
              ],
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true, ignoreId: true));

    semantics.dispose();
  });

  testWidgets('floating label does not overlap with value at large textScaleFactors', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'Just some text');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
              data: MediaQueryData.fromWindow(ui.window).copyWith(textScaleFactor: 4.0),
              child: Center(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Label', border: UnderlineInputBorder()),
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
    );

    await tester.tap(find.byType(TextField));
    final Rect labelRect = tester.getRect(find.text('Label'));
    final Rect fieldRect = tester.getRect(find.text('Just some text'));
    expect(labelRect.bottom, lessThanOrEqualTo(fieldRect.top));
  });

  testWidgets('TextField scrolls into view but does not bounce (SingleChildScrollView)', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/20485

    final Key textField1 = UniqueKey();
    final Key textField2 = UniqueKey();
    final ScrollController scrollController = ScrollController();

    double minOffset;
    double maxOffset;

    scrollController.addListener(() {
      final double offset = scrollController.offset;
      minOffset = math.min(minOffset ?? offset, offset);
      maxOffset = math.max(maxOffset ?? offset, offset);
    });

    Widget buildFrame(Axis scrollDirection) {
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              controller: scrollController,
              child: Column(
                children: <Widget>[
                  SizedBox( // visible when scrollOffset is 0.0
                    height: 100.0,
                    width: 100.0,
                    child: TextField(key: textField1, scrollPadding: const EdgeInsets.all(200.0)),
                  ),
                  const SizedBox(
                    height: 600.0, // Same size as the frame. Initially
                    width: 800.0,  // textField2 is not visible
                  ),
                  SizedBox( // visible when scrollOffset is 200.0
                    height: 100.0,
                    width: 100.0,
                    child: TextField(key: textField2, scrollPadding: const EdgeInsets.all(200.0)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(Axis.vertical));
    await tester.enterText(find.byKey(textField1), '1');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
    await tester.pumpAndSettle();

    expect(minOffset, 0.0);
    expect(maxOffset, 200.0);

    minOffset = null;
    maxOffset = null;

    await tester.pumpWidget(buildFrame(Axis.horizontal));
    await tester.enterText(find.byKey(textField1), '1');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
    await tester.pumpAndSettle();

    expect(minOffset, 0.0);
    expect(maxOffset, 200.0);
  });

  testWidgets('TextField scrolls into view but does not bounce (ListView)', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/20485

    final Key textField1 = UniqueKey();
    final Key textField2 = UniqueKey();
    final ScrollController scrollController = ScrollController();

    double minOffset;
    double maxOffset;

    scrollController.addListener(() {
      final double offset = scrollController.offset;
      minOffset = math.min(minOffset ?? offset, offset);
      maxOffset = math.max(maxOffset ?? offset, offset);
    });

    Widget buildFrame(Axis scrollDirection) {
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              controller: scrollController,
              children: <Widget>[
                SizedBox( // visible when scrollOffset is 0.0
                  height: 100.0,
                  width: 100.0,
                  child: TextField(key: textField1, scrollPadding: const EdgeInsets.all(200.0)),
                ),
                const SizedBox(
                  height: 450.0, // 50.0 smaller than the overall frame so that both
                  width: 650.0,  // textfields are always partially visible.
                ),
                SizedBox( // visible when scrollOffset = 50.0
                  height: 100.0,
                  width: 100.0,
                  child: TextField(key: textField2, scrollPadding: const EdgeInsets.all(200.0)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(Axis.vertical));
    await tester.enterText(find.byKey(textField1), '1'); // textfield1 is visible
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
    await tester.pumpAndSettle();

    expect(minOffset, 0.0);
    expect(maxOffset, 50.0);

    minOffset = null;
    maxOffset = null;

    await tester.pumpWidget(buildFrame(Axis.horizontal));
    await tester.enterText(find.byKey(textField1), '1'); // textfield1 is visible
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField2), '2'); //scroll textField2 into view
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(textField1), '3'); //scroll textField1 back into view
    await tester.pumpAndSettle();

    expect(minOffset, 0.0);
    expect(maxOffset, 50.0);
  });

  testWidgets('onTap is called upon tap', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      overlay(
        child: TextField(
          onTap: () {
            tapCount += 1;
          },
        ),
      ),
    );

    expect(tapCount, 0);
    await tester.tap(find.byType(TextField));
    // Wait a bit so they're all single taps and not double taps.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tapCount, 3);
  });

  testWidgets('onTap is not called, field is disabled', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      overlay(
        child: TextField(
          enabled: false,
          onTap: () {
            tapCount += 1;
          },
        ),
      ),
    );

    expect(tapCount, 0);
    await tester.tap(find.byType(TextField));
    await tester.tap(find.byType(TextField));
    await tester.tap(find.byType(TextField));
    expect(tapCount, 0);
  });

  testWidgets('Includes cursor for TextField', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/24612

    Widget buildFrame({
      double stepWidth,
      double cursorWidth,
      TextAlign textAlign,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IntrinsicWidth(
                  stepWidth: stepWidth,
                  child: TextField(
                    textAlign: textAlign,
                    cursorWidth: cursorWidth,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // A cursor of default size doesn't cause the TextField to increase its
    // width.
    const String text = '1234';
    double stepWidth = 80.0;
    await tester.pumpWidget(buildFrame(
      stepWidth: 80.0,
      cursorWidth: 2.0,
      textAlign: TextAlign.left,
    ));
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TextField)).width, stepWidth);

    // A wide cursor is counted in the width of the text and causes the
    // TextField to increase to twice the stepWidth.
    await tester.pumpWidget(buildFrame(
      stepWidth: stepWidth,
      cursorWidth: 18.0,
      textAlign: TextAlign.left,
    ));
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TextField)).width, 2 * stepWidth);

    // A null stepWidth causes the TextField to perfectly wrap the text plus
    // the cursor regardless of alignment.
    stepWidth = null;
    const double WIDTH_OF_CHAR = 16.0;
    await tester.pumpWidget(buildFrame(
      stepWidth: stepWidth,
      cursorWidth: 18.0,
      textAlign: TextAlign.left,
    ));
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TextField)).width, WIDTH_OF_CHAR * text.length + 18.0);
    await tester.pumpWidget(buildFrame(
      stepWidth: stepWidth,
      cursorWidth: 18.0,
      textAlign: TextAlign.right,
    ));
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TextField)).width, WIDTH_OF_CHAR * text.length + 18.0);
  });

  testWidgets('TextField style is merged with theme', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/23994

    final ThemeData themeData = ThemeData(
      textTheme: TextTheme(
        subhead: TextStyle(
          color: Colors.blue[500],
        ),
      ),
    );

    Widget buildFrame(TextStyle style) {
      return MaterialApp(
        theme: themeData,
        home: Material(
          child: Center(
            child: TextField(
              style: style,
            ),
          ),
        ),
      );
    }

    // Empty TextStyle is overridden by theme
    await tester.pumpWidget(buildFrame(const TextStyle()));
    EditableText editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, themeData.textTheme.subhead.color);
    expect(editableText.style.background, themeData.textTheme.subhead.background);
    expect(editableText.style.shadows, themeData.textTheme.subhead.shadows);
    expect(editableText.style.decoration, themeData.textTheme.subhead.decoration);
    expect(editableText.style.locale, themeData.textTheme.subhead.locale);
    expect(editableText.style.wordSpacing, themeData.textTheme.subhead.wordSpacing);

    // Properties set on TextStyle override theme
    const Color setColor = Colors.red;
    await tester.pumpWidget(buildFrame(const TextStyle(color: setColor)));
    editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, setColor);

    // inherit: false causes nothing to be merged in from theme
    await tester.pumpWidget(buildFrame(const TextStyle(
      fontSize: 24.0,
      textBaseline: TextBaseline.alphabetic,
      inherit: false,
    )));
    editableText = tester.widget(find.byType(EditableText));
    expect(editableText.style.color, isNull);
  });

  testWidgets('style enforces required fields', (WidgetTester tester) async {
    Widget buildFrame(TextStyle style) {
      return MaterialApp(
        home: Material(
          child: TextField(
            style: style,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(const TextStyle(
      inherit: false,
      fontSize: 12.0,
      textBaseline: TextBaseline.alphabetic,
    )));
    expect(tester.takeException(), isNull);

    // With inherit not set to false, will pickup required fields from theme
    await tester.pumpWidget(buildFrame(const TextStyle(
      fontSize: 12.0,
    )));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildFrame(const TextStyle(
      inherit: false,
      fontSize: 12.0,
    )));
    expect(tester.takeException(), isNotNull);
  });

  testWidgets(
    'tap moves cursor to the edge of the word it tapped on (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // We moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // But don't trigger the toolbar.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'tap moves cursor to the position tapped (Android)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // We moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 3),
      );

      // But don't trigger the toolbar.
      expect(find.byType(FlatButton), findsNothing);
    },
  );

  testWidgets(
    'two slow taps do not trigger a word selection (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // Plain collapsed selection.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // No toolbar.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'double tap selects word and first tap of double tap moves cursor (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      // This tap just puts the cursor somewhere different than where the double
      // tap will occur to test that the double tap moves the existing cursor first.
      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump();

      // Second tap selects the word around the cursor.
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );

      // Selected text shows 3 toolbar buttons.
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'double tap selects word and first tap of double tap moves cursor and shows toolbar (Android)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      // This tap just puts the cursor somewhere different than where the double
      // tap will occur to test that the double tap moves the existing cursor first.
      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 9),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump();

      // Second tap selects the word around the cursor.
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );

      // Selected text shows 3 toolbar buttons.
      expect(find.byType(FlatButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'double tap hold selects word (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      final TestGesture gesture =
         await tester.startGesture(textfieldStart + const Offset(150.0, 5.0));
      // Hold the press.
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );

      // Selected text shows 3 toolbar buttons.
      expect(find.byType(CupertinoButton), findsNWidgets(3));

      await gesture.up();
      await tester.pump();

      // Still selected.
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'tap after a double tap select is not affected (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tapAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump();

      // Plain collapsed selection at the edge of first word. In iOS 12, the
      // the first tap after a double tap ends up putting the cursor at where
      // you tapped instead of the edge like every other single tap. This is
      // likely a bug in iOS 12 and not present in other versions.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // No toolbar.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'long press moves cursor to the exact long press position and shows toolbar (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.longPressAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // Collapsed cursor for iOS long press.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 3),
      );

      // Collapsed toolbar shows 2 buttons.
      expect(find.byType(CupertinoButton), findsNWidgets(2));
    },
  );

  testWidgets(
    'long press selects word and shows toolbar (Android)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.longPressAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );

      // Collapsed toolbar shows 3 buttons.
      expect(find.byType(FlatButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'long press tap is not a double tap (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.longPressAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump();

      // We ended up moving the cursor to the edge of the same word and dismissed
      // the toolbar.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );

      // Collapsed toolbar shows 2 buttons.
      expect(find.byType(CupertinoButton), findsNothing);
    },
  );

  testWidgets(
    'long tap after a double tap select is not affected (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor to the beginning of the second word.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.longPressAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump();

      // Plain collapsed selection at the exact tap position.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 6),
      );

      // Long press toolbar.
      expect(find.byType(CupertinoButton), findsNWidgets(2));
    },
  );

  testWidgets(
    'double tap after a long tap is not affected (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.longPressAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump();

      // Double tap selection.
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets(
    'double tap chains work (iOS)',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'Atwater Peel Sherbrooke Bonaventure',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Material(
            child: Center(
              child: TextField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );
      await tester.tapAt(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));

      // Double tap selecting the same word somewhere else is fine.
      await tester.tapAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7, affinity: TextAffinity.upstream),
      );
      await tester.tapAt(textfieldStart + const Offset(100.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));

      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      // First tap moved the cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 8, affinity: TextAffinity.downstream),
      );
      await tester.tapAt(textfieldStart + const Offset(150.0, 5.0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        controller.selection,
        const TextSelection(baseOffset: 8, extentOffset: 12),
      );
      expect(find.byType(CupertinoButton), findsNWidgets(3));
    },
  );

  testWidgets('force press does not select a word on (android)', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: controller,
          ),
        ),
      ),
    );

    final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

    const int pointerValue = 1;
    final TestGesture gesture =
    await tester.startGesture(textfieldStart + const Offset(150.0, 5.0));
    await gesture.updateWithCustomEvent(PointerMoveEvent(pointer: pointerValue, position: textfieldStart + const Offset(150.0, 5.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));

    // We don't want this gesture to select any word on Android.
    expect(controller.selection, const TextSelection.collapsed(offset: -1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(FlatButton), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('force press selects word (iOS)', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            controller: controller,
          ),
        ),
      ),
    );

    final Offset textfieldStart = tester.getTopLeft(find.byType(CupertinoTextField));

    const int pointerValue = 1;
    final TestGesture gesture =
    await tester.startGesture(textfieldStart + const Offset(150.0, 5.0));
    await gesture.updateWithCustomEvent(PointerMoveEvent(pointer: pointerValue, position: textfieldStart + const Offset(150.0, 5.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));
    // We expect the force press to select a word at the given location.
    expect(
      controller.selection,
      const TextSelection(baseOffset: 8, extentOffset: 12),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoButton), findsNWidgets(3));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('default TextField debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    const TextField().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[]);
  });

  testWidgets('TextField implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();

    // Not checking controller, inputFormatters, focusNode
    const TextField(
      decoration: InputDecoration(labelText: 'foo'),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.none,
      style: TextStyle(color: Color(0xff00ff00)),
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr,
      autofocus: true,
      obscureText: true,
      autocorrect: false,
      maxLines: 10,
      maxLength: 100,
      maxLengthEnforced: false,
      enabled: false,
      cursorWidth: 1.0,
      cursorRadius: Radius.zero,
      cursorColor: Color(0xff00ff00),
      keyboardAppearance: Brightness.dark,
      scrollPadding: EdgeInsets.zero,
      enableInteractiveSelection: false,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString()).toList();

    expect(description, <String>[
      'enabled: false',
      'decoration: InputDecoration(labelText: "foo")',
      'style: TextStyle(inherit: true, color: Color(0xff00ff00))',
      'autofocus: true',
      'obscureText: true',
      'autocorrect: false',
      'maxLines: 10',
      'maxLength: 100',
      'maxLength not enforced',
      'textInputAction: done',
      'textAlign: end',
      'textDirection: ltr',
      'cursorWidth: 1.0',
      'cursorRadius: Radius.circular(0.0)',
      'cursorColor: Color(0xff00ff00)',
      'keyboardAppearance: Brightness.dark',
      'scrollPadding: EdgeInsets.zero',
      'selection disabled'
    ]);
  });
}

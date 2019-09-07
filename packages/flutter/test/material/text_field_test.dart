// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome') // This whole test suite needs triage.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show window;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior, PointerDeviceKind;

import '../rendering/mock_canvas.dart';
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
  final OverlayEntry entry = OverlayEntry(
    builder: (BuildContext context) {
      return Center(
        child: Material(
          child: child,
        ),
      );
    },
  );
  return overlayWithEntry(entry);
}

Widget overlayWithEntry(OverlayEntry entry) {
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
            entry
          ],
        ),
      ),
    ),
  );
}

Widget boilerplate({ Widget child }) {
  return MaterialApp(
    home: Localizations(
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
  TestWidgetsFlutterBinding.ensureInitialized();
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

  final Key textFieldKey = UniqueKey();
  Widget textFieldBuilder({
    int maxLines = 1,
    int minLines,
  }) {
    return boilerplate(
      child: TextField(
        key: textFieldKey,
        style: const TextStyle(color: Colors.black, fontSize: 34.0),
        maxLines: maxLines,
        minLines: minLines,
        decoration: const InputDecoration(
          hintText: 'Placeholder',
        ),
      ),
    );
  }

  testWidgets('TextField passes onEditingComplete to EditableText', (WidgetTester tester) async {
    final VoidCallback onEditingComplete = () { };

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
          },
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

  testWidgets('Material cursor android golden', (WidgetTester tester) async {
    final Widget widget = overlay(
      child: const RepaintBoundary(
        key: ValueKey<int>(1),
        child: TextField(
          cursorColor: Colors.blue,
          cursorWidth: 15,
          cursorRadius: Radius.circular(3.0),
        ),
      ),
    );
    await tester.pumpWidget(widget);

    const String testValue = 'A short phrase';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    await tester.tapAt(textOffsetToPosition(tester, testValue.length));
    await tester.pump();

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile(
        'text_field_cursor_test.material.0.png',
        version: 0,
      ),
    );
  });

  testWidgets('Material cursor iOS golden', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Widget widget = overlay(
      child: const RepaintBoundary(
        key: ValueKey<int>(1),
        child: TextField(
          cursorColor: Colors.blue,
          cursorWidth: 15,
          cursorRadius: Radius.circular(3.0),
        ),
      ),
    );
    await tester.pumpWidget(widget);

    const String testValue = 'A short phrase';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    await tester.tapAt(textOffsetToPosition(tester, testValue.length));
    await tester.pump();

    debugDefaultTargetPlatformOverride = null;
    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile(
        'text_field_cursor_test.material.1.png',
        version: 0,
      ),
    );
  });

  testWidgets('text field selection toolbar renders correctly inside opacity', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Container(
              width: 100,
              height: 100,
              child: const Opacity(
                opacity: 0.5,
                child: TextField(
                  decoration: InputDecoration(hintText: 'Placeholder'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));

    const String testValue = 'A B C';
    tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: testValue
        )
    );
    await tester.pump();

    // The selectWordsInRange with SelectionChangedCause.tap seems to be needed to show the toolbar.
    // (This is true even if we provide selection parameter to the TextEditingValue above.)
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    state.renderEditable.selectWordsInRange(from: const Offset(0, 0), cause: SelectionChangedCause.tap);

    expect(state.showToolbar(), true);

    // This is needed for the AnimatedOpacity to turn from 0 to 1 so the toolbar is visible.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // Sanity check that the toolbar widget exists.
    expect(find.text('PASTE'), findsOneWidget);

    await expectLater(
      // The toolbar exists in the Overlay above the MaterialApp.
      find.byType(Overlay),
      matchesGoldenFile(
        'text_field_opacity_test.0.png',
        version: 3,
      ),
    );
  }, skip: isBrowser);

  // TODO(hansmuller): restore these tests after the fix for #24876 has landed.
  /*
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
  */

  testWidgets('Overflowing a line with spaces stops the cursor at the end', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          key: textFieldKey,
          controller: controller,
          maxLines: null,
        ),
      )
    );
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);

    const String testValueOneLine = 'enough text to be exactly at the end of the line.';
    await tester.enterText(find.byType(TextField), testValueOneLine);
    await skipPastScrollingAnimation(tester);

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

    RenderBox inputBox = findInputBox();
    final Size oneLineInputSize = inputBox.size;

    await tester.tapAt(textOffsetToPosition(tester, testValueOneLine.length));
    await tester.pump();

    const String testValueTwoLines = 'enough text to overflow the first line and go to the second';
    await tester.enterText(find.byType(TextField), testValueTwoLines);
    await skipPastScrollingAnimation(tester);

    expect(inputBox, findInputBox());
    inputBox = findInputBox();
    expect(inputBox.size.height, greaterThan(oneLineInputSize.height));
    final Size twoLineInputSize = inputBox.size;

    // Enter a string with the same number of characters as testValueTwoLines,
    // but where the overflowing part is all spaces. Assert that it only renders
    // on one line.
    const String testValueSpaces = testValueOneLine + '          ';
    expect(testValueSpaces.length, testValueTwoLines.length);
    await tester.enterText(find.byType(TextField), testValueSpaces);
    await skipPastScrollingAnimation(tester);

    expect(inputBox, findInputBox());
    inputBox = findInputBox();
    expect(inputBox.size.height, oneLineInputSize.height);

    // Swapping the final space for a letter causes it to wrap to 2 lines.
    const String testValueSpacesOverflow = testValueOneLine + '         a';
    expect(testValueSpacesOverflow.length, testValueTwoLines.length);
    await tester.enterText(find.byType(TextField), testValueSpacesOverflow);
    await skipPastScrollingAnimation(tester);

    expect(inputBox, findInputBox());
    inputBox = findInputBox();
    expect(inputBox.size.height, twoLineInputSize.height);

    // Positioning the cursor at the end of a line overflowing with spaces puts
    // it inside the input still.
    await tester.enterText(find.byType(TextField), testValueSpaces);
    await skipPastScrollingAnimation(tester);
    await tester.tapAt(textOffsetToPosition(tester, testValueSpaces.length));
    await tester.pump();

    final double inputWidth = findRenderEditable(tester).size.width;
    final Offset cursorOffsetSpaces = findRenderEditable(tester).getLocalRectForCaret(
      const TextPosition(offset: testValueSpaces.length),
    ).bottomRight;

    // Gap between caret and edge of input, defined in editable.dart.
    const int _kCaretGap = 1;

    expect(cursorOffsetSpaces.dx, inputWidth - _kCaretGap);
  });

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
    await tester.longPressAt(ePos, pointer: 7);
    await tester.pump();

    // 'def' is selected.
    expect(controller.selection.baseOffset, testValue.indexOf('d'));
    expect(controller.selection.extentOffset, testValue.indexOf('f')+1);

    // Tapping elsewhere immediately collapses and moves the cursor.
    await tester.tapAt(textOffsetToPosition(tester, testValue.indexOf('h')));
    await tester.pump();

    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, testValue.indexOf('h'));
  });

  testWidgets('Slight movements in longpress don\'t hide/show handles', (WidgetTester tester) async {
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

    // Long press the 'e' to select 'def', but don't release the gesture.
    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    final TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Handles are shown
    final Finder fadeFinder = find.byType(FadeTransition);
    expect(fadeFinder, findsNWidgets(2)); // 2 handles, 1 toolbar
    FadeTransition handle = tester.widget(fadeFinder.at(0));
    expect(handle.opacity.value, equals(1.0));

    // Move the gesture very slightly
    await gesture.moveBy(const Offset(1.0, 1.0));
    await tester.pump(TextSelectionOverlay.fadeDuration * 0.5);
    handle = tester.widget(fadeFinder.at(0));

    // The handle should still be fully opaque.
    expect(handle.opacity.value, equals(1.0));
  });

  testWidgets('Entering text hides selection handle caret', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          controller: controller,
        ),
      )
    );

    const String testValue = 'abcdefghi';
    await tester.enterText(find.byType(TextField), testValue);
    expect(controller.value.text, testValue);
    await skipPastScrollingAnimation(tester);

    // Handle not shown.
    expect(controller.selection.isCollapsed, true);
    final Finder fadeFinder = find.byType(FadeTransition);
    expect(fadeFinder, findsNothing);

    // Tap on the text field to show the handle.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(controller.selection.isCollapsed, true);
    expect(fadeFinder, findsNWidgets(1));
    final FadeTransition handle = tester.widget(fadeFinder.at(0));
    expect(handle.opacity.value, equals(1.0));

    // Enter more text.
    const String testValueAddition = 'jklmni';
    await tester.enterText(find.byType(TextField), testValueAddition);
    expect(controller.value.text, testValueAddition);
    await skipPastScrollingAnimation(tester);

    // Handle not shown.
    expect(controller.selection.isCollapsed, true);
    expect(fadeFinder, findsNothing);
  });

  testWidgets('Mouse long press is just like a tap', (WidgetTester tester) async {
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

    // Long press the 'e' using a mouse device.
    final int eIndex = testValue.indexOf('e');
    final Offset ePos = textOffsetToPosition(tester, eIndex);
    final TestGesture gesture = await tester.startGesture(ePos, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    // The cursor is placed just like a regular tap.
    expect(controller.selection.baseOffset, eIndex);
    expect(controller.selection.extentOffset, eIndex);
  });

  testWidgets('Read only text field basic', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'readonly');

    await tester.pumpWidget(
        overlay(
          child: TextField(
            controller: controller,
            readOnly: true,
          ),
        )
    );
    // Read only text field cannot open keyboard.
    await tester.showKeyboard(find.byType(TextField));
    expect(tester.testTextInput.hasAnyClients, false);
    await skipPastScrollingAnimation(tester);

    expect(controller.selection.isCollapsed, true);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);
    final EditableTextState editableText = tester.state(find.byType(EditableText));
    // Collapse selection should not paint.
    expect(editableText.selectionOverlay.handlesAreVisible, isFalse);
    // Long press on the 'd' character of text 'readOnly' to show context menu.
    const int dIndex = 3;
    final Offset dPos = textOffsetToPosition(tester, dIndex);
    await tester.longPressAt(dPos);
    await tester.pump();

    // Context menu should not have paste and cut.
    expect(find.text('COPY'), findsOneWidget);
    expect(find.text('PASTE'), findsNothing);
    expect(find.text('CUT'), findsNothing);
  });

  testWidgets('does not paint toolbar when no options available on ios', (WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const Material(
            child: TextField(
              readOnly: true,
            ),
          ),
        )
    );

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(TextField));
    // Wait for context menu to be built.
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoTextSelectionToolbar), paintsNothing);
  });

  testWidgets('text field build empty toolbar when no options available android', (WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: TextField(
              readOnly: true,
            ),
          ),
        )
    );

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(TextField));
    // Wait for context menu to be built.
    await tester.pumpAndSettle();
    final RenderBox container = tester.renderObject(find.descendant(
      of: find.byType(FadeTransition),
      matching: find.byType(Container),
    ));
    expect(container.size, Size.zero);
  });

  testWidgets('Sawping controllers should update selection', (WidgetTester tester) async {
    TextEditingController controller = TextEditingController(text: 'readonly');
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: TextField(
              controller: controller,
              readOnly: true,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    const int dIndex = 3;
    final Offset dPos = textOffsetToPosition(tester, dIndex);
    await tester.longPressAt(dPos);
    await tester.pumpAndSettle();
    final EditableTextState state = tester.state(find.byType(EditableText));
    TextSelection currentOverlaySelection =
        state.selectionOverlay.value.selection;
    expect(currentOverlaySelection.baseOffset, 0);
    expect(currentOverlaySelection.extentOffset, 8);

    // Update selection from [0 to 8] to [1 to 7].
    controller = TextEditingController.fromValue(
      controller.value.copyWith(selection: const TextSelection(
          baseOffset: 1, extentOffset: 7
      ))
    );

    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();

    await tester.pump();
    currentOverlaySelection = state.selectionOverlay.value.selection;
    expect(currentOverlaySelection.baseOffset, 1);
    expect(currentOverlaySelection.extentOffset, 7);
  });

  testWidgets('Read only text should not compose', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController.fromValue(
        const TextEditingValue(
            text: 'readonly',
            composing: TextRange(start: 0, end: 8) // Simulate text composing.
        )
    );

    await tester.pumpWidget(
        overlay(
          child: TextField(
            controller: controller,
            readOnly: true,
          ),
        )
    );

    final RenderEditable renderEditable = findRenderEditable(tester);
    // There should be no composing.
    expect(renderEditable.text, TextSpan(text:'readonly', style: renderEditable.text.style));
  });

  testWidgets('Dynamically switching between read only and not read only should hide or show collapse cursor', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'readonly');
    bool readOnly = true;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableText = tester.state(find.byType(EditableText));
    // Collapse selection should not paint.
    expect(editableText.selectionOverlay.handlesAreVisible, isFalse);

    readOnly = false;
    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();
    await tester.pumpAndSettle();
    expect(editableText.selectionOverlay.handlesAreVisible, isTrue);

    readOnly = true;
    entry.markNeedsBuild();
    await tester.pumpAndSettle();
    expect(editableText.selectionOverlay.handlesAreVisible, isFalse);
  });

  testWidgets('Dynamically switching to read only should close input connection', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'readonly');
    bool readOnly = false;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, true);

    readOnly = true;
    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);
  });

  testWidgets('Dynamically switching to non read only should open input connection', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'readonly');
    bool readOnly = true;
    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Center(
          child: Material(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
    await tester.pumpWidget(overlayWithEntry(entry));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, false);

    readOnly = false;
    // Mark entry to be dirty in order to trigger overlay update.
    entry.markNeedsBuild();
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, true);
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
    await tester.longPressAt(ePos, pointer: 7);
    await tester.pump();

    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, -1);
    expect(controller.selection.extentOffset, -1);
  });

  testWidgets('Can select text by dragging with a mouse', (WidgetTester tester) async {
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

    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    final Offset gPos = textOffsetToPosition(tester, testValue.indexOf('g'));

    final TestGesture gesture = await tester.startGesture(ePos, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(gPos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, testValue.indexOf('e'));
    expect(controller.selection.extentOffset, testValue.indexOf('g'));
  });

  testWidgets('Continuous dragging does not cause flickering', (WidgetTester tester) async {
    int selectionChangedCount = 0;
    const String testValue = 'abc def ghi';
    final TextEditingController controller = TextEditingController(text: testValue);

    controller.addListener(() {
      selectionChangedCount++;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            dragStartBehavior: DragStartBehavior.down,
            controller: controller,
            style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
          ),
        ),
      ),
    );

    final Offset cPos = textOffsetToPosition(tester, 2); // Index of 'c'.
    final Offset gPos = textOffsetToPosition(tester, 8); // Index of 'g'.
    final Offset hPos = textOffsetToPosition(tester, 9); // Index of 'h'.

    // Drag from 'c' to 'g'.
    final TestGesture gesture = await tester.startGesture(cPos, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(gPos);
    await tester.pumpAndSettle();

    expect(selectionChangedCount, isNonZero);
    selectionChangedCount = 0;
    expect(controller.selection.baseOffset, 2);
    expect(controller.selection.extentOffset, 8);

    // Tiny movement shouldn't cause text selection to change.
    await gesture.moveTo(gPos + const Offset(4.0, 0.0));
    await tester.pumpAndSettle();
    expect(selectionChangedCount, 0);

    // Now a text selection change will occur after a significant movement.
    await gesture.moveTo(hPos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectionChangedCount, 1);
    expect(controller.selection.baseOffset, 2);
    expect(controller.selection.extentOffset, 9);
  });

  testWidgets('Dragging in opposite direction also works', (WidgetTester tester) async {
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

    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    final Offset gPos = textOffsetToPosition(tester, testValue.indexOf('g'));

    final TestGesture gesture = await tester.startGesture(gPos, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(ePos);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, testValue.indexOf('e'));
    expect(controller.selection.extentOffset, testValue.indexOf('g'));
  });

  testWidgets('Slow mouse dragging also selects text', (WidgetTester tester) async {
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

    final Offset ePos = textOffsetToPosition(tester, testValue.indexOf('e'));
    final Offset gPos = textOffsetToPosition(tester, testValue.indexOf('g'));

    final TestGesture gesture = await tester.startGesture(ePos, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(seconds: 2));
    await gesture.moveTo(gPos);
    await tester.pump();
    await gesture.up();

    expect(controller.selection.baseOffset, testValue.indexOf('e'));
    expect(controller.selection.extentOffset, testValue.indexOf('g'));
  });

  testWidgets('Can drag handles to change selection', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          dragStartBehavior: DragStartBehavior.down,
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
    expect(selection.baseOffset, 4);
    expect(selection.extentOffset, 7);

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
    Offset newHandlePos = textOffsetToPosition(tester, testValue.length);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 11);

    // Drag the left handle 2 letters to the left.
    handlePos = endpoints[0].point + const Offset(-1.0, 1.0);
    newHandlePos = textOffsetToPosition(tester, 0);
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, 11);
  });

  testWidgets('Cannot drag one handle past the other', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      overlay(
        child: TextField(
          dragStartBehavior: DragStartBehavior.down,
          controller: controller,
        ),
      ),
    );

    const String testValue = 'abc def ghi';
    await tester.enterText(find.byType(TextField), testValue);
    await skipPastScrollingAnimation(tester);

    // Long press the 'e' to select 'def'.
    final Offset ePos = textOffsetToPosition(tester, 5); // Position before 'e'.
    TestGesture gesture = await tester.startGesture(ePos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero

    final TextSelection selection = controller.selection;
    expect(selection.baseOffset, 4);
    expect(selection.extentOffset, 7);

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(selection),
      renderEditable,
    );
    expect(endpoints.length, 2);

    // Drag the right handle until there's only 1 char selected.
    // We use a small offset because the endpoint is on the very corner
    // of the handle.
    final Offset handlePos = endpoints[1].point + const Offset(4.0, 0.0);
    Offset newHandlePos = textOffsetToPosition(tester, 5); // Position before 'e'.
    gesture = await tester.startGesture(handlePos, pointer: 7);
    await tester.pump();
    await gesture.moveTo(newHandlePos);
    await tester.pump();

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 5);

    newHandlePos = textOffsetToPosition(tester, 2); // Position before 'c'.
    await gesture.moveTo(newHandlePos);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.selection.baseOffset, 4);
    // The selection doesn't move beyond the left handle. There's always at
    // least 1 char selected.
    expect(controller.selection.extentOffset, 5);
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
    // Tapping on the part of the handle's GestureDetector where it overlaps
    // with the text itself does not show the menu, so add a small vertical
    // offset to tap below the text.
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 13.0));
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
    // Allow time for handle to appear and double tap to time out.
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, testValue.indexOf('e'));
    expect(controller.selection.extentOffset, testValue.indexOf('e'));
    renderEditable = findRenderEditable(tester);
    endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, testValue.indexOf('e'));
    expect(controller.selection.extentOffset, testValue.indexOf('e'));

    // PASTE right before the 'e'.
    await tester.tap(find.text('PASTE'));
    await tester.pump();
    expect(controller.text, 'abc d${testValue}ef ghi');
  });

  // Show the selection menu at the given index into the text by tapping to
  // place the cursor and then tapping on the handle.
  Future<void> _showSelectionMenuAt(WidgetTester tester, TextEditingController controller, int index) async {
    await tester.tapAt(tester.getCenter(find.byType(EditableText)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
    expect(find.text('SELECT ALL'), findsNothing);

    // Tap the selection handle to bring up the "paste / select all" menu for
    // the last line of text.
    await tester.tapAt(textOffsetToPosition(tester, index));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    // Tapping on the part of the handle's GestureDetector where it overlaps
    // with the text itself does not show the menu, so add a small vertical
    // offset to tap below the text.
    await tester.tapAt(endpoints[0].point + const Offset(1.0, 13.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // skip past the frame where the opacity is zero
  }

  testWidgets(
    'Check the toolbar appears below the TextField when there is not enough space above the TextField to show it',
    (WidgetTester tester) async {
      // This is a regression test for
      // https://github.com/flutter/flutter/issues/29808
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(30.0),
            child: TextField(
              controller: controller,
              ),
            ),
          ),
        ),
      );

      const String testValue = 'abc def ghi';
      await tester.enterText(find.byType(TextField), testValue);
      await skipPastScrollingAnimation(tester);

      await _showSelectionMenuAt(tester, controller, testValue.indexOf('e'));

      // Verify the selection toolbar position is below the text.
      Offset toolbarTopLeft = tester.getTopLeft(find.text('SELECT ALL'));
      Offset textFieldTopLeft = tester.getTopLeft(find.byType(TextField));
      expect(textFieldTopLeft.dy, lessThan(toolbarTopLeft.dy));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(150.0),
            child: TextField(
              controller: controller,
            ),
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), testValue);
      await skipPastScrollingAnimation(tester);

      await _showSelectionMenuAt(tester, controller, testValue.indexOf('e'));

      // Verify the selection toolbar position
      toolbarTopLeft = tester.getTopLeft(find.text('SELECT ALL'));
      textFieldTopLeft = tester.getTopLeft(find.byType(TextField));
      expect(toolbarTopLeft.dy, lessThan(textFieldTopLeft.dy));
    },
  );

  testWidgets(
    'Toolbar appears in the right places in multiline inputs',
    (WidgetTester tester) async {
      // This is a regression test for
      // https://github.com/flutter/flutter/issues/36749
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(30.0),
            child: TextField(
              controller: controller,
              minLines: 6,
              maxLines: 6,
            ),
          ),
        ),
      ));

      expect(find.text('SELECT ALL'), findsNothing);
      const String testValue = 'abc\ndef\nghi\njkl\nmno\npqr';
      await tester.enterText(find.byType(TextField), testValue);
      await skipPastScrollingAnimation(tester);

      // Show the selection menu on the first line and verify the selection
      // toolbar position is below the first line.
      await _showSelectionMenuAt(tester, controller, testValue.indexOf('c'));
      expect(find.text('SELECT ALL'), findsOneWidget);
      final Offset firstLineToolbarTopLeft = tester.getTopLeft(find.text('SELECT ALL'));
      final Offset firstLineTopLeft = textOffsetToPosition(tester, testValue.indexOf('a'));
      expect(firstLineTopLeft.dy, lessThan(firstLineToolbarTopLeft.dy));

      // Show the selection menu on the second to last line and verify the
      // selection toolbar position is above that line and above the first
      // line's toolbar.
      await _showSelectionMenuAt(tester, controller, testValue.indexOf('o'));
      expect(find.text('SELECT ALL'), findsOneWidget);
      final Offset penultimateLineToolbarTopLeft = tester.getTopLeft(find.text('SELECT ALL'));
      final Offset penultimateLineTopLeft = textOffsetToPosition(tester, testValue.indexOf('p'));
      expect(penultimateLineToolbarTopLeft.dy, lessThan(penultimateLineTopLeft.dy));
      expect(penultimateLineToolbarTopLeft.dy, lessThan(firstLineToolbarTopLeft.dy));

      // Show the selection menu on the last line and verify the selection
      // toolbar position is above that line and below the position of the
      // second to last line's toolbar.
      await _showSelectionMenuAt(tester, controller, testValue.indexOf('r'));
      expect(find.text('SELECT ALL'), findsOneWidget);
      final Offset lastLineToolbarTopLeft = tester.getTopLeft(find.text('SELECT ALL'));
      final Offset lastLineTopLeft = textOffsetToPosition(tester, testValue.indexOf('p'));
      expect(lastLineToolbarTopLeft.dy, lessThan(lastLineTopLeft.dy));
      expect(lastLineToolbarTopLeft.dy, greaterThan(penultimateLineToolbarTopLeft.dy));
    },
  );

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
    // Allow time for the handle to appear and for a double tap to time out.
    await tester.pump(const Duration(milliseconds: 600));
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

  testWidgets('An obscured TextField is selectable by default', (WidgetTester tester) async {
    // This is a regression test for
    // https://github.com/flutter/flutter/issues/32845

    final TextEditingController controller = TextEditingController();
    Widget buildFrame(bool obscureText) {
      return overlay(
        child: TextField(
          controller: controller,
          obscureText: obscureText,
        ),
      );
    }

    // Obscure text and don't enable or disable selection.
    await tester.pumpWidget(buildFrame(true));
    await tester.enterText(find.byType(TextField), 'abcdefghi');
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.isCollapsed, true);

    // Long press does select text.
    final Offset ePos = textOffsetToPosition(tester, 1);
    await tester.longPressAt(ePos, pointer: 7);
    await tester.pump();
    expect(controller.selection.isCollapsed, false);
  });

  testWidgets('An obscured TextField is not selectable when disabled', (WidgetTester tester) async {
    // This is a regression test for
    // https://github.com/flutter/flutter/issues/32845

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

    // Explicitly disabled selection on obscured text.
    await tester.pumpWidget(buildFrame(true, false));
    await tester.enterText(find.byType(TextField), 'abcdefghi');
    await skipPastScrollingAnimation(tester);
    expect(controller.selection.isCollapsed, true);

    // Long press doesn't select text.
    final Offset ePos2 = textOffsetToPosition(tester, 1);
    await tester.longPressAt(ePos2, pointer: 7);
    await tester.pump();
    expect(controller.selection.isCollapsed, true);
  });

  testWidgets('An obscured TextField is selected as one word', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(overlay(
      child: TextField(
        controller: controller,
        obscureText: true,
      ),
    ));
    await tester.enterText(find.byType(TextField), 'abcde fghi');
    await skipPastScrollingAnimation(tester);

    // Long press does select text.
    final Offset bPos = textOffsetToPosition(tester, 1);
    await tester.longPressAt(bPos, pointer: 7);
    await tester.pump();
    final TextSelection selection = controller.selection;
    expect(selection.isCollapsed, false);
    expect(selection.baseOffset, 0);
    expect(selection.extentOffset, 10);
  });

  testWidgets('An obscured TextField has correct default context menu', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(overlay(
      child: TextField(
        controller: controller,
        obscureText: true,
      ),
    ));
    await tester.enterText(find.byType(TextField), 'abcde fghi');
    await skipPastScrollingAnimation(tester);

    // Long press to select text.
    final Offset bPos = textOffsetToPosition(tester, 1);
    await tester.longPressAt(bPos, pointer: 7);
    await tester.pump();

    // Should only have paste option when whole obscure text is selected.
    expect(find.text('PASTE'), findsOneWidget);
    expect(find.text('COPY'), findsNothing);
    expect(find.text('CUT'), findsNothing);
    expect(find.text('SELECT ALL'), findsNothing);

    // Long press at the end
    final Offset iPos = textOffsetToPosition(tester, 10);
    final Offset slightRight = iPos + const Offset(30.0, 0.0);
    await tester.longPressAt(slightRight, pointer: 7);
    await tester.pump();

    // Should have paste and select all options when collapse.
    expect(find.text('PASTE'), findsOneWidget);
    expect(find.text('SELECT ALL'), findsOneWidget);
    expect(find.text('COPY'), findsNothing);
    expect(find.text('CUT'), findsNothing);
  });

  testWidgets('TextField height with minLines unset', (WidgetTester tester) async {
    await tester.pumpWidget(textFieldBuilder());

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

    final RenderBox inputBox = findInputBox();
    final Size emptyInputSize = inputBox.size;

    await tester.enterText(find.byType(TextField), 'No wrapping here.');
    await tester.pumpWidget(textFieldBuilder());
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    // Even when entering multiline text, TextField doesn't grow. It's a single
    // line input.
    await tester.enterText(find.byType(TextField), kThreeLines);
    await tester.pumpWidget(textFieldBuilder());
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    // maxLines: 3 makes the TextField 3 lines tall
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpWidget(textFieldBuilder(maxLines: 3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size.height, greaterThan(emptyInputSize.height));
    expect(inputBox.size.width, emptyInputSize.width);

    final Size threeLineInputSize = inputBox.size;

    // Filling with 3 lines of text stays the same size
    await tester.enterText(find.byType(TextField), kThreeLines);
    await tester.pumpWidget(textFieldBuilder(maxLines: 3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);

    // An extra line won't increase the size because we max at 3.
    await tester.enterText(find.byType(TextField), kMoreThanFourLines);
    await tester.pumpWidget(textFieldBuilder(maxLines: 3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);

    // But now it will... but it will max at four
    await tester.enterText(find.byType(TextField), kMoreThanFourLines);
    await tester.pumpWidget(textFieldBuilder(maxLines: 4));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size.height, greaterThan(threeLineInputSize.height));
    expect(inputBox.size.width, threeLineInputSize.width);

    final Size fourLineInputSize = inputBox.size;

    // Now it won't max out until the end
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpWidget(textFieldBuilder(maxLines: null));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));
    await tester.enterText(find.byType(TextField), kThreeLines);
    await tester.pump();
    expect(inputBox.size, equals(threeLineInputSize));
    await tester.enterText(find.byType(TextField), kMoreThanFourLines);
    await tester.pump();
    expect(inputBox.size.height, greaterThan(fourLineInputSize.height));
    expect(inputBox.size.width, fourLineInputSize.width);
  });

  testWidgets('TextField height with minLines and maxLines', (WidgetTester tester) async {
    await tester.pumpWidget(textFieldBuilder());

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));

    final RenderBox inputBox = findInputBox();
    final Size emptyInputSize = inputBox.size;

    await tester.enterText(find.byType(TextField), 'No wrapping here.');
    await tester.pumpWidget(textFieldBuilder());
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(emptyInputSize));

    // min and max set to same value locks height to value.
    await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: 3));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size.height, greaterThan(emptyInputSize.height));
    expect(inputBox.size.width, emptyInputSize.width);

    final Size threeLineInputSize = inputBox.size;

    // maxLines: null with minLines set grows beyond minLines
    await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: null));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, threeLineInputSize);
    await tester.enterText(find.byType(TextField), kMoreThanFourLines);
    await tester.pump();
    expect(inputBox.size.height, greaterThan(threeLineInputSize.height));
    expect(inputBox.size.width, threeLineInputSize.width);

    // With minLines and maxLines set, input will expand through the range
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: 4));
    expect(findInputBox(), equals(inputBox));
    expect(inputBox.size, equals(threeLineInputSize));
    await tester.enterText(find.byType(TextField), kMoreThanFourLines);
    await tester.pump();
    expect(inputBox.size.height, greaterThan(threeLineInputSize.height));
    expect(inputBox.size.width, threeLineInputSize.width);

    // minLines can't be greater than maxLines.
    expect(() async {
      await tester.pumpWidget(textFieldBuilder(minLines: 3, maxLines: 2));
    }, throwsAssertionError);
    expect(() async {
      await tester.pumpWidget(textFieldBuilder(minLines: 3));
    }, throwsAssertionError);

    // maxLines defaults to 1 and can't be less than minLines
    expect(() async {
      await tester.pumpWidget(textFieldBuilder(minLines: 3));
    }, throwsAssertionError);
  });

  testWidgets('Multiline text when wrapped in Expanded', (WidgetTester tester) async {
    Widget expandedTextFieldBuilder({
      int maxLines = 1,
      int minLines,
      bool expands = false,
    }) {
      return boilerplate(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: TextField(
                key: textFieldKey,
                style: const TextStyle(color: Colors.black, fontSize: 34.0),
                maxLines: maxLines,
                minLines: minLines,
                expands: expands,
                decoration: const InputDecoration(
                  hintText: 'Placeholder',
                ),
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(expandedTextFieldBuilder());

    RenderBox findBorder() {
      return tester.renderObject(find.descendant(
        of: find.byType(InputDecorator),
        matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_BorderContainer'),
      ));
    }
    final RenderBox border = findBorder();

    // Without expanded: true and maxLines: null, the TextField does not expand
    // to fill its parent when wrapped in an Expanded widget.
    final Size unexpandedInputSize = border.size;

    // It does expand to fill its parent when expands: true, maxLines: null, and
    // it's wrapped in an Expanded widget.
    await tester.pumpWidget(expandedTextFieldBuilder(expands: true, maxLines: null));
    expect(border.size.height, greaterThan(unexpandedInputSize.height));
    expect(border.size.width, unexpandedInputSize.width);

    // min/maxLines that is not null and expands: true contradict each other.
    expect(() async {
      await tester.pumpWidget(expandedTextFieldBuilder(expands: true, maxLines: 4));
    }, throwsAssertionError);
    expect(() async {
      await tester.pumpWidget(expandedTextFieldBuilder(expands: true, minLines: 1, maxLines: null));
    }, throwsAssertionError);
  });

  // Regression test for https://github.com/flutter/flutter/pull/29093
  testWidgets('Multiline text when wrapped in IntrinsicHeight', (WidgetTester tester) async {
    final Key intrinsicHeightKey = UniqueKey();
    Widget intrinsicTextFieldBuilder(bool wrapInIntrinsic) {
      final TextFormField textField = TextFormField(
        key: textFieldKey,
        style: const TextStyle(color: Colors.black, fontSize: 34.0),
        maxLines: null,
        decoration: const InputDecoration(
          counterText: 'I am counter',
        ),
      );
      final Widget widget = wrapInIntrinsic
        ? IntrinsicHeight(key: intrinsicHeightKey, child: textField)
        : textField;
      return boilerplate(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[widget],
        ),
      );
    }

    await tester.pumpWidget(intrinsicTextFieldBuilder(false));
    expect(find.byKey(intrinsicHeightKey), findsNothing);

    RenderBox findEditableText() => tester.renderObject(find.byType(EditableText));
    RenderBox editableText = findEditableText();
    final Size unwrappedEditableTextSize = editableText.size;

    // Wrapping in IntrinsicHeight should not affect the height of the input
    await tester.pumpWidget(intrinsicTextFieldBuilder(true));
    editableText = findEditableText();
    expect(editableText.size.height, unwrappedEditableTextSize.height);
    expect(editableText.size.width, unwrappedEditableTextSize.width);
  });

  // Regression test for https://github.com/flutter/flutter/pull/29093
  testWidgets('errorText empty string', (WidgetTester tester) async {
    Widget textFormFieldBuilder(String errorText) {
      return boilerplate(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              key: textFieldKey,
              maxLength: 3,
              maxLengthEnforced: false,
              decoration: InputDecoration(
                counterText: '',
                errorText: errorText,
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(textFormFieldBuilder(null));

    RenderBox findInputBox() => tester.renderObject(find.byKey(textFieldKey));
    final RenderBox inputBox = findInputBox();
    final Size errorNullInputSize = inputBox.size;

    // Setting errorText causes the input's height to increase to accommodate it
    await tester.pumpWidget(textFormFieldBuilder('im errorText'));
    expect(inputBox, findInputBox());
    expect(inputBox.size.height, greaterThan(errorNullInputSize.height));
    expect(inputBox.size.width, errorNullInputSize.width);
    final Size errorInputSize = inputBox.size;

    // Setting errorText to an empty string causes the input's height to
    // increase to accommodate it, even though it's not displayed.
    // This may or may not be ideal behavior, but it is legacy behavior and
    // there are visual tests that rely on it (see Github issue referenced at
    // the top of this test). A counterText of empty string does not affect
    // input height, however.
    await tester.pumpWidget(textFormFieldBuilder(''));
    expect(inputBox, findInputBox());
    expect(inputBox.size.height, errorInputSize.height);
    expect(inputBox.size.width, errorNullInputSize.width);
  });

  testWidgets('Growable TextField when content height exceeds parent', (WidgetTester tester) async {
    const double height = 200.0;
    const double padding = 24.0;

    Widget containedTextFieldBuilder({
      Widget counter,
      String helperText,
      String labelText,
      Widget prefix,
    }) {
      return boilerplate(
        child: Container(
          height: height,
          child: TextField(
            key: textFieldKey,
            maxLines: null,
            decoration: InputDecoration(
              counter: counter,
              helperText: helperText,
              labelText: labelText,
              prefix: prefix,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(containedTextFieldBuilder());
    RenderBox findEditableText() => tester.renderObject(find.byType(EditableText));

    final RenderBox inputBox = findEditableText();

    // With no decoration and when overflowing with content, the EditableText
    // takes up the full height minus the padding, so the input fits perfectly
    // inside the parent.
    await tester.enterText(find.byType(TextField), 'a\n' * 11);
    await tester.pump();
    expect(findEditableText(), equals(inputBox));
    expect(inputBox.size.height, height - padding);

    // Adding a counter causes the EditableText to shrink to fit the counter
    // inside the parent as well.
    const double counterHeight = 40.0;
    const double subtextGap = 8.0;
    const double counterSpace = counterHeight + subtextGap;
    await tester.pumpWidget(containedTextFieldBuilder(
      counter: Container(height: counterHeight),
    ));
    expect(findEditableText(), equals(inputBox));
    expect(inputBox.size.height, height - padding - counterSpace);

    // Including helperText causes the EditableText to shrink to fit the text
    // inside the parent as well.
    await tester.pumpWidget(containedTextFieldBuilder(
      helperText: 'I am helperText',
    ));
    expect(findEditableText(), equals(inputBox));
    const double helperTextSpace = 12.0;
    expect(inputBox.size.height, height - padding - helperTextSpace - subtextGap);

    // When both helperText and counter are present, EditableText shrinks by the
    // height of the taller of the two in order to fit both within the parent.
    await tester.pumpWidget(containedTextFieldBuilder(
      counter: Container(height: counterHeight),
      helperText: 'I am helperText',
    ));
    expect(findEditableText(), equals(inputBox));
    expect(inputBox.size.height, height - padding - counterSpace);

    // When a label is present, EditableText shrinks to fit it at the top so
    // that the bottom of the input still lines up perfectly with the parent.
    await tester.pumpWidget(containedTextFieldBuilder(
      labelText: 'I am labelText',
    ));
    const double labelSpace = 16.0;
    expect(findEditableText(), equals(inputBox));
    expect(inputBox.size.height, height - padding - labelSpace);

    // When decoration is present on the top and bottom, EditableText shrinks to
    // fit both inside the parent independently.
    await tester.pumpWidget(containedTextFieldBuilder(
      counter: Container(height: counterHeight),
      labelText: 'I am labelText',
    ));
    expect(findEditableText(), equals(inputBox));
    expect(inputBox.size.height, height - padding - counterSpace - labelSpace);

    // When a prefix or suffix is present in an input that's full of content,
    // it is ignored and allowed to expand beyond the top of the input. Other
    // top and bottom decoration is still respected.
    await tester.pumpWidget(containedTextFieldBuilder(
      counter: Container(height: counterHeight),
      labelText: 'I am labelText',
      prefix: Container(
        width: 10,
        height: 60,
      ),
    ));
    expect(findEditableText(), equals(inputBox));
    expect(
      inputBox.size.height,
      height
      - padding
      - labelSpace
      - counterSpace,
    );
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
    expect(findHintText(multipleLineText).size.width, greaterThanOrEqualTo(oneLineHintSize.width));
    expect(findHintText(multipleLineText).size.height, greaterThanOrEqualTo(oneLineHintSize.height));
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
          strutStyle: StrutStyle.disabled,
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
    expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(firstPos)), isTrue);
    expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(fourthPos)), isFalse);

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
    expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isFalse);
    expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isTrue);

    // Now try scrolling by dragging the selection handle.
    // Long press the middle of the word "won't" in the fourth line.
    final Offset selectedWordPos = textOffsetToPosition(
      tester,
      kMoreThanFourLines.indexOf('Fourth line') + 14,
    );

    gesture = await tester.startGesture(selectedWordPos, pointer: 7);
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(controller.selection.base.offset, 77);
    expect(controller.selection.extent.offset, 82);
    // Sanity check for the word selected is the intended one.
    expect(
      controller.text.substring(controller.selection.baseOffset, controller.selection.extentOffset),
      "won't",
    );

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
    expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFirstPos)), isTrue);
    expect(inputBox.hitTest(BoxHitTestResult(), position: inputBox.globalToLocal(newFourthPos)), isFalse);
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

  testWidgets('TextField prefix and suffix appear correctly with no hint or label', (WidgetTester tester) async {
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

  testWidgets('TextField prefix and suffix appear correctly with hint text', (WidgetTester tester) async {
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

  testWidgets('TextField prefix and suffix appear correctly with label text', (WidgetTester tester) async {
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
  }, skip: isBrowser);

  testWidgets('Collapsed hint text placement', (WidgetTester tester) async {
    await tester.pumpWidget(
      overlay(
        child: const TextField(
          decoration: InputDecoration.collapsed(
            hintText: 'hint',
          ),
          strutStyle: StrutStyle.disabled,
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

    // The overlay() function centers its child within a 800x600 window.
    // Default cursorWidth is 2.0, test windowWidth is 800
    // Centered cursor topLeft.dx: 399 == windowWidth/2 - cursorWidth/2
    expect(topLeft.dx, equals(399.0));

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );

    // TextPosition(offset: 2) - center of 'abcd'
    expect(topLeft.dx, equals(399.0));
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

    // The overlay() function centers its child within a 800x600 window.
    // Default cursorWidth is 2.0, test windowWidth is 800
    // Centered cursor topLeft.dx: 399 == windowWidth/2 - cursorWidth/2
    expect(topLeft.dx, equals(399.0));

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );

    // TextPosition(offset: 2) - center of 'abcd'
    expect(topLeft.dx, equals(399.0));
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
    expect(scrollableState.position.pixels, equals(222.0));
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
              controller: controller1,
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

  testWidgets('setting maxLength to TextField.noMaxLength shows only entered length', (WidgetTester tester) async {
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
              buildCounter: (BuildContext context, { int currentLength, int maxLength, bool isFocused }) {
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

  testWidgets('Read only TextField identifies as read only text field in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              maxLength: 10,
              readOnly: true,
            ),
          ),
        ),
      ),
    );

    expect(
      semantics,
      includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.isTextField, SemanticsFlag.isReadOnly])
    );

    semantics.dispose();
  });

  testWidgets('TextField loses focus when disabled', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'TextField');
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              focusNode: focusNode,
              autofocus: true,
              maxLength: 10,
              enabled: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: TextField(
              focusNode: focusNode,
              autofocus: true,
              maxLength: 10,
              enabled: false,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets("Disabled TextField can't be traversed to when disabled.", (WidgetTester tester) async {
    final FocusNode focusNode1 = FocusNode(debugLabel: 'TextField 1');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'TextField 2');
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: Column(
              children: <Widget>[
                TextField(
                  focusNode: focusNode1,
                  autofocus: true,
                  maxLength: 10,
                  enabled: true,
                ),
                TextField(
                  focusNode: focusNode2,
                  maxLength: 10,
                  enabled: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);

    expect(focusNode1.nextFocus(), isTrue);
    await tester.pump();

    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);
  });

  void sendFakeKeyEvent(Map<String, dynamic> data) {
    ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
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
      'keyCode': code,
      'hidUsage': 0x04,
      'codePoint': 0x64,
      'metaState': metaState,
    });
  }

  group('Keyboard Tests', () {
    TextEditingController controller;

    setUp( () {
      controller = TextEditingController();
    });

    Future<void> setupWidget(WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: RawKeyboardListener(
              focusNode: focusNode,
              onKey: null,
              child: TextField(
                controller: controller,
                maxLines: 3,
                strutStyle: StrutStyle.disabled,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Shift test 1', (WidgetTester tester) async {
      await setupWidget(tester);
      const String testValue = 'a big house';
      await tester.enterText(find.byType(TextField), testValue);

      await tester.idle();
      // Need to wait for selection to catch up.
      await tester.pump();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      sendKeyEventWithCode(21, true, true, false);     // LEFT_ARROW keydown, SHIFT_ON
      expect(controller.selection.extentOffset - controller.selection.baseOffset, 1);
    });

    testWidgets('Shift test 2', (WidgetTester tester) async {
      await setupWidget(tester);

      const String testValue = 'abcdefghi';
      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: testValue,
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: testValue.length)
      ));
      await tester.pump();

      sendKeyEventWithCode(22, true, true, false);
      await tester.pumpAndSettle();
      expect(controller.selection.extentOffset - controller.selection.baseOffset, 1);
    });

    testWidgets('Control Shift test', (WidgetTester tester) async {
      await setupWidget(tester);
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

    testWidgets('Down and up test', (WidgetTester tester) async {
      await setupWidget(tester);
      const String testValue = 'a big house';
      await tester.enterText(find.byType(TextField), testValue);

      await tester.idle();
      // Need to wait for selection to catch up.
      await tester.pump();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      sendKeyEventWithCode(19, true, true, false);         // UP_ARROW keydown
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 11);

      sendKeyEventWithCode(19, false, true, false);          // UP_ARROW keyup
      await tester.pumpAndSettle();
      sendKeyEventWithCode(20, true, true, false);           // DOWN_ARROW keydown
      await tester.pumpAndSettle();

      expect(controller.selection.extentOffset - controller.selection.baseOffset, 0);
    });

    testWidgets('Down and up test 2', (WidgetTester tester) async {
      await setupWidget(tester);
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

    testWidgets('Read only keyboard selection test', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(text: 'readonly');
      await tester.pumpWidget(
          overlay(
            child: TextField(
              controller: controller,
              readOnly: true,
            ),
          )
      );

      await tester.idle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      sendKeyEventWithCode(21, true, true, false);     // LEFT_ARROW keydown, SHIFT_ON
      expect(controller.selection.extentOffset - controller.selection.baseOffset, 1);
    });
  });

  const int _kXKeyCode = 52;
  const int _kCKeyCode = 31;
  const int _kVKeyCode = 50;
  const int _kAKeyCode = 29;
  const int _kDelKeyCode = 112;

  testWidgets('Copy paste test', (WidgetTester tester) async {
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
    focusNode.requestFocus();
    await tester.pump();

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

  testWidgets('Cut test', (WidgetTester tester) async {
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
    focusNode.requestFocus();
    await tester.pump();

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

  testWidgets('Select all test', (WidgetTester tester) async {
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
    focusNode.requestFocus();
    await tester.pump();

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

  testWidgets('Delete test', (WidgetTester tester) async {
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
    focusNode.requestFocus();
    await tester.pump();

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

  testWidgets('Changing positions of text fields', (WidgetTester tester) async {

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
    // Need to wait for selection to catch up.
    await tester.pump();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(21, true, true, false); // LEFT_ARROW keydown
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
      sendKeyEventWithCode(21, true, true, false); // LEFT_ARROW keydown
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


    const String testValue = 'a big house';
    await tester.enterText(find.byType(TextField).first, testValue);
    await tester.idle();
    await tester.pump();

    await tester.idle();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(21, true, true, false); // LEFT_ARROW keydown
      await tester.pumpAndSettle();
    }

    expect(c1.selection.extentOffset - c1.selection.baseOffset, 5);
    expect(c2.selection.extentOffset - c2.selection.baseOffset, 0);

    await tester.enterText(find.byType(TextField).last, testValue);
    await tester.idle();
    await tester.pump();

    await tester.idle();
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i += 1) {
      sendKeyEventWithCode(21, true, true, false); // LEFT_ARROW keydown
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

  testWidgets('TextField baseline alignment no-strut', (WidgetTester tester) async {
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
                strutStyle: StrutStyle.disabled,
              ),
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
                strutStyle: StrutStyle.disabled,
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
              ),
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
    // The values here should match the version with strut disabled ('TextField baseline alignment no-strut')
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
    semanticsOwner.performAction(inputFieldId, SemanticsAction.setSelection, <dynamic, dynamic>{
      'base': 4,
      'extent': 4,
    });
    await tester.pump();
    expect(controller.selection, const TextSelection.collapsed(offset: 4));

    // move cursor to front
    semanticsOwner.performAction(inputFieldId, SemanticsAction.setSelection, <dynamic, dynamic>{
      'base': 0,
      'extent': 0,
    });
    await tester.pump();
    expect(controller.selection, const TextSelection.collapsed(offset: 0));

    // select all
    semanticsOwner.performAction(inputFieldId, SemanticsAction.setSelection, <dynamic, dynamic>{
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
    final FocusNode focusNode = FocusNode(debugLabel: 'TextField Focus Node');

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

    expect(topLeft.dx, equals(701));

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

    expect(topLeft.dx, equals(160.0));
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

      // Selected text shows 4 toolbar buttons: cut, copy, paste, select all
      expect(find.byType(FlatButton), findsNWidgets(4));
    },
  );

  testWidgets(
    'double tap on top of cursor also selects word (Android)',
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

      // Tap to put the cursor after the "w".
      const int index = 3;
      await tester.tapAt(textOffsetToPosition(tester, index));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: index),
      );

      // Double tap on the same location.
      await tester.tapAt(textOffsetToPosition(tester, index));
      await tester.pump(const Duration(milliseconds: 50));

      // First tap doesn't change the selection
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: index),
      );

      // Second tap selects the word around the cursor.
      await tester.tapAt(textOffsetToPosition(tester, index));
      await tester.pump();
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 7),
      );

      // Selected text shows 4 toolbar buttons: cut, copy, paste, select all
      expect(find.byType(FlatButton), findsNWidgets(4));
    },
  );

  testWidgets(
    'double double tap just shows the selection menu',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: '',
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

      // Double tap on the same location shows the selection menu.
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pump();
      expect(find.text('PASTE'), findsOneWidget);

      // Double tap again keeps the selection menu visible.
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pump();
      expect(find.text('PASTE'), findsOneWidget);
    },
  );

  testWidgets(
    'double long press just shows the selection menu',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: '',
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

      // Long press shows the selection menu.
      await tester.longPressAt(textOffsetToPosition(tester, 0));
      await tester.pump();
      expect(find.text('PASTE'), findsOneWidget);

      // Long press again keeps the selection menu visible.
      await tester.longPressAt(textOffsetToPosition(tester, 0));
      await tester.pump();
      expect(find.text('PASTE'), findsOneWidget);
    },
  );

  testWidgets(
    'A single tap hides the selection menu',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: '',
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

      // Long press shows the selection menu.
      await tester.longPress(find.byType(TextField));
      await tester.pump();
      expect(find.text('PASTE'), findsOneWidget);

      // Tap hides the selection menu.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(find.text('PASTE'), findsNothing);
    },
  );

  testWidgets(
    'Long press on an autofocused field shows the selection menu',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: TextField(
                autofocus: true,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      // This extra pump allows the selection set by autofocus to propagate to
      // the RenderEditable.
      await tester.pump();

      // Long press shows the selection menu.
      expect(find.text('PASTE'), findsNothing);
      await tester.longPress(find.byType(TextField));
      await tester.pump();
      expect(find.text('PASTE'), findsOneWidget);
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
      // The toolbar is still showing.
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

      // Collapsed toolbar shows 4 buttons: cut, copy, paste, select all
      expect(find.byType(FlatButton), findsNWidgets(4));
    },
  );

  testWidgets(
    'long press tap cannot initiate a double tap (iOS)',
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
    'long press drag moves the cursor under the drag and shows toolbar on lift (iOS)',
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

      final TestGesture gesture =
          await tester.startGesture(textfieldStart + const Offset(50.0, 5.0));
      await tester.pump(const Duration(milliseconds: 500));

      // Long press on iOS shows collapsed selection cursor.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 3, affinity: TextAffinity.downstream),
      );
      // Cursor move doesn't trigger a toolbar initially.
      expect(find.byType(CupertinoButton), findsNothing);

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // The selection position is now moved with the drag.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 6, affinity: TextAffinity.downstream),
      );
      // Still no toolbar.
      expect(find.byType(CupertinoButton), findsNothing);

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // The selection position is now moved with the drag.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 9, affinity: TextAffinity.downstream),
      );
      // Still no toolbar.
      expect(find.byType(CupertinoButton), findsNothing);

      await gesture.up();
      await tester.pump();

      // The selection isn't affected by the gesture lift.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 9, affinity: TextAffinity.downstream),
      );
      // The toolbar now shows up.
      expect(find.byType(CupertinoButton), findsNWidgets(2));
    },
  );

  testWidgets('long press drag can edge scroll (iOS)', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure Angrignon Peel Côte-des-Neiges',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Material(
          child: Center(
            child: TextField(
              controller: controller,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );

    final RenderEditable renderEditable = findRenderEditable(tester);

    List<TextSelectionPoint> lastCharEndpoint = renderEditable.getEndpointsForSelection(
      const TextSelection.collapsed(offset: 66), // Last character's position.
    );

    expect(lastCharEndpoint.length, 1);
    // Just testing the test and making sure that the last character is off
    // the right side of the screen.
    expect(lastCharEndpoint[0].point.dx, 1056);

    final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

    final TestGesture gesture =
        await tester.startGesture(textfieldStart + const Offset(300, 5));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 19, affinity: TextAffinity.upstream),
    );
    expect(find.byType(CupertinoButton), findsNothing);

    await gesture.moveBy(const Offset(600, 0));
    // To the edge of the screen basically.
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 56, affinity: TextAffinity.downstream),
    );
    // Keep moving out.
    await gesture.moveBy(const Offset(1, 0));
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 62, affinity: TextAffinity.downstream),
    );
    await gesture.moveBy(const Offset(1, 0));
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 66, affinity: TextAffinity.upstream),
    ); // We're at the edge now.
    expect(find.byType(CupertinoButton), findsNothing);

    await gesture.up();
    await tester.pump();

    // The selection isn't affected by the gesture lift.
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 66, affinity: TextAffinity.upstream),
    );
    // The toolbar now shows up.
    expect(find.byType(CupertinoButton), findsNWidgets(2));

    lastCharEndpoint = renderEditable.getEndpointsForSelection(
      const TextSelection.collapsed(offset: 66), // Last character's position.
    );

    expect(lastCharEndpoint.length, 1);
    // The last character is now on screen near the right edge.
    expect(lastCharEndpoint[0].point.dx, moreOrLessEquals(798, epsilon: 1));

    final List<TextSelectionPoint> firstCharEndpoint = renderEditable.getEndpointsForSelection(
      const TextSelection.collapsed(offset: 0), // First character's position.
    );
    expect(firstCharEndpoint.length, 1);
    // The first character is now offscreen to the left.
    expect(firstCharEndpoint[0].point.dx, moreOrLessEquals(-257, epsilon: 1));
  });

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

    final Offset offset = tester.getTopLeft(find.byType(TextField)) + const Offset(150.0, 5.0);

    const int pointerValue = 1;
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      offset,
      PointerDownEvent(
          pointer: pointerValue,
          position: offset,
          pressure: 0.0,
          pressureMax: 6.0,
          pressureMin: 0.0,
      ),
    );
    await gesture.updateWithCustomEvent(PointerMoveEvent(pointer: pointerValue, position: offset + const Offset(150.0, 5.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));

    // We don't want this gesture to select any word on Android.
    expect(controller.selection, const TextSelection.collapsed(offset: -1));

    await gesture.up();
    await tester.pump();
    expect(find.byType(FlatButton), findsNothing);
  });

  testWidgets('force press selects word (iOS)', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Material(
          child: TextField(
            controller: controller,
          ),
        ),
      ),
    );

    final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

    const int pointerValue = 1;
    final Offset offset = textfieldStart + const Offset(150.0, 5.0);
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      offset,
      PointerDownEvent(
        pointer: pointerValue,
        position: offset,
        pressure: 0.0,
        pressureMax: 6.0,
        pressureMin: 0.0,
      ),
    );

    await gesture.updateWithCustomEvent(PointerMoveEvent(pointer: pointerValue, position: textfieldStart + const Offset(150.0, 5.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));
    // We expect the force press to select a word at the given location.
    expect(
      controller.selection,
      const TextSelection(baseOffset: 8, extentOffset: 12),
    );

    await gesture.up();
    await tester.pump();
    expect(find.byType(CupertinoButton), findsNWidgets(3));
  });

  testWidgets('tap on non-force-press-supported devices work (iOS)', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Atwater Peel Sherbrooke Bonaventure',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Material(
          child: TextField(
            controller: controller,
          ),
        ),
      ),
    );

    final Offset textfieldStart = tester.getTopLeft(find.byType(TextField));

    const int pointerValue = 1;
    final Offset offset = textfieldStart + const Offset(150.0, 5.0);
    final TestGesture gesture = await tester.createGesture();
    await gesture.downWithCustomEvent(
      offset,
      PointerDownEvent(
        pointer: pointerValue,
        position: offset,
        // iPhone 6 and below report 0 across the board.
        pressure: 0,
        pressureMax: 0,
        pressureMin: 0,
      ),
    );

    await gesture.updateWithCustomEvent(PointerMoveEvent(pointer: pointerValue, position: textfieldStart + const Offset(150.0, 5.0), pressure: 0.5, pressureMin: 0, pressureMax: 1));
    await gesture.up();
    // The event should fallback to a normal tap and move the cursor.
    // Single taps selects the edge of the word.
    expect(
      controller.selection,
      const TextSelection.collapsed(offset: 8),
    );

    await tester.pump();
    // Single taps shouldn't trigger the toolbar.
    expect(find.byType(CupertinoButton), findsNothing);
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
      scrollPhysics: ClampingScrollPhysics(),
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
      'selection disabled',
      'scrollPhysics: ClampingScrollPhysics',
    ]);
  });

  testWidgets(
    'strut basic single line',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // This is the height of the decoration (24) plus the metrics from the default
        // TextStyle of the theme (16).
        const Size(800, 40),
      );
    },
  );

  testWidgets(
    'strut TextStyle increases height',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // Strut should inherit the TextStyle.fontSize by default and produce the
        // same height as if it were disabled.
        const Size(800, 44),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(
                style: TextStyle(fontSize: 20),
                strutStyle: StrutStyle.disabled,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // The height here should match the previous version with strut enabled.
        const Size(800, 44),
      );
    },
  );

  testWidgets(
    'strut basic multi line',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(
                maxLines: 6,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // The height should be the input decoration (24) plus 6x the strut height (16).
        const Size(800, 120),
      );
    },
  );

  testWidgets(
    'strut no force small strut',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(
                maxLines: 6,
                strutStyle: StrutStyle(
                  // The small strut is overtaken by the larger
                  // TextStyle fontSize.
                  fontSize: 5,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // When the strut's height is smaller than TextStyle's and forceStrutHeight
        // is disabled, then the TextStyle takes precedence. Should be the same height
        // as 'strut basic multi line'.
        const Size(800, 120),
      );
    },
  );

  testWidgets(
    'strut no force large strut',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(
                maxLines: 6,
                strutStyle: StrutStyle(
                  fontSize: 25,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // When the strut's height is larger than TextStyle's and forceStrutHeight
        // is disabled, then the StrutStyle takes precedence.
        const Size(800, 174),
      );
    },
  );

  testWidgets(
    'strut height override',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(
                maxLines: 3,
                strutStyle: StrutStyle(
                  fontSize: 8,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // The smaller font size of strut make the field shorter than normal.
        const Size(800, 48),
      );
    },
  );

  testWidgets(
    'strut forces field taller',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Material(
            child: Center(
              child: TextField(
                maxLines: 3,
                style: TextStyle(fontSize: 10),
                strutStyle: StrutStyle(
                  fontSize: 18,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextField)),
        // When the strut fontSize is larger than a provided TextStyle, the
        // the strut's height takes precedence.
        const Size(800, 78),
      );
    },
  );

  testWidgets('Caret center position', (WidgetTester tester) async {
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

    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();


    Offset topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 4)).topLeft,
    );
    expect(topLeft.dx, equals(431));

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 3)).topLeft,
    );
    expect(topLeft.dx, equals(415));

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );
    expect(topLeft.dx, equals(399));

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 1)).topLeft,
    );
    expect(topLeft.dx, equals(383));
  });

  testWidgets('Caret indexes into trailing whitespace center align', (WidgetTester tester) async {
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

    await tester.enterText(find.byType(TextField), 'abcd    ');
    await tester.pump();

    Offset topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 7)).topLeft,
    );
    expect(topLeft.dx, equals(479));

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 8)).topLeft,
    );
    expect(topLeft.dx, equals(495));

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 4)).topLeft,
    );
    expect(topLeft.dx, equals(431));

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 3)).topLeft,
    );
    expect(topLeft.dx, equals(415)); // Should be same as equivalent in 'Caret center position'

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 2)).topLeft,
    );
    expect(topLeft.dx, equals(399)); // Should be same as equivalent in 'Caret center position'

    topLeft = editable.localToGlobal(
      editable.getLocalRectForCaret(const TextPosition(offset: 1)).topLeft,
    );
    expect(topLeft.dx, equals(383)); // Should be same as equivalent in 'Caret center position'
  });

  testWidgets('selection handles are rendered and not faded away', (WidgetTester tester) async {
    const String testText = 'lorem ipsum';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: controller,
          ),
        ),
      ),
    );

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));
    final RenderEditable renderEditable = state.renderEditable;

    await tester.tapAt(const Offset(20, 10));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pumpAndSettle();

    final List<Widget> transitions =
      find.byType(FadeTransition).evaluate().map((Element e) => e.widget).toList();
    // On Android, an empty app contains a single FadeTransition. The following
    // two are the left and right text selection handles, respectively.
    expect(transitions.length, 3);
    final FadeTransition left = transitions[1];
    final FadeTransition right = transitions[2];

    expect(left.opacity.value, equals(1.0));
    expect(right.opacity.value, equals(1.0));
  });

  testWidgets('iOS selection handles are rendered and not faded away', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const String testText = 'lorem ipsum';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: controller,
          ),
        ),
      ),
    );

    final RenderEditable renderEditable =
      tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;

    await tester.tapAt(const Offset(20, 10));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pumpAndSettle();

    final List<Widget> transitions =
      find.byType(FadeTransition).evaluate().map((Element e) => e.widget).toList();
    expect(transitions.length, 2);
    final FadeTransition left = transitions[0];
    final FadeTransition right = transitions[1];

    expect(left.opacity.value, equals(1.0));
    expect(right.opacity.value, equals(1.0));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Tap shows handles but not toolbar', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(controller: controller),
        ),
      ),
    );

    // Tap to trigger the text field.
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.selectionOverlay.handlesAreVisible, isTrue);
    expect(editableText.selectionOverlay.toolbarIsVisible, isFalse);
  });

  testWidgets(
    'Tap in empty text field does not show handles nor toolbar',
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TextField(controller: controller),
          ),
        ),
      );

      // Tap to trigger the text field.
      await tester.tap(find.byType(TextField));
      await tester.pump();

      final EditableTextState editableText = tester.state(find.byType(EditableText));
      expect(editableText.selectionOverlay.handlesAreVisible, isFalse);
      expect(editableText.selectionOverlay.toolbarIsVisible, isFalse);
    },
  );

  testWidgets('Long press shows handles and toolbar', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(controller: controller),
        ),
      ),
    );

    // Long press to trigger the text field.
    await tester.longPress(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.selectionOverlay.handlesAreVisible, isTrue);
    expect(editableText.selectionOverlay.toolbarIsVisible, isTrue);
  });

  testWidgets(
    'Long press in empty text field shows handles and toolbar',
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TextField(controller: controller),
          ),
        ),
      );

      // Tap to trigger the text field.
      await tester.longPress(find.byType(TextField));
      await tester.pump();

      final EditableTextState editableText = tester.state(find.byType(EditableText));
      expect(editableText.selectionOverlay.handlesAreVisible, isTrue);
      expect(editableText.selectionOverlay.toolbarIsVisible, isTrue);
    },
  );

  testWidgets('Double tap shows handles and toolbar', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(controller: controller),
        ),
      ),
    );

    // Double tap to trigger the text field.
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.selectionOverlay.handlesAreVisible, isTrue);
    expect(editableText.selectionOverlay.toolbarIsVisible, isTrue);
  });

  testWidgets(
    'Double tap in empty text field shows toolbar but not handles',
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TextField(controller: controller),
          ),
        ),
      );

      // Double tap to trigger the text field.
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      final EditableTextState editableText = tester.state(find.byType(EditableText));
      expect(editableText.selectionOverlay.handlesAreVisible, isFalse);
      expect(editableText.selectionOverlay.toolbarIsVisible, isTrue);
    },
  );

  testWidgets(
    'Mouse tap does not show handles nor toolbar',
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'abc def ghi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TextField(controller: controller),
          ),
        ),
      );

      // Long press to trigger the text field.
      final Offset textFieldPos = tester.getCenter(find.byType(TextField));
      final TestGesture gesture = await tester.startGesture(
        textFieldPos,
        pointer: 7,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final EditableTextState editableText = tester.state(find.byType(EditableText));
      expect(editableText.selectionOverlay.toolbarIsVisible, isFalse);
      expect(editableText.selectionOverlay.handlesAreVisible, isFalse);
    },
  );

  testWidgets(
    'Mouse long press does not show handles nor toolbar',
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'abc def ghi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TextField(controller: controller),
          ),
        ),
      );

      // Long press to trigger the text field.
      final Offset textFieldPos = tester.getCenter(find.byType(TextField));
      final TestGesture gesture = await tester.startGesture(
        textFieldPos,
        pointer: 7,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(seconds: 2));
      await gesture.up();
      await tester.pump();

      final EditableTextState editableText = tester.state(find.byType(EditableText));
      expect(editableText.selectionOverlay.toolbarIsVisible, isFalse);
      expect(editableText.selectionOverlay.handlesAreVisible, isFalse);
    },
  );

  testWidgets(
    'Mouse double tap does not show handles nor toolbar',
        (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'abc def ghi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: TextField(controller: controller),
          ),
        ),
      );

      // Double tap to trigger the text field.
      final Offset textFieldPos = tester.getCenter(find.byType(TextField));
      final TestGesture gesture = await tester.startGesture(
        textFieldPos,
        pointer: 7,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();
      await gesture.down(textFieldPos);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final EditableTextState editableText = tester.state(find.byType(EditableText));
      expect(editableText.selectionOverlay.toolbarIsVisible, isFalse);
      expect(editableText.selectionOverlay.handlesAreVisible, isFalse);
    },
  );

  testWidgets('Tapping selection handles toggles the toolbar', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'abc def ghi',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(controller: controller),
        ),
      ),
    );

    // Tap to position the cursor and show the selection handles.
    final Offset ePos = textOffsetToPosition(tester, 5); // Index of 'e'.
    await tester.tapAt(ePos, pointer: 7);
    await tester.pumpAndSettle();

    final EditableTextState editableText = tester.state(find.byType(EditableText));
    expect(editableText.selectionOverlay.toolbarIsVisible, isFalse);
    expect(editableText.selectionOverlay.handlesAreVisible, isTrue);

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(controller.selection),
      renderEditable,
    );
    expect(endpoints.length, 1);

    // Tap the handle to show the toolbar.
    final Offset handlePos = endpoints[0].point + const Offset(0.0, 1.0);
    await tester.tapAt(handlePos, pointer: 7);
    expect(editableText.selectionOverlay.toolbarIsVisible, isTrue);

    // Tap the handle again to hide the toolbar.
    await tester.tapAt(handlePos, pointer: 7);
    expect(editableText.selectionOverlay.toolbarIsVisible, isFalse);
  });

  testWidgets('when TextField would be blocked by keyboard, it is shown with enough space for the selection handle', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(),
      home: Scaffold(
        body: Center(
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              Container(height: 579), // Push field almost off screen.
              TextField(controller: controller),
              Container(height: 1000),
            ],
          ),
        ),
      ),
    ));

    // Tap the TextField to put the cursor into it and bring it into view.
    expect(scrollController.offset, 0.0);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // The ListView has scrolled to keep the TextField and cursor handle
    // visible.
    expect(scrollController.offset, 44.0);
  });
}

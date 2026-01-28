// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTextInputControl with TextInputControl {
  TextInputStyle? lastStyle;
  final List<String> methodCalls = <String>[];

  @override
  void attach(TextInputClient client, TextInputConfiguration configuration) {
    methodCalls.add('attach');
  }

  @override
  void detach(TextInputClient client) {
    methodCalls.add('detach');
  }

  @override
  void setEditingState(TextEditingValue value) {}

  @override
  void updateConfig(TextInputConfiguration configuration) {}

  @override
  void show() {}

  @override
  void hide() {}

  @override
  void setComposingRect(Rect rect) {}

  @override
  void setCaretRect(Rect rect) {}

  @override
  void setEditableSizeAndTransform(Size editableBoxSize, Matrix4 transform) {}

  @override
  void setSelectionRects(List<SelectionRect> selectionRects) {}

  @override
  void setStyle({
    required String? fontFamily,
    required double? fontSize,
    required FontWeight? fontWeight,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {}

  @override
  void updateStyle(TextInputStyle style) {
    lastStyle = style;
    methodCalls.add('updateStyle');
  }

  @override
  void finishAutofillContext({bool shouldSave = true}) {}

  @override
  void requestAutofill() {}
}

void main() {
  testWidgets('EditableText updates style when boldText changes', (WidgetTester tester) async {
    final control = FakeTextInputControl();
    TextInput.setInputControl(control);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(fontWeight: FontWeight.normal),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.fontWeight, FontWeight.normal);
    control.lastStyle = null; // Reset

    // Update boldText
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(boldText: true),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(fontWeight: FontWeight.normal),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.fontWeight, FontWeight.bold);

    TextInput.restorePlatformInputControl();
  });

  testWidgets('EditableText updates style when letterSpacingOverride changes', (
    WidgetTester tester,
  ) async {
    final control = FakeTextInputControl();
    TextInput.setInputControl(control);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(letterSpacing: 1.0),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle?.letterSpacing, 1.0);
    control.lastStyle = null;

    // Update letterSpacingOverride
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(letterSpacingOverride: 5.0),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(letterSpacing: 1.0),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.letterSpacing, 5.0);

    TextInput.restorePlatformInputControl();
  });

  testWidgets('EditableText updates style when wordSpacingOverride changes', (
    WidgetTester tester,
  ) async {
    final control = FakeTextInputControl();
    TextInput.setInputControl(control);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(wordSpacing: 2.0),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle?.wordSpacing, 2.0);
    control.lastStyle = null;

    // Update wordSpacingOverride
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(wordSpacingOverride: 10.0),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(wordSpacing: 2.0),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.wordSpacing, 10.0);

    TextInput.restorePlatformInputControl();
  });

  testWidgets('EditableText updates style when lineHeightScaleFactorOverride changes', (
    WidgetTester tester,
  ) async {
    final control = FakeTextInputControl();
    TextInput.setInputControl(control);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(lineHeightScaleFactorOverride: 1.0),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(fontSize: 20.0, height: 1.0),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle!.lineHeight, 20.0);
    control.lastStyle = null;

    // Update lineHeightScaleFactorOverride to 2.0
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(lineHeightScaleFactorOverride: 2.0),
          child: Material(
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: const TextStyle(fontSize: 20.0, height: 1.0),
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle!.lineHeight, 40.0);

    TextInput.restorePlatformInputControl();
  });
}

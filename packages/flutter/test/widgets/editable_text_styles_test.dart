// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
  late FakeTextInputControl control;
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    control = FakeTextInputControl();
    TextInput.setInputControl(control);
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    TextInput.restorePlatformInputControl();
    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('EditableText updates style when boldText changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontWeight: FontWeight.normal),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.fontWeight, FontWeight.normal);
    control.lastStyle = null; // Reset.

    // Update boldText.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(boldText: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontWeight: FontWeight.normal),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.fontWeight, FontWeight.bold);
  });

  testWidgets('EditableText updates style when letterSpacingOverride changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(letterSpacing: 1.0),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle?.letterSpacing, 1.0);
    control.lastStyle = null;

    // Update letterSpacingOverride.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(letterSpacingOverride: 5.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(letterSpacing: 1.0),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.letterSpacing, 5.0);
  });

  testWidgets('EditableText updates style when wordSpacingOverride changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(wordSpacing: 2.0),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle?.wordSpacing, 2.0);
    control.lastStyle = null;

    // Update wordSpacingOverride.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(wordSpacingOverride: 10.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(wordSpacing: 2.0),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle?.wordSpacing, 10.0);
  });

  testWidgets('EditableText updates style when lineHeightScaleFactorOverride changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(lineHeightScaleFactorOverride: 1.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 20.0, height: 1.0),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle!.lineHeight, 20.0);
    control.lastStyle = null;

    // Update lineHeightScaleFactorOverride to 2.0.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(lineHeightScaleFactorOverride: 2.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 20.0, height: 1.0),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(control.lastStyle, isNotNull);
    expect(control.lastStyle!.lineHeight, 40.0);
  });
}

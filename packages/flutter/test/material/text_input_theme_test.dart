// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/material/selectable_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('TextInputThemeData copyWith, ==, hashCode basics', () {
    expect(const TextInputThemeData(), const TextInputThemeData().copyWith());
    expect(const TextInputThemeData().hashCode, const TextInputThemeData().copyWith().hashCode);
  });

  test('TextInputThemeData null fields by default', () {
    const TextInputThemeData theme = TextInputThemeData();
    expect(theme.cursorColor, null);
    expect(theme.selectionHandleColor, null);
  });

  testWidgets('Default TextInputThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const TextInputThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('TextInputThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const TextInputThemeData(
      cursorColor: Color(0xffeeffaa),
      selectionHandleColor: Color(0xaabbccdd),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'cursorColor: Color(0xffeeffaa)',
      'selectionHandleColor: Color(0xaabbccdd)',
    ]);
  });

  testWidgets('Empty textInputTheme will use defaults', (WidgetTester tester) async {
    // Test TextField's cursor color
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: TextField(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, const Color(0x004285f4));

    // Test the selection handle color
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return materialTextSelectionControls.buildHandle(
                  context, TextSelectionHandleType.left, 10.0
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderBox handle = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(handle, paints..path(color: Colors.blue[300]));

  });

  testWidgets('Empty textInputTheme, with useTextInputTheme set will use new defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData.fallback().copyWith(useTextInputTheme: true);
    final Color primaryColor = Color(theme.colorScheme.primary.value);

    // Test TextField's cursor color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextField(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, primaryColor.withAlpha(0));

    // Test the selection handle color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return materialTextSelectionControls.buildHandle(
                context, TextSelectionHandleType.left, 10.0
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderBox handle = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(handle, paints..path(color: primaryColor));
  });

  testWidgets('ThemeDate.textInputTheme will used if provided', (WidgetTester tester) async {
    const TextInputThemeData textInputTheme = TextInputThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      useTextInputTheme: true,
      textInputTheme: textInputTheme,
    );

    // Test TextField's cursor color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextField(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, textInputTheme.cursorColor.withAlpha(0));

    // Test the selection handle color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return materialTextSelectionControls.buildHandle(
                  context, TextSelectionHandleType.left, 10.0
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderBox handle = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(handle, paints..path(color: textInputTheme.selectionHandleColor));
  });

  testWidgets('TextInputTheme widget will override ThemeDate.textInputTheme', (WidgetTester tester) async {
    const TextInputThemeData defaultTextInputTheme = TextInputThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      useTextInputTheme: true,
      textInputTheme: defaultTextInputTheme,
    );
    const TextInputThemeData widgetTextInputTheme = TextInputThemeData(
      cursorColor: Color(0xffddeeff),
      selectionHandleColor: Color(0x00ffeedd),
    );

    // Test TextField's cursor color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextInputTheme(
            data: widgetTextInputTheme,
            child: TextField(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, widgetTextInputTheme.cursorColor.withAlpha(0));

    // Test the selection handle color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: TextInputTheme(
            data: widgetTextInputTheme,
            child: Builder(
              builder: (BuildContext context) {
                return materialTextSelectionControls.buildHandle(
                    context, TextSelectionHandleType.left, 10.0
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderBox handle = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(handle, paints..path(color: widgetTextInputTheme.selectionHandleColor));
  });

  testWidgets('TextField parameters will override theme settings', (WidgetTester tester) async {
    const TextInputThemeData defaultTextInputTheme = TextInputThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      useTextInputTheme: true,
      textInputTheme: defaultTextInputTheme,
    );
    const TextInputThemeData widgetTextInputTheme = TextInputThemeData(
      cursorColor: Color(0xffddeeff),
      selectionHandleColor: Color(0x00ffeedd),
    );
    const Color cursorColor = Color(0x88888888);

    // Test TextField's cursor color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextInputTheme(
            data: widgetTextInputTheme,
            child: TextField(cursorColor: cursorColor),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, cursorColor.withAlpha(0));

    // Test SelectableText's cursor color
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextInputTheme(
            data: widgetTextInputTheme,
            child: SelectableText('foobar', cursorColor: cursorColor),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState selectableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderSelectable = selectableTextState.renderEditable;
    expect(renderSelectable.cursorColor, cursorColor.withAlpha(0));
  });
}

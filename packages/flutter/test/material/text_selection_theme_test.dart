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
  test('TextSelectionThemeData copyWith, ==, hashCode basics', () {
    expect(const TextSelectionThemeData(), const TextSelectionThemeData().copyWith());
    expect(const TextSelectionThemeData().hashCode, const TextSelectionThemeData().copyWith().hashCode);
  });

  test('TextSelectionThemeData null fields by default', () {
    const TextSelectionThemeData theme = TextSelectionThemeData();
    expect(theme.cursorColor, null);
    expect(theme.selectionColor, null);
    expect(theme.selectionHandleColor, null);
  });

  testWidgets('Default TextSelectionThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const TextSelectionThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('TextSelectionThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const TextSelectionThemeData(
      cursorColor: Color(0xffeeffaa),
      selectionColor: Color(0x88888888),
      selectionHandleColor: Color(0xaabbccdd),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'cursorColor: Color(0xffeeffaa)',
      'selectionColor: Color(0x88888888)',
      'selectionHandleColor: Color(0xaabbccdd)',
    ]);
  });

  testWidgets('Empty textSelectionTheme will use defaults', (WidgetTester tester) async {
    // Test TextField's cursor & selection color.
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
    expect(renderEditable.selectionColor, const Color(0xFF90CAF9));

    // Test the selection handle color.
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

  testWidgets('Empty textSelectionTheme with useTextSelectionTheme set will use new defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData.fallback().copyWith(useTextSelectionTheme: true);
    final Color primaryColor = Color(theme.colorScheme.primary.value);

    // Test TextField's cursor & selection color.
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
    expect(Color(renderEditable.selectionColor.value), primaryColor.withOpacity(0.12));

    // Test the selection handle color.
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

  testWidgets('ThemeDate.textSelectionTheme will be used if provided', (WidgetTester tester) async {
    const TextSelectionThemeData textSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionColor: Color(0x88888888),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      useTextSelectionTheme: true,
      textSelectionTheme: textSelectionTheme,
    );

    // Test TextField's cursor & selection color.
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
    expect(renderEditable.cursorColor, textSelectionTheme.cursorColor.withAlpha(0));
    expect(renderEditable.selectionColor, textSelectionTheme.selectionColor);

    // Test the selection handle color.
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
    expect(handle, paints..path(color: textSelectionTheme.selectionHandleColor));
  });

  testWidgets('TextSelectionTheme widget will override ThemeDate.textSelectionTheme', (WidgetTester tester) async {
    const TextSelectionThemeData defaultTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionColor: Color(0x88888888),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      useTextSelectionTheme: true,
      textSelectionTheme: defaultTextSelectionTheme,
    );
    const TextSelectionThemeData widgetTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffddeeff),
      selectionColor: Color(0x44444444),
      selectionHandleColor: Color(0x00ffeedd),
    );

    // Test TextField's cursor & selection color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
            child: TextField(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, widgetTextSelectionTheme.cursorColor.withAlpha(0));
    expect(renderEditable.selectionColor, widgetTextSelectionTheme.selectionColor);

    // Test the selection handle color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
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
    expect(handle, paints..path(color: widgetTextSelectionTheme.selectionHandleColor));
  });

  testWidgets('TextField parameters will override theme settings', (WidgetTester tester) async {
    const TextSelectionThemeData defaultTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      useTextSelectionTheme: true,
      textSelectionTheme: defaultTextSelectionTheme,
    );
    const TextSelectionThemeData widgetTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffddeeff),
      selectionHandleColor: Color(0x00ffeedd),
    );
    const Color cursorColor = Color(0x88888888);

    // Test TextField's cursor color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
            child: TextField(cursorColor: cursorColor),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, cursorColor.withAlpha(0));

    // Test SelectableText's cursor color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
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

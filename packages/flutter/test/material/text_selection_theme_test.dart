// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    const Color defaultCursorColor = Color(0xff2196f3);
    const Color defaultSelectionColor = Color(0x662196f3);
    const Color defaultSelectionHandleColor = Color(0xff2196f3);

    EditableText.debugDeterministicCursor = true;
    addTearDown(() {
      EditableText.debugDeterministicCursor = false;
    });

    // Test TextField's cursor & selection color.
    final TextEditingController editingController = TextEditingController(text: 'abc def ghi');
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: editingController,
            autofocus: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, defaultCursorColor);
    expect(renderEditable.selectionColor?.value, defaultSelectionColor.value);

    // Select 'def'.
    editingController.selection = const TextSelection(baseOffset: 4, extentOffset: 7);

    // Test the selection handle color.
    await tester.pumpAndSettle();
    final Iterable<RenderBox> handles = tester.renderObjectList<RenderBox>(find.byType(CustomPaint));
    final RenderBox leftHandle = handles.first;
    final RenderBox rightHandle = handles.last;
    expect(leftHandle, paints..path(color: defaultSelectionHandleColor));
    expect(rightHandle, paints..path(color: defaultSelectionHandleColor));
  });

  testWidgets('ThemeData.textSelectionTheme will be used if provided', (WidgetTester tester) async {
    const TextSelectionThemeData textSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionColor: Color(0x88888888),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      textSelectionTheme: textSelectionTheme,
    );

    EditableText.debugDeterministicCursor = true;
    addTearDown(() {
      EditableText.debugDeterministicCursor = false;
    });

    // Test TextField's cursor & selection color.
    final TextEditingController editingController = TextEditingController(text: 'abc def ghi');
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: TextField(
            controller: editingController,
            autofocus: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, textSelectionTheme.cursorColor);
    expect(renderEditable.selectionColor, textSelectionTheme.selectionColor);

    // Select 'def'.
    editingController.selection = const TextSelection(baseOffset: 4, extentOffset: 7);

    // Test the selection handle color.
    await tester.pumpAndSettle();
    final Iterable<RenderBox> handles = tester.renderObjectList<RenderBox>(find.byType(CustomPaint));
    final RenderBox leftHandle = handles.first;
    final RenderBox rightHandle = handles.last;
    expect(leftHandle, paints..path(color: textSelectionTheme.selectionHandleColor));
    expect(rightHandle, paints..path(color: textSelectionTheme.selectionHandleColor));
  });

  testWidgets('TextSelectionTheme widget will override ThemeData.textSelectionTheme', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/74890
    const TextSelectionThemeData defaultTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionColor: Color(0x88888888),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      textSelectionTheme: defaultTextSelectionTheme,
    );
    const TextSelectionThemeData widgetTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffddeeff),
      selectionColor: Color(0x44444444),
      selectionHandleColor: Color(0x00ffeedd),
    );

    EditableText.debugDeterministicCursor = true;
    addTearDown(() {
      EditableText.debugDeterministicCursor = false;
    });

    // Test TextField's cursor & selection color.
    final TextEditingController editingController = TextEditingController(text: 'abc def ghi');
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
            child: TextField(
              controller: editingController,
              autofocus: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, widgetTextSelectionTheme.cursorColor);
    expect(renderEditable.selectionColor, widgetTextSelectionTheme.selectionColor);

    // Select 'def'.
    editingController.selection = const TextSelection(baseOffset: 4, extentOffset: 7);

    // Test the selection handle color.
    await tester.pumpAndSettle();
    final Iterable<RenderBox> handles = tester.renderObjectList<RenderBox>(find.byType(CustomPaint));
    final RenderBox leftHandle = handles.first;
    final RenderBox rightHandle = handles.last;
    expect(leftHandle, paints..path(color: widgetTextSelectionTheme.selectionHandleColor));
    expect(rightHandle, paints..path(color: widgetTextSelectionTheme.selectionHandleColor));
  });

  testWidgets('TextField parameters will override theme settings', (WidgetTester tester) async {
    const TextSelectionThemeData defaultTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
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

  testWidgets('TextSelectionThem overrides DefaultSelectionStyle', (WidgetTester tester) async {
    const Color themeSelectionColor = Color(0xffaabbcc);
    const Color themeCursorColor = Color(0x00ccbbaa);
    const Color defaultSelectionColor = Color(0xffaa1111);
    const Color defaultCursorColor = Color(0x00cc2222);
    final Key defaultSelectionStyle = UniqueKey();
    final Key themeStyle = UniqueKey();
    // Test TextField's cursor color.
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultSelectionStyle(
          selectionColor: defaultSelectionColor,
          cursorColor: defaultCursorColor,
          child: Container(
            key: defaultSelectionStyle,
            child: TextSelectionTheme(
              data: const TextSelectionThemeData(
                selectionColor: themeSelectionColor,
                cursorColor: themeCursorColor,
              ),
              child: Placeholder(
                key: themeStyle,
              ),
            ),
          )
        ),
      ),
    );
    final BuildContext defaultSelectionStyleContext = tester.element(find.byKey(defaultSelectionStyle));
    DefaultSelectionStyle style = DefaultSelectionStyle.of(defaultSelectionStyleContext);
    expect(style.selectionColor, defaultSelectionColor);
    expect(style.cursorColor, defaultCursorColor);

    final BuildContext themeStyleContext = tester.element(find.byKey(themeStyle));
    style = DefaultSelectionStyle.of(themeStyleContext);
    expect(style.selectionColor, themeSelectionColor);
    expect(style.cursorColor, themeCursorColor);
  });
}

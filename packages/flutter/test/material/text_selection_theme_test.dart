// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class CustomContextMenu extends AdaptiveTextSelectionToolbar {
  const CustomContextMenu.buttonItems({
    super.key,
    required super.anchors,
    required super.buttonItems,
  }) : super.buttonItems();
}

void main() {
  CustomContextMenu defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return CustomContextMenu.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: <ContextMenuButtonItem>[
        ContextMenuButtonItem(
          onPressed: () {
            ContextMenuController.removeAny();
          },
          label: 'Context Button Item',
        ),
      ],
    );
  }

  test('TextSelectionThemeData copyWith, ==, hashCode basics', () {
    expect(const TextSelectionThemeData(), const TextSelectionThemeData().copyWith());
    expect(
      const TextSelectionThemeData().hashCode,
      const TextSelectionThemeData().copyWith().hashCode,
    );
  });

  test('TextSelectionThemeData lerp special cases', () {
    expect(TextSelectionThemeData.lerp(null, null, 0), null);
    const data = TextSelectionThemeData();
    expect(identical(TextSelectionThemeData.lerp(data, data, 0.5), data), true);
  });

  test('TextSelectionThemeData null fields by default', () {
    const theme = TextSelectionThemeData();
    expect(theme.cursorColor, null);
    expect(theme.selectionColor, null);
    expect(theme.selectionHandleColor, null);
    expect(theme.contextMenuBuilder, null);
  });

  testWidgets('Default TextSelectionThemeData debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    const TextSelectionThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('TextSelectionThemeData implements debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    TextSelectionThemeData(
      cursorColor: const Color(0xffeeffaa),
      selectionColor: const Color(0x88888888),
      selectionHandleColor: const Color(0xaabbccdd),
      contextMenuBuilder: defaultContextMenuBuilder,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'cursorColor: ${const Color(0xffeeffaa)}',
      'selectionColor: ${const Color(0x88888888)}',
      'selectionHandleColor: ${const Color(0xaabbccdd)}',
      'contextMenuBuilder: Closure: (BuildContext, EditableTextState) => CustomContextMenu',
    ]);
  });

  testWidgets('Material2 - Empty textSelectionTheme will use defaults', (
    WidgetTester tester,
  ) async {
    final theme = ThemeData(useMaterial3: false);
    const defaultCursorColor = Color(0xff2196f3);
    const defaultSelectionColor = Color(0x662196f3);
    const defaultSelectionHandleColor = Color(0xff2196f3);

    EditableText.debugDeterministicCursor = true;
    addTearDown(() {
      EditableText.debugDeterministicCursor = false;
    });
    // Test TextField's cursor & selection color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(child: TextField(autofocus: true)),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, defaultCursorColor);
    expect(renderEditable.selectionColor, defaultSelectionColor);

    final BuildContext textFieldContext = tester.element(find.byType(TextField));
    final EditableTextContextMenuBuilder? themeContextMenuBuilder = TextSelectionTheme.of(
      textFieldContext,
    ).contextMenuBuilder;
    expect(themeContextMenuBuilder, null);

    // Test the selection handle color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return materialTextSelectionControls.buildHandle(
                context,
                TextSelectionHandleType.left,
                10.0,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderBox handle = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(handle, paints..path(color: defaultSelectionHandleColor));
  });

  testWidgets('Material3 - Empty textSelectionTheme will use defaults', (
    WidgetTester tester,
  ) async {
    final theme = ThemeData();
    final Color defaultCursorColor = theme.colorScheme.primary;
    final Color defaultSelectionColor = theme.colorScheme.primary.withOpacity(0.40);
    final Color defaultSelectionHandleColor = theme.colorScheme.primary;

    EditableText.debugDeterministicCursor = true;
    addTearDown(() {
      EditableText.debugDeterministicCursor = false;
    });
    // Test TextField's cursor & selection color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(child: TextField(autofocus: true)),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, defaultCursorColor);
    expect(renderEditable.selectionColor, defaultSelectionColor);

    final BuildContext textFieldContext = tester.element(find.byType(TextField));
    final EditableTextContextMenuBuilder? themeContextMenuBuilder = TextSelectionTheme.of(
      textFieldContext,
    ).contextMenuBuilder;
    expect(themeContextMenuBuilder, null);

    // Test the selection handle color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return materialTextSelectionControls.buildHandle(
                context,
                TextSelectionHandleType.left,
                10.0,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final RenderBox handle = tester.firstRenderObject<RenderBox>(find.byType(CustomPaint));
    expect(handle, paints..path(color: defaultSelectionHandleColor));
  });

  testWidgets('ThemeData.textSelectionTheme will be used if provided', (WidgetTester tester) async {
    final textSelectionTheme = TextSelectionThemeData(
      cursorColor: const Color(0xffaabbcc),
      selectionColor: const Color(0x88888888),
      selectionHandleColor: const Color(0x00ccbbaa),
      contextMenuBuilder: defaultContextMenuBuilder,
    );
    final ThemeData theme = ThemeData.fallback().copyWith(textSelectionTheme: textSelectionTheme);

    EditableText.debugDeterministicCursor = true;
    addTearDown(() {
      EditableText.debugDeterministicCursor = false;
    });

    // Test TextField's cursor & selection color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(child: TextField(autofocus: true)),
      ),
    );
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, textSelectionTheme.cursorColor);
    expect(renderEditable.selectionColor, textSelectionTheme.selectionColor);
    final BuildContext textFieldContext = tester.element(find.byType(TextField));
    final EditableTextContextMenuBuilder? themeContextMenuBuilder = TextSelectionTheme.of(
      textFieldContext,
    ).contextMenuBuilder;
    expect(themeContextMenuBuilder, textSelectionTheme.contextMenuBuilder);

    // Test the selection handle color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return materialTextSelectionControls.buildHandle(
                context,
                TextSelectionHandleType.left,
                10.0,
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

  testWidgets('TextSelectionTheme widget will override ThemeData.textSelectionTheme', (
    WidgetTester tester,
  ) async {
    const defaultTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionColor: Color(0x88888888),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      textSelectionTheme: defaultTextSelectionTheme,
    );
    final widgetTextSelectionTheme = TextSelectionThemeData(
      cursorColor: const Color(0xffddeeff),
      selectionColor: const Color(0x44444444),
      selectionHandleColor: const Color(0x00ffeedd),
      contextMenuBuilder: defaultContextMenuBuilder,
    );

    EditableText.debugDeterministicCursor = true;
    addTearDown(() {
      EditableText.debugDeterministicCursor = false;
    });
    // Test TextField's cursor & selection color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
            child: const TextField(autofocus: true),
          ),
        ),
      ),
    );
    await tester.pump();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, widgetTextSelectionTheme.cursorColor);
    expect(renderEditable.selectionColor, widgetTextSelectionTheme.selectionColor);

    final BuildContext textFieldContext = tester.element(find.byType(TextField));
    final EditableTextContextMenuBuilder? themeContextMenuBuilder = TextSelectionTheme.of(
      textFieldContext,
    ).contextMenuBuilder;
    expect(themeContextMenuBuilder, widgetTextSelectionTheme.contextMenuBuilder);

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
                  context,
                  TextSelectionHandleType.left,
                  10.0,
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
    const defaultTextSelectionTheme = TextSelectionThemeData(
      cursorColor: Color(0xffaabbcc),
      selectionHandleColor: Color(0x00ccbbaa),
    );
    final ThemeData theme = ThemeData.fallback().copyWith(
      textSelectionTheme: defaultTextSelectionTheme,
    );
    const widgetTextSelectionTheme = TextSelectionThemeData(cursorColor: Color(0xffddeeff));
    const cursorColor = Color(0x88888888);

    // Test TextField's cursor color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
            child: TextField(
              cursorColor: cursorColor,
              contextMenuBuilder: defaultContextMenuBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;
    expect(renderEditable.cursorColor, cursorColor.withAlpha(0));
    expect(editableTextState.widget.contextMenuBuilder, defaultContextMenuBuilder);

    // Test SelectableText's cursor color.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: TextSelectionTheme(
            data: widgetTextSelectionTheme,
            child: SelectableText(
              'foobar',
              cursorColor: cursorColor,
              contextMenuBuilder: defaultContextMenuBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final EditableTextState selectableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderSelectable = selectableTextState.renderEditable;
    expect(renderSelectable.cursorColor, cursorColor.withAlpha(0));
    expect(selectableTextState.widget.contextMenuBuilder, defaultContextMenuBuilder);
  });

  testWidgets('TextSelectionThem overrides DefaultSelectionStyle', (WidgetTester tester) async {
    const themeSelectionColor = Color(0xffaabbcc);
    const themeCursorColor = Color(0x00ccbbaa);
    const defaultSelectionColor = Color(0xffaa1111);
    const defaultCursorColor = Color(0x00cc2222);
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
              data: TextSelectionThemeData(
                selectionColor: themeSelectionColor,
                cursorColor: themeCursorColor,
                contextMenuBuilder: defaultContextMenuBuilder,
              ),
              child: Placeholder(key: themeStyle),
            ),
          ),
        ),
      ),
    );
    final BuildContext defaultSelectionStyleContext = tester.element(
      find.byKey(defaultSelectionStyle),
    );
    DefaultSelectionStyle style = DefaultSelectionStyle.of(defaultSelectionStyleContext);
    expect(style.selectionColor, defaultSelectionColor);
    expect(style.cursorColor, defaultCursorColor);

    TextSelectionThemeData textSelectionTheme = TextSelectionTheme.of(defaultSelectionStyleContext);
    expect(textSelectionTheme.contextMenuBuilder, null);

    final BuildContext themeStyleContext = tester.element(find.byKey(themeStyle));
    style = DefaultSelectionStyle.of(themeStyleContext);
    expect(style.selectionColor, themeSelectionColor);
    expect(style.cursorColor, themeCursorColor);

    textSelectionTheme = TextSelectionTheme.of(themeStyleContext);
    expect(textSelectionTheme.contextMenuBuilder, defaultContextMenuBuilder);
  });
}

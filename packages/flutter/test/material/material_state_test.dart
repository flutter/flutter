// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome') // whole file needs triage.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('MaterialStateBuilder properly builds in all states', (WidgetTester tester) async {
    const String defaultStateText = 'default';
    const String disabledText = 'disabled';
    const String selectedText = 'selected';
    const String errorText = 'error';
    const String hoverText = 'hovered';
    const String focusText = 'focused';
    const String pressText = 'pressed';

    FocusNode focusNode = FocusNode();

    Widget entireWidget({bool disabled = false, bool selected = false, bool error = false}) {
      return MaterialApp(
        home: Scaffold(
          body: Focus(
            focusNode: focusNode,
            child: MaterialStateBuilder(
              disabled: disabled,
              selected: selected,
              error: error,
              builder: (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled))
                  return const Text(disabledText);
                if (states.contains(MaterialState.selected))
                  return const Text(selectedText);
                if (states.contains(MaterialState.error))
                  return const Text(errorText);
                if (states.contains(MaterialState.hovered))
                  return const Text(hoverText);
                if (states.contains(MaterialState.focused))
                  return const Text(focusText);
                if (states.contains(MaterialState.pressed))
                  return const Text(pressText);
                return const Text(defaultStateText);
              },
            ),
          ),
        ),
      );
    }

    // Default state.
    await tester.pumpWidget(entireWidget());
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(disabledText), findsNothing);
    expect(find.text(selectedText), findsNothing);
    expect(find.text(errorText), findsNothing);
    expect(find.text(hoverText), findsNothing);
    expect(find.text(focusText), findsNothing);
    expect(find.text(pressText), findsNothing);

    // Disabled state.
    await tester.pumpWidget(entireWidget(disabled: true));
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(disabledText), findsOneWidget);
    expect(find.text(selectedText), findsNothing);
    expect(find.text(errorText), findsNothing);
    expect(find.text(hoverText), findsNothing);
    expect(find.text(focusText), findsNothing);
    expect(find.text(pressText), findsNothing);

    // Re-enabled.
    await tester.pumpWidget(entireWidget(disabled: false));
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(disabledText), findsNothing);

    // Selected state.
    await tester.pumpWidget(entireWidget(selected: true));
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(disabledText), findsNothing);
    expect(find.text(selectedText), findsOneWidget);

    // Un-select.
    await tester.pumpWidget(entireWidget(selected: false));
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(disabledText), findsNothing);
    expect(find.text(selectedText), findsNothing);

    // Error state.
    await tester.pumpWidget(entireWidget(error: true));
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(errorText), findsOneWidget);

    // Undo error.
    await tester.pumpWidget(entireWidget(error: false));
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(errorText), findsNothing);

    // Hover state.
    await tester.pumpWidget(entireWidget());
    final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.moveTo(tester.getCenter(find.byType(Text)));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(hoverText), findsOneWidget);

    // Un-hover.
    await mouse.moveTo(tester.getTopRight(find.byType(MaterialApp)));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(hoverText), findsNothing);

    // Focus.
    focusNode = focusNode.children.first;
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(focusText), findsOneWidget);

    // Un-focus.
    focusNode.unfocus();
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(focusText), findsNothing);

    // Press.
    final TestGesture finger = await tester.createGesture();
    await finger.down(tester.getCenter(find.byType(Text)));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(pressText), findsOneWidget);

    // Lift Press.
    await finger.up();
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(pressText), findsNothing);

    // Teardown.
    await mouse.removePointer();
  });

  testWidgets('MaterialStateBuilder handles combined states', (WidgetTester tester) async {
    const String defaultStateText = 'default';
    const String disabledText = 'disabled';
    const String hoverText = 'hover';
    const String selectedText = 'selected';
    const String hoverAndSelectedText = 'hovered and selected';

    Widget entireWidget({bool disabled = false, bool selected = false, bool error = false}) {
      return MaterialApp(
        home: Scaffold(
          body: MaterialStateBuilder(
            disabled: disabled,
            selected: selected,
            error: error,
            builder: (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return const Text(disabledText);
              }

              if (states.contains(MaterialState.selected)) {
                if (states.contains(MaterialState.hovered)) {
                  return const Text(hoverAndSelectedText);
                }
                return const Text(selectedText);
              }

              if (states.contains(MaterialState.hovered)) {
                return const Text(hoverText);
              }
              return const Text(defaultStateText);
            },
          ),
        ),
      );
    }

    // Default state.
    await tester.pumpWidget(entireWidget());
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(hoverText), findsNothing);
    expect(find.text(selectedText), findsNothing);
    expect(find.text(hoverAndSelectedText), findsNothing);

    // Hover state.
    await tester.pumpWidget(entireWidget());
    final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.moveTo(tester.getCenter(find.byType(Text)));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(hoverText), findsOneWidget);

    // Un-hover.
    await mouse.moveTo(tester.getTopRight(find.byType(MaterialApp)));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsOneWidget);
    expect(find.text(hoverText), findsNothing);

    // Select.
    await tester.pumpWidget(entireWidget(selected: true));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(selectedText), findsOneWidget);

    // Hover (while selected).
    await mouse.moveTo(tester.getCenter(find.byType(Text)));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(selectedText), findsNothing);
    expect(find.text(hoverText), findsNothing);
    expect(find.text(hoverAndSelectedText), findsOneWidget);

    // Unselect (while still hovered).
    await tester.pumpWidget(entireWidget(selected: false));
    await tester.pumpAndSettle();
    expect(find.text(defaultStateText), findsNothing);
    expect(find.text(selectedText), findsNothing);
    expect(find.text(hoverText), findsOneWidget);
    expect(find.text(hoverAndSelectedText), findsNothing);

    // Disable (while still hovered).
    await tester.pumpWidget(entireWidget(disabled: true));
    await tester.pumpAndSettle();
    expect(find.text(disabledText), findsOneWidget);
    expect(find.text(selectedText), findsNothing);
    expect(find.text(hoverText), findsNothing);
    expect(find.text(hoverAndSelectedText), findsNothing);

    // Re-enabled and select (while still hovered).
    await tester.pumpWidget(entireWidget(disabled: false, selected: true));
    await tester.pumpAndSettle();
    expect(find.text(disabledText), findsNothing);
    expect(find.text(selectedText), findsNothing);
    expect(find.text(hoverText), findsNothing);
    expect(find.text(hoverAndSelectedText), findsOneWidget);

    // Un-hover (back to just selected).
    await mouse.moveTo(tester.getTopRight(find.byType(MaterialApp)));
    await tester.pumpAndSettle();
    expect(find.text(disabledText), findsNothing);
    expect(find.text(selectedText), findsOneWidget);
    expect(find.text(hoverText), findsNothing);
    expect(find.text(hoverAndSelectedText), findsNothing);

    // Teardown.
    await mouse.removePointer();
  });
}

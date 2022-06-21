// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/material/menu_bar/menu_bar.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can open menu', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MenuBarApp(),
    );

    final Finder menuBarFinder = find.byType(MenuBar);
    final MenuBar menuBar = tester.widget<MenuBar>(menuBarFinder);
    expect(menuBar.children, isNotEmpty);
    expect(menuBar.children.length, equals(1));

    final Finder menuButtonFinder = find.byType(MenuBarButton).first;
    await tester.tap(menuButtonFinder);
    await tester.pump();

    expect(find.text(example.MenuSelection.about.label), findsOneWidget);
    expect(find.text(example.MenuSelection.showMessage.label), findsOneWidget);
    expect(find.text(example.MenuSelection.resetMessage.label), findsOneWidget);
    expect(find.text('Background Color'), findsOneWidget);
    expect(find.text(example.MenuSelection.colorRed.label), findsNothing);
    expect(find.text(example.MenuSelection.colorGreen.label), findsNothing);
    expect(find.text(example.MenuSelection.colorBlue.label), findsNothing);
    expect(find.text(example.kMessage), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(find.text(example.MenuSelection.about.label), findsOneWidget);
    expect(find.text(example.MenuSelection.showMessage.label), findsOneWidget);
    expect(find.text(example.MenuSelection.resetMessage.label), findsOneWidget);
    expect(find.text('Background Color'), findsOneWidget);
    expect(find.text(example.MenuSelection.colorRed.label), findsOneWidget);
    expect(find.text(example.MenuSelection.colorGreen.label), findsOneWidget);
    expect(find.text(example.MenuSelection.colorBlue.label), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text(example.kMessage), findsOneWidget);
    expect(find.text('Last Selected: ${example.MenuSelection.showMessage.label}'), findsOneWidget);
  });
  testWidgets('Shortcuts work', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MenuBarApp(),
    );

    await tester.tap(find.byType(MenuBarButton).first);
    await tester.pump();

    expect(find.text(example.kMessage), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text(example.kMessage), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.text(example.kMessage), findsNothing);
    expect(find.text('Last Selected: ${example.MenuSelection.resetMessage.label}'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text('Last Selected: ${example.MenuSelection.colorRed.label}'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text('Last Selected: ${example.MenuSelection.colorGreen.label}'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text('Last Selected: ${example.MenuSelection.colorBlue.label}'), findsOneWidget);
  });
}

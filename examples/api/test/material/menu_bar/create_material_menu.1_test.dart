// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/material/menu_bar/create_material_menu.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can open menu', (WidgetTester tester) async {
    Finder findMenu() {
      return find.ancestor(of: find.text(example.MenuSelection.about.label), matching: find.byType(FocusScope)).first;
    }

    await tester.pumpWidget(
      const example.MenuBarApp(),
    );

    await tester.tapAt(const Offset(100, 200), buttons: kSecondaryButton);
    await tester.pump();

    expect(tester.getRect(findMenu()), equals(const Rect.fromLTRB(100.0, 200.0, 404.0, 400.0)));

    // Make sure tapping in a different place causes the menu to move.
    await tester.tapAt(const Offset(200, 100), buttons: kSecondaryButton);
    await tester.pump();

    expect(tester.getRect(findMenu()), equals(const Rect.fromLTRB(200.0, 100.0, 504.0, 300.0)));

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

    await tester.tap(find.text('Background Color'));
    await tester.pump();

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

    await tester.tapAt(const Offset(100, 100), buttons: kSecondaryButton);
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

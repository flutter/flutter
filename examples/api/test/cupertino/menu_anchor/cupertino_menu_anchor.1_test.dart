// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/cupertino/menu_anchor/cupertino_menu_anchor.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // These tests were copied from the Material version of this sample and
  // adapted to work with a menu without submenus.
  testWidgets('Menu opens and displays items', (WidgetTester tester) async {
    Finder findMenu() {
      return find.ancestor(
            of: find.text(example.MenuEntry.about.label),
            matching: find.byType(FocusScope),
          )
          .first;
    }

    await tester.pumpWidget(const example.CupertinoMenuApp());
    await tester.tap(find.byType(TextButton));

    // Pump one frame: the menu should mount
    await tester.pump();

    expect(find.text(example.MenuEntry.about.label), findsOneWidget);
    expect(find.text(example.MenuEntry.showMessage.label), findsOneWidget);
    expect(find.text(example.MenuEntry.hideMessage.label), findsNothing);
    expect(find.text(example.MenuEntry.colorRed.label), findsOneWidget);
    expect(find.text(example.MenuEntry.colorGreen.label), findsOneWidget);
    expect(find.text(example.MenuEntry.colorBlue.label), findsOneWidget);
    expect(find.text(example.CupertinoMenuApp.kMessage), findsNothing);

    // Finish animating
    await tester.pumpAndSettle();

    // TODO(davidhicks980): Remove this conditional if/when layout differences
    // are resolved. https://github.com/flutter/flutter/issues/102332
    if (!isBrowser) {
      expect(tester.getRect(findMenu()),
          rectMoreOrLessEquals(const Rect.fromLTRB(8.0, 48.0, 258.0, 351.7), epsilon: 0.1));
    }

    // Tap outside the menu to close it
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(find.text(example.MenuEntry.about.label), findsNothing);
  });
  testWidgets('Menu displays a message when showMessage is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CupertinoMenuApp(),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();


    // About
    // TODO(davidhicks980): Remove conditional when focus differences are
    // resolved, https://github.com/flutter/flutter/issues/147770
    if (isBrowser) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    } else {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }

    // Show Message
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    // Red Background
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    // Show Message
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text(example.CupertinoMenuApp.kMessage), findsOneWidget);
    expect(find.text('Last Selected: ${example.MenuEntry.showMessage.label}'), findsOneWidget);
  });

  testWidgets('Shortcuts work', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CupertinoMenuApp(),
    );

    // Open the menu so we can watch state changes resulting from the shortcuts
    // firing.
    await tester.tap(find.byType(TextButton));
    await tester.pump();

    expect(find.text(example.MenuEntry.showMessage.label), findsOneWidget);
    expect(find.text(example.MenuEntry.hideMessage.label), findsNothing);
    expect(find.text(example.CupertinoMenuApp.kMessage), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    // Need to pump twice because of the one frame delay in the notification to
    // update the overlay entry.
    await tester.pump();

    expect(find.text(example.MenuEntry.showMessage.label), findsNothing);
    expect(find.text(example.MenuEntry.hideMessage.label), findsOneWidget);
    expect(find.text(example.CupertinoMenuApp.kMessage), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump();

    expect(find.text(example.MenuEntry.showMessage.label), findsOneWidget);
    expect(find.text(example.MenuEntry.hideMessage.label), findsNothing);
    expect(find.text(example.CupertinoMenuApp.kMessage), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text('Last Selected: ${example.MenuEntry.colorRed.label}'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text('Last Selected: ${example.MenuEntry.colorGreen.label}'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(find.text('Last Selected: ${example.MenuEntry.colorBlue.label}'), findsOneWidget);
  });

  testWidgets('MenuAnchor is wrapped in a SafeArea', (WidgetTester tester) async {
    const double safeAreaPadding = 100.0;
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          padding: EdgeInsets.symmetric(vertical: safeAreaPadding),
        ),
        child: example.CupertinoMenuApp(),
      ),
    );

    expect(tester.getTopLeft(find.byType(CupertinoMenuAnchor)), const Offset(0.0, safeAreaPadding));
  });
}

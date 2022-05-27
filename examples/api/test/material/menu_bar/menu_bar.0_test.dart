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
    expect(menuBar.menus, isNotEmpty);
    expect(menuBar.menus.length, equals(1));

    final Finder menuButtonFinder = find.byType(MenuBarItem).first;
    await tester.tap(menuButtonFinder);
    await tester.pump();

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Show Message'), findsOneWidget);
    expect(find.text('Background Color'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(find.text('Red Background'), findsNothing);
    expect(find.text('Green Background'), findsNothing);
    expect(find.text('Blue Background'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Show Message'), findsOneWidget);
    expect(find.text('Background Color'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(find.text('Red Background'), findsOneWidget);
    expect(find.text('Green Background'), findsOneWidget);
    expect(find.text('Blue Background'), findsOneWidget);
    expect(find.text('Message'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('"Talk less. Smile more." - A. Burr'), findsOneWidget);
  });
}

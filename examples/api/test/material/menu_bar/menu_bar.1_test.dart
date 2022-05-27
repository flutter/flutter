// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/material/menu_bar/menu_bar.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Menu contains the right things', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(child: example.MenuApp()),
      ),
    );

    final Finder menuBarFinder = find.byType(MenuBar);
    final MenuBar menuBar = tester.widget<MenuBar>(menuBarFinder);
    expect(menuBar.menus, isNotEmpty);
    expect(menuBar.menus.length, equals(2));

    final Finder menuButtonFinder = find.byType(MenuBarItem).first;
    await tester.tap(menuButtonFinder);
    await tester.pump();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Save As...'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
  });
}

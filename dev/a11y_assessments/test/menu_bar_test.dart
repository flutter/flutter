// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('menu bar can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, MenuBarUseCase());
    expect(find.byType(MenuBar), findsExactly(2));

    // Test the enabled menu bar
    {
      final Finder finder = find.byKey(const Key('enabled menu bar'));
      final Finder fileMenu = find.descendant(
        of: finder,
        matching: find.widgetWithText(SubmenuButton, 'File'),
      );
      await tester.tap(fileMenu);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(MenuItemButton, 'Save'), findsWidgets);
      await tester.tap(find.widgetWithText(MenuItemButton, 'Save').last, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // Test the disabled menu bar
    {
      final Finder finder = find.byKey(const Key('disabled menu bar'));
      final SubmenuButton disabledSubmenu = tester.widget<SubmenuButton>(
        find.descendant(of: finder, matching: find.byType(SubmenuButton)),
      );
      expect(disabledSubmenu.menuChildren, isEmpty);

      final MenuItemButton disabledItem = tester.widget<MenuItemButton>(
        find.descendant(of: finder, matching: find.byType(MenuItemButton)),
      );
      expect(disabledItem.onPressed, isNull);
    }
  });

  testWidgets('menu bar demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, MenuBarUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('MenuBar Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}

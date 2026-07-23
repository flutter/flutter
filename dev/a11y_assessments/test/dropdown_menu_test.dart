// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('dropdown menu can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, DropdownMenuUseCase());
    expect(find.byType(DropdownMenu<String>), findsExactly(2));

    // Test the enabled dropdown menu
    {
      final Finder finder = find.byKey(const Key('enabled dropdown menu'));
      await tester.tap(
        find.descendant(of: finder, matching: find.byIcon(Icons.arrow_drop_down)).first,
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(MenuItemButton, 'banana'), findsWidgets);
      await tester.tap(find.widgetWithText(MenuItemButton, 'banana').last, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // Test the disabled dropdown menu
    {
      final Finder finder = find.byKey(const Key('disabled dropdown menu'));
      final DropdownMenu<String> dropdownMenu = tester.widget<DropdownMenu<String>>(finder);
      expect(dropdownMenu.enabled, isFalse);
    }
  });

  testWidgets('dropdown menu demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, DropdownMenuUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('DropdownMenu Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/menu_anchor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('menu anchor can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, MenuAnchorUseCase());
    expect(find.byType(MenuAnchor), findsExactly(2));

    // Test the enabled menu anchor
    {
      final Finder finder = find.byKey(const Key('enabled menu anchor'));
      final Finder button = find.descendant(of: finder, matching: find.byType(ElevatedButton));
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(MenuItemButton, 'Item 1'), findsWidgets);
      await tester.tap(find.widgetWithText(MenuItemButton, 'Item 1').last, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // Test the disabled menu anchor
    {
      final Finder finder = find.byKey(const Key('disabled menu anchor'));
      final Finder button = find.descendant(of: finder, matching: find.byType(ElevatedButton));
      final ElevatedButton elevatedButton = tester.widget<ElevatedButton>(button);
      expect(elevatedButton.enabled, isFalse);
    }
  });

  testWidgets('menu anchor demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, MenuAnchorUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('MenuAnchor Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}

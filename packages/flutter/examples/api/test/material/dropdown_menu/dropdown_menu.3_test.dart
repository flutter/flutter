// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/dropdown_menu/dropdown_menu.3.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Selecting an entry updates the text field and state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.DropdownMenuClearExampleApp());

    expect(find.text('Selected: None'), findsOne);
    expect(find.widgetWithText(TextField, ''), findsOne);

    // Open menu and select Green.
    await tester.tap(find.byType(DropdownMenu<example.ColorItem>));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MenuItemButton, 'Green').last);
    await tester.pumpAndSettle();

    expect(find.text('Selected: Green'), findsOne);
    expect(find.widgetWithText(TextField, 'Green'), findsOne);
  });

  testWidgets(
    'Pressing clear selection button resets the text field and state',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.DropdownMenuClearExampleApp());

      // Open menu and select Blue.
      await tester.tap(find.byType(DropdownMenu<example.ColorItem>));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MenuItemButton, 'Blue').last);
      await tester.pumpAndSettle();

      expect(find.text('Selected: Blue'), findsOne);
      expect(find.widgetWithText(TextField, 'Blue'), findsOne);

      // Tap clear button.
      await tester.tap(find.widgetWithText(FilledButton, 'Clear selection'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: None'), findsOne);
      expect(find.widgetWithText(TextField, ''), findsOne);
    },
  );
}

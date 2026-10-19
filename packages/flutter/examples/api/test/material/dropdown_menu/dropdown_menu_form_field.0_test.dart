// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/dropdown_menu/dropdown_menu_form_field.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DropdownMenuFormField leading icon and form validation test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.DropdownMenuFormFieldApp());

    // Verify DropdownMenuFormField renders with leading icon.
    expect(find.byType(DropdownMenuFormField<String>), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.byIcon(Icons.person),
      ),
      findsOneWidget,
    );
    expect(find.text('User Role'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.text('User Role'),
      ),
      findsOneWidget,
    );

    // Tap submit without selecting a role -> validation error displays.
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Please select a role'), findsOneWidget);

    // Open dropdown and select a role.
    await tester.tap(find.byType(DropdownMenuFormField<String>));
    await tester.pumpAndSettle();

    final Finder adminOption = find
        .widgetWithText(MenuItemButton, 'Admin')
        .last;
    expect(adminOption, findsOneWidget);
    await tester.tap(adminOption);
    await tester.pumpAndSettle();

    // Tap submit again -> validation passes and SnackBar appears.
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Please select a role'), findsNothing);
    expect(find.text('Selected role: Admin'), findsOneWidget);

    // Leading icon is still present.
    expect(find.byIcon(Icons.person), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.byIcon(Icons.person),
      ),
      findsOneWidget,
    );
  });
}

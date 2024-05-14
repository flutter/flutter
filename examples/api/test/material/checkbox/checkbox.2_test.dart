// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/checkbox/checkbox.2.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Checkbox can be checked', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CheckboxExampleApp(),
    );

    Checkbox checkbox = tester.widget(find.byType(Checkbox));

    // Verify the initial state of the checkboxes.
    expect(checkbox.value, isTrue);
    expect(checkbox.tristate, isTrue);

    // Tap the Checkbox and verify the state change.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    checkbox = tester.widget(find.byType(Checkbox));

    expect(checkbox.value, isNull);

    // Tap the Checkbox and verify the state change.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    checkbox = tester.widget(find.byType(Checkbox));

    expect(checkbox.value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    checkbox = tester.widget(find.byType(Checkbox));

    expect(checkbox.value, isTrue);
  });

  testWidgets('Show adaptive checkbox theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.CheckboxExampleApp(),
    );

    // Default is material style checkboxes.
    expect(find.text('Show cupertino style'), findsOneWidget);
    expect(find.text('Show material style'), findsNothing);

    Finder adaptiveCheckbox = find.byType(Checkbox);
    expect(
      adaptiveCheckbox,
      paints
        ..path(color: const Color(0xff6750a4)) // M3 primary color.
        ..rrect(color: Colors.transparent) // Box color.
        ..path(color: Colors.white), // Check color.
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add customization'));
    await tester.pumpAndSettle();

    // Theme adaptation does not affect material-style switch.
    adaptiveCheckbox = find.byType(Checkbox);
    expect(
      adaptiveCheckbox,
      paints
        ..path(color: const Color(0xff6750a4))
        ..rrect(color: Colors.transparent)
        ..path(color: Colors.white),
    );

    await tester
        .tap(find.widgetWithText(OutlinedButton, 'Show cupertino style'));
    await tester.pumpAndSettle();

    expect(
      adaptiveCheckbox,
      paints
        ..path(color: const Color(0xfff44336))
        ..rrect(color: Colors.transparent)
        ..path(color: Colors.white),
    );
    await tester.pump();
    await tester
        .tap(find.widgetWithText(OutlinedButton, 'Remove customization'));
    await tester.pumpAndSettle();

    expect(
      adaptiveCheckbox,
      paints
        ..path(color: const Color(0xff007aff)) // Cupertino design blue.
        ..rrect(color: Colors.transparent)
        ..path(color: Colors.white),
    );
  });
}

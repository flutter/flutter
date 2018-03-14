// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/material/text_form_field_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('validates name field correctly', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(home: const TextFormFieldDemo()));

    final Finder submitButton = find.widgetWithText(RaisedButton, 'SUBMIT');
    expect(submitButton, findsOneWidget);

    final Finder nameField = find.widgetWithText(TextFormField, 'Name *');
    expect(nameField, findsOneWidget);

    final Finder passwordField = find.widgetWithText(TextFormField, 'Password *');
    expect(passwordField, findsOneWidget);

    await tester.enterText(nameField, '');
    // The submit button isn't initially visible. Drag it into view so that
    // it will see the tap.
    await tester.drag(nameField, const Offset(0.0, -1200.0));
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Now drag the password field (the submit button will be obscured by
    // the snackbar) and expose the name field again.
    await tester.drag(passwordField, const Offset(0.0, 1200.0));
    await tester.pumpAndSettle();
    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Please enter only alphabetical characters.'), findsNothing);
    await tester.enterText(nameField, '#');

    // Make the submit button visible again (by dragging the name field), so
    // it will see the tap.
    await tester.drag(nameField, const Offset(0.0, -1200.0));
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Name is required.'), findsNothing);
    expect(find.text('Please enter only alphabetical characters.'), findsOneWidget);

    await tester.enterText(nameField, 'Jane Doe');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Name is required.'), findsNothing);
    expect(find.text('Please enter only alphabetical characters.'), findsNothing);
  });
}

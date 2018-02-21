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

    await tester.enterText(nameField, '');
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Please enter only alphabetical characters.'), findsNothing);

    await tester.enterText(nameField, '#');
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('Name is required.'), findsNothing);
    expect(find.text('Please enter only alphabetical characters.'), findsOneWidget);

    await tester.enterText(nameField, 'Jane Doe');
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('Name is required.'), findsNothing);
    expect(find.text('Please enter only alphabetical characters.'), findsNothing);
  });
}

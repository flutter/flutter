// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/autocomplete/autocomplete.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('can search and find options by email and name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.AutocompleteExampleApp());

    expect(find.text('Alice'), findsNothing);
    expect(find.text('Bob'), findsNothing);
    expect(find.text('Charlie'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Ali');
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
    expect(find.text('Charlie'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'gmail');
    await tester.pump();

    expect(find.text('Alice'), findsNothing);
    expect(find.text('Bob'), findsNothing);
    expect(find.text('Charlie'), findsOneWidget);
  });
}

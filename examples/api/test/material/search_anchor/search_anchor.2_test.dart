// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/search_anchor/search_anchor.2.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Suggestion of the search bar can be selected', (WidgetTester tester) async {
    await tester.pumpWidget(const example.SearchBarApp());

    expect(find.widgetWithText(AppBar, 'Search Anchor Sample'), findsOne);
    expect(find.text('No item selected'), findsOne);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    for (int i = 0; i < 5; i++) {
      expect(find.widgetWithText(ListTile, 'item $i'), findsOne);
    }

    await tester.tap(find.text('item 2'));
    await tester.pumpAndSettle();

    expect(find.text('Selected item: item 2'), findsOne);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'item 3'));
    await tester.pumpAndSettle();

    expect(find.text('Selected item: item 3'), findsOne);
  });
}

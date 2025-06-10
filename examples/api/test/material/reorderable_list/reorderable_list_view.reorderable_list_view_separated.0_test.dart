// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/reorderable_list/reorderable_list_view.reorderable_list_view_separated.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReorderableListView with separators', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ReorderableApp());

    // Verify the app bar is present
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('ReorderableListView Sample'), findsOneWidget);

    // Verify the reorderable list view is present
    expect(find.byType(ReorderableListView), findsOneWidget);

    // Verify some list items are present
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);

    // Verify dividers (separators) are present
    expect(find.byType(Divider), findsWidgets);
  });
}

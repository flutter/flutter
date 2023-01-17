// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/expansion_tile/expansion_tile.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Renders ExpansionTile.single Widget',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: example.MyApp(),
        ),
      ),
    );
    expect(find.text('Expansion tile with fixed height Scrollable content'),
        findsOneWidget);
    expect(find.byType(ExpansionTile), findsWidgets);
    final Finder icon = find.byIcon(Icons.expand_more);
    expect(icon.first, findsOneWidget);
    await tester.tap(icon.first);
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/material/expansion_tile/expansion_tile.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpansionTiles can be expanded', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExpansionTileApp(),
    );

    // Expand/Collapse ExpansionTile 1.
    await tester.tap(find.text('ExpansionTile 1'));
    await tester.pumpAndSettle();
    expect(find.text('This is tile number 1'), findsOneWidget);
    await tester.tap(find.text('ExpansionTile 1'));
    await tester.pumpAndSettle();
    expect(find.text('This is tile number 1'), findsNothing);

    // Expand/Collapse ExpansionTile 2.
    await tester.tap(find.text('ExpansionTile 2'));
    await tester.pumpAndSettle();
    expect(find.text('This is tile number 2'), findsOneWidget);
    await tester.tap(find.text('ExpansionTile 2'));
    await tester.pumpAndSettle();
    expect(find.text('This is tile number 2'), findsNothing);

    // Expand/Collapse ExpansionTile 3.
    await tester.tap(find.text('ExpansionTile 3'));
    await tester.pumpAndSettle();
    expect(find.text('This is tile number 3'), findsOneWidget);
    await tester.tap(find.text('ExpansionTile 3'));
    await tester.pumpAndSettle();
    expect(find.text('This is tile number 3'), findsNothing);
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/material/expansion_tile/expansion_tile.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpansionTiles can be expanded', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExpansionTileApp(),
    );

    // Expand/Collapse ExpansionTile.
    await tester.tap(find.text('ExpansionTile'));
    await tester.pumpAndSettle();
    expect(find.text('Item 3'), findsOneWidget);
    await tester.tap(find.text('ExpansionTile'));
    await tester.pumpAndSettle();
    expect(find.text('Item 3'), findsNothing);
  });
}

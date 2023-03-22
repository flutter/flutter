// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/expansion_tile/expansion_tile.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('When expansion tiles are expanded tile numbers are revealed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExpansionTileControllerApp(),
    );

    expect(find.byType(ExpansionTile), findsOneWidget);

    expect(find.text('Collapse This Tile'), findsNothing);

    await tester.tap(find.text('ExpansionTile'));
    await tester.pumpAndSettle();
    expect(find.text('Collapse This Tile'), findsOneWidget);

    await tester.tap(find.text('Collapse This Tile'));
    await tester.pumpAndSettle();
    expect(find.text('Collapse This Tile'), findsNothing);
  });
}

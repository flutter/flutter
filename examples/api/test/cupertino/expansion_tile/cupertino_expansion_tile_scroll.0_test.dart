// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/cupertino/expansion_tile/cupertino_expansion_tile_scroll.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'CupertinoExpansionTile scroll transition expands and collapses correctly',
      (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CupertinoExpansionTileScrollApp());

    // Initial state: collapsed
    expect(find.text('Tap to expand'), findsOneWidget);
    expect(find.textContaining('expanded content'), findsNothing);

    // Tap the tile to expand
    await tester.tap(find.text('Tap to expand'));
    await tester.pumpAndSettle(); // Wait for animation to finish

    expect(find.text('Collapse me'), findsOneWidget);
    expect(find.textContaining('expanded content'), findsOneWidget);

    // Tap the tile to collapse
    await tester.tap(find.text('Collapse me'));
    await tester.pumpAndSettle(); // Wait for animation to finish

    expect(find.text('Tap to expand'), findsOneWidget);
    expect(find.textContaining('expanded content'), findsNothing);
  });
}

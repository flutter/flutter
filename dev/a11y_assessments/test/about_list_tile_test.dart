// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/about_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('about list tile can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, AboutListTileUseCase());
    expect(find.byType(AboutListTile), findsOneWidget);
  });

  testWidgets('about list tile can open dialog', (WidgetTester tester) async {
    await pumpsUseCase(tester, AboutListTileUseCase());

    final Finder findTile = find.byType(AboutListTile);
    expect(findTile, findsOneWidget);
    await tester.tap(findTile);
    await tester.pumpAndSettle();

    expect(find.byType(AboutDialog), findsOneWidget);
  });
}

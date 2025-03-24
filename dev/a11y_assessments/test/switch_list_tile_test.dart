// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('switch list can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, SwitchListTileUseCase());
    expect(find.byType(SwitchListTile), findsExactly(2));
  });

  testWidgets('switch list demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, SwitchListTileUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('SwitchListTile Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}

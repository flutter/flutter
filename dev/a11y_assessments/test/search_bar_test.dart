// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('search bar can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, SearchBarUseCase());
    expect(find.byType(SearchBar), findsExactly(2));

    // Test the enabled search bar
    {
      final Finder finder = find.byKey(const Key('enabled search bar'));
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await tester.enterText(finder, 'abc');
      await tester.pumpAndSettle();
      expect(find.text('abc'), findsOneWidget);
    }

    // Test the disabled search bar
    {
      final Finder finder = find.byKey(const Key('disabled search bar'));
      final SearchBar searchBar = tester.widget<SearchBar>(finder);
      expect(searchBar.enabled, isFalse);
    }
  });

  testWidgets('search bar demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, SearchBarUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('SearchBar Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}

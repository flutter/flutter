// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/search_anchor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  Finder findSearchAnchors() => find.byWidgetPredicate((Widget w) => w is SearchAnchor);

  testWidgets('search anchor can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, SearchAnchorUseCase());
    expect(findSearchAnchors(), findsExactly(2));

    // Test the enabled search anchor
    {
      final Finder finder = find.descendant(
        of: find.byKey(const Key('enabled search anchor')),
        matching: findSearchAnchors(),
      );
      await tester.tap(finder);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'app');
      await tester.pumpAndSettle();
      expect(find.text('apple'), findsOneWidget);

      await tester.tap(find.text('apple'));
      await tester.pumpAndSettle();
    }

    // Test the disabled search anchor
    {
      final Finder finder = find.descendant(
        of: find.byKey(const Key('disabled search anchor')),
        matching: findSearchAnchors(),
      );
      final SearchAnchor searchAnchor = tester.widget<SearchAnchor>(finder);
      expect(searchAnchor.enabled, isFalse);
    }
  });

  testWidgets('search anchor demo page has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, SearchAnchorUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('SearchAnchor Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });
}

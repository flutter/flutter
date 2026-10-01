// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/badge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('badge can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, BadgeUseCase());
    expect(find.semantics.byLabel('5 new messages'), findsOne);
    expect(find.semantics.byLabel('Messages'), findsOne);
  });

  testWidgets('badge has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, BadgeUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel(RegExp('Badge Demo'));
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });

  // The badge label carries a `semanticsLabel` that differs from the rendered
  // text, so `textContrastGuideline` cannot locate it and silently skips it.
  // Check the label explicitly with a finder based guideline instead.
  // Regression test for https://github.com/flutter/flutter/issues/172993.
  testWidgets('badge label meets text contrast guideline', (WidgetTester tester) async {
    await pumpsUseCase(tester, BadgeUseCase());
    await expectLater(
      tester,
      meetsGuideline(CustomMinimumContrastGuideline(finder: find.text('5'))),
    );
  });
}

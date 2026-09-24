// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/main.dart';
import 'package:a11y_assessments/use_cases/material_banner.dart';
import 'package:a11y_assessments/use_cases/use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('material banner can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, MaterialBannerUseCase());
    expect(find.text('Show a MaterialBanner'), findsOneWidget);

    await tester.tap(find.text('Show a MaterialBanner'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, I am a Material Banner'), findsOneWidget);

    await tester.tap(find.text('DISMISS'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, I am a Material Banner'), findsNothing);
  });

  testWidgets('dismiss button focused on banner open', (WidgetTester tester) async {
    await pumpsUseCase(tester, MaterialBannerUseCase());
    await tester.tap(find.text('Show a MaterialBanner'));
    await tester.pumpAndSettle();

    final TextButton dismissButtonFinder = tester.widget<TextButton>(find.byType(TextButton));
    expect(dismissButtonFinder.focusNode!.hasFocus, isTrue);
  });

  testWidgets('show button focused on banner close', (WidgetTester tester) async {
    await pumpsUseCase(tester, MaterialBannerUseCase());
    await tester.tap(find.text('Show a MaterialBanner'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextButton));

    final ElevatedButton showButtonFinder = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(showButtonFinder.focusNode!.hasFocus, isTrue);
  });

  testWidgets('material banner has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, MaterialBannerUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('MaterialBanner Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });

  testWidgets('material banner does not outlive its page', (WidgetTester tester) async {
    await tester.pumpWidget(const App(initialTags: <Tag>{}));

    final Finder useCaseButton = find.byKey(Key(MaterialBannerUseCase().name));
    await tester.scrollUntilVisible(useCaseButton, 300);
    await tester.tap(useCaseButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show a MaterialBanner'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, I am a Material Banner'), findsOneWidget);

    // Navigate back to the home page without dismissing the banner.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Accessibility Assessments'), findsOneWidget);

    // The banner belongs to the page, so it must go away with the page instead
    // of staying on the home page where its dismiss button would use the
    // page's disposed focus nodes and unmounted state.
    expect(find.text('Hello, I am a Material Banner'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

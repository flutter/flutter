// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('floating action button has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, FloatingActionButtonUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel(RegExp('FloatingActionButton Demo'));
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });

  testWidgets('floating action button can increment tap count', (WidgetTester tester) async {
    await pumpsUseCase(tester, FloatingActionButtonUseCase());

    expect(find.text('Tap count: 0'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Tap count: 1'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Tap count: 2'), findsOneWidget);
  });
}

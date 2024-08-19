// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/navigation_bar.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('navigation bar can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, NavigationBarUseCase());
    expect(find.text('Page 1'), findsOneWidget);

    await tester.tap(find.text('Business'));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);

    await tester.tap(find.text('School'));
    await tester.pumpAndSettle();
    expect(find.text('Page 3'), findsOneWidget);
  });

  testWidgets('navigation bar has one h1 tag', (WidgetTester tester) async {
    await pumpsUseCase(tester, NavigationBarUseCase());
    final Finder findHeadingLevelOnes = find.bySemanticsLabel('NavigationBar Demo');
    await tester.pumpAndSettle();
    expect(findHeadingLevelOnes, findsOne);
  });

  // testWidgets('navigation bar has one selected tab', (WidgetTester tester) async {
  //   await pumpsUseCase(tester, NavigationBarUseCase());
  //   final Finder findHeadingLevelOnes = find.bySemanticsLabel('NavigationBar Demo');
  //   await tester.pumpAndSettle();
  //   expect(findHeadingLevelOnes, findsOne);
  // });

  testWidgets('navigation bar has one selected tab with correct aria-label', (WidgetTester tester) async {
    await pumpsUseCase(tester, NavigationBarUseCase());
    await tester.pumpAndSettle();

    final Finder selectedTabFinder = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byWidgetPredicate((Widget widget) {
        if (widget is Semantics) {
          final SemanticsData semanticsData = widget.toDiagnosticsNode().value! as SemanticsData;
          return semanticsData.label!.contains('selected');
        }
        return false;
      }),
    );

    expect(selectedTabFinder, findsOneWidget);
    debugDumpRenderTree();
  });
}

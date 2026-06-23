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

  testWidgets('floating action button can increment tap count (with supportsAnnounce = true)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(supportsAnnounce: true),
          child: Builder(
            builder: (BuildContext context) {
              return FloatingActionButtonUseCase().buildWithTitle(context);
            },
          ),
        ),
      ),
    );

    expect(find.text('Tap count: 0'), findsOneWidget);
    expect(tester.getSemantics(find.text('Tap count: 0')), matchesSemantics(label: 'Tap count: 0'));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Tap count: 1'), findsOneWidget);
    expect(tester.takeAnnouncements(), <Matcher>[isAccessibilityAnnouncement('Tap count: 1')]);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Tap count: 2'), findsOneWidget);
    expect(tester.takeAnnouncements(), <Matcher>[isAccessibilityAnnouncement('Tap count: 2')]);

    handle.dispose();
  });

  testWidgets(
    'floating action button can increment tap count (with supportsAnnounce = false, using liveRegion)',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(), // defaults to supportsAnnounce = false
            child: Builder(
              builder: (BuildContext context) {
                return FloatingActionButtonUseCase().buildWithTitle(context);
              },
            ),
          ),
        ),
      );

      expect(find.text('Tap count: 0'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Tap count: 0')),
        matchesSemantics(label: 'Tap count: 0', isLiveRegion: true),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('Tap count: 1'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Tap count: 1')),
        matchesSemantics(label: 'Tap count: 1', isLiveRegion: true),
      );
      expect(tester.takeAnnouncements(), isEmpty);

      handle.dispose();
    },
  );
}

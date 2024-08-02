// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/scroll_view/custom_scroll_view.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Combination of two behavoirs: IconButton click and mouse scroll.', () {
    group('Before IconButton click.', () {
      group('Before IconButton click and before mouse scroll.', () {
        testWidgets('What should be visible or not visible in the initial state.', (WidgetTester tester) async {
          await tester.pumpWidget(const example.CustomScrollViewExampleApp());

          expect(find.byType(Scaffold), findsOne);

          expect(
            find.descendant(
              of: find.byType(Scaffold),
              matching: find.byType(AppBar),
            ),
            findsOne,
          );

          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.byType(IconButton),
            ),
            findsOne,
          );

          expect(
            find.descendant(
              of: find.byType(Scaffold),
              matching: find.byType(CustomScrollView),
            ),
            findsOne,
          );

          expect(
            find.descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(SliverList),
            ),
            findsOne,
            reason: 'Expected one, initial (bottom) SliverList in the CustomScrollView.',
          );
          expect(
            find.widgetWithText(SliverList, 'Item: -1'),
            findsNothing,
            reason: 'Initial state should present only "Item: 0" on the SliverList.',
          );
          expect(
            find.widgetWithText(SliverList, 'Item: 0'),
            findsOne,
            reason: 'Initial state should present "Item: 0" on the SliverList.',
          );
          expect(
            find.widgetWithText(SliverList, 'Item: 1'),
            findsNothing,
            reason: 'Initial state should present only "Item: 0" on the SliverList.',
          );
        });
      });
      group('Before IconButton click and after mouse scroll.', () {
        testWidgets('Mouse scroll does not reveal additional SliverList.', (WidgetTester tester) async {
          await tester.pumpWidget(const example.CustomScrollViewExampleApp());

          // Mouse wheel scroll
          final Offset location = tester.getCenter(find.byType(CustomScrollView));
          final TestPointer testPointer = TestPointer(1, PointerDeviceKind.mouse);
          testPointer.hover(location);
          await tester.sendEventToBinding(
            PointerScrollEvent(position: location, scrollDelta: const Offset(0, -1)),
          );
          await tester.pump();

          expect(find.byType(SliverList), findsOne, reason: 'Mouse scroll does not reveal additional SliverList.');
          expect(find.widgetWithText(SliverList, 'Item: -1'), findsNothing);
          expect(find.widgetWithText(SliverList, 'Item: 0'), findsOne);
          expect(find.widgetWithText(SliverList, 'Item: 1'), findsNothing);
        });
      });
    });
    group('After IconButton click.', () {
      group('After IconButton click and before mouse scroll.', () {
        testWidgets('Additional element on the SliverList is shown.', (WidgetTester tester) async {
          await tester.pumpWidget(const example.CustomScrollViewExampleApp());

          await tester.tap(find.byType(IconButton));
          await tester.pump();

          expect(find.widgetWithText(SliverList, 'Item: -1'), findsNothing);
          expect(find.widgetWithText(SliverList, 'Item: 0'), findsOne);
          expect(
            find.widgetWithText(SliverList, 'Item: 1'),
            findsOne,
            reason: 'Additional element on the SliverList is shown.',
          );
        });
        testWidgets('Additional SliverList should not be visible.', (WidgetTester tester) async {
          await tester.pumpWidget(const example.CustomScrollViewExampleApp());

          await tester.tap(find.byType(IconButton));
          await tester.pump();

          expect(
            find.byType(SliverList),
            findsOne,
            reason: 'Additional SliverList should not be visible.',
          );
        });
      });
      group('After IconButton click and after mouse scroll.', () {
        testWidgets('Mouse scroll reveals additonal SliverList.', (WidgetTester tester) async {
          await tester.pumpWidget(const example.CustomScrollViewExampleApp());

          await tester.tap(find.byType(IconButton));
          await tester.pump();

          // Mouse wheel scroll
          final Offset location = tester.getCenter(find.byType(CustomScrollView));
          final TestPointer testPointer = TestPointer(1, PointerDeviceKind.mouse);
          testPointer.hover(location);
          await tester.sendEventToBinding(
            PointerScrollEvent(position: location, scrollDelta: const Offset(0, -1)),
          );
          await tester.pump();

          expect(
            find.byType(SliverList),
            findsExactly(2),
            reason: 'Mouse scroll reveals additonal SliverList.',
          );
          expect(find.widgetWithText(SliverList, 'Item: 0'), findsOne);
          expect(find.widgetWithText(SliverList, 'Item: -1'), findsOne);
          expect(find.widgetWithText(SliverList, 'Item: 1'), findsOne);
        });
      });
    });
  });
}

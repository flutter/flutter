// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('SliverCoordinator basics', (WidgetTester tester) async {
    late CoordinatedSliver sliver;
    ScrollNotification? callbackNotification;
    SliverCoordinatorData? callbackData;

    void sliverCoordinatorCallback(ScrollNotification notification, SliverCoordinatorData data) {
      callbackNotification = notification;
      callbackData = data;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SliverCoordinator(
            callback: sliverCoordinatorCallback,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => SizedBox(height: 100, child: Text('0.$index')),
                    childCount: 8,
                  ),
                ),
                sliver = const CoordinatedSliver(
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(height: 300, child: Text('CoordinatedSliver')),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => SizedBox(height: 100, child: Text('1.$index')),
                    childCount: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Future<void> scrollVertical(double dy) {
      callbackNotification = null;
      callbackData = null;
      return tester.drag(find.byType(CustomScrollView), Offset(0, dy));
    }

    Finder findSizedBox(String text) => find.widgetWithText(SizedBox, text);

    void testSliverConstraints(double scrollOffset, double precedingScrollExtent, double remainingPaintExtent) {
      final SliverConstraints value = sliver.getSliverConstraints(callbackData!);
      expect(value.scrollOffset, scrollOffset);
      expect(value.precedingScrollExtent, precedingScrollExtent);
      expect(value.remainingPaintExtent, remainingPaintExtent);
      expect(value.crossAxisExtent, 800);
      expect(value.viewportMainAxisExtent, 600);
    }

    void testSliverGeometry(double scrollExtent, double paintExtent, double maxPaintExtent) {
      final SliverGeometry value = sliver.getSliverGeometry(callbackData!);
      expect(value.scrollExtent, scrollExtent);
      expect(value.paintExtent, paintExtent);
      expect(value.maxPaintExtent, maxPaintExtent);
    }

    expect(findSizedBox('0.0'), findsOneWidget);
    expect(findSizedBox('0.5'), findsOneWidget);
    expect(findSizedBox('CoordinatedSliver'), findsNothing);

    // No scroll yet, so no callback data or notification.
    expect(callbackData, isNull);
    expect(callbackNotification, isNull);

    // Scroll the coordinated sliver to the top of the viewport
    await scrollVertical(-800);
    await tester.pumpAndSettle();

    expect(tester.getRect(findSizedBox('CoordinatedSliver')), const Rect.fromLTRB(0.0, 0.0, 800.0, 300.0));
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(0, 800, 600);
    testSliverGeometry(300, 300, 300); // paintExtent = 300

    // Scroll the coordinated sliver 50% of the top of the viewport.
    await scrollVertical(-150);
    await tester.pumpAndSettle();

    expect(tester.getRect(findSizedBox('CoordinatedSliver')), const Rect.fromLTRB(0.0, -150.0, 800.0, 150.0));
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(150, 800, 600);
    testSliverGeometry(300, 150, 300); // paintExtent = 150

    // Scroll the remainder of the coordinated sliver off the top of the viewport.
    await scrollVertical(-150);
    await tester.pumpAndSettle();

    expect(findSizedBox('CoordinatedSliver'), findsNothing);

    // Even though the coordinated sliver is no longer visible, it was
    // laid out when the scroll view was scrolled.
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(300, 800, 600);
    testSliverGeometry(300, 0, 300); // paintExent = 0

    // Scroll the coordinated sliver down to the top of the viewport again
    await scrollVertical(300);
    await tester.pumpAndSettle();

    expect(tester.getRect(findSizedBox('CoordinatedSliver')), const Rect.fromLTRB(0.0, 0.0, 800.0, 300.0));
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(0, 800, 600);
    testSliverGeometry(300, 300, 300); // paintExtent = 300
  });

  testWidgets('CoordinatedSliver removed from SliverCoordinatorData', (WidgetTester tester) async {
    late CoordinatedSliver sliver1;
    late CoordinatedSliver sliver2;
    SliverCoordinatorData? callbackData;

    void sliverCoordinatorCallback(ScrollNotification notification, SliverCoordinatorData data) {
      callbackData = data;
    }

    // The sliverHeight parameter is just to avoid analyzer complaints about
    // the CoordinatedSlivers not being const.
    Widget buildFrame(double sliverHeight) {
      return MaterialApp(
        home: Scaffold(
          body: SliverCoordinator(
            callback: sliverCoordinatorCallback,
            child: CustomScrollView(
              slivers: <Widget>[
                sliver1 = CoordinatedSliver(
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: sliverHeight,
                      child: const Text('CoordinatedSliver1')),
                  ),
                ),
                sliver2 = CoordinatedSliver(
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: sliverHeight,
                      child: const Text('CoordinatedSliver2')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(400));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(sliver1.hasLayoutInfo(callbackData!), isTrue);
    expect(sliver2.hasLayoutInfo(callbackData!), isTrue);

    final CoordinatedSliver oldSliver1 = sliver1;
    final CoordinatedSliver oldSliver2 = sliver2;

    await tester.pumpWidget(buildFrame(400));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(oldSliver1.hasLayoutInfo(callbackData!), isFalse);
    expect(oldSliver2.hasLayoutInfo(callbackData!), isFalse);

    expect(sliver1.hasLayoutInfo(callbackData!), isTrue);
    expect(sliver2.hasLayoutInfo(callbackData!), isTrue);

  });
}

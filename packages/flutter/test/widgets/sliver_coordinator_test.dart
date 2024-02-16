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

    // Scroll the sliver to the top of the viewport
    await scrollVertical(-800);
    await tester.pumpAndSettle();

    expect(tester.getRect(findSizedBox('CoordinatedSliver')), const Rect.fromLTRB(0.0, 0.0, 800.0, 300.0));
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(0, 800, 600);
    testSliverGeometry(300, 300, 300); // paintExtent = 300

    // Scroll the sliver 50% of the top of the viewport.
    await scrollVertical(-150);
    await tester.pumpAndSettle();

    expect(tester.getRect(findSizedBox('CoordinatedSliver')), const Rect.fromLTRB(0.0, -150.0, 800.0, 150.0));
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(150, 800, 600);
    testSliverGeometry(300, 150, 300); // paintExtent = 150

    // Scroll the remainder of the sliver off the top of the viewport.
    await scrollVertical(-150);
    await tester.pumpAndSettle();

    expect(findSizedBox('CoordinatedSliver'), findsNothing);

    // Even though the sliver is no longer visible, it was laid out when the
    // scroll view was scrolled.
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(300, 800, 600);
    testSliverGeometry(300, 0, 300); // paintExent = 0

    // Scroll the sliver down to the top of the viewport again
    await scrollVertical(300);
    await tester.pumpAndSettle();

    expect(tester.getRect(findSizedBox('CoordinatedSliver')), const Rect.fromLTRB(0.0, 0.0, 800.0, 300.0));
    expect(callbackData, isNotNull);
    expect(callbackNotification, isNotNull);
    expect(sliver.hasLayoutInfo(callbackData!), isTrue);

    testSliverConstraints(0, 800, 600);
    testSliverGeometry(300, 300, 300); // paintExtent = 300
  });
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Scroll notification basics', (WidgetTester tester) async {
    ScrollNotification notification;

    await tester.pumpWidget(new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification value) {
        notification = value;
        return false;
      },
      child: new ScrollableViewport(
        child: const SizedBox(height: 1200.0)
      )
    ));

    TestGesture gesture = await tester.startGesture(const Point(100.0, 100.0));
    await tester.pump(const Duration(seconds: 1));
    expect(notification.kind, equals(ScrollNotificationKind.started));
    expect(notification.depth, equals(0));
    expect(notification.dragStartDetails, isNotNull);
    expect(notification.dragStartDetails.globalPosition, equals(const Point(100.0, 100.0)));
    expect(notification.dragUpdateDetails, isNull);
    expect(notification.dragEndDetails, isNull);

    await gesture.moveBy(const Offset(-10.0, -10.0));
    await tester.pump(const Duration(seconds: 1));
    expect(notification.kind, equals(ScrollNotificationKind.updated));
    expect(notification.depth, equals(0));
    expect(notification.dragStartDetails, isNull);
    expect(notification.dragUpdateDetails, isNotNull);
    expect(notification.dragUpdateDetails.globalPosition, equals(const Point(90.0, 90.0)));
    expect(notification.dragUpdateDetails.delta, equals(const Offset(0.0, -10.0)));
    expect(notification.dragEndDetails, isNull);

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(notification.kind, equals(ScrollNotificationKind.ended));
    expect(notification.depth, equals(0));
    expect(notification.dragStartDetails, isNull);
    expect(notification.dragUpdateDetails, isNull);
    expect(notification.dragEndDetails, isNotNull);
    expect(notification.dragEndDetails.velocity, equals(Velocity.zero));
  });

  testWidgets('Scroll notification depth', (WidgetTester tester) async {
    final List<ScrollNotificationKind> depth0Kinds = <ScrollNotificationKind>[];
    final List<ScrollNotificationKind> depth1Kinds = <ScrollNotificationKind>[];
    final List<int> depth0Values = <int>[];
    final List<int> depth1Values = <int>[];

    await tester.pumpWidget(new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification value) {
        depth1Kinds.add(value.kind);
        depth1Values.add(value.depth);
        return false;
      },
      child: new ScrollableViewport(
        child: new SizedBox(
          height: 1200.0,
          child: new NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification value) {
              depth0Kinds.add(value.kind);
              depth0Values.add(value.depth);
              return false;
            },
            child: new Container(
              padding: const EdgeInsets.all(50.0),
              child: new ScrollableViewport(child: const SizedBox(height: 1200.0))
            )
          )
        )
      )
    ));

    TestGesture gesture = await tester.startGesture(const Point(100.0, 100.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveBy(const Offset(-10.0, -10.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    final List<ScrollNotificationKind> kinds = <ScrollNotificationKind>[
      ScrollNotificationKind.started,
      ScrollNotificationKind.updated,
      ScrollNotificationKind.ended
    ];
    expect(depth0Kinds, equals(kinds));
    expect(depth1Kinds, equals(kinds));

    expect(depth0Values, equals(<int>[0, 0, 0]));
    expect(depth1Values, equals(<int>[1, 1, 1]));
  });
}

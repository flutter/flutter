// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScrollMetricsNotification test', (WidgetTester tester) async {
    final List<Notification> events = <Notification>[];
    Widget buildFrame(double height) {
      return NotificationListener<Notification>(
        onNotification: (Notification value) {
          events.add(value);
          return false;
        },
        child: SingleChildScrollView(
          child: SizedBox(height: height),
        ),
      );
    }
    await tester.pumpWidget(buildFrame(1200.0));
    expect(events.length, 1);

    events.clear();
    await tester.pumpWidget(buildFrame(1000.0));
    // Change the content dimensions will trigger a new event.
    expect(events.length, 1);
    ScrollMetricsNotification event = events[0] as ScrollMetricsNotification;
    expect(event.metrics.extentBefore, 0.0);
    expect(event.metrics.extentInside, 600.0);
    expect(event.metrics.extentAfter, 400.0);

    events.clear();
    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    expect(events.length, 1);
    // user scroll do not trigger the ScrollContentMetricsNotification.
    expect(events[0] is ScrollStartNotification, true);

    events.clear();
    await gesture.moveBy(const Offset(-10.0, -10.0));
    expect(events.length, 2);
    // User scroll do not trigger the ScrollContentMetricsNotification.
    expect(events[0] is UserScrollNotification, true);
    expect(events[1] is ScrollUpdateNotification, true);

    events.clear();
    // Change the content dimensions again.
    await tester.pumpWidget(buildFrame(500.0));
    expect(events.length, 1);
    event = events[0] as ScrollMetricsNotification;
    expect(event.metrics.extentBefore, 10.0);
    expect(event.metrics.extentInside, 590.0);
    expect(event.metrics.extentAfter, 0.0);

    events.clear();
    // The content dimensions does not change.
    await tester.pumpWidget(buildFrame(500.0));
    expect(events.length, 0);
  });

  testWidgets('Scroll notification basics', (WidgetTester tester) async {
    late ScrollNotification notification;

    await tester.pumpWidget(NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification value) {
        if (value is ScrollStartNotification || value is ScrollUpdateNotification || value is ScrollEndNotification) {
          notification = value;
        }
        return false;
      },
      child: const SingleChildScrollView(
        child: SizedBox(height: 1200.0),
      ),
    ));

    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await tester.pump(const Duration(seconds: 1));
    expect(notification, isA<ScrollStartNotification>());
    expect(notification.depth, equals(0));
    final ScrollStartNotification start = notification as ScrollStartNotification;
    expect(start.dragDetails, isNotNull);
    expect(start.dragDetails!.globalPosition, equals(const Offset(100.0, 100.0)));

    await gesture.moveBy(const Offset(-10.0, -10.0));
    await tester.pump(const Duration(seconds: 1));
    expect(notification, isA<ScrollUpdateNotification>());
    expect(notification.depth, equals(0));
    final ScrollUpdateNotification update = notification as ScrollUpdateNotification;
    expect(update.dragDetails, isNotNull);
    expect(update.dragDetails!.globalPosition, equals(const Offset(90.0, 90.0)));
    expect(update.dragDetails!.delta, equals(const Offset(0.0, -10.0)));

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(notification, isA<ScrollEndNotification>());
    expect(notification.depth, equals(0));
    final ScrollEndNotification end = notification as ScrollEndNotification;
    expect(end.dragDetails, isNotNull);
    expect(end.dragDetails!.velocity, equals(Velocity.zero));
  });

  testWidgets('Scroll notification depth', (WidgetTester tester) async {
    final List<Type> depth0Types = <Type>[];
    final List<Type> depth1Types = <Type>[];
    final List<int> depth0Values = <int>[];
    final List<int> depth1Values = <int>[];

    await tester.pumpWidget(NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification value) {
        depth1Types.add(value.runtimeType);
        depth1Values.add(value.depth);
        return false;
      },
      child: SingleChildScrollView(
        dragStartBehavior: DragStartBehavior.down,
        child: SizedBox(
          height: 1200.0,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification value) {
              depth0Types.add(value.runtimeType);
              depth0Values.add(value.depth);
              return false;
            },
            child: Container(
              padding: const EdgeInsets.all(50.0),
              child: const SingleChildScrollView(
                dragStartBehavior: DragStartBehavior.down,
                child: SizedBox(height: 1200.0),
              ),
            ),
          ),
        ),
      ),
    ));

    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveBy(const Offset(-10.0, -40.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    final List<Type> types = <Type>[
      ScrollStartNotification,
      UserScrollNotification,
      ScrollUpdateNotification,
      ScrollEndNotification,
      UserScrollNotification,
    ];
    expect(depth0Types, equals(types));
    expect(depth1Types, equals(types));

    expect(depth0Values, equals(<int>[0, 0, 0, 0, 0]));
    expect(depth1Values, equals(<int>[1, 1, 1, 1, 1]));
  });

  testWidgets('ScrollNotifications bubble past Scaffold Material', (WidgetTester tester) async {
    final List<Type> notificationTypes = <Type>[];

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification value) {
            notificationTypes.add(value.runtimeType);
            return false;
          },
          child: Scaffold(
            body: SizedBox.expand(
              child: SingleChildScrollView(
                dragStartBehavior: DragStartBehavior.down,
                child: SizedBox(
                  height: 1200.0,
                  child: Container(
                    padding: const EdgeInsets.all(50.0),
                    child: const SingleChildScrollView(
                      dragStartBehavior: DragStartBehavior.down,
                      child: SizedBox(height: 1200.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveBy(const Offset(-10.0, -40.0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    final List<Type> types = <Type>[
      ScrollStartNotification,
      UserScrollNotification,
      ScrollUpdateNotification,
      ScrollEndNotification,
      UserScrollNotification,
    ];
    expect(notificationTypes, equals(types));
  });

  testWidgets('ScrollNotificationObserver', (WidgetTester tester) async {
    late ScrollNotificationObserverState observer;
    ScrollNotification? notification;

    void handleNotification(ScrollNotification value) {
      if (value is ScrollStartNotification || value is ScrollUpdateNotification || value is ScrollEndNotification) {
        notification = value;
      }
    }

    await tester.pumpWidget(
      ScrollNotificationObserver(
        child: Builder(
          builder: (BuildContext context) {
            observer = ScrollNotificationObserver.of(context)!;
            return const SingleChildScrollView(
              child: SizedBox(height: 1200.0),
            );
          },
        ),
      ),
    );

    observer.addListener(handleNotification);

    TestGesture gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await tester.pumpAndSettle();
    expect(notification, isA<ScrollStartNotification>());
    expect(notification!.depth, equals(0));

    final ScrollStartNotification start = notification! as ScrollStartNotification;
    expect(start.dragDetails, isNotNull);
    expect(start.dragDetails!.globalPosition, equals(const Offset(100.0, 100.0)));

    await gesture.moveBy(const Offset(-10.0, -10.0));
    await tester.pumpAndSettle();
    expect(notification, isA<ScrollUpdateNotification>());
    expect(notification!.depth, equals(0));
    final ScrollUpdateNotification update = notification! as ScrollUpdateNotification;
    expect(update.dragDetails, isNotNull);
    expect(update.dragDetails!.globalPosition, equals(const Offset(90.0, 90.0)));
    expect(update.dragDetails!.delta, equals(const Offset(0.0, -10.0)));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(notification, isA<ScrollEndNotification>());
    expect(notification!.depth, equals(0));
    final ScrollEndNotification end = notification! as ScrollEndNotification;
    expect(end.dragDetails, isNotNull);
    expect(end.dragDetails!.velocity, equals(Velocity.zero));

    observer.removeListener(handleNotification);
    notification = null;

    gesture = await tester.startGesture(const Offset(100.0, 100.0));
    await tester.pumpAndSettle();
    expect(notification, isNull);

    await gesture.moveBy(const Offset(-10.0, -10.0));
    await tester.pumpAndSettle();
    expect(notification, isNull);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(notification, isNull);
  });
}

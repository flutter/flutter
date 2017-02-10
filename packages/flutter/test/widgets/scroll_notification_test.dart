// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Scroll notification basics', (WidgetTester tester) async {
    ScrollNotification2 notification;

    await tester.pumpWidget(new NotificationListener<ScrollNotification2>(
      onNotification: (ScrollNotification2 value) {
        if (value is ScrollStartNotification || value is ScrollUpdateNotification || value is ScrollEndNotification)
          notification = value;
        return false;
      },
      child: new SingleChildScrollView(
        child: const SizedBox(height: 1200.0)
      )
    ));

    TestGesture gesture = await tester.startGesture(const Point(100.0, 100.0));
    await tester.pump(const Duration(seconds: 1));
    expect(notification, const isInstanceOf<ScrollStartNotification>());
    expect(notification.depth, equals(1));
    ScrollStartNotification start = notification;
    expect(start.dragDetails, isNotNull);
    expect(start.dragDetails.globalPosition, equals(const Point(100.0, 100.0)));

    await gesture.moveBy(const Offset(-10.0, -10.0));
    await tester.pump(const Duration(seconds: 1));
    expect(notification, const isInstanceOf<ScrollUpdateNotification>());
    expect(notification.depth, equals(1));
    ScrollUpdateNotification update = notification;
    expect(update.dragDetails, isNotNull);
    expect(update.dragDetails.globalPosition, equals(const Point(90.0, 90.0)));
    expect(update.dragDetails.delta, equals(const Offset(0.0, -10.0)));

    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(notification, const isInstanceOf<ScrollEndNotification>());
    expect(notification.depth, equals(1));
    ScrollEndNotification end = notification;
    expect(end.dragDetails, isNotNull);
    expect(end.dragDetails.velocity, equals(Velocity.zero));
  });

  testWidgets('Scroll notification depth', (WidgetTester tester) async {
    final List<Type> depth0Types = <Type>[];
    final List<Type> depth1Types = <Type>[];
    final List<int> depth0Values = <int>[];
    final List<int> depth1Values = <int>[];

    await tester.pumpWidget(new NotificationListener<ScrollNotification2>(
      onNotification: (ScrollNotification2 value) {
        depth1Types.add(value.runtimeType);
        depth1Values.add(value.depth);
        return false;
      },
      child: new SingleChildScrollView(
        child: new SizedBox(
          height: 1200.0,
          child: new NotificationListener<ScrollNotification2>(
            onNotification: (ScrollNotification2 value) {
              depth0Types.add(value.runtimeType);
              depth0Values.add(value.depth);
              return false;
            },
            child: new Container(
              padding: const EdgeInsets.all(50.0),
              child: new SingleChildScrollView(child: const SizedBox(height: 1200.0))
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

    final List<Type> types = <Type>[
      ScrollStartNotification,
      UserScrollNotification,
      ScrollUpdateNotification,
      ScrollEndNotification,
      UserScrollNotification,
    ];
    expect(depth0Types, equals(types));
    expect(depth1Types, equals(types));

    // These values might not be what we want in the end.
    // See <https://github.com/flutter/flutter/issues/8017>.
    expect(depth0Values, equals(<int>[1, 1, 1, 1, 1]));
    expect(depth1Values, equals(<int>[2, 2, 2, 2, 2]));
  });
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test Android page transition', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Material(child: new Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Material(child: new Text('Page 2'));
          },
        }
      )
    );

    final Point widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final Point widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    expect(widget1TopLeft.x == widget2TopLeft.x, true);
    expect(widget1TopLeft.y - widget2TopLeft.y < 0, true); // Page 1 is above page 2 mid-transition.
  });

  testWidgets('test iOS page transition', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Material(child: new Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Material(child: new Text('Page 2'));
          },
        }
      )
    );

    final Point widget1StartingTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final Point widget1OutgoingTopLeft = tester.getTopLeft(find.text('Page 1'));
    final Point widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 is moving to the left.
    expect(widget1OutgoingTopLeft.x < widget1StartingTopLeft.x, true);
    // Page 1 isn't moving vertically.
    expect(widget1OutgoingTopLeft.y == widget1StartingTopLeft.y, true);
    // Page 2 animates in horizontally only.
    expect(widget1StartingTopLeft.y == widget2TopLeft.y, true);
    // Page 2 is coming in from the right.
    expect(widget2TopLeft.x > widget1StartingTopLeft.x, true);
  });

  testWidgets('Check back gesture works on iOS', (WidgetTester tester) async {
    final GlobalKey containerKey1 = new GlobalKey();
    final GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(key: containerKey1, body: new Text('Home')),
      '/settings': (_) => new Scaffold(key: containerKey2, body: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.iOS),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Point(5.0, 100.0));
    await gesture.moveBy(const Offset(50.0, 0.0));
    await tester.pump();

    // Home is now visible.
    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);
  });

  testWidgets('Check back gesture does nothing on android', (WidgetTester tester) async {
    final GlobalKey containerKey1 = new GlobalKey();
    final GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(key: containerKey1, body: new Text('Home')),
      '/settings': (_) => new Scaffold(key: containerKey2, body: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.android),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Point(5.0, 100.0));
    await gesture.moveBy(const Offset(50.0, 0.0));
    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);
  });

  testWidgets('Check page transition positioning on iOS', (WidgetTester tester) async {
    final GlobalKey containerKey1 = new GlobalKey();
    final GlobalKey containerKey2 = new GlobalKey();
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (_) => new Scaffold(key: containerKey1, body: new Text('Home')),
      '/settings': (_) => new Scaffold(key: containerKey2, body: new Text('Settings')),
    };

    await tester.pumpWidget(new MaterialApp(
      routes: routes,
      theme: new ThemeData(platform: TargetPlatform.iOS),
    ));

    Navigator.pushNamed(containerKey1.currentContext, '/settings');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Home'), isOnstage);
    expect(find.text('Settings'), isOnstage);

    // Home page is staying in place.
    Point homeOffset = tester.getTopLeft(find.text('Home'));
    expect(homeOffset.x, 0.0);
    expect(homeOffset.y, 0.0);

    // Settings page is sliding up from the bottom.
    Point settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, 0.0);
    expect(settingsOffset.y, greaterThan(0.0));

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Settings'), isOnstage);

    // Settings page is in position.
    settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, 0.0);
    expect(settingsOffset.y, 0.0);

    Navigator.pop(containerKey1.currentContext);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // Home page is staying in place.
    homeOffset = tester.getTopLeft(find.text('Home'));
    expect(homeOffset.x, 0.0);
    expect(homeOffset.y, 0.0);

    // Settings page is sliding down off the bottom.
    settingsOffset = tester.getTopLeft(find.text('Settings'));
    expect(settingsOffset.x, 0.0);
    expect(settingsOffset.y, greaterThan(0.0));

    await tester.pump(const Duration(seconds: 1));
  });
}

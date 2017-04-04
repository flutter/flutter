// Copyright 2017 The Chromium Authors. All rights reserved.
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
        },
      )
    );

    final Point widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    Opacity widget2Opacity = tester.element(find.text('Page 2')).ancestorWidgetOfExactType(Opacity);
    Point widget2TopLeft = tester.getTopLeft(find.text('Page 2'));
    final Size widget2Size = tester.getSize(find.text('Page 2'));

    // Android transition is vertical only.
    expect(widget1TopLeft.x == widget2TopLeft.x, true);
    // Page 1 is above page 2 mid-transition.
    expect(widget1TopLeft.y < widget2TopLeft.y, true);
    // Animation begins 3/4 of the way up the page.
    expect(widget2TopLeft.y < widget2Size.height / 4.0, true);
    // Animation starts with page 2 being near transparent.
    expect(widget2Opacity.opacity < 0.01, true);

    await tester.pumpAndSettle();

    // Page 2 covers page 1.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    widget2Opacity = tester.element(find.text('Page 2')).ancestorWidgetOfExactType(Opacity);
    widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 2 starts to move down.
    expect(widget1TopLeft.y < widget2TopLeft.y, true);
    // Page 2 starts to lose opacity.
    expect(widget2Opacity.opacity < 1.0, true);

    await tester.pumpAndSettle();

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
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
        },
      )
    );

    final Point widget1InitialTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Point widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    Point widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 is moving to the left.
    expect(widget1TransientTopLeft.x < widget1InitialTopLeft.x, true);
    // Page 1 isn't moving vertically.
    expect(widget1TransientTopLeft.y == widget1InitialTopLeft.y, true);
    // iOS transition is horizontal only.
    expect(widget1InitialTopLeft.y == widget2TopLeft.y, true);
    // Page 2 is coming in from the right.
    expect(widget2TopLeft.x > widget1InitialTopLeft.x, true);

    await tester.pumpAndSettle();

    // Page 2 covers page 1.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 is coming back from the left.
    expect(widget1TransientTopLeft.x < widget1InitialTopLeft.x, true);
    // Page 1 isn't moving vertically.
    expect(widget1TransientTopLeft.y == widget1InitialTopLeft.y, true);
    // iOS transition is horizontal only.
    expect(widget1InitialTopLeft.y == widget2TopLeft.y, true);
    // Page 2 is leaving towards the right.
    expect(widget2TopLeft.x > widget1InitialTopLeft.x, true);

    await tester.pumpAndSettle();

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);

    widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));

    // Page 1 is back where it started.
    expect(widget1InitialTopLeft == widget1TransientTopLeft, true);
  });

  testWidgets('test iOS fullscreen dialog transition', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Material(child: new Text('Page 1')),
      )
    );

    final Point widget1InitialTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).push(new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Material(child: new Text('Page 2'));
      },
      fullscreenDialog: true,
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Point widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    Point widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 doesn't move.
    expect(widget1TransientTopLeft == widget1InitialTopLeft, true);
    // Fullscreen dialogs transitions vertically only.
    expect(widget1InitialTopLeft.x == widget2TopLeft.x, true);
    // Page 2 is coming in from the bottom.
    expect(widget2TopLeft.y > widget1InitialTopLeft.y, true);

    await tester.pumpAndSettle();

    // Page 2 covers page 1.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 doesn't move.
    expect(widget1TransientTopLeft == widget1InitialTopLeft, true);
    // Fullscreen dialogs transitions vertically only.
    expect(widget1InitialTopLeft.x == widget2TopLeft.x, true);
    // Page 2 is leaving towards the bottom.
    expect(widget2TopLeft.y > widget1InitialTopLeft.y, true);

    await tester.pumpAndSettle();

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);

    widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));

    // Page 1 is back where it started.
    expect(widget1InitialTopLeft == widget1TransientTopLeft, true);
  });

  testWidgets('test no back gesture on Android', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: new Scaffold(body: new Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Scaffold(body: new Text('Page 2'));
          },
        },
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Point(5.0, 100.0));
    await gesture.moveBy(const Offset(400.0, 0.0));
    await tester.pump();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Page 2 didn't move
    expect(tester.getTopLeft(find.text('Page 2')), Point.origin);
  });

  testWidgets('test back gesture on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Scaffold(body: new Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Scaffold(body: new Text('Page 2'));
          },
        },
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Point(5.0, 100.0));
    await gesture.moveBy(const Offset(400.0, 0.0));
    await tester.pump();

    // Page 1 is now visible.
    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), isOnstage);

    // The route widget position needs to track the finger position very exactly.
    expect(tester.getTopLeft(find.text('Page 2')), const Point(400.0, 0.0));

    await gesture.moveBy(const Offset(-200.0, 0.0));
    await tester.pump();

    expect(tester.getTopLeft(find.text('Page 2')), const Point(200.0, 0.0));

    await gesture.moveBy(const Offset(-100.0, 200.0));
    await tester.pump();

    expect(tester.getTopLeft(find.text('Page 2')), const Point(100.0, 0.0));
  });

  testWidgets('test no back gesture on iOS fullscreen dialogs', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: new Scaffold(body: new Text('Page 1')),
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new Scaffold(body: new Text('Page 2'));
      },
      fullscreenDialog: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Point(5.0, 100.0));
    await gesture.moveBy(const Offset(400.0, 0.0));
    await tester.pump();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Page 2 didn't move
    expect(tester.getTopLeft(find.text('Page 2')), Point.origin);
  });
}

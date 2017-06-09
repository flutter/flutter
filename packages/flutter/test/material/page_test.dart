// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart' hide TypeMatcher;

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('test Android page transition', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.android),
        home: const Material(child: const Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return const Material(child: const Text('Page 2'));
          },
        },
      )
    );

    final Offset widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));
    final Size widget2Size = tester.getSize(find.text('Page 2'));

    // Android transition is vertical only.
    expect(widget1TopLeft.dx == widget2TopLeft.dx, true);
    // Page 1 is above page 2 mid-transition.
    expect(widget1TopLeft.dy < widget2TopLeft.dy, true);
    // Animation begins from the top of the page.
    expect(widget2TopLeft.dy < widget2Size.height, true);

    await tester.pumpAndSettle();

    // Page 2 covers page 1.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 2 starts to move down.
    expect(widget1TopLeft.dy < widget2TopLeft.dy, true);

    await tester.pumpAndSettle();

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets('test iOS page transition', (WidgetTester tester) async {
    final Key page2Key = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: const Material(child: const Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return new Material(
              key: page2Key,
              child: const Text('Page 2'),
            );
          },
        },
      )
    );

    final Offset widget1InitialTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    Offset widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));
    final RenderDecoratedBox box = tester.element(find.byKey(page2Key))
        .ancestorRenderObjectOfType(const TypeMatcher<RenderDecoratedBox>());

    // Page 1 is moving to the left.
    expect(widget1TransientTopLeft.dx < widget1InitialTopLeft.dx, true);
    // Page 1 isn't moving vertically.
    expect(widget1TransientTopLeft.dy == widget1InitialTopLeft.dy, true);
    // iOS transition is horizontal only.
    expect(widget1InitialTopLeft.dy == widget2TopLeft.dy, true);
    // Page 2 is coming in from the right.
    expect(widget2TopLeft.dx > widget1InitialTopLeft.dx, true);
    // The shadow should be drawn to one screen width to the left of where
    // the page 2 box is. `paints` tests relative to the painter's given canvas
    // rather than relative to the screen so assert that it's one screen
    // width to the left of 0 offset box rect and nothing is drawn inside the
    // box's rect.
    expect(box, paints..rect(
      rect: new Rect.fromLTWH(-800.0, 0.0, 800.0, 600.0)
    ));

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
    expect(widget1TransientTopLeft.dx < widget1InitialTopLeft.dx, true);
    // Page 1 isn't moving vertically.
    expect(widget1TransientTopLeft.dy == widget1InitialTopLeft.dy, true);
    // iOS transition is horizontal only.
    expect(widget1InitialTopLeft.dy == widget2TopLeft.dy, true);
    // Page 2 is leaving towards the right.
    expect(widget2TopLeft.dx > widget1InitialTopLeft.dx, true);

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
        home: const Material(child: const Text('Page 1')),
      )
    );

    final Offset widget1InitialTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).push(new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return const Material(child: const Text('Page 2'));
      },
      fullscreenDialog: true,
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Offset widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 doesn't move.
    expect(widget1TransientTopLeft == widget1InitialTopLeft, true);
    // Fullscreen dialogs transitions vertically only.
    expect(widget1InitialTopLeft.dx == widget2TopLeft.dx, true);
    // Page 2 is coming in from the bottom.
    expect(widget2TopLeft.dy > widget1InitialTopLeft.dy, true);

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
    expect(widget1InitialTopLeft.dx == widget2TopLeft.dx, true);
    // Page 2 is leaving towards the bottom.
    expect(widget2TopLeft.dy > widget1InitialTopLeft.dy, true);

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
        home: const Scaffold(body: const Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return const Scaffold(body: const Text('Page 2'));
          },
        },
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Offset(5.0, 100.0));
    await gesture.moveBy(const Offset(400.0, 0.0));
    await tester.pump();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Page 2 didn't move
    expect(tester.getTopLeft(find.text('Page 2')), Offset.zero);
  });

  testWidgets('test back gesture on iOS', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(body: const Text('Page 1')),
        routes: <String, WidgetBuilder>{
          '/next': (BuildContext context) {
            return const Scaffold(body: const Text('Page 2'));
          },
        },
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Offset(5.0, 100.0));
    await gesture.moveBy(const Offset(400.0, 0.0));
    await tester.pump();

    // Page 1 is now visible.
    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), isOnstage);

    // The route widget position needs to track the finger position very exactly.
    expect(tester.getTopLeft(find.text('Page 2')), const Offset(400.0, 0.0));

    await gesture.moveBy(const Offset(-200.0, 0.0));
    await tester.pump();

    expect(tester.getTopLeft(find.text('Page 2')), const Offset(200.0, 0.0));

    await gesture.moveBy(const Offset(-100.0, 200.0));
    await tester.pump();

    expect(tester.getTopLeft(find.text('Page 2')), const Offset(100.0, 0.0));
  });

  testWidgets('test no back gesture on iOS fullscreen dialogs', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(platform: TargetPlatform.iOS),
        home: const Scaffold(body: const Text('Page 1')),
      )
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return const Scaffold(body: const Text('Page 2'));
      },
      fullscreenDialog: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from left edge to invoke the gesture.
    final TestGesture gesture = await tester.startGesture(const Offset(5.0, 100.0));
    await gesture.moveBy(const Offset(400.0, 0.0));
    await tester.pump();

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Page 2 didn't move
    expect(tester.getTopLeft(find.text('Page 2')), Offset.zero);
  });
}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test iOS page transition', (WidgetTester tester) async {
    await tester.pumpWidget(
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              final String pageNumber = settings.name == '/' ? "1" : "2";
              return new Center(child: new Text('Page $pageNumber'));
            }
          );
        },
      ),
    );

    final Offset widget1InitialTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    Offset widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 is moving to the left.
    expect(widget1TransientTopLeft.dx < widget1InitialTopLeft.dx, true);
    // Page 1 isn't moving vertically.
    expect(widget1TransientTopLeft.dy == widget1InitialTopLeft.dy, true);
    // iOS transition is horizontal only.
    expect(widget1InitialTopLeft.dy == widget2TopLeft.dy, true);
    // Page 2 is coming in from the right.
    expect(widget2TopLeft.dx > widget1InitialTopLeft.dx, true);

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
      new WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return new CupertinoPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return const Center(child: const Text('Page 1'));
            }
          );
        },
      ),
    );

    final Offset widget1InitialTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).push(new CupertinoPageRoute<Null>(
      builder: (BuildContext context) {
        return const Center(child: const Text('Page 2'));
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
}
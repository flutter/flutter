// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/demo/cupertino/cupertino_navigation_demo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

void main() {

  // This verifies that specifically on android devices, a page back
  // swipe doesn't work when looking at Cupertino pages in the flutter gallery.
  testWidgets('test only edge swipes work (LTR)', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) {
          return CupertinoPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) {
                final bool firstPage = settings.name == '/';
                if (firstPage)
                  return const Text('Page 1');
                else
                  return CupertinoNavigationDemo();
              }
          );
        },
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Now drag from the left edge.
    final TestGesture gesture = await tester.startGesture(const Offset(5.0, 200.0));
    await gesture.moveBy(const Offset(300.0, 0.0));
    await tester.pump();

    // Page 1 is not visible.
    expect(find.text('Page 1'), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('test only edge swipes work (LTR)', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) {
          return CupertinoPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) {
                final bool firstPage = settings.name == '/';
                if (firstPage)
                  return const Text('Page 1');
                else
                  return CupertinoNavigationDemo();
              }
          );
        },
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Page 2 covers page 1.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Home'), isOnstage);

    // Drag from the middle to the right.
    TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));
    await gesture.moveBy(const Offset(300.0, 0.0));
    await tester.pump();

    // Nothing should happen.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Home'), isOnstage);

    // Drag from the right to the left.
    gesture = await tester.startGesture(const Offset(795.0, 200.0));
    await gesture.moveBy(const Offset(-300.0, 0.0));
    await tester.pump();

    // Nothing should happen.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Home'), isOnstage);

    // Drag from the right to the further right.
    gesture = await tester.startGesture(const Offset(795.0, 200.0));
    await gesture.moveBy(const Offset(300.0, 0.0));
    await tester.pump();

    // Nothing should happen.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Home'), isOnstage);

    // Now drag from the left edge.
    gesture = await tester.startGesture(const Offset(5.0, 200.0));
    await gesture.moveBy(const Offset(300.0, 0.0));
    await tester.pump();

    // Page 1 is now visible.
    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Home'), isOnstage);
    debugDefaultTargetPlatformOverride = null;
  });
}

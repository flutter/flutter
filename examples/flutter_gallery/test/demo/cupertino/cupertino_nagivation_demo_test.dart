// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/demo/cupertino/cupertino_navigation_demo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

void main() {
  testWidgets('Back button doesn\'t work on Android', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoButton(
          child: const Text('test'),
          onPressed: (){},
        ),
        routes: <String, WidgetBuilder>{
          'nav demo', CupertinoNavigationDemo()
        }
      ),
    );

    await tester.pageBack();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('test only edge swipes work (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) {
          return CupertinoPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) {
                final String pageNumber = settings.name == '/' ? '1' : '2';
                return Center(child: Text('Page $pageNumber'));
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
    expect(find.text('Page 2'), isOnstage);

    // Drag from the middle to the right.
    TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));
    await gesture.moveBy(const Offset(300.0, 0.0));
    await tester.pump();

    // Nothing should happen.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from the right to the left.
    gesture = await tester.startGesture(const Offset(795.0, 200.0));
    await gesture.moveBy(const Offset(-300.0, 0.0));
    await tester.pump();

    // Nothing should happen.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Drag from the right to the further right.
    gesture = await tester.startGesture(const Offset(795.0, 200.0));
    await gesture.moveBy(const Offset(300.0, 0.0));
    await tester.pump();

    // Nothing should happen.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    // Now drag from the left edge.
    gesture = await tester.startGesture(const Offset(5.0, 200.0));
    await gesture.moveBy(const Offset(300.0, 0.0));
    await tester.pump();

    // Page 1 is now visible.
    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), isOnstage);
  });
}

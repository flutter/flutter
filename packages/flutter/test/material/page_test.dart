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

    Point widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    // await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    Point widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

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

    Point widget1TopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    // await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    Point widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // This is currently an incorrect behaviour and we want right to left transition instead.
    // See https://github.com/flutter/flutter/issues/8726.
    expect(widget1TopLeft.x == widget2TopLeft.x, true);
    expect(widget1TopLeft.y - widget2TopLeft.y < 0, true);
  });
}

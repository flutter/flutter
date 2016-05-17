// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class ThePositiveNumbers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new ScrollableLazyList(
      itemExtent: 100.0,
      itemBuilder: (BuildContext context, int start, int count) {
        List<Widget> result = new List<Widget>();
        for (int index = start; index < start + count; index += 1)
          result.add(new Text('$index', key: new ValueKey<int>(index)));
        return result;
      }
    );
  }
}

void main() {
  testWidgets('whether we remember our scroll position', (WidgetTester tester) async {
    GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
    await tester.pumpWidget(new Navigator(
      key: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/')
          return new MaterialPageRoute<Null>(builder: (_) => new Container(child: new ThePositiveNumbers()));
        else if (settings.name == '/second')
          return new MaterialPageRoute<Null>(builder: (_) => new Container(child: new ThePositiveNumbers()));
        return null;
      }
    ));

    // we're 600 pixels high, each item is 100 pixels high, scroll position is
    // zero, so we should have exactly 6 items, 0..5.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing);
    expect(find.text('10'), findsNothing);
    expect(find.text('100'), findsNothing);

    ScrollableState targetState = tester.state(find.byType(Scrollable));
    targetState.scrollTo(1000.0);
    await tester.pump(new Duration(seconds: 1));

    // we're 600 pixels high, each item is 100 pixels high, scroll position is
    // 1000, so we should have exactly 6 items, 10..15.

    expect(find.text('0'), findsNothing);
    expect(find.text('8'), findsNothing);
    expect(find.text('9'), findsNothing);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('16'), findsNothing);
    expect(find.text('100'), findsNothing);

    navigatorKey.currentState.openTransaction(
      (NavigatorTransaction transaction) => transaction.pushNamed('/second')
    );
    await tester.pump(); // navigating always takes two frames
    await tester.pump(new Duration(seconds: 1));

    // same as the first list again
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing);
    expect(find.text('10'), findsNothing);
    expect(find.text('100'), findsNothing);

    navigatorKey.currentState.openTransaction(
      (NavigatorTransaction transaction) => transaction.pop()
    );
    await tester.pump(); // navigating always takes two frames
    await tester.pump(new Duration(seconds: 1));

    // we're 600 pixels high, each item is 100 pixels high, scroll position is
    // 1000, so we should have exactly 6 items, 10..15.

    expect(find.text('0'), findsNothing);
    expect(find.text('8'), findsNothing);
    expect(find.text('9'), findsNothing);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('16'), findsNothing);
    expect(find.text('100'), findsNothing);

  });
}

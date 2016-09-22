// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class ThePositiveNumbers extends StatelessWidget {
  ThePositiveNumbers({ @required this.from });
  final int from;
  @override
  Widget build(BuildContext context) {
    return new ScrollableLazyList(
      itemExtent: 100.0,
      itemBuilder: (BuildContext context, int start, int count) {
        List<Widget> result = new List<Widget>();
        for (int index = start; index < start + count; index += 1)
          result.add(new Text('${index + from}', key: new ValueKey<int>(index)));
        return result;
      }
    );
  }
}

Future<Null> performTest(WidgetTester tester, bool maintainState) async {
  GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
  await tester.pumpWidget(new Navigator(
    key: navigatorKey,
    onGenerateRoute: (RouteSettings settings) {
      if (settings.name == '/') {
        return new MaterialPageRoute<Null>(
          settings: settings,
          builder: (_) => new Container(child: new ThePositiveNumbers(from: 0)),
          maintainState: maintainState,
        );
      } else if (settings.name == '/second') {
        return new MaterialPageRoute<Null>(
          settings: settings,
          builder: (_) => new Container(child: new ThePositiveNumbers(from: 10000)),
          maintainState: maintainState,
        );
      }
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

  Completer<Null> completer = new Completer<Null>();
  tester.state/*<ScrollableState>*/(find.byType(Scrollable)).scrollTo(1000.0).whenComplete(completer.complete);
  expect(completer.isCompleted, isFalse);
  await tester.pump(new Duration(seconds: 1));
  expect(completer.isCompleted, isTrue);

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

  navigatorKey.currentState.pushNamed('/second');
  await tester.pump(); // navigating always takes two frames, one to start...
  await tester.pump(new Duration(seconds: 1)); // ...and one to end the transition

  // the second list is now visible, starting at 10000
  expect(find.text('10000'), findsOneWidget);
  expect(find.text('10001'), findsOneWidget);
  expect(find.text('10002'), findsOneWidget);
  expect(find.text('10003'), findsOneWidget);
  expect(find.text('10004'), findsOneWidget);
  expect(find.text('10005'), findsOneWidget);
  expect(find.text('10006'), findsNothing);
  expect(find.text('10010'), findsNothing);
  expect(find.text('10100'), findsNothing);

  navigatorKey.currentState.pop();
  await tester.pump(); // again, navigating always takes two frames

  // Ensure we don't clamp the scroll offset even during the navigation.
  // https://github.com/flutter/flutter/issues/4883
  LazyListViewport viewport = tester.firstWidget(find.byType(LazyListViewport));
  expect(viewport.scrollOffset, equals(1000.0));

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
}

void main() {
  testWidgets('whether we remember our scroll position', (WidgetTester tester) async {
    await performTest(tester, true);
    await performTest(tester, false);
  });
}

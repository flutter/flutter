// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

ScrollController _controller = ScrollController(
  initialScrollOffset: 110.0,
);

class ThePositiveNumbers extends StatelessWidget {
  const ThePositiveNumbers({ @required this.from });
  final int from;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey<String>('ThePositiveNumbers'),
      itemExtent: 100.0,
      controller: _controller,
      itemBuilder: (BuildContext context, int index) {
        return Text('${index + from}', key: ValueKey<int>(index));
      }
    );
  }
}

Future<void> performTest(WidgetTester tester, bool maintainState) async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Container(child: const ThePositiveNumbers(from: 0)),
              maintainState: maintainState,
            );
          } else if (settings.name == '/second') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Container(child: const ThePositiveNumbers(from: 10000)),
              maintainState: maintainState,
            );
          }
          return null;
        }
      ),
    ),
  );

  // we're 600 pixels high, each item is 100 pixels high, scroll position is
  // 110.0, so we should have 7 items, 1..7.
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
  expect(find.text('2'), findsOneWidget);
  expect(find.text('3'), findsOneWidget);
  expect(find.text('4'), findsOneWidget);
  expect(find.text('5'), findsOneWidget);
  expect(find.text('6'), findsOneWidget);
  expect(find.text('7'), findsOneWidget);
  expect(find.text('8'), findsNothing);
  expect(find.text('10'), findsNothing);
  expect(find.text('100'), findsNothing);

  tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(1000.0);
  await tester.pump(const Duration(seconds: 1));

  // we're 600 pixels high, each item is 100 pixels high, scroll position is
  // 1000, so we should have exactly 6 items, 10..15.

  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsNothing);
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
  await tester.pump(const Duration(seconds: 1)); // ...and one to end the transition

  // the second list is now visible, starting at 10001
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsNothing);
  expect(find.text('10'), findsNothing);
  expect(find.text('11'), findsNothing);
  expect(find.text('10000'), findsNothing);
  expect(find.text('10001'), findsOneWidget);
  expect(find.text('10002'), findsOneWidget);
  expect(find.text('10003'), findsOneWidget);
  expect(find.text('10004'), findsOneWidget);
  expect(find.text('10005'), findsOneWidget);
  expect(find.text('10006'), findsOneWidget);
  expect(find.text('10007'), findsOneWidget);
  expect(find.text('10008'), findsNothing);
  expect(find.text('10010'), findsNothing);
  expect(find.text('10100'), findsNothing);

  navigatorKey.currentState.pop();
  await tester.pump(); // again, navigating always takes two frames

  // Ensure we don't clamp the scroll offset even during the navigation.
  // https://github.com/flutter/flutter/issues/4883
  final ScrollableState state = tester.state(find.byType(Scrollable).first);
  expect(state.position.pixels, equals(1000.0));

  await tester.pump(const Duration(seconds: 1));

  // we're 600 pixels high, each item is 100 pixels high, scroll position is
  // 1000, so we should have exactly 6 items, 10..15.

  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsNothing);
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

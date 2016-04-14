// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

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
  test('whether we remember our scroll position', () {
    testWidgets((WidgetTester tester) {
      GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
      tester.pumpWidget(new Navigator(
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
      expect(tester, hasWidget(find.text('0')));
      expect(tester, hasWidget(find.text('1')));
      expect(tester, hasWidget(find.text('2')));
      expect(tester, hasWidget(find.text('3')));
      expect(tester, hasWidget(find.text('4')));
      expect(tester, hasWidget(find.text('5')));
      expect(tester, doesNotHaveWidget(find.text('6')));
      expect(tester, doesNotHaveWidget(find.text('10')));
      expect(tester, doesNotHaveWidget(find.text('100')));

      ScrollableState targetState = tester.stateOf(find.byType(ScrollableLazyList));
      targetState.scrollTo(1000.0);
      tester.pump(new Duration(seconds: 1));

      // we're 600 pixels high, each item is 100 pixels high, scroll position is
      // 1000, so we should have exactly 6 items, 10..15.

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('8')));
      expect(tester, doesNotHaveWidget(find.text('9')));
      expect(tester, hasWidget(find.text('10')));
      expect(tester, hasWidget(find.text('11')));
      expect(tester, hasWidget(find.text('12')));
      expect(tester, hasWidget(find.text('13')));
      expect(tester, hasWidget(find.text('14')));
      expect(tester, hasWidget(find.text('15')));
      expect(tester, doesNotHaveWidget(find.text('16')));
      expect(tester, doesNotHaveWidget(find.text('100')));

      navigatorKey.currentState.openTransaction(
        (NavigatorTransaction transaction) => transaction.pushNamed('/second')
      );
      tester.pump(); // navigating always takes two frames
      tester.pump(new Duration(seconds: 1));

      // same as the first list again
      expect(tester, hasWidget(find.text('0')));
      expect(tester, hasWidget(find.text('1')));
      expect(tester, hasWidget(find.text('2')));
      expect(tester, hasWidget(find.text('3')));
      expect(tester, hasWidget(find.text('4')));
      expect(tester, hasWidget(find.text('5')));
      expect(tester, doesNotHaveWidget(find.text('6')));
      expect(tester, doesNotHaveWidget(find.text('10')));
      expect(tester, doesNotHaveWidget(find.text('100')));

      navigatorKey.currentState.openTransaction(
        (NavigatorTransaction transaction) => transaction.pop()
      );
      tester.pump(); // navigating always takes two frames
      tester.pump(new Duration(seconds: 1));

      // we're 600 pixels high, each item is 100 pixels high, scroll position is
      // 1000, so we should have exactly 6 items, 10..15.

      expect(tester, doesNotHaveWidget(find.text('0')));
      expect(tester, doesNotHaveWidget(find.text('8')));
      expect(tester, doesNotHaveWidget(find.text('9')));
      expect(tester, hasWidget(find.text('10')));
      expect(tester, hasWidget(find.text('11')));
      expect(tester, hasWidget(find.text('12')));
      expect(tester, hasWidget(find.text('13')));
      expect(tester, hasWidget(find.text('14')));
      expect(tester, hasWidget(find.text('15')));
      expect(tester, doesNotHaveWidget(find.text('16')));
      expect(tester, doesNotHaveWidget(find.text('100')));

    });
  });
}

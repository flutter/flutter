// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

class ThePositiveNumbers extends ScrollableWidgetList {
  ThePositiveNumbers() : super(itemExtent: 100.0);
  ThePositiveNumbersState createState() => new ThePositiveNumbersState();
}

class ThePositiveNumbersState extends ScrollableWidgetListState<ThePositiveNumbers> {

  ScrollBehavior createScrollBehavior() => new UnboundedBehavior();

  int get itemCount => null;

  List<Widget> buildItems(BuildContext context, int start, int count) {
    List<Widget> result = new List<Widget>();
    for (int index = start; index < start + count; index += 1)
      result.add(new Text('$index', key: new ValueKey<int>(index)));
    return result;
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
            return new MaterialPageRoute(builder: (_) => new Container(child: new ThePositiveNumbers()));
          else if (settings.name == '/second')
            return new MaterialPageRoute(builder: (_) => new Container(child: new ThePositiveNumbers()));
          return null;
        }
      ));

      // we're 600 pixels high, each item is 100 pixels high, scroll position is
      // zero, so we should have exactly 6 items, 0..5.
      expect(tester.findText('0'), isNotNull);
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('2'), isNotNull);
      expect(tester.findText('3'), isNotNull);
      expect(tester.findText('4'), isNotNull);
      expect(tester.findText('5'), isNotNull);
      expect(tester.findText('6'), isNull);
      expect(tester.findText('10'), isNull);
      expect(tester.findText('100'), isNull);

      StatefulComponentElement<ThePositiveNumbers, ThePositiveNumbersState> target =
        tester.findElement((Element element) => element.widget is ThePositiveNumbers);
      target.state.scrollTo(1000.0);
      tester.pump(new Duration(seconds: 1));

      // we're 600 pixels high, each item is 100 pixels high, scroll position is
      // 1000, so we should have exactly 6 items, 10..15.

      expect(tester.findText('0'), isNull);
      expect(tester.findText('8'), isNull);
      expect(tester.findText('9'), isNull);
      expect(tester.findText('10'), isNotNull);
      expect(tester.findText('11'), isNotNull);
      expect(tester.findText('12'), isNotNull);
      expect(tester.findText('13'), isNotNull);
      expect(tester.findText('14'), isNotNull);
      expect(tester.findText('15'), isNotNull);
      expect(tester.findText('16'), isNull);
      expect(tester.findText('100'), isNull);

      navigatorKey.currentState.openTransaction(
        (NavigatorTransaction transaction) => transaction.pushNamed('/second')
      );
      tester.pump(); // navigating always takes two frames
      tester.pump(new Duration(seconds: 1));

      // same as the first list again
      expect(tester.findText('0'), isNotNull);
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('2'), isNotNull);
      expect(tester.findText('3'), isNotNull);
      expect(tester.findText('4'), isNotNull);
      expect(tester.findText('5'), isNotNull);
      expect(tester.findText('6'), isNull);
      expect(tester.findText('10'), isNull);
      expect(tester.findText('100'), isNull);

      navigatorKey.currentState.openTransaction(
        (NavigatorTransaction transaction) => transaction.pop()
      );
      tester.pump(); // navigating always takes two frames
      tester.pump(new Duration(seconds: 1));

      // we're 600 pixels high, each item is 100 pixels high, scroll position is
      // 1000, so we should have exactly 6 items, 10..15.

      expect(tester.findText('0'), isNull);
      expect(tester.findText('8'), isNull);
      expect(tester.findText('9'), isNull);
      expect(tester.findText('10'), isNotNull);
      expect(tester.findText('11'), isNotNull);
      expect(tester.findText('12'), isNotNull);
      expect(tester.findText('13'), isNotNull);
      expect(tester.findText('14'), isNotNull);
      expect(tester.findText('15'), isNotNull);
      expect(tester.findText('16'), isNull);
      expect(tester.findText('100'), isNull);

    });
  });
}

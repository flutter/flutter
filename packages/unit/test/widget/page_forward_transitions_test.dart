// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

class TestTransition extends TransitionComponent {
  TestTransition({
    Key key,
    this.childFirstHalf,
    this.childSecondHalf,
    PerformanceView performance
  }) : super(key: key, performance: performance) {
    assert(performance != null);
  }

  final Widget childFirstHalf;
  final Widget childSecondHalf;

  Widget build(BuildContext context) {
    if (performance.progress >= 0.5)
      return childSecondHalf;
    return childFirstHalf;
  }
}

class TestRoute<T> extends PageRoute<T> {
  TestRoute({ this.child, NamedRouteSettings settings}) : super(settings: settings);
  final Widget child;
  Duration get transitionDuration => kMaterialPageRouteTransitionDuration;
  Color get barrierColor => null;
  Widget buildPage(BuildContext context, PerformanceView performance, PerformanceView forwardPerformance) {
    return child;
  }
}

void main() {
  final Duration kTwoTenthsOfTheTransitionDuration = kMaterialPageRouteTransitionDuration * 0.2;
  final Duration kFourTenthsOfTheTransitionDuration = kMaterialPageRouteTransitionDuration * 0.4;

  test('Check onstage/offstage handling around transitions', () {
    testWidgets((WidgetTester tester) {

      GlobalKey insideKey = new GlobalKey();

      String state() {
        String result = '';
        if (tester.findText('A') != null)
          result += 'A';
        if (tester.findText('B') != null)
          result += 'B';
        if (tester.findText('C') != null)
          result += 'C';
        if (tester.findText('D') != null)
          result += 'D';
        if (tester.findText('E') != null)
          result += 'E';
        if (tester.findText('F') != null)
          result += 'F';
        if (tester.findText('G') != null)
          result += 'G';
        return result;
      }

      tester.pumpWidget(
        new MaterialApp(
          onGenerateRoute: (NamedRouteSettings settings) {
            switch (settings.name) {
              case '/':
                return new TestRoute(
                  settings: settings,
                  child: new Builder(
                    key: insideKey,
                    builder: (BuildContext context) {
                      PageRoute route = ModalRoute.of(context);
                      return new Column([
                        new TestTransition(
                          childFirstHalf: new Text('A'),
                          childSecondHalf: new Text('B'),
                          performance: route.performance
                        ),
                        new TestTransition(
                          childFirstHalf: new Text('C'),
                          childSecondHalf: new Text('D'),
                          performance: route.forwardPerformance
                        ),
                      ]);
                    }
                  )
                );
              case '/2': return new TestRoute(settings: settings, child: new Text('E'));
              case '/3': return new TestRoute(settings: settings, child: new Text('F'));
              case '/4': return new TestRoute(settings: settings, child: new Text('G'));
            }
          }
        )
      );

      NavigatorState navigator = insideKey.currentContext.ancestorStateOfType(NavigatorState);

      expect(state(), equals('BC')); // transition ->1 is at 1.0

      navigator.openTransaction((NavigatorTransaction transaction) => transaction.pushNamed('/2'));
      expect(state(), equals('BC')); // transition 1->2 is not yet built
      tester.pump();
      expect(state(), equals('BCE')); // transition 1->2 is at 0.0

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BCE')); // transition 1->2 is at 0.4

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BDE')); // transition 1->2 is at 0.8

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('E')); // transition 1->2 is at 1.0


      navigator.openTransaction((NavigatorTransaction transaction) => transaction.pop());
      expect(state(), equals('E')); // transition 1<-2 is at 1.0, just reversed
      tester.pump();
      expect(state(), equals('BDE')); // transition 1<-2 is at 1.0

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BDE')); // transition 1<-2 is at 0.6

      navigator.openTransaction((NavigatorTransaction transaction) => transaction.pushNamed('/3'));
      expect(state(), equals('BDE')); // transition 1<-2 is at 0.6
      tester.pump();
      expect(state(), equals('BDEF')); // transition 1<-2 is at 0.6, 1->3 is at 0.0

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BCEF')); // transition 1<-2 is at 0.2, 1->3 is at 0.4

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BDF')); // transition 1<-2 is done, 1->3 is at 0.8

      navigator.openTransaction((NavigatorTransaction transaction) => transaction.pop());
      expect(state(), equals('BDF')); // transition 1<-3 is at 0.8, just reversed
      tester.pump();
      expect(state(), equals('BDF')); // transition 1<-3 is at 0.8

      tester.pump(kTwoTenthsOfTheTransitionDuration); // notice that dT=0.2 here, not 0.4
      expect(state(), equals('BDF')); // transition 1<-3 is at 0.6

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BCF')); // transition 1<-3 is at 0.2

      navigator.openTransaction((NavigatorTransaction transaction) => transaction.pushNamed('/4'));
      expect(state(), equals('BCF')); // transition 1<-3 is at 0.2, 1->4 is not yet built
      tester.pump();
      expect(state(), equals('BCFG')); // transition 1<-3 is at 0.2, 1->4 is at 0.0

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BCG')); // transition 1<-3 is done, 1->4 is at 0.4

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('BDG')); // transition 1->4 is at 0.8

      tester.pump(kFourTenthsOfTheTransitionDuration);
      expect(state(), equals('G')); // transition 1->4 is done

    });
  });
}

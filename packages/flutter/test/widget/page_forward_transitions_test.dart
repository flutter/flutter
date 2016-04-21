// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart' hide TypeMatcher;

class TestTransition extends AnimatedWidget {
  TestTransition({
    Key key,
    this.childFirstHalf,
    this.childSecondHalf,
    Animation<double> animation
  }) : super(key: key, animation: animation) {
    assert(animation != null);
  }

  final Widget childFirstHalf;
  final Widget childSecondHalf;

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.animation;
    if (animation.value >= 0.5)
      return childSecondHalf;
    return childFirstHalf;
  }
}

class TestRoute<T> extends PageRoute<T> {
  TestRoute({ this.child, RouteSettings settings}) : super(settings: settings);

  final Widget child;

  @override
  Duration get transitionDuration => kMaterialPageRouteTransitionDuration;

  @override
  Color get barrierColor => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    return child;
  }
}

void main() {
  final Duration kTwoTenthsOfTheTransitionDuration = kMaterialPageRouteTransitionDuration * 0.2;
  final Duration kFourTenthsOfTheTransitionDuration = kMaterialPageRouteTransitionDuration * 0.4;

  testWidgets('Check onstage/offstage handling around transitions', (WidgetTester tester) {

      GlobalKey insideKey = new GlobalKey();

      String state() {
        String result = '';
        if (tester.any(find.text('A')))
          result += 'A';
        if (tester.any(find.text('B')))
          result += 'B';
        if (tester.any(find.text('C')))
          result += 'C';
        if (tester.any(find.text('D')))
          result += 'D';
        if (tester.any(find.text('E')))
          result += 'E';
        if (tester.any(find.text('F')))
          result += 'F';
        if (tester.any(find.text('G')))
          result += 'G';
        return result;
      }

      tester.pumpWidget(
        new MaterialApp(
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case '/':
                return new TestRoute<Null>(
                  settings: settings,
                  child: new Builder(
                    key: insideKey,
                    builder: (BuildContext context) {
                      PageRoute<Null> route = ModalRoute.of(context);
                      return new Column(
                        children: <Widget>[
                          new TestTransition(
                            childFirstHalf: new Text('A'),
                            childSecondHalf: new Text('B'),
                            animation: route.animation
                          ),
                          new TestTransition(
                            childFirstHalf: new Text('C'),
                            childSecondHalf: new Text('D'),
                            animation: route.forwardAnimation
                          ),
                        ]
                      );
                    }
                  )
                );
              case '/2': return new TestRoute<Null>(settings: settings, child: new Text('E'));
              case '/3': return new TestRoute<Null> (settings: settings, child: new Text('F'));
              case '/4': return new TestRoute<Null> (settings: settings, child: new Text('G'));
            }
          }
        )
      );

      NavigatorState navigator = insideKey.currentContext.ancestorStateOfType(const TypeMatcher<NavigatorState>());

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
}

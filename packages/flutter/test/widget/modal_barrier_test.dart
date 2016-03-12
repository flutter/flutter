// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  bool tapped;
  Widget tapTarget;

  setUp(() {
    tapped = false;
    tapTarget = new GestureDetector(
      onTap: () {
        tapped = true;
      },
      child: new SizedBox(
        width: 10.0,
        height: 10.0,
        child: new Text('target')
      )
    );
  });

  test('ModalBarrier prevents interactions with widgets behind it', () {
    testWidgets((WidgetTester tester) {
      Widget subject = new Stack(
        children: <Widget>[
          tapTarget,
          new ModalBarrier(dismissable: false),
        ]
      );

      tester.pumpWidget(subject);
      tester.tap(tester.findText('target'));
      tester.pumpWidget(subject);
      expect(tapped, isFalse,
        reason: 'because the tap is prevented by ModalBarrier');
    });
  });

  test('ModalBarrier does not prevent interactions with widgets in front of it', () {
    testWidgets((WidgetTester tester) {
      Widget subject = new Stack(
        children: <Widget>[
          new ModalBarrier(dismissable: false),
          tapTarget,
        ]
      );

      tester.pumpWidget(subject);
      tester.tap(tester.findText('target'));
      tester.pumpWidget(subject);
      expect(tapped, isTrue,
        reason: 'because the tap is not prevented by ModalBarrier');
    });
  });

  test('ModalBarrier pops the Navigator when dismissed', () {
    testWidgets((WidgetTester tester) {
      final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
        '/': (RouteArguments args) => new FirstWidget(),
        '/modal': (RouteArguments args) => new SecondWidget(),
      };

      tester.pumpWidget(new MaterialApp(routes: routes));

      // Initially the barrier is not visible
      expect(tester.findElementByKey(const ValueKey<String>('barrier')), isNull);

      // Tapping on X routes to the barrier
      tester.tap(tester.findText('X'));
      tester.pump();  // begin transition
      tester.pump(const Duration(seconds: 1));  // end transition

      // Tap on the barrier to dismiss it
      tester.tap(tester.findElementByKey(const ValueKey<String>('barrier')));
      tester.pump();  // begin transition
      tester.pump(const Duration(seconds: 1));  // end transition

      expect(tester.findElementByKey(const ValueKey<String>('barrier')), isNull,
        reason: 'because the barrier was dismissed');
    });
  });
}

class FirstWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/modal');
      },
      child: new Container(
        child: new Text('X')
      )
    );
  }
}

class SecondWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return new ModalBarrier(
      key: const ValueKey<String>('barrier'),
      dismissable: true
    );
  }
}

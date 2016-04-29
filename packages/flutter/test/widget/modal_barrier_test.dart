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

  testWidgets('ModalBarrier prevents interactions with widgets behind it', (WidgetTester tester) {
    Widget subject = new Stack(
      children: <Widget>[
        tapTarget,
        new ModalBarrier(dismissable: false),
      ]
    );

    tester.pumpWidget(subject);
    tester.tap(find.text('target'));
    tester.pumpWidget(subject);
    expect(tapped, isFalse,
      reason: 'because the tap is prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier does not prevent interactions with widgets in front of it', (WidgetTester tester) {
    Widget subject = new Stack(
      children: <Widget>[
        new ModalBarrier(dismissable: false),
        tapTarget,
      ]
    );

    tester.pumpWidget(subject);
    tester.tap(find.text('target'));
    tester.pumpWidget(subject);
    expect(tapped, isTrue,
      reason: 'because the tap is not prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier pops the Navigator when dismissed', (WidgetTester tester) {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => new FirstWidget(),
      '/modal': (BuildContext context) => new SecondWidget(),
    };

    tester.pumpWidget(new MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    tester.tap(find.text('X'));
    tester.pump();  // begin transition
    tester.pump(const Duration(seconds: 1));  // end transition

    // Tap on the barrier to dismiss it
    tester.tap(find.byKey(const ValueKey<String>('barrier')));
    tester.pump();  // begin transition
    tester.pump(const Duration(seconds: 1));  // end transition

    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing,
      reason: 'because the barrier was dismissed');
  });
}

class FirstWidget extends StatelessWidget {
  @override
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
  @override
  Widget build(BuildContext context) {
  return new ModalBarrier(
    key: const ValueKey<String>('barrier'),
    dismissable: true
  );
  }
}

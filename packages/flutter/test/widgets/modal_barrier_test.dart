// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  bool tapped;
  Widget tapTarget;

  setUp(() {
    tapped = false;
    tapTarget = new GestureDetector(
      onTap: () {
        tapped = true;
      },
      child: const SizedBox(
        width: 10.0,
        height: 10.0,
        child: const Text('target')
      )
    );
  });

  testWidgets('ModalBarrier prevents interactions with widgets behind it', (WidgetTester tester) async {
    final Widget subject = new Stack(
      children: <Widget>[
        tapTarget,
        const ModalBarrier(dismissible: false),
      ]
    );

    await tester.pumpWidget(subject);
    await tester.tap(find.text('target'));
    await tester.pumpWidget(subject);
    expect(tapped, isFalse,
      reason: 'because the tap is prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier does not prevent interactions with widgets in front of it', (WidgetTester tester) async {
    final Widget subject = new Stack(
      children: <Widget>[
        const ModalBarrier(dismissible: false),
        tapTarget,
      ]
    );

    await tester.pumpWidget(subject);
    await tester.tap(find.text('target'));
    await tester.pumpWidget(subject);
    expect(tapped, isTrue,
      reason: 'because the tap is not prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier pops the Navigator when dismissed', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => new FirstWidget(),
      '/modal': (BuildContext context) => new SecondWidget(),
    };

    await tester.pumpWidget(new MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump();  // begin transition
    await tester.pump(const Duration(seconds: 1));  // end transition

    // Tap on the barrier to dismiss it
    await tester.tap(find.byKey(const ValueKey<String>('barrier')));
    await tester.pump();  // begin transition
    await tester.pump(const Duration(seconds: 1));  // end transition

    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing,
      reason: 'The route should have been dismissed by tapping the barrier.');
  });

  testWidgets('Undismissible ModalBarrier hidden in semantic tree', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(const ModalBarrier(dismissible: false));

    final TestSemantics expectedSemantics = new TestSemantics.root();
    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  testWidgets('Dismissible ModalBarrier includes button in semantic tree', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(const ModalBarrier(dismissible: true));

    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          children: <TestSemantics>[
            new TestSemantics(
              id: 2,
              rect: TestSemantics.fullScreen,
              actions: SemanticsAction.tap.index,
            ),
          ]
        ),
      ]
    );
    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
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
      child: const Text('X')
    )
  );
  }
}

class SecondWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  return const ModalBarrier(
    key: const ValueKey<String>('barrier'),
    dismissible: true
  );
  }
}

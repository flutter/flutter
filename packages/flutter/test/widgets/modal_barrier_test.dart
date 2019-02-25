// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  bool tapped;
  Widget tapTarget;

  setUp(() {
    tapped = false;
    tapTarget = GestureDetector(
      onTap: () {
        tapped = true;
      },
      child: const SizedBox(
        width: 10.0,
        height: 10.0,
        child: Text('target', textDirection: TextDirection.ltr)
      )
    );
  });

  testWidgets('ModalBarrier prevents interactions with widgets behind it', (WidgetTester tester) async {
    final Widget subject = Stack(
      textDirection: TextDirection.ltr,
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
    final Widget subject = Stack(
      textDirection: TextDirection.ltr,
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
      '/': (BuildContext context) => FirstWidget(),
      '/modal': (BuildContext context) => SecondWidget(),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    // Tap on the barrier to dismiss it
    await tester.tap(find.byKey(const ValueKey<String>('barrier')));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing,
      reason: 'The route should have been dismissed by tapping the barrier.');
  });

  testWidgets('ModalBarrier does not pop the Navigator with a WillPopScope that returns false', (WidgetTester tester) async {
    bool willPopCalled = false;
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => FirstWidget(),
      '/modal': (BuildContext context) => Stack(
        children: <Widget>[
          SecondWidget(),
          WillPopScope(
            child: const SizedBox(),
            onWillPop: () async {
              willPopCalled = true;
              return false;
            },
          ),
      ],),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(willPopCalled, isFalse);

    // Tap on the barrier to attempt to dismiss it
    await tester.tap(find.byKey(const ValueKey<String>('barrier')));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(find.byKey(const ValueKey<String>('barrier')), findsOneWidget,
      reason: 'The route should still be present if the pop is vetoed.');

    expect(willPopCalled, isTrue);
  });

  testWidgets('ModalBarrier pops the Navigator with a WillPopScope that returns true', (WidgetTester tester) async {
    bool willPopCalled = false;
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => FirstWidget(),
      '/modal': (BuildContext context) => Stack(
        children: <Widget>[
          SecondWidget(),
          WillPopScope(
            child: const SizedBox(),
            onWillPop: () async {
              willPopCalled = true;
              return true;
            },
          ),
        ],),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(willPopCalled, isFalse);

    // Tap on the barrier to attempt to dismiss it
    await tester.tap(find.byKey(const ValueKey<String>('barrier')));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing,
      reason: 'The route should not be present if the pop is permitted.');

    expect(willPopCalled, isTrue);
  });

  testWidgets('Undismissible ModalBarrier hidden in semantic tree', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const ModalBarrier(dismissible: false));

    final TestSemantics expectedSemantics = TestSemantics.root();
    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  testWidgets('Dismissible ModalBarrier includes button in semantic tree on iOS', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: ModalBarrier(
        dismissible: true,
        semanticsLabel: 'Dismiss',
      ),
    ));

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: TestSemantics.fullScreen,
          actions: SemanticsAction.tap.index,
          label: 'Dismiss',
          textDirection: TextDirection.ltr,
        ),
      ]
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true));

    semantics.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Dismissible ModalBarrier is hidden on Android (back button is used to dismiss)', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const ModalBarrier(dismissible: true));

    final TestSemantics expectedSemantics = TestSemantics.root();
    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });
}

class FirstWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, '/modal');
    },
    child: Container(
      child: const Text('X')
    )
  );
  }
}

class SecondWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  return const ModalBarrier(
    key: ValueKey<String>('barrier'),
    dismissible: true
  );
  }
}

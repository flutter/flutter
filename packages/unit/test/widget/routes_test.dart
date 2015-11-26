// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

final List<String> results = <String>[];

class TestRoute extends Route<String> {
  TestRoute(this.name);
  final String name;

  List<OverlayEntry> get overlayEntries => _entries;

  List<OverlayEntry> _entries = <OverlayEntry>[];

  void log(String s) {
    results.add('$name: $s');
  }

  void install(OverlayState overlay, OverlayEntry insertionPoint) {
    log('install');
    OverlayEntry entry = new OverlayEntry(
      builder: (BuildContext context) => new Container(),
      opaque: true
    );
    _entries.add(entry);
    overlay?.insert(entry, above: insertionPoint);
  }

  void didPush() {
    log('didPush');
  }

  void didReplace(TestRoute oldRoute) {
    log('didReplace ${oldRoute.name}');
  }

  bool didPop(String result) {
    log('didPop $result');
    return super.didPop(result);
  }

  void didPushNext(TestRoute nextRoute) {
    log('didPushNext ${nextRoute.name}');
  }

  void didPopNext(TestRoute nextRoute) {
    log('didPopNext ${nextRoute.name}');
  }

  void didReplaceNext(TestRoute oldNextRoute, TestRoute newNextRoute) {
    log('didReplaceNext ${oldNextRoute.name} ${newNextRoute.name}');
  }

  void dispose() {
    log('dispose');
    _entries.forEach((OverlayEntry entry) { entry.remove(); });
    _entries.clear();
  }

}

void runNavigatorTest(
  WidgetTester tester,
  NavigatorState host,
  void test(NavigatorState transaction),
  List<String> expectations
) {
  expect(host, isNotNull);
  test(host);
  expect(results, equals(expectations));
  results.clear();
  tester.pump();
}

void main() {
  test('Route management', () {
    testWidgets((WidgetTester tester) {
      GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
      tester.pumpWidget(new Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) => new TestRoute('initial')
      ));
      NavigatorState host = navigatorKey.currentState;
      runNavigatorTest(
        tester,
        host,
        (NavigatorState transaction) {
        },
        [
          'initial: install',
          'initial: didPush',
        ]
      );
      TestRoute second;
      runNavigatorTest(
        tester,
        host,
        (NavigatorState transaction) {
          transaction.push(second = new TestRoute('second'));
        },
        [
          'second: install',
          'second: didPush',
          'initial: didPushNext second',
        ]
      );
      runNavigatorTest(
        tester,
        host,
        (NavigatorState transaction) {
          transaction.push(new TestRoute('third'));
        },
        [
          'third: install',
          'third: didPush',
          'second: didPushNext third',
        ]
      );
      runNavigatorTest(
        tester,
        host,
        (NavigatorState transaction) {
          transaction.replace(oldRoute: second, newRoute: new TestRoute('two'));
        },
        [
          'two: install',
          'two: didReplace second',
          'initial: didReplaceNext second two',
          'second: dispose',
        ]
      );
      runNavigatorTest(
        tester,
        host,
        (NavigatorState transaction) {
          transaction.pop('hello');
        },
        [
          'third: didPop hello',
          'two: didPopNext third',
        ]
      );
      runNavigatorTest(
        tester,
        host,
        (NavigatorState transaction) {
          transaction.pop('good bye');
        },
        [
          'two: didPop good bye',
          'initial: didPopNext two',
        ]
      );
    });
  });
}

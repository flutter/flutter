// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

Widget _buildScroller({Key key, List<String> log}) {
  return new ScrollableViewport(
    scrollableKey: key,
    onScrollStart: (double scrollOffset) {
      log.add('scrollstart');
    },
    onScroll: (double scrollOffset) {
      log.add('scroll');
    },
    onScrollEnd: (double scrollOffset) {
      log.add('scrollend');
    },
    child: new Container(width: 1000.0, height: 1000.0)
  );
}

void main() {
  testWidgets('Scroll event drag', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    TestGesture gesture = await tester.startGesture(new Point(100.0, 100.0));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart']));
    await gesture.moveBy(new Offset(-10.0, -10.0));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await gesture.up();
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll scrollTo animation', (WidgetTester tester) async {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals(<String>[]));
    // ignore: unawaited_futures
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll scrollTo no animation', (WidgetTester tester) async {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals(<String>[]));
    // ignore: unawaited_futures
    scrollKey.currentState.scrollTo(100.0);
    expect(log, equals(<String>['scrollstart', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll during animation', (WidgetTester tester) async {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals(<String>[]));
    // ignore: unawaited_futures
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    // ignore: unawaited_futures
    scrollKey.currentState.scrollTo(100.0);
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll during animation', (WidgetTester tester) async {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals(<String>[]));
    // ignore: unawaited_futures
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    // ignore: unawaited_futures
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
  });

  testWidgets('fling, fling generates two start/end pairs', (WidgetTester tester) async {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(new Point(100.0, 100.0), new Offset(-50.0, -50.0), 500.0);
    await tester.pump(new Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(<String>['scrollstart']));
    await tester.flingFrom(new Point(100.0, 100.0), new Offset(-50.0, -50.0), 500.0);
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(<String>['scrollstart', 'scrollend', 'scrollstart']));
    await tester.pump(new Duration(seconds: 1));
    await tester.pump(new Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(<String>['scrollstart', 'scrollend', 'scrollstart', 'scrollend']));
  });

  testWidgets('fling up ends', (WidgetTester tester) async {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(new Point(100.0, 100.0), new Offset(50.0, 50.0), 500.0);
    await tester.pump(new Duration(seconds: 1));
    await tester.pump(new Duration(seconds: 1));
    await tester.pump(new Duration(seconds: 1));
    expect(log.first, equals('scrollstart'));
    expect(log.last, equals('scrollend'));
    log.removeWhere((String value) => value == 'scroll');
    expect(log.length, equals(2));
    expect(scrollKey.currentState.scrollOffset, equals(0.0));
  });
}

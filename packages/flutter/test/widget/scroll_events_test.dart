// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

Widget _buildScroller({Key key, List<String> log}) {
  return new ScrollableViewport(
    key: key,
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
  testWidgets('Scroll event drag', (WidgetTester tester) {
    List<String> log = <String>[];
    tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals([]));
    TestGesture gesture = tester.startGesture(new Point(100.0, 100.0));
    expect(log, equals(['scrollstart']));
    tester.pump(const Duration(seconds: 1));
    expect(log, equals(['scrollstart']));
    gesture.moveBy(new Offset(-10.0, -10.0));
    expect(log, equals(['scrollstart', 'scroll']));
    tester.pump(const Duration(seconds: 1));
    expect(log, equals(['scrollstart', 'scroll']));
    gesture.up();
    expect(log, equals(['scrollstart', 'scroll']));
    tester.pump(const Duration(seconds: 1));
    expect(log, equals(['scrollstart', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll scrollTo animation', (WidgetTester tester) {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals([]));
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(['scrollstart']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart', 'scroll']));
    tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(['scrollstart', 'scroll', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll scrollTo no animation', (WidgetTester tester) {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals([]));
    scrollKey.currentState.scrollTo(100.0);
    expect(log, equals(['scrollstart', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll during animation', (WidgetTester tester) {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals([]));
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(['scrollstart']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart', 'scroll']));
    scrollKey.currentState.scrollTo(100.0);
    expect(log, equals(['scrollstart', 'scroll', 'scroll']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart', 'scroll', 'scroll', 'scrollend']));
    tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(['scrollstart', 'scroll', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll during animation', (WidgetTester tester) {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals([]));
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(['scrollstart']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart', 'scroll']));
    scrollKey.currentState.scrollTo(100.0, duration: const Duration(seconds: 1));
    expect(log, equals(['scrollstart', 'scroll']));
    tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(['scrollstart', 'scroll']));
    tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(['scrollstart', 'scroll', 'scroll', 'scrollend']));
  });

  testWidgets('fling, fling generates two start/end pairs', (WidgetTester tester) {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals([]));
    tester.flingFrom(new Point(100.0, 100.0), new Offset(-50.0, -50.0), 500.0);
    tester.pump(new Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(['scrollstart']));
    tester.flingFrom(new Point(100.0, 100.0), new Offset(-50.0, -50.0), 500.0);
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(['scrollstart', 'scrollend', 'scrollstart']));
    tester.pump(new Duration(seconds: 1));
    tester.pump(new Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(['scrollstart', 'scrollend', 'scrollstart', 'scrollend']));
  });

  testWidgets('fling up ends', (WidgetTester tester) {
    GlobalKey<ScrollableState<Scrollable>> scrollKey = new GlobalKey<ScrollableState<Scrollable>>();
    List<String> log = <String>[];
    tester.pumpWidget(_buildScroller(key: scrollKey, log: log));

    expect(log, equals([]));
    tester.flingFrom(new Point(100.0, 100.0), new Offset(50.0, 50.0), 500.0);
    tester.pump(new Duration(seconds: 1));
    tester.pump(new Duration(seconds: 1));
    tester.pump(new Duration(seconds: 1));
    expect(log.first, equals('scrollstart'));
    expect(log.last, equals('scrollend'));
    log.removeWhere((String value) => value == 'scroll');
    expect(log.length, equals(2));
    expect(scrollKey.currentState.scrollOffset, equals(0.0));
  });
}

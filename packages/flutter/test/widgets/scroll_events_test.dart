// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

Widget _buildScroller({ List<String> log }) {
  return new ScrollableViewport(
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
  Completer<Null> scrollTo(WidgetTester tester, double newScrollOffset, { Duration duration }) {
    Completer<Null> completer = new Completer<Null>();
    final ScrollableState scrollable = tester.state(find.byType(Scrollable));
    scrollable.scrollTo(newScrollOffset, duration: duration).whenComplete(completer.complete);
    return completer;
  }

  testWidgets('Scroll event drag', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    TestGesture gesture = await tester.startGesture(const Point(100.0, 100.0));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart']));
    await gesture.moveBy(const Offset(-10.0, -10.0));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await gesture.up();
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scrollend']));
  });

  testWidgets('Scroll scrollTo animation', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<Null> completer = scrollTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('Scroll scrollTo no animation', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<Null> completer = scrollTo(tester, 100.0);
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scrollstart', 'scroll', 'scrollend']));
    await tester.pump();
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('Scroll during animation', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<Null> completer = scrollTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    expect(completer.isCompleted, isFalse);

    completer = scrollTo(tester, 100.0);
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('Scroll during animation', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<Null> completer = scrollTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    expect(completer.isCompleted, isFalse);

    completer = scrollTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scrollstart', 'scroll']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scrollstart', 'scroll', 'scroll', 'scrollend']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('fling, fling generates two start/end pairs', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(const Point(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(<String>['scrollstart']));
    await tester.flingFrom(const Point(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(<String>['scrollstart', 'scrollend', 'scrollstart']));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll');
    expect(log, equals(<String>['scrollstart', 'scrollend', 'scrollstart', 'scrollend']));
  });

  testWidgets('fling up ends', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(const Point(100.0, 100.0), const Offset(50.0, 50.0), 500.0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(log.first, equals('scrollstart'));
    expect(log.last, equals('scrollend'));
    log.removeWhere((String value) => value == 'scroll');
    expect(log.length, equals(2));
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).scrollOffset, equals(0.0));
  });
}

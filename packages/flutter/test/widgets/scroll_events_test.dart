// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

Widget _buildScroller({ List<String> log }) {
  return new NotificationListener<ScrollNotification2>(
    onNotification: (ScrollNotification2 notification) {
      if (notification is ScrollStartNotification) {
        log.add('scroll-start');
      } else if (notification is ScrollUpdateNotification) {
        log.add('scroll-update');
      } else if (notification is ScrollEndNotification) {
        log.add('scroll-end');
      }
      return false;
    },
    child: new SingleChildScrollView(
      child: new Container(width: 1000.0, height: 1000.0),
    ),
  );
}

void main() {
  Completer<Null> animateTo(WidgetTester tester, double newScrollOffset, { @required Duration duration }) {
    Completer<Null> completer = new Completer<Null>();
    final Scrollable2State scrollable = tester.state(find.byType(Scrollable2));
    scrollable.position.animateTo(newScrollOffset, duration: duration, curve: Curves.linear).whenComplete(completer.complete);
    return completer;
  }

  void jumpTo(WidgetTester tester, double newScrollOffset) {
    final Scrollable2State scrollable = tester.state(find.byType(Scrollable2));
    scrollable.position.jumpTo(newScrollOffset);
  }

  testWidgets('Scroll event drag', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    TestGesture gesture = await tester.startGesture(const Point(100.0, 100.0));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scroll-start']));
    await gesture.moveBy(const Offset(-10.0, -10.0));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await gesture.up();
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
    await tester.pump(const Duration(seconds: 1));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
  });

  testWidgets('Scroll animateTo', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<Null> completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('Scroll jumpTo', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    jumpTo(tester, 100.0);
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
    await tester.pump();
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end']));
  });

  testWidgets('Scroll jumpTo during animation', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<Null> completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    expect(completer.isCompleted, isFalse);

    jumpTo(tester, 100.0);
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end', 'scroll-start', 'scroll-update', 'scroll-end']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end', 'scroll-start', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-end', 'scroll-start', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('Scroll scrollTo during animation', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    Completer<Null> completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    expect(completer.isCompleted, isFalse);

    completer = animateTo(tester, 100.0, duration: const Duration(seconds: 1));
    expect(completer.isCompleted, isFalse);
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, equals(<String>['scroll-start', 'scroll-update']));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(log, equals(<String>['scroll-start', 'scroll-update', 'scroll-update', 'scroll-end']));
    expect(completer.isCompleted, isTrue);
  });

  testWidgets('fling, fling generates two start/end pairs', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(const Point(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start']));
    await tester.flingFrom(const Point(100.0, 100.0), const Offset(-50.0, -50.0), 500.0);
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start', 'scroll-end', 'scroll-start']));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log, equals(<String>['scroll-start', 'scroll-end', 'scroll-start', 'scroll-end']));
  });

  testWidgets('fling up ends', (WidgetTester tester) async {
    List<String> log = <String>[];
    await tester.pumpWidget(_buildScroller(log: log));

    expect(log, equals(<String>[]));
    await tester.flingFrom(const Point(100.0, 100.0), const Offset(50.0, 50.0), 500.0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(log.first, equals('scroll-start'));
    expect(log.last, equals('scroll-end'));
    log.removeWhere((String value) => value == 'scroll-update');
    expect(log.length, equals(2));
    expect(tester.state<Scrollable2State>(find.byType(Scrollable2)).position.pixels, equals(0.0));
  });
}

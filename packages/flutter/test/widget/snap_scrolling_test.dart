// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

const double itemExtent = 200.0;
Axis scrollDirection = Axis.vertical;
GlobalKey scrollableListKey;

Widget buildItem(int item) {
  return new Container(
    width: itemExtent,
    height: itemExtent,
    child: new Text(item.toString())
  );
}

double snapOffsetCallback(double offset, Size size) {
  return (offset / itemExtent).floor() * itemExtent;
}

Widget buildFrame() {
  scrollableListKey = new GlobalKey();
  return new Center(
    child: new Container(
      height: itemExtent * 2.0,
      child: new ScrollableList(
        scrollableKey: scrollableListKey,
        snapOffsetCallback: snapOffsetCallback,
        scrollDirection: scrollDirection,
        itemExtent: itemExtent,
        children: <int>[0, 1, 2, 3, 4, 5, 7, 8, 9].map(buildItem)
      )
    )
  );
}

ScrollableState get scrollableState => scrollableListKey.currentState;

double get scrollOffset =>  scrollableState.scrollOffset;
set scrollOffset(double value) {
  scrollableState.scrollTo(value);
}

Completer<Null> fling(double velocity) {
  Completer<Null> completer = new Completer<Null>();
  scrollableState.fling(velocity).whenComplete(completer.complete);
  return completer;
}

void main() {
  testWidgets('ScrollableList snap scrolling', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame());

    scrollOffset = 0.0;
    await tester.pump();
    expect(scrollOffset, 0.0);

    Duration dt = const Duration(seconds: 2);

    Completer<Null> completer = fling(1000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump(); // Start the scheduler at 0.0
    await tester.pump(dt);
    expect(scrollOffset, closeTo(200.0, 1.0));
    expect(completer.isCompleted, isTrue);

    scrollOffset = 0.0;
    await tester.pump();
    expect(scrollOffset, 0.0);

    completer = fling(2000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(scrollOffset, closeTo(400.0, 1.0));
    expect(completer.isCompleted, isTrue);

    scrollOffset = 400.0;
    await tester.pump();
    expect(scrollOffset, 400.0);

    completer = fling(-800.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(scrollOffset, closeTo(0.0, 1.0));
    expect(completer.isCompleted, isTrue);

    scrollOffset = 800.0;
    await tester.pump();
    expect(scrollOffset, 800.0);

    completer = fling(-2000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(scrollOffset, closeTo(200.0, 1.0));
    expect(completer.isCompleted, isTrue);

    scrollOffset = 800.0;
    await tester.pump();
    expect(scrollOffset, 800.0);

    completer = fling(-2000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(completer.isCompleted, isTrue);
    expectSync(scrollOffset, closeTo(200.0, 1.0));
  });
}

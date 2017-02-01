// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

const double itemExtent = 200.0;
Axis scrollDirection = Axis.vertical;

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

class TestScrollConfigurationDelegate extends ScrollConfigurationDelegate {
  const TestScrollConfigurationDelegate();

  // Not testing platform-specific fling scrolling, use the default fling
  // decleration simulation.
  @override
  TargetPlatform get platform => null;

  @override
  ExtentScrollBehavior createScrollBehavior() => new OverscrollWhenScrollableBehavior(platform: platform);

  @override
  bool updateShouldNotify(ScrollConfigurationDelegate old) => false;
}

Widget buildFrame() {
  return new ScrollConfiguration(
    delegate: const TestScrollConfigurationDelegate(),
    child: new Center(
      child: new Container(
        height: itemExtent * 2.0,
        child: new ScrollableList(
          snapOffsetCallback: snapOffsetCallback,
          scrollDirection: scrollDirection,
          itemExtent: itemExtent,
          children: <int>[0, 1, 2, 3, 4, 5, 7, 8, 9].map(buildItem)
        )
      )
    )
  );
}

void main() {
  testWidgets('ScrollableList snap scrolling', (WidgetTester tester) async {
    ScrollableState getScrollableState() => tester.state(find.byType(Scrollable));

    double getScrollOffset() => getScrollableState().scrollOffset;
    void setScrollOffset(double value) {
      getScrollableState().scrollTo(value);
    }

    Completer<Null> fling(double velocity) {
      Completer<Null> completer = new Completer<Null>();
      getScrollableState().fling(velocity).whenComplete(completer.complete);
      return completer;
    }

    await tester.pumpWidget(buildFrame());

    setScrollOffset(0.0);
    await tester.pump();
    expect(getScrollOffset(), 0.0);

    Duration dt = const Duration(seconds: 2);

    Completer<Null> completer = fling(1000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump(); // Start the scheduler at 0.0
    await tester.pump(dt);
    expect(getScrollOffset(), closeTo(200.0, 1.0));
    expect(completer.isCompleted, isTrue);

    setScrollOffset(0.0);
    await tester.pump();
    expect(getScrollOffset(), 0.0);

    completer = fling(2000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(getScrollOffset(), closeTo(400.0, 1.0));
    expect(completer.isCompleted, isTrue);

    setScrollOffset(400.0);
    await tester.pump();
    expect(getScrollOffset(), 400.0);

    completer = fling(-800.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(getScrollOffset(), closeTo(0.0, 1.0));
    expect(completer.isCompleted, isTrue);

    setScrollOffset(800.0);
    await tester.pump();
    expect(getScrollOffset(), 800.0);

    completer = fling(-2000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(getScrollOffset(), closeTo(200.0, 1.0));
    expect(completer.isCompleted, isTrue);

    setScrollOffset(800.0);
    await tester.pump();
    expect(getScrollOffset(), 800.0);

    completer = fling(-2000.0);
    expect(completer.isCompleted, isFalse);
    await tester.pump();
    await tester.pump(dt);
    expect(completer.isCompleted, isTrue);
    expectSync(getScrollOffset(), closeTo(200.0, 1.0));
  });
}

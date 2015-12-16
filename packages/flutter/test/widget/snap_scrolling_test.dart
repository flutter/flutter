// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

const double itemExtent = 200.0;
ScrollDirection scrollDirection = ScrollDirection.vertical;
GlobalKey scrollableListKey;

Widget buildItem(BuildContext context, int item, int index) {
  return new Container(
    key: new ValueKey<int>(item),
    width: itemExtent,
    height: itemExtent,
    child: new Text(item.toString())
  );
}

double snapOffsetCallback(double offset) {
  return (offset / itemExtent).floor() * itemExtent;
}

Widget buildFrame() {
  scrollableListKey = new GlobalKey();
  return new Center(
    child: new Container(
      height: itemExtent * 2.0,
      child: new ScrollableList<int>(
        key: scrollableListKey,
        snapOffsetCallback: snapOffsetCallback,
        scrollDirection: scrollDirection,
        items: <int>[0, 1, 2, 3, 4, 5, 7, 8, 9],
        itemBuilder: buildItem,
        itemExtent: itemExtent
      )
    )
  );
}

ScrollableState get scrollableState => scrollableListKey.currentState;

double get scrollOffset =>  scrollableState.scrollOffset;
void set scrollOffset(double value) {
  scrollableState.scrollTo(value);
}

Future fling(double velocity) {
  Offset velocityOffset = scrollDirection == ScrollDirection.vertical
    ? new Offset(0.0, velocity)
    : new Offset(velocity, 0.0);
  return scrollableState.fling(velocityOffset);
}

void main() {
  test('ScrollableList snap scrolling, fling(-0.8)', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(buildFrame());

      scrollOffset = 0.0;
      tester.pump();
      expect(scrollOffset, 0.0);

      Duration dt = const Duration(seconds: 2);

      fling(-0.8);
      tester.pump(); // Start the scheduler at 0.0
      tester.pump(dt);
      expect(scrollOffset, closeTo(200.0, 1.0));

      scrollOffset = 0.0;
      tester.pump();
      expect(scrollOffset, 0.0);

      fling(-2.0);
      tester.pump();
      tester.pump(dt);
      expect(scrollOffset, closeTo(400.0, 1.0));

      scrollOffset = 400.0;
      tester.pump();
      expect(scrollOffset, 400.0);

      fling(0.8);
      tester.pump();
      tester.pump(dt);
      expect(scrollOffset, closeTo(0.0, 1.0));

      scrollOffset = 800.0;
      tester.pump();
      expect(scrollOffset, 800.0);

      fling(2.0);
      tester.pump();
      tester.pump(dt);
      expect(scrollOffset, closeTo(200.0, 1.0));

      scrollOffset = 800.0;
      tester.pump();
      expect(scrollOffset, 800.0);

      bool completed = false;
      fling(2.0).then((_) {
        completed = true;
        expect(scrollOffset, closeTo(200.0, 1.0));
      });
      tester.pump();
      tester.pump(dt);
      expect(completed, true);
    });
  });
}

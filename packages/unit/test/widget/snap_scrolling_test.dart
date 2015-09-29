// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:quiver/testing/async.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../fn3/widget_tester.dart';

const double itemExtent = 200.0;
ScrollDirection scrollDirection = ScrollDirection.vertical;
GlobalKey scrollableListKey;

Widget buildItem(BuildContext context, int item) {
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

Widget buildScrollableList() {
  scrollableListKey = new GlobalKey();
  return new Container(
    height: itemExtent * 2.0,
    child: new ScrollableList<int>(
      key: scrollableListKey,
      snapOffsetCallback: snapOffsetCallback,
      scrollDirection: scrollDirection,
      items: [0, 1, 2, 3, 4, 5, 7, 8, 9],
      itemBuilder: buildItem,
      itemExtent: itemExtent
    )
  );
}

ScrollableState get scrollableState => scrollableListKey.currentState;

double get scrollOffset =>  scrollableState.scrollOffset;
void set scrollOffset(double value) {
  scrollableState.scrollTo(value);
}

void fling(double velocity) {
  Offset velocityOffset = scrollDirection == ScrollDirection.vertical
    ? new Offset(0.0, velocity)
    : new Offset(velocity, 0.0);
  scrollableState.fling(velocityOffset);
}

void main() {
  test('ScrollableList snap scrolling, fling(-800)', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(new Center(child: buildScrollableList()));
    expect(scrollOffset, 0.0);

    new FakeAsync().run((async) {
      fling(-800.0);
      tester.pumpFrameWithoutChange(); // Start the scheduler at 0.0
      tester.pumpFrameWithoutChange(1000.0);
      async.elapse(new Duration(seconds: 1));
      expect(scrollOffset, closeTo(200.0, 1.0));
    });
  });

  test('ScrollableList snap scrolling, fling(-2000)', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(new Center(child: buildScrollableList()));
    expect(scrollOffset, 0.0);

    new FakeAsync().run((async) {
      fling(-2000.0);
      tester.pumpFrameWithoutChange(); // Start the scheduler at 0.0
      tester.pumpFrameWithoutChange(1000.0);
      async.elapse(new Duration(seconds: 1));
      expect(scrollOffset, closeTo(400.0, 1.0));
    });
  });
}

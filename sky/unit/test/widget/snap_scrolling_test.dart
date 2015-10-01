// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:quiver/testing/async.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

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

Widget buildFrame() {
  scrollableListKey = new GlobalKey();
  return new Center(
    child: new Container(
      height: itemExtent * 2.0,
      child: new ScrollableList<int>(
        key: scrollableListKey,
        snapOffsetCallback: snapOffsetCallback,
        scrollDirection: scrollDirection,
        items: [0, 1, 2, 3, 4, 5, 7, 8, 9],
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
  WidgetTester tester = new WidgetTester();
  tester.pumpFrame(buildFrame());

  test('ScrollableList snap scrolling, fling(-800)', () {
    scrollOffset = 0.0;
    tester.pumpFrameWithoutChange();
    expect(scrollOffset, 0.0);

    double t0 = 0.0;
    int dt = 2000;
    new FakeAsync().run((async) {
      fling(-800.0);
      tester.pumpFrameWithoutChange(t0); // Start the scheduler at 0.0
      tester.pumpFrameWithoutChange(t0 + dt);
      async.elapse(new Duration(milliseconds: dt));
      expect(scrollOffset, closeTo(200.0, 1.0));
    });
  });

  test('ScrollableList snap scrolling, fling(-2000)', () {
    scrollOffset = 0.0;
    tester.pumpFrameWithoutChange();
    expect(scrollOffset, 0.0);

    double t0 = 0.0;
    int dt = 2000;
    new FakeAsync().run((async) {
      fling(-2000.0);
      tester.pumpFrameWithoutChange(t0);
      tester.pumpFrameWithoutChange(t0 + dt);
      async.elapse(new Duration(milliseconds: dt));
      expect(scrollOffset, closeTo(400.0, 1.0));
    });
  });

  test('ScrollableList snap scrolling, fling(800)', () {
    scrollOffset = 400.0;
    tester.pumpFrameWithoutChange();
    expect(scrollOffset, 400.0);

    double t0 = 0.0;
    int dt = 2000;
    new FakeAsync().run((async) {
      fling(800.0);
      tester.pumpFrameWithoutChange(t0);
      tester.pumpFrameWithoutChange(t0 + dt);
      async.elapse(new Duration(milliseconds: dt));
      expect(scrollOffset, closeTo(0.0, 1.0));
    });
  });

  test('ScrollableList snap scrolling, fling(2000)', () {
    scrollOffset = 800.0;
    tester.pumpFrameWithoutChange();
    expect(scrollOffset, 800.0);

    double t0 = 0.0;
    int dt = 2000;
    new FakeAsync().run((async) {
      fling(2000.0);
      tester.pumpFrameWithoutChange(t0);
      tester.pumpFrameWithoutChange(t0 + dt);
      async.elapse(new Duration(milliseconds: dt));
      expect(scrollOffset, closeTo(200.0, 1.0));
    });
  });

  test('ScrollableList snap scrolling, fling(2000).then()', () {
    scrollOffset = 800.0;
    tester.pumpFrameWithoutChange();
    expect(scrollOffset, 800.0);

    double t0 = 0.0;
    int dt = 2000;
    bool completed = false;
    new FakeAsync().run((async) {
      fling(2000.0).then((_) {
        completed = true;
        expect(scrollOffset, closeTo(200.0, 1.0));
      });
      tester.pumpFrameWithoutChange(t0);
      tester.pumpFrameWithoutChange(t0 + dt);
      async.elapse(new Duration(milliseconds: dt));
      expect(completed, true);
    });
  });

}

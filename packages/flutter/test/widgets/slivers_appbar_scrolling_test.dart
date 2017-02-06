// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

void verifyPaintPosition(GlobalKey key, Offset ideal) {
  RenderObject target = key.currentContext.findRenderObject();
  expect(target.parent, new isInstanceOf<RenderViewport2>());
  SliverPhysicalParentData parentData = target.parentData;
  Offset actual = parentData.paintOffset;
  expect(actual, ideal);
}

void main() {
  testWidgets('Sliver appbars - scrolling', (WidgetTester tester) async {
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      new TestScrollable(
        axisDirection: AxisDirection.down,
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey()),
          new SliverPersistentHeader(key: key2 = new GlobalKey(), delegate: new TestDelegate()),
          new SliverPersistentHeader(key: key3 = new GlobalKey(), delegate: new TestDelegate()),
          new BigSliver(key: key4 = new GlobalKey()),
          new BigSliver(key: key5 = new GlobalKey()),
        ],
      ),
    );
    ScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;
    final double max = RenderBigSliver.height * 3.0 + new TestDelegate().maxExtent * 2.0 - 600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1450.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animate(to: 10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    verifyPaintPosition(key1, new Offset(0.0, 0.0));
    verifyPaintPosition(key2, new Offset(0.0, 0.0));
    verifyPaintPosition(key3, new Offset(0.0, 0.0));
    verifyPaintPosition(key4, new Offset(0.0, 0.0));
    verifyPaintPosition(key5, new Offset(0.0, 50.0));
  });

  testWidgets('Sliver appbars - scrolling off screen', (WidgetTester tester) async {
    GlobalKey key = new GlobalKey();
    TestDelegate delegate = new TestDelegate();
    await tester.pumpWidget(
      new TestScrollable(
        axisDirection: AxisDirection.down,
        slivers: <Widget>[
          new BigSliver(),
          new SliverPersistentHeader(key: key, delegate: delegate),
          new BigSliver(),
          new BigSliver(),
        ],
      ),
    );
    ScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;
    position.animate(to: RenderBigSliver.height + delegate.maxExtent - 5.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 1000));
    RenderBox box = tester.renderObject<RenderBox>(find.byType(Container));
    Rect rect = new Rect.fromPoints(box.localToGlobal(Point.origin), box.localToGlobal(box.size.bottomRight(Point.origin)));
    expect(rect, equals(new Rect.fromLTWH(0.0, -195.0, 800.0, 200.0)));
  });
}

class TestDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get maxExtent => 200.0;

  @override
  Widget build(BuildContext context, double shrinkOffset) {
    return new Container(height: maxExtent);
  }

  @override
  bool shouldRebuild(TestDelegate oldDelegate) => false;
}


class RenderBigSliver extends RenderSliver {
  static const double height = 550.0;
  double get paintExtent => (height - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);

  @override
  void performLayout() {
    geometry = new SliverGeometry(
      scrollExtent: height,
      paintExtent: paintExtent,
      maxPaintExtent: height,
    );
  }
}

class BigSliver extends LeafRenderObjectWidget {
  BigSliver({ Key key }) : super(key: key);
  @override
  RenderBigSliver createRenderObject(BuildContext context) {
    return new RenderBigSliver();
  }
}

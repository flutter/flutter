// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void verifyPaintPosition(GlobalKey key, Offset ideal, bool visible) {
  final RenderSliver target = key.currentContext.findRenderObject();
  expect(target.parent, const isInstanceOf<RenderViewport>());
  final SliverPhysicalParentData parentData = target.parentData;
  final Offset actual = parentData.paintOffset;
  expect(actual, ideal);
  final SliverGeometry geometry = target.geometry;
  expect(geometry.visible, visible);
}

void verifyActualBoxPosition(WidgetTester tester, Finder finder, int index, Rect ideal) {
  final RenderBox box = tester.renderObjectList<RenderBox>(finder).elementAt(index);
  final Rect rect = new Rect.fromPoints(box.localToGlobal(Offset.zero), box.localToGlobal(box.size.bottomRight(Offset.zero)));
  expect(rect, equals(ideal));
}

void main() {
  testWidgets('Sliver appbars - pinned', (WidgetTester tester) async {
    const double bigHeight = 550.0;
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverPersistentHeader(key: key2 = new GlobalKey(), delegate: new TestDelegate(), pinned: true),
          new SliverPersistentHeader(key: key3 = new GlobalKey(), delegate: new TestDelegate(), pinned: true),
          new BigSliver(key: key4 = new GlobalKey(), height: bigHeight),
          new BigSliver(key: key5 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max = bigHeight * 3.0 + new TestDelegate().maxExtent * 2.0 - 600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1450.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 50.0), true);
  });

  testWidgets('Sliver appbars - pinned with slow scroll', (WidgetTester tester) async {
    const double bigHeight = 550.0;
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverPersistentHeader(key: key2 = new GlobalKey(), delegate: new TestDelegate(), pinned: true),
          new SliverPersistentHeader(key: key3 = new GlobalKey(), delegate: new TestDelegate(), pinned: true),
          new BigSliver(key: key4 = new GlobalKey(), height: bigHeight),
          new BigSliver(key: key5 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    verifyPaintPosition(key1, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, const Offset(0.0, 550.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 600.0), false);
    verifyPaintPosition(key4, const Offset(0.0, 600.0), false);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(550.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 200.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 400.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(600.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 150.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 350.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(650.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 1, new Rect.fromLTWH(0.0, 100.0, 800.0, 200.0));
    verifyPaintPosition(key4, const Offset(0.0, 300.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(700.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 1, new Rect.fromLTWH(0.0, 100.0, 800.0, 200.0));
    verifyPaintPosition(key4, const Offset(0.0, 250.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(750.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 1, new Rect.fromLTWH(0.0, 100.0, 800.0, 200.0));
    verifyPaintPosition(key4, const Offset(0.0, 200.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(800.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 60));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 150.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(850.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 70));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(900.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 80));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 50.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 600.0), false);
    position.animateTo(950.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 90));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 1, new Rect.fromLTWH(0.0, 100.0, 800.0, 100.0));
    verifyPaintPosition(key4, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key5, const Offset(0.0, 550.0), true);
  });

  testWidgets('Sliver appbars - pinned with less overlap', (WidgetTester tester) async {
    const double bigHeight = 650.0;
    GlobalKey key1, key2, key3, key4, key5;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverPersistentHeader(key: key2 = new GlobalKey(), delegate: new TestDelegate(), pinned: true),
          new SliverPersistentHeader(key: key3 = new GlobalKey(), delegate: new TestDelegate(), pinned: true),
          new BigSliver(key: key4 = new GlobalKey(), height: bigHeight),
          new BigSliver(key: key5 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max = bigHeight * 3.0 + new TestDelegate().maxExtent * 2.0 - 600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1750.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 10));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key3, const Offset(0.0, 100.0), true);
    verifyPaintPosition(key4, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key5, const Offset(0.0, 0.0), true);
  });

  testWidgets('Sliver appbars - overscroll gap is below header', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          new SliverPersistentHeader(delegate: new TestDelegate(), pinned: true),
          new SliverList(
            delegate: new SliverChildListDelegate(<Widget>[
              const SizedBox(
                height: 300.0,
                child: const Text('X'),
              ),
            ]),
          ),
        ],
      ),
    );

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 200.0));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(-50.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 250.0));

    position.jumpTo(50.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 150.0));

    position.jumpTo(150.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(Container)), Offset.zero);
    expect(tester.getTopLeft(find.text('X')), const Offset(0.0, 50.0));
  });
}

class TestDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get maxExtent => 200.0;

  @override
  double get minExtent => 100.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(constraints: new BoxConstraints(minHeight: minExtent, maxHeight: maxExtent));
  }

  @override
  bool shouldRebuild(TestDelegate oldDelegate) => false;
}


class RenderBigSliver extends RenderSliver {
  RenderBigSliver(double height) : _height = height;

  double get height => _height;
  double _height;
  set height(double value) {
    if (value == _height)
      return;
    _height = value;
    markNeedsLayout();
  }

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
  BigSliver({ Key key, this.height }) : super(key: key);

  final double height;

  @override
  RenderBigSliver createRenderObject(BuildContext context) {
    return new RenderBigSliver(height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBigSliver renderObject) {
    renderObject.height = height;
  }
}

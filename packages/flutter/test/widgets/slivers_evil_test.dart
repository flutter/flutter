// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

class TestSliverAppBarDelegate extends SliverAppBarDelegate {
  TestSliverAppBarDelegate(this._maxExtent);

  final double _maxExtent;

  @override
  double get maxExtent => _maxExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset) {
    return new Column(
      children: <Widget>[
        new Container(height: 16.0),
        new Expanded(child: new Container()),
      ],
    );
  }

  @override
  bool shouldRebuild(TestSliverAppBarDelegate oldDelegate) => false;
}

class TestBehavior extends ScrollBehavior2 {
  @override
  Widget wrap(BuildContext context, Widget child, AxisDirection axisDirection) {
    return new GlowingOverscrollIndicator(
      child: child,
      axisDirection: axisDirection,
      color: const Color(0xFFFFFFFF),
    );
  }

  @override
  ScrollPosition createScrollPosition(BuildContext context, Scrollable2State state, ScrollPosition oldPosition) {
    return new TestViewportScrollPosition(
      state,
      new Tolerance(velocity: 20.0, distance: 1.0),
      oldPosition,
    );
  }

  @override
  bool shouldNotify(TestBehavior oldDelegate) => false;
}

class TestViewportScrollPosition extends AbsoluteScrollPosition
  with ClampingAbsoluteScrollPositionMixIn {
  TestViewportScrollPosition(
    Scrollable2State state,
    Tolerance scrollTolerances,
    ScrollPosition oldPosition,
  ) : super(state, scrollTolerances, oldPosition);

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    expect(minScrollExtent, moreOrLessEquals(-3895.0));
    expect(maxScrollExtent, moreOrLessEquals(8575.0));
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }
}

void main() {
  testWidgets('Evil test of sliver features - 1', (WidgetTester tester) async {
    final GlobalKey<Scrollable2State> scrollableKey = new GlobalKey<Scrollable2State>();
    final GlobalKey centerKey = new GlobalKey();
    await tester.pumpWidget(
      new Scrollbar2(
        child: new ScrollableViewport2(
          key: scrollableKey,
          axisDirection: AxisDirection.down,
          center: centerKey,
          anchor: 0.25,
          scrollBehavior: new TestBehavior(),
          slivers: <Widget>[
            new SliverToBoxAdapter(child: new Container(height: 5.0)),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(150.0), pinned: true),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverPadding(
              padding: new EdgeInsets.all(50.0),
              child: new SliverToBoxAdapter(child: new Container(height: 520.0)),
            ),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(150.0), floating: true),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverToBoxAdapter(key: centerKey, child: new Container(height: 520.0)), // ------------------------ CENTER ------------------------
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(150.0), pinned: true),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverPadding(
              padding: new EdgeInsets.all(50.0),
              child: new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0), pinned: true),
            ),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0), pinned: true),
            new SliverToBoxAdapter(child: new Container(height: 5.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0), pinned: true),
            new SliverToBoxAdapter(child: new Container(height: 5.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0), pinned: true),
                        new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0), pinned: true),
            new SliverToBoxAdapter(child: new Container(height: 5.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0), pinned: true),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0)),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(150.0), floating: true),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(150.0), floating: true),
            new SliverToBoxAdapter(child: new Container(height: 5.0)),
            new SliverBlock(
              delegate: new SliverChildListDelegate(<Widget>[
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
                new Container(height: 50.0),
              ]),
            ),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0)),
            new SliverAppBar(delegate: new TestSliverAppBarDelegate(250.0)),
            new SliverPadding(
              padding: new EdgeInsets.symmetric(horizontal: 50.0),
              child: new SliverToBoxAdapter(child: new Container(height: 520.0)),
            ),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverToBoxAdapter(child: new Container(height: 520.0)),
            new SliverToBoxAdapter(child: new Container(height: 5.0)),
          ],
        ),
      ),
    );
    AbsoluteScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;

    position.animate(to: 10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 122));

    position.animate(to: -10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 122));

    position.animate(to: 10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 122));

    position.animate(to: -10000.0, curve: Curves.linear, duration: const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 122));

    position.animate(to: 10000.0, curve: Curves.linear, duration: const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 122));

  });
}

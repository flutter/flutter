// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

import 'test_widgets.dart';

class TestSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  TestSliverPersistentHeaderDelegate(this._maxExtent);

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
  bool shouldRebuild(TestSliverPersistentHeaderDelegate oldDelegate) => false;
}

class TestBehavior extends ScrollBehavior2 {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return new GlowingOverscrollIndicator(
      child: child,
      axisDirection: axisDirection,
      color: const Color(0xFFFFFFFF),
    );
  }
}

class TestScrollPhysics extends ClampingScrollPhysics {
  const TestScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

  @override
  TestScrollPhysics applyTo(ScrollPhysics parent) => new TestScrollPhysics(parent: parent);

  @override
  Tolerance get tolerance => new Tolerance(velocity: 20.0, distance: 1.0);
}

class TestViewportScrollPosition extends ScrollPosition {
  TestViewportScrollPosition(
    ScrollPhysics physics,
    AbstractScrollState state,
    ScrollPosition oldPosition,
  ) : super(physics, state, oldPosition);

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    expect(minScrollExtent, moreOrLessEquals(-3895.0));
    expect(maxScrollExtent, moreOrLessEquals(8575.0));
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }
}

void main() {
  testWidgets('Evil test of sliver features - 1', (WidgetTester tester) async {
    final GlobalKey centerKey = new GlobalKey();
    await tester.pumpWidget(
      new ScrollConfiguration2(
        behavior: new TestBehavior(),
        child: new Scrollbar2(
          child: new TestScrollable(
            axisDirection: AxisDirection.down,
            center: centerKey,
            anchor: 0.25,
            physics: const TestScrollPhysics(),
            slivers: <Widget>[
              new SliverToBoxAdapter(child: new Container(height: 5.0)),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(150.0), pinned: true),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverPadding(
                padding: new EdgeInsets.all(50.0),
                child: new SliverToBoxAdapter(child: new Container(height: 520.0)),
              ),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(150.0), floating: true),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverToBoxAdapter(key: centerKey, child: new Container(height: 520.0)), // ------------------------ CENTER ------------------------
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(150.0), pinned: true),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverPadding(
                padding: new EdgeInsets.all(50.0),
                child: new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0), pinned: true),
              ),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0), pinned: true),
              new SliverToBoxAdapter(child: new Container(height: 5.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0), pinned: true),
              new SliverToBoxAdapter(child: new Container(height: 5.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0), pinned: true),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0), pinned: true),
              new SliverToBoxAdapter(child: new Container(height: 5.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0), pinned: true),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0)),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(150.0), floating: true),
              new SliverToBoxAdapter(child: new Container(height: 520.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(150.0), floating: true),
              new SliverToBoxAdapter(child: new Container(height: 5.0)),
              new SliverList(
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
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0)),
              new SliverPersistentHeader(delegate: new TestSliverPersistentHeaderDelegate(250.0)),
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
      ),
    );
    ScrollPosition position = tester.state<Scrollable2State>(find.byType(Scrollable2)).position;

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

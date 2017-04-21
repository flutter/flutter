// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TestScrollPosition extends ScrollPosition {
  TestScrollPosition({
    ScrollPhysics physics,
    AbstractScrollState state,
    ScrollPosition oldPosition,
  }) : _pixels = 100.0, super(
    physics: physics,
    state: state,
    oldPosition: oldPosition,
  ) {
    assert(physics is TestScrollPhysics);
  }

  @override
  TestScrollPhysics get physics => super.physics;

  double _pixels;

  @override
  double get pixels => _pixels;

  @override
  double setPixels(double value) {
    final double oldPixels = _pixels;
    _pixels = value;
    state.dispatchNotification(activity.createScrollUpdateNotification(state, _pixels - oldPixels));
    return 0.0;
  }

  @override
  void correctBy(double correction) {
    _pixels += correction;
  }

  @override
  ScrollMetrics getMetrics() {
    final double insideExtent = viewportDimension;
    final double beforeExtent = _pixels - minScrollExtent;
    final double afterExtent = maxScrollExtent - _pixels;
    if (insideExtent > 0.0) {
      return new ScrollMetrics(
        extentBefore: physics.extentMultiplier * beforeExtent / insideExtent,
        extentInside: physics.extentMultiplier,
        extentAfter: physics.extentMultiplier * afterExtent / insideExtent,
        viewportDimension: viewportDimension,
      );
    } else {
      return new ScrollMetrics(
        extentBefore: 0.0,
        extentInside: 0.0,
        extentAfter: 0.0,
        viewportDimension: viewportDimension,
      );
    }
  }

  @override
  Future<Null> ensureVisible(RenderObject object, {
    double alignment: 0.0,
    Duration duration: Duration.ZERO,
    Curve curve: Curves.ease,
  }) {
    return new Future<Null>.value();
  }
}

class TestScrollPhysics extends ScrollPhysics {
  const TestScrollPhysics({ this.extentMultiplier, ScrollPhysics parent }) : super(parent);

  final double extentMultiplier;

  @override
  ScrollPhysics applyTo(ScrollPhysics parent) {
    return new TestScrollPhysics(
      extentMultiplier: extentMultiplier,
      parent: parent,
    );
  }
}

class TestScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, AbstractScrollState state, ScrollPosition oldPosition) {
    return new TestScrollPosition(physics: physics, state: state, oldPosition: oldPosition);
  }
}

class TestScrollBehavior extends ScrollBehavior {
  const TestScrollBehavior(this.extentMultiplier);

  final double extentMultiplier;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return new TestScrollPhysics(
      extentMultiplier: extentMultiplier
    ).applyTo(super.getScrollPhysics(context));
  }

  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) => child;

  @override
  bool shouldNotify(TestScrollBehavior oldDelegate) {
    return extentMultiplier != oldDelegate.extentMultiplier;
  }
}

void main() {
  testWidgets('Changing the scroll behavior dynamically', (WidgetTester tester) async {
    await tester.pumpWidget(new ScrollConfiguration(
      behavior: const TestScrollBehavior(1.0),
      child: new CustomScrollView(
        controller: new TestScrollController(),
        slivers: <Widget>[
          const SliverToBoxAdapter(child: const SizedBox(height: 2000.0)),
        ],
      ),
    ));
    final ScrollableState state = tester.state(find.byType(Scrollable));

    expect(state.position.getMetrics().extentInside, 1.0);
    await tester.pumpWidget(new ScrollConfiguration(
      behavior: const TestScrollBehavior(2.0),
      child: new CustomScrollView(
        controller: new TestScrollController(),
        slivers: <Widget>[
          const SliverToBoxAdapter(child: const SizedBox(height: 2000.0)),
        ],
      ),
    ));
    expect(state.position.getMetrics().extentInside, 2.0);
  });
}

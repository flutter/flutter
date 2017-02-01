// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'test_widgets.dart';

class TestScrollPosition extends ScrollPosition {
  TestScrollPosition(
    TestScrollPhysics physics,
    AbstractScrollState state,
    ScrollPosition oldPosition,
  ) : _pixels = 100.0, super(physics, state, oldPosition);

  @override
  TestScrollPhysics get physics => super.physics;

  double _min, _viewport, _max, _pixels;

  @override
  double get pixels => _pixels;

  @override
  double setPixels(double value) {
    double oldPixels = _pixels;
    _pixels = value;
    state.dispatchNotification(activity.createScrollUpdateNotification(state, _pixels - oldPixels));
    return 0.0;
  }

  @override
  void correctBy(double correction) {
    _pixels += correction;
  }

  @override
  void applyViewportDimension(double viewportDimension) {
    _viewport = viewportDimension;
    super.applyViewportDimension(viewportDimension);
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    _min = minScrollExtent;
    _max = maxScrollExtent;
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  ScrollableMetrics getMetrics() {
    double insideExtent = _viewport;
    double beforeExtent = _pixels - _min;
    double afterExtent = _max - _pixels;
    if (insideExtent > 0.0) {
      return new ScrollableMetrics(
        extentBefore: physics.extentMultiplier * beforeExtent / insideExtent,
        extentInside: physics.extentMultiplier,
        extentAfter: physics.extentMultiplier * afterExtent / insideExtent,
      );
    } else {
      return new ScrollableMetrics(
        extentBefore: 0.0,
        extentInside: 0.0,
        extentAfter: 0.0,
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
  const TestScrollPhysics({ ScrollPhysics parent, this.extentMultiplier }) : super(parent);

  final double extentMultiplier;

  @override
  TestScrollPhysics applyTo(ScrollPhysics parent) {
    return new TestScrollPhysics(parent: parent, extentMultiplier: extentMultiplier);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, AbstractScrollState state, ScrollPosition oldPosition) {
    return new TestScrollPosition(physics, state, oldPosition);
  }
}

class TestScrollBehavior extends ScrollBehavior2 {
  TestScrollBehavior(this.extentMultiplier);

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
    await tester.pumpWidget(new ScrollConfiguration2(
      behavior: new TestScrollBehavior(1.0),
      child: new TestScrollable(
        slivers: <Widget>[
          new SliverToBoxAdapter(child: new SizedBox(height: 2000.0)),
        ],
      ),
    ));
    Scrollable2State state = tester.state(find.byType(Scrollable2));

    expect(state.position.getMetrics().extentInside, 1.0);
    await tester.pumpWidget(new ScrollConfiguration2(
      behavior: new TestScrollBehavior(2.0),
      child: new TestScrollable(
        slivers: <Widget>[
          new SliverToBoxAdapter(child: new SizedBox(height: 2000.0)),
        ],
      ),
    ));
    expect(state.position.getMetrics().extentInside, 2.0);
  });
}

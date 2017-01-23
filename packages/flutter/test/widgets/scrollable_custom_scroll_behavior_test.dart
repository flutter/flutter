// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TestScrollPosition extends ScrollPosition {
  TestScrollPosition(
    this.extentMultiplier,
    Scrollable2State state,
    Tolerance scrollTolerances,
    ScrollPosition oldPosition,
  ) : _pixels = 100.0, super(state, scrollTolerances, oldPosition);

  final double extentMultiplier;

  double _min, _viewport, _max, _pixels;

  @override
  double get pixels => _pixels;

  @override
  double setPixels(double value) {
    double oldPixels = _pixels;
    _pixels = value;
    dispatchNotification(activity.createScrollUpdateNotification(state, _pixels - oldPixels));
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
        extentBefore: extentMultiplier * beforeExtent / insideExtent,
        extentInside: extentMultiplier,
        extentAfter: extentMultiplier * afterExtent / insideExtent,
      );
    } else {
      return new ScrollableMetrics(
        extentBefore: 0.0,
        extentInside: 0.0,
        extentAfter: 0.0,
      );
    }
  }
}

class TestScrollBehavior extends ScrollBehavior2 {
  TestScrollBehavior(this.extentMultiplier);
  final double extentMultiplier;
  @override
  Widget wrap(BuildContext context, Widget child, AxisDirection axisDirection) => child;
  @override
  ScrollPosition createScrollPosition(BuildContext context, Scrollable2State state, ScrollPosition oldPosition) {
    return new TestScrollPosition(extentMultiplier, state, ViewportScrollBehavior.defaultScrollTolerances, oldPosition);
  }
  @override
  bool shouldNotify(TestScrollBehavior oldDelegate) {
    return extentMultiplier != oldDelegate.extentMultiplier;
  }
}

void main() {
  testWidgets('Changing the scroll behavior dynamically', (WidgetTester tester) async {
    GlobalKey<Scrollable2State> key = new GlobalKey<Scrollable2State>();
    await tester.pumpWidget(new Scrollable2(
      key: key,
      scrollBehavior: new TestScrollBehavior(1.0),
      children: <Widget>[
        new SliverToBoxAdapter(child: new SizedBox(height: 2000.0)),
      ],
    ));
    expect(key.currentState.position.getMetrics().extentInside, 1.0);
    await tester.pumpWidget(new Scrollable2(
      key: key,
      scrollBehavior: new TestScrollBehavior(2.0),
      children: <Widget>[
        new SliverToBoxAdapter(child: new SizedBox(height: 2000.0)),
      ],
    ));
    expect(key.currentState.position.getMetrics().extentInside, 2.0);
  });
}
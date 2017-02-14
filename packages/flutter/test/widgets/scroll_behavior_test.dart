// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestScrollBehavior extends ScrollBehavior2 {
  TestScrollBehavior(this.flag);

  final bool flag;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return flag
      ? const ClampingScrollPhysics()
      : const BouncingScrollPhysics();
  }

  @override
  bool shouldNotify(TestScrollBehavior old) => flag != old.flag;
}

void main() {
  testWidgets('Inherited ScrollConfiguration changed', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey(debugLabel: 'scrollable');
    TestScrollBehavior behavior;
    ScrollPosition position;

    Widget scrollView = new SingleChildScrollView(
      key: key,
      child: new Builder(
        builder: (BuildContext context) {
          behavior = ScrollConfiguration2.of(context);
          position = Scrollable2.of(context).position;
          return new Container(height: 1000.0);
        },
      ),
    );

    await tester.pumpWidget(
      new ScrollConfiguration2(
        behavior: new TestScrollBehavior(true),
        child: scrollView,
      ),
    );

    expect(behavior, isNotNull);
    expect(behavior.flag, isTrue);
    expect(position.physics, const isInstanceOf<ClampingScrollPhysics>());
    ScrollMetrics metrics = position.getMetrics();
    expect(metrics.extentAfter, equals(400.0));
    expect(metrics.viewportDimension, equals(600.0));

    // Same Scrollable, different ScrollConfiguration
    await tester.pumpWidget(
      new ScrollConfiguration2(
        behavior: new TestScrollBehavior(false),
        child: scrollView,
      ),
    );

    expect(behavior, isNotNull);
    expect(behavior.flag, isFalse);
    expect(position.physics, const isInstanceOf<BouncingScrollPhysics>());
    // Regression test for https://github.com/flutter/flutter/issues/5856
    metrics = position.getMetrics();
    expect(metrics.extentAfter, equals(400.0));
    expect(metrics.viewportDimension, equals(600.0));
  });
}

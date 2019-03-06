// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestScrollBehavior extends ScrollBehavior {
  const TestScrollBehavior(this.flag);

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
    final GlobalKey key = GlobalKey(debugLabel: 'scrollable');
    TestScrollBehavior behavior;
    ScrollPositionWithSingleContext position;

    final Widget scrollView = SingleChildScrollView(
      key: key,
      child: Builder(
        builder: (BuildContext context) {
          behavior = ScrollConfiguration.of(context);
          position = Scrollable.of(context).position;
          return Container(height: 1000.0);
        },
      ),
    );

    await tester.pumpWidget(
      ScrollConfiguration(
        behavior: const TestScrollBehavior(true),
        child: scrollView,
      ),
    );

    expect(behavior, isNotNull);
    expect(behavior.flag, isTrue);
    expect(position.physics, isInstanceOf<ClampingScrollPhysics>());
    ScrollMetrics metrics = position.copyWith();
    expect(metrics.extentAfter, equals(400.0));
    expect(metrics.viewportDimension, equals(600.0));

    // Same Scrollable, different ScrollConfiguration
    await tester.pumpWidget(
      ScrollConfiguration(
        behavior: const TestScrollBehavior(false),
        child: scrollView,
      ),
    );

    expect(behavior, isNotNull);
    expect(behavior.flag, isFalse);
    expect(position.physics, isInstanceOf<BouncingScrollPhysics>());
    // Regression test for https://github.com/flutter/flutter/issues/5856
    metrics = position.copyWith();
    expect(metrics.extentAfter, equals(400.0));
    expect(metrics.viewportDimension, equals(600.0));
  });
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestScrollConfigurationDelegate extends ScrollConfigurationDelegate {
  TestScrollConfigurationDelegate(this.flag);

  final bool flag;

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  ExtentScrollBehavior createScrollBehavior() {
    return flag
      ? new BoundedBehavior(platform: platform)
      : new UnboundedBehavior(platform: platform);
  }

  @override
  bool updateShouldNotify(TestScrollConfigurationDelegate old) => flag != old.flag;
}

void main() {
  test('BoundedBehavior min scroll offset', () {
    BoundedBehavior behavior = new BoundedBehavior(
      contentExtent: 150.0,
      containerExtent: 75.0,
      minScrollOffset: -100.0,
      platform: TargetPlatform.iOS
    );

    expect(behavior.minScrollOffset, equals(-100.0));
    expect(behavior.maxScrollOffset, equals(-25.0));

    double scrollOffset = behavior.updateExtents(
      contentExtent: 125.0,
      containerExtent: 50.0,
      scrollOffset: -80.0
    );

    expect(behavior.minScrollOffset, equals(-100.0));
    expect(behavior.maxScrollOffset, equals(-25.0));
    expect(scrollOffset, equals(-80.0));

    scrollOffset = behavior.updateExtents(
      minScrollOffset: 50.0,
      scrollOffset: scrollOffset
    );

    expect(behavior.minScrollOffset, equals(50.0));
    expect(behavior.maxScrollOffset, equals(125.0));
    expect(scrollOffset, equals(50.0));
  });

  testWidgets('Inherited ScrollConfiguration changed', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey(debugLabel: 'scrollable');
    TestScrollConfigurationDelegate delegate;
    ExtentScrollBehavior behavior;

    await tester.pumpWidget(
      new ScrollConfiguration(
        delegate: new TestScrollConfigurationDelegate(true),
        child: new ScrollableViewport(
          key: key,
          child: new Builder(
            builder: (BuildContext context) {
              delegate = ScrollConfiguration.of(context);
              behavior = Scrollable.of(context).scrollBehavior;
              return new Container(height: 1000.0);
            }
          )
        )
      )
    );

    expect(delegate, isNotNull);
    expect(delegate.flag, isTrue);
    expect(behavior, const isInstanceOf<BoundedBehavior>());
    expect(behavior.contentExtent, equals(1000.0));
    expect(behavior.containerExtent, equals(600.0));

    // Same Scrollable, different ScrollConfiguration
    await tester.pumpWidget(
      new ScrollConfiguration(
        delegate: new TestScrollConfigurationDelegate(false),
        child: new ScrollableViewport(
          key: key,
          child: new Builder(
            builder: (BuildContext context) {
              delegate = ScrollConfiguration.of(context);
              behavior = Scrollable.of(context).scrollBehavior;
              return new Container(height: 1000.0);
            }
          )
        )
      )
    );

    expect(delegate, isNotNull);
    expect(delegate.flag, isFalse);
    expect(behavior, const isInstanceOf<UnboundedBehavior>());
    // Regression test for https://github.com/flutter/flutter/issues/5856
    expect(behavior.contentExtent, equals(1000.0));
    expect(behavior.containerExtent, equals(600.0));
  });
}

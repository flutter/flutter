// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

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
}

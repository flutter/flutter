// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

const double kHeight = 10.0;
const double kFlingOffset = kHeight * 20.0;

class TestDelegate extends LazyBlockDelegate {
  @override
  Widget buildItem(BuildContext context, int index) {
    return new Container(height: kHeight);
  }

  @override
  double estimateTotalExtent(int firstIndex, int lastIndex, double minOffset, double firstStartOffset, double lastEndOffset) {
    return double.INFINITY;
  }

  @override
  bool shouldRebuild(LazyBlockDelegate oldDelegate) => false;
}

double currentOffset;

void main() {
  testWidgets('Flings don\'t stutter', (WidgetTester tester) async {
    await tester.pumpWidget(new LazyBlock(
      delegate: new TestDelegate(),
      onScroll: (double scrollOffset) { currentOffset = scrollOffset; },
    ));
    await tester.fling(find.byType(LazyBlock), const Offset(0.0, -kFlingOffset), 1000.0);
    expect(currentOffset, kFlingOffset);
    while (tester.binding.transientCallbackCount > 0) {
      double lastOffset = currentOffset;
      await tester.pump(const Duration(milliseconds: 20));
      expect(currentOffset, greaterThan(lastOffset));
    }
  }, skip: true); // see https://github.com/flutter/flutter/issues/5339
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('Stateless widget smoke test', (WidgetTester tester) async {
    TestBuildCounter.buildCount = 0;

    await tester.pumpWidget(const TestBuildCounter());

    expect(TestBuildCounter.buildCount, equals(1));
  });

  testWidgets('Stateless shouldRebuild test', (WidgetTester tester) async {
    TestBuildCounter.buildCount = 0;

    await tester.pumpWidget(const TestBuildCounterValue(1000)); // Built 1st time
    await tester.pumpWidget(const TestBuildCounterValue(1000)); // same parameter, no rebuild
    await tester.pumpWidget(const TestBuildCounterValue(1000)); // same parameter, no rebuild
    await tester.pumpWidget(const TestBuildCounterValue(1000)); // same parameter, no rebuild
    expect(TestBuildCounter.buildCount, equals(1));

    await tester.pumpWidget(const TestBuildCounterValue(1234)); // change parameter, rebuilt 2nd
    await tester.pumpWidget(const TestBuildCounterValue(5678)); // change parameter, rebuilt 3rd
    await tester.pumpWidget(const TestBuildCounterValue(9876)); // change parameter, rebuilt 4th
    expect(TestBuildCounter.buildCount, equals(4));
  });
}

class TestBuildCounterValue extends TestBuildCounter {
  const TestBuildCounterValue(this.value);

  final int value;

  @override
  bool shouldRebuild(TestBuildCounterValue oldWidget) => value != oldWidget.value;
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('scrolling performance test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null)
        driver.close();
    });

    Future<Null> testScrollPerf(String listKey, String summaryName) async {
      final Timeline timeline = await driver.traceAction(() async {
        // Find the scrollable stock list
        final SerializableFinder list = find.byValueKey(listKey);
        expect(list, isNotNull);

        // Scroll down
        for (int i = 0; i < 5; i++) {
          await driver.scroll(list, 0.0, -300.0, const Duration(milliseconds: 300));
          await new Future<Null>.delayed(const Duration(milliseconds: 500));
        }

        // Scroll up
        for (int i = 0; i < 5; i++) {
          await driver.scroll(list, 0.0, 300.0, const Duration(milliseconds: 300));
          await new Future<Null>.delayed(const Duration(milliseconds: 500));
        }
      });

      final TimelineSummary summary = new TimelineSummary.summarize(timeline);
      summary.writeSummaryToFile(summaryName, pretty: true);
      summary.writeTimelineToFile(summaryName, pretty: true);
    }

    test('complex_layout_scroll_perf', () async {
      await testScrollPerf('complex-scroll', 'complex_layout_scroll_perf');
    });

    test('tiles_scroll_perf', () async {
      await driver.tap(find.byTooltip('Open navigation menu'));
      await driver.tap(find.byValueKey('scroll-switcher'));
      await testScrollPerf('tiles-scroll', 'tiles_scroll_perf');
    });
  });
}

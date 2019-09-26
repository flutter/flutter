// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_driver/flutter_self_driver.dart';
import 'package:flutter_test/flutter_test.dart' show Finder, find;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:complex_layout/main.dart' as app;

Future<void> main() async {
  final FlutterSelfDriver driver = await FlutterSelfDriver.connect();
  app.main();
  group('scrolling performance test', () {

    setUpAll(() async {
      await driver.waitUntilFirstFrameRasterized();
    });

    tearDownAll(() async {
    });

    Future<void> testScrollPerf(String listKey, String summaryName) async {
      // The slight initial delay avoids starting the timing during a
      // period of increased load on the device. Without this delay, the
      // benchmark has greater noise.
      // See: https://github.com/flutter/flutter/issues/19434
      await Future<void>.delayed(const Duration(milliseconds: 250));

      await driver.forceGC();

      final Timeline timeline = await driver.traceAction(() async {
        // Find the scrollable stock list
        final Finder list = find.byKey(ValueKey<String>(listKey));
        expect(list, isNotNull);

        // Scroll down
        for (int i = 0; i < 5; i += 1) {
          await driver.scroll(list, 0.0, -300.0, const Duration(milliseconds: 300));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }

        // Scroll up
        for (int i = 0; i < 5; i += 1) {
          await driver.scroll(list, 0.0, 300.0, const Duration(milliseconds: 300));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      });

      final TimelineSummary summary = TimelineSummary.summarize(timeline);
      final Map<String, dynamic> results = Map<String, dynamic>.from(summary.summaryJson);
      results.remove('frame_build_times');
      results.remove('frame_rasterizer_times');
      print('================ RESULTS ================');
      print(json.encode(results));
    }

    test('complex_layout_scroll_perf', () async {
      await testScrollPerf('complex-scroll', 'complex_layout_scroll_perf');
    });

    test('tiles_scroll_perf', () async {
      await driver.tap(find.byTooltip('Open navigation menu'));
      await driver.tap(find.byKey(const ValueKey<String>('scroll-switcher')));
      await testScrollPerf('tiles-scroll', 'tiles_scroll_perf');
    });
  });
}

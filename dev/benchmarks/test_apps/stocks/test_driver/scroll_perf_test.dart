// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('scrolling performance test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver.close();
    });

    test('measure', () async {
      final Timeline timeline = await driver.traceAction(() async {
        // Find the scrollable stock list
        final SerializableFinder stockList = find.byValueKey('stock-list');
        expect(stockList, isNotNull);

        // Scroll down
        for (var i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, -300.0, const Duration(milliseconds: 300));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }

        // Scroll up
        for (var i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, 300.0, const Duration(milliseconds: 300));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      });

      final summary = TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile('stocks_scroll_perf', pretty: true);
    }, timeout: Timeout.none);
  });
}

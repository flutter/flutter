// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_driver/flutter_self_driver.dart';
import 'package:flutter_test/flutter_test.dart' show Finder, find;
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;
import 'package:stocks/main.dart' as app;

Future<void> main() async {
  final FlutterSelfDriver driver = await FlutterSelfDriver.connect();
  app.main();
  group('scrolling performance test', () {

    setUpAll(() async {
    });

    tearDownAll(() async {
    });

    test('measure', () async {
      final Timeline timeline = await driver.traceAction(() async {
        // Find the scrollable stock list
        final Finder stockList = find.byKey(const ValueKey<String>('stock-list'));
        expect(stockList, isNotNull);

        // Scroll down
        for (int i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, -300.0, const Duration(milliseconds: 300));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }

        // Scroll up
        for (int i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, 300.0, const Duration(milliseconds: 300));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      });

      final TimelineSummary summary = TimelineSummary.summarize(timeline);
      final Map<String, dynamic> results = Map<String, dynamic>.from(summary.summaryJson);
      results.remove('frame_build_times');
      results.remove('frame_rasterizer_times');
      print('================ RESULTS ================');
      print(json.encode(results));
    });
  });
}

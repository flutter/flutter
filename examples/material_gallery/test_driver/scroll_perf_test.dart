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

    test('measure', () async {
      Timeline timeline = await driver.traceAction(() async {
        // Find the scrollable stock list
        ObjectRef stockList = await driver.findByValueKey('Gallery List');
        expect(stockList, isNotNull);

        await driver.tap(await driver.findByText('Demos'));
        await driver.tap(await driver.findByText('Components'));
        await driver.tap(await driver.findByText('Style'));

        // TODO(eseidel): These are very artifical scrolls, we should use better
        // https://github.com/flutter/flutter/issues/3316
        // Scroll down
        for (int i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, -300.0, new Duration(milliseconds: 300));
          await new Future<Null>.delayed(new Duration(milliseconds: 500));
        }

        // Scroll up
        for (int i = 0; i < 5; i++) {
          await driver.scroll(stockList, 0.0, 300.0, new Duration(milliseconds: 300));
          await new Future<Null>.delayed(new Duration(milliseconds: 500));
        }
      });

      new TimelineSummary.summarize(timeline)
        ..writeSummaryToFile('home_scroll_perf', pretty: true)
        ..writeTimelineToFile('home_scroll_perf', pretty: true);
    });
  });
}

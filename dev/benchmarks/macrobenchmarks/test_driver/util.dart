// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'package:macrobenchmarks/common.dart';

const Duration kTimeout = Duration(seconds: 30);

typedef DriverTestCallBack = Future<void> Function(FlutterDriver driver);

Future<void> runDriverTestForRoute(String routeName, DriverTestCallBack body) async {
  final FlutterDriver driver = await FlutterDriver.connect();

  // The slight initial delay avoids starting the timing during a
  // period of increased load on the device. Without this delay, the
  // benchmark has greater noise.
  // See: https://github.com/flutter/flutter/issues/19434
  await Future<void>.delayed(const Duration(milliseconds: 250));

  await driver.forceGC();

  final SerializableFinder scrollable = find.byValueKey(kScrollableName);
  expect(scrollable, isNotNull);
  final SerializableFinder button = find.byValueKey(routeName);
  expect(button, isNotNull);
  await driver.scrollUntilVisible(scrollable, button, dyScroll: -50.0);
  await driver.tap(button);

  await body(driver);

  driver.close();
}

void macroPerfTest(
    String testName,
    String routeName,
    { Duration pageDelay,
      Duration duration = const Duration(seconds: 3),
      Duration timeout = kTimeout,
      Future<void> driverOps(FlutterDriver driver),
      Future<void> setupOps(FlutterDriver driver),
    }) {
  test(testName, () async {
    Timeline timeline;
    await runDriverTestForRoute(routeName, (FlutterDriver driver) async {
      if (pageDelay != null) {
        // Wait for the page to load
        await Future<void>.delayed(pageDelay);
      }

      if (setupOps != null) {
      await setupOps(driver);
      }

      timeline = await driver.traceAction(() async {
      final Future<void> durationFuture = Future<void>.delayed(duration);
      if (driverOps != null) {
        await driverOps(driver);
      }
        await durationFuture;
      });
    });

    expect(timeline, isNotNull);

    final TimelineSummary summary = TimelineSummary.summarize(timeline);
    await summary.writeSummaryToFile(testName, pretty: true);
    await summary.writeTimelineToFile(testName, pretty: true);
  }, timeout: Timeout(timeout));
}

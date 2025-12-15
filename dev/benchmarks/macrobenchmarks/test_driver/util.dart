// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:macrobenchmarks/common.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

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
  // -320 comes from the logical pixels for a full screen scroll for the
  // smallest reference device, iPhone 4, whose physical screen dimensions are
  // 960px × 640px.
  const dyScroll = -320.0;
  await driver.scrollUntilVisible(scrollable, button, dyScroll: dyScroll);
  await driver.tap(button);

  await body(driver);

  driver.close();
}

void macroPerfTest(
  String testName,
  String routeName, {
  Duration? pageDelay,
  Duration duration = const Duration(seconds: 3),
  Future<void> Function(FlutterDriver driver)? driverOps,
  Future<void> Function(FlutterDriver driver)? setupOps,
}) {
  test(testName, () async {
    late Timeline timeline;
    await runDriverTestForRoute(routeName, (FlutterDriver driver) async {
      if (pageDelay != null) {
        // Wait for the page to load
        await Future<void>.delayed(pageDelay);
      }

      if (setupOps != null) {
        await setupOps(driver);
      }

      timeline = await driver.traceAction(() async {
        final durationFuture = Future<void>.delayed(duration);
        if (driverOps != null) {
          await driverOps(driver);
        }
        await durationFuture;
      });
    });

    expect(timeline, isNotNull);

    final summary = TimelineSummary.summarize(timeline);
    await summary.writeTimelineToFile(testName, pretty: true);
  }, timeout: Timeout.none);
}

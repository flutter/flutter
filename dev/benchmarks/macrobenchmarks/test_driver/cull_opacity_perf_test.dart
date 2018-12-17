// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'package:macrobenchmarks/common.dart';

void main() {
  const String kName = 'cull_opacity_perf';

  test(kName, () async {
    final FlutterDriver driver = await FlutterDriver.connect();

    // The slight initial delay avoids starting the timing during a
    // period of increased load on the device. Without this delay, the
    // benchmark has greater noise.
    // See: https://github.com/flutter/flutter/issues/19434
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await driver.forceGC();

    final SerializableFinder button = find.byValueKey(kCullOpacityRouteName);
    expect(button, isNotNull);
    await driver.tap(button);

    // Wait for the page to load
    await Future<void>.delayed(const Duration(seconds: 1));

    final Timeline timeline = await driver.traceAction(() async {
      await Future<void>.delayed(const Duration(seconds: 10));
    });

    final TimelineSummary summary = TimelineSummary.summarize(timeline);
    summary.writeSummaryToFile(kName, pretty: true);
    summary.writeTimelineToFile(kName, pretty: true);

    driver.close();
  });
}

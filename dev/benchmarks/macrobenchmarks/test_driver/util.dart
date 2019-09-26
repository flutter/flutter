// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_driver/flutter_self_driver.dart';
import 'package:flutter_test/flutter_test.dart' show Finder, find;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:macrobenchmarks/main.dart' as app;

Future<void> macroPerfTest(
    String testName,
    String routeName,
    {Duration pageDelay, Duration duration = const Duration(seconds: 3)}) async {
  final FlutterSelfDriver driver = await FlutterSelfDriver.connect();
  app.main();
  test(testName, () async {
    // The slight initial delay avoids starting the timing during a
    // period of increased load on the device. Without this delay, the
    // benchmark has greater noise.
    // See: https://github.com/flutter/flutter/issues/19434
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await driver.forceGC();

    final Finder button = find.byKey(ValueKey<String>(routeName));
    expect(button, isNotNull);
    await driver.tap(button);

    if (pageDelay != null) {
      // Wait for the page to load
      await Future<void>.delayed(pageDelay);
    }

    final Timeline timeline = await driver.traceAction(() async {
      await Future<void>.delayed(duration);
    });

    final TimelineSummary summary = TimelineSummary.summarize(timeline);
    final Map<String, dynamic> results = Map<String, dynamic>.from(summary.summaryJson);
    results.remove('frame_build_times');
    results.remove('frame_rasterizer_times');
    print('================ RESULTS ================');
    print(json.encode(results));
  });
}

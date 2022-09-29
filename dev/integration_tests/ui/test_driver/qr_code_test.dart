// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  test('measure', () async {
    await driver.waitFor(find.byValueKey('Button'));
    final Timeline timeline = await driver.traceAction(() async {
      await driver.tap(find.byValueKey('Button'));
      await driver.waitFor(find.byValueKey('Painter'));
      // Frame rasterization can take a long time. We don't have
      // a good way to wait for it to be complete.
      await Future<void>.delayed(const Duration(seconds: 15));
    });

    final TimelineSummary summary = TimelineSummary.summarize(timeline);
    await summary.writeTimelineToFile('qr_code_perf', pretty: true);
  }, timeout: Timeout.none);
}

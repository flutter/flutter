// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

Future<void> main() async {
  const String fileName = 'large_image_changer';

  test('Animate for 20 seconds', () async {
    final FlutterDriver driver = await FlutterDriver.connect();
    await driver.forceGC();

    final String targetPlatform = await driver.requestData('getTargetPlatform');

    Timeline timeline;
    switch (targetPlatform) {
      case 'TargetPlatform.iOS':
        {
          timeline = await driver.traceAction(() async {
            await Future<void>.delayed(const Duration(seconds: 20));
          });
        }
        break;
      case 'TargetPlatform.android':
        {
          // Just run for 20 seconds to collect memory usage. The widget itself
          // animates during this time.
          await Future<void>.delayed(const Duration(seconds: 20));
        }
        break;
      default:
        throw UnsupportedError('Unsupported platform $targetPlatform');
    }

    if (timeline != null) {
      final TimelineSummary summary = TimelineSummary.summarize(timeline);
      await summary.writeSummaryToFile(fileName, pretty: true);
      await summary.writeTimelineToFile(fileName, pretty: true);
    }

    await driver.close();
  });
}

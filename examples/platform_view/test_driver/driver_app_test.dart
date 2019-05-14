// Copyright 2019, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Scroll list of WebViews', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });

    test('scroll to the last item', () async {
      final SerializableFinder listFinder = find.byValueKey('long_list');
      final SerializableFinder itemFinder = find.byValueKey(9);

      final Timeline timeline = await driver.traceAction(() async {
        await driver.scrollUntilVisible(
          listFinder,
          itemFinder,
          dyScroll: -300.0,
        );
      });

      final TimelineSummary summary = TimelineSummary.summarize(timeline);
      summary.writeSummaryToFile(
        'list_webview_scrolling_summary',
        pretty: true,
      );
      summary.writeTimelineToFile(
        'list_webview_scrolling_timeline',
        pretty: true,
      );
    });
  });
}

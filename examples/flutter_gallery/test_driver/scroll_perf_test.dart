// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_driver/flutter_self_driver.dart';
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  final FlutterSelfDriver driver = await FlutterSelfDriver.connect();
  // As in lib/main.dart: overriding https://github.com/flutter/flutter/issues/13736
  // for better visual effect at the cost of performance.
  runApp(const GalleryApp(testMode: true));
  group('scrolling performance test', () {

    setUpAll(() async {
      await driver.waitUntilFirstFrameRasterized();
    });

    tearDownAll(() async {
    });

    test('measure', () async {
      final Timeline timeline = await driver.traceAction(() async {
        await driver.tap(find.text('Material'));

        final Finder demoList = find.byKey(const Key('GalleryDemoList'));

        // TODO(eseidel): These are very artificial scrolls, we should use better
        // https://github.com/flutter/flutter/issues/3316
        // Scroll down
        for (int i = 0; i < 5; i++) {
          await driver.scroll(demoList, 0.0, -300.0, const Duration(milliseconds: 300));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }

        // Scroll up
        for (int i = 0; i < 5; i++) {
          await driver.scroll(demoList, 0.0, 300.0, const Duration(milliseconds: 300));
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

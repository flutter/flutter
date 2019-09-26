// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_driver/flutter_self_driver.dart';
import 'package:flutter_gallery/gallery/demos.dart';
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Demos for which timeline data will be collected using
// FlutterDriver.traceAction().
//
// Warning: The number of tests executed with timeline collection enabled
// significantly impacts heap size of the running app. When run with
// --trace-startup, as we do in this test, the VM stores trace events in an
// endless buffer instead of a ring buffer.
//
// These names must match GalleryItem titles from kAllGalleryDemos
// in examples/flutter_gallery/lib/gallery/demos.dart
const List<String> kProfiledDemos = <String>[
  'Shrine@Studies',
  'Contact profile@Studies',
  'Animation@Studies',
  'Bottom navigation@Material',
  'Buttons@Material',
  'Cards@Material',
  'Chips@Material',
  'Dialogs@Material',
  'Pickers@Material',
];

// There are 3 places where the Gallery demos are traversed.
// 1- In widget tests such as examples/flutter_gallery/test/smoke_test.dart
// 2- In driver tests such as examples/flutter_gallery/test_driver/transitions_perf_test.dart
// 3- In on-device instrumentation tests such as examples/flutter_gallery/test/live_smoketest.dart
//
// If you change navigation behavior in the Gallery or in the framework, make
// sure all 3 are covered.

// Demos that will be backed out of within FlutterDriver.runUnsynchronized();
//
// These names must match GalleryItem titles from kAllGalleryDemos
// in examples/flutter_gallery/lib/gallery/demos.dart
const List<String> kUnsynchronizedDemos = <String>[
  'Progress indicators@Material',
  'Activity Indicator@Cupertino',
  'Video@Media',
];

const List<String> kSkippedDemos = <String>[];

// All of the gallery demos, identified as "title@category".
//
// These names are reported by the test app, see _handleMessages()
// in transitions_perf.dart.
List<String> _allDemos = kAllGalleryDemos.map((GalleryDemo demo) => '${demo.title}@${demo.category.name}').toList();

/// Scrolls each demo menu item into view, launches it, then returns to the
/// home screen twice.
Future<void> runDemos(List<String> demos, FlutterSelfDriver driver) async {
  final Finder demoList = find.byKey(const Key('GalleryDemoList'));
  String currentDemoCategory;

  for (String demo in demos) {
    if (kSkippedDemos.contains(demo))
      continue;

    final String demoName = demo.substring(0, demo.indexOf('@'));
    final String demoCategory = demo.substring(demo.indexOf('@') + 1);
    print('> $demo');

    if (currentDemoCategory == null) {
      await driver.tap(find.text(demoCategory));
    } else if (currentDemoCategory != demoCategory) {
      await driver.tap(find.byTooltip('Back'));
      await driver.tap(find.text(demoCategory));
      // Scroll back to the top
      await driver.scroll(demoList, 0.0, 10000.0, const Duration(milliseconds: 100));
    }
    currentDemoCategory = demoCategory;

    final Finder demoItem = find.text(demoName);
    await driver.scrollUntilVisible(demoList, demoItem,
      dyScroll: -48.0,
      alignment: 0.5,
      timeout: const Duration(seconds: 30),
    );

    for (int i = 0; i < 2; i += 1) {
      await driver.tap(demoItem); // Launch the demo

      if (kUnsynchronizedDemos.contains(demo)) {
        await driver.runUnsynchronized<void>(() async {
          // TODO(sortie): The page back can be delivered too early and not get
          // properly acted on, causing this to deadlock. We should probably
          // wait for the title of the demo to appear before sending the page
          // back. Simply waiting a moment works around the issue.
          await Future<void>.delayed(const Duration(microseconds: 1000000));
          await driver.tap(driver.createPageBackFinder());
        });
      } else {
        await driver.tap(driver.createPageBackFinder());
      }
    }

    print('< Success');
  }

  // Return to the home screen
  await driver.tap(find.byTooltip('Back'));
}

Future<void> main([List<String> args = const <String>[]]) async {
  final FlutterSelfDriver driver = await FlutterSelfDriver.connect();
  // As in lib/main.dart: overriding https://github.com/flutter/flutter/issues/13736
  // for better visual effect at the cost of performance.
  runApp(const GalleryApp(testMode: true));
  group('flutter gallery transitions', () {
    setUpAll(() async {
      // Wait for the first frame to be rasterized.
      await driver.waitUntilFirstFrameRasterized();

      if (args.contains('--with_semantics')) {
        print('Enabeling semantics...');
        await driver.setSemantics(true);
      }
    });

    tearDownAll(() async {
    });

    test('all demos', () async {
      // Collect timeline data for just a limited set of demos to avoid OOMs.
      final Timeline timeline = await driver.traceAction(
        () async {
          await runDemos(kProfiledDemos, driver);
        },
        streams: const <TimelineStream>[
          TimelineStream.dart,
          TimelineStream.embedder,
        ],
      );

      // Save the duration (in microseconds) of the first timeline Frame event
      // that follows a 'Start Transition' event. The Gallery app adds a
      // 'Start Transition' event when a demo is launched (see GalleryItem).
      final TimelineSummary summary = TimelineSummary.summarize(timeline);
      final Map<String, dynamic> results = Map<String, dynamic>.from(summary.summaryJson);
      results.remove('frame_build_times');
      results.remove('frame_rasterizer_times');
      print('================ RESULTS ================');
      print(json.encode(results));

      // Execute the remaining tests.
      final Set<String> unprofiledDemos = Set<String>.from(_allDemos)..removeAll(kProfiledDemos);
      await runDemos(unprofiledDemos.toList(), driver);

    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}

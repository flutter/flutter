// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder, JsonDecoder;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const FileSystem _fs = const LocalFileSystem();

// Demos for which timeline data will be collected using
// FlutterDriver.traceAction().
//
// Warning: The number of tests executed with timeline collection enabled
// significantly impacts heap size of the running app. When run with
// --trace-startup, as we do in this test, the VM stores trace events in an
// endless buffer instead of a ring buffer.
//
// These names must match GalleryItem titles from  kAllGalleryItems
// in examples/flutter_gallery/lib/gallery.item.dart
const List<String> kProfiledDemos = const <String>[
  'Shrine',
  'Contact profile',
  'Animation',
  'Bottom navigation',
  'Buttons',
  'Cards',
  'Chips',
  'Date and time pickers',
  'Dialog',
];

// Demos that will be backed out of within FlutterDriver.runUnsynchronized();
//
// These names must match GalleryItem titles from  kAllGalleryItems
// in examples/flutter_gallery/lib/gallery.item.dart
const List<String> kUnsynchronizedDemos = const <String>[
  'Progress indicators',
  'Activity Indicator',
  'Video',
];

// All of the gallery demo titles in the order they appear on the
// gallery home page.
//
// These names are reported by the test app, see _handleMessages()
// in transitions_perf.dart.
List<String> _allDemos = <String>[];

/// Extracts event data from [events] recorded by timeline, validates it, turns
/// it into a histogram, and saves to a JSON file.
Future<Null> saveDurationsHistogram(List<Map<String, dynamic>> events, String outputPath) async {
  final Map<String, List<int>> durations = <String, List<int>>{};
  Map<String, dynamic> startEvent;

  // Save the duration of the first frame after each 'Start Transition' event.
  for (Map<String, dynamic> event in events) {
    final String eventName = event['name'];
    if (eventName == 'Start Transition') {
      assert(startEvent == null);
      startEvent = event;
    } else if (startEvent != null && eventName == 'Frame') {
      final String routeName = startEvent['args']['to'];
      durations[routeName] ??= <int>[];
      durations[routeName].add(event['dur']);
      startEvent = null;
    }
  }

  // Verify that the durations data is valid.
  if (durations.keys.isEmpty)
    throw 'no "Start Transition" timeline events found';
  final Map<String, int> unexpectedValueCounts = <String, int>{};
  durations.forEach((String routeName, List<int> values) {
    if (values.length != 2) {
      unexpectedValueCounts[routeName] = values.length;
    }
  });

  if (unexpectedValueCounts.isNotEmpty) {
    final StringBuffer error = new StringBuffer('Some routes recorded wrong number of values (expected 2 values/route):\n\n');
    unexpectedValueCounts.forEach((String routeName, int count) {
      error.writeln(' - $routeName recorded $count values.');
    });
    error.writeln('\nFull event sequence:');
    final Iterator<Map<String, dynamic>> eventIter = events.iterator;
    String lastEventName = '';
    String lastRouteName = '';
    while (eventIter.moveNext()) {
      final String eventName = eventIter.current['name'];

      if (!<String>['Start Transition', 'Frame'].contains(eventName))
        continue;

      final String routeName = eventName == 'Start Transition'
        ? eventIter.current['args']['to']
        : '';

      if (eventName == lastEventName && routeName == lastRouteName) {
        error.write('.');
      } else {
        error.write('\n - $eventName $routeName .');
      }

      lastEventName = eventName;
      lastRouteName = routeName;
    }
    throw error;
  }

  // Save the durations Map to a file.
  final File file = await _fs.file(outputPath).create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(durations));
}

/// Scrolls each demo menu item into view, launches it, then returns to the
/// home screen twice.
Future<Null> runDemos(List<String> demos, FlutterDriver driver) async {
  for (String demo in demos) {
    print('Testing "$demo" demo');
    final SerializableFinder menuItem = find.text(demo);
    await driver.scrollUntilVisible(find.byType('CustomScrollView'), menuItem,
      dyScroll: -48.0,
      alignment: 0.5,
    );

    for (int i = 0; i < 2; i += 1) {
      await driver.tap(menuItem); // Launch the demo

      // This demo's back button isn't initially visible.
      if (demo == 'Backdrop')
        await driver.tap(find.byTooltip('Tap to dismiss'));

      if (kUnsynchronizedDemos.contains(demo)) {
        await driver.runUnsynchronized<Future<Null>>(() async {
          await driver.tap(find.byTooltip('Back'));
        });
      } else {
        await driver.tap(find.byTooltip('Back'));
      }
    }
    print('Success');
  }
}

void main([List<String> args = const <String>[]]) {
  group('flutter gallery transitions', () {
    FlutterDriver driver;
    setUpAll(() async {
      driver = await FlutterDriver.connect();

      if (args.contains('--with_semantics')) {
        print('Enabeling semantics...');
        await driver.setSemantics(true);
      }

      // See _handleMessages() in transitions_perf.dart.
      _allDemos = const JsonDecoder().convert(await driver.requestData('demoNames'));
      if (_allDemos.isEmpty)
        throw 'no demo names found';
    });

    tearDownAll(() async {
      if (driver != null)
        await driver.close();
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
      final TimelineSummary summary = new TimelineSummary.summarize(timeline);
      await summary.writeSummaryToFile('transitions', pretty: true);
      final String histogramPath = path.join(testOutputsDirectory, 'transition_durations.timeline.json');
      await saveDurationsHistogram(timeline.json['traceEvents'], histogramPath);

      // Scroll back to the top
      await driver.scrollUntilVisible(find.byType('CustomScrollView'), find.text(_allDemos[0]),
        dyScroll: 200.0,
        alignment: 0.0
      );

      // Execute the remaining tests.
      final Set<String> unprofiledDemos = new Set<String>.from(_allDemos)..removeAll(kProfiledDemos);
      await runDemos(unprofiledDemos.toList(), driver);

    }, timeout: const Timeout(const Duration(minutes: 5)));
  });
}

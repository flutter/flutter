// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class Demo {
  const Demo(this.title, {this.synchronized = true, this.profiled = false});

  /// The title of the demo.
  final String title;

  /// True if frameSync should be enabled for this test.
  final bool synchronized;

  // True if timeline data should be collected for this test.
  //
  // Warning: The number of tests executed with timeline collection enabled
  // significantly impacts heap size of the running app. When run with
  // --trace-startup, as we do in this test, the VM stores trace events in an
  // endless buffer instead of a ring buffer.
  final bool profiled;
}

// Warning: this list must be kept in sync with the value of
// kAllGalleryItems.map((GalleryItem item) => item.title).toList();
const List<Demo> demos = const <Demo>[
  // Demos
  const Demo('Shrine', profiled: true),
  const Demo('Contact profile', profiled: true),
  const Demo('Animation', profiled: true),

  // Material Components
  const Demo('Bottom navigation', profiled: true),
  const Demo('Buttons', profiled: true),
  const Demo('Cards', profiled: true),
  const Demo('Chips', profiled: true),
  const Demo('Date and time pickers', profiled: true),
  const Demo('Dialog', profiled: true),
  const Demo('Drawer'),
  const Demo('Expand/collapse list control'),
  const Demo('Expansion panels'),
  const Demo('Floating action button'),
  const Demo('Grid'),
  const Demo('Icons'),
  const Demo('Leave-behind list items'),
  const Demo('List'),
  const Demo('Menus'),
  const Demo('Modal bottom sheet'),
  const Demo('Page selector'),
  const Demo('Persistent bottom sheet'),
  const Demo('Progress indicators', synchronized: false),
  const Demo('Pull to refresh'),
  const Demo('Scrollable tabs'),
  const Demo('Selection controls'),
  const Demo('Sliders'),
  const Demo('Snackbar'),
  const Demo('Tabs'),
  const Demo('Text fields'),
  const Demo('Tooltips'),

  // Cupertino Components
  const Demo('Activity Indicator', synchronized: false),
  const Demo('Buttons'),
  const Demo('Dialogs'),
  const Demo('Sliders'),
  const Demo('Switches'),

  // Style
  const Demo('Colors'),
  const Demo('Typography'),
];

final FileSystem _fs = const LocalFileSystem();

const Duration kWaitBetweenActions = const Duration(milliseconds: 250);

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
    while(eventIter.moveNext()) {
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
Future<Null> runDemos(Iterable<Demo> demos, FlutterDriver driver) async {
  for (Demo demo in demos) {
    print('Testing "${demo.title}" demo');
    final SerializableFinder menuItem = find.text(demo.title);
    await driver.scrollIntoView(menuItem, alignment: 0.5);
    await new Future<Null>.delayed(kWaitBetweenActions);

    for (int i = 0; i < 2; i += 1) {
      await driver.tap(menuItem); // Launch the demo
      await new Future<Null>.delayed(kWaitBetweenActions);
      if (demo.synchronized) {
        await driver.tap(find.byTooltip('Back'));
      } else {
        await driver.runUnsynchronized<Future<Null>>(() async {
          await new Future<Null>.delayed(kWaitBetweenActions);
          await driver.tap(find.byTooltip('Back'));
        });
      }
      await new Future<Null>.delayed(kWaitBetweenActions);
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
    });

    tearDownAll(() async {
      if (driver != null)
        await driver.close();
    });

    test('all demos', () async {
      // Collect timeline data for just a limited set of demos to avoid OOMs.
      final Timeline timeline = await driver.traceAction(() async {
        final Iterable<Demo> profiledDemos = demos.where((Demo demo) => demo.profiled);
        await runDemos(profiledDemos, driver);
      },
      streams: const <TimelineStream>[
        TimelineStream.dart,
        TimelineStream.embedder,
      ]);

      // Save the duration (in microseconds) of the first timeline Frame event
      // that follows a 'Start Transition' event. The Gallery app adds a
      // 'Start Transition' event when a demo is launched (see GalleryItem).
      final TimelineSummary summary = new TimelineSummary.summarize(timeline);
      await summary.writeSummaryToFile('transitions', pretty: true);
      final String histogramPath = path.join(testOutputsDirectory, 'transition_durations.timeline.json');
      await saveDurationsHistogram(timeline.json['traceEvents'], histogramPath);

      // Execute the remaining tests.
      final Iterable<Demo> unprofiledDemos = demos.where((Demo demo) => !demo.profiled);
      await runDemos(unprofiledDemos, driver);

    }, timeout: const Timeout(const Duration(minutes: 5)));
  });
}

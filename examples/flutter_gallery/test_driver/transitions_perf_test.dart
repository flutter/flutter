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

// Warning: this list must be kept in sync with the value of
// kAllGalleryItems.map((GalleryItem item) => item.category)).toList();
final List<String> demoCategories = <String>[
  'Demos',
  'Components',
  'Style'
];

// Warning: this list must be kept in sync with the value of
// kAllGalleryItems.map((GalleryItem item) => item.title).toList();
final List<String> demoTitles = <String>[
  // Demos
  'Pesto',
  'Shrine',
  'Contact profile',
  // Components
  'Bottom navigation',
  'Buttons',
  'Cards',
  'Chips',
  'Date and time pickers',
  'Dialog',
  'Drawer',
  'Expand/collapse list control',
  'Expansion panels',
  'Floating action button',
  'Grid',
  'Icons',
  'Leave-behind list items',
  'List',
  'Menus',
  'Modal bottom sheet',
  'Over-scroll',
  'Page selector',
  'Persistent bottom sheet',
  'Progress indicators',
  'Scrollable tabs',
  'Selection controls',
  'Sliders',
  'Snackbar',
  'Tabs',
  'Text fields',
  'Tooltips',
  // Style
  'Colors',
  'Typography'
];

// Subset of [demoTitles] that needs frameSync turned off.
final List<String> unsynchedDemoTitles = <String>[
  'Progress indicators',
];

final FileSystem _fs = new LocalFileSystem();

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
      durations[routeName] ??= new List<int>();
      durations[routeName].add(event['dur']);
      startEvent = null;
    }
  }

  // Verify that the durations data is valid.
  if (durations.keys.isEmpty)
    throw 'no "Start Transition" timeline events found';
  Map<String, int> unexpectedValueCounts = <String, int>{};
  durations.forEach((String routeName, List<int> values) {
    if (values.length != 2) {
      unexpectedValueCounts[routeName] = values.length;
    }
  });

  if (unexpectedValueCounts.isNotEmpty) {
    StringBuffer error = new StringBuffer('Some routes recorded wrong number of values (expected 2 values/route):\n\n');
    unexpectedValueCounts.forEach((String routeName, int count) {
      error.writeln(' - $routeName recorded $count values.');
    });
    error.writeln('\nFull event sequence:');
    Iterator<Map<String, dynamic>> eventIter = events.iterator;
    String lastEventName = '';
    String lastRouteName = '';
    while(eventIter.moveNext()) {
      String eventName = eventIter.current['name'];

      if (!<String>['Start Transition', 'Frame'].contains(eventName))
        continue;

      String routeName = eventName == 'Start Transition'
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
  await file.writeAsString(new JsonEncoder.withIndent('  ').convert(durations));
}

void main() {
  group('flutter gallery transitions', () {
    FlutterDriver driver;
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null)
        await driver.close();
    });

    test('all demos', () async {
      Timeline timeline = await driver.traceAction(() async {
        // Expand the demo category submenus.
        for (String category in demoCategories.reversed) {
          await driver.tap(find.text(category));
          await new Future<Null>.delayed(kWaitBetweenActions);
        }
        // Scroll each demo menu item into view, launch the demo and
        // return to the demo menu 2x.
        for(String demoTitle in demoTitles) {
          print('Testing "$demoTitle" demo');
          SerializableFinder menuItem = find.text(demoTitle);
          await driver.scrollIntoView(menuItem);
          await new Future<Null>.delayed(kWaitBetweenActions);

          for(int i = 0; i < 2; i += 1) {
            await driver.tap(menuItem); // Launch the demo
            await new Future<Null>.delayed(kWaitBetweenActions);
            if (!unsynchedDemoTitles.contains(demoTitle)) {
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
      },
      streams: const <TimelineStream>[
        TimelineStream.dart,
        TimelineStream.embedder,
      ]);

      // Save the duration (in microseconds) of the first timeline Frame event
      // that follows a 'Start Transition' event. The Gallery app adds a
      // 'Start Transition' event when a demo is launched (see GalleryItem).
      TimelineSummary summary = new TimelineSummary.summarize(timeline);
      await summary.writeSummaryToFile('transitions', pretty: true);
      String histogramPath = path.join(testOutputsDirectory, 'transition_durations.timeline.json');
      await saveDurationsHistogram(timeline.json['traceEvents'], histogramPath);
    }, timeout: new Timeout(new Duration(minutes: 5)));
  });
}

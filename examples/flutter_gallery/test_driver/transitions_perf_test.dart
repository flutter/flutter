// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JsonEncoder;

import 'package:file/file.dart';
import 'package:file/io.dart';
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
  'Date picker',
  'Dialog',
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
  'Time picker',
  'Tooltips',
  // Style
  'Colors',
  'Typography'
];

Future<Null> saveDurationsHistogram(List<Map<String, dynamic>> events) async {
  final Map<String, List<int>> durations = new Map<String, List<int>>();
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
  for(String routeName in durations.keys) {
    if (durations[routeName] == null || durations[routeName].length != 2)
      throw 'invalid timeline data for $routeName transition';
  }

  // Save the durations Map to a file.
  final String destinationDirectory = 'build';
  final FileSystem fs = new LocalFileSystem();
  await fs.directory(destinationDirectory).create(recursive: true);
  final File file = fs.file(path.join(destinationDirectory, 'transition_durations.timeline.json'));
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
        driver.close();
    });

    test('all demos', () async {
      Timeline timeline = await driver.traceAction(() async {
        // Expand the demo category submenus.
        for (String category in demoCategories.reversed) {
          await driver.tap(find.text(category));
          await new Future<Null>.delayed(new Duration(milliseconds: 500));
        }
        // Scroll each demo menu item into view, launch the demo and
        // return to the demo menu 2x.
        for(String demoTitle in demoTitles) {
          SerializableFinder menuItem = find.text(demoTitle);
          await driver.scrollIntoView(menuItem);
          await new Future<Null>.delayed(new Duration(milliseconds: 500));

          for(int i = 0; i < 2; i += 1) {
            await driver.tap(menuItem); // Launch the demo
            await new Future<Null>.delayed(new Duration(milliseconds: 500));
            await driver.tap(find.byTooltip('Back'));
            await new Future<Null>.delayed(new Duration(milliseconds: 1000));
          }
        }
      },
      streams: const <TimelineStream>[
        TimelineStream.dart
      ]);

      // Save the duration (in microseconds) of the first timeline Frame event
      // that follows a 'Start Transition' event. The Gallery app adds a
      // 'Start Transition' event when a demo is launched (see GalleryItem).
      saveDurationsHistogram(timeline.json['traceEvents']);

    }, timeout: new Timeout(new Duration(minutes: 5)));
  });
}

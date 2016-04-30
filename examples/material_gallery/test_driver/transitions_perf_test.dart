// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

// Warning: the following strings must be kept in sync with GalleryHome.
const List<String> demoCategories = const <String>['Demos', 'Components', 'Style'];

const List<String> demoNames = const <String>[
  'Weather',
  'Fitness',
  'Fancy lines',
  'Flexible space toolbar',
  'Floating action button',
  'Buttons',
  'Cards',
  'Chips',
  'Date picker',
  'Data tables',
  'Dialog',
  'Drop-down button',
  'Expand/collapse list control',
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
  'Colors',
  'Typography'
];

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
        // return to the demo menu 5x.
        for(String demoName in demoNames) {
          SerializableFinder menuItem = find.text(demoName);
          await driver.scrollToVisible(menuItem);
          await new Future<Null>.delayed(new Duration(milliseconds: 500));

          for(int i = 0; i < 5; i += 1) {
            await driver.tap(menuItem); // Launch the demo
            await new Future<Null>.delayed(new Duration(milliseconds: 500));
            await driver.tap(find.byTooltip('Back'));
            await new Future<Null>.delayed(new Duration(milliseconds: 1000));
          }
        }
      });
      new TimelineSummary.summarize(timeline)
        ..writeSummaryToFile('transitions_perf', pretty: true)
        ..writeTimelineToFile('transitions_perf', pretty: true);
    }, timeout: new Timeout(new Duration(minutes: 15)));
  });
}

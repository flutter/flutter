// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/find.dart';
import 'package:test/test.dart';

void main() {
  group('button tap test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null)
        driver.close();
    });

    test('tap on the button, verify result', () async {
      final Timeline timeline = await driver.traceAction(() async {

        SerializableFinder batteryLevelLabel = find.byValueKey('Battery level label');
        expect(batteryLevelLabel, isNotNull);

        SerializableFinder button = find.text('Get Battery Level');
        await driver.waitFor(button);
        await driver.tap(button);

        driver.waitUntilNoTransientCallbacks();

        String label = await driver.getText(batteryLevelLabel);

        String successPrefix = 'Battery level at';
        String failPrefix = 'Failed to get battery level';
        Match match = successPrefix.matchAsPrefix(label) != null
            ? successPrefix
            : failPrefix.matchAsPrefix(label);
        expect(match, isNotNull);
      });

      new TimelineSummary.summarize(timeline)
        ..writeSummaryToFile('button_tap', pretty: true)
        ..writeTimelineToFile('button_tap', pretty: true);
    });
  });
}
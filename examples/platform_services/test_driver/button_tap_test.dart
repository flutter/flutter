// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_driver/src/find.dart';
import 'package:flutter_driver/src/retry.dart';
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
        SerializableFinder batteryLevelLabel = find.byValueKey('Battery level label');
        expect(batteryLevelLabel, isNotNull);

        SerializableFinder button = find.text('Get Battery Level');
        await driver.waitFor(button);
        await driver.tap(button);

      expect(
        retry(
          () async {
            return await driver.getText(batteryLevelLabel);
          },
          const Duration(milliseconds: 30),
          const Duration(milliseconds: 10),
          predicate: (String result) {
            return 'Battery level at'.matchAsPrefix(result) != null;
          }
        ),
        completion(anything)
      );
    });
  });
}
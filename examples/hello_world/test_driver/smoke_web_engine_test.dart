// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

/// The following test is used as a simple smoke test for verfying Flutter
/// Framework and Flutter Web Engine integration.
void main() {
  group('Hello World App', () {
    final SerializableFinder titleFinder = find.byValueKey('title');

    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('title is correct', () async {
      expect(await driver.getText(titleFinder), 'Hello, world!');
    });
  });
}

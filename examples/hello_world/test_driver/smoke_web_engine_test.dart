// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8
import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:webdriver/async_io.dart';

/// The following test is used as a simple smoke test for verifying Flutter
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
      driver.close();
    });

    test('title is correct', () async {
      expect(await driver.getText(titleFinder), 'Hello, world!');
    });

    test('enable accessibility', () async {
      await driver.enableAccessibility();

      await Future<void>.delayed(const Duration(seconds: 2));

      // Elements with tag "flt-semantics" would show up after enabling
      // accessibility.
      //
      // The tag used here is based on
      // https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/semantics/semantics.dart#L534
      final WebElement element = await driver.webDriver.findElement(const By.tagName('flt-semantics'));

      expect(element, isNotNull);
    });
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:webdriver/async_io.dart';

// TODO(web): Migrate this test to a normal integration_test with a WidgetTester.

/// The following test is used as a simple smoke test for verifying Flutter
/// Framework and Flutter Web Engine integration.
void main() {
  group('Hello World App', () {
    final SerializableFinder titleFinder = find.byValueKey('title');

    late FlutterDriver driver;

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
      await driver.setSemantics(true);

      // TODO(ianh): this delay violates our style guide. We should instead wait for a triggering event.
      await Future<void>.delayed(const Duration(seconds: 2));

      // A flutter web app may be rendered directly on the body of the page, or
      // inside the shadow root of the flt-glass-pane (after Flutter 2.4). To
      // make this test backwards compatible, we first need to locate the correct
      // root for the app.
      //
      // It's either the shadowRoot within flt-glass-pane, or [driver.webDriver].
      final SearchContext appRoot = await driver.webDriver.execute(
        'return document.querySelector("flt-glass-pane")?.shadowRoot;',
        <dynamic>[],
      ) as SearchContext? ?? driver.webDriver;

      // Elements with tag "flt-semantics" would show up after enabling
      // accessibility.
      //
      // The tag used here is based on
      // https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/semantics/semantics.dart#L534
      final WebElement element = await appRoot.findElement(const By.cssSelector('flt-semantics'));

      expect(element, isNotNull);
    });
  });
}

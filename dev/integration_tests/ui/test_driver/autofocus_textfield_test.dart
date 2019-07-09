// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:integration_ui/keys.dart' as keys;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('Autofocused TextField shows selection menu after longpress', () async {
      final SerializableFinder textFieldFinder = find.byValueKey(keys.kDefaultTextField);
      final SerializableFinder pasteFinder = find.text('Paste');

      // The TextField exists but the selection menu isn't shown yet.
      await driver.waitFor(textFieldFinder);
      await driver.waitForAbsent(pasteFinder);

      // Long press to show the selection menu.
      await driver.scroll(textFieldFinder, 0, 0, const Duration(milliseconds: 500));
      await driver.waitFor(pasteFinder);
    });
  });
}

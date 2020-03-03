// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

Future<void> main() async {
  FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() => driver.close());

  test('Merge thread to create and remove platform views should not crash', () async {

    final SerializableFinder platformViewButton =
        find.byValueKey('platform_view_button');
    await driver.waitFor(platformViewButton);
    await driver.tap(platformViewButton);

    final SerializableFinder plusButton =
        find.byValueKey('plus_button');
    await driver.waitFor(plusButton);
    await driver.waitUntilNoTransientCallbacks();
    await driver.tap(plusButton);
    await driver.waitUntilNoTransientCallbacks();

    final SerializableFinder backButton = find.pageBack();
    await driver.tap(backButton);
    await driver.waitUntilNoTransientCallbacks();

    Health driverHealth = await driver.checkHealth();
    expect(driverHealth.status, HealthStatus.ok);
  });
}
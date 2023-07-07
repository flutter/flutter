// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  tearDownAll(() async {
    await driver.close();
  });

  //TODO(cyanglaz): Use TabBar tabs to navigate between pages after https://github.com/flutter/flutter/issues/16991 is fixed.
  //TODO(cyanglaz): Un-skip the test after https://github.com/flutter/flutter/issues/43012 is fixed
  test('Push a page contains video and pop back, do not crash.', () async {
    final SerializableFinder pushTab = find.byValueKey('push_tab');
    await driver.waitFor(pushTab);
    await driver.tap(pushTab);
    await driver.waitForAbsent(pushTab);
    await driver.waitFor(find.byValueKey('home_page'));
    await driver.waitUntilNoTransientCallbacks();
    final Health health = await driver.checkHealth();
    expect(health.status, HealthStatus.ok);
  }, skip: 'Cirrus CI currently hangs while playing videos');
}

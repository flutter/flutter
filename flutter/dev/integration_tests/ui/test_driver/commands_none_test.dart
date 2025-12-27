// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  test('check that we are in normal mode', () async {
    expect(await driver.requestData('status'), 'log: paint');
    await driver.waitForAbsent(find.byType('PerformanceOverlay'));
  }, timeout: Timeout.none);
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('channel suite', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    test('step through', () async {
      final SerializableFinder stepButton = find.byValueKey('step');
      final SerializableFinder statusField = find.byValueKey('status');
      int step = 0;
      while (await driver.getText(statusField) == 'ok') {
        await driver.tap(stepButton);
        step++;
      }
      final String status = await driver.getText(statusField);
      if (status != 'complete') {
        fail('Failed at step $step with status $status');
      }
    }, timeout: const Timeout(Duration(minutes: 1)));

    tearDownAll(() async {
      driver?.close();
    });
  });
}

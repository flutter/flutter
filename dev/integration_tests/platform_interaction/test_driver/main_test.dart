// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('channel suite', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect(printCommunication: true);
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
    });

    tearDownAll(() async {
      driver?.close();
    });
  });
}

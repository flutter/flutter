// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('channel suite', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    test('run ffi tests', () async {
      final SerializableFinder runButton = find.byValueKey('run');
      final SerializableFinder stepName = find.byValueKey('status');
      final SerializableFinder stepOutcome = find.byValueKey('outcome');

      while (await driver.getText(stepName) != 'Status: Start') {
        await Future<dynamic>.delayed(const Duration(milliseconds: 1));
      }
      await driver.tap(runButton);
      while (await driver.getText(stepName) == 'Status: Executing') {
        await Future<dynamic>.delayed(const Duration(milliseconds: 1));
      }
      if (await driver.getText(stepName) != 'Status: Success') {
        fail('Did not complete running FFI tests successfully:\n'
             '${await driver.getText(stepName)}\n'
             '${await driver.getText(stepOutcome)}');
      }
    }, timeout: const Timeout(Duration(minutes: 1)));

    tearDownAll(() async {
      driver?.close();
    });
  });
}

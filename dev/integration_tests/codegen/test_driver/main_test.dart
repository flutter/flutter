// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Can execute generated code', () async {
      const String button = 'Press Button, Get Coffee';
      await driver.tap(find.text(button));

      const String message = 'Thanks for using PourOverSupremeFiesta by Coffee by Flutter Inc.';
      final String fullMessage = await driver.getText(find.text(message));
      expect(fullMessage, message);
    });
}

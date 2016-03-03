// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

main() {
  group('scrolling performance test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null)
        driver.close();
    });

    test('tap on the floating action button; verify counter', () async {
      // Find the scrollable stock list
      ObjectRef stockList = await driver.findByValueKey('stock-list');
      expect(stockList, isNotNull);

      // Scroll down 5 times
      for (int i = 0; i < 5; i++) {
        await driver.scroll(stockList, 0.0, -300.0, new Duration(milliseconds: 300));
        await new Future.delayed(new Duration(milliseconds: 500));
      }

      // Scroll up 5 times
      for (int i = 0; i < 5; i++) {
        await driver.scroll(stockList, 0.0, 300.0, new Duration(milliseconds: 300));
        await new Future.delayed(new Duration(milliseconds: 500));
      }
    });
  });
}

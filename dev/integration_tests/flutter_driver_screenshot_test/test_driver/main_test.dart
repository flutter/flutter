// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import './driver_screenshot_tester.dart';

Future<void> main() async {
  FlutterDriver driver;
  String deviceModel;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
    deviceModel = await driver.requestData('device_model');
  });

  tearDownAll(() => driver.close());

  test('A page with an image screenshot', () async {

    final SerializableFinder imagePageListTile =
        find.byValueKey('image_page');
    await driver.waitFor(imagePageListTile);
    await driver.tap(imagePageListTile);
    await driver.waitFor(find.byValueKey('red_square_image'));
    await driver.waitUntilNoTransientCallbacks();

    final DriverScreenShotTester tester = DriverScreenShotTester(testName: 'red_square_image', deviceModel: deviceModel, driver: driver);
    final List<int> screenShot = await tester.getScreenshotAsBytes();
    final bool compareResult = await tester.compareScreenshots(screenShot);
    expect(compareResult, true);
    await driver.tap(find.byTooltip('Back'));
  });
}

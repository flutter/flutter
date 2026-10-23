// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect() as WebFlutterDriver;
  await (await driver.webDriver.window).setSize(const Rectangle<int>(0, 0, 1024, 1024));

  // Clicks must not depend on screenshots, so no onScreenshot is passed: a
  // screenshot request would fail the run.
  await integrationDriver(driver: driver);
}

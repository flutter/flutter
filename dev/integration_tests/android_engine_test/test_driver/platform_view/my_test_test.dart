// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:android_driver_extensions/native_driver.dart';
import 'package:android_driver_extensions/skia_gold.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import '../_luci_skia_gold_prelude.dart';

void main() async {
  late final FlutterDriver flutterDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await flutterDriver.close();
  });

  test('Should be able to tap multiple times', () async {
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));
    await flutterDriver.tap(find.byValueKey('TogglePlatformView'));

  }, timeout: Timeout.none);
}

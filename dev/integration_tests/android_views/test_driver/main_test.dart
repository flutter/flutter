// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;


Future<void> main() async {
  FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() {
    driver.close();
  });

  group('MotionEvents tests ', () {
    test('recomposition', () async {
      if (Platform.isAndroid) {
        final SerializableFinder motionEventsListTile =
        find.byValueKey('MotionEventsListTile');
        await driver.tap(motionEventsListTile);
        await driver.waitFor(find.byValueKey('PlatformView'));
        final String errorMessage = await driver.requestData('run test');
        expect(errorMessage, '');
      }
    });
  });

  group('Composition tests', (){
    test('mutations', () async {
        final SerializableFinder motionEventsListTile =
        find.byValueKey('MutationPageListTile');
        await driver.tap(motionEventsListTile);
        await driver.waitFor(find.byValueKey('PlatformView0'));
        _takeAndSaveScreenshot(driver, 'test_driver/screenshots/mutation_test.png');
        Image currentImage = image.file('test_driver/screenshots/mutation_test.png');
        assert(currentImage != null);
        Image screenShot = Image.memory(await driver.screenshot());
        expect(currentImage.toByteData == screenShot.toByteData);
     });
  });
}


_takeAndSaveScreenshot(FlutterDriver driver, String path) async {
  final List<int> pixels = await driver.screenshot();
  final File file = new File(path);
  await file.writeAsBytes(pixels);
}
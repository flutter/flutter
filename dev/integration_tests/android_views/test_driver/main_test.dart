// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform, File;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:collection/collection.dart';

const String kAndroidScreenShotPath =
    'test_driver/screenshots/mutation_test_android.png';

Future<void> main() async {
  FlutterDriver driver;

  group('MotionEvents tests ', () {
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });
    test('recomposition', () async {
      final SerializableFinder motionEventsListTile =
          find.byValueKey('MotionEventsListTile');
      await driver.tap(motionEventsListTile);
      await driver.waitFor(find.byValueKey('PlatformView'));
      final String errorMessage = await driver.requestData('run test');
      expect(errorMessage, '');
    });
  });

  group('Composition tests', () {
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });
    test('mutations', () async {
      final SerializableFinder motionEventsListTile =
          find.byValueKey('MutationPageListTile');
      await driver.tap(motionEventsListTile);
      await driver.waitFor(find.byValueKey('PlatformView0'));
      final List<int> screenShot = await driver.screenshot();
      final String path = _getScreenShotPath();
      print(Platform.operatingSystem);
      print(path);
      final File file = File(path);
      if (!file.existsSync()) {
        print('Platform view mutation test file not exist, creating a new one');
        file.writeAsBytesSync(screenShot);
      }
      final List<int> matcher = file.readAsBytesSync();

      final Function listEquals = const ListEquality<int>().equals;
      expect(listEquals(screenShot, matcher), true);
    });
  });
}

String _getScreenShotPath() {
  return kAndroidScreenShotPath;
}

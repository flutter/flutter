// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:collection/collection.dart';

const String kAndroidScreenShotPathStandard =
    'test_driver/screenshots/mutation_test_android.png';
const String kAndroidScreenShotPathWithScrollView =
    'test_driver/screenshots/mutation_test_android_scroll.png';
const String kIOSScreenShotPathStandard =
    'test_driver/screenshots/mutation_test_ios.png';
const String kIOSScreenShotPathWithScrollView =
    'test_driver/screenshots/mutation_test_ios_scroll.png';

// Currently, only `MotionEvents tests recomposition` have access to the `FlutterDriverExtension` callback.
// So we are setting and getting general information in the `MotionEvents tests recomposition` test. This test
// Has to be run as the first test case in this file.
Future<void> main() async {
  FlutterDriver driver;
  String target;

  group('MotionEvents tests ', () {
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    // This test suite only tests Android.
    // Has to be run as the first test case.
    test('recomposition', () async {
      final SerializableFinder motionEventsListTile =
          find.byValueKey('MotionEventsListTile');
      await driver.tap(motionEventsListTile);
      await driver.waitFor(find.byValueKey('PlatformView'));
      target = await driver.requestData('target_platform');
      print(target);
      if (target == 'android') {
        final String errorMessage = await driver.requestData('run test');
        expect(errorMessage, '');
      }
      final String popStatus = await driver.requestData('pop');
      assert(popStatus == 'success');
    });
  });

  group('Composition tests', () {
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });
    test('mutations standard', () async {
      assert(target == 'ios' || target == 'android');
      final SerializableFinder motionEventsListTile =
          find.byValueKey('MutationPageListTile');
      await driver.tap(motionEventsListTile);
      await driver.waitFor(find.byValueKey('PlatformView0'));
      final List<int> screenShot = await driver.screenshot();
      final String path = target == 'ios'?kIOSScreenShotPathStandard:kAndroidScreenShotPathStandard;
      final File file = File(path);
      final List<int> matcher = file.readAsBytesSync();

      final Function listEquals = const ListEquality<int>().equals;
      expect(listEquals(screenShot, matcher), true);
      await driver.tap(find.byValueKey('back'));
    });

    // Testing a failure case that was raised in https://github.com/flutter/flutter/issues/35840.
    test('mutations: clipping with scrolling view', () async {
      assert(target == 'ios' || target == 'android');
      final SerializableFinder motionEventsListTile =
          find.byValueKey('ScrollViewNestedPlatformViewListTile');
      await driver.tap(motionEventsListTile);
      await driver.waitFor(find.byValueKey('PlatformView'));
      final List<int> screenShot = await driver.screenshot();
      final String path = target == 'ios'?kIOSScreenShotPathWithScrollView:kAndroidScreenShotPathWithScrollView;
      final File file = File(path);
      final List<int> matcher = file.readAsBytesSync();

      final Function listEquals = const ListEquality<int>().equals;
      expect(listEquals(screenShot, matcher), true);
      await driver.tap(find.byValueKey('back'));
    });
  });
}
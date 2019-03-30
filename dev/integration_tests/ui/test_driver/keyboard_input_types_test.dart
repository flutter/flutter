// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:meta/meta.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import '../../../devicelab/lib/framework/adb.dart' as adb;
import '../../../devicelab/lib/framework/adb.dart' show Device, AndroidDevice;

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver?.close();
    });

    test('Flutter textfields display keyboard characters that the user enters, no matter which input type is chosen', () async {
      await driver.setTextEntryEmulation(enabled: false); // we want the keyboard to come up

      final SerializableFinder textFieldFinder = find.byValueKey('text');
      final SerializableFinder datetimeFieldFinder = find.byValueKey('datetime');
      final SerializableFinder emailAddressFieldFinder = find.byValueKey('emailAddress');
      final SerializableFinder multilineFieldFinder = find.byValueKey('multiline');
      final SerializableFinder numberFieldFinder = find.byValueKey('number');
      final SerializableFinder phoneFieldFinder = find.byValueKey('phone');
      final SerializableFinder urlFieldFinder = find.byValueKey('url');
      const String kTestText = '1';

      final AndroidDevice device = await adb.devices.workingDevice;

      await enterTextAndVerifyAppearance(
        device: device,
        driver: driver,
        fieldFinder: textFieldFinder,
        textToEnter: kTestText,
      );

      await enterTextAndVerifyAppearance(
        device: device,
        driver: driver,
        fieldFinder: datetimeFieldFinder,
        textToEnter: kTestText,
      );

      await enterTextAndVerifyAppearance(
        device: device,
        driver: driver,
        fieldFinder: emailAddressFieldFinder,
        textToEnter: kTestText,
      );

      await enterTextAndVerifyAppearance(
        device: device,
        driver: driver,
        fieldFinder: multilineFieldFinder,
        textToEnter: kTestText,
      );

      await enterTextAndVerifyAppearance(
        device: device,
        driver: driver,
        fieldFinder: numberFieldFinder,
        textToEnter: kTestText,
      );

      await enterTextAndVerifyAppearance(
        device: device,
        driver: driver,
        fieldFinder: phoneFieldFinder,
        textToEnter: kTestText,
      );

      await enterTextAndVerifyAppearance(
        device: device,
        driver: driver,
        fieldFinder: urlFieldFinder,
        textToEnter: kTestText,
      );
    });
  });
}

Future<void> enterTextAndVerifyAppearance({
  @required AndroidDevice device,
  @required FlutterDriver driver,
  @required SerializableFinder fieldFinder,
  @required String textToEnter,
}) async {
  // Bring up keyboard
  await driver.tap(fieldFinder);
  await Future<void>.delayed(const Duration(seconds: 1));

  // Enter the desired text.
  // await device.adb(<String>[
  //   'shell',
  //   'input',
  //   'keyboard',
  //   'text',
  //   '"$textToEnter"'
  // ]);
  await device.adb(<String>[
    'shell',
    'input',
    'keyevent',
    '8'
  ]);
  // await device.typeTextOnVirtualKeyboard(textToEnter);

  await driver.waitUntilNoTransientCallbacks();
  await Future<void>.delayed(const Duration(seconds: 5));

  // Verify that the desired text resides within the textfield.
  expect(await driver.getText(fieldFinder), textToEnter);
}
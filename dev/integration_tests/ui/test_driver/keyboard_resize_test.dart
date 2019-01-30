// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:integration_ui/keys.dart' as keys;
import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver?.close();
    });

    test('Ensure keyboard dismissal resizes the view to original size', () async {
      await driver.setTextEntryEmulation(enabled: false);
      final SerializableFinder heightText = find.byValueKey(keys.kHeightText);
      await driver.waitFor(heightText);

      // Measure the initial height.
      final String startHeight = await driver.getText(heightText);

      // Focus the text field to show the keyboard.
      final SerializableFinder defaultTextField = find.byValueKey(keys.kDefaultTextField);
      await driver.waitFor(defaultTextField);
      await driver.tap(defaultTextField);
      await Future<void>.delayed(const Duration(seconds: 1));

      // Measure the height with keyboard displayed.
      final String heightWithKeyboardShown = await driver.getText(heightText);
      expect(double.parse(heightWithKeyboardShown) < double.parse(startHeight), isTrue);

      // Unfocus the text field to dismiss the keyboard.
      final SerializableFinder unfocusButton = find.byValueKey(keys.kUnfocusButton);
      await driver.waitFor(unfocusButton);
      await driver.tap(unfocusButton);
      await Future<void>.delayed(const Duration(seconds: 1));

      // Measure the final height.
      final String endHeight = await driver.getText(heightText);

      expect(endHeight, startHeight);
    });
  });
}

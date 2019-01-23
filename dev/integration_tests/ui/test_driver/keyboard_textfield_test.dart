// Copyright 2018 The Chromium Authors. All rights reserved.
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

    test('Textfield scrolls back into view after covered by keyboard', () async {
      await driver.setTextEntryEmulation(enabled: false); // we want the keyboard to come up

      final SerializableFinder listViewFinder = find.byValueKey(keys.kListView);
      final SerializableFinder textFieldFinder = find.byValueKey(keys.kDefaultTextField);
      final SerializableFinder autoSelectTextFieldFinder = find.byValueKey(keys.kAutoSelectTextField);
      final SerializableFinder dismissButtonFinder = find.byValueKey(keys.kDismissButton);
      final SerializableFinder offsetFinder = find.byValueKey(keys.kOffsetText);

      // Align TextField with bottom edge to ensure it would be covered when keyboard comes up.
      await driver.waitForAbsent(textFieldFinder);
      await driver.scrollUntilVisible(
        listViewFinder,
        textFieldFinder,
        alignment: 1.0,
        dyScroll: -20.0,
      );
      await driver.waitFor(textFieldFinder);
      final double scrollOffsetWithoutKeyboard = double.parse(await driver.getText(offsetFinder));

      // Bring up keyboard
      await driver.tap(textFieldFinder);
      await Future<void>.delayed(const Duration(seconds: 1));

      // Ensure that TextField is visible again
      await driver.waitFor(textFieldFinder);
      final double scrollOffsetWithKeyboard = double.parse(await driver.getText(offsetFinder));

      // Ensure the scroll offset changed appropriately when TextField scrolled back into view.
      expect(scrollOffsetWithKeyboard, greaterThan(scrollOffsetWithoutKeyboard));

      // now do the same for the TextField with auto select
      await driver.tap(dismissButtonFinder);
      await Future<void>.delayed(const Duration(seconds: 1));

      await driver.scrollUntilVisible(
        listViewFinder,
        autoSelectTextFieldFinder,
        alignment: 1.0,
        dyScroll: -20.0,
      );
      await driver.waitFor(autoSelectTextFieldFinder);
      final double autoSelectScrollOffsetWithoutKeyboard = double.parse(await driver.getText(offsetFinder));

      // Bring up keyboard
      await driver.tap(autoSelectTextFieldFinder);
      await Future<void>.delayed(const Duration(seconds: 1));

      // Ensure that TextField is visible again
      await driver.waitFor(autoSelectTextFieldFinder);
      final double autoSelectScrollOffsetWithKeyboard = double.parse(await driver.getText(offsetFinder));

      // Ensure the scroll offset changed appropriately when TextField scrolled back into view.
      expect(autoSelectScrollOffsetWithKeyboard, greaterThan(autoSelectScrollOffsetWithoutKeyboard));


    });
  });
}

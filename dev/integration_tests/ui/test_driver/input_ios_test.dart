// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:image/image.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('FlutterDriver', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Autocorrection highlight rect appear and disappear as expected.', () async {
      final SerializableFinder textFieldFinder = find.byValueKey('enter-text-field');
      final Matcher promptRectVisible = contains(getColor(0x00, 0x7A, 0xFF, 47));

      Future<void> verifyScreenshot(bool hasPromptRect) async {
        final Image image = decodePng(await driver.screenshot());
        expect(
          image.data,
          hasPromptRect ? promptRectVisible : isNot(promptRectVisible),
        );
      }

      await driver.waitFor(textFieldFinder);
      await driver.tap(textFieldFinder);

      driver.enterText('a');
      await driver.waitFor(find.text('a'));
      // Wait for the prompt rect to show up.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await verifyScreenshot(false);

      driver.enterText('asd');
      // Wait for the prompt rect to show up.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await driver.waitFor(find.text('asd'));
      await verifyScreenshot(true);

      driver.enterText('asdz');
      // Wait for the prompt rect to show up.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await driver.waitFor(find.text('asdz'));
      await verifyScreenshot(true);

      driver.enterText('asd');
      // Wait for the prompt rect to show up.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await driver.waitFor(find.text('asd'));
      // Should not show up since we deleted the last character.
      await verifyScreenshot(false);
    });
  });
}

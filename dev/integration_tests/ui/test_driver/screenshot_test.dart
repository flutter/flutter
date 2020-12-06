// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

    test('should take screenshot', () async {
      final SerializableFinder toggleBtn = find.byValueKey('toggle');
      // Cards use a magic background color that we look for in the screenshots.
      final Matcher cardsAreVisible = contains(getColor(0xff, 0x01, 0x02));
      await driver.waitFor(toggleBtn);

      bool cardsShouldBeVisible = false;
      Image imageBefore = decodePng(await driver.screenshot());
      for (int i = 0; i < 10; i += 1) {
        await driver.tap(toggleBtn);
        cardsShouldBeVisible = !cardsShouldBeVisible;
        final Image imageAfter = decodePng(await driver.screenshot());

        if (cardsShouldBeVisible) {
          expect(imageBefore.data, isNot(cardsAreVisible));
          expect(imageAfter.data, cardsAreVisible);
        } else {
          expect(imageBefore.data, cardsAreVisible);
          expect(imageAfter.data, isNot(cardsAreVisible));
        }

        imageBefore = imageAfter;
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('Texture rendering integration test', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('renders red color when Red button is pressed', () async {
      // Find the "Red" button.
      final SerializableFinder redButton = find.text('Red');
      await driver.waitFor(redButton);

      // Take initial screenshot before changing the color to Red.
      final List<int> initialScreenshot = await driver.screenshot(
        format: ScreenshotFormat.rawStraightRgba,
      );

      final int initialRedPixels = countRedPixels(initialScreenshot);
      // ignore: avoid_print
      print('Initial red pixel count: $initialRedPixels');
      // Initially, there shouldn't be a significant number of pixels matching the texture's red color.
      expect(initialRedPixels, lessThan(100));

      // Tap the "Red" button.
      await driver.tap(redButton);

      // Poll, taking screenshots and counting red pixels for up to 10 seconds (20 attempts of 500ms).
      var afterRedPixels = 0;
      var attempt = 1;
      while (afterRedPixels < 10000) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final List<int> afterScreenshot = await driver.screenshot(
          format: ScreenshotFormat.rawStraightRgba,
        );
        afterRedPixels = countRedPixels(afterScreenshot);
        // ignore: avoid_print
        print('Attempt $attempt: after red pixel count = $afterRedPixels');
        attempt++;
      }

      // The texture size is 300x300. Even with scaling/different device pixel ratio,
      // there should be a substantial block of red pixels (at least several thousands).
      expect(afterRedPixels, greaterThan(10000));
    });
  });
}

int countRedPixels(List<int> data) {
  var count = 0;
  for (var i = 0; i < data.length; i += 4) {
    final int r = data[i];
    final int g = data[i + 1];
    final int b = data[i + 2];
    if ((r - 0xf2).abs() < 5 && (g - 0x5d).abs() < 5 && (b - 0x50).abs() < 5) {
      count++;
    }
  }
  return count;
}

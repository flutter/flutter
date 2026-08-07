// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import '../test_driver/image_utils.dart';

void main() {
  group('isImageBlank', () {
    test('returns true for an empty or 0-sized image', () {
      final image = img.Image(width: 0, height: 0);
      expect(isImageBlank(image), isTrue);
    });

    test('returns true for a fully transparent image (all zero bytes)', () {
      final image = img.Image(
        width: 10,
        height: 10,
      ); // default is transparent black (all 0s)
      expect(isImageBlank(image), isTrue);
    });

    test('returns true for a solid opaque black image', () {
      final image = img.Image(width: 10, height: 10);
      for (final pixel in image) {
        pixel.r = 0;
        pixel.g = 0;
        pixel.b = 0;
        pixel.a = 255;
      }
      expect(isImageBlank(image), isTrue);
    });

    test('returns false for a solid opaque red image', () {
      final image = img.Image(width: 10, height: 10);
      for (final pixel in image) {
        pixel.r = 255;
        pixel.g = 0;
        pixel.b = 0;
        pixel.a = 255;
      }
      expect(isImageBlank(image), isFalse);
    });

    test('returns false for an image with drawings (one non-black pixel)', () {
      final image = img.Image(width: 10, height: 10);
      // set one pixel to red
      final img.Pixel pixel = image.getPixel(5, 5);
      pixel.r = 255;
      pixel.g = 0;
      pixel.b = 0;
      pixel.a = 255;
      expect(isImageBlank(image), isFalse);
    });
  });

  group('cropImage', () {
    test('crops image correctly within bounds', () {
      final image = img.Image(width: 10, height: 10);
      // Draw a pixel at (2, 2)
      final img.Pixel pixel = image.getPixel(2, 2);
      pixel.r = 255;
      pixel.g = 0;
      pixel.b = 0;
      pixel.a = 255;

      final img.Image cropped = cropImage(image, 1, 1, 3, 3);
      expect(cropped.width, equals(3));
      expect(cropped.height, equals(3));

      // The drawn pixel at (2, 2) relative to parent is now at (1, 1) relative to cropped image
      final img.Pixel croppedPixel = cropped.getPixel(1, 1);
      expect(croppedPixel.r, equals(255));
      expect(croppedPixel.a, equals(255));
    });

    test('throws ArgumentError for invalid crop bounds', () {
      final image = img.Image(width: 10, height: 10);
      expect(() => cropImage(image, -1, 0, 5, 5), throwsArgumentError);
      expect(() => cropImage(image, 0, -1, 5, 5), throwsArgumentError);
      expect(() => cropImage(image, 0, 0, 11, 5), throwsArgumentError);
      expect(() => cropImage(image, 0, 0, 5, 11), throwsArgumentError);
      expect(() => cropImage(image, 8, 8, 5, 5), throwsArgumentError);
    });
  });
}

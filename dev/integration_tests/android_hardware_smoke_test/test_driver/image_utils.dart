// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Checks if the image is transparent or solid black.
bool isImageBlank(img.Image image) {
  if (image.width == 0 || image.height == 0) {
    return true;
  }
  final img.Pixel pixel0 = image.getPixel(0, 0);
  final num r0 = pixel0.r;
  final num g0 = pixel0.g;
  final num b0 = pixel0.b;
  final num a0 = pixel0.a;

  final bool isTransparentOrBlack = a0 == 0 || (r0 == 0 && g0 == 0 && b0 == 0);
  if (!isTransparentOrBlack) {
    return false;
  }

  // Fast path: check raw memory buffer directly to avoid pixel wrapper allocations in the loop
  try {
    final Uint32List pixels = image.buffer.asUint32List();
    final int val0 = pixels[0];
    for (var i = 1; i < pixels.length; i++) {
      if (pixels[i] != val0) {
        return false;
      }
    }
    return true;
  } catch (_) {
    // Fall back to safe iterator if the buffer alignment/type is different
    for (final pixel in image) {
      if (pixel.r != r0 || pixel.g != g0 || pixel.b != b0 || pixel.a != a0) {
        return false;
      }
    }
    return true;
  }
}

/// Validates crop bounds and crops [source] to the specified rect.
img.Image cropImage(img.Image source, int x, int y, int width, int height) {
  if (x < 0 ||
      y < 0 ||
      width <= 0 ||
      height <= 0 ||
      x + width > source.width ||
      y + height > source.height) {
    throw ArgumentError(
      'Crop bounds out of range: x=$x, y=$y, width=$width, height=$height, source.width=${source.width}, source.height=${source.height}',
    );
  }
  return img.copyCrop(source, x: x, y: y, width: width, height: height);
}

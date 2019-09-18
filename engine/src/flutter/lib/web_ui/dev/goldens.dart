// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:image/image.dart';

/// This class encapsulates visually diffing an Image with any other.
/// Both images need to be the exact same size.
class ImageDiff {

  /// The image to match
  final Image golden;

  /// The image being compared
  final Image other;

  /// The output of the comparison
  /// Pixels in the output image can have 3 different colors depending on the comparison
  /// between golden pixels and other pixels:
  ///  * white: when both pixels are the same
  ///  * red: when a pixel is found in other, but not in golden
  ///  * green: when a pixel is found in golden, but not in other
  Image diff;

  /// The ratio of wrong pixels to all pixels in golden (between 0 and 1)
  /// This gets set to 1 (100% difference) when golden and other aren't the same size.
  double get rate => _wrongPixels / _pixelCount;

  ImageDiff({ Image this.golden, Image this.other }) {
    _computeDiff();
  }

  int _pixelCount = 0;
  int _wrongPixels = 0;

  final int _colorOk = Color.fromRgb(255, 255, 255);
  final int _colorBadPixel = Color.fromRgb(255, 0, 0);
  final int _colorExpectedPixel = Color.fromRgb(0, 255, 0);

  void _computeDiff() {
    int goldenWidth = golden.width;
    int goldenHeight = golden.height;

    _pixelCount = goldenWidth * goldenHeight;
    diff = Image(goldenWidth, goldenHeight);

    if (goldenWidth == other.width && goldenHeight == other.height) {
      for(int y = 0; y < goldenHeight; y++) {
        for (int x = 0; x < goldenWidth; x++) {
          int goldenPixel = golden.getPixel(x, y);
          int otherPixel = other.getPixel(x, y);

          if (goldenPixel == otherPixel) {
            diff.setPixel(x, y, _colorOk);
          } else {
            if (getLuminance(goldenPixel) < getLuminance(otherPixel)) {
              diff.setPixel(x, y, _colorExpectedPixel);
            } else {
              diff.setPixel(x, y, _colorBadPixel);
            }
            _wrongPixels++;
          }
        }
      }
    } else {
      // Images are completely different resolutions. Bail out big time.
      _wrongPixels = _pixelCount;
    }
  }
}

// Returns text with info about the files we just compared
String getPrintableDiffFilesInfo(diffRate, maxRate, filename, outputPath, diffPath) => '''
(${((diffRate) * 100).toStringAsFixed(4)}% different pixels. Max: ${((maxRate) * 100).toStringAsFixed(4)}%).

* Output image: ${outputPath}
*  Diff pixels: ${diffPath}

To update the golden file call matchGoldenFile('$filename', write: true).
''';

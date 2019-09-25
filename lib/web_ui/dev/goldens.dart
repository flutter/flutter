// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io' as io;
import 'package:image/image.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'environment.dart';
import 'utils.dart';

void main(List<String> args) {
  final io.File fileA = io.File(args[0]);
  final io.File fileB = io.File(args[1]);
  final Image imageA = decodeNamedImage(fileA.readAsBytesSync(), 'a.png');
  final Image imageB = decodeNamedImage(fileB.readAsBytesSync(), 'b.png');
  final ImageDiff diff = ImageDiff(golden: imageA, other: imageB);
  print('Diff: ${(diff.rate * 100).toStringAsFixed(4)}%');
}

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

  /// That would be the distance between black and white.
  static final double _maxTheoreticalColorDistance = Color.distance(
    <int>[255, 255, 255],  // white
    <int>[0, 0, 0],  // black
    false,
  );

  // If the normalized color difference of a pixel is greater than this number,
  // we consider it a wrong pixel.
  static const double _kColorDistanceThreshold = 0.1;

  final int _colorOk = Color.fromRgb(255, 255, 255);
  final int _colorBadPixel = Color.fromRgb(255, 0, 0);
  final int _colorExpectedPixel = Color.fromRgb(0, 255, 0);

  /// Reads a pixel value out of [image] at [x] and [y].
  ///
  /// If the pixel is out of bounds, reflects the [x] and [y] coordinates off
  /// the border back into the image treating the border like a mirror.
  static int _reflectedPixel(Image image, int x, int y) {
    x = x.abs();
    if (x == image.width) {
      x = image.width - 2;
    }

    y = y.abs();
    if (y == image.height) {
      y = image.height - 2;
    }

    return image.getPixel(x, y);
  }

  static int _average(Iterable<int> values) {
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  /// Reads the RGBA values of the average of the 3x3 box of pixels centered at [x] and [y].
  static List<int> _getFuzzyRgb(Image image, int x, int y) {
    final List<int> pixels = <int>[
      _reflectedPixel(image, x - 1, y - 1),
      _reflectedPixel(image, x - 1, y),
      _reflectedPixel(image, x - 1, y + 1),

      _reflectedPixel(image, x, y - 1),
      _reflectedPixel(image, x, y),
      _reflectedPixel(image, x, y + 1),

      _reflectedPixel(image, x + 1, y - 1),
      _reflectedPixel(image, x + 1, y),
      _reflectedPixel(image, x + 1, y + 1),
    ];
    return <int>[
      _average(pixels.map((p) => getRed(p))),
      _average(pixels.map((p) => getGreen(p))),
      _average(pixels.map((p) => getBlue(p))),
    ];
  }

  void _computeDiff() {
    int goldenWidth = golden.width;
    int goldenHeight = golden.height;

    _pixelCount = goldenWidth * goldenHeight;
    diff = Image(goldenWidth, goldenHeight);

    if (goldenWidth == other.width && goldenHeight == other.height) {
      for(int y = 0; y < goldenHeight; y++) {
        for (int x = 0; x < goldenWidth; x++) {
          final bool isExactlySame = golden.getPixel(x, y) == other.getPixel(x, y);
          final List<int> goldenPixel = _getFuzzyRgb(golden, x, y);
          final List<int> otherPixel = _getFuzzyRgb(other, x, y);
          final double colorDistance = Color.distance(goldenPixel, otherPixel, false) / _maxTheoreticalColorDistance;
          if (isExactlySame || colorDistance < _kColorDistanceThreshold) {
            diff.setPixel(x, y, _colorOk);
          } else {
            final int goldenLuminance = getLuminanceRgb(goldenPixel[0], goldenPixel[1], goldenPixel[2]);
            final int otherLuminance = getLuminanceRgb(otherPixel[0], otherPixel[1], otherPixel[2]);
            if (goldenLuminance < otherLuminance) {
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

// Returns text explaining pixel difference rate.
String getPrintableDiffFilesInfo(double diffRate, double maxRate) =>
  '(${((diffRate) * 100).toStringAsFixed(4)}% of pixels were different. '
  'Maximum allowed rate is: ${(maxRate * 100).toStringAsFixed(4)}%).';

/// Fetches golden files from github.com/flutter/goldens, cloning the repository if necessary.
///
/// The repository is cloned into web_ui/.dart_tool.
Future<void> fetchGoldens() async {
  await _GoldensRepoFetcher().fetch();
}

class _GoldensRepoFetcher {
  String _repository;
  String _revision;

  Future<void> fetch() async {
    final io.File lockFile = io.File(
      path.join(environment.webUiDevDir.path, 'goldens_lock.yaml')
    );
    final YamlMap lock = loadYaml(lockFile.readAsStringSync());
    _repository = lock['repository'];
    _revision = lock['revision'];

    final String localRevision = await _getLocalRevision();
    if (localRevision == _revision) {
      return;
    }

    print('Fetching $_repository@$_revision');

    if (!environment.webUiGoldensRepositoryDirectory.existsSync()) {
      environment.webUiGoldensRepositoryDirectory.createSync(recursive: true);
      await runProcess(
        'git',
        <String>['init'],
        workingDirectory: environment.webUiGoldensRepositoryDirectory.path,
        mustSucceed: true,
      );
      await runProcess(
        'git',
        <String>['remote', 'add', 'origin', _repository],
        workingDirectory: environment.webUiGoldensRepositoryDirectory.path,
        mustSucceed: true,
      );
    }

    await runProcess(
      'git',
      <String>['fetch', 'origin', 'master'],
      workingDirectory: environment.webUiGoldensRepositoryDirectory.path,
      mustSucceed: true,
    );
    await runProcess(
      'git',
      <String>['checkout', _revision],
      workingDirectory: environment.webUiGoldensRepositoryDirectory.path,
      mustSucceed: true,
    );
  }

  Future<String> _getLocalRevision() async {
    final io.File head = io.File(path.join(
      environment.webUiGoldensRepositoryDirectory.path, '.git', 'HEAD'
    ));

    if (!head.existsSync()) {
      return null;
    }

    return head.readAsStringSync().trim();
  }
}

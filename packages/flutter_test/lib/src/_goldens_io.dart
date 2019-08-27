// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test_api/test_api.dart' as test_package show TestFailure;

import 'goldens.dart';

/// The default [GoldenFileComparator] implementation for `flutter test`.
///
/// This comparator loads golden files from the local file system, treating the
/// golden key as a relative path from the test file's directory.
///
/// This comparator performs a pixel-for-pixel comparison of the decoded PNGs,
/// returning true only if there's an exact match.
///
/// When using `flutter test --update-goldens`, [LocalFileComparator]
/// updates the files on disk to match the rendering.
class LocalFileComparator extends GoldenFileComparator {
  /// Creates a new [LocalFileComparator] for the specified [testFile].
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which [testFile] resides.
  ///
  /// The [testFile] URL must represent a file.
  LocalFileComparator(Uri testFile, {path.Style pathStyle})
      : basedir = _getBasedir(testFile, pathStyle),
        _path = _getPath(pathStyle);

  static path.Context _getPath(path.Style style) {
    return path.Context(style: style ?? path.Style.platform);
  }

  static Uri _getBasedir(Uri testFile, path.Style pathStyle) {
    final path.Context context = _getPath(pathStyle);
    final String testFilePath = context.fromUri(testFile);
    final String testDirectoryPath = context.dirname(testFilePath);
    return context.toUri(testDirectoryPath + context.separator);
  }

  /// The directory in which the test was loaded.
  ///
  /// Golden file keys will be interpreted as file paths relative to this
  /// directory.
  final Uri basedir;

  /// Path context exists as an instance variable rather than just using the
  /// system path context in order to support testing, where we can spoof the
  /// platform to test behaviors with arbitrary path styles.
  final path.Context _path;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File goldenFile = _getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw test_package.TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    final List<int> goldenBytes = await goldenFile.readAsBytes();
    final ComparisonResult result = _compareLists(imageBytes, goldenBytes);

    if (!result.passed) {
      String additionalFeedback = '';
      if (result.diffs != null) {
        additionalFeedback = '\nFailure feedback can be found at ${path.join(basedir.path, 'failures')}';
        final Map<String, Image> diffs = result.diffs;
        diffs.forEach((String name, Image image) {
          final File output = _getFailureFile(name, golden);
          output.parent.createSync(recursive: true);
          output.writeAsBytesSync(encodePng(image));
        });
      }
      throw test_package.TestFailure('Golden "$golden": ${result.error}$additionalFeedback');
    }
    return result.passed;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = _getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  File _getGoldenFile(Uri golden) {
    return File(_path.join(_path.fromUri(basedir), _path.fromUri(golden.path)));
  }

  File _getFailureFile(String failure, Uri golden) {
    final String fileName = golden.pathSegments[0];
    final String testName = fileName.split(path.extension(fileName))[0]
        + '_'
        + failure
        + '.png';
    return File(_path.join('failures', testName));
  }
}

/// Returns whether [test] and [master] are pixel by pixel identical.
bool compareLists(List<int> test, List<int> master) {
  return _compareLists(test, master).passed;
}

/// Returns a [ComparisonResult] to describe the pixel differential of the
/// [test] and [master] image bytes provided.
ComparisonResult _compareLists(List<int> test, List<int> master) {
  if (identical(test, master))
    return ComparisonResult(passed: true);

  if (test == null || master == null || test.isEmpty || master.isEmpty) {
    return ComparisonResult(
      passed: false,
      error: 'Pixel test failed, null image provided.',
    );
  }

  final Image testImage = decodePng(test);
  final Image masterImage = decodePng(master);

  assert(testImage != null);
  assert(masterImage != null);

  final int width = testImage.width;
  final int height = testImage.height;

  if (width != masterImage.width || height != masterImage.height) {
    return ComparisonResult(
      passed: false,
      error: 'Pixel test failed, image sizes do not match.\n'
        'Master Image: ${masterImage.width} X ${masterImage.height}\n'
        'Test Image: ${testImage.width} X ${testImage.height}',
    );
  }

  int pixelDiffCount = 0;
  final int totalPixels = width * height;
  final Image invertedMaster = invert(Image.from(masterImage));
  final Image invertedTest = invert(Image.from(testImage));

  final Map<String, Image> diffs = <String, Image>{
    'masterImage' : masterImage,
    'testImage' : testImage,
    'maskedDiff' : Image.from(testImage),
    'isolatedDiff' : Image(width, height),
  };

  for (int x = 0; x < width; x++) {
    for (int y =0; y < height; y++) {
      final int testPixel = testImage.getPixel(x, y);
      final int masterPixel = masterImage.getPixel(x, y);

      final int diffPixel = (getRed(testPixel) - getRed(masterPixel)).abs()
        + (getGreen(testPixel) - getGreen(masterPixel)).abs()
        + (getBlue(testPixel) - getBlue(masterPixel)).abs()
        + (getAlpha(testPixel) - getAlpha(masterPixel)).abs();

      if (diffPixel != 0 ) {
        final int invertedMasterPixel = invertedMaster.getPixel(x, y);
        final int invertedTestPixel = invertedTest.getPixel(x, y);
        final int maskPixel = math.max(invertedMasterPixel, invertedTestPixel);
        diffs['maskedDiff'].setPixel(x, y, maskPixel);
        diffs['isolatedDiff'].setPixel(x, y, maskPixel);
        pixelDiffCount++;
      }
    }
  }

  if (pixelDiffCount > 0) {
    return ComparisonResult(
      passed: false,
      error: 'Pixel test failed, ${((pixelDiffCount/totalPixels) * 100).toStringAsFixed(2)}% diff detected.',
      diffs: diffs,
    );
  }
  return ComparisonResult(passed: true);
}

/// The result of a pixel comparison test.
///
/// The [ComparisonResult] will always indicate if a test has [passed]. The
/// optional [error] and [diffs] parameters provide further information about
/// the result of a failing test.
class ComparisonResult {
  /// Creates a new [ComparisonResult] for the current test.
  ComparisonResult({
    @required this.passed,
    this.error,
    this.diffs,
  }) : assert(passed != null);

  /// Indicates whether or not a pixel comparison test has failed.
  ///
  /// This value cannot be null.
  final bool passed;

  /// Error message used to describe the cause of the pixel comparison failure.
  final String error;

  /// Map containing differential images to illustrate found variants in pixel
  /// values in the execution of the pixel test.
  final Map<String, Image> diffs;
}

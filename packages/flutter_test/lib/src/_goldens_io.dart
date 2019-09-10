// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:path/path.dart' as path;
import 'package:test_api/test_api.dart' as test_package show TestFailure;

import 'goldens.dart';

/// The default [GoldenFileComparator] implementation for `flutter test`.
///
/// The term __golden file__ refers to a master image that is considered the true
/// rendering of a given widget, state, application, or other visual
/// representation you have chosen to capture. This comparator loads golden
/// files from the local file system, treating the golden key as a relative
/// path from the test file's directory.
///
/// This comparator performs a pixel-for-pixel comparison of the decoded PNGs,
/// returning true only if there's an exact match. In cases where the captured
/// test image does not match the golden file, this comparator will provide
/// output to illustrate the difference, described in further detail below.
///
/// When using `flutter test --update-goldens`, [LocalFileComparator]
/// updates the golden files on disk to match the rendering.
///
/// ## Local Output from Golden File Testing
///
/// The [LocalFileComparator] will output test feedback when a golden file test
/// fails. This output takes the form of differential images contained within a
/// `failures` directory that will be generated in the same location specified
/// by the golden key. The differential images include the master and test
/// images that were compared, as well as an isolated diff of detected pixels,
/// and a masked diff that overlays these detected pixels over the master image.
///
/// The following images are examples of a test failure output:
///
/// |  File Name                 |  Image Output |
/// |----------------------------|---------------|
/// |  testName_masterImage.png  | ![A golden master image](https://flutter.github.io/assets-for-api-docs/assets/flutter-test/goldens/widget_masterImage.png)  |
/// |  testName_testImage.png    | ![Test image](https://flutter.github.io/assets-for-api-docs/assets/flutter-test/goldens/widget_testImage.png)  |
/// |  testName_isolatedDiff.png | ![An isolated pixel difference.](https://flutter.github.io/assets-for-api-docs/assets/flutter-test/goldens/widget_isolatedDiff.png) |
/// |  testName_maskedDiff.png   | ![A masked pixel difference](https://flutter.github.io/assets-for-api-docs/assets/flutter-test/goldens/widget_maskedDiff.png) |
///
/// See also:
///
///   * [GoldenFileComparator], the abstract class that [LocalFileComparator]
///   implements.
///   * [matchesGoldenFile], the function from [flutter_test] that invokes the
///    comparator.
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
    final ComparisonResult result = GoldenFileComparator.compareLists(imageBytes, goldenBytes);

    if (!result.passed) {
      String additionalFeedback = '';
      if (result.diffs != null) {
        additionalFeedback = '\nFailure feedback can be found at ${path.join(basedir.path, 'failures')}';
        final Map<String, Object> diffs = result.diffs;
        diffs.forEach((String name, Object untypedImage) {
          final Image image = untypedImage;
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

/// Returns a [ComparisonResult] to describe the pixel differential of the
/// [test] and [master] image bytes provided.
ComparisonResult compareLists(List<int> test, List<int> master) {
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

// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart';
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
    final ComparisonResult result = GoldenFileComparator.compareLists<Uint8List>(imageBytes, goldenBytes);

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


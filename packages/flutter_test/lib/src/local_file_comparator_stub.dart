// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:matcher/expect.dart' show fail;
import 'package:path/path.dart' as path;

import 'goldens.dart';
import 'test_async_utils.dart';

/// The default [GoldenFileComparator] implementation for `flutter test`.
///
/// The term __golden file__ refers to a master image that is considered the
/// true rendering of a given widget, state, application, or other visual
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
/// {@macro flutter.flutter_test.matchesGoldenFile.custom_fonts}
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
  LocalFileComparator(Uri testFile, {path.Style? pathStyle});

  /// The directory in which the test was loaded.
  ///
  /// Golden file keys will be interpreted as file paths relative to this
  /// directory.
  Uri get basedir => throw UnimplementedError('stub');

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) {
    throw UnimplementedError('stub');
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    throw UnimplementedError('stub');
  }

  /// Returns the bytes of the given [golden] file.
  ///
  /// If the file cannot be found, an error will be thrown.
  @protected
  Future<List<int>> getGoldenBytes(Uri golden) => throw UnimplementedError('stub');

  /// Writes out diffs from the [ComparisonResult] of a golden file test.
  ///
  /// Will throw an error if a null result is provided.
  Future<String> generateFailureOutput(
    ComparisonResult result,
    Uri golden,
    Uri basedir, {
    String key = '',
  }) => throw UnimplementedError('stub');

  /// Returns the appropriate file for a given diff from a [ComparisonResult].
  File getFailureFile(String failure, Uri golden, Uri basedir) {
    throw UnimplementedError('stub');
  }
}

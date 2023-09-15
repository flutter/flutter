// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:matcher/expect.dart' show fail;
import 'package:path/path.dart' as path;

import 'goldens.dart';
import 'test_async_utils.dart';

/// The [GoldenFileComparator] implementation for `flutter test` which retrieves
/// goldens from a remote server.
///
/// The term __golden file__ refers to a master image that is considered the
/// true rendering of a given widget, state, application, or other visual
/// representation you have chosen to capture. This comparator requests golden
/// files from a remote server.
///
/// This comparator performs a pixel-for-pixel comparison of the decoded PNGs,
/// returning true only if there's an exact match. In cases where the captured
/// test image does not match the golden file, this comparator will provide
/// output to illustrate the difference, described in further detail below.
///
/// When using `flutter test --update-goldens`, [RemoteGoldenComparator]
/// updates the golden files on disk to match the rendering.
class RemoteGoldenComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (!result.passed) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = _getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  /// Returns the bytes of the given [golden] file.
  ///
  /// If the file cannot be found, an error will be thrown.
  @protected
  Future<List<int>> getGoldenBytes(Uri golden) async {
    final File goldenFile = _getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      fail(
        'Could not be compared against non-existent file: "$golden"'
      );
    }
    final List<int> goldenBytes = await goldenFile.readAsBytes();
    return goldenBytes;
  }
}

/// A mixin for use in golden file comparators that run locally and provide
/// output.
mixin LocalComparisonOutput {
  /// Writes out diffs from the [ComparisonResult] of a golden file test.
  ///
  /// Will throw an error if a null result is provided.
  Future<String> generateFailureOutput(
    ComparisonResult result,
    Uri golden,
    Uri basedir, {
    String key = '',
  }) async => TestAsyncUtils.guard<String>(() async {
    String additionalFeedback = '';
    if (result.diffs != null) {
      additionalFeedback = '\nFailure feedback can be found at ${path.join(basedir.path, 'failures')}';
      final Map<String, Image> diffs = result.diffs!;
      for (final MapEntry<String, Image> entry in diffs.entries) {
        final File output = getFailureFile(
          key.isEmpty ? entry.key : '${entry.key}_$key',
          golden,
          basedir,
        );
        output.parent.createSync(recursive: true);
        final ByteData? pngBytes = await entry.value.toByteData(format: ImageByteFormat.png);
        output.writeAsBytesSync(pngBytes!.buffer.asUint8List());
      }
    }
    return 'Golden "$golden": ${result.error}$additionalFeedback';
  });

  /// Returns the appropriate file for a given diff from a [ComparisonResult].
  File getFailureFile(String failure, Uri golden, Uri basedir) {
    final String fileName = golden.pathSegments.last;
    final String testName = '${fileName.split(path.extension(fileName))[0]}_$failure.png';
    return File(path.join(
      path.fromUri(basedir),
      path.fromUri(Uri.parse('failures/$testName')),
    ));
  }
}

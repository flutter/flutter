// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as p;

import 'src/digests_json_format.dart';

/// Uploads the images of digests  in [workDirectory] to Skia Gold.
///
/// The directory is expected to match the following structure:
/// ```txt
/// workDirectory/
///   - digest.json
///   - test_name_1.png
///   - test_name_2.png
///   - ...
/// ```
///
/// The format of `digest.json` is expected to match the following:
/// ```jsonc
/// {
///   "dimensions": {
///     // Key-value pairs of dimensions to provide to Skia Gold.
///     // For example:
///     "platform": "linux",
///   },
///   "entries": [
///     // Each entry is a test-run with the following format:
///     {
///       // Path must be a direct sibling of digest.json.
///       "filename": "test_name_1.png",
///
///       // Called `screenshotSize` in Skia Gold (width * height).
///       "width": 100,
///       "height": 100,
///
///       // Called `differentPixelsRate` in Skia Gold.
///       "maxDiffPixelsPercent": 0.01,
///
///       // Called `pixelColorDelta` in Skia Gold.
///       "maxColorDelta": 0
///     }
///   ]
/// }
/// ```
Future<void> harvest({
  required io.Directory workDirectory,
  required AddImageToSkiaGold addImg,
  required StringSink stderr,
}) async {
  final io.File file = io.File(p.join(workDirectory.path, 'digest.json'));
  if (!file.existsSync()) {
    // Check if the directory exists or if the file is just missing.
    if (!workDirectory.existsSync()) {
      throw ArgumentError('Directory not found: ${workDirectory.path}.');
    }
    // Lookup sibling files to help the user understand what's missing.
    final List<io.FileSystemEntity> files = workDirectory.listSync();
    throw StateError(
      'File "digest.json" not found in ${workDirectory.path}.\n\n'
      'Found files: ${files.map((io.FileSystemEntity e) => p.basename(e.path)).join(', ')}',
    );
  }
  final Digests digests = Digests.parse(file.readAsStringSync());
  final List<Future<void>> pendingComparisons = <Future<void>>[];
  for (final DigestEntry entry in digests.entries) {
    final io.File goldenFile = io.File(p.join(workDirectory.path, entry.filename));
    final Future<void> future = addImg(
      entry.filename,
      goldenFile,
      screenshotSize: entry.width * entry.height,
      differentPixelsRate: entry.maxDiffPixelsPercent,
      pixelColorDelta: entry.maxColorDelta,
    ).catchError((Object e) {
      stderr.writeln('Failed to add image to Skia Gold: $e');
      throw FailedComparisonException(entry.filename);
    });
    pendingComparisons.add(future);
  }

  await Future.wait(pendingComparisons);
}

/// An exception thrown when a comparison fails.
final class FailedComparisonException implements Exception {
  /// Creates a new instance of [FailedComparisonException].
  const FailedComparisonException(this.testName);

  /// The test name that failed.
  final String testName;

  @override
  String toString() => 'Failed comparison: $testName';
}

/// A function that uploads an image to Skia Gold.
typedef AddImageToSkiaGold = Future<void> Function(
  String testName,
  io.File goldenFile, {
  double differentPixelsRate,
  int pixelColorDelta,
  required int screenshotSize,
});

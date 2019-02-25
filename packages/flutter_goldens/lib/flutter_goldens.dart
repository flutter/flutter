// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import 'package:flutter_goldens_client/client.dart';
export 'package:flutter_goldens_client/client.dart';

/// Main method that can be used in a `flutter_test_config.dart` file to set
/// [goldenFileComparator] to an instance of [FlutterGoldenFileComparator] that
/// works for the current test.
Future<void> main(FutureOr<void> testMain()) async {
  goldenFileComparator = await FlutterGoldenFileComparator.fromDefaultComparator();
  await testMain();
}

/// A golden file comparator specific to the `flutter/flutter` repository.
///
/// Within the https://github.com/flutter/flutter repository, it's important
/// not to check-in binaries in order to keep the size of the repository to a
/// minimum. To satisfy this requirement, this comparator retrieves the golden
/// files from a sibling repository, `flutter/goldens`.
///
/// This comparator will locally clone the `flutter/goldens` repository into
/// the `$FLUTTER_ROOT/bin/cache/pkg/goldens` folder, then perform the comparison against
/// the files therein.
class FlutterGoldenFileComparator implements GoldenFileComparator {
  /// Creates a [FlutterGoldenFileComparator] that will resolve golden file
  /// URIs relative to the specified [basedir].
  ///
  /// The [fs] parameter exists for testing purposes only.
  @visibleForTesting
  FlutterGoldenFileComparator(
    this.basedir, {
    this.fs = const LocalFileSystem(),
  });

  /// The directory to which golden file URIs will be resolved in [compare] and [update].
  final Uri basedir;

  /// The file system used to perform file access.
  @visibleForTesting
  final FileSystem fs;

  /// Creates a new [FlutterGoldenFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  ///
  /// By the time the future completes, the clone of the `flutter/goldens`
  /// repository is guaranteed to be ready use.
  ///
  /// The [goldens] and [defaultComparator] parameters are visible for testing
  /// purposes only.
  static Future<FlutterGoldenFileComparator> fromDefaultComparator({
    GoldensClient goldens,
    LocalFileComparator defaultComparator,
  }) async {
    defaultComparator ??= goldenFileComparator;

    // Prepare the goldens repo.
    goldens ??= GoldensClient();
    await goldens.prepare();

    // Calculate the appropriate basedir for the current test context.
    final FileSystem fs = goldens.fs;
    final Directory testDirectory = fs.directory(defaultComparator.basedir);
    final String testDirectoryRelativePath = fs.path.relative(testDirectory.path, from: goldens.flutterRoot.path);
    return FlutterGoldenFileComparator(goldens.repositoryRoot.childDirectory(testDirectoryRelativePath).uri);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File goldenFile = _getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    final List<int> goldenBytes = await goldenFile.readAsBytes();
    // TODO(tvolkert): Improve the intelligence of this comparison.
    if (goldenBytes.length != imageBytes.length) {
      return false;
    }
    for (int i = 0; i < goldenBytes.length; i++) {
      if (goldenBytes[i] != imageBytes[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = _getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  File _getGoldenFile(Uri uri) {
    return fs.directory(basedir).childFile(fs.file(uri).path);
  }
}

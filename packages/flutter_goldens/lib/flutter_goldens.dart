// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:test_api/test_api.dart' as test_package show TestFailure;

import 'package:flutter_goldens_client/client.dart';
export 'package:flutter_goldens_client/client.dart';

const String _kFlutterRootKey = 'FLUTTER_ROOT';

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
/// minimum. To satisfy this requirement, this comparator uses the
/// [SkiaGoldClient] to upload widgets for framework-related golden tests and
/// process results.
///
/// This comparator will instantiate the [SkiaGoldClient] and process the
/// results of the test.
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

  /// Instance of the [SkiaGoldClient] for executing tests.
  final SkiaGoldClient _skiaClient = SkiaGoldClient();

  /// Creates a new [FlutterGoldenFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  ///
  /// The [defaultComparator] parameter is visible for testing
  /// purposes only.
  static Future<FlutterGoldenFileComparator> fromDefaultComparator({
    LocalFileComparator defaultComparator,
  }) async {
    defaultComparator ??= goldenFileComparator;

    // Calculate the appropriate basedir for the current test context.
    const FileSystem fs = LocalFileSystem();
    final Directory testDirectory = fs.directory(defaultComparator.basedir);
    final Directory flutterRoot = fs.directory(Platform.environment[_kFlutterRootKey]);
    final Directory goldenRoot = flutterRoot.childDirectory(fs.path.join(
      'bin',
      'cache',
      'pkg',
      'goldens',
    ));
    final String testDirectoryRelativePath = fs.path.relative(
      testDirectory.path,
      from: flutterRoot.path,
    );
    return FlutterGoldenFileComparator(goldenRoot.childDirectory(testDirectoryRelativePath).uri);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File goldenFile = _getGoldenFile(golden);
    if(!goldenFile.existsSync()) {
      throw test_package.TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    final bool authorized = await _skiaClient.auth(fs.directory(basedir));
    if (!authorized) {
      // TODO(Piinks): Clean up for final implementation on CI, https://github.com/flutter/flutter/pull/31630
      return true;
      //throw test_package.TestFailure('Could not authorize golctl.');
    }
    await _skiaClient.imgtestInit();

    return await _skiaClient.imgtestAdd(golden.path, goldenFile);
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

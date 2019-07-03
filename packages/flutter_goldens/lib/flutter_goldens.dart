// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';

import 'package:flutter_goldens_client/client.dart';
import 'package:flutter_goldens_client/skia_client.dart';

export 'package:flutter_goldens_client/client.dart';
export 'package:flutter_goldens_client/skia_client.dart';

/// Main method that can be used in a `flutter_test_config.dart` file to set
/// [goldenFileComparator] to an instance of [FlutterGoldenFileComparator] that
/// works for the current test.
Future<void> main(FutureOr<void> testMain()) async {
  goldenFileComparator = //testingWithSkiaGold(const LocalPlatform())
    //? await FlutterSkiaGoldFileComparator.fromDefaultComparator()
    await FlutterGoldensRepositoryFileComparator.fromDefaultComparator();
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
/// the `$FLUTTER_ROOT/bin/cache/pkg/goldens` folder using the [GoldensClient],
/// then perform the comparison against the files therein.
///
/// For testing across all platforms, the [SkiaGoldClient] is used to upload
/// images for framework-related golden tests and process results. Currently
/// these tests are designed to be run post-submit on Cirrus CI, informed by the
/// environment. When running test pre-submit or locally, they are executed via
/// the [GoldensClient].
///
/// This comparator will instantiate [GoldensClient] and [SkiaGoldClient].
abstract class FlutterGoldenFileComparator implements GoldenFileComparator {

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes);

  @override
  Uri getTestUri(Uri key, int version);


  File getGoldenFile(Uri uri);
}

class FlutterGoldensRepositoryFileComparator implements FlutterGoldenFileComparator {
  /// Creates a [FlutterGoldenFileComparator] that will resolve golden file
  /// URIs relative to the specified [basedir].
  ///
  /// The [fs] parameter exists for testing purposes only.
  @visibleForTesting
  FlutterGoldensRepositoryFileComparator(
    this.basedir, {
    this.fs = const LocalFileSystem(),
    this.platform = const LocalPlatform(),
  }) : assert(basedir != null);

  /// The directory to which golden file URIs will be resolved in [compare] and [update].
  final Uri basedir;

  /// The file system used to perform file access.
  @visibleForTesting
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  ///
  /// This is only for use in tests, where the system platform (the default) can
  /// be replaced by mock platform instance.
  @visibleForTesting
  final Platform platform;

  /// Creates a new [FlutterGoldensRespositoryFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  ///
  /// By the time the future completes, the clone of the `flutter/goldens`
  /// repository is guaranteed to be ready use.
  ///
  /// The [goldens] and [defaultComparator] parameters are visible for testing
  /// purposes only.
  static Future<FlutterGoldensRepositoryFileComparator> fromDefaultComparator({
    GoldensRepositoryClient goldens,
    LocalFileComparator defaultComparator,
  }) async {
    defaultComparator ??= goldenFileComparator;

    // Prepare the goldens repo.
    goldens ??= GoldensRepositoryClient();
    await goldens.prepare();

    // Calculate the appropriate basedir for the current test context.
    final FileSystem fs = goldens.fs;
    final Directory testDirectory = fs.directory(defaultComparator.basedir);
    final String testDirectoryRelativePath = fs.path.relative(testDirectory.path, from: goldens.flutterRoot.path);
    return FlutterGoldensRepositoryFileComparator(goldens.comparisonRoot.childDirectory(testDirectoryRelativePath).uri);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File goldenFile = getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw TestFailure('Could not be compared against non-existent file: "$golden"');
    }

    if (platform.isLinux) {
      final List<int> goldenBytes = await goldenFile.readAsBytes();
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
    print('Skipping "$golden" : Skia Gold unavailable && !isLinux');
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  @override
  File getGoldenFile(Uri uri) {
    return fs.directory(basedir).childFile(fs.file(uri).path);
  }

  @override
  Uri getTestUri(Uri key, int version) {
    return _addVersion(key, version);
  }

  Uri _addVersion(Uri key, int version) {
    final String extension = path.extension(key.toString());
    return version == null ? key : Uri.parse(
      key
        .toString()
        .split(extension)
        .join() + '.' + version.toString() + extension
    );
  }
}

class FlutterSkiaGoldFileComparator implements FlutterGoldenFileComparator {
  /// Creates a [FlutterGoldenFileComparator] that will resolve golden file
  /// URIs relative to the specified [basedir].
  ///
  /// The [fs] parameter exists for testing purposes only.
  @visibleForTesting
  FlutterSkiaGoldFileComparator(
    this.basedir, {
      this.fs = const LocalFileSystem(),
      this.platform = const LocalPlatform(),
    }) : assert(basedir != null);

  /// The directory to which golden file URIs will be resolved in [compare] and [update].
  final Uri basedir;

  /// The file system used to perform file access.
  @visibleForTesting
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  ///
  /// This is only for use in tests, where the system platform (the default) can
  /// be replaced by mock platform instance.
  @visibleForTesting
  final Platform platform;

  final SkiaGoldClient _skiaClient = SkiaGoldClient();

  /// Creates a new [FlutterSkiaGoldFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  ///
  /// By the time the future completes, the clone of the `flutter/goldens`
  /// repository is guaranteed to be ready use.
  ///
  /// The [goldens] and [defaultComparator] parameters are visible for testing
  /// purposes only.
  static Future<FlutterSkiaGoldFileComparator> fromDefaultComparator({
    SkiaGoldClient goldens,
    LocalFileComparator defaultComparator,
  }) async {
    defaultComparator ??= goldenFileComparator;
    goldens ??= SkiaGoldClient();

    // Calculate the appropriate basedir for the current test context.
    final FileSystem fs = goldens.fs;
    final Directory testDirectory = fs.directory(defaultComparator.basedir);
    final String testDirectoryRelativePath = fs.path.relative(testDirectory.path, from: goldens.flutterRoot.path);
    //final Uri baseDirectory = goldens.comparisonRoot.childDirectory(testDirectoryRelativePath).uri;
    //goldens.auth(fs.directory(baseDirectory));
    return FlutterSkiaGoldFileComparator(goldens.comparisonRoot.childDirectory(testDirectoryRelativePath).uri);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = _addPrefix(golden);
    await update(golden, imageBytes);

    final File goldenFile = getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    await _skiaClient.auth(fs.directory(basedir));
    await _skiaClient.imgtestInit();
    return await _skiaClient.imgtestAdd(golden.path, goldenFile);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  @override
  File getGoldenFile(Uri uri) {
    return fs.directory(basedir).childFile(fs.file(uri).path);
  }

  @override
  Uri getTestUri(Uri key, int version) {
    return key;
  }

  Uri _addPrefix(Uri golden) {
    final String prefix = basedir.pathSegments[basedir.pathSegments.length - 2];
    return Uri.parse(prefix + '.' + golden.toString());
  }
}

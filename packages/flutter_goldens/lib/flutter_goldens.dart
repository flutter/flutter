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
/// works for the current test. _Which_ FlutterGoldenFileComparator is
/// instantiated is based on the current testing environment.
Future<void> main(FutureOr<void> testMain()) async {
  goldenFileComparator = _testingWithSkiaGold(const LocalPlatform())
    ? await FlutterSkiaGoldFileComparator.fromDefaultComparator()
    : await FlutterGoldensRepositoryFileComparator.fromDefaultComparator();
  await testMain();
}

/// Abstract base class golden file comparator specific to the `flutter/flutter`
/// repository.
abstract class FlutterGoldenFileComparator implements GoldenFileComparator {

  /// Completes pixel differential tests utilizing [imageBytes] identified by
  /// [golden].
  ///
  /// The returned future completes with a  boolean value that indicates whether
  /// the imageBytes given matched. The method by which comparison is completed
  /// is left up to the implementation class. For instance, some
  /// implementations may load files from the local file system, whereas others
  /// may upload files over the network.
  ///
  /// In the case of comparison mismatch, the comparator may choose to throw a
  /// [TestFailure] if it wants to control the failure message.
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden);

  /// Updates the golden file identified by [golden] with [imageBytes].
  ///
  /// This will be invoked in lieu of [compare] when [autoUpdateGoldenFiles]
  /// is `true` (which gets set automatically by the test framework when the
  /// user runs `flutter test --update-goldens`).
  ///
  /// The method by which [golden] is located and by which its bytes are written
  /// is left up to the implementation class.
  @override
  Future<void> update(Uri golden, Uint8List imageBytes);

  /// Updates the uri [key] of the golden file to incorporate any [version]
  /// number.
  ///
  /// The [version] is an optional int that can be used to differentiate
  /// historical golden files.
  ///
  /// Version numbers are used in golden file tests for package:flutter. You can
  /// learn more about these tests [here](https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter).
  @override
  Uri getTestUri(Uri key, int version);

  /// Returns the golden file identified by the given [Uri].
  File getGoldenFile(Uri uri);
}

/// Implementation of the abstract base class [FlutterGoldenFileComparator] for
/// testing against the `flutter/goldens` repository.
///
/// Within the https://github.com/flutter/flutter repository, it's important
/// not to check-in binaries in order to keep the size of the repository to a
/// minimum. To satisfy this requirement, this comparator retrieves the golden
/// files from a sibling repository, `flutter/goldens`.
///
/// This comparator will locally clone the `flutter/goldens` repository into
/// the `$FLUTTER_ROOT/bin/cache/pkg/goldens` folder using the
/// [GoldensRepositoryClient], then perform the comparison against the files
/// therein.
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

  /// The directory to which golden file URIs will be resolved in [compare] and
  /// [update].
  final Uri basedir;

  /// The file system used to perform file access.
  @visibleForTesting
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  ///
  /// This is only for use in tests, where the system platform (the default) can
  /// be replaced by a mock platform instance.
  @visibleForTesting
  final Platform platform;

  /// Creates a new [FlutterGoldensRespositoryFileComparator] that mirrors the
  /// relative path resolution of the default [goldenFileComparator].
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

  /// Compares [imageBytes] against the golden file identified by [golden].
  ///
  /// The returned future completes with a boolean value that indicates whether
  /// [imageBytes] matches the golden file's bytes.
  ///
  /// In the case of the given golden file being unavailable, the comparator
  /// will throw a [TestFailure].
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

  /// Updates the golden file identified by [golden] with [imageBytes].
  ///
  /// This will be invoked in lieu of [compare] when [autoUpdateGoldenFiles]
  /// is `true` (which gets set automatically by the test framework when the
  /// user runs `flutter test --update-goldens`).
  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  /// Returns the golden file identified by the given [Uri].
  @override
  File getGoldenFile(Uri uri) {
    return fs.directory(basedir).childFile(fs.file(uri).path);
  }

  /// Modifies the given [Uri] to incorporate an optional [version] number.
  ///
  /// Golden files for package:flutter use version numbers, and must be used to
  /// reference the appropriate file.
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

/// Implementation of the abstract base class [FlutterGoldenFileComparator] for
/// testing against with Skia Gold.
///
/// For testing across all platforms, the [SkiaGoldClient] is used to upload
/// images for framework-related golden tests and process results. Currently
/// these tests are designed to be run post-submit on Cirrus CI, informed by the
/// environment.
class FlutterSkiaGoldFileComparator implements FlutterGoldenFileComparator {
  /// Creates a [FlutterSkiaGoldFileComparator] that will resolve golden file
  /// URIs relative to the specified [basedir].
  ///
  /// The [fs] parameter exists for testing purposes only.
  @visibleForTesting
  FlutterSkiaGoldFileComparator(
    this.basedir, {
      this.fs = const LocalFileSystem(),
      this.platform = const LocalPlatform(),
    }) : assert(basedir != null);

  /// The directory to which golden file URIs will be resolved in [compare] and
  /// [update].
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
    return FlutterSkiaGoldFileComparator(goldens.comparisonRoot.childDirectory(testDirectoryRelativePath).uri);
  }

  /// Updates the local golden file with the most recent imageBytes before
  /// uploading to Skia Gold for comparison.
  ///
  /// The returned future completes with a boolean value that indicates whether
  /// [imageBytes] passed the Skia Gold pixel test.
  ///
  /// In the case of the given golden file being unavailable, the comparator
  /// will throw a [TestFailure].
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

  /// Updates the golden file identified by [golden] with [imageBytes].
  ///
  /// This will be invoked in lieu of [compare] when [autoUpdateGoldenFiles]
  /// is `true` (which gets set automatically by the test framework when the
  /// user runs `flutter test --update-goldens`).
  ///
  /// The [FlutterSkiaGoldFileComparator] will always update the local golden
  /// file so upload to Skia Gold.
  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  /// Returns the golden file identified by the given [Uri].
  @override
  File getGoldenFile(Uri uri) {
    return fs.directory(basedir).childFile(fs.file(uri).path);
  }

  /// Modifies the given [Uri] to incorporate the current test library as a
  /// prefix in the golden file name.
  @override
  Uri getTestUri(Uri key, int version) {
    return key;
  }

  Uri _addPrefix(Uri golden) {
    final String prefix = basedir.pathSegments[basedir.pathSegments.length - 2];
    return Uri.parse(prefix + '.' + golden.toString());
  }
}

/// Utilized in the Main method to set [goldenFileComparator] to an instance of
/// [FlutterGoldensRepositoryFileComparator] or [FlutterSkiaGoldFileComparator]
/// based on the current testing environment.
bool _testingWithSkiaGold(Platform platform) {
  final String cirrusCI = platform.environment['CIRRUS_CI'] ?? '';
  final String cirrusPR = platform.environment['CIRRUS_PR'] ?? '';
  final String cirrusBranch = platform.environment['CIRRUS_BRANCH'] ?? '';
  return cirrusCI.isNotEmpty && cirrusPR.isEmpty && cirrusBranch == 'master';
}

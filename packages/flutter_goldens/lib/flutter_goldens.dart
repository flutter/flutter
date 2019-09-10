// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
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
  const Platform platform = LocalPlatform();
  if (FlutterSkiaGoldFileComparator.isAvailableOnPlatform(platform)) {
    goldenFileComparator = await FlutterSkiaGoldFileComparator.fromDefaultComparator();
  } else if (FlutterGoldensRepositoryFileComparator.isAvailableOnPlatform(platform)) {
    goldenFileComparator = await FlutterGoldensRepositoryFileComparator.fromDefaultComparator();
  } else {
    goldenFileComparator = FlutterSkippingGoldenFileComparator.fromDefaultComparator();
  }
  await testMain();
}

/// Abstract base class golden file comparator specific to the `flutter/flutter`
/// repository.
abstract class FlutterGoldenFileComparator extends GoldenFileComparator {
  /// Creates a [FlutterGoldenFileComparator] that will resolve golden file
  /// URIs relative to the specified [basedir].
  ///
  /// The [fs] and [platform] parameters useful in tests, where the default file
  /// system and platform can be replaced by mock instances.
  @visibleForTesting
  FlutterGoldenFileComparator(
    this.basedir, {
    this.fs = const LocalFileSystem(),
    this.platform = const LocalPlatform(),
  }) : assert(basedir != null),
       assert(fs != null),
       assert(platform != null);

  /// The directory to which golden file URIs will be resolved in [compare] and
  /// [update].
  final Uri basedir;

  /// The file system used to perform file access.
  @visibleForTesting
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  @visibleForTesting
  final Platform platform;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  /// Calculate the appropriate basedir for the current test context.
  @protected
  @visibleForTesting
  static Directory getBaseDirectory(GoldensClient goldens, LocalFileComparator defaultComparator) {
    final FileSystem fs = goldens.fs;
    final Directory testDirectory = fs.directory(defaultComparator.basedir);
    final String testDirectoryRelativePath = fs.path.relative(testDirectory.path, from: goldens.flutterRoot.path);
    return goldens.comparisonRoot.childDirectory(testDirectoryRelativePath);
  }

  /// Returns the golden [File] identified by the given [Uri].
  @protected
  File getGoldenFile(Uri uri) {
    assert(basedir.scheme == 'file');
    final File goldenFile = fs.directory(basedir).childFile(fs.file(uri).path);
    assert(goldenFile.uri.scheme == 'file');
    return goldenFile;
  }
}

/// A [FlutterGoldenFileComparator] for testing golden images against the
/// `flutter/goldens` repository.
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
///
/// See also:
///
///  * [GoldenFileComparator], the abstract class that
///    [FlutterGoldenFileComparator] implements.
///  * [FlutterSkiaGoldFileComparator], another [FlutterGoldenFileComparator]
///    that tests golden images through Skia Gold.
class FlutterGoldensRepositoryFileComparator extends FlutterGoldenFileComparator {
  /// Creates a [FlutterGoldensRepositoryFileComparator] that will test golden
  /// file images against the `flutter/goldens` repository.
  ///
  /// The [fs] and [platform] parameters useful in tests, where the default file
  /// system and platform can be replaced by mock instances.
  FlutterGoldensRepositoryFileComparator(
    Uri basedir, {
    FileSystem fs = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
  }) : super(
    basedir,
    fs: fs,
    platform: platform,
  );

  /// Creates a new [FlutterGoldensRespositoryFileComparator] that mirrors the
  /// relative path resolution of the default [goldenFileComparator].
  ///
  /// By the time the future completes, the clone of the `flutter/goldens`
  /// repository is guaranteed to be ready to use.
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

    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(goldens, defaultComparator);
    return FlutterGoldensRepositoryFileComparator(baseDirectory.uri);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File goldenFile = getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    final List<int> goldenBytes = await goldenFile.readAsBytes();
    final ComparisonResult result = GoldenFileComparator.compareLists(imageBytes, goldenBytes);
    return result.passed;
  }

  /// Decides based on the current platform whether goldens tests should be
  /// performed against the flutter/goldens repository.
  static bool isAvailableOnPlatform(Platform platform) => platform.isLinux;
}

/// A [FlutterGoldenFileComparator] for testing golden images with Skia Gold.
///
/// For testing across all platforms, the [SkiaGoldClient] is used to upload
/// images for framework-related golden tests and process results. Currently
/// these tests are designed to be run post-submit on Cirrus CI, informed by the
/// environment.
///
/// See also:
///
///  * [GoldenFileComparator], the abstract class that
///    [FlutterGoldenFileComparator] implements.
///  * [FlutterGoldensRepositoryFileComparator], another
///    [FlutterGoldenFileComparator] that tests golden images using the
///    flutter/goldens repository.
class FlutterSkiaGoldFileComparator extends FlutterGoldenFileComparator {
  /// Creates a [FlutterSkiaGoldFileComparator] that will test golden file
  /// images against Skia Gold.
  ///
  /// The [fs] and [platform] parameters useful in tests, where the default file
  /// system and platform can be replaced by mock instances.
  FlutterSkiaGoldFileComparator(
    final Uri basedir,
    this.skiaClient, {
    FileSystem fs = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
  }) : super(
    basedir,
    fs: fs,
    platform: platform,
  );

  final SkiaGoldClient skiaClient;

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

    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(goldens, defaultComparator);
    if (!baseDirectory.existsSync())
      baseDirectory.createSync(recursive: true);
    await goldens.auth(baseDirectory);
    await goldens.imgtestInit();
    return FlutterSkiaGoldFileComparator(baseDirectory.uri, goldens);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = _addPrefix(golden);
    await update(golden, imageBytes);

    final File goldenFile = getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    return await skiaClient.imgtestAdd(golden.path, goldenFile);
  }

  @override
  Uri getTestUri(Uri key, int version) => key;

  /// Decides based on the current environment whether goldens tests should be
  /// performed against Skia Gold.
  static bool isAvailableOnPlatform(Platform platform) {
    final String cirrusCI = platform.environment['CIRRUS_CI'] ?? '';
    final String cirrusPR = platform.environment['CIRRUS_PR'] ?? '';
    final String cirrusBranch = platform.environment['CIRRUS_BRANCH'] ?? '';
    final String goldServiceAccount = platform.environment['GOLD_SERVICE_ACCOUNT'] ?? '';
    return cirrusCI.isNotEmpty
      && cirrusPR.isEmpty
      && cirrusBranch == 'master'
      && goldServiceAccount.isNotEmpty;
  }

  /// Prepends the golden Uri with the library name that encloses the current
  /// test.
  Uri _addPrefix(Uri golden) {
    final String prefix = basedir.pathSegments[basedir.pathSegments.length - 2];
    return Uri.parse(prefix + '.' + golden.toString());
  }
}

/// A [FlutterGoldenFileComparator] for skipping golden image tests when Skia
/// Gold is unavailable or the current platform that is executing tests is not
/// Linux.
///
/// See also:
///
///  * [FlutterGoldensRepositoryFileComparator], another
///    [FlutterGoldenFileComparator] that tests golden images using the
///    flutter/goldens repository.
///  * [FlutterSkiaGoldFileComparator], another [FlutterGoldenFileComparator]
///    that tests golden images through Skia Gold.
class FlutterSkippingGoldenFileComparator extends FlutterGoldenFileComparator {
  /// Creates a [FlutterSkippingGoldenFileComparator] that will skip tests that
  /// are not in the right environment for golden file testing.
  FlutterSkippingGoldenFileComparator(Uri basedir) : super(basedir);

  /// Creates a new [FlutterSkippingGoldenFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  static FlutterSkippingGoldenFileComparator fromDefaultComparator({
    LocalFileComparator defaultComparator,
  }) {
    defaultComparator ??= goldenFileComparator;
    return FlutterSkippingGoldenFileComparator(defaultComparator.basedir);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    print('Skipping "$golden" test : Skia Gold is not available in this testing '
      'environment and flutter/goldens repository comparison is only available '
      'on Linux machines.'
    );
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) => null;
}

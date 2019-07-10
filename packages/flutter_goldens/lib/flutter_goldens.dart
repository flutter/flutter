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
  const Platform platform = LocalPlatform();
  goldenFileComparator = _testingWithSkiaGold(platform)
    ? await FlutterSkiaGoldFileComparator.fromDefaultComparator()
    : platform.isLinux
      ? await FlutterGoldensRepositoryFileComparator.fromDefaultComparator()
      : await FlutterDummyGoldenFileComparator.fromDefaultComparator();
  await testMain();
}

/// Abstract base class golden file comparator specific to the `flutter/flutter`
/// repository.
abstract class FlutterGoldenFileComparator implements GoldenFileComparator {
  /// Creates a [FlutterGoldenFileComparator] that will resolve golden file
  /// URIs relative to the specified [basedir].
  ///
  /// The [fs] and [platform] parameters are only for use in tests, where the
  /// default file system and platform can be replaced by mock instances.
  @visibleForTesting
  FlutterGoldenFileComparator(
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
  @visibleForTesting
  final Platform platform;

  @override
  @protected
  @visibleForTesting
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  /// Modifies the given [Uri] to incorporate the current test library as a
  /// prefix in the golden file name.
  @override
  @protected
  @visibleForTesting
  Uri getTestUri(Uri key, int version) {
    return key;
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
  File getGoldenFile(Uri uri){
    return fs.directory(basedir).childFile(fs.file(uri).path);
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
  FlutterGoldensRepositoryFileComparator(Uri basedir) : super(basedir);

  /// Constructor used specifically for testing in order to provide mock members.
  FlutterGoldensRepositoryFileComparator.test(
    Uri basedir,
    FileSystem testFileSystem,
    Platform testPlatform,
    ) : super(
    basedir,
    fs: testFileSystem,
    platform: testPlatform,
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
  Uri getTestUri(Uri key, int version) {
    final String extension = path.extension(key.toString());
    return version == null ? key : Uri.parse(
      key
        .toString()
        .split(extension)
        .join() + '.' + version.toString() + extension
    );
  }
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
///    [FlutterGoldenFileComparator] that tests golden images through Skia Gold.
class FlutterSkiaGoldFileComparator extends FlutterGoldenFileComparator {
  FlutterSkiaGoldFileComparator(Uri basedir) : super(basedir) {
    _skiaClient = SkiaGoldClient(fs.directory(basedir));
  }

  /// Constructor used specifically for testing in order to provide mock members.
  FlutterSkiaGoldFileComparator.test(
    Uri basedir,
    FileSystem testFileSystem,
    Platform testPlatform,
  ) : super(
    basedir,
    fs: testFileSystem,
    platform: testPlatform,
  );


  SkiaGoldClient _skiaClient;

  /// Creates a new [FlutterSkiaGoldFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  ///
  /// The [goldens] and [defaultComparator] parameters are visible for testing
  /// purposes only.
  static Future<FlutterSkiaGoldFileComparator> fromDefaultComparator({
    GoldensClient goldens,
    LocalFileComparator defaultComparator,
  }) async {
    defaultComparator ??= goldenFileComparator;
    goldens ??= GoldensClient();

    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(goldens, defaultComparator);
    final SkiaGoldClient skiaClient = SkiaGoldClient(baseDirectory);
    await skiaClient.auth();
    await skiaClient.imgtestInit();
    return FlutterSkiaGoldFileComparator(baseDirectory.uri);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = _addPrefix(golden);
    await update(golden, imageBytes);

    final File goldenFile = getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    return await _skiaClient.imgtestAdd(golden.path, goldenFile);
  }

  /// Prepends the golden Uri with the library name that encloses the current
  /// test.
  Uri _addPrefix(Uri golden) {
    final String prefix = basedir.pathSegments[basedir.pathSegments.length - 2];
    return Uri.parse(prefix + '.' + golden.toString());
  }
}

class FlutterDummyGoldenFileComparator extends FlutterGoldenFileComparator {
  FlutterDummyGoldenFileComparator(Uri basedir) : super(basedir);

  /// Creates a new [FlutterDummyGoldenFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  static Future<FlutterSkiaGoldFileComparator> fromDefaultComparator({
    LocalFileComparator defaultComparator,
  }) async {
    defaultComparator ??= goldenFileComparator;
    return FlutterSkiaGoldFileComparator(defaultComparator.basedir);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    print('Skipping "$golden" test : Skia Gold is not available in this testing'
      ' environment and flutter/goldens repository comparison is only available'
      ' on Linux machines.');
    return true;
  }
}

/// Decides based on the current environment whether goldens tests should be
/// performed against Skia Gold.
bool _testingWithSkiaGold(Platform platform) {
  final String cirrusCI = platform.environment['CIRRUS_CI'] ?? '';
  final String cirrusPR = platform.environment['CIRRUS_PR'] ?? '';
  final String cirrusBranch = platform.environment['CIRRUS_BRANCH'] ?? '';
  return cirrusCI.isNotEmpty && cirrusPR.isEmpty && cirrusBranch == 'master';
}

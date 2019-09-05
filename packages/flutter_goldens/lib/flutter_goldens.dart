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

import 'package:flutter_goldens_client/skia_client.dart';
export 'package:flutter_goldens_client/skia_client.dart';

const String _kFlutterRootKey = 'FLUTTER_ROOT';

/// Main method that can be used in a `flutter_test_config.dart` file to set
/// [goldenFileComparator] to an instance of [FlutterGoldenFileComparator] that
/// works for the current test. _Which_ FlutterGoldenFileComparator is
/// instantiated is based on the current testing environment.
Future<void> main(FutureOr<void> testMain()) async {
  const Platform platform = LocalPlatform();
  if (FlutterSkiaGoldFileComparator.isAvailableForEnvironment(platform)) {
    goldenFileComparator = await FlutterSkiaGoldFileComparator.fromDefaultComparator(platform);
  } else if (FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform)) {
    goldenFileComparator = await FlutterPreSubmitFileComparator.fromDefaultComparator(platform);
  } else {
    goldenFileComparator = await FlutterLocalFileComparator.fromDefaultComparator(platform);
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
    this.basedir,
    this.skiaClient, {
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

  /// Doc
  final SkiaGoldClient skiaClient;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final File goldenFile = getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  @override
  Uri getTestUri(Uri key, int version) => key;

  /// Calculate the appropriate basedir for the current test context.
  @protected
  @visibleForTesting
  static Directory getBaseDirectory(LocalFileComparator defaultComparator, Platform platform) {
    const FileSystem fs = LocalFileSystem();
    final Directory flutterRoot = fs.directory(platform.environment[_kFlutterRootKey]);
    final Directory comparisonRoot = flutterRoot.childDirectory(
      fs.path.join(
        'bin',
        'cache',
        'pkg',
        'skia_goldens',
      )
    );

    final Directory testDirectory = fs.directory(defaultComparator.basedir);
    final String testDirectoryRelativePath = fs.path.relative(
      testDirectory.path,
      from: flutterRoot.path,
    );
    return comparisonRoot.childDirectory(testDirectoryRelativePath);
  }

  /// Returns the golden [File] identified by the given [Uri].
  @protected
  File getGoldenFile(Uri uri) {
    assert(basedir.scheme == 'file');
    final File goldenFile = fs.directory(basedir).childFile(fs.file(uri).path);
    assert(goldenFile.uri.scheme == 'file');
    return goldenFile;
  }

  /// Prepends the golden Uri with the library name that encloses the current
  /// test.
  Uri addPrefix(Uri golden) {
    final String prefix = basedir.pathSegments[basedir.pathSegments.length - 2];
    return Uri.parse(prefix + '.' + golden.toString());
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
    final SkiaGoldClient skiaClient, {
    final FileSystem fs = const LocalFileSystem(),
    final Platform platform = const LocalPlatform(),
  }) : super(
    basedir,
    skiaClient,
    fs: fs,
    platform: platform,
  );

  /// Creates a new [FlutterSkiaGoldFileComparator] that mirrors the relative
  /// path resolution of the default [goldenFileComparator].
  ///
  /// The [goldens] and [defaultComparator] parameters are visible for testing
  /// purposes only.
  static Future<FlutterSkiaGoldFileComparator> fromDefaultComparator(
    final Platform platform, {
    SkiaGoldClient goldens,
    LocalFileComparator defaultComparator,
  }) async {

    defaultComparator ??= goldenFileComparator;
    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(defaultComparator, platform);
    if (!baseDirectory.existsSync())
      baseDirectory.createSync(recursive: true);

    goldens ??= SkiaGoldClient(baseDirectory);
    await goldens.auth();
    await goldens.imgtestInit();
    return FlutterSkiaGoldFileComparator(baseDirectory.uri, goldens);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = addPrefix(golden);
    await update(golden, imageBytes);

    final File goldenFile = getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    return await skiaClient.imgtestAdd(golden.path, goldenFile);
  }

  /// Decides based on the current environment whether goldens tests should be
  /// performed against Skia Gold.
  static bool isAvailableForEnvironment(Platform platform) {
    final String cirrusCI = platform.environment['CIRRUS_CI'] ?? '';
    final String cirrusPR = platform.environment['CIRRUS_PR'] ?? '';
    final String cirrusBranch = platform.environment['CIRRUS_BRANCH'] ?? '';
    final String goldServiceAccount = platform.environment['GOLD_SERVICE_ACCOUNT'] ?? '';
    return cirrusCI.isNotEmpty
      && cirrusPR.isEmpty
      && cirrusBranch == 'master'
      && goldServiceAccount.isNotEmpty;
  }
}

/// DOC
class FlutterPreSubmitFileComparator extends FlutterGoldenFileComparator {
  /// Doc
  FlutterPreSubmitFileComparator(
    final Uri basedir,
    final SkiaGoldClient skiaClient, {
    final FileSystem fs = const LocalFileSystem(),
    final Platform platform = const LocalPlatform(),
  }) : super(
    basedir,
    skiaClient,
    fs: fs,
    platform: platform,
  );

  /// Creates a new [FlutterPreSubmitFileComparator] that mirrors the
  /// relative path resolution of the default [goldenFileComparator].
  ///
  /// The [goldens] and [defaultComparator] parameters are visible for testing
  /// purposes only.
  static Future<FlutterGoldenFileComparator> fromDefaultComparator(
    final Platform platform, {
    SkiaGoldClient goldens,
    LocalFileComparator defaultComparator,
  }) async {

    defaultComparator ??= goldenFileComparator;
    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(defaultComparator, platform);
    if (!baseDirectory.existsSync())
      baseDirectory.createSync(recursive: true);

    goldens ??= SkiaGoldClient(baseDirectory);
    return FlutterPreSubmitFileComparator(baseDirectory.uri, goldens);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = addPrefix(golden);
    final List<int> goldenBytes = await skiaClient.getMasterBytes(golden.path);
    final ComparisonResult result = GoldenFileComparator.compareLists<Uint8List>(imageBytes, goldenBytes);
    // TODO(Piinks): If !result.passed return skiaClient.testIsIgnoredForPR
    return result.passed;
  }

  /// Decides based on the current environment whether goldens tests should be
  /// performed as pre-submit tests with Skia Gold.
  static bool isAvailableForEnvironment(Platform platform) {
    final String cirrusCI = platform.environment['CIRRUS_CI'] ?? '';
    final String cirrusPR = platform.environment['CIRRUS_PR'] ?? '';
    return cirrusCI.isNotEmpty && cirrusPR.isNotEmpty;
  }
}

/// Doc
class FlutterLocalFileComparator extends FlutterGoldenFileComparator with LocalComparisonOutput {
  /// Doc
  FlutterLocalFileComparator(
    final Uri basedir,
    final SkiaGoldClient skiaClient, {
    final FileSystem fs = const LocalFileSystem(),
    final Platform platform = const LocalPlatform(),
  }) : super(
    basedir,
    skiaClient,
    fs: fs,
    platform: platform,
  );

  /// Creates a new [FlutterLocalFileComparator] that mirrors the
  /// relative path resolution of the default [goldenFileComparator].
  ///
  /// The [goldens] and [defaultComparator] parameters are visible for testing
  /// purposes only.
  static Future<FlutterGoldenFileComparator> fromDefaultComparator(
    final Platform platform, {
      SkiaGoldClient goldens,
      LocalFileComparator defaultComparator,
    }) async {

    defaultComparator ??= goldenFileComparator;
    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(defaultComparator, platform);
    if (!baseDirectory.existsSync())
      baseDirectory.createSync(recursive: true);

    goldens ??= SkiaGoldClient(baseDirectory);
    return FlutterLocalFileComparator(baseDirectory.uri, goldens);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = addPrefix(golden);
    final List<int> goldenBytes = await skiaClient.getMasterBytes(golden.path);
    final ComparisonResult result = GoldenFileComparator.compareLists<Uint8List>(imageBytes, goldenBytes);

    if (!result.passed) {
      generateFailureOutput(result, golden, basedir);
    }
    return result.passed;

  }
}

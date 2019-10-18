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

// If you are here trying to figure out how to use golden files in the Flutter
// repo itself, consider reading this wiki page:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package%3Aflutter

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
///
/// Golden file testing for the `flutter/flutter` repository is handled by three
/// different [FlutterGoldenFileComparator]s, depending on the current testing
/// environment.
///
///   * The [FlutterSkiaGoldFileComparator] is utilized during post-submit
///     testing, after a pull request has landed on the master branch. This
///     comparator uses the [SkiaGoldClient] and the `goldctl` tool to upload
///     tests to the [Flutter Gold dashboard](https://flutter-gold.skia.org).
///     Flutter Gold manages the master golden files for the `flutter/flutter`
///     repository.
///
///   * The [FlutterPreSubmitFileComparator] is utilized in pre-submit testing,
///     before a pull request can land on the master branch. This comparator
///     uses the [SkiaGoldClient] to request the baseline images kept by the
///     [Flutter Gold dashboard](https://flutter-gold.skia.org). It then
///     compares the current test image to the baseline images using the
///     standard [GoldenFileComparator.compareLists] to detect any pixel
///     difference. The [SkiaGoldClient] is also used here to check the active
///     ignores from the dashboard, in order to allow intended changes to pass
///     tests.
///
///   * The [FlutterLocalFileComparator] is used for any other tests run outside
///     of the above conditions. Similar to the
///     [FlutterPreSubmitFileComparator], this comparator will use the
///     [SkiaGoldClient] to request baseline images from
///     [Flutter Gold](https://flutter-gold.skia.org) and compares for the
///     current test image. If a difference is detected, this comparator will
///     generate failure output illustrating the found difference. If a baseline
///     is not found for a given test image, it will consider it a new test and
///     output the new image for verification.
abstract class FlutterGoldenFileComparator extends GoldenFileComparator {
  /// Creates a [FlutterGoldenFileComparator] that will resolve golden file
  /// URIs relative to the specified [basedir], and retrieve golden baselines
  /// using the [skiaClient]. The [basedir] is used for writing and accessing
  /// information and files for interacting with the [skiaClient]. When testing
  /// locally, the [basedir] will also contain any diffs from failed tests, or
  /// goldens generated from newly introduced tests.
  ///
  /// The [fs] and [platform] parameters are useful in tests, where the default
  /// file system and platform can be replaced by mock instances.
  @visibleForTesting
  FlutterGoldenFileComparator(
    this.basedir,
    this.skiaClient, {
    this.fs = const LocalFileSystem(),
    this.platform = const LocalPlatform(),
  }) : assert(basedir != null),
       assert(skiaClient != null),
       assert(fs != null),
       assert(platform != null);

  /// The directory to which golden file URIs will be resolved in [compare] and
  /// [update], cannot be null.
  final Uri basedir;

  /// A client for uploading image tests and making baseline requests to the
  /// Flutter Gold Dashboard, cannot be null.
  final SkiaGoldClient skiaClient;

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
    final File goldenFile = fs.directory(basedir).childFile(fs.file(uri).path);
    return goldenFile;
  }

  /// Prepends the golden Uri with the library name that encloses the current
  /// test.
  Uri _addPrefix(Uri golden) {
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
///  * [FlutterPreSubmitFileComparator], another
///    [FlutterGoldenFileComparator] that tests golden images before changes are
///    merged into the master branch.
///  * [FlutterLocalFileComparator], another
///    [FlutterGoldenFileComparator] that tests golden images locally on your
///    current machine.
class FlutterSkiaGoldFileComparator extends FlutterGoldenFileComparator {
  /// Creates a [FlutterSkiaGoldFileComparator] that will test golden file
  /// images against Skia Gold.
  ///
  /// The [fs] and [platform] parameters are useful in tests, where the default
  /// file system and platform can be replaced by mock instances.
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
    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(
      defaultComparator,
      platform,
    );

    if(!baseDirectory.existsSync()) {
      baseDirectory.createSync(recursive: true);
    }

    goldens ??= SkiaGoldClient(baseDirectory);
    await goldens.auth();
    await goldens.imgtestInit();
    return FlutterSkiaGoldFileComparator(baseDirectory.uri, goldens);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = _addPrefix(golden);
    await update(golden, imageBytes);
    final File goldenFile = getGoldenFile(golden);

    return skiaClient.imgtestAdd(golden.path, goldenFile);
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

/// A [FlutterGoldenFileComparator] for testing golden images before changes are
/// merged into the master branch.
///
/// This comparator utilizes the [SkiaGoldClient] to request baseline images for
/// the given device under test for comparison. This comparator is only
/// initialized during pre-submit testing on Cirrus CI.
///
/// See also:
///
///  * [GoldenFileComparator], the abstract class that
///    [FlutterGoldenFileComparator] implements.
///  * [FlutterSkiaGoldFileComparator], another
///    [FlutterGoldenFileComparator] that uploads tests to the Skia Gold
///    dashboard.
///  * [FlutterLocalFileComparator], another
///    [FlutterGoldenFileComparator] that tests golden images locally on your
///    current machine.
class FlutterPreSubmitFileComparator extends FlutterGoldenFileComparator {
  /// Creates a [FlutterPreSubmitFileComparator] that will test golden file
  /// images against baselines requested from Flutter Gold.
  ///
  /// The [fs] and [platform] parameters are useful in tests, where the default
  /// file system and platform can be replaced by mock instances.
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
    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(
      defaultComparator,
      platform,
    );

    if(!baseDirectory.existsSync()) {
      baseDirectory.createSync(recursive: true);
    }

    goldens ??= SkiaGoldClient(baseDirectory);
    await goldens.getExpectations();

    return FlutterPreSubmitFileComparator(baseDirectory.uri, goldens);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = _addPrefix(golden);
    final String testName = skiaClient.cleanTestName(golden.path);
    final List<String> testExpectations = skiaClient.expectations[testName];

    if (testExpectations == null) {
      // There is no baseline for this test
      return true;
    }

    ComparisonResult result;
    for (String expectation in testExpectations) {
      final List<int> goldenBytes = await skiaClient.getImageBytes(expectation);

      result = GoldenFileComparator.compareLists(
        imageBytes,
        goldenBytes,
      );

      if (result.passed) {
        return true;
      }
    }

    return skiaClient.testIsIgnoredForPullRequest(
      platform.environment['CIRRUS_PR'] ?? '',
      golden.path,
    );
  }

  /// Decides based on the current environment whether goldens tests should be
  /// performed as pre-submit tests with Skia Gold.
  static bool isAvailableForEnvironment(Platform platform) {
    final String cirrusCI = platform.environment['CIRRUS_CI'] ?? '';
    final String cirrusPR = platform.environment['CIRRUS_PR'] ?? '';
    return cirrusCI.isNotEmpty && cirrusPR.isNotEmpty;
  }
}

/// A [FlutterGoldenFileComparator] for testing golden images locally on your
/// current machine.
///
/// This comparator utilizes the [SkiaGoldClient] to request baseline images for
/// the given device under test for comparison. This comparator is only
/// initialized when running tests locally, and is intended to serve as a smoke
/// test during development. As such, it will not be able to detect unintended
/// changes on other machines until it they are tested using the
/// [FlutterPreSubmitFileComparator].
///
/// See also:
///
///  * [GoldenFileComparator], the abstract class that
///    [FlutterGoldenFileComparator] implements.
///  * [FlutterSkiaGoldFileComparator], another
///    [FlutterGoldenFileComparator] that uploads tests to the Skia Gold
///    dashboard.
///  * [FlutterPreSubmitFileComparator], another
///    [FlutterGoldenFileComparator] that tests golden images before changes are
///    merged into the master branch.
class FlutterLocalFileComparator extends FlutterGoldenFileComparator with LocalComparisonOutput {
  /// Creates a [FlutterLocalFileComparator] that will test golden file
  /// images against baselines requested from Flutter Gold.
  ///
  /// The [fs] and [platform] parameters are useful in tests, where the default
  /// file system and platform can be replaced by mock instances.
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
    final Directory baseDirectory = FlutterGoldenFileComparator.getBaseDirectory(
      defaultComparator,
      platform,
    );

    if(!baseDirectory.existsSync()) {
      baseDirectory.createSync(recursive: true);
    }

    goldens ??= SkiaGoldClient(baseDirectory);
    await goldens.getExpectations();

    return FlutterLocalFileComparator(baseDirectory.uri, goldens);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = _addPrefix(golden);
    final String testName = skiaClient.cleanTestName(golden.path);
    final List<String> testExpectations = skiaClient.expectations[testName];
    if (testExpectations == null) {
      // There is no baseline for this test
      print('No expectations provided by Skia Gold for test: $golden. '
        'This may be a new test. If this is an unexpected result, check'
        ' https://flutter-gold.skia.org.\n'
        'Validate image output found at $basedir'
      );
      update(golden, imageBytes);
      return true;
    }

    ComparisonResult result;
    final Map<String, ComparisonResult> validFailures = <String, ComparisonResult>{};
    for (String expectation in testExpectations) {
      final List<int> goldenBytes = await skiaClient.getImageBytes(expectation);

      result = GoldenFileComparator.compareLists(
        imageBytes,
        goldenBytes,
      );

      if (result.passed) {
        return true;
      } else if (await skiaClient.isValidDigestForExpectation(expectation, golden.path)) {
        validFailures[expectation] = result;
      }
    }
    validFailures.forEach((String expectation, ComparisonResult result) {
      generateFailureOutput(result, golden, basedir, key: expectation);
    });
    return false;
  }
}

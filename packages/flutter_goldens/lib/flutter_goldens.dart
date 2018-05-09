// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

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
    this.fs: const LocalFileSystem(),
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
    goldens ??= new GoldensClient();
    await goldens.prepare();

    // Calculate the appropriate basedir for the current test context.
    final FileSystem fs = goldens.fs;
    final Directory testDirectory = fs.directory(defaultComparator.basedir);
    final String testDirectoryRelativePath = fs.path.relative(testDirectory.path, from: goldens.flutterRoot.path);
    return new FlutterGoldenFileComparator(goldens.repositoryRoot.childDirectory(testDirectoryRelativePath).uri);
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File goldenFile = _getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      throw new TestFailure('Could not be compared against non-existent file: "$golden"');
    }
    final List<int> goldenBytes = await goldenFile.readAsBytes();
    // TODO(tvolkert): Improve the intelligence of this comparison.
    return const ListEquality<int>().equals(goldenBytes, imageBytes);
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

/// A class that represents a clone of the https://github.com/flutter/goldens
/// repository, nested within the `bin/cache` directory of the caller's Flutter
/// repository.
@visibleForTesting
class GoldensClient {
  GoldensClient({
    this.fs: const LocalFileSystem(),
    this.platform: const LocalPlatform(),
    this.process: const LocalProcessManager(),
  });

  final FileSystem fs;
  final Platform platform;
  final ProcessManager process;

  RandomAccessFile _lock;

  Directory get flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);

  Directory get repositoryRoot => flutterRoot.childDirectory(fs.path.join('bin', 'cache', 'pkg', 'goldens'));

  /// Prepares the local clone of the `flutter/goldens` repository for golden
  /// file testing.
  ///
  /// This ensures that the goldens repository has been cloned into its
  /// expected location within `bin/cache` and that it is synced to the Git
  /// revision specified in `bin/internal/goldens.version`.
  ///
  /// While this is preparing the repository, it obtains a file lock such that
  /// [GoldensClient] instances in other processes or isolates will not
  /// duplicate the work that this is doing.
  Future<void> prepare() async {
    final String goldensCommit = await _getGoldensCommit();
    String currentCommit = await _getCurrentCommit();
    if (currentCommit != goldensCommit) {
      await _obtainLock();
      try {
        // Check the current commit again now that we have the lock.
        currentCommit = await _getCurrentCommit();
        if (currentCommit != goldensCommit) {
          if (currentCommit == null) {
            await _initRepository();
          }
          await _syncTo(goldensCommit);
        }
      } finally {
        await _releaseLock();
      }
    }
  }

  Future<String> _getGoldensCommit() async {
    final File versionFile = flutterRoot.childFile(fs.path.join('bin', 'internal', 'goldens.version'));
    return (await versionFile.readAsString()).trim();
  }

  Future<String> _getCurrentCommit() async {
    if (!repositoryRoot.existsSync()) {
      return null;
    } else {
      final io.ProcessResult revParse = await process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: repositoryRoot.path,
      );
      return revParse.exitCode == 0 ? revParse.stdout.trim() : null;
    }
  }

  Future<void> _initRepository() async {
    await repositoryRoot.create(recursive: true);
    await _runCommands(
      <String>[
        'git init',
        'git remote add upstream https://github.com/flutter/goldens.git',
        'git remote set-url --push upstream git@github.com:flutter/goldens.git',
      ],
      workingDirectory: repositoryRoot,
    );
  }

  Future<void> _syncTo(String commit) async {
    await _runCommands(
      <String>[
        'git pull upstream master',
        'git fetch upstream $commit',
        'git reset --hard FETCH_HEAD',
      ],
      workingDirectory: repositoryRoot,
    );
  }

  Future<void> _runCommands(
    List<String> commands, {
    Directory workingDirectory,
  }) async {
    for (String command in commands) {
      final List<String> parts = command.split(' ');
      final io.ProcessResult result = await process.run(
        parts,
        workingDirectory: workingDirectory?.path,
      );
      if (result.exitCode != 0) {
        throw new NonZeroExitCode(result.exitCode, result.stderr);
      }
    }
  }

  Future<void> _obtainLock() async {
    final File lockFile = flutterRoot.childFile(fs.path.join('bin', 'cache', 'goldens.lockfile'));
    await lockFile.create(recursive: true);
    _lock = await lockFile.open(mode: io.FileMode.WRITE); // ignore: deprecated_member_use
    await _lock.lock(io.FileLock.BLOCKING_EXCLUSIVE); // ignore: deprecated_member_use
  }

  Future<void> _releaseLock() async {
    await _lock.close();
    _lock = null;
  }
}

/// Exception that signals a process' exit with a non-zero exit code.
class NonZeroExitCode implements Exception {
  const NonZeroExitCode(this.exitCode, this.stderr) : assert(exitCode != 0);

  final int exitCode;
  final String stderr;

  @override
  String toString() {
    return 'Exit code $exitCode: $stderr';
  }
}

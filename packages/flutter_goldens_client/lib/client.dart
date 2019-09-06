// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

// If you are here trying to figure out how to use golden files in the Flutter
// repo itself, consider reading this wiki page:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package%3Aflutter

const String _kFlutterRootKey = 'FLUTTER_ROOT';

/// A base class that provides shared information to the
/// [FlutterGoldenFileComparator] as well as the [SkiaGoldClient] and
/// [GoldensRepositoryClient].
abstract class GoldensClient {
  /// Creates a handle to the local environment of golden file images.
  GoldensClient({
    this.fs = const LocalFileSystem(),
    this.platform = const LocalPlatform(),
    this.process = const LocalProcessManager(),
  });

  /// The file system to use for storing the local clone of the repository.
  ///
  /// This is useful in tests, where a local file system (the default) can
  /// be replaced by a memory file system.
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  ///
  /// This is useful in tests, where the system platform (the default) can
  /// be replaced by a mock platform instance.
  final Platform platform;

  /// A controller for launching subprocesses.
  ///
  /// This is useful in tests, where the real process manager (the default)
  /// can be replaced by a mock process manager that doesn't really create
  /// subprocesses.
  final ProcessManager process;

  /// The local [Directory] where the Flutter repository is hosted.
  ///
  /// Uses the [fs] file system.
  Directory get flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);

  /// The local [Directory] where the goldens files are located.
  ///
  /// Uses the [fs] file system.
  Directory get comparisonRoot => flutterRoot.childDirectory(fs.path.join('bin', 'cache', 'pkg', 'goldens'));

}

/// A class that represents a clone of the https://github.com/flutter/goldens
/// repository, nested within the `bin/cache` directory of the caller's Flutter
/// repository.
class GoldensRepositoryClient extends GoldensClient {
  GoldensRepositoryClient({
    FileSystem fs = const LocalFileSystem(),
    ProcessManager process = const LocalProcessManager(),
    Platform platform = const LocalPlatform(),
  }) : super(
    fs: fs,
    process: process,
    platform: platform,
  );

  RandomAccessFile _lock;

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
          await _checkCanSync();
          await _syncTo(goldensCommit);
        }
      } finally {
        await _releaseLock();
      }
    }
  }

  Future<String> _getCurrentCommit() async {
    if (!comparisonRoot.existsSync()) {
      return null;
    } else {
      final io.ProcessResult revParse = await process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: comparisonRoot.path,
      );
      return revParse.exitCode == 0 ? revParse.stdout.trim() : null;
    }
  }

  Future<String> _getGoldensCommit() async {
    final File versionFile = flutterRoot.childFile(fs.path.join('bin', 'internal', 'goldens.version'));
    return (await versionFile.readAsString()).trim();
  }

  Future<void> _initRepository() async {
    await comparisonRoot.create(recursive: true);
    await _runCommands(
      <String>[
        'git init',
        'git remote add upstream https://github.com/flutter/goldens.git',
        'git remote set-url --push upstream git@github.com:flutter/goldens.git',
      ],
      workingDirectory: comparisonRoot,
    );
  }

  Future<void> _checkCanSync() async {
    final io.ProcessResult result = await process.run(
      <String>['git', 'status', '--porcelain'],
      workingDirectory: comparisonRoot.path,
    );
    if (result.stdout.trim().isNotEmpty) {
      final StringBuffer buf = StringBuffer()
        ..writeln('flutter_goldens git checkout at ${comparisonRoot.path} has local changes and cannot be synced.')
        ..writeln('To reset your client to a clean state, and lose any local golden test changes:')
        ..writeln('cd ${comparisonRoot.path}')
        ..writeln('git reset --hard HEAD')
        ..writeln('git clean -x -d -f -f');
      throw NonZeroExitCode(1, buf.toString());
    }
  }

  Future<void> _syncTo(String commit) async {
    await _runCommands(
      <String>[
        'git pull upstream master',
        'git fetch upstream $commit',
        'git reset --hard FETCH_HEAD',
      ],
      workingDirectory: comparisonRoot,
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
        throw NonZeroExitCode(result.exitCode, result.stderr);
      }
    }
  }

  Future<void> _obtainLock() async {
    final File lockFile = flutterRoot.childFile(fs.path.join('bin', 'cache', 'goldens.lockfile'));
    await lockFile.create(recursive: true);
    _lock = await lockFile.open(mode: io.FileMode.write);
    await _lock.lock(io.FileLock.blockingExclusive);
  }

  Future<void> _releaseLock() async {
    await _lock.close();
    _lock = null;
  }
}

/// Exception that signals a process' exit with a non-zero exit code.
class NonZeroExitCode implements Exception {
  /// Create an exception that represents a non-zero exit code.
  ///
  /// The first argument must be non-zero.
  const NonZeroExitCode(this.exitCode, this.stderr) : assert(exitCode != 0);

  /// The code that the process will signal to the operating system.
  ///
  /// By definition, this is not zero.
  final int exitCode;

  /// The message to show on standard error.
  final String stderr;

  @override
  String toString() {
    return 'Exit code $exitCode: $stderr';
  }
}

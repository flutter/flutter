// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//TODO(katelovett): Change to Skia Gold Client
import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

// If you are here trying to figure out how to use golden files in the Flutter
// repo itself, consider reading this wiki page:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package%3Aflutter
//TODO(katelovett): Tests [flutter_goldens_test.dart] and inline documentation
const String _kFlutterRootKey = 'FLUTTER_ROOT';
const String _kGoldctlKey = 'GOLDCTL';
const String _kServiceAccountKey = 'GOLD_SERVICE_ACCOUNT';
const String _kSkiaGoldInstance = 'SKIA_GOLD_INSTANCE';

class SkiaGoldClient {
  SkiaGoldClient({
    this.fs = const LocalFileSystem(),
    this.platform = const LocalPlatform(),
    this.process = const LocalProcessManager(),
  });

  final FileSystem fs;
  final Platform platform;
  final ProcessManager process;
  Directory _workDirectory;

  //TODO(katelovett): Environment variables swapped out for final CI implementation
  String get _goldctl => platform.environment[_kGoldctlKey];
  String get _serviceAccount => platform.environment[_kServiceAccountKey];
  String get _skiaGoldInstance => platform.environment[_kSkiaGoldInstance];
  Directory get _flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);

  Future<bool> auth(Directory workDirectory) async {
    _workDirectory = workDirectory;
    List<String> authArguments = <String>['auth'];
    if(_serviceAccount == null)
      throw const NonZeroExitCode(1, 'No Service Account found.');

    authArguments += <String>[
      '--service-account', _serviceAccount,
      '--work-dir', _workDirectory.childDirectory('temp').path,
    ];

    final io.ProcessResult authResults = io.Process.runSync(_goldctl, authArguments);
    if (authResults.exitCode != 0) {
      final StringBuffer buf = StringBuffer();
      buf
        ..writeln('Flutter + Skia Gold auth failed.')
        ..writeln('stdout: ${authResults.stdout}')
        ..writeln('stderr: ${authResults.stderr}');
      throw NonZeroExitCode(authResults.exitCode, buf.toString());
    }
    return true;
  }

  Future<bool> imgtest(String testName, File goldenFile) async {
    List<String> imgtestArguments = <String>[
      'imgtest',
      'add',
    ];

    final String commitHash = await _getCommitHash();
    final String keys = '${_workDirectory.path}keys.json';
    final String failures = '${_workDirectory.path}failures.json';
    await io.File(keys).writeAsString(_getKeysJSON());
    await io.File(failures).create();

    imgtestArguments += <String>[
      '--instance', _skiaGoldInstance,
      '--work-dir', _workDirectory.childDirectory('temp').path,
      '--commit', commitHash,
      '--test-name', testName,
      '--png-file', goldenFile.path,
      '--keys-file', keys,
      '--failure-file', failures,
      '--passfail',
    ];

    if(imgtestArguments.contains(null)) {
      final StringBuffer buf = StringBuffer();
      buf.writeln('null argument for Skia Gold imgtest:');
      imgtestArguments.forEach(buf.writeln);
      throw NonZeroExitCode(1, buf.toString());
    }

    final io.ProcessResult imgtestResult = io.Process.runSync(_goldctl, imgtestArguments);
    if (imgtestResult.exitCode != 0) {
      final StringBuffer buf = StringBuffer();
      buf
        ..writeln('Flutter + Skia Gold imgtest failed.')
        ..writeln('If this is the first execution of this test, it may need to be triaged.')
        ..writeln('\tIn this case, re-run the test after triage is completed.')
        ..writeln('stdout: ${imgtestResult.stdout}')
        ..writeln('stderr: ${imgtestResult.stderr}');
      throw NonZeroExitCode(imgtestResult.exitCode, buf.toString());
    }
    return true;
  }

  Future<String> _getCommitHash() async {
    if (!_flutterRoot.existsSync()) {
      return null;
    } else {
      final io.ProcessResult revParse = await process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: _flutterRoot.path,
      );
      return revParse.exitCode == 0 ? revParse.stdout.trim() : null;
    }
  }

  String _getKeysJSON() {
    return convert.json.encode(
      <String, dynamic>{
        'Operating System' : io.Platform.operatingSystem,
        'Operating System Version' : io.Platform.operatingSystemVersion,
        'Dart Version' : io.Platform.version,
      });
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
  /// By definiton, this is not zero.
  final int exitCode;

  /// The message to show on standard error.
  final String stderr;

  @override
  String toString() {
    return 'Exit code $exitCode: $stderr';
  }
}

//
///// A class that represents a clone of the https://github.com/flutter/goldens
///// repository, nested within the `bin/cache` directory of the caller's Flutter
///// repository.
//class GoldensClient {
//  /// Create a handle to a local clone of the goldens repository.
//  GoldensClient({
//    this.fs = const LocalFileSystem(),
//    this.platform = const LocalPlatform(),
//    this.process = const LocalProcessManager(),
//  });
//
//  /// The file system to use for storing the local clone of the repository.
//  ///
//  /// This is useful in tests, where a local file system (the default) can
//  /// be replaced by a memory file system.
//  final FileSystem fs;
//
//  /// A wrapper for the [dart:io.Platform] API.
//  ///
//  /// This is useful in tests, where the system platform (the default) can
//  /// be replaced by a mock platform instance.
//  final Platform platform;
//
//  /// A controller for launching subprocesses.
//  ///
//  /// This is useful in tests, where the real process manager (the default)
//  /// can be replaced by a mock process manager that doesn't really create
//  /// subprocesses.
//  final ProcessManager process;
//
//  RandomAccessFile _lock;
//
//  /// The local [Directory] where the Flutter repository is hosted.
//  ///
//  /// Uses the [fs] file system.
//  Directory get flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);
//
//  /// The local [Directory] where the goldens repository is hosted.
//  ///
//  /// Uses the [fs] file system.
//  Directory get repositoryRoot => flutterRoot.childDirectory(fs.path.join('bin', 'cache', 'pkg', 'goldens'));
//
//  /// Prepares the local clone of the `flutter/goldens` repository for golden
//  /// file testing.
//  ///
//  /// This ensures that the goldens repository has been cloned into its
//  /// expected location within `bin/cache` and that it is synced to the Git
//  /// revision specified in `bin/internal/goldens.version`.
//  ///
//  /// While this is preparing the repository, it obtains a file lock such that
//  /// [GoldensClient] instances in other processes or isolates will not
//  /// duplicate the work that this is doing.
//  Future<void> prepare() async {
//    print('GoldensClient.prepare');
//    final String goldensCommit = await _getGoldensCommit();
//    String currentCommit = await _getCurrentCommit();
//    if (currentCommit != goldensCommit) {
//      await _obtainLock();
//      try {
//        // Check the current commit again now that we have the lock.
//        currentCommit = await _getCurrentCommit();
//        if (currentCommit != goldensCommit) {
//          if (currentCommit == null) {
//            await _initRepository();
//          }
//          await _checkCanSync();
//          await _syncTo(goldensCommit);
//        }
//      } finally {
//        await _releaseLock();
//      }
//    }
//  }
//
//  Future<String> _getGoldensCommit() async {
//    final File versionFile = flutterRoot.childFile(fs.path.join('bin', 'internal', 'goldens.version'));
//    return (await versionFile.readAsString()).trim();
//  }
//
//  Future<String> _getCurrentCommit() async {
//    if (!repositoryRoot.existsSync()) {
//      return null;
//    } else {
//      final io.ProcessResult revParse = await process.run(
//        <String>['git', 'rev-parse', 'HEAD'],
//        workingDirectory: repositoryRoot.path,
//      );
//      return revParse.exitCode == 0 ? revParse.stdout.trim() : null;
//    }
//  }
//
//  Future<void> _initRepository() async {
//    await repositoryRoot.create(recursive: true);
//    await _runCommands(
//      <String>[
//        'git init',
//        'git remote add upstream https://github.com/flutter/goldens.git',
//        'git remote set-url --push upstream git@github.com:flutter/goldens.git',
//      ],
//      workingDirectory: repositoryRoot,
//    );
//  }
//
//  Future<void> _checkCanSync() async {
//    final io.ProcessResult result = await process.run(
//      <String>['git', 'status', '--porcelain'],
//      workingDirectory: repositoryRoot.path,
//    );
//    if (result.stdout.trim().isNotEmpty) {
//      final StringBuffer buf = StringBuffer();
//      buf
//        ..writeln('flutter_goldens git checkout at ${repositoryRoot.path} has local changes and cannot be synced.')
//        ..writeln('To reset your client to a clean state, and lose any local golden test changes:')
//        ..writeln('cd ${repositoryRoot.path}')
//        ..writeln('git reset --hard HEAD')
//        ..writeln('git clean -x -d -f -f');
//      throw NonZeroExitCode(1, buf.toString());
//    }
//  }
//
//  Future<void> _syncTo(String commit) async {
//    await _runCommands(
//      <String>[
//        'git pull upstream master',
//        'git fetch upstream $commit',
//        'git reset --hard FETCH_HEAD',
//      ],
//      workingDirectory: repositoryRoot,
//    );
//  }
//
//  Future<void> _runCommands(
//    List<String> commands, {
//    Directory workingDirectory,
//  }) async {
//    for (String command in commands) {
//      final List<String> parts = command.split(' ');
//      final io.ProcessResult result = await process.run(
//        parts,
//        workingDirectory: workingDirectory?.path,
//      );
//      if (result.exitCode != 0) {
//        throw NonZeroExitCode(result.exitCode, result.stderr);
//      }
//    }
//  }
//
//  Future<void> _obtainLock() async {
//    final File lockFile = flutterRoot.childFile(fs.path.join('bin', 'cache', 'goldens.lockfile'));
//    await lockFile.create(recursive: true);
//    _lock = await lockFile.open(mode: io.FileMode.write);
//    await _lock.lock(io.FileLock.blockingExclusive);
//  }
//
//  Future<void> _releaseLock() async {
//    await _lock.close();
//    _lock = null;
//  }
//}
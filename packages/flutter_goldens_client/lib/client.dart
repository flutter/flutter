// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process/process.dart';

// If you are here trying to figure out how to use golden files in the Flutter
// repo itself, consider reading this wiki page:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package%3Aflutter

const String _kFlutterRootKey = 'FLUTTER_ROOT';
const String _kGoldctlKey = 'GOLDCTL';
const String _kServiceAccountKey = 'GOLD_SERVICE_ACCOUNT';
const String _kSkiaGoldInstance = 'SKIA_GOLD_INSTANCE';

/// A class that represents the Skia Gold client for golden file testing.
class SkiaGoldClient {
  /// Create a  handle to a local workspace for the Skia Gold Client.
  SkiaGoldClient({
    this.fs = const LocalFileSystem(),
    this.platform = const LocalPlatform(),
    this.process = const LocalProcessManager(),
  });

  /// The file system to use for storing local files for running imgtests.
  ///
  /// This is useful in tests, where a local file system (the default) can be
  /// replaced by a memory file system.
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  ///
  /// This is useful in tests, where the system platform (the default) can be
  /// replaced by a mock platform instance.
  final Platform platform;

  /// A controller for launching sub-processes.
  ///
  /// This is useful in tests, where the real process manager (the default) can
  /// be replaced by a mock process manager that doesn't really create
  /// sub-processes.
  final ProcessManager process;

  Directory _workDirectory;

  // TODO(Piinks): Environment variables are temporary for local testing, https://github.com/flutter/flutter/pull/31630
  /// The local [Directory] where the Flutter repository is hosted.
  ///
  /// Uses the [fs] file system.
  Directory get flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);

  /// The [path] to the local [Directory] where the goldctl tool is hosted.
  ///
  /// Uses the [platform] [environment] in this iteration.
  String get _goldctl => platform.environment[_kGoldctlKey];

  /// The [path] to the local [Directory] where the service account key is
  /// hosted.
  ///
  /// Uses the [platform] [environment] in this iteration.
  String get _serviceAccount => platform.environment[_kServiceAccountKey];

  /// The name of the Skia Gold Flutter instance.
  ///
  /// Uses the [platform] [environment] in this iteration.
  String get _skiaGoldInstance => platform.environment[_kSkiaGoldInstance];

  /// Prepares the local work space for golden file testing and initializes the
  /// goldctl authorization for executing tests.
  ///
  /// This ensures that the goldctl tool is authorized and ready for testing.
  Future<bool> auth(Directory workDirectory) async {
    _workDirectory = workDirectory;

    // TODO(Piinks): Cleanup for final CI implementation, https://github.com/flutter/flutter/pull/31630
    if (_serviceAccount == null)
      return false; // Not in the proper environment for golden file testing.

    final File authFile = _workDirectory.childFile(fs.path.join(
      'temp',
      'auth_opt.json'
    ));
    if (!authFile.existsSync()) {
      final List<String> authArguments = <String>[
        'auth',
        '--service-account', _serviceAccount,
        '--work-dir', _workDirectory.childDirectory('temp').path,
      ];

      final io.ProcessResult authResults = io.Process.runSync(
        _goldctl,
        authArguments
      );
      if (authResults.exitCode != 0) {
        final StringBuffer buf = StringBuffer();
        buf
          ..writeln('Flutter + Skia Gold auth failed.')
          ..writeln('stdout: ${authResults.stdout}')
          ..writeln('stderr: ${authResults.stderr}');
        throw NonZeroExitCode(authResults.exitCode, buf.toString());
      }
    }
    return true;
  }

  Future<void> imgtestInit() async {
    final File keysFile = _workDirectory.childFile('keys.json');

    if(!keysFile.existsSync() || await _isNewCommit()) {
      final String commitHash = await _getCommitHash();
      final String keys = '${_workDirectory.path}keys.json';
      final String failures = '${_workDirectory.path}failures.json';

      await io.File(keys).writeAsString(_getKeysJSON());
      await io.File(failures).create();

      final List<String> imgtestInitArguments = <String>[
        'imgtest', 'init',
        '--instance', _skiaGoldInstance,
        '--work-dir', _workDirectory.childDirectory('temp').path,
        '--commit', commitHash,
        '--keys-file', keys,
        '--failure-file', failures,
        '--passfail',
      ];

      if(imgtestInitArguments.contains(null)) {
        final StringBuffer buf = StringBuffer();
        buf.writeln('Null argument for Skia Gold imgtest init:');
        imgtestInitArguments.forEach(buf.writeln);
        throw NonZeroExitCode(1, buf.toString());
      }

      final io.ProcessResult imgtestInitResult = io.Process.runSync(
        _goldctl,
        imgtestInitArguments,
      );

      if (imgtestInitResult.exitCode != 0) {
        final StringBuffer buf = StringBuffer();
        buf
          ..writeln('Flutter + Skia Gold imgtest init failed.')
          ..writeln('stdout: ${imgtestInitResult.stdout}')
          ..writeln('stderr: ${imgtestInitResult.stderr}');
        throw NonZeroExitCode(imgtestInitResult.exitCode, buf.toString());
      }
    }
  }

  Future<bool> imgtestAdd(String testName, File goldenFile) async {
    final List<String> imgtestArguments = <String>[
      'imgtest', 'add',
      '--work-dir', _workDirectory.childDirectory('temp').path,
      '--test-name', testName,
      '--png-file', goldenFile.path,
    ];

    if(imgtestArguments.contains(null)) {
      final StringBuffer buf = StringBuffer();
      buf.writeln('Null argument for Skia Gold imgtest add:');
      imgtestArguments.forEach(buf.writeln);
      throw NonZeroExitCode(1, buf.toString());
    }

    final io.ProcessResult imgtestResult = io.Process.runSync(
      _goldctl,
      imgtestArguments,
    );
    if (imgtestResult.exitCode != 0) {
      final StringBuffer buf = StringBuffer();
      buf
        ..writeln('Flutter + Skia Gold imgtest add failed.')
        ..writeln('If this is the first execution of this test, it may need to be triaged.')
        ..writeln('In this case, re-run the test after triage is completed.\n')
        ..writeln('stdout: ${imgtestResult.stdout}')
        ..writeln('stderr: ${imgtestResult.stderr}');
      throw NonZeroExitCode(imgtestResult.exitCode, buf.toString());
    }
    return true;
  }

  Future<String> _getCommitHash() async {
    // TODO(Piinks): Remove after pre-commit tests can be ingested by Skia Gold, https://github.com/flutter/flutter/pull/31630
    return 'e51947241b37790a9e4e33bfdef59aaa9b930851';
//    if (!flutterRoot.existsSync()) {
//      return null;
//    } else {
//      final io.ProcessResult revParse = await process.run(
//        <String>['git', 'rev-parse', 'HEAD'],
//        workingDirectory: flutterRoot.path,
//      );
//      return revParse.exitCode == 0 ? revParse.stdout.trim() : null;
  }

  Future<bool> _isNewCommit() async {
    // auth file is there, need to check if we are on a new commit
    final File resultFile = _workDirectory.childFile(fs.path.join(
      'temp',
      'result-state.json'
    ));
    final String contents = await resultFile.readAsString();
    final Map<String, dynamic> resultJSON = convert.json.decode(contents);
    final String lastTestedCommit = resultJSON['SharedConfig']['gitHash'];
    final String currentCommit = await _getCommitHash();
    return lastTestedCommit == currentCommit ? false : true;
  }

  String _getKeysJSON() {
    // TODO(Piinks): Parse out cleaner key information, https://github.com/flutter/flutter/pull/31630
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
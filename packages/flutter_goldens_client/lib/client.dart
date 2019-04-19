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
  /// This is usefule in tests, where a local file system (the default) can be
  /// replaced by a memory file system.
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  ///
  /// This is useful in tests, where the system platform (the default) can be
  /// replaced by a mock platform instance.
  final Platform platform;

  /// A controller for launching subprocesses.
  ///
  /// This is useful in tests, where the real process manager (the default) can
  /// be replaced by a mock process manager that doesn't really create
  /// subprocesses.
  final ProcessManager process;

  Directory _workDirectory;

  //TODO(katelovett): Environment variables swapped out for CI implementation
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

  /// The local [Directory] where the Flutter repository is hosted.
  ///
  /// Uses the [fs] file system.
  Directory get _flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);

  /// Prepares the local work space for golden file testing and initializes the
  /// goldctl authorization for executing tests.
  ///
  /// This ensures that the goldctl tool is authorized and ready for testing.
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
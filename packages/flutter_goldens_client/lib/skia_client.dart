// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';

import 'package:flutter_goldens_client/client.dart';

// If you are here trying to figure out how to use golden files in the Flutter
// repo itself, consider reading this wiki page:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package%3Aflutter

// TODO(Piinks): This file will replace ./client.dart when transition to Skia
// Gold testing is complete
const String _kFlutterRootKey = 'FLUTTER_ROOT';
const String _kGoldctlKey = 'GOLDCTL';
const String _kServiceAccountKey = 'GOLD_SERVICE_ACCOUNT';

/// A class that represents the Skia Gold client for golden file testing.
class SkiaGoldClient {
  /// Create a handle to a local workspace for the Skia Gold Client
  SkiaGoldClient({
    this.fs = const LocalFileSystem(),
    this.platform = const LocalPlatform(),
  });

  /// The file system to use for storing local files for running imgtests.
  ///
  /// This is useful in tests, where a local file system (the default) can be
  /// replaced by a memory file system.
  final FileSystem fs;

  /// A wrapper for the [dart:io.Platform] API.
  ///
  /// This is useful in tests, where the system platform (the default) can be
  /// replaced by mock platform instance.
  final Platform platform;

  /// The local [Directory] where The Skia Client will be operating tests.
  ///
  /// This is provided by the [FlutterGoldenFileComparator], cannot be null.
  Directory _workDirectory;

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

  /// Prepares the local work space for golden file testing and initializes the
  /// goldctl authorization for executing tests.
  ///
  /// This ensures that the goldctl tool is authorized and ready for testing.
  Future<bool> auth(Directory workDirectory) async {
    _workDirectory = workDirectory;

    if (_serviceAccount == null)
      return false;

    final String authorization ='${_workDirectory.path}serviceAccount.json';
    await io.File(authorization).writeAsString(_serviceAccount);

    final List<String> authArguments = <String>[
      'auth',
      '--service-account', authorization,
      '--work-dir', _workDirectory.childDirectory('temp').path,
    ];

    final io.ProcessResult authResults = io.Process.runSync(
      _goldctl,
      authArguments,
    );

    if(authResults.exitCode != 0) {
      final StringBuffer buf = StringBuffer();
      buf
        ..writeln('Flutter + Skia Gold auth failed.')
        ..writeln('stdout: ${authResults.stdout}')
        ..writeln('stderr: ${authResults.stderr}');
      throw NonZeroExitCode(authResults.exitCode, buf.toString());
    }
    return true;
  }

  Future<void> imgtestInit() async {
    final String commitHash = await _getCommitHash();
    final String keys = '${_workDirectory.path}keys.json';
    final String failures = '${_workDirectory.path}failures.json';

    await io.File(keys).writeAsString(_getKeysJSON());
    await io.File(failures).create();

    final List<String> imgtestInitArguments = <String>[
      'imgtest', 'init',
      '--instance', 'flutter',
      '--work-dir', _workDirectory
        .childDirectory('temp')
        .path,
      '--commit', commitHash,
      '--keys-file', keys,
      '--failure-file', failures,
      '--passfail',
    ];

    if (imgtestInitArguments.contains(null)) {
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

  Future<bool> imgtestAdd(String testName, File goldenFile) async {
    final List<String> imgtestArguments = <String>[
      'imgtest', 'add',
      '--work-dir', _workDirectory.childDirectory('temp').path,
      '--test-name', testName.split('.png')[0],
      '--png-file', goldenFile.path,
    ];

    if(imgtestArguments.contains(null)) {
      final StringBuffer buf = StringBuffer();
      buf.writeln('Null argument for Skia Gold imgtest add:');
      imgtestArguments.forEach(buf.writeln);
      throw NonZeroExitCode(1, buf.toString());
    }

    //final io.ProcessResult imgtestResult =
    await io.Process.run( //Sync(
      _goldctl,
      imgtestArguments,
    );

    // Will not turn the tree red.
    // TODO(Piinks): Comment on PR if triage is needed, https://github.com/flutter/flutter/issues/34673
    // if (imgtestResult.exitCode != 0) {
    //   final StringBuffer buf = StringBuffer();
    //  buf
    //    ..writeln('Flutter + Skia Gold imgtest add failed.')
    //    ..writeln('If this is the first execution of this test, it may need to be triaged.')
    //    ..writeln('In this case, re-run the test after triage is completed.\n')
    //    ..writeln('stdout: ${imgtestResult.stdout}')
    //    ..writeln('stderr: ${imgtestResult.stderr}');
    //  throw NonZeroExitCode(imgtestResult.exitCode, buf.toString());
    // }
    return true;
  }

  Future<String> _getCommitHash() async {
    if (!flutterRoot.existsSync()) {
      return null;
    } else {
      final io.ProcessResult revParse = io.Process.runSync(
        'git',
        <String>['rev-parse', 'HEAD'],
        workingDirectory: flutterRoot.path,
      );
      return revParse.exitCode == 0 ? revParse.stdout.trim() : null;
    }
  }

  String _getKeysJSON() {
    return convert.json.encode(
    <String, dynamic>{
    'Platform' : platform.operatingSystem,
    });
  }
}
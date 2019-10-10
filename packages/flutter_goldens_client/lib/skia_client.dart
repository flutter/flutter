// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'package:flutter_goldens_client/client.dart';

// If you are here trying to figure out how to use golden files in the Flutter
// repo itself, consider reading this wiki page:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package%3Aflutter

// TODO(Piinks): This file will replace ./client.dart when transition to Skia
// Gold testing is complete

const String _kGoldctlKey = 'GOLDCTL';
const String _kServiceAccountKey = 'GOLD_SERVICE_ACCOUNT';

/// An extension of the [GoldensClient] class that interfaces with Skia Gold
/// for golden file testing.
class SkiaGoldClient extends GoldensClient {
  SkiaGoldClient({
    FileSystem fs = const LocalFileSystem(),
    ProcessManager process = const LocalProcessManager(),
    Platform platform = const LocalPlatform(),
  }) : super(
    fs: fs,
    process: process,
    platform: platform,
  );

  /// The local [Directory] within the [comparisonRoot] for the current test
  /// context. In this directory, the client will create image and json files
  /// for the goldctl tool to use.
  ///
  /// This is informed by the [FlutterGoldenFileComparator] [basedir]. It cannot
  /// be null.
  Directory _workDirectory;

  /// The path to the local [Directory] where the goldctl tool is hosted.
  ///
  /// Uses the [platform] environment in this implementation.
  String get _goldctl => platform.environment[_kGoldctlKey];

  /// The path to the local [Directory] where the service account key is
  /// hosted.
  ///
  /// Uses the [platform] environment in this implementation.
  String get _serviceAccount => platform.environment[_kServiceAccountKey];

  @override
  Directory get comparisonRoot => flutterRoot.childDirectory(fs.path.join('bin', 'cache', 'pkg', 'skia_goldens'));

  /// Prepares the local work space for golden file testing and calls the
  /// goldctl `auth` command.
  ///
  /// This ensures that the goldctl tool is authorized and ready for testing. It
  /// will only be called once for each instance of
  /// [FlutterSkiaGoldFileComparator].
  ///
  /// The [workDirectory] parameter specifies the current directory that golden
  /// tests are executing in, relative to the library of the given test. It is
  /// informed by the basedir of the [FlutterSkiaGoldFileComparator].
  Future<void> auth(Directory workDirectory) async {
    assert(workDirectory != null);
    _workDirectory = workDirectory;
    if (_clientIsAuthorized())
      return;

    if (_serviceAccount.isEmpty) {
      final StringBuffer buf = StringBuffer()..writeln('Gold service account is unavailable.');
      throw NonZeroExitCode(1, buf.toString());
    }

    final File authorization = _workDirectory.childFile('serviceAccount.json');
    await authorization.writeAsString(_serviceAccount);

    final List<String> authArguments = <String>[
      'auth',
      '--service-account', authorization.path,
      '--work-dir', _workDirectory.childDirectory('temp').path,
    ];

    // final io.ProcessResult authResults =
    await io.Process.run(
      _goldctl,
      authArguments,
    );
    // TODO(Piinks): Re-enable after Gold flakes are resolved, https://github.com/flutter/flutter/pull/36103
    // if (authResults.exitCode != 0) {
    //   final StringBuffer buf = StringBuffer()
    //     ..writeln('Flutter + Skia Gold auth failed.')
    //     ..writeln('stdout: ${authResults.stdout}')
    //     ..writeln('stderr: ${authResults.stderr}');
    //   throw NonZeroExitCode(authResults.exitCode, buf.toString());
    // }
  }

  /// Executes the `imgtest init` command in the goldctl tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `init` argument initializes the current test.
  Future<void> imgtestInit() async {
    final File keys = _workDirectory.childFile('keys.json');
    final File failures = _workDirectory.childFile('failures.json');

    await keys.writeAsString(_getKeysJSON());
    await failures.create();
    final String commitHash = await _getCurrentCommit();

    final List<String> imgtestInitArguments = <String>[
      'imgtest', 'init',
      '--instance', 'flutter',
      '--work-dir', _workDirectory.childDirectory('temp').path,
      '--commit', commitHash,
      '--keys-file', keys.path,
      '--failure-file', failures.path,
      '--passfail',
    ];

    if (imgtestInitArguments.contains(null)) {
      final StringBuffer buf = StringBuffer();
      buf.writeln('Null argument for Skia Gold imgtest init:');
      imgtestInitArguments.forEach(buf.writeln);
      throw NonZeroExitCode(1, buf.toString());
    }

    // final io.ProcessResult imgtestInitResult =
    await io.Process.run(
      _goldctl,
      imgtestInitArguments,
    );

    // TODO(Piinks): Re-enable after Gold flakes are resolved, https://github.com/flutter/flutter/pull/36103
    // if (imgtestInitResult.exitCode != 0) {
    //   final StringBuffer buf = StringBuffer()
    //     ..writeln('Flutter + Skia Gold imgtest init failed.')
    //     ..writeln('stdout: ${imgtestInitResult.stdout}')
    //     ..writeln('stderr: ${imgtestInitResult.stderr}');
    //   throw NonZeroExitCode(imgtestInitResult.exitCode, buf.toString());
    // }
  }

  /// Executes the `imgtest add` command in the goldctl tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test. A response is
  /// returned from the invocation of this command that indicates a pass or fail
  /// result.
  ///
  /// The testName and goldenFile parameters reference the current comparison
  /// being evaluated by the [FlutterSkiaGoldFileComparator].
  Future<bool> imgtestAdd(String testName, File goldenFile) async {
    assert(testName != null);
    assert(goldenFile != null);

    final List<String> imgtestArguments = <String>[
      'imgtest', 'add',
      '--work-dir', _workDirectory.childDirectory('temp').path,
      '--test-name', testName.split(path.extension(testName.toString()))[0],
      '--png-file', goldenFile.path,
    ];

    await io.Process.run(
      _goldctl,
      imgtestArguments,
    );

    // TODO(Piinks): Comment on PR if triage is needed, https://github.com/flutter/flutter/issues/34673
    // So as not to turn the tree red in this initial implementation, this will
    // return true for now.
    // The ProcessResult that returns from line 157 contains the pass/fail
    // result of the test & links to the dashboard and diffs.
    return true;
  }

  /// Returns the current commit hash of the Flutter repository.
  Future<String> _getCurrentCommit() async {
    if (!flutterRoot.existsSync()) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Flutter root could not be found: $flutterRoot');
      throw NonZeroExitCode(1, buf.toString());
    } else {
      final io.ProcessResult revParse = await process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: flutterRoot.path,
      );
      return revParse.exitCode == 0 ? revParse.stdout.trim() : null;
    }
  }

  /// Returns a JSON String with keys value pairs used to uniquely identify the
  /// configuration that generated the given golden file.
  ///
  /// Currently, the only key value pair being tracked is the platform the image
  /// was rendered on.
  String _getKeysJSON() {
    return json.encode(
      <String, dynamic>{
        'Platform' : platform.operatingSystem,
      }
    );
  }

  /// Returns a boolean value to prevent the client from re-authorizing itself
  /// for multiple tests.
  bool _clientIsAuthorized() {
    final File authFile = _workDirectory?.childFile(super.fs.path.join(
      'temp',
      'auth_opt.json',
    ));
    return authFile.existsSync();
  }
}

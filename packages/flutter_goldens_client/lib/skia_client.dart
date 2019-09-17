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

// If you are here trying to figure out how to use golden files in the Flutter
// repo itself, consider reading this wiki page:
// https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package%3Aflutter

const String _kFlutterRootKey = 'FLUTTER_ROOT';
const String _kGoldctlKey = 'GOLDCTL';
const String _kServiceAccountKey = 'GOLD_SERVICE_ACCOUNT';
const String _kFlutterGoldDashboard = 'https://flutter-gold.skia.org';

/// Doc
class SkiaGoldClient {
  SkiaGoldClient(this.workDirectory, {
    this.fs = const LocalFileSystem(),
    this.process = const LocalProcessManager(),
    this.platform = const LocalPlatform(),
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
  /// sub-processes.
  final ProcessManager process;

  /// The local [Directory] within the [comparisonRoot] for the current test
  /// context. In this directory, the client will create image and json files
  /// for the goldctl tool to use.
  ///
  /// This is informed by the [FlutterGoldenFileComparator] [basedir]. It cannot
  /// be null.
  final Directory workDirectory;

  /// Doc
  Directory get _flutterRoot =>
    fs.directory(platform.environment[_kFlutterRootKey]);

  /// The path to the local [Directory] where the goldctl tool is hosted.
  ///
  /// Uses the [platform] environment in this implementation.
  String get _goldctl => platform.environment[_kGoldctlKey];

  /// The path to the local [Directory] where the service account key is
  /// hosted.
  ///
  /// Uses the [platform] environment in this implementation.
  String get _serviceAccount => platform.environment[_kServiceAccountKey];

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
  Future<void> auth() async {
    if (_clientIsAuthorized())
      return;

    if (_serviceAccount.isEmpty) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Gold service account is unavailable.');
      throw NonZeroExitCode(1, buf.toString());
    }

    final File authorization = workDirectory.childFile('serviceAccount.json');
    await authorization.writeAsString(_serviceAccount);

    final List<String> authArguments = <String>[
      'auth',
      '--service-account', authorization.path,
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
    ];

    await io.Process.run(
      _goldctl,
      authArguments,
    );
  }

  /// Executes the `imgtest init` command in the goldctl tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `init` argument initializes the current test.
  Future<void> imgtestInit() async {
    final File keys = workDirectory.childFile('keys.json');
    final File failures = workDirectory.childFile('failures.json');

    await keys.writeAsString(_getKeysJSON());
    await failures.create();
    final String commitHash = await _getCurrentCommit();

    final List<String> imgtestInitArguments = <String>[
      'imgtest', 'init',
      '--instance', 'flutter',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--commit', commitHash,
      '--keys-file', keys.path,
      '--failure-file', failures.path,
      '--passfail',
    ];

    if (imgtestInitArguments.contains(null)) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Null argument for Skia Gold imgtest init:');
      imgtestInitArguments.forEach(buf.writeln);
      throw NonZeroExitCode(1, buf.toString());
    }

    await io.Process.run(
      _goldctl,
      imgtestInitArguments,
    );
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
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--test-name', _cleanTestName(testName),
      '--png-file', goldenFile.path,
    ];

    await io.Process.run(
      _goldctl,
      imgtestArguments,
    );
    return true;
  }

  /// Doc
  Future<List<int>>getMasterBytes(String testName) async {
    List<int> masterImageBytes;
    await io.HttpOverrides.runWithHttpOverrides<Future<void>>(() async {

      final io.HttpClient client = io.HttpClient();

      testName = _cleanTestName(testName);
      final Uri requestForDigest = Uri.parse(
        'https://flutter-gold.skia.org/json/search?'
          'fdiffmax=-1&fref=false&frgbamax=255&frgbamin=0'
          '&head=true'      // Goldens @ head
          '&include=true'   // Include ignored tests
          '&limit=50&master=false&match=name&metric=combined'
          '&neg=false'      // No negative digests
          '&offset=0'
          '&pos=true'       // Get positive digests
          '&query=Platform%3D${platform.operatingSystem}%26name%3D$testName%26'
          'source_type%3Dflutter&sort=desc'
          '&unt=false',     // No untriaged digests
      );
      SkiaGoldDigest masterDigest;

      try {
        await client.getUrl(requestForDigest)
          .then((io.HttpClientRequest request) => request.close())
          .then((io.HttpClientResponse response) async {
          final String responseBody = await response.transform(utf8.decoder).join();
          final Map<String,dynamic> skiaJson = json.decode(responseBody);

          if (skiaJson['digests'].length > 1) {

            final StringBuffer buf = StringBuffer()
              ..writeln('There is more than one digest available for golden')
              ..writeln('test: $testName. Triage may have broken down.')
              ..writeln('Check $_kFlutterGoldDashboard to validate the')
              ..writeln('current status of this test.');
            throw NonZeroExitCode(1, buf.toString());

          } else if (skiaJson['digests'].length == 0) {

            print('No digests provided by Skia Gold for test: $testName. '
              'This may be a new test. If this is an unexpected result, check'
              ' $_kFlutterGoldDashboard.'
            );

          }
          masterDigest = null;//SkiaGoldDigest.fromJson(skiaJson['digests'][0]);
          assert(masterDigest != null);
        });
      } catch(e) {
        e = e.toString();
        if (e.contains('triage')) {
          rethrow;
        } else if (e.contains('masterDigest != null')) {
          rethrow;
        } else {
          // i.e. Don't break people running local tests in airplane mode.
          print('Baselines are not available from Skia Gold, you may not be'
            'connected to the internet. Skipping test: $testName.');
          masterImageBytes = <int>[0];
        }
      }

      if (masterImageBytes == <int>[0])
        return;

      if (!masterDigest.isValid(platform, testName)) {
        final StringBuffer buf = StringBuffer()
          ..writeln('Invalid digest returned for golden test: $testName.')
          ..writeln('Check $_kFlutterGoldDashboard to validate the')
          ..writeln('current status of this test.');
        throw NonZeroExitCode(1, buf.toString());
      }

      final Uri requestForImage = Uri.parse(
        'https://flutter-gold.skia.org/img/images/${masterDigest.imageHash}.png',
      );

      try {
        await client.getUrl(requestForImage)
          .then((io.HttpClientRequest request) => request.close())
          .then((io.HttpClientResponse response) async {
          final List<List<int>> byteList = await response.toList();
          masterImageBytes = byteList.expand((List<int> x) => x).toList();
        });
      } catch(e) {
        rethrow;
      }
    },
      SkiaGoldHttpOverrides(),
    );
    return masterImageBytes;
  }

  /// Doc - for PreSubmit comparator
  Future<bool> testIsIgnoredForPullRequest(String pullRequest, String testName) async {
    bool ignoreIsActive = false;
    testName = _cleanTestName(testName);
    await io.HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final io.HttpClient client = io.HttpClient();

      final Uri requestForIgnores = Uri.parse('https://flutter-gold.skia.org/json/ignores');
      Map<String, dynamic> ignoredTest;
      try {
        await client.getUrl(requestForIgnores)
          .then((io.HttpClientRequest request) => request.close())
          .then((io.HttpClientResponse response) async {
          final String responseBody = await response.transform(utf8.decoder).join();
          final List<Map<String, dynamic>> skiaJson = json.decode(responseBody);
          for(int i = 0; i < skiaJson.length; i++) {
            ignoredTest = skiaJson[i];
            final List<String> ignoredQueries = ignoredTest['query'].split('&');
            final String ignoredPullRequest = ignoredTest['note']
              .split['/']
              .last();
            if (ignoredQueries.contains('name=$testName') && ignoredPullRequest == pullRequest) {
              ignoreIsActive = true;
            }
          }
        });
      } catch(_) {
        rethrow;
      }
    },
      SkiaGoldHttpOverrides(),
    );
    return ignoreIsActive;
  }

  /// Returns the current commit hash of the Flutter repository.
  Future<String> _getCurrentCommit() async {
    if (!_flutterRoot.existsSync()) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Flutter root could not be found: $_flutterRoot');
      throw NonZeroExitCode(1, buf.toString());
    } else {
      final io.ProcessResult revParse = await process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: _flutterRoot.path,
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
        'Platform': platform.operatingSystem,
      }
    );
  }

  /// Doc
  String _cleanTestName(String fileName) {
    return fileName.split(path.extension(fileName.toString()))[0];
  }

  /// Returns a boolean value to prevent the client from re-authorizing itself
  /// for multiple tests.
  bool _clientIsAuthorized() {
    final File authFile = workDirectory?.childFile(fs.path.join(
      'temp',
      'auth_opt.json',
    ));
    return authFile.existsSync();
  }
}

/// Doc
class SkiaGoldHttpOverrides extends io.HttpOverrides {}

/// Doc
class SkiaGoldDigest {
  /// Doc
  const SkiaGoldDigest({
    this.imageHash,
    this.paramSet,
    this.testName,
    this.status,
  });

  /// Doc
  factory SkiaGoldDigest.fromJson(Map<String, dynamic> json) {
    if (json == null)
      return null;

    return SkiaGoldDigest(
      imageHash: json['digest'],
      paramSet: Map<String, dynamic>.from(json['paramset']),
      testName: json['test'],
      status: json['status'],
    );
  }

  /// Unique identifier for the image associated with the digest.
  final String imageHash;

  /// Parameter set for the given test, e.g. Platform : Windows.
  final Map<String, dynamic> paramSet;

  /// Test name associated with the digest, e.g. positive or untriaged.
  final String testName;

  /// Status of the given digest, e.g. positive or untriaged.
  final String status;

  /// Doc
  bool isValid(Platform platform, String name) {
    return imageHash != null
      && paramSet['Platform'].contains(platform.operatingSystem)
      && testName == name
      && status == 'positive';
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
  String toString() => 'Exit code $exitCode: $stderr';
}

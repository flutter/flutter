// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
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
const String _kTestBrowserKey = 'FLUTTER_TEST_BROWSER';
const String _kWebRendererKey = 'FLUTTER_WEB_RENDERER';

/// A client for uploading image tests and making baseline requests to the
/// Flutter Gold Dashboard.
class SkiaGoldClient {
  /// Creates a [SkiaGoldClient] with the given [workDirectory].
  ///
  /// All other parameters are optional. They may be provided in tests to
  /// override the defaults for [fs], [process], [platform], and [httpClient].
  SkiaGoldClient(
    this.workDirectory, {
    this.fs = const LocalFileSystem(),
    this.process = const LocalProcessManager(),
    this.platform = const LocalPlatform(),
    io.HttpClient? httpClient,
  }) : httpClient = httpClient ?? io.HttpClient();

  /// The file system to use for storing the local clone of the repository.
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

  /// A client for making Http requests to the Flutter Gold dashboard.
  final io.HttpClient httpClient;

  /// The local [Directory] within the [comparisonRoot] for the current test
  /// context. In this directory, the client will create image and JSON files
  /// for the goldctl tool to use.
  ///
  /// This is informed by the [FlutterGoldenFileComparator] [basedir]. It cannot
  /// be null.
  final Directory workDirectory;

  /// The local [Directory] where the Flutter repository is hosted.
  ///
  /// Uses the [fs] file system.
  Directory get _flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);

  /// The path to the local [Directory] where the goldctl tool is hosted.
  ///
  /// Uses the [platform] environment in this implementation.
  String get _goldctl => platform.environment[_kGoldctlKey]!;

  /// Prepares the local work space for golden file testing and calls the
  /// goldctl `auth` command.
  ///
  /// This ensures that the goldctl tool is authorized and ready for testing.
  /// Used by the [FlutterPostSubmitFileComparator] and the
  /// [FlutterPreSubmitFileComparator].
  Future<void> auth() async {
    if (await clientIsAuthorized())
      return;
    final List<String> authCommand = <String>[
      _goldctl,
      'auth',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--luci',
    ];

    final io.ProcessResult result = await process.run(authCommand);

    if (result.exitCode != 0) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold authorization failed.')
        ..writeln('Luci environments authenticate using the file provided '
          'by LUCI_CONTEXT. There may be an error with this file or Gold '
          'authentication.')
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      throw Exception(buf.toString());
    }
  }

  /// Signals if this client is initialized for uploading images to the Gold
  /// service.
  ///
  /// Since Flutter framework tests are executed in parallel, and in random
  /// order, this will signal is this instance of the Gold client has been
  /// initialized.
  bool _initialized = false;

  /// Executes the `imgtest init` command in the goldctl tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `init` argument initializes the current test. Used by the
  /// [FlutterPostSubmitFileComparator].
  Future<void> imgtestInit() async {
    // This client has already been intialized
    if (_initialized)
      return;

    final File keys = workDirectory.childFile('keys.json');
    final File failures = workDirectory.childFile('failures.json');

    await keys.writeAsString(_getKeysJSON());
    await failures.create();
    final String commitHash = await _getCurrentCommit();

    final List<String> imgtestInitCommand = <String>[
      _goldctl,
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

    if (imgtestInitCommand.contains(null)) {
      final StringBuffer buf = StringBuffer()
        ..writeln('A null argument was provided for Skia Gold imgtest init.')
        ..writeln('Please confirm the settings of your golden file test.')
        ..writeln('Arguments provided:');
      imgtestInitCommand.forEach(buf.writeln);
      throw Exception(buf.toString());
    }

    final io.ProcessResult result = await process.run(imgtestInitCommand);

    if (result.exitCode != 0) {
      _initialized = false;
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold imgtest init failed.')
        ..writeln('An error occurred when initializing golden file test with ')
        ..writeln('goldctl.')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      throw Exception(buf.toString());
    }
    _initialized = true;
  }

  /// Executes the `imgtest add` command in the goldctl tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test. A response is
  /// returned from the invocation of this command that indicates a pass or fail
  /// result.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated by the [FlutterPostSubmitFileComparator].
  Future<bool> imgtestAdd(String testName, File goldenFile) async {
    final List<String> imgtestCommand = <String>[
      _goldctl,
      'imgtest', 'add',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--test-name', cleanTestName(testName),
      '--png-file', goldenFile.path,
      '--passfail',
    ];

    final io.ProcessResult result = await process.run(imgtestCommand);

    if (result.exitCode != 0) {
      // If an unapproved image has made it to post-submit, throw to close the
      // tree.
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold received an unapproved image in post-submit ')
        ..writeln('testing. Golden file images in flutter/flutter are triaged ')
        ..writeln('in pre-submit during code review for the given PR.')
        ..writeln()
        ..writeln('Visit https://flutter-gold.skia.org/ to view and approve ')
        ..writeln('the image(s), or revert the associated change. For more ')
        ..writeln('information, visit the wiki: ')
        ..writeln('https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      // Temporarily print logs for issue diagnosis
      // ignore: avoid_print
      print(buf.toString());
      // TODO(Piinks): Re-enable once https://github.com/flutter/flutter/issues/100304
      // is resolved.
      // throw Exception(buf.toString());
    }

    return true;
  }

  /// Signals if this client is initialized for uploading tryjobs to the Gold
  /// service.
  ///
  /// Since Flutter framework tests are executed in parallel, and in random
  /// order, this will signal is this instance of the Gold client has been
  /// initialized for tryjobs.
  bool _tryjobInitialized = false;

  /// Executes the `imgtest init` command in the goldctl tool for tryjobs.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `init` argument initializes the current tryjob. Used by the
  /// [FlutterPreSubmitFileComparator].
  Future<void> tryjobInit() async {
    // This client has already been initialized
    if (_tryjobInitialized)
      return;

    final File keys = workDirectory.childFile('keys.json');
    final File failures = workDirectory.childFile('failures.json');

    await keys.writeAsString(_getKeysJSON());
    await failures.create();
    final String commitHash = await _getCurrentCommit();

    final List<String> imgtestInitCommand = <String>[
      _goldctl,
      'imgtest', 'init',
      '--instance', 'flutter',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--commit', commitHash,
      '--keys-file', keys.path,
      '--failure-file', failures.path,
      '--passfail',
      '--crs', 'github',
      '--patchset_id', commitHash,
      ...getCIArguments(),
    ];

    if (imgtestInitCommand.contains(null)) {
      final StringBuffer buf = StringBuffer()
        ..writeln('A null argument was provided for Skia Gold tryjob init.')
        ..writeln('Please confirm the settings of your golden file test.')
        ..writeln('Arguments provided:');
      imgtestInitCommand.forEach(buf.writeln);
      throw Exception(buf.toString());
    }

    final io.ProcessResult result = await process.run(imgtestInitCommand);

    if (result.exitCode != 0) {
      _tryjobInitialized = false;
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold tryjobInit failure.')
        ..writeln('An error occurred when initializing golden file tryjob with ')
        ..writeln('goldctl.')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      throw Exception(buf.toString());
    }
    _tryjobInitialized = true;
  }

  /// Executes the `imgtest add` command in the goldctl tool for tryjobs.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test. A response is
  /// returned from the invocation of this command that indicates a pass or fail
  /// result for the tryjob.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated by the [FlutterPreSubmitFileComparator].
  Future<void> tryjobAdd(String testName, File goldenFile) async {
    final List<String> imgtestCommand = <String>[
      _goldctl,
      'imgtest', 'add',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--test-name', cleanTestName(testName),
      '--png-file', goldenFile.path,
    ];

    final io.ProcessResult result = await process.run(imgtestCommand);

    final String/*!*/ resultStdout = result.stdout.toString();
    if (result.exitCode != 0 &&
      !(resultStdout.contains('Untriaged') || resultStdout.contains('negative image'))) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Unexpected Gold tryjobAdd failure.')
        ..writeln('Tryjob execution for golden file test $testName failed for')
        ..writeln('a reason unrelated to pixel comparison.')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}')
        ..writeln();
      throw Exception(buf.toString());
    }
  }

  /// Returns the latest positive digest for the given test known to Flutter
  /// Gold at head.
  Future<String?> getExpectationForTest(String testName) async {
    late String? expectation;
    final String traceID = getTraceID(testName);
    await io.HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final Uri requestForExpectations = Uri.parse(
        'https://flutter-gold.skia.org/json/v2/latestpositivedigest/$traceID'
      );
      late String rawResponse;
      try {
        final io.HttpClientRequest request = await httpClient.getUrl(requestForExpectations);
        final io.HttpClientResponse response = await request.close();
        rawResponse = await utf8.decodeStream(response);
        final dynamic jsonResponse = json.decode(rawResponse);
        if (jsonResponse is! Map<String, dynamic>)
          throw const FormatException('Skia gold expectations do not match expected format.');
        expectation = jsonResponse['digest'] as String?;
      } on FormatException catch (error) {
        // Ideally we'd use something like package:test's printOnError, but best reliabilty
        // in getting logs on CI for now we're just using print.
        // See also: https://github.com/flutter/flutter/issues/91285
        print( // ignore: avoid_print
          'Formatting error detected requesting expectations from Flutter Gold.\n'
          'error: $error\n'
          'url: $requestForExpectations\n'
          'response: $rawResponse'
        );
        rethrow;
      }
    },
      SkiaGoldHttpOverrides(),
    );
    return expectation;
  }

  /// Returns a list of bytes representing the golden image retrieved from the
  /// Flutter Gold dashboard.
  ///
  /// The provided image hash represents an expectation from Flutter Gold.
  Future<List<int>>getImageBytes(String imageHash) async {
    final List<int> imageBytes = <int>[];
    await io.HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final Uri requestForImage = Uri.parse(
        'https://flutter-gold.skia.org/img/images/$imageHash.png',
      );
      final io.HttpClientRequest request = await httpClient.getUrl(requestForImage);
      final io.HttpClientResponse response = await request.close();
      await response.forEach((List<int> bytes) => imageBytes.addAll(bytes));
    },
      SkiaGoldHttpOverrides(),
    );
    return imageBytes;
  }

  /// Returns the current commit hash of the Flutter repository.
  Future<String> _getCurrentCommit() async {
    if (!_flutterRoot.existsSync()) {
      throw Exception('Flutter root could not be found: $_flutterRoot\n');
    } else {
      final io.ProcessResult revParse = await process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: _flutterRoot.path,
      );
      if (revParse.exitCode != 0) {
        throw Exception('Current commit of Flutter can not be found.');
      }
      return (revParse.stdout as String/*!*/).trim();
    }
  }

  /// Returns a JSON String with keys value pairs used to uniquely identify the
  /// configuration that generated the given golden file.
  ///
  /// Currently, the only key value pairs being tracked is the platform the
  /// image was rendered on, and for web tests, the browser the image was
  /// rendered on.
  String _getKeysJSON() {
    final Map<String, dynamic> keys = <String, dynamic>{
      'Platform' : platform.operatingSystem,
      'CI' : 'luci',
    };
    if (platform.environment[_kTestBrowserKey] != null) {
      keys['Browser'] = platform.environment[_kTestBrowserKey];
      keys['Platform'] = '${keys['Platform']}-browser';
      if (platform.environment[_kWebRendererKey] == 'canvaskit') {
        keys['WebRenderer'] = 'canvaskit';
      }
    }
    return json.encode(keys);
  }

  /// Removes the file extension from the [fileName] to represent the test name
  /// properly.
  String cleanTestName(String fileName) {
    return fileName.split(path.extension(fileName))[0];
  }

  /// Returns a boolean value to prevent the client from re-authorizing itself
  /// for multiple tests.
  Future<bool> clientIsAuthorized() async {
    final File authFile = workDirectory.childFile(fs.path.join(
      'temp',
      'auth_opt.json',
    ))/*!*/;

    if(await authFile.exists()) {
      final String contents = await authFile.readAsString();
      final Map<String, dynamic> decoded = json.decode(contents) as Map<String, dynamic>;
      return !(decoded['GSUtil'] as bool/*!*/);
    }
    return false;
  }

  /// Returns a list of arguments for initializing a tryjob based on the testing
  /// environment.
  List<String> getCIArguments() {
    final String jobId = platform.environment['LOGDOG_STREAM_PREFIX']!.split('/').last;
    final List<String> refs = platform.environment['GOLD_TRYJOB']!.split('/');
    final String pullRequest = refs[refs.length - 2];

    return <String>[
      '--changelist', pullRequest,
      '--cis', 'buildbucket',
      '--jobid', jobId,
    ];
  }

  /// Returns a trace id based on the current testing environment to lookup
  /// the latest positive digest on Flutter Gold with a hex-encoded md5 hash of
  /// the image keys.
  String getTraceID(String testName) {
    final Map<String, dynamic> keys = <String, dynamic>{
      if (platform.environment[_kTestBrowserKey] != null)
        'Browser' : platform.environment[_kTestBrowserKey],
      if (platform.environment[_kTestBrowserKey] != null && platform.environment[_kWebRendererKey] == 'canvaskit')
        'WebRenderer' : 'canvaskit',
      'CI' : 'luci',
      'Platform' : platform.operatingSystem,
      'name' : testName,
      'source_type' : 'flutter',
    };
    final String jsonTrace = json.encode(keys);
    final String md5Sum = md5.convert(utf8.encode(jsonTrace)).toString();
    return md5Sum;
  }
}

/// Used to make HttpRequests during testing.
class SkiaGoldHttpOverrides extends io.HttpOverrides { }

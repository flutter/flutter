// Copyright 2014 The Flutter Authors. All rights reserved.
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
const String _kTestBrowserKey = 'FLUTTER_TEST_BROWSER';

/// A client for uploading image tests and making baseline requests to the
/// Flutter Gold Dashboard.
class SkiaGoldClient {
  SkiaGoldClient(
    this.workDirectory, {
    this.fs = const LocalFileSystem(),
    this.process = const LocalProcessManager(),
    this.platform = const LocalPlatform(),
    io.HttpClient httpClient,
  }) : assert(workDirectory != null),
       assert(fs != null),
       assert(process != null),
       assert(platform != null),
       httpClient = httpClient ?? io.HttpClient();

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

  /// A controller for launching sub-processes.
  ///
  /// This is useful in tests, where the real process manager (the default)
  /// can be replaced by a mock process manager that doesn't really create
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

  /// A map of known golden file tests and their associated positive image
  /// hashes.
  ///
  /// This is set and used by the [FlutterLocalFileComparator] and
  /// [FlutterPreSubmitFileComparator] to test against golden masters maintained
  /// in the Flutter Gold dashboard.
  Map<String, List<String>> get expectations => _expectations;
  Map<String, List<String>> _expectations;

  /// The local [Directory] where the Flutter repository is hosted.
  ///
  /// Uses the [fs] file system.
  Directory get _flutterRoot => fs.directory(platform.environment[_kFlutterRootKey]);

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
  Future<void> auth() async {
    if (_clientIsAuthorized())
      return;

    if (_serviceAccount.isEmpty) {
      final StringBuffer buf = StringBuffer()
        ..writeln('The Gold service account is unavailable.')
        ..writeln('Without a service account, Gold can not be authorized.')
        ..writeln('Please check your user permissions and current comparator.');
      throw Exception(buf.toString());
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

    final io.ProcessResult result = await io.Process.run(
      _goldctl,
      authArguments,
    );

    if (result.exitCode != 0) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold authorization failed.')
        ..writeln('This could be caused by incorrect user permissions, if the ')
        ..writeln('debug information below contains ENCRYPTED, the wrong ')
        ..writeln('comparator was chosen for the test case.')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      throw Exception(buf.toString());
    }
  }

  /// Prepares the local work space for an unauthorized client to lookup golden
  /// file expectations using [imgtestCheck].
  ///
  /// It will only be called once for each instance of an
  /// [_UnauthorizedFlutterPreSubmitComparator].
  Future<void> emptyAuth() async {
    final List<String> authArguments = <String>[
      'auth',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
    ];

    final io.ProcessResult result = await io.Process.run(
      _goldctl,
      authArguments,
    );

    if (result.exitCode != 0) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold emptyAuth failed.')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      throw Exception(buf.toString());
    }
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
        ..writeln('A null argument was provided for Skia Gold imgtest init.')
        ..writeln('Please confirm the settings of your golden file test.')
        ..writeln('Arguments provided:');
      imgtestInitArguments.forEach(buf.writeln);
      throw Exception(buf.toString());
    }

    final io.ProcessResult result = await io.Process.run(
      _goldctl,
      imgtestInitArguments,
    );

    if (result.exitCode != 0) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold imgtest init failed.')
        ..writeln('An error occured when initializing golden file test with ')
        ..writeln('goldctl.')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      throw Exception(buf.toString());
    }
  }

  /// Executes the `imgtest add` command in the goldctl tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test. A response is
  /// returned from the invocation of this command that indicates a pass or fail
  /// result.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated by the [FlutterSkiaGoldFileComparator].
  Future<bool> imgtestAdd(String testName, File goldenFile) async {
    assert(testName != null);
    assert(goldenFile != null);

    final List<String> imgtestArguments = <String>[
      'imgtest', 'add',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--test-name', cleanTestName(testName),
      '--png-file', goldenFile.path,
    ];

    final io.ProcessResult result = await io.Process.run(
      _goldctl,
      imgtestArguments,
    );

    if (result.exitCode != 0) {
      // We do not want to throw for non-zero exit codes here, as an intentional
      // change or new golden file test expect non-zero exit codes. Logging here
      // is meant to inform when an unexpected result occurs.
      print('goldctl imgtest add stdout: ${result.stdout}');
      print('goldctl imgtest add stderr: ${result.stderr}');
    }

    return true;
  }

  /// Executes the `imgtest init` command in the goldctl tool for tryjobs.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `init` argument initializes the current tryjob.
  Future<void> tryjobInit() async {
    final File keys = workDirectory.childFile('keys.json');
    final File failures = workDirectory.childFile('failures.json');

    await keys.writeAsString(_getKeysJSON());
    await failures.create();
    final String commitHash = await _getCurrentCommit();
    final String pullRequest = platform.environment['CIRRUS_PR'];
    final String cirrusTaskID = platform.environment['CIRRUS_TASK_ID'];


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
      '--crs', 'github',
      '--changelist', pullRequest,
      '--cis', 'cirrus',
      '--jobid', cirrusTaskID,
      '--patchset_id', commitHash,
    ];

    if (imgtestInitArguments.contains(null)) {
      final StringBuffer buf = StringBuffer()
        ..writeln('A null argument was provided for Skia Gold tryjob init.')
        ..writeln('Please confirm the settings of your golden file test.')
        ..writeln('Arguments provided:');
      imgtestInitArguments.forEach(buf.writeln);
      throw Exception(buf.toString());
    }

    final io.ProcessResult result = await io.Process.run(
      _goldctl,
      imgtestInitArguments,
    );

    if (result.exitCode != 0) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Skia Gold tryjobInit failure.')
        ..writeln('An error occured when initializing golden file tryjob with ')
        ..writeln('goldctl.')
        ..writeln()
        ..writeln('Debug information for Gold:')
        ..writeln('stdout: ${result.stdout}')
        ..writeln('stderr: ${result.stderr}');
      throw Exception(buf.toString());
    }
  }

  /// Executes the `imgtest add` command in the goldctl tool for tryjobs.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test. A response is
  /// returned from the invocation of this command that indicates a pass or fail
  /// result for the tryjob.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated by the [_AuthorizedFlutterPreSubmitComparator].
  Future<bool> tryjobAdd(String testName, File goldenFile) async {
    assert(testName != null);
    assert(goldenFile != null);

    final List<String> imgtestArguments = <String>[
      'imgtest', 'add',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--test-name', cleanTestName(testName),
      '--png-file', goldenFile.path,
    ];

    final io.ProcessResult result = await io.Process.run(
      _goldctl,
      imgtestArguments,
    );

    if (result.exitCode != 0) {
      final String resultStdout = result.stdout.toString();
      if (resultStdout.contains('Untriaged') || resultStdout.contains('negative image')) {
        final List<String> failureLinks = await workDirectory.childFile('failures.json').readAsLines();

        final StringBuffer buf = StringBuffer()
          ..writeln('The golden file "$testName" ')
          ..writeln('did not match the expected image.')
          ..writeln('To view the closest matching image, the actual image generated, ')
          ..writeln('and the visual difference, visit: ')
          ..writeln(failureLinks.last)
          ..writeln('There you can also triage this image (e.g. because this ')
          ..writeln('is an intentional change).')
          ..writeln();
        throw Exception(buf.toString());
      } else {
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

    return result.exitCode == 0;
  }

  /// Executes the `imgtest check` command in the goldctl tool for unauthorized
  /// clients.
  ///
  /// Using the `check` command hashes the current test images and checks that
  /// hash against Gold's known expectation hashes. A response is returned from
  /// the invocation of this command that indicates a pass or fail result,
  /// indicating if Gold has seen this image before.
  ///
  /// This will not allow for state change on the Gold dashboard, it is
  /// essentially a lookup function. If an unauthorized change needs to be made,
  /// use Gold's ignore feature.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated by the
  /// [_UnauthorizedFlutterPreSubmitComparator].
  Future<bool> imgtestCheck(String testName, File goldenFile) async {
    assert(testName != null);
    assert(goldenFile != null);

    final List<String> imgtestArguments = <String>[
      'imgtest', 'check',
      '--work-dir', workDirectory
        .childDirectory('temp')
        .path,
      '--test-name', cleanTestName(testName),
      '--png-file', goldenFile.path,
      '--instance', 'flutter',
    ];

    final io.ProcessResult result = await io.Process.run(
      _goldctl,
      imgtestArguments,
    );

    return result.exitCode == 0;
  }

  /// Requests and sets the [_expectations] known to Flutter Gold at head.
  Future<void> getExpectations() async {
    _expectations = <String, List<String>>{};
    await io.HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final Uri requestForExpectations = Uri.parse(
        'https://flutter-gold.skia.org/json/expectations/commit/HEAD'
      );
      String rawResponse;
      try {
        final io.HttpClientRequest request = await httpClient.getUrl(requestForExpectations);
        final io.HttpClientResponse response = await request.close();
        rawResponse = await utf8.decodeStream(response);
        final Map<String, dynamic> skiaJson = json.decode(rawResponse)['master'] as Map<String, dynamic>;

        skiaJson.forEach((String key, dynamic value) {
          final Map<String, dynamic> hashesMap = value as Map<String, dynamic>;
          _expectations[key] = hashesMap.keys.toList();
        });
      } on FormatException catch(_) {
        print('Formatting error detected requesting expectations from Flutter Gold.\n'
          'rawResponse: $rawResponse');
        rethrow;
      }
    },
      SkiaGoldHttpOverrides(),
    );
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

      try {
        final io.HttpClientRequest request = await httpClient.getUrl(requestForImage);
        final io.HttpClientResponse response = await request.close();
        await response.forEach((List<int> bytes) => imageBytes.addAll(bytes));

      } catch(e) {
        rethrow;
      }
    },
      SkiaGoldHttpOverrides(),
    );
    return imageBytes;
  }

  /// Returns a boolean value for whether or not the given test and current pull
  /// request are ignored on Flutter Gold.
  ///
  /// This is only relevant when used by the [FlutterPreSubmitFileComparator]
  /// when a golden file test fails. In order to land a change to an existing
  /// golden file, an ignore must be set up in Flutter Gold. This will serve as
  /// a flag to permit the change to land, protect against any unwanted changes,
  /// and ensure that changes that have landed are triaged.
  Future<bool> testIsIgnoredForPullRequest(String pullRequest, String testName) async {
    bool ignoreIsActive = false;
    testName = cleanTestName(testName);
    String rawResponse;
    await io.HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final Uri requestForIgnores = Uri.parse(
        'https://flutter-gold.skia.org/json/ignores'
      );

      try {
        final io.HttpClientRequest request = await httpClient.getUrl(requestForIgnores);
        final io.HttpClientResponse response = await request.close();
        rawResponse = await utf8.decodeStream(response);
        final List<dynamic> ignores = json.decode(rawResponse) as List<dynamic>;
        for(final dynamic ignore in ignores) {
          final List<String> ignoredQueries = (ignore['query'] as String).split('&');
          final String ignoredPullRequest = (ignore['note'] as String).split('/').last;
          final DateTime expiration = DateTime.parse(ignore['expires'] as String);
          // The currently failing test is in the process of modification.
          if (ignoredQueries.contains('name=$testName')) {
            if (expiration.isAfter(DateTime.now())) {
              ignoreIsActive = true;
            } else {
              // If any ignore is expired for the given test, throw with
              // guidance.
              final StringBuffer buf = StringBuffer()
                ..writeln('This test has an expired ignore in place, and the')
                ..writeln('change has not been triaged.')
                ..writeln('The associated pull request is:')
                ..writeln('https://github.com/flutter/flutter/pull/$ignoredPullRequest');
              throw Exception(buf.toString());
            }
          }
        }
      } on FormatException catch(_) {
        if (rawResponse.contains('stream timeout')) {
          final StringBuffer buf = StringBuffer()
            ..writeln('Stream timeout on /ignores api.')
            ..writeln('This may be caused by a failure to triage a change.')
            ..writeln('Check https://flutter-gold.skia.org/ignores, or')
            ..writeln('https://flutter-gold.skia.org/?query=source_type%3Dflutter')
            ..writeln('for untriaged golden files.');
          throw Exception(buf.toString());
        } else {
          print('Formatting error detected requesting /ignores from Flutter Gold.'
            '\nrawResponse: $rawResponse');
          rethrow;
        }
      }
    },
      SkiaGoldHttpOverrides(),
    );
    return ignoreIsActive;
  }

  /// The [_expectations] retrieved from Flutter Gold do not include the
  /// parameters of the given test. This function queries the Flutter Gold
  /// details api to determine if the given expectation for a test matches the
  /// configuration of the executing machine.
  Future<bool> isValidDigestForExpectation(String expectation, String testName) async {
    bool isValid = false;
    testName = cleanTestName(testName);
    String rawResponse;
    await io.HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final Uri requestForDigest = Uri.parse(
        'https://flutter-gold.skia.org/json/details?test=$testName&digest=$expectation'
      );

      try {
        final io.HttpClientRequest request = await httpClient.getUrl(requestForDigest);
        final io.HttpClientResponse response = await request.close();
        rawResponse = await utf8.decodeStream(response);
        final Map<String, dynamic> skiaJson = json.decode(rawResponse) as Map<String, dynamic>;
        final SkiaGoldDigest digest = SkiaGoldDigest.fromJson(skiaJson['digest'] as Map<String, dynamic>);
        isValid = digest.isValid(platform, testName, expectation);

      } on FormatException catch(_) {
        if (rawResponse.contains('stream timeout')) {
          final StringBuffer buf = StringBuffer()
            ..writeln('Stream timeout on Gold\'s /details api.');
          throw Exception(buf.toString());
        } else {
          print('Formatting error detected requesting /ignores from Flutter Gold.'
            '\nrawResponse: $rawResponse');
          rethrow;
        }
      }
    },
      SkiaGoldHttpOverrides(),
    );
    return isValid;
  }

  /// Returns the current commit hash of the Flutter repository.
  Future<String> _getCurrentCommit() async {
    if (!_flutterRoot.existsSync()) {
      final StringBuffer buf = StringBuffer()
        ..writeln('Flutter root could not be found: $_flutterRoot');
      throw Exception(buf.toString());
    } else {
      final io.ProcessResult revParse = await process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: _flutterRoot.path,
      );
      return revParse.exitCode == 0 ? (revParse.stdout as String).trim() : null;
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
    };
    if (platform.environment[_kTestBrowserKey] != null)
      keys['Browser'] = platform.environment[_kTestBrowserKey];
    return json.encode(keys);
  }

  /// Removes the file extension from the [fileName] to represent the test name
  /// properly.
  String cleanTestName(String fileName) {
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

/// Used to make HttpRequests during testing.
class SkiaGoldHttpOverrides extends io.HttpOverrides {}

/// A digest returned from a request to the Flutter Gold dashboard.
class SkiaGoldDigest {
  const SkiaGoldDigest({
    this.imageHash,
    this.paramSet,
    this.testName,
    this.status,
  });

  /// Create a digest from requested JSON.
  factory SkiaGoldDigest.fromJson(Map<String, dynamic> json) {
    if (json == null)
      return null;

    return SkiaGoldDigest(
      imageHash: json['digest'] as String,
      paramSet: Map<String, dynamic>.from(json['paramset'] as Map<String, dynamic> ??
        <String, List<String>>{'Platform': <String>[]}),
      testName: json['test'] as String,
      status: json['status'] as String,
    );
  }

  /// Unique identifier for the image associated with the digest.
  final String imageHash;

  /// Parameter set for the given test, e.g. Platform : Windows.
  final Map<String, dynamic> paramSet;

  /// Test name associated with the digest, e.g. positive or un-triaged.
  final String testName;

  /// Status of the given digest, e.g. positive or un-triaged.
  final String status;

  /// Validates a given digest against the current testing conditions.
  bool isValid(Platform platform, String name, String expectation) {
    return imageHash == expectation
      && (paramSet['Platform'] as List<dynamic>).contains(platform.operatingSystem)
      && (platform.environment[_kTestBrowserKey] == null
         || paramSet['Browser'] == platform.environment[_kTestBrowserKey])
      && testName == name
      && status == 'positive';
  }
}

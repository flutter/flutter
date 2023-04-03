// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

const String _kGoldctlKey = 'GOLDCTL';
const String _kPresubmitEnvName = 'GOLD_TRYJOB';
const String _kLuciEnvName = 'LUCI_CONTEXT';

const String _skiaGoldHost = 'https://flutter-engine-gold.skia.org';
const String _instance = 'flutter-engine';

/// Whether the Skia Gold client is available and can be used in this
/// environment.
bool get isSkiaGoldClientAvailable => Platform.environment.containsKey(_kGoldctlKey);

/// Returns true if the current environment is a LUCI builder.
bool get isLuciEnv => Platform.environment.containsKey(_kLuciEnvName);

/// Whether the current task is run during a presubmit check.
bool get _isPresubmit => isLuciEnv && isSkiaGoldClientAvailable && Platform.environment.containsKey(_kPresubmitEnvName);

/// Whether the current task is run during a postsubmit check.
bool get _isPostsubmit => isLuciEnv && isSkiaGoldClientAvailable && !Platform.environment.containsKey(_kPresubmitEnvName);

/// A client for uploading image tests and making baseline requests to the
/// Flutter Gold Dashboard.
class SkiaGoldClient {
  /// Creates a [SkiaGoldClient] with the given [workDirectory].
  ///
  /// [dimensions] allows to add attributes about the environment
  /// used to generate the screenshots.
  SkiaGoldClient(this.workDirectory, { this.dimensions });

  /// Allows to add attributes about the environment used to generate the screenshots.
  final Map<String, String>? dimensions;

  /// A controller for launching sub-processes.
  final ProcessManager process = const LocalProcessManager();

  /// A client for making Http requests to the Flutter Gold dashboard.
  final HttpClient httpClient = HttpClient();

  /// The local [Directory] for the current test context. In this directory, the
  /// client will create image and JSON files for the `goldctl` tool to use.
  final Directory workDirectory;

  String get _tempPath => path.join(workDirectory.path, 'temp');
  String get _keysPath => path.join(workDirectory.path, 'keys.json');
  String get _failuresPath => path.join(workDirectory.path, 'failures.json');

  /// Indicates whether the `goldctl` tool has been initialized for the current
  /// test context.
  bool _isInitialized = false;

  /// Indicates whether the client has already been authorized to communicate
  /// with the Skia Gold backend.
  bool get _isAuthorized {
    final File authFile = File(path.join(_tempPath, 'auth_opt.json'));

    if(authFile.existsSync()) {
      final String contents = authFile.readAsStringSync();
      final Map<String, dynamic> decoded = json.decode(contents) as Map<String, dynamic>;
      return !(decoded['GSUtil'] as bool);
    }
    return false;
  }

  /// The path to the local [Directory] where the `goldctl` tool is hosted.
  String get _goldctl {
    assert(
      isSkiaGoldClientAvailable,
      'Trying to use `goldctl` in an environment where it is not available',
    );
    return Platform.environment[_kGoldctlKey]!;
  }

  /// Prepares the local work space for golden file testing and calls the
  /// `goldctl auth` command.
  ///
  /// This ensures that the `goldctl` tool is authorized and ready for testing.
  Future<void> auth() async {
    if (_isAuthorized) {
      return;
    }
    final List<String> authCommand = <String>[
      _goldctl,
      'auth',
      '--work-dir', _tempPath,
      '--luci',
    ];

    final ProcessResult result = await _runCommand(authCommand);

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

  Future<ProcessResult> _runCommand(List<String> command) {
    print(command.join(' '));
    return process.run(command);
  }

  /// Executes the `imgtest init` command in the `goldctl` tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `init` argument initializes the current test.
  Future<void> _imgtestInit() async {
    if (_isInitialized) {
      return;
    }

    final File keys = File(_keysPath);
    final File failures = File(_failuresPath);

    await keys.writeAsString(_getKeysJSON());
    await failures.create();
    final String commitHash = await _getCurrentCommit();

    final List<String> imgtestInitCommand = <String>[
      _goldctl,
      'imgtest', 'init',
      '--instance', _instance,
      '--work-dir', _tempPath,
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

    final ProcessResult result = await _runCommand(imgtestInitCommand);

    if (result.exitCode != 0) {
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
    _isInitialized = true;
  }

  /// Executes the `imgtest add` command in the `goldctl` tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test.
  ///
  /// Throws an exception for try jobs that failed to pass the pixel comparison.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated.
  ///
  /// [pixelColorDelta] defines maximum acceptable difference in RGB channels of
  /// each pixel, such that:
  ///
  /// ```
  /// bool isSame(Color image, Color golden, int pixelDeltaThreshold) {
  ///   return abs(image.r - golden.r)
  ///     + abs(image.g - golden.g)
  ///     + abs(image.b - golden.b) <= pixelDeltaThreshold;
  /// }
  /// ```
  ///
  /// [differentPixelsRate] is the fraction of pixels that can differ, as
  /// determined by the [pixelColorDelta] parameter. It's in the range [0.0,
  /// 1.0] and defaults to 0.01. A value of 0.01 means that 1% of the pixels are
  /// allowed to be different.
  Future<void> addImg(
    String testName,
    File goldenFile, {
    double differentPixelsRate = 0.01,
    int pixelColorDelta = 0,
    required int screenshotSize,
  }) async {
    assert(_isPresubmit || _isPostsubmit);

    if (_isPresubmit) {
      await _tryjobAdd(testName, goldenFile, screenshotSize, pixelColorDelta, differentPixelsRate);
    }
    if (_isPostsubmit) {
      await _imgtestAdd(testName, goldenFile, screenshotSize, pixelColorDelta, differentPixelsRate);
    }
  }

  /// Executes the `imgtest add` command in the `goldctl` tool.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test. A response is
  /// returned from the invocation of this command that indicates a pass or fail
  /// result.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated.
  Future<void> _imgtestAdd(
    String testName,
    File goldenFile,
    int screenshotSize,
    int pixelDeltaThreshold,
    double maxDifferentPixelsRate,
  ) async {
    await _imgtestInit();

    final List<String> imgtestCommand = <String>[
      _goldctl,
      'imgtest', 'add',
      '--work-dir', _tempPath,
      '--test-name', cleanTestName(testName),
      '--png-file', goldenFile.path,
      ..._getMatchingArguments(testName, screenshotSize, pixelDeltaThreshold, maxDifferentPixelsRate),
    ];

    final ProcessResult result = await _runCommand(imgtestCommand);

    if (result.exitCode != 0) {
      // We do not want to throw for non-zero exit codes here, as an intentional
      // change or new golden file test expect non-zero exit codes. Logging here
      // is meant to inform when an unexpected result occurs.
      print('goldctl imgtest add stdout: ${result.stdout}');
      print('goldctl imgtest add stderr: ${result.stderr}');
    }
  }

  /// Executes the `imgtest init` command in the `goldctl` tool for tryjobs.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `init` argument initializes the current tryjob.
  Future<void> _tryjobInit() async {
    if (_isInitialized) {
      return;
    }

    final File keys = File(_keysPath);
    final File failures = File(_failuresPath);

    await keys.writeAsString(_getKeysJSON());
    await failures.create();
    final String commitHash = await _getCurrentCommit();

    final List<String> tryjobInitCommand = <String>[
      _goldctl,
      'imgtest', 'init',
      '--instance', _instance,
      '--work-dir', _tempPath,
      '--commit', commitHash,
      '--keys-file', keys.path,
      '--failure-file', failures.path,
      '--passfail',
      '--crs', 'github',
      '--patchset_id', commitHash,
      ...getCIArguments(),
    ];

    if (tryjobInitCommand.contains(null)) {
      final StringBuffer buf = StringBuffer()
        ..writeln('A null argument was provided for Skia Gold tryjob init.')
        ..writeln('Please confirm the settings of your golden file test.')
        ..writeln('Arguments provided:');
      tryjobInitCommand.forEach(buf.writeln);
      throw Exception(buf.toString());
    }

    final ProcessResult result = await _runCommand(tryjobInitCommand);

    if (result.exitCode != 0) {
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
    _isInitialized = true;
  }

  /// Executes the `imgtest add` command in the `goldctl` tool for tryjobs.
  ///
  /// The `imgtest` command collects and uploads test results to the Skia Gold
  /// backend, the `add` argument uploads the current image test. A response is
  /// returned from the invocation of this command that indicates a pass or fail
  /// result for the tryjob.
  ///
  /// The [testName] and [goldenFile] parameters reference the current
  /// comparison being evaluated.
  Future<void> _tryjobAdd(
    String testName,
    File goldenFile,
    int screenshotSize,
    int pixelDeltaThreshold,
    double differentPixelsRate,
  ) async {
    await _tryjobInit();

    final List<String> tryjobCommand = <String>[
      _goldctl,
      'imgtest', 'add',
      '--work-dir', _tempPath,
      '--test-name', cleanTestName(testName),
      '--png-file', goldenFile.path,
      ..._getMatchingArguments(testName, screenshotSize, pixelDeltaThreshold, differentPixelsRate),
    ];

    final ProcessResult result = await _runCommand(tryjobCommand);

    final String resultStdout = result.stdout.toString();
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

  List<String> _getMatchingArguments(
    String testName,
    int screenshotSize,
    int pixelDeltaThreshold,
    double differentPixelsRate,
  ) {
    // The algorithm to be used when matching images. The available options are:
    // - "fuzzy": Allows for customizing the thresholds of pixel differences.
    // - "sobel": Same as "fuzzy" but performs edge detection before performing
    //            a fuzzy match.
    const String algorithm = 'fuzzy';

    // The number of pixels in this image that are allowed to differ from the
    // baseline. It's okay for this to be a slightly high number like 10% of the
    // image size because those wrong pixels are constrained by
    // `pixelDeltaThreshold` below.
    final int maxDifferentPixels = (screenshotSize * differentPixelsRate).toInt();
    return <String>[
      '--add-test-optional-key', 'image_matching_algorithm:$algorithm',
      '--add-test-optional-key', 'fuzzy_max_different_pixels:$maxDifferentPixels',
      '--add-test-optional-key', 'fuzzy_pixel_delta_threshold:$pixelDeltaThreshold',
    ];
  }

  /// Returns the latest positive digest for the given test known to Skia Gold
  /// at head.
  Future<String?> getExpectationForTest(String testName) async {
    late String? expectation;
    final String traceID = getTraceID(testName);
    await HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final Uri requestForExpectations = Uri.parse(
        '$_skiaGoldHost/json/v2/latestpositivedigest/$traceID'
      );
      late String rawResponse;
      try {
        final HttpClientRequest request = await httpClient.getUrl(requestForExpectations);
        final HttpClientResponse response = await request.close();
        rawResponse = await utf8.decodeStream(response);
        final dynamic jsonResponse = json.decode(rawResponse);
        if (jsonResponse is! Map<String, dynamic>) {
          throw const FormatException('Skia gold expectations do not match expected format.');
        }
        expectation = jsonResponse['digest'] as String?;
      } on FormatException catch (error) {
        print(
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
  /// Skia Gold dashboard.
  ///
  /// The provided image hash represents an expectation from Skia Gold.
  Future<List<int>>getImageBytes(String imageHash) async {
    final List<int> imageBytes = <int>[];
    await HttpOverrides.runWithHttpOverrides<Future<void>>(() async {
      final Uri requestForImage = Uri.parse(
        '$_skiaGoldHost/img/images/$imageHash.png',
      );

      final HttpClientRequest request = await httpClient.getUrl(requestForImage);
      final HttpClientResponse response = await request.close();
      await response.forEach((List<int> bytes) => imageBytes.addAll(bytes));
    },
      SkiaGoldHttpOverrides(),
    );
    return imageBytes;
  }

  /// Returns the current commit hash of the engine repository.
  Future<String> _getCurrentCommit() async {
    final File currentScript = File.fromUri(Platform.script);
    final ProcessResult revParse = await process.run(
      <String>['git', 'rev-parse', 'HEAD'],
      workingDirectory: currentScript.parent.absolute.path,
    );
    if (revParse.exitCode != 0) {
      throw Exception('Current commit of the engine can not be found from path ${currentScript.path}.');
    }
    return (revParse.stdout as String).trim();
  }

  /// Returns a Map of key value pairs used to uniquely identify the
  /// configuration that generated the given golden file.
  ///
  /// Currently, the only key value pairs being tracked are the platform and
  /// browser the image was rendered on.
  Map<String, dynamic> _getKeys() {
    final Map<String, dynamic> initialKeys = <String, dynamic>{
      'CI': 'luci',
      'Platform': Platform.operatingSystem,
    };
    if (dimensions != null) {
      initialKeys.addAll(dimensions!);
    }
    return initialKeys;
  }

  /// Same as [_getKeys] but encodes it in a JSON string.
  String _getKeysJSON() {
    return json.encode(_getKeys());
  }

  /// Removes the file extension from the [fileName] to represent the test name
  /// properly.
  String cleanTestName(String fileName) {
    return fileName.split(path.extension(fileName))[0];
  }

  /// Returns a list of arguments for initializing a tryjob based on the testing
  /// environment.
  List<String> getCIArguments() {
    final String jobId = Platform.environment['LOGDOG_STREAM_PREFIX']!.split('/').last;
    final List<String> refs = Platform.environment['GOLD_TRYJOB']!.split('/');
    final String pullRequest = refs[refs.length - 2];

    return <String>[
      '--changelist', pullRequest,
      '--cis', 'buildbucket',
      '--jobid', jobId,
    ];
  }

  /// Returns a trace id based on the current testing environment to lookup
  /// the latest positive digest on Skia Gold with a hex-encoded md5 hash of
  /// the image keys.
  String getTraceID(String testName) {
    final Map<String, dynamic> keys = <String, dynamic>{
      ..._getKeys(),
      'name': testName,
      'source_type': _instance,
    };
    final String jsonTrace = json.encode(keys);
    final String md5Sum = md5.convert(utf8.encode(jsonTrace)).toString();
    return md5Sum;
  }
}

/// Used to make HttpRequests during testing.
class SkiaGoldHttpOverrides extends HttpOverrides { }

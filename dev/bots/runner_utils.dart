// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(sigmund): includeLocalEngineEnv should default to true. Currently we
// only enable it on flutter-web test because some test suites do not work
// properly when overriding the local engine (for example, because some platform
// dependent targets are only built on some engines).
// See https://github.com/flutter/flutter/issues/72368
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file/file.dart' as fs;
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import 'run_command.dart';
import 'tool_subsharding.dart';
import 'utils.dart';

final String exe = Platform.isWindows ? '.exe' : '';
final String bat = Platform.isWindows ? '.bat' : '';
final String flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String flutter = path.join(flutterRoot, 'bin', 'flutter$bat');
final String dart = path.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart$exe');
final String pubCache = path.join(flutterRoot, '.pub-cache');
final String engineVersionFile = path.join(flutterRoot, 'bin', 'internal', 'engine.version');

const String kSubshardKey = 'SUBSHARD';

/// Environment variables to override the local engine when running `pub test`,
/// if such flags are provided to `test.dart`.
final Map<String,String> localEngineEnv = <String, String>{};


// The seed used to shuffle tests. If not passed with
// --test-randomize-ordering-seed=<seed> on the command line, it will be set the
// first time it is accessed. Pass zero to turn off shuffling.
String? _shuffleSeed;
String get shuffleSeed {
  if (_shuffleSeed == null) {
    // Change the seed at 7am, UTC.
    final DateTime seedTime = DateTime.now().toUtc().subtract(const Duration(hours: 7));
    // Generates YYYYMMDD as the seed, so that testing continues to fail for a
    // day after the seed changes, and on other days the seed can be used to
    // replicate failures.
    _shuffleSeed = '${seedTime.year * 10000 + seedTime.month * 100 + seedTime.day}';
  }
  return _shuffleSeed!;
}

Future<void> runDartTest(String workingDirectory, {
  List<String>? testPaths,
  bool enableFlutterToolAsserts = true,
  bool useBuildRunner = false,
  String? coverage,
  bool forceSingleCore = false,
  Duration? perTestTimeout,
  bool includeLocalEngineEnv = false,
  bool ensurePrecompiledTool = true,
  bool shuffleTests = true,
  bool collectMetrics = false,
}) async {
  int? cpus;
  final String? cpuVariable = Platform.environment['CPU']; // CPU is set in cirrus.yml
  if (cpuVariable != null) {
    cpus = int.tryParse(cpuVariable, radix: 10);
    if (cpus == null) {
      foundError(<String>[
        '${red}The CPU environment variable, if set, must be set to the integer number of available cores.$reset',
        'Actual value: "$cpuVariable"',
      ]);
      return;
    }
  } else {
    cpus = 2; // Don't default to 1, otherwise we won't catch race conditions.
  }
  // Integration tests that depend on external processes like chrome
  // can get stuck if there are multiple instances running at once.
  if (forceSingleCore) {
    cpus = 1;
  }

  const LocalFileSystem fileSystem = LocalFileSystem();
  final String suffix = DateTime.now().microsecondsSinceEpoch.toString();
  final File metricFile = fileSystem.systemTempDirectory.childFile('metrics_$suffix.json');
  final List<String> args = <String>[
    'run',
    'test',
    '--reporter=expanded',
    '--file-reporter=json:${metricFile.path}',
    if (shuffleTests) '--test-randomize-ordering-seed=$shuffleSeed',
    '-j$cpus',
    if (!hasColor)
      '--no-color',
    if (coverage != null)
      '--coverage=$coverage',
    if (perTestTimeout != null)
      '--timeout=${perTestTimeout.inMilliseconds}ms',
    if (testPaths != null)
      for (final String testPath in testPaths)
        testPath,
  ];
  final Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': flutterRoot,
    if (includeLocalEngineEnv)
      ...localEngineEnv,
    if (Directory(pubCache).existsSync())
      'PUB_CACHE': pubCache,
  };
  if (enableFlutterToolAsserts) {
    adjustEnvironmentToEnableFlutterAsserts(environment);
  }
  if (ensurePrecompiledTool) {
    // We rerun the `flutter` tool here just to make sure that it is compiled
    // before tests run, because the tests might time out if they have to rebuild
    // the tool themselves.
    await runCommand(flutter, <String>['--version'], environment: environment);
  }
  await runCommand(
    dart,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
    removeLine: useBuildRunner ? (String line) => line.startsWith('[INFO]') : null,
  );

  final TestFileReporterResults test = TestFileReporterResults.fromFile(metricFile); // --file-reporter name
  final File info = fileSystem.file(path.join(flutterRoot, 'error.log'));
  info.writeAsStringSync(json.encode(test.errors));

  if (collectMetrics) {
    try {
      final List<String> testList = <String>[];
      final Map<int, TestSpecs> allTestSpecs = test.allTestSpecs;
      for (final TestSpecs testSpecs in allTestSpecs.values) {
        testList.add(testSpecs.toJson());
      }
      if (testList.isNotEmpty) {
        final String testJson = json.encode(testList);
        final File testResults = fileSystem.file(
            path.join(flutterRoot, 'test_results.json'));
        testResults.writeAsStringSync(testJson);
      }
    } on fs.FileSystemException catch (e) {
      print('Failed to generate metrics: $e');
    }
  }

  // metriciFile is a transitional file that needs to be deleted once it is parsed.
  // TODO(godofredoc): Ensure metricFile is parsed and aggregated before deleting.
  // https://github.com/flutter/flutter/issues/146003
  metricFile.deleteSync();
}

/// This will force the next run of the Flutter tool (if it uses the provided
/// environment) to have asserts enabled, by setting an environment variable.
void adjustEnvironmentToEnableFlutterAsserts(Map<String, String> environment) {
  // If an existing env variable exists append to it, but only if
  // it doesn't appear to already include enable-asserts.
  String toolsArgs = Platform.environment['FLUTTER_TOOL_ARGS'] ?? '';
  if (!toolsArgs.contains('--enable-asserts')) {
    toolsArgs += ' --enable-asserts';
  }
  environment['FLUTTER_TOOL_ARGS'] = toolsArgs.trim();
}

/// Parse (one-)index/total-named subshards from environment variable SUBSHARD
/// and equally distribute [tests] between them.
/// Subshard format is "{index}_{total number of shards}".
/// The scheduler can change the number of total shards without needing an additional
/// commit in this repository.
///
/// Examples:
/// 1_3
/// 2_3
/// 3_3
List<T> selectIndexOfTotalSubshard<T>(List<T> tests, {String subshardKey = kSubshardKey}) {
  // Example: "1_3" means the first (one-indexed) shard of three total shards.
  final String? subshardName = Platform.environment[subshardKey];
  if (subshardName == null) {
    print('$kSubshardKey environment variable is missing, skipping sharding');
    return tests;
  }
  printProgress('$bold$subshardKey=$subshardName$reset');

  final RegExp pattern = RegExp(r'^(\d+)_(\d+)$');
  final Match? match = pattern.firstMatch(subshardName);
  if (match == null || match.groupCount != 2) {
    foundError(<String>[
      '${red}Invalid subshard name "$subshardName". Expected format "[int]_[int]" ex. "1_3"',
    ]);
    throw Exception('Invalid subshard name: $subshardName');
  }
  // One-indexed.
  final int index = int.parse(match.group(1)!);
  final int total = int.parse(match.group(2)!);
  if (index > total) {
    foundError(<String>[
      '${red}Invalid subshard name "$subshardName". Index number must be greater or equal to total.',
    ]);
    return <T>[];
  }

  final int testsPerShard = (tests.length / total).ceil();
  final int start = (index - 1) * testsPerShard;
  final int end = math.min(index * testsPerShard, tests.length);

  print('Selecting subshard $index of $total (tests ${start + 1}-$end of ${tests.length})');
  return tests.sublist(start, end);
}

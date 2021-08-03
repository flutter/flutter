// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;
import 'package:pool/pool.dart';
import 'package:web_test_utils/goldens.dart';

import '../environment.dart';
import '../exceptions.dart';
import '../utils.dart';
import '../watcher.dart';

/// Compiles web tests and their dependencies.
///
/// Includes:
///  * compile the test code itself
///  * compile the page that hosts the tests
///  * fetch the golden repo for screenshot comparison
class CompileTestsStep implements PipelineStep {
  CompileTestsStep({
    this.skipGoldensRepoFetch = false,
    this.testFiles,
  });

  final bool skipGoldensRepoFetch;
  final List<FilePath>? testFiles;

  @override
  String get description => 'compile_tests';

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<void> interrupt() async {
    await cleanup();
  }

  @override
  Future<void> run() async {
    if (!skipGoldensRepoFetch) {
      await fetchGoldensRepo();
    }
    await buildHostPage();
    await compileTests(testFiles ?? findAllTests());
  }
}

/// Compiles the specified unit tests.
Future<void> compileTests(List<FilePath> testFiles) async {
  final Stopwatch stopwatch = Stopwatch()..start();

  // Separate HTML targets from CanvasKit targets because the two use
  // different dart2js options.
  final List<FilePath> htmlTargets = <FilePath>[];
  final List<FilePath> canvasKitTargets = <FilePath>[];
  final String canvasKitTestDirectory =
      pathlib.join(environment.webUiTestDir.path, 'canvaskit');
  for (final FilePath testFile in testFiles) {
    if (pathlib.isWithin(canvasKitTestDirectory, testFile.absolute)) {
      canvasKitTargets.add(testFile);
    } else {
      htmlTargets.add(testFile);
    }
  }

  await Future.wait(<Future<void>>[
    if (htmlTargets.isNotEmpty)
      _compileTestsInParallel(targets: htmlTargets, forCanvasKit: false),
    if (canvasKitTargets.isNotEmpty)
      _compileTestsInParallel(targets: canvasKitTargets, forCanvasKit: true),
  ]);

  stopwatch.stop();

  final int targetCount = htmlTargets.length + canvasKitTargets.length;
  print(
    'Built $targetCount tests in ${stopwatch.elapsedMilliseconds ~/ 1000} '
    'seconds using $_dart2jsConcurrency concurrent dart2js processes.',
  );
}

// Maximum number of concurrent dart2js processes to use.
const int _dart2jsConcurrency = int.fromEnvironment('FELT_DART2JS_CONCURRENCY', defaultValue: 8);

final Pool _dart2jsPool = Pool(_dart2jsConcurrency);

/// Spawns multiple dart2js processes to compile [targets] in parallel.
Future<void> _compileTestsInParallel({
  required List<FilePath> targets,
  required bool forCanvasKit,
}) async {
  final Stream<bool> results = _dart2jsPool.forEach(
    targets,
    (FilePath file) => compileUnitTest(file, forCanvasKit: forCanvasKit),
  );
  await for (final bool isSuccess in results) {
    if (!isSuccess) {
      throw ToolExit('Failed to compile tests.');
    }
  }
}

/// Compiles one unit test using `dart2js`.
///
/// When building for CanvasKit we have to use extra argument
/// `DFLUTTER_WEB_USE_SKIA=true`.
///
/// Dart2js creates the following outputs:
/// - target.browser_test.dart.js
/// - target.browser_test.dart.js.deps
/// - target.browser_test.dart.js.maps
/// under the same directory with test file. If all these files are not in
/// the same directory, Chrome dev tools cannot load the source code during
/// debug.
///
/// All the files under test already copied from /test directory to /build
/// directory before test are build. See [_copyFilesFromTestToBuild].
///
/// Later the extra files will be deleted in [_cleanupExtraFilesUnderTestDir].
Future<bool> compileUnitTest(FilePath input, { required bool forCanvasKit }) async {
  final String targetFileName = pathlib.join(
    environment.webUiBuildDir.path,
    '${input.relativeToWebUi}.browser_test.dart.js',
  );

  final io.Directory directoryToTarget = io.Directory(pathlib.join(
      environment.webUiBuildDir.path,
      pathlib.dirname(input.relativeToWebUi)));

  if (!directoryToTarget.existsSync()) {
    directoryToTarget.createSync(recursive: true);
  }

  final List<String> arguments = <String>[
    '--no-minify',
    '--disable-inlining',
    '--enable-asserts',
    '--enable-experiment=non-nullable',
    '--no-sound-null-safety',

    // We do not want to auto-select a renderer in tests. As of today, tests
    // are designed to run in one specific mode. So instead, we specify the
    // renderer explicitly.
    '-DFLUTTER_WEB_AUTO_DETECT=false',
    '-DFLUTTER_WEB_USE_SKIA=$forCanvasKit',

    '-O2',
    '-o',
    targetFileName, // target path.
    input.relativeToWebUi, // current path.
  ];

  final int exitCode = await runProcess(
    environment.dart2jsExecutable,
    arguments,
    workingDirectory: environment.webUiRootDir.path,
  );

  if (exitCode != 0) {
    io.stderr.writeln('ERROR: Failed to compile test $input. '
        'Dart2js exited with exit code $exitCode');
    return false;
  } else {
    return true;
  }
}

Future<void> buildHostPage() async {
  final String hostDartPath = pathlib.join('lib', 'static', 'host.dart');
  final io.File hostDartFile = io.File(pathlib.join(
    environment.webEngineTesterRootDir.path,
    hostDartPath,
  ));
  final io.File timestampFile = io.File(pathlib.join(
    environment.webEngineTesterRootDir.path,
    '$hostDartPath.js.timestamp',
  ));

  final String timestamp =
      hostDartFile.statSync().modified.millisecondsSinceEpoch.toString();
  if (timestampFile.existsSync()) {
    final String lastBuildTimestamp = timestampFile.readAsStringSync();
    if (lastBuildTimestamp == timestamp) {
      // The file is still fresh. No need to rebuild.
      return;
    } else {
      // Record new timestamp, but don't return. We need to rebuild.
      print('${hostDartFile.path} timestamp changed. Rebuilding.');
    }
  } else {
    print('Building ${hostDartFile.path}.');
  }

  final int exitCode = await runProcess(
    environment.dart2jsExecutable,
    <String>[
      hostDartPath,
      '-o',
      '$hostDartPath.js',
    ],
    workingDirectory: environment.webEngineTesterRootDir.path,
  );

  if (exitCode != 0) {
    throw ToolExit(
      'Failed to compile ${hostDartFile.path}. Compiler '
        'exited with exit code $exitCode',
      exitCode: exitCode,
    );
  }

  // Record the timestamp to avoid rebuilding unless the file changes.
  timestampFile.writeAsStringSync(timestamp);
}

Future<void> fetchGoldensRepo() async {
  print('INFO: Fetching goldens repo');
  final GoldensRepoFetcher goldensRepoFetcher = GoldensRepoFetcher(
      environment.webUiGoldensRepositoryDirectory,
      pathlib.join(environment.webUiDevDir.path, 'goldens_lock.yaml'));
  await goldensRepoFetcher.fetch();
}

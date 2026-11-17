// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:flutter_tools/src/test/test_golden_comparator.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/fakes.dart';
import 'test_data/integration_tests_project.dart';
import 'test_utils.dart';

/// Tests that [`TestGoldenComparator`] is working end-to-end-ish.
///
/// Spawns `flutter_tester`, and asks it to compare (using the default
/// `LocalFileComparator`) two images, one that will be an exact match, and one
/// that is very different.
void main() {
  final (File testPng1, File testPng2) = () {
    final Directory testData = fileSystem
        .directory(getFlutterRoot())
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childDirectory('test')
        .childDirectory('integration.shard')
        .childDirectory('test_data');
    return (testData.childFile('test_1.png'), testData.childFile('test_2.png'));
  }();

  late LocalFileSystem localFs;
  late FileSystem fs;
  late Directory tmpDir;
  late BufferLogger logger;
  late IntegrationTestsProject testProject;
  late FlutterProject project;

  setUp(() async {
    localFs = LocalFileSystem.test(signals: LocalSignals.instance);
    fs = ErrorHandlingFileSystem(delegate: localFs, platform: const LocalPlatform());
    tmpDir = fs.systemTempDirectory.createTempSync();
    logger = BufferLogger.test();

    testProject = IntegrationTestsProject();
    await testProject.setUpIn(tmpDir);
    project = FlutterProject.fromDirectoryTest(tmpDir, logger);
    testPng1.copySync(tmpDir.childDirectory('integration_test').childFile('test.png').path);
  });

  tearDown(() async {
    tryToDelete(tmpDir);
    await localFs.dispose();
    printOnFailure(logger.warningText);
    printOnFailure(logger.errorText);
  });

  TestGoldenComparator createComparator() {
    final File packageConfig = tmpDir.childDirectory('.dart_tool').childFile('package_config.json');
    expect(packageConfig, exists);

    final String flutterRoot = getFlutterRoot();
    final testProcessManager = _TestProcessManager();
    final cache = Cache.test(
      rootOverride: fs.directory(flutterRoot),
      flutterRoot: flutterRoot,
      fileSystem: fs,
      logger: logger,
      platform: platform,
      processManager: testProcessManager,
    );
    final artifacts = CachedArtifacts(
      fileSystem: fs,
      cache: cache,
      platform: platform,
      operatingSystemUtils: cache.osUtils,
    );
    final toolContext = FakeToolContext(
      artifacts: artifacts,
      cache: cache,
      config: Config.test(logger: logger),
      fs: fs,
      logger: logger,
      platform: platform,
      processManager: testProcessManager,
      shutdownHooks: ShutdownHooks(),
    );
    final compiler = TestCompiler(
      BuildInfo(
        BuildMode.debug,
        null,
        treeShakeIcons: false,
        packageConfigPath: packageConfig.path,
      ),
      project,
      templateRenderer: const MustacheTemplateRenderer(),
      toolContext: toolContext,
    );
    final comparator = TestGoldenComparator(
      compilerFactory: () => compiler,
      flutterTesterBinPath: artifacts.getArtifactPath(.flutterTester),
      toolContext: toolContext,
    );
    addTearDown(() async {
      await toolContext.shutdownHooks.runShutdownHooks(logger);
      await compiler.dispose();
      for (final Process process in testProcessManager.startedProcesses) {
        process.kill();
        await process.exitCode;
      }
      await comparator.close();
    });
    return comparator;
  }

  testWithoutContext('successful comparison is successful', () async {
    final TestGoldenComparator comparator = createComparator();
    final TestGoldenComparison result = await comparator.compare(
      Uri(path: testProject.testFilePath),
      testPng1.readAsBytesSync(),
      Uri(path: 'test.png'),
    );
    expect(result, isA<TestGoldenComparisonDone>());
  });

  // Regression test for https://github.com/flutter/flutter/issues/174267.
  testWithoutContext('failed comparison is failed but not crashed', () async {
    final TestGoldenComparator comparator = createComparator();
    final TestGoldenComparison result = await comparator.compare(
      Uri(path: testProject.testFilePath),
      testPng2.readAsBytesSync(),
      Uri(path: 'test.png'),
    );
    expect(
      result,
      isA<TestGoldenComparisonError>().having(
        (e) => e.error,
        'error',
        contains('Pixel test failed, image sizes do not match'),
      ),
    );
  });
}

class _TestProcessManager extends LocalProcessManager {
  final startedProcesses = <Process>[];

  @override
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    final Process process = await super.start(
      command,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
    startedProcesses.add(process);
    return process;
  }
}

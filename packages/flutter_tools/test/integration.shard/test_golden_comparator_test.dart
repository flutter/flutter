// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:flutter_tools/src/test/test_golden_comparator.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/integration_tests_project.dart';

/// Tests that [`TestGoldenComparator`] can handle a failure gracefully.
///
/// Regression test for https://github.com/flutter/flutter/issues/174267.
void main() {
  final (File testPng1, File testPng2) = () {
    final Directory testData = globals.localFileSystem
        .directory(getFlutterRoot())
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childDirectory('test')
        .childDirectory('integration.shard')
        .childDirectory('test_data');
    return (testData.childFile('test_1.png'), testData.childFile('test_2.png'));
  }();

  late LocalFileSystem fs;
  late Directory tmpDir;
  late BufferLogger logger;
  late IntegrationTestsProject testProject;
  late FlutterProject project;

  setUp(() async {
    fs = globals.localFileSystem;
    tmpDir = fs.systemTempDirectory.createTempSync();
    logger = BufferLogger.test();

    testProject = IntegrationTestsProject();
    await testProject.setUpIn(tmpDir);
    project = FlutterProject.fromDirectoryTest(tmpDir, logger);
    testPng1.copySync(tmpDir.childDirectory('integration_test').childFile('test.png').path);
  });

  late TestCompiler compiler;
  late TestGoldenComparator comparator;

  tearDown(() {
    printOnFailure(logger.warningText);
    printOnFailure(logger.errorText);
  });

  testUsingContext('successful comparison is successful', () async {
    final File packageConfig = tmpDir.childDirectory('.dart_tool').childFile('package_config.json');
    expect(packageConfig, exists);

    compiler = TestCompiler(
      BuildInfo(
        BuildMode.debug,
        null,
        treeShakeIcons: false,
        packageConfigPath: packageConfig.path,
      ),
      project,
    );
    comparator = TestGoldenComparator(
      flutterTesterBinPath: globals.artifacts!.getArtifactPath(Artifact.flutterTester),
      compilerFactory: () => compiler,
      logger: logger,
      fileSystem: globals.fs,
      processManager: globals.processManager,
    );

    final TestGoldenComparison result = await comparator.compare(
      Uri(path: testProject.testFilePath),
      testPng1.readAsBytesSync(),
      Uri(path: 'test.png'),
    );
    expect(result, isA<TestGoldenComparisonDone>());
  });

  testUsingContext('failed comparison is failed but not crashed', () async {
    final File packageConfig = tmpDir.childDirectory('.dart_tool').childFile('package_config.json');
    expect(packageConfig, exists);

    compiler = TestCompiler(
      BuildInfo(
        BuildMode.debug,
        null,
        treeShakeIcons: false,
        packageConfigPath: packageConfig.path,
      ),
      project,
    );
    comparator = TestGoldenComparator(
      flutterTesterBinPath: globals.artifacts!.getArtifactPath(Artifact.flutterTester),
      compilerFactory: () => compiler,
      logger: logger,
      fileSystem: globals.fs,
      processManager: globals.processManager,
    );

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

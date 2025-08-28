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

/// Tests that [`TestGoldenComparator`] is working end-to-end-ish.
///
/// Spawns `flutter_tester`, and asks it to compare (using the default
/// `LocalFileComparator`) two images, one that will be an exact match, and one
/// that is very different.
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

  tearDown(() {
    printOnFailure(logger.warningText);
    printOnFailure(logger.errorText);
  });

  TestGoldenComparator createComparator() {
    final File packageConfig = tmpDir.childDirectory('.dart_tool').childFile('package_config.json');
    expect(packageConfig, exists);

    final compiler = TestCompiler(
      BuildInfo(
        BuildMode.debug,
        null,
        treeShakeIcons: false,
        packageConfigPath: packageConfig.path,
      ),
      project,
    );
    return TestGoldenComparator(
      flutterTesterBinPath: globals.artifacts!.getArtifactPath(Artifact.flutterTester),
      compilerFactory: () => compiler,
      logger: logger,
      fileSystem: globals.fs,
      processManager: globals.processManager,
    );
  }

  testUsingContext('successful comparison is successful', () async {
    final TestGoldenComparator comparator = createComparator();
    final TestGoldenComparison result = await comparator.compare(
      Uri(path: testProject.testFilePath),
      testPng1.readAsBytesSync(),
      Uri(path: 'test.png'),
    );
    expect(result, isA<TestGoldenComparisonDone>());
  });

  // Regression test for https://github.com/flutter/flutter/issues/174267.
  testUsingContext('failed comparison is failed but not crashed', () async {
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

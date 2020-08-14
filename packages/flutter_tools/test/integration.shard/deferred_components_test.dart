// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/deferred_components_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  FlutterRunTestDriver _flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await _flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('simple build appbundle android-arm64 target succeeds', () async {
    final DeferredComponentsProject project = DeferredComponentsProject(BasicDeferredComponentsConfig());
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'appbundle',
      '--target-platform=android-arm64'
    ], workingDirectory: tempDir.path);

    expect(result.stdout.toString(), contains('app-release.aab'));
    expect(result.stdout.toString(), contains('Deferred components setup verification part 1 of 2 passed.'));
    expect(result.stdout.toString(), contains('Deferred components setup verification part 2 of 2 passed.'));

    final String line = result.stdout.toString()
      .split('\n')
      .firstWhere((String line) => line.contains('app-release.aab'));

    final String outputFilePath = line.split(' ')[2].trim();
    expect(fileSystem.file(fileSystem.path.join(tempDir.path, outputFilePath)), exists);

    expect(result.exitCode, 0);
  });

  testWithoutContext('simple build appbundle all targets succeeds', () async {
    final DeferredComponentsProject project = DeferredComponentsProject(BasicDeferredComponentsConfig());
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'appbundle',
    ], workingDirectory: tempDir.path);

    expect(result.stdout.toString(), contains('app-release.aab'));
    expect(result.stdout.toString(), contains('Deferred components setup verification part 1 of 2 passed.'));
    expect(result.stdout.toString(), contains('Deferred components setup verification part 2 of 2 passed.'));

    final String line = result.stdout.toString()
      .split('\n')
      .firstWhere((String line) => line.contains('app-release.aab'));

    final String outputFilePath = line.split(' ')[2].trim();
    expect(fileSystem.file(fileSystem.path.join(tempDir.path, outputFilePath)), exists);

    expect(result.exitCode, 0);
  });

  testWithoutContext('simple build appbundle no-deferred-components succeeds', () async {
    final DeferredComponentsProject project = DeferredComponentsProject(BasicDeferredComponentsConfig());
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'appbundle',
      '--no-deferred-components'
    ], workingDirectory: tempDir.path);

    expect(result.stdout.toString(), contains('app-release.aab'));
    expect(result.stdout.toString().contains('Deferred components setup verification part 1 of 2 passed.'), false);
    expect(result.stdout.toString().contains('Deferred components setup verification part 2 of 2 passed.'), false);

    final String line = result.stdout.toString()
      .split('\n')
      .firstWhere((String line) => line.contains('app-release.aab'));

    final String outputFilePath = line.split(' ')[2].trim();
    expect(fileSystem.file(fileSystem.path.join(tempDir.path, outputFilePath)), exists);

    expect(result.exitCode, 0);
  });

  testWithoutContext('simple build appbundle mismatched golden no-verify-deferred-components succeeds', () async {
    final DeferredComponentsProject project = DeferredComponentsProject(NoMismatchedGoldenDeferredComponentsConfig());
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'appbundle',
      '--no-verify-deferred-components',
    ], workingDirectory: tempDir.path);

    expect(result.stdout.toString().contains('app-release.aab'), true);
    expect(result.stdout.toString().contains('Deferred components setup verification part 1 of 2 passed.'), false);
    expect(result.stdout.toString().contains('Deferred components setup verification part 2 of 2 passed.'), false);

    expect(result.stdout.toString().contains('New loading units were found:'), false);
    expect(result.stdout.toString().contains('Previously existing loading units no longer exist:'), false);

    final String line = result.stdout.toString()
      .split('\n')
      .firstWhere((String line) => line.contains('app-release.aab'));

    final String outputFilePath = line.split(' ')[2].trim();
    expect(fileSystem.file(fileSystem.path.join(tempDir.path, outputFilePath)), exists);

    expect(result.exitCode, 0);
  });

  testWithoutContext('simple build appbundle missing android dynamic feature module fails', () async {
    final DeferredComponentsProject project = DeferredComponentsProject(NoAndroidDynamicFeatureModuleDeferredComponentsConfig());
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'appbundle',
    ], workingDirectory: tempDir.path);

    expect(result.stdout.toString().contains('app-release.aab'), false);
    expect(result.stdout.toString().contains('Deferred components setup verification part 1 of 2 passed.'), false);
    expect(result.stdout.toString().contains('Deferred components setup verification part 2 of 2 passed.'), false);

    expect(result.stdout.toString(), contains('Newly generated android files:'));
    expect(result.stdout.toString(), contains('build/android_deferred_components_setup_files/component1/build.gradle'));
    expect(result.stdout.toString(), contains('build/android_deferred_components_setup_files/component1/src/main/AndroidManifest.xml'));

    expect(result.exitCode, 1);
  });

  testWithoutContext('simple build appbundle missing golden fails', () async {
    final DeferredComponentsProject project = DeferredComponentsProject(NoGoldenDeferredComponentsConfig());
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'appbundle',
    ], workingDirectory: tempDir.path);

    expect(result.stdout.toString().contains('app-release.aab'), false);
    expect(result.stdout.toString().contains('Deferred components setup verification part 1 of 2 passed.'), true);
    expect(result.stdout.toString().contains('Deferred components setup verification part 2 of 2 passed.'), false);

    expect(result.stdout.toString(), contains('New loading units were found:'));
    expect(result.stdout.toString(), contains('- package:test/deferred_library.dart'));

    expect(result.stdout.toString().contains('Previously existing loading units no longer exist:'), false);

    expect(result.exitCode, 1);
  });

  testWithoutContext('simple build appbundle mismatched golden fails', () async {
    final DeferredComponentsProject project = DeferredComponentsProject(NoMismatchedGoldenDeferredComponentsConfig());
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'appbundle',
    ], workingDirectory: tempDir.path);

    expect(result.stdout.toString().contains('app-release.aab'), false);
    expect(result.stdout.toString().contains('Deferred components setup verification part 1 of 2 passed.'), true);
    expect(result.stdout.toString().contains('Deferred components setup verification part 2 of 2 passed.'), false);

    expect(result.stdout.toString(), contains('New loading units were found:'));
    expect(result.stdout.toString(), contains('- package:test/deferred_library.dart'));

    expect(result.stdout.toString(), contains('Previously existing loading units no longer exist:'));
    expect(result.stdout.toString(), contains('- package:test/invalid_lib_name.dart'));

    expect(result.stdout.toString(), contains('This loading unit check will not fail again on the next build attempt'));

    expect(result.exitCode, 1);
  });
}

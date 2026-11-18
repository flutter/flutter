// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory workingDirectory;

  setUp(() {
    workingDirectory = fileSystem.systemTempDirectory.createTempSync(
      'build_without_xcworkspace_test.',
    );
  });

  tearDown(() {
    ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
  });

  test(
    'flutter build ios succeeds when no .xcworkspace is present',
    () async {
      await _testBuildWithoutWorkspace(
        workingDirectory: workingDirectory,
        targetPlatform: 'ios',
        buildArgs: <String>['--debug', '--no-codesign'],
        // This file only exists if the app was fully built.
        fullyBuiltMarker: (Directory appDirectory) => appDirectory
            .childDirectory('build')
            .childDirectory('ios')
            .childDirectory('iphoneos')
            .childDirectory('Runner.app')
            .childFile('AppFrameworkInfo.plist'),
      );
    },
    skip: !platform.isMacOS, // [intended] Can only build for iOS on macOS.
  );

  test(
    'flutter build macos succeeds when no .xcworkspace is present',
    () async {
      await _testBuildWithoutWorkspace(
        workingDirectory: workingDirectory,
        targetPlatform: 'macos',
        buildArgs: <String>['--debug'],
        // This file only exists if the app was fully built.
        fullyBuiltMarker: (Directory appDirectory) => appDirectory
            .childDirectory('build')
            .childDirectory('macos')
            .childDirectory('Build')
            .childDirectory('Products')
            .childDirectory('Debug')
            .childDirectory('App.framework')
            .childDirectory('Resources')
            .childFile('Info.plist'),
      );
    },
    skip: !platform.isMacOS, // [intended] Can only build for macOS on macOS.
  );
}

/// Creates an app, removes its `Runner.xcworkspace`, and verifies the build
/// still succeeds.
Future<void> _testBuildWithoutWorkspace({
  required Directory workingDirectory,
  required String targetPlatform,
  required List<String> buildArgs,
  required File Function(Directory appDirectory) fullyBuiltMarker,
}) async {
  const appName = 'no_workspace_app';

  final ProcessResult createResult = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'create',
    '--org',
    'io.flutter.devicelab',
    appName,
    '--platforms=$targetPlatform',
  ], workingDirectory: workingDirectory.path);
  expect(
    createResult.exitCode,
    0,
    reason:
        'Failed to create app: \n'
        'stdout: \n${createResult.stdout}\n'
        'stderr: \n${createResult.stderr}\n',
  );

  final Directory appDirectory = workingDirectory.childDirectory(appName);

  final Directory workspace = appDirectory
      .childDirectory(targetPlatform)
      .childDirectory('Runner.xcworkspace');
  ErrorHandlingFileSystem.deleteIfExists(workspace, recursive: true);
  expect(workspace, isNot(exists));

  final ProcessResult buildResult = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'build',
    targetPlatform,
    ...buildArgs,
  ], workingDirectory: appDirectory.path);
  expect(
    buildResult.exitCode,
    0,
    reason:
        'Failed to build the app without a .xcworkspace: \n'
        'stdout: \n${buildResult.stdout}\n'
        'stderr: \n${buildResult.stderr}\n',
  );

  // The build must not require or silently recreate the workspace; that is
  // the regression this test guards against.
  expect(workspace, isNot(exists));
  expect(fullyBuiltMarker(appDirectory), exists);
}

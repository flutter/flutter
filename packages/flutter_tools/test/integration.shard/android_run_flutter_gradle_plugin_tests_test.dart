// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import 'test_utils.dart';

Future<void> runFlutterGradlePluginTests({
  List<String> extraGradleArguments = const <String>[],
}) async {
  final gradleFileName = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
  final gradleExecutable = Platform.isWindows ? '.\\$gradleFileName' : './$gradleFileName';
  final String flutterRoot = getFlutterRoot();
  final Directory flutterGradlePluginDirectory = fileSystem
      .directory(flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory('gradle');
  final logger = BufferLogger.test();
  final cache = Cache.test(
    rootOverride: fileSystem.directory(flutterRoot),
    flutterRoot: flutterRoot,
    fileSystem: fileSystem,
    logger: logger,
    platform: platform,
    processManager: processManager,
  );
  GradleUtils(
    platform: platform,
    logger: logger,
    cache: cache,
    operatingSystemUtils: cache.osUtils,
  ).injectGradleWrapperIfNeeded(flutterGradlePluginDirectory);
  makeExecutable(flutterGradlePluginDirectory.childFile(gradleFileName));
  final processUtils = ProcessUtils(processManager: processManager, logger: logger);
  final RunResult runResult = await processUtils.run(<String>[
    gradleExecutable,
    'test',
    ...extraGradleArguments,
  ], workingDirectory: flutterGradlePluginDirectory.path);
  expect(runResult.processResult, const ProcessResultMatcher());
}

void main() {
  testWithoutContext('Flutter Gradle Plugin unit tests pass', () async {
    await runFlutterGradlePluginTests();
  });

  testWithoutContext('Flutter Gradle Plugin unit tests pass against the AGP 9 line', () async {
    // The public AGP DSL is not binary-compatible between major versions everywhere (see
    // AgpCommonExtensionWrapper.kt), so the plugin must compile and pass its tests against
    // both the default AGP version in build.gradle.kts and the AGP version used by the
    // project templates. This also runs the bytecode check that no compiled class
    // references CommonExtension.
    await runFlutterGradlePluginTests(
      extraGradleArguments: <String>[
        '-Pflutter.internal.agpVersion=$templateAndroidGradlePluginVersion',
        '--rerun-tasks', // Required to run tests back to back with different agp versions.
      ],
    );
  });
}

void makeExecutable(File file) {
  if (Platform.isWindows) {
    // no op.
    return;
  }

  final ProcessResult result = processManager.runSync(<String>['chmod', '+x', file.path]);
  expect(result, const ProcessResultMatcher());
}

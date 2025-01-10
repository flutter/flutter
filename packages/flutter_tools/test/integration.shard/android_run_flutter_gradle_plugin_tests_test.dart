// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import 'bash_entrypoint_test.dart';
import 'test_utils.dart';
import '../src/common.dart';
import '../src/context.dart';

void main() {
  testUsingContext('Flutter Gradle Plugin unit tests pass', () async {
    final String gradleFileName = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
    final String gradleExecutable = Platform.isWindows ? '.\\$gradleFileName' : './$gradleFileName';
    final Directory flutterGradlePluginDirectory = fileSystem.directory(getFlutterRoot())
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childDirectory('gradle');
    globals.gradleUtils?.injectGradleWrapperIfNeeded(flutterGradlePluginDirectory);
    makeExecutable(flutterGradlePluginDirectory.childFile(gradleFileName));
    final RunResult runResult = await globals.processUtils.run(<String>[gradleExecutable, 'test'], workingDirectory: flutterGradlePluginDirectory.path);
    expect(runResult.exitCode, 0);
  });
}

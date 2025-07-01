// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/context.dart';
import 'test_utils.dart';

void main() {

  testUsingContext('8.12', () async {
    final String gradleFileName = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
    final String gradleExecutable = Platform.isWindows ? '.\\$gradleFileName' : './$gradleFileName';
    final Directory pluginDir = fileSystem
        .directory(getFlutterRoot())
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childDirectory('gradle');
    final File wrapperProps = pluginDir
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties');

    final String originalWrapperContent = wrapperProps.readAsStringSync();

      // Modify gradle-wrapper.properties
      final String updatedContent = originalWrapperContent.replaceAllMapped(
        RegExp(r'distributionUrl=.*?/gradle-(.*?)-'),
        (match) => match.group(0)!.replaceAll(match.group(1)!, '8.12'),
      );
      wrapperProps.writeAsStringSync(updatedContent);

      // Inject and make executable
      globals.gradleUtils?.injectGradleWrapperIfNeeded(pluginDir);
      makeExecutable(pluginDir.childFile(gradleFileName));

      final RunResult runResult = await globals.processUtils.run(<String>[
        gradleExecutable,
        'test',
      ], workingDirectory: pluginDir.path);
      expect(runResult.processResult, const ProcessResultMatcher());
    }

  
  );


testUsingContext('8.6', () async {
    final String gradleFileName = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
    final String gradleExecutable = Platform.isWindows ? '.\\$gradleFileName' : './$gradleFileName';
    final Directory pluginDir = fileSystem
        .directory(getFlutterRoot())
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childDirectory('gradle');
    final File wrapperProps = pluginDir
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties');

    final String originalWrapperContent = wrapperProps.readAsStringSync();

      // Modify gradle-wrapper.properties
      final String updatedContent = originalWrapperContent.replaceAllMapped(
        RegExp(r'distributionUrl=.*?/gradle-(.*?)-'),
        (match) => match.group(0)!.replaceAll(match.group(1)!, '8.6'),
      );
      wrapperProps.writeAsStringSync(updatedContent);

      // Inject and make executable
      globals.gradleUtils?.injectGradleWrapperIfNeeded(pluginDir);
      makeExecutable(pluginDir.childFile(gradleFileName));

      final RunResult runResult = await globals.processUtils.run(<String>[
        gradleExecutable,
        'test',
      ], workingDirectory: pluginDir.path);
      expect(runResult.processResult, const ProcessResultMatcher());
    }

  
  );
}

void makeExecutable(File file) {
  if (Platform.isWindows) {
    // no op.
    return;
  }

  final ProcessResult result = processManager.runSync(<String>['chmod', '+x', file.path]);
  expect(result, const ProcessResultMatcher());
}

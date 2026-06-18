// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:file/file.dart';
import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('gradle_init_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('gradle build succeeds when global init.gradle defines repositories', () async {
    // Create a new flutter project.
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      tempDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());

    // Create a mock GRADLE_USER_HOME.
    final Directory gradleUserHome = tempDir.childDirectory('gradle_user_home');
    gradleUserHome.createSync();

    // Link host's gradle cache/wrapper into the mock GRADLE_USER_HOME to avoid downloading Gradle/plugins.
    final String? hostHome =
        platform.environment['GRADLE_USER_HOME'] ??
        (platform.isWindows ? platform.environment['USERPROFILE'] : platform.environment['HOME']);
    if (hostHome != null) {
      final Directory hostGradleHome = tempDir.fileSystem.directory(
        tempDir.fileSystem.path.join(hostHome, '.gradle'),
      );
      if (hostGradleHome.existsSync()) {
        for (final FileSystemEntity entity in hostGradleHome.listSync()) {
          final String name = entity.basename;
          if (name == 'init.gradle' || name == 'init.d') {
            continue;
          }
          final String linkPath = tempDir.fileSystem.path.join(gradleUserHome.path, name);
          try {
            tempDir.fileSystem.link(linkPath).createSync(entity.path);
          } on FileSystemException {
            // Fallback for environment constraints.
          }
        }
      }
    }

    // Create an init.gradle in the gradle_user_home directory.
    final File initGradle = gradleUserHome.childFile('init.gradle');
    initGradle.writeAsStringSync('''
allprojects {
    repositories {
        mavenLocal()
    }
}
''');

    result = await processManager.run(
      <String>[flutterBin, 'build', 'apk', '--debug', ...getLocalEngineArguments()],
      workingDirectory: tempDir.path,
      environment: <String, String>{'GRADLE_USER_HOME': gradleUserHome.path},
    );

    // We expect the build to succeed.
    expect(result.exitCode, 0);
    expect(
      result.stderr.toString() + result.stdout.toString(),
      isNot(contains('prefer settings repositories over project repositories')),
    );
  });
}

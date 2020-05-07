// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';

/// Tests that AARs can be built on plugin projects.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create plugin project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org', 'io.flutter.devicelab',
            '--template', 'plugin',
            'hello',
          ],
        );
      });

      section('Build release AAR');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['aar', '--verbose', '--release'],
        );
      });

      final String repoPath = path.join(
        projectDir.path,
        'build',
        'outputs',
        'repo',
      );

      final File releaseAar = File(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'hello_release',
        '1.0',
        'hello_release-1.0.aar',
      ));

      if (!exists(releaseAar)) {
        return TaskResult.failure('Failed to build the release AAR file.');
      }

      final File releasePom = File(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'hello_release',
        '1.0',
        'hello_release-1.0.pom',
      ));

      if (!exists(releasePom)) {
        return TaskResult.failure('Failed to build the release POM file.');
      }

      section('Build debug AAR');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>[
            'aar',
            '--verbose',
            '--debug',
          ],
        );
      });

      final File debugAar = File(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'hello_debug',
        '1.0',
        'hello_debug-1.0.aar',
      ));

      if (!exists(debugAar)) {
        return TaskResult.failure('Failed to build the debug AAR file.');
      }

      final File debugPom = File(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'hello_debug',
        '1.0',
        'hello_debug-1.0.pom',
      ));

      if (!exists(debugPom)) {
        return TaskResult.failure('Failed to build the debug POM file.');
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';
final String fileReadWriteMode = Platform.isWindows ? 'rw-rw-rw-' : 'rw-r--r--';

/// Combines several TaskFunctions with trivial success value into one.
TaskFunction combine(List<TaskFunction> tasks) {
  return () async {
    for (final task in tasks) {
      final TaskResult result = await task();
      if (result.failed) {
        return result;
      }
    }
    return TaskResult.success(null);
  };
}

/// Tests that the Flutter module project template works and supports
/// adding Flutter to an existing Android app.
class ModuleTest {
  ModuleTest({this.gradleVersion = '7.6.3'});

  static const String buildTarget = 'module-gradle';
  final String gradleVersion;
  final StringBuffer stdout = StringBuffer();
  final StringBuffer stderr = StringBuffer();

  Future<TaskResult> call() async {
    section('Running: $buildTarget-$gradleVersion');
    section('Find Java');

    final String? javaHome = await findJavaHome();
    if (javaHome == null) {
      return TaskResult.failure('Could not find Java');
    }
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--template=module', 'hello'],
          output: stdout,
          stderr: stderr,
        );
      });

      final integrationTestFile = File(
          path.join(
            projectDir.path,
            'lib',
            'main.dart',
          ),
        );
      integrationTestFile
        ..createSync(recursive: true)
        ..writeAsStringSync('''
    import 'package:flutter/material.dart';
    import 'dart:math';

    const String text = \'\'\'
    Hello world.

    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum facilisis vel quam nec scelerisque. Nullam leo sapien, ornare blandit dui ac, varius condimentum leo. Vestibulum quis sem vulputate, varius dui nec, malesuada sem. Aliquam tincidunt pretium dolor, quis ullamcorper nunc consequat quis. Donec at dui in ex pharetra pretium. Quisque molestie massa vel tellus scelerisque feugiat. Ut sed consectetur neque.\'\'\';

    void main() {
      final random = Random();
      final numTexts = random.nextInt(4) + 1;
      runApp(Text(text * numTexts, textDirection: TextDirection.ltr));
    }
    ''');

      section('Build host app');

      await inDirectory(projectDir, () async {
        // Does not work with local engine changes.
        await flutter('build', options: <String>['apk'], output: stdout, stderr: stderr);
      });

      final bool hostApkBuilt = exists(
        File(
          path.join(
            projectDir.path,
            'build',
            'host',
            'outputs',
            'apk',
            'release',
            'app-release.apk',
          ),
        ),
      );

      if (!hostApkBuilt) {
        return TaskResult.failure('Failed to build host .apk');
      }

      section('Add to existing Android app');

      final hostApp = Directory(path.join(tempDir.path, 'hello_host_app'));
      mkdir(hostApp);
      recursiveCopy(
        Directory(
          path.join(
            flutterDirectory.path,
            'dev',
            'integration_tests',
            'pure_android_host_apps',
            'content_sizing',
          ),
        ),
        hostApp,
      );
      copy(File(path.join(projectDir.path, '.android', gradlew)), hostApp);
      copy(
        File(path.join(projectDir.path, '.android', 'gradle', 'wrapper', 'gradle-wrapper.jar')),
        Directory(path.join(hostApp.path, 'gradle', 'wrapper')),
      );

      // Modify gradle version to passed in version.
      // This is somehow the wrong file.
      final gradleWrapperProperties = File(
        path.join(hostApp.path, 'gradle', 'wrapper', 'gradle-wrapper.properties'),
      );
      String propertyContent = await gradleWrapperProperties.readAsString();
      propertyContent = propertyContent.replaceFirst('REPLACEME', gradleVersion);
      section(propertyContent);
      await gradleWrapperProperties.writeAsString(propertyContent, flush: true);

      section('Build debug host APK');

      await inDirectory(hostApp, () async {
        if (!Platform.isWindows) {
          await exec('chmod', <String>['+x', 'gradlew']);
        }
        await exec(
          gradlewExecutable,
          <String>['app:installDebug'],
          environment: <String, String>{
            'JAVA_HOME': javaHome,
            'FLUTTER_SUPPRESS_ANALYTICS': 'true',
          },
        );
      });

      section('Run app');

      final devices = DeviceDiscovery();
      final activity = 'com.example.myapplication/.MainActivity';
      final device = await devices.workingDevice as AndroidDevice;
      await device.adb(<String>['shell', 'am', 'start', '-n', activity], canFail: true);

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  }
}

Future<void> main() async {
  await task(combine(<TaskFunction>[ModuleTest(gradleVersion: '8.7').call]));
}

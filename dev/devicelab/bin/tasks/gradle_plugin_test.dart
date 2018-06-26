// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

String javaHome;
String errorMessage;

/// Runs the given [testFunction] on a freshly generated Flutter project.
Future<void> runProjectTest(Future<void> testFunction(FlutterProject project)) async {
  final Directory tmp = await Directory.systemTemp.createTemp('gradle');
  final FlutterProject project = await FlutterProject.create(tmp, 'hello');

  try {
    await testFunction(project);
  } finally {
    project.parent.deleteSync(recursive: true);
  }
}

/// Runs the given [testFunction] on a freshly generated Flutter plugin project.
Future<void> runPluginProjectTest(Future<void> testFunction(FlutterPluginProject pluginProject)) async {
  final Directory tmp = await Directory.systemTemp.createTemp('gradle');
  final FlutterPluginProject pluginProject = await FlutterPluginProject.create(tmp, 'aaa');

  try {
    await testFunction(pluginProject);
  } finally {
    pluginProject.parent.deleteSync(recursive: true);
  }
}

void main() async {
  await task(() async {
    section('Find Java');

    javaHome = await findJavaHome();
    if (javaHome == null)
      return new TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    try {
      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleDebug');
        await project.runGradleTask('assembleDebug');
        errorMessage = _validateSnapshotDependency(project, 'build/app.dill');
        if (errorMessage != null) {
          throw new TaskResult.failure(errorMessage);
        }
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleDebug no-preview-dart-2');
        await project.runGradleTask('assembleDebug',
            options: <String>['-Ppreview-dart-2=false']);
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleProfile');
        await project.runGradleTask('assembleProfile');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleRelease');
        await project.runGradleTask('assembleRelease');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleLocal (custom debug build)');
        await project.addCustomBuildType('local', initWith: 'debug');
        await project.runGradleTask('assembleLocal');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleBeta (custom release build)');
        await project.addCustomBuildType('beta', initWith: 'release');
        await project.runGradleTask('assembleBeta');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleFreeDebug (product flavor)');
        await project.addProductFlavor('free');
        await project.runGradleTask('assembleFreeDebug');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew on build script with error');
        await project.introduceError();
        final ProcessResult result =
            await project.resultOfGradleTask('assembleRelease');
        if (result.exitCode == 0)
          throw _failure(
              'Gradle did not exit with error as expected', result);
        final String output = result.stdout + '\n' + result.stderr;
        if (output.contains('GradleException') ||
            output.contains('Failed to notify') ||
            output.contains('at org.gradle'))
          throw _failure(
              'Gradle output should not contain stacktrace', result);
        if (!output.contains('Build failed') || !output.contains('builTypes'))
          throw _failure(
              'Gradle output should contain a readable error message',
              result);
      });

      await runProjectTest((FlutterProject project) async {
        section('flutter build apk on build script with error');
        await project.introduceError();
        final ProcessResult result = await project.resultOfFlutterCommand('build', <String>['apk']);
        if (result.exitCode == 0)
          throw _failure(
              'flutter build apk should fail when Gradle does', result);
        final String output = result.stdout + '\n' + result.stderr;
        if (!output.contains('Build failed') || !output.contains('builTypes'))
          throw _failure(
              'flutter build apk output should contain a readable Gradle error message',
              result);
        if (_hasMultipleOccurrences(output, 'builTypes'))
          throw _failure(
              'flutter build apk should not invoke Gradle repeatedly on error',
              result);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('gradlew assembleDebug on plugin example');
        await pluginProject.runGradleTask('assembleDebug');
        if (!pluginProject.hasDebugApk)
          throw new TaskResult.failure(
              'Gradle did not produce an apk file at the expected place');
      });

      return new TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return new TaskResult.failure(e.toString());
    }
  });
}

TaskResult _failure(String message, ProcessResult result) {
  print('Unexpected process result:');
  print('Exit code: ${result.exitCode}');
  print('Std out  :\n${result.stdout}');
  print('Std err  :\n${result.stderr}');
  return new TaskResult.failure(message);
}

bool _hasMultipleOccurrences(String text, Pattern pattern) {
  return text.indexOf(pattern) != text.lastIndexOf(pattern);
}

class FlutterProject {
  FlutterProject(this.parent, this.name);

  final Directory parent;
  final String name;

  static Future<FlutterProject> create(Directory directory, String name) async {
    await inDirectory(directory, () async {
      await flutter('create', options: <String>[name]);
    });
    return new FlutterProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get androidPath => path.join(rootPath, 'android');

  Future<Null> addCustomBuildType(String name, {String initWith}) async {
    final File buildScript = new File(
      path.join(androidPath, 'app', 'build.gradle'),
    );
    // ignore: deprecated_member_use
    buildScript.openWrite(mode: FileMode.APPEND).write('''

android {
    buildTypes {
        $name {
            initWith $initWith
        }
    }
}
    ''');
  }

  Future<Null> addProductFlavor(String name) async {
    final File buildScript = new File(
      path.join(androidPath, 'app', 'build.gradle'),
    );
    // ignore: deprecated_member_use
    buildScript.openWrite(mode: FileMode.APPEND).write('''

android {
    flavorDimensions "mode"
    productFlavors {
        $name {
            applicationIdSuffix ".$name"
            versionNameSuffix "-$name"
        }
    }
}
    ''');
  }

  Future<Null> introduceError() async {
    final File buildScript = new File(
      path.join(androidPath, 'app', 'build.gradle'),
    );
    await buildScript.writeAsString((await buildScript.readAsString()).replaceAll('buildTypes', 'builTypes'));
  }

  Future<Null> runGradleTask(String task, {List<String> options}) async {
    return _runGradleTask(workingDirectory: androidPath, task: task, options: options);
  }

  Future<ProcessResult> resultOfGradleTask(String task, {List<String> options}) {
    return _resultOfGradleTask(workingDirectory: androidPath, task: task, options: options);
  }

  Future<ProcessResult> resultOfFlutterCommand(String command, List<String> options) {
    return Process.run(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>[command]..addAll(options),
      workingDirectory: rootPath,
    );
  }
}

class FlutterPluginProject {
  FlutterPluginProject(this.parent, this.name);

  final Directory parent;
  final String name;

  static Future<FlutterPluginProject> create(Directory directory, String name) async {
    await inDirectory(directory, () async {
      await flutter('create', options: <String>['-t', 'plugin', name]);
    });
    return new FlutterPluginProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get examplePath => path.join(rootPath, 'example');
  String get exampleAndroidPath => path.join(examplePath, 'android');
  String get debugApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'debug', 'app-debug.apk');

  Future<Null> runGradleTask(String task, {List<String> options}) async {
    return _runGradleTask(workingDirectory: exampleAndroidPath, task: task, options: options);
  }

  bool get hasDebugApk => new File(debugApkPath).existsSync();
}

Future<Null> _runGradleTask({String workingDirectory, String task, List<String> options}) async {
  final ProcessResult result = await _resultOfGradleTask(
      workingDirectory: workingDirectory,
      task: task,
      options: options);
  if (result.exitCode != 0) {
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
  }
  if (result.exitCode != 0)
    throw 'Gradle exited with error';
}

Future<ProcessResult> _resultOfGradleTask({String workingDirectory, String task,
    List<String> options}) {
  final List<String> args = <String>['app:$task'];
  if (options != null) {
    args.addAll(options);
  }
  return Process.run(
    './gradlew',
    args,
    workingDirectory: workingDirectory,
    environment: <String, String>{ 'JAVA_HOME': javaHome }
  );
}

class _Dependencies {
  String target;
  Set<String> dependencies;
  _Dependencies(String depfilePath) {
    final RegExp _separatorExpr = new RegExp(r'([^\\]) ');
    final RegExp _escapeExpr = new RegExp(r'\\(.)');

    // Depfile format:
    // outfile1 outfile2 : file1.dart file2.dart file3.dart file\ 4.dart
    final String contents = new File(depfilePath).readAsStringSync();
    final List<String> colonSeparated = contents.split(': ');
    target = colonSeparated[0].trim();
    dependencies = colonSeparated[1]
        // Put every file on right-hand side on the separate line
        .replaceAllMapped(_separatorExpr, (Match match) => '${match.group(1)}\n')
        .split('\n')
        // Expand escape sequences, so that '\ ', for example,ß becomes ' '
        .map((String path) => path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)).trim())
        .where((String path) => path.isNotEmpty)
        .toSet();
  }
}

/// Returns [null] if target matches [expectedTarget], otherwise returns an error message.
String _validateSnapshotDependency(FlutterProject project, String expectedTarget) {
  final _Dependencies deps = new _Dependencies(
      path.join(project.rootPath, 'build', 'app', 'intermediates',
          'flutter', 'debug', 'snapshot_blob.bin.d'));
  return deps.target == expectedTarget ? null :
    'Dependency file should have $expectedTarget as target. Instead has ${deps.target}';
}

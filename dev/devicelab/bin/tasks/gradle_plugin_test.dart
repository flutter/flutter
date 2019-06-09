// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

String javaHome;
String errorMessage;

/// Runs the given [testFunction] on a freshly generated Flutter project.
Future<void> runProjectTest(Future<void> testFunction(FlutterProject project)) async {
  final Directory tempDir = Directory.systemTemp.createTempSync('flutter_devicelab_gradle_plugin_test.');
  final FlutterProject project = await FlutterProject.create(tempDir, 'hello');

  try {
    await testFunction(project);
  } finally {
    rmTree(tempDir);
  }
}

/// Runs the given [testFunction] on a freshly generated Flutter plugin project.
Future<void> runPluginProjectTest(Future<void> testFunction(FlutterPluginProject pluginProject)) async {
  final Directory tempDir = Directory.systemTemp.createTempSync('flutter_devicelab_gradle_plugin_test.');
  final FlutterPluginProject pluginProject = await FlutterPluginProject.create(tempDir, 'aaa');

  try {
    await testFunction(pluginProject);
  } finally {
    rmTree(tempDir);
  }
}

Future<void> main() async {
  await task(() async {
    section('Find Java');

    javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    try {
      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleDebug without explicit target platform');
        await pluginProject.runGradleTask('assembleDebug');

        if (!pluginProject.hasDebugApk)
          throw TaskResult.failure(
              'Gradle did not produce a debug apk file at: ${pluginProject.debugApkPath}');

        final Iterable<String> apkFiles = await pluginProject.getFilesInApk(pluginProject.debugApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
          'lib/arm64-v8a/libflutter.so',
          'lib/armeabi-v7a/libflutter.so',
          // Debug mode intentionally includes `x86` and `x86_64`.
          'lib/x86/libflutter.so',
          'lib/x86_64/libflutter.so',
        ], apkFiles);

        _checkItDoesNotContain<String>(<String>[
          'lib/arm64-v8a/libapp.so',
          'lib/armeabi-v7a/libapp.so',
          'lib/x86/libapp.so',
          'lib/x86_64/libapp.so',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleDebug with target platform = android-arm');
        await pluginProject.runGradleTask('assembleDebug',
            options: <String>['-Ptarget-platform=android-arm']);

        if (!pluginProject.hasDebugApk)
          throw TaskResult.failure(
              'Gradle did not produce a debug apk file at: ${pluginProject.debugApkPath}');

        final Iterable<String> apkFiles = await pluginProject.getFilesInApk(pluginProject.debugApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
          'lib/armeabi-v7a/libflutter.so',
          // Debug mode intentionally includes `x86` and `x86_64`.
          'lib/x86/libflutter.so',
          'lib/x86_64/libflutter.so',
        ], apkFiles);

        _checkItDoesNotContain<String>(<String>[
          'lib/armeabi-v7a/libapp.so',
          'lib/x86/libapp.so',
          'lib/x86_64/libapp.so',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleRelease without explicit target platform');
        await pluginProject.runGradleTask('assembleRelease');

        if (!pluginProject.hasReleaseApk)
          throw TaskResult.failure(
              'Gradle did not produce a release apk file at: ${pluginProject.releaseApkPath}');

        final Iterable<String> apkFiles = await pluginProject.getFilesInApk(pluginProject.releaseApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/arm64-v8a/libflutter.so',
          'lib/arm64-v8a/libapp.so',
          'lib/armeabi-v7a/libflutter.so',
          'lib/armeabi-v7a/libapp.so',
        ], apkFiles);

        _checkItDoesNotContain<String>(<String>[
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleRelease with target platform = android-arm');
        await pluginProject.runGradleTask('assembleRelease',
            options: <String>['-Ptarget-platform=android-arm']);

        if (!pluginProject.hasReleaseApk)
          throw TaskResult.failure(
              'Gradle did not produce a release apk file at: ${pluginProject.releaseApkPath}');

        final Iterable<String> apkFiles = await pluginProject.getFilesInApk(pluginProject.releaseApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/armeabi-v7a/libflutter.so',
          'lib/armeabi-v7a/libapp.so',
        ], apkFiles);

        _checkItDoesNotContain<String>(<String>[
          'lib/arm64-v8a/libflutter.so',
          'lib/arm64-v8a/libapp.so',
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleRelease with target platform = android-arm64');
        await pluginProject.runGradleTask('assembleRelease',
            options: <String>['-Ptarget-platform=android-arm64']);

        if (!pluginProject.hasReleaseApk)
          throw TaskResult.failure(
              'Gradle did not produce a release apk file at: ${pluginProject.releaseApkPath}');

        final Iterable<String> apkFiles = await pluginProject.getFilesInApk(pluginProject.releaseApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/arm64-v8a/libflutter.so',
          'lib/arm64-v8a/libapp.so',
        ], apkFiles);

        _checkItDoesNotContain<String>(<String>[
          'lib/armeabi-v7a/libflutter.so',
          'lib/armeabi-v7a/libapp.so',
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleRelease with target platform = android-arm, android-arm64');
        await pluginProject.runGradleTask('assembleRelease',
            options: <String>['-Ptarget-platform=android-arm,android-arm64']);

        if (!pluginProject.hasReleaseApk)
          throw TaskResult.failure(
              'Gradle did not produce a release apk at: ${pluginProject.releaseApkPath}');

        final Iterable<String> apkFiles = await pluginProject.getFilesInApk(pluginProject.releaseApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/armeabi-v7a/libflutter.so',
          'lib/armeabi-v7a/libapp.so',
          'lib/arm64-v8a/libflutter.so',
          'lib/arm64-v8a/libapp.so',
        ], apkFiles);

        _checkItDoesNotContain<String>(<String>[
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], apkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('APK content for task assembleRelease with '
                'target platform = android-arm, android-arm64 and split per ABI');
        await pluginProject.runGradleTask('assembleRelease',
            options: <String>['-Ptarget-platform=android-arm,android-arm64', '-Psplit-per-abi=true']);

        if (!pluginProject.hasReleaseArmApk)
          throw TaskResult.failure(
              'Gradle did not produce a release apk at: ${pluginProject.releaseArmApkPath}');

        final Iterable<String> armApkFiles = await pluginProject.getFilesInApk(pluginProject.releaseArmApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/armeabi-v7a/libflutter.so',
          'lib/armeabi-v7a/libapp.so',
        ], armApkFiles);

        _checkItDoesNotContain<String>(<String>[
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], armApkFiles);

        if (!pluginProject.hasReleaseArm64Apk)
          throw TaskResult.failure(
              'Gradle did not produce a release apk at: ${pluginProject.releaseArm64ApkPath}');

        final Iterable<String> arm64ApkFiles = await pluginProject.getFilesInApk(pluginProject.releaseArm64ApkPath);

        _checkItContains<String>(<String>[
          'AndroidManifest.xml',
          'classes.dex',
          'lib/arm64-v8a/libflutter.so',
          'lib/arm64-v8a/libapp.so',
        ], arm64ApkFiles);

        _checkItDoesNotContain<String>(<String>[
          'assets/flutter_assets/isolate_snapshot_data',
          'assets/flutter_assets/kernel_blob.bin',
          'assets/flutter_assets/vm_snapshot_data',
        ], arm64ApkFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('App bundle content for task bundleRelease without explicit target platform');
        await pluginProject.runGradleTask('bundleRelease');

        if (!pluginProject.hasReleaseBundle)
          throw TaskResult.failure(
              'Gradle did not produce a release aab file at: ${pluginProject.releaseBundlePath}');

        final Iterable<String> bundleFiles = await pluginProject.getFilesInAppBundle(pluginProject.releaseBundlePath);

        _checkItContains<String>(<String>[
          'base/manifest/AndroidManifest.xml',
          'base/dex/classes.dex',
          'base/lib/arm64-v8a/libapp.so',
          'base/lib/arm64-v8a/libflutter.so',
          'base/lib/armeabi-v7a/libapp.so',
          'base/lib/armeabi-v7a/libflutter.so',
        ], bundleFiles);
      });

      await runPluginProjectTest((FlutterPluginProject pluginProject) async {
        section('App bundle content for task bundleRelease with target platform = android-arm');
        await pluginProject.runGradleTask('bundleRelease',
            options: <String>['-Ptarget-platform=android-arm']);

        if (!pluginProject.hasReleaseBundle)
          throw TaskResult.failure(
              'Gradle did not produce a release aab file at: ${pluginProject.releaseBundlePath}');

        final Iterable<String> bundleFiles = await pluginProject.getFilesInAppBundle(pluginProject.releaseBundlePath);

        _checkItContains<String>(<String>[
          'base/manifest/AndroidManifest.xml',
          'base/dex/classes.dex',
          'base/lib/armeabi-v7a/libapp.so',
          'base/lib/armeabi-v7a/libflutter.so',
        ], bundleFiles);

        _checkItDoesNotContain<String>(<String>[
          'base/lib/arm64-v8a/libapp.so',
          'base/lib/arm64-v8a/libflutter.so',
        ], bundleFiles);
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleDebug');
        await project.runGradleTask('assembleDebug');
        errorMessage = _validateSnapshotDependency(project, 'build/app.dill');
        if (errorMessage != null) {
          throw TaskResult.failure(errorMessage);
        }
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleProfile');
        await project.runGradleTask('assembleProfile');
      });

      await runProjectTest((FlutterProject project) async {
        section('gradlew assembleRelease');
        await project.runGradleTask('assembleRelease');

        // When the platform-target isn't specified, we generate the snapshots
        // for arm and arm64.
        final List<String> targetPlatforms = <String>[
          'android-arm',
          'android-arm64'
        ];
        for (final String targetPlatform in targetPlatforms) {
          final String androidArmSnapshotPath = path.join(
              project.rootPath,
              'build',
              'app',
              'intermediates',
              'flutter',
              'release',
              targetPlatform);

          final String sharedLibrary = path.join(androidArmSnapshotPath, 'app.so');
          if (!File(sharedLibrary).existsSync()) {
            throw TaskResult.failure('Shared library doesn\'t exist');
          }
        }
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
          throw TaskResult.failure(
              'Gradle did not produce an apk file at the expected place');
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}


void _checkItContains<T>(Iterable<T> values, Iterable<T> collection) {
  for (T value in values) {
    if (!collection.contains(value)) {
      throw TaskResult.failure('Expected to find `$value` in `$collection`.');
    }
  }
}

void _checkItDoesNotContain<T>(Iterable<T> values, Iterable<T> collection) {
  for (T value in values) {
    if (collection.contains(value)) {
      throw TaskResult.failure('Did not expect to find `$value` in `$collection`.');
    }
  }
}

TaskResult _failure(String message, ProcessResult result) {
  print('Unexpected process result:');
  print('Exit code: ${result.exitCode}');
  print('Std out  :\n${result.stdout}');
  print('Std err  :\n${result.stderr}');
  return TaskResult.failure(message);
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
      await flutter('create', options: <String>['--template=app', name]);
    });
    return FlutterProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get androidPath => path.join(rootPath, 'android');

  Future<void> addCustomBuildType(String name, {String initWith}) async {
    final File buildScript = File(
      path.join(androidPath, 'app', 'build.gradle'),
    );

    buildScript.openWrite(mode: FileMode.append).write('''

android {
    buildTypes {
        $name {
            initWith $initWith
        }
    }
}
    ''');
  }

  Future<void> addProductFlavor(String name) async {
    final File buildScript = File(
      path.join(androidPath, 'app', 'build.gradle'),
    );

    buildScript.openWrite(mode: FileMode.append).write('''

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

  Future<void> introduceError() async {
    final File buildScript = File(
      path.join(androidPath, 'app', 'build.gradle'),
    );
    await buildScript.writeAsString((await buildScript.readAsString()).replaceAll('buildTypes', 'builTypes'));
  }

  Future<void> runGradleTask(String task, {List<String> options}) async {
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
      await flutter('create', options: <String>['--template=plugin', name]);
    });
    return FlutterPluginProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get examplePath => path.join(rootPath, 'example');
  String get exampleAndroidPath => path.join(examplePath, 'android');
  String get debugApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'debug', 'app-debug.apk');
  String get releaseApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'release', 'app-release.apk');
  String get releaseArmApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'release', 'app-armeabi-v7a-release.apk');
  String get releaseArm64ApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'release', 'app-arm64-v8a-release.apk');
  String get releaseBundlePath => path.join(examplePath, 'build', 'app', 'outputs', 'bundle', 'release', 'app.aab');

  bool get hasDebugApk => File(debugApkPath).existsSync();
  bool get hasReleaseApk => File(releaseApkPath).existsSync();
  bool get hasReleaseArmApk => File(releaseArmApkPath).existsSync();
  bool get hasReleaseArm64Apk => File(releaseArm64ApkPath).existsSync();
  bool get hasReleaseBundle => File(releaseBundlePath).existsSync();

  Future<void> runGradleTask(String task, {List<String> options}) async {
    return _runGradleTask(workingDirectory: exampleAndroidPath, task: task, options: options);
  }

  Future<Iterable<String>> getFilesInApk(String apk) async {
    final Process unzip = await startProcess(
      'unzip',
      <String>['-v', apk],
      isBot: false, // we just want to test the output, not have any debugging info
    );
    return unzip.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((String line) => line.split(' ').last)
        .toList();
  }

  Future<Iterable<String>> getFilesInAppBundle(String bundle) {
    return getFilesInApk(bundle);
  }
}

Future<void> _runGradleTask({String workingDirectory, String task, List<String> options}) async {
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
  final String gradle = Platform.isWindows ? 'gradlew.bat' : './gradlew';
  print('Running Gradle: ${path.join(workingDirectory, gradle)} ${args.join(' ')}');
  print(File(path.join(workingDirectory, gradle)).readAsStringSync());
  return Process.run(
    gradle,
    args,
    workingDirectory: workingDirectory,
    environment: <String, String>{ 'JAVA_HOME': javaHome },
  );
}

class _Dependencies {
  _Dependencies(String depfilePath) {
    final RegExp _separatorExpr = RegExp(r'([^\\]) ');
    final RegExp _escapeExpr = RegExp(r'\\(.)');

    // Depfile format:
    // outfile1 outfile2 : file1.dart file2.dart file3.dart file\ 4.dart
    final String contents = File(depfilePath).readAsStringSync();
    final List<String> colonSeparated = contents.split(': ');
    target = colonSeparated[0].trim();
    dependencies = colonSeparated[1]
        // Put every file on right-hand side on the separate line
        .replaceAllMapped(_separatorExpr, (Match match) => '${match.group(1)}\n')
        .split('\n')
        // Expand escape sequences, so that '\ ', for example,ß becomes ' '
        .map<String>((String path) => path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)).trim())
        .where((String path) => path.isNotEmpty)
        .toSet();
  }

  String target;
  Set<String> dependencies;
}

/// Returns [null] if target matches [expectedTarget], otherwise returns an error message.
String _validateSnapshotDependency(FlutterProject project, String expectedTarget) {
  final _Dependencies deps = _Dependencies(
      path.join(project.rootPath, 'build', 'app', 'intermediates',
          'flutter', 'debug', 'android-arm', 'snapshot_blob.bin.d'));
  return deps.target == expectedTarget ? null :
    'Dependency file should have $expectedTarget as target. Instead has ${deps.target}';
}

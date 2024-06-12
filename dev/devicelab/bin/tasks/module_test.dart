// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable =
    Platform.isWindows ? '.\\$gradlew' : './$gradlew';
final String fileReadWriteMode = Platform.isWindows ? 'rw-rw-rw-' : 'rw-r--r--';
final String platformLineSep = Platform.isWindows ? '\r\n' : '\n';

/// Combines several TaskFunctions with trivial success value into one.
TaskFunction combine(List<TaskFunction> tasks) {
  return () async {
    for (final TaskFunction task in tasks) {
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
  ModuleTest(
    this.buildTarget, {
    this.gradleVersion = '7.6.3',
  });

  final String buildTarget;
  final String gradleVersion;

  Future<TaskResult> call() async {
    section('Running: $buildTarget');
    section('Find Java');

    final String? javaHome = await findJavaHome();
    if (javaHome == null) {
      return TaskResult.failure('Could not find Java');
    }
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--template=module', 'hello'],
        );
      });

      section('Create package with native assets');

      await flutter(
        'config',
        options: <String>['--enable-native-assets'],
      );

      const String ffiPackageName = 'ffi_package';
      await createFfiPackage(ffiPackageName, tempDir);

      section('Add FFI package');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        'dependencies:$platformLineSep',
        'dependencies:$platformLineSep  $ffiPackageName:$platformLineSep    path: ..${Platform.pathSeparator}$ffiPackageName$platformLineSep',
      );
      await pubspec.writeAsString(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Add read-only asset');

      final File readonlyTxtAssetFile = await File(path.join(
        projectDir.path,
        'assets',
        'read-only.txt'
      ))
      .create(recursive: true);

      if (!exists(readonlyTxtAssetFile)) {
        return TaskResult.failure('Failed to create read-only asset');
      }

      if (!Platform.isWindows) {
        await exec('chmod', <String>[
          '444',
          readonlyTxtAssetFile.path,
        ]);
      }

      content = content.replaceFirst(
        '$platformLineSep  # assets:$platformLineSep',
        '$platformLineSep  assets:$platformLineSep    - assets/read-only.txt$platformLineSep',
      );
      await pubspec.writeAsString(content, flush: true);

      section('Add plugins');

      content = content.replaceFirst(
        '${platformLineSep}dependencies:$platformLineSep',
        '${platformLineSep}dependencies:$platformLineSep  device_info: 2.0.3$platformLineSep  package_info: 2.0.2$platformLineSep',
      );
      await pubspec.writeAsString(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      // TODO(dacoharkes): Implement Add2app. https://github.com/flutter/flutter/issues/129757

      section('Build Flutter module library archive');

      await inDirectory(Directory(path.join(projectDir.path, '.android')), () async {
        await exec(
          gradlewExecutable,
          <String>['flutter:assembleDebug'],
          environment: <String, String>{ 'JAVA_HOME': javaHome },
        );
      });

      final bool aarBuilt = exists(File(path.join(
        projectDir.path,
        '.android',
        'Flutter',
        'build',
        'outputs',
        'aar',
        'flutter-debug.aar',
      )));

      if (!aarBuilt) {
        return TaskResult.failure('Failed to build .aar');
      }

      section('Build ephemeral host app');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['apk'],
        );
      });

      final bool ephemeralHostApkBuilt = exists(File(path.join(
        projectDir.path,
        'build',
        'host',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      )));

      if (!ephemeralHostApkBuilt) {
        return TaskResult.failure('Failed to build ephemeral host .apk');
      }

      section('Clean build');

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      section('Make Android host app editable');

      await inDirectory(projectDir, () async {
        await flutter(
          'make-host-app-editable',
          options: <String>['android'],
        );
      });

      section('Build editable host app');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['apk'],
        );
      });

      final bool editableHostApkBuilt = exists(File(path.join(
        projectDir.path,
        'build',
        'host',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      )));

      if (!editableHostApkBuilt) {
        return TaskResult.failure('Failed to build editable host .apk');
      }

      section('Add to existing Android app');

      final Directory hostApp = Directory(path.join(tempDir.path, 'hello_host_app'));
      mkdir(hostApp);
      recursiveCopy(
        Directory(
          path.join(
            flutterDirectory.path,
            'dev',
            'integration_tests',
            'android_host_app_v2_embedding',
          ),
        ),
        hostApp,
      );
      copy(
        File(path.join(projectDir.path, '.android', gradlew)),
        hostApp,
      );
      copy(
        File(path.join(projectDir.path, '.android', 'gradle', 'wrapper',
            'gradle-wrapper.jar')),
        Directory(path.join(hostApp.path, 'gradle', 'wrapper')),
      );

      // Modify gradle version to passed in version.
      // This is somehow the wrong file.
      final File gradleWrapperProperties = File(path.join(
          hostApp.path, 'gradle', 'wrapper', 'gradle-wrapper.properties'));
      String propertyContent = await gradleWrapperProperties.readAsString();
      propertyContent = propertyContent.replaceFirst(
        'REPLACEME',
        gradleVersion,
      );
      section(propertyContent);
      await gradleWrapperProperties.writeAsString(propertyContent, flush: true);

      final File analyticsOutputFile =
          File(path.join(tempDir.path, 'analytics.log'));

      section('Build debug host APK');

      await inDirectory(hostApp, () async {
        if (!Platform.isWindows) {
          await exec('chmod', <String>['+x', 'gradlew']);
        }
        await exec(gradlewExecutable,
          <String>['app:assembleDebug'],
          environment: <String, String>{
            'JAVA_HOME': javaHome,
            'FLUTTER_ANALYTICS_LOG_FILE': analyticsOutputFile.path,
          },
        );
      });

      section('Check debug APK exists');

      final String debugHostApk = path.join(
        hostApp.path,
        'app',
        'build',
        'outputs',
        'apk',
        'debug',
        'app-debug.apk',
      );
      if (!exists(File(debugHostApk))) {
        return TaskResult.failure('Failed to build debug host APK');
      }

      section('Check files in debug APK');

      checkCollectionContains<String>(<String>[
        ...flutterAssets,
        ...debugAssets,
        ...baseApkFiles,
        'lib/arm64-v8a/lib$ffiPackageName.so',
        'lib/armeabi-v7a/lib$ffiPackageName.so',
      ], await getFilesInApk(debugHostApk));

      section('Check debug AndroidManifest.xml');

      final String androidManifestDebug = await getAndroidManifest(debugHostApk);
      if (!androidManifestDebug.contains('''
        <meta-data
            android:name="flutterProjectType"
            android:value="module" />''')
      ) {
        return TaskResult.failure("Debug host APK doesn't contain metadata: flutterProjectType = module ");
      }

      final String analyticsOutput = analyticsOutputFile.readAsStringSync();
      if (!analyticsOutput.contains('cd24: android')
          || !analyticsOutput.contains('cd25: true')
          || !analyticsOutput.contains('viewName: assemble')) {
        return TaskResult.failure(
          'Building outer app produced the following analytics: "$analyticsOutput" '
          'but not the expected strings: "cd24: android", "cd25: true" and '
          '"viewName: assemble"'
        );
      }

      section('Check file access modes for read-only asset from Flutter module');

      final String readonlyDebugAssetFilePath = path.joinAll(<String>[
        hostApp.path,
        'app',
        'build',
        'intermediates',
        'assets',
        'debug',
        'flutter_assets',
        'assets',
        'read-only.txt',
      ]);
      final File readonlyDebugAssetFile = File(readonlyDebugAssetFilePath);
      if (!exists(readonlyDebugAssetFile)) {
        return TaskResult.failure('Failed to copy read-only asset file');
      }

      String modes = readonlyDebugAssetFile.statSync().modeString();
      print('\nread-only.txt file access modes = $modes');
      if (modes.compareTo(fileReadWriteMode) != 0) {
        return TaskResult.failure('Failed to make assets user-readable and writable');
      }

      section('Build release host APK');

      await inDirectory(hostApp, () async {
        await exec(gradlewExecutable,
          <String>['app:assembleRelease'],
          environment: <String, String>{
            'JAVA_HOME': javaHome,
            'FLUTTER_ANALYTICS_LOG_FILE': analyticsOutputFile.path,
          },
        );
      });

      final String releaseHostApk = path.join(
        hostApp.path,
        'app',
        'build',
        'outputs',
        'apk',
        'release',
        'app-release-unsigned.apk',
      );
      if (!exists(File(releaseHostApk))) {
        return TaskResult.failure('Failed to build release host APK');
      }

      section('Check files in release APK');

      checkCollectionContains<String>(<String>[
        ...flutterAssets,
        ...baseApkFiles,
        'lib/arm64-v8a/lib$ffiPackageName.so',
        'lib/arm64-v8a/libapp.so',
        'lib/arm64-v8a/libflutter.so',
        'lib/armeabi-v7a/lib$ffiPackageName.so',
        'lib/armeabi-v7a/libapp.so',
        'lib/armeabi-v7a/libflutter.so',
      ], await getFilesInApk(releaseHostApk));

      section('Check the NOTICE file is correct');

      await inDirectory(hostApp, () async {
        final File apkFile = File(releaseHostApk);
        final Archive apk = ZipDecoder().decodeBytes(apkFile.readAsBytesSync());
        // Shouldn't be missing since we already checked it exists above.
        final ArchiveFile? noticesFile = apk.findFile('assets/flutter_assets/NOTICES.Z');

        final Uint8List? licenseData = noticesFile?.content as Uint8List?;
        if (licenseData == null) {
          return TaskResult.failure('Invalid license file.');
        }
        final String licenseString = utf8.decode(gzip.decode(licenseData));
        if (!licenseString.contains('skia') || !licenseString.contains('Flutter Authors')) {
          return TaskResult.failure('License content missing.');
        }
      });

      section('Check release AndroidManifest.xml');

      final String androidManifestRelease = await getAndroidManifest(debugHostApk);
      if (!androidManifestRelease.contains('''
        <meta-data
            android:name="flutterProjectType"
            android:value="module" />''')
      ) {
        return TaskResult.failure("Release host APK doesn't contain metadata: flutterProjectType = module ");
      }

      section('Check file access modes for read-only asset from Flutter module');

      final String readonlyReleaseAssetFilePath = path.joinAll(<String>[
        hostApp.path,
        'app',
        'build',
        'intermediates',
        'assets',
        'release',
        'flutter_assets',
        'assets',
        'read-only.txt',
      ]);
      final File readonlyReleaseAssetFile = File(readonlyReleaseAssetFilePath);
      if (!exists(readonlyReleaseAssetFile)) {
        return TaskResult.failure('Failed to copy read-only asset file');
      }

      modes = readonlyReleaseAssetFile.statSync().modeString();
      print('\nread-only.txt file access modes = $modes');
      if (modes.compareTo(fileReadWriteMode) != 0) {
        return TaskResult.failure('Failed to make assets user-readable and writable');
      }

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  }
}

Future<void> main() async {
  await task(combine(<TaskFunction>[
    // ignore: avoid_redundant_argument_values
    ModuleTest('module-gradle-7.6', gradleVersion: '7.6.3').call,
    ModuleTest('module-gradle-7.6', gradleVersion: '7.6-rc-2').call,
  ]));
}

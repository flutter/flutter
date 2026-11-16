// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDirPluginMethodChannels;
  late Directory tempDirPluginFfi;

  setUp(() async {
    tempDirPluginMethodChannels = createResolvedTempDirectorySync('flutter_plugin_test.');
    tempDirPluginFfi = createResolvedTempDirectorySync('flutter_ffi_plugin_test.');
  });

  tearDown(() async {
    tryToDelete(tempDirPluginMethodChannels);
    tryToDelete(tempDirPluginFfi);
  });

  Future<void> testPlugin({required String template, required Directory tempDir}) async {
    final testName = '${template}_test';

    ProcessResult result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=$template',
      '--platforms=android',
      testName,
    ], workingDirectory: tempDir.path);
    if (result.exitCode != 0) {
      throw Exception(
        'flutter create failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
      );
    }

    final Directory exampleAppDir = tempDir.childDirectory(testName).childDirectory('example');

    // Regression test for https://github.com/flutter/flutter/issues/169215,
    // https://github.com/flutter/flutter/issues/196412 and
    // https://github.com/flutter/flutter/issues/196696.
    //
    // The Flutter Gradle Plugin copies the app's build types onto library
    // plugins that don't define them, such as this plugin and integration_test.
    // A library can't use any of the settings below: applicationIdSuffix and
    // isShrinkResources are app-only, and the plugins don't enable the
    // buildConfig or resValues build features. Gradle configures every build
    // type, so building one variant is enough to catch a bad copy.
    final File appGradleFile = exampleAppDir
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');
    expect(appGradleFile, exists);
    appGradleFile.writeAsStringSync('''
${appGradleFile.readAsStringSync()}

android {
    buildFeatures {
        buildConfig = true
        resValues = true
    }
    buildTypes {
        getByName("profile") {
            applicationIdSuffix = ".profile"
            versionNameSuffix = "-PROFILE"
            buildConfigField("String", "BUILD_TYPE_NOTE", "\\"profile\\"")
            resValue("string", "build_type_note", "profile")
        }
        create("staging") {
            initWith(getByName("release"))
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
''');

    result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: exampleAppDir.path);
    expect(result.stderr, isNot(contains('Library projects cannot set applicationIdSuffix')));
    expect(result.stderr, isNot(contains('Resource shrinker cannot be used for libraries')));
    expect(result.stderr, isNot(contains('contains custom BuildConfig fields')));
    expect(result.stderr, isNot(contains('contains custom resource values')));
    if (result.exitCode != 0) {
      throw Exception(
        'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
      );
    }

    final File exampleApk = fileSystem.file(
      fileSystem.path.join(
        exampleAppDir.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk',
      ),
    );
    expect(exampleApk, exists);

    if (template == 'plugin_ffi') {
      // Does not support AGP 3.3.0.
      return;
    }

    // Clean
    result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'clean',
    ], workingDirectory: exampleAppDir.path);
    if (result.exitCode != 0) {
      throw Exception(
        'flutter clean failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
      );
    }

    // Remove Gradle wrapper
    fileSystem
        .directory(fileSystem.path.join(exampleAppDir.path, 'android', 'gradle', 'wrapper'))
        .deleteSync(recursive: true);

    // Enable R8 in gradle.properties
    final File gradleProperties = exampleAppDir
        .childDirectory('android')
        .childFile('gradle.properties');
    expect(gradleProperties, exists);

    gradleProperties.writeAsStringSync('''
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true''');

    // Run flutter build apk using AGP 3.3.0
    result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: exampleAppDir.path);
    if (result.exitCode != 0) {
      throw Exception(
        'flutter build failed: ${result.exitCode}\n${result.stderr}\n${result.stdout}',
      );
    }
    expect(exampleApk, exists);
  }

  test('plugin example can be built using current Flutter Gradle plugin', () async {
    await testPlugin(template: 'plugin', tempDir: tempDirPluginMethodChannels);
  });

  test('FFI plugin example can be built using current Flutter Gradle plugin', () async {
    await testPlugin(template: 'plugin_ffi', tempDir: tempDirPluginFfi);
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('reproduce_186810_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext(
    'appbundle build release successfully packages libapp.so in custom build directory',
    () async {
      final Directory appDir = tempDir.childDirectory('app');

      // 1. Create a native FFI package template.
      final ProcessResult pluginResult = processManager.runSync(<String>[
        flutterBin,
        'create',
        '--template=package_ffi',
        'my_plugin',
      ], workingDirectory: tempDir.path);
      expect(
        pluginResult.exitCode,
        0,
        reason: 'flutter create plugin failed: ${pluginResult.stderr}',
      );

      // 2. Create the app template.
      final ProcessResult createResult = processManager.runSync(<String>[
        flutterBin,
        'create',
        '--template=app',
        '--platforms=android',
        'app',
      ], workingDirectory: tempDir.path);
      expect(createResult.exitCode, 0, reason: 'flutter create failed: ${createResult.stderr}');

      // 3. Add my_plugin to the app's pubspec.yaml.
      final File pubspecFile = appDir.childFile('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);
      String pubspecContent = pubspecFile.readAsStringSync();
      pubspecContent = pubspecContent.replaceFirst(
        'dependencies:',
        'dependencies:\n  my_plugin:\n    path: ../my_plugin',
      );
      pubspecFile.writeAsStringSync(pubspecContent);

      // 4. Downgrade Gradle and AGP in the app's android directory.
      final File gradleWrapperFile = appDir
          .childDirectory('android')
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .childFile('gradle-wrapper.properties');
      if (gradleWrapperFile.existsSync()) {
        String content = gradleWrapperFile.readAsStringSync();
        content = content.replaceFirst('gradle-9.1.0-all.zip', 'gradle-8.14-all.zip');
        gradleWrapperFile.writeAsStringSync(content);
      }
      final File settingsFile = appDir.childDirectory('android').childFile('settings.gradle.kts');
      if (settingsFile.existsSync()) {
        String content = settingsFile.readAsStringSync();
        content = content.replaceFirst('version "9.0.1"', 'version "8.11.1"');
        settingsFile.writeAsStringSync(content);
      }

      // 5. Configure a custom build directory and disable minification in build.gradle.kts of the app.
      final File buildGradleFile = appDir
          .childDirectory('android')
          .childDirectory('app')
          .childFile('build.gradle.kts');
      expect(buildGradleFile.existsSync(), isTrue);
      String buildGradleContent = buildGradleFile.readAsStringSync();

      // Inject custom layout.buildDirectory setting inside the android { ... } block
      buildGradleContent = buildGradleContent.replaceFirst(
        'android {',
        'android {\n    layout.buildDirectory.set(layout.projectDirectory.dir("custom_build_dir"))',
      );

      // Disable minification in release build type
      buildGradleContent = buildGradleContent.replaceFirst(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = signingConfigs.getByName("debug")\n            isMinifyEnabled = false\n            isShrinkResources = false',
      );
      buildGradleFile.writeAsStringSync(buildGradleContent);

      // 6. Run flutter build appbundle --release.
      // The command will return a non-zero exit code because the Flutter tool's post-build validation
      // expects the built .aab to reside in the default build/ directory, but the Gradle build itself
      // should succeed and write to custom_build_dir/.
      final ProcessResult buildResult = processManager.runSync(<String>[
        flutterBin,
        'build',
        'appbundle',
        '--release',
        '--verbose',
      ], workingDirectory: appDir.path);

      final String buildOutput = buildResult.stderr.toString() + buildResult.stdout.toString();
      expect(
        buildOutput,
        contains(
          "Gradle build failed to produce an .aab file. It's likely that this file was generated under",
        ),
        reason: 'Build failed for an unexpected reason: $buildOutput',
      );

      // 7. Verify using apkanalyzer that libapp.so is present inside the built AAB.
      final File localPropertiesFile = appDir
          .childDirectory('android')
          .childFile('local.properties');
      expect(localPropertiesFile.existsSync(), isTrue);
      final String localPropertiesContent = localPropertiesFile.readAsStringSync();
      final sdkDirRegex = RegExp(r'sdk\.dir=(.+)');
      final Match? sdkDirMatch = sdkDirRegex.firstMatch(localPropertiesContent);
      final String sdkPath = sdkDirMatch?.group(1) ?? '';
      expect(sdkPath, isNotEmpty);

      final String apkAnalyzerPath = fileSystem.path.join(
        sdkPath,
        'cmdline-tools',
        'latest',
        'bin',
        Platform.isWindows ? 'apkanalyzer.bat' : 'apkanalyzer',
      );

      final File aabFile = appDir
          .childDirectory('android')
          .childDirectory('app')
          .childDirectory('custom_build_dir')
          .childDirectory('outputs')
          .childDirectory('bundle')
          .childDirectory('release')
          .childFile('app-release.aab');
      expect(
        aabFile.existsSync(),
        isTrue,
        reason: 'AAB file was not built at the expected custom path: ${aabFile.path}',
      );

      final ProcessResult analyzerResult = processManager.runSync(<String>[
        apkAnalyzerPath,
        'files',
        'list',
        aabFile.path,
      ]);

      expect(analyzerResult.exitCode, 0, reason: 'apkanalyzer failed: ${analyzerResult.stderr}');
      final fileList = analyzerResult.stdout.toString();
      expect(
        fileList,
        contains('/base/lib/arm64-v8a/libapp.so'),
        reason: 'libapp.so was not packaged inside the final AAB. Files list:\n$fileList',
      );
    },
  );
}

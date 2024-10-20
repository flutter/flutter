// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/src/interface/file_system_entity.dart';

import '../integration.shard/test_utils.dart';
import '../src/common.dart';
import '../src/context.dart';

const String gradleSettingsFileContent = r'''
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "AGP_REPLACE_ME" apply false
    id "org.jetbrains.kotlin.android" version "KGP_REPLACE_ME" apply false
}

include ":app"

''';

const String agpReplacementString = 'AGP_REPLACE_ME';
const String kgpReplacementString = 'KGP_REPLACE_ME';

const String gradleWrapperPropertiesFileContent = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-GRADLE_REPLACE_ME-all.zip

''';

const String gradleReplacementString = 'GRADLE_REPLACE_ME';

// This test is currently on the preview shard (but not using the preview
// version of Android) because it is the only one using Java 11. This test
// requires Java 11 due to the intentionally low version of Gradle.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDownAll(() async {
    tryToDelete(tempDir as FileSystemEntity);
  });

  Future<ProcessResult> buildFlutterApkWithSpecifiedDependencyVersions({
    required String gradleVersion,
    required String agpVersion,
    required String kgpVersion}) async {
    // Create a new flutter project.
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      'dependency_checker_app',
      '--platforms=android',
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());

    final Directory app = Directory(fileSystem.path.join(tempDir.path, 'dependency_checker_app'));

    // Modify gradle version to passed in version.
    final File gradleWrapperProperties = File(fileSystem.path.join(
        app.path, 'android', 'gradle', 'wrapper', 'gradle-wrapper.properties'));
    final String propertyContent = gradleWrapperPropertiesFileContent.replaceFirst(
      gradleReplacementString,
      gradleVersion,
    );
    await gradleWrapperProperties.writeAsString(propertyContent, flush: true);

    final File gradleSettings = File(fileSystem.path.join(
        app.path, 'android', 'settings.gradle'));
    final String settingsContent = gradleSettingsFileContent
        .replaceFirst(agpReplacementString, agpVersion)
        .replaceFirst(kgpReplacementString, kgpVersion);
    await gradleSettings.writeAsString(settingsContent, flush: true);


    // Ensure that gradle files exists from templates.
    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--debug',
    ], workingDirectory: app.path);
    return result;
  }

  testUsingContext(
      'AGP version out of "warn" support band but in "error" band builds '
          'successfully and prints warning', () async {

    final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(
        gradleVersion: '7.5',
        agpVersion: '7.0.0',
        kgpVersion: '1.7.10'
    );
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Android Gradle Plugin version'));
  });

  testUsingContext(
      'Gradle version out of "warn" support band but in "error" band builds '
          'successfully and prints warning', () async {
    // Create a new flutter project.
    final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(
        gradleVersion: '7.0.2',
        agpVersion: '7.0.0',
        kgpVersion: '1.7.10'
    );
    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Gradle version'));
  });

  testUsingContext(
      'Kotlin version out of "warn" support band but in "error" band builds '
          'successfully and prints warning', () async {
    final ProcessResult result = await buildFlutterApkWithSpecifiedDependencyVersions(
        gradleVersion: '7.5',
        agpVersion: '7.4.0',
        kgpVersion: '1.7.0'
    );

    expect(result, const ProcessResultMatcher());
    expect(result.stderr, contains('Please upgrade your Kotlin version'));
  });
}

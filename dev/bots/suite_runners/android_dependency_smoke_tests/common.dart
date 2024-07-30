// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';

import '../../run_command.dart';


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

class VersionTuple {

  VersionTuple({
    required this.agpVersion,
    required this.gradleVersion,
    required this.kotlinVersion
  });

  String agpVersion;
  String gradleVersion;
  String kotlinVersion;

  @override
  String toString() {
    return '(AGP version: $agpVersion, Gradle version: $gradleVersion, Kotlin version: $kotlinVersion)';
  }
}

Future<void> buildFlutterApkWithSpecifiedDependencyVersions({
  required VersionTuple versions,
  required Directory tempDir,
  required LocalFileSystem localFileSystem,}) async {
  // Create a new flutter project.
  await runCommand(
    'flutter',
      <String>[
        'create',
        'dependency_checker_app',
        '--platforms=android',
      ],
      workingDirectory: tempDir.path,
  );

  final String appPath = '${tempDir.absolute.path}dependency_checker_app';

  // Modify gradle version to passed in version.
  final File gradleWrapperProperties = localFileSystem.file(localFileSystem.path.join(
      appPath, 'android', 'gradle', 'wrapper', 'gradle-wrapper.properties'));
  final String propertyContent = gradleWrapperPropertiesFileContent.replaceFirst(
    gradleReplacementString,
    versions.gradleVersion,
  );
  await gradleWrapperProperties.writeAsString(propertyContent, flush: true);

  final File gradleSettings = localFileSystem.file(localFileSystem.path.join(
      appPath, 'android', 'settings.gradle'));
  final String settingsContent = gradleSettingsFileContent
      .replaceFirst(agpReplacementString, versions.agpVersion)
      .replaceFirst(kgpReplacementString, versions.kotlinVersion);
  await gradleSettings.writeAsString(settingsContent, flush: true);


  // Ensure that gradle files exists from templates.
  await runCommand(
    'flutter',
    <String>[
      'build',
      'apk',
      '--debug',
    ],
    workingDirectory: appPath,
  );

  tempDir.deleteSync();
}

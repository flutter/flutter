// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late String flutterBin;
  late Directory exampleAppDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_plugin_test.');
    flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );
    exampleAppDir = tempDir.childDirectory('aaa').childDirectory('example');

    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=android',
      'aaa',
    ], workingDirectory: tempDir.path);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test(
    'build succeeds targeting string compileSdkVersion',
    () async {
      final File buildGradleFile = exampleAppDir.childDirectory('android').childDirectory('app').childFile('build.gradle');
      // write a build.gradle with compileSdkVersion as `Tiramisu` which is a string preview version
      buildGradleFile.writeAsStringSync(r'''
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

android {
    compileSdkVersion "android-Tiramisu"
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId "com.example.buildtest"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-build-configuration.
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
}
''', flush: true);
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'apk',
        '--debug',
      ], workingDirectory: exampleAppDir.path);
      print(result.stdout);
      print(result.stderr);
      expect(exampleAppDir.childDirectory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('apk')
        .childDirectory('debug')
        .childFile('app-debug.apk').existsSync(), true);
    },
  );
}

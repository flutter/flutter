// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import '../../src/common.dart';
import '../../src/context.dart';

void main() {
   group('injectGradleWrapperIfNeeded', () {
    MemoryFileSystem fileSystem;
    Directory gradleWrapperDirectory;
    GradleUtils gradleUtils;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      gradleWrapperDirectory = fileSystem.directory('cache/bin/cache/artifacts/gradle_wrapper');
      gradleWrapperDirectory.createSync(recursive: true);
      gradleWrapperDirectory
        .childFile('gradlew')
        .writeAsStringSync('irrelevant');
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .createSync(recursive: true);
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .writeAsStringSync('irrelevant');
      gradleUtils = GradleUtils(
        cache: Cache.test(processManager: FakeProcessManager.any(), fileSystem: fileSystem),
        fileSystem: fileSystem,
        platform: FakePlatform(environment: <String, String>{}, operatingSystem: 'linux'),
        logger: BufferLogger.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );
    });

    testWithoutContext('injects the wrapper when all files are missing', () {
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      gradleUtils.injectGradleWrapperIfNeeded(sampleAppAndroid);

      expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .readAsStringSync(),
            'distributionBase=GRADLE_USER_HOME\n'
            'distributionPath=wrapper/dists\n'
            'zipStoreBase=GRADLE_USER_HOME\n'
            'zipStorePath=wrapper/dists\n'
            'distributionUrl=https\\://services.gradle.org/distributions/gradle-6.7-all.zip\n');
    });

    testWithoutContext('injects the wrapper when some files are missing', () {
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      // There's an existing gradlew
      sampleAppAndroid.childFile('gradlew').writeAsStringSync('existing gradlew');

      gradleUtils.injectGradleWrapperIfNeeded(sampleAppAndroid);

      expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);
      expect(sampleAppAndroid.childFile('gradlew').readAsStringSync(),
          equals('existing gradlew'));

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .readAsStringSync(),
          'distributionBase=GRADLE_USER_HOME\n'
          'distributionPath=wrapper/dists\n'
          'zipStoreBase=GRADLE_USER_HOME\n'
          'zipStorePath=wrapper/dists\n'
          'distributionUrl=https\\://services.gradle.org/distributions/gradle-6.7-all.zip\n');
    });

    testWithoutContext('injects the wrapper and the Gradle version is derivated from the AGP version', () {
      const Map<String, String> testCases = <String, String>{
        // AGP version : Gradle version
        '1.0.0': '2.3',
        '3.3.1': '4.10.2',
        '3.0.0': '4.1',
        '3.0.5': '4.1',
        '3.0.9': '4.1',
        '3.1.0': '4.4',
        '3.2.0': '4.6',
        '3.3.0': '4.10.2',
        '3.4.0': '5.6.2',
        '3.5.0': '5.6.2',
        '4.0.0': '6.7',
        '4.0.5': '6.7',
        '4.1.0': '6.7',
      };

      for (final MapEntry<String, String> entry in testCases.entries) {
        final Directory sampleAppAndroid = fileSystem.systemTempDirectory.createTempSync('android');
        sampleAppAndroid
          .childFile('build.gradle')
          .writeAsStringSync('''
  buildscript {
      dependencies {
          classpath 'com.android.tools.build:gradle:${entry.key}'
      }
  }
  ''');
        gradleUtils.injectGradleWrapperIfNeeded(sampleAppAndroid);

        expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);

        expect(sampleAppAndroid
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .childFile('gradle-wrapper.jar')
          .existsSync(), isTrue);

        expect(sampleAppAndroid
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .childFile('gradle-wrapper.properties')
          .existsSync(), isTrue);

        expect(sampleAppAndroid
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .childFile('gradle-wrapper.properties')
          .readAsStringSync(),
              'distributionBase=GRADLE_USER_HOME\n'
              'distributionPath=wrapper/dists\n'
              'zipStoreBase=GRADLE_USER_HOME\n'
              'zipStorePath=wrapper/dists\n'
              'distributionUrl=https\\://services.gradle.org/distributions/gradle-${entry.value}-all.zip\n');
      }
    });

    testWithoutContext('returns the gradlew path', () {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('gradlew').createSync();
      androidDirectory.childFile('gradlew.bat').createSync();
      androidDirectory.childFile('gradle.properties').createSync();

      final FlutterProject flutterProject = FlutterProjectFactory(
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
      ).fromDirectory(fileSystem.currentDirectory);

      expect(gradleUtils.getExecutable(flutterProject),
        androidDirectory.childFile('gradlew').path,
      );
    });
  });
}

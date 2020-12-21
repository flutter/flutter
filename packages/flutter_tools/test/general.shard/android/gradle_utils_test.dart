// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
   group('injectGradleWrapperIfNeeded', () {
    MemoryFileSystem memoryFileSystem;
    Directory tempDir;
    Directory gradleWrapperDirectory;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      tempDir = memoryFileSystem.systemTempDirectory.createTempSync('flutter_artifacts_test.');
      gradleWrapperDirectory = memoryFileSystem.directory(
          memoryFileSystem.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'gradle_wrapper'));
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
    });

    testUsingContext('injects the wrapper when all files are missing', () {
      final Directory sampleAppAndroid = globals.fs.directory('/sample-app/android');
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
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(rootOverride: tempDir, fileSystem: memoryFileSystem),
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('injects the wrapper when some files are missing', () {
      final Directory sampleAppAndroid = globals.fs.directory('/sample-app/android');
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
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(rootOverride: tempDir, fileSystem: memoryFileSystem),
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('injects the wrapper and the Gradle version is derivated from the AGP version', () {
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
        final Directory sampleAppAndroid = globals.fs.systemTempDirectory.createTempSync('android');
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
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(rootOverride: tempDir, fileSystem: memoryFileSystem),
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('GradleUtils.getExecutable', () {
    final String gradlewFilename = globals.platform.isWindows ? 'gradlew.bat' : 'gradlew';

    MemoryFileSystem memoryFileSystem;
    OperatingSystemUtils operatingSystemUtils;
    MockGradleUtils gradleUtils;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      operatingSystemUtils = MockOperatingSystemUtils();
      gradleUtils = MockGradleUtils();
    });

    testUsingContext('returns the gradlew path', () {
      final Directory androidDirectory = globals.fs.directory('/android')..createSync();
      androidDirectory.childFile('gradlew').createSync();
      androidDirectory.childFile('gradlew.bat').createSync();
      androidDirectory.childFile('gradle.properties').createSync();

      when(gradleUtils.injectGradleWrapperIfNeeded(any)).thenReturn(null);

      expect(
        GradleUtils().getExecutable(FlutterProject.current()),
        androidDirectory.childFile(gradlewFilename).path,
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      OperatingSystemUtils: () => operatingSystemUtils,
      GradleUtils: () => gradleUtils,
    });

    testUsingContext('gives execute permission to gradle', () {
      final FlutterProject flutterProject = MockFlutterProject();
      final AndroidProject androidProject = MockAndroidProject();
      when(flutterProject.android).thenReturn(androidProject);

      final FileStat gradleStat = MockFileStat();
      when(gradleStat.mode).thenReturn(444);

      final File gradlew = MockFile();
      when(gradlew.path).thenReturn('gradlew');
      when(gradlew.absolute).thenReturn(gradlew);
      when(gradlew.statSync()).thenReturn(gradleStat);
      when(gradlew.existsSync()).thenReturn(true);

      final Directory androidDirectory = MockDirectory();
      when(androidDirectory.childFile(gradlewFilename)).thenReturn(gradlew);
      when(androidProject.hostAppGradleRoot).thenReturn(androidDirectory);

      when(gradleUtils.injectGradleWrapperIfNeeded(any)).thenReturn(null);

      GradleUtils().getExecutable(flutterProject);

      verify(operatingSystemUtils.makeExecutable(gradlew)).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      OperatingSystemUtils: () => operatingSystemUtils,
      GradleUtils: () => gradleUtils,
    });

    testUsingContext('gives execute permission to gradle even when not all permission flags are set', () {
      final FlutterProject flutterProject = MockFlutterProject();
      final AndroidProject androidProject = MockAndroidProject();
      when(flutterProject.android).thenReturn(androidProject);

      final FileStat gradleStat = MockFileStat();
      when(gradleStat.mode).thenReturn(400);

      final File gradlew = MockFile();
      when(gradlew.path).thenReturn('gradlew');
      when(gradlew.absolute).thenReturn(gradlew);
      when(gradlew.statSync()).thenReturn(gradleStat);
      when(gradlew.existsSync()).thenReturn(true);

      final Directory androidDirectory = MockDirectory();
      when(androidDirectory.childFile(gradlewFilename)).thenReturn(gradlew);
      when(androidProject.hostAppGradleRoot).thenReturn(androidDirectory);

      when(gradleUtils.injectGradleWrapperIfNeeded(any)).thenReturn(null);

      GradleUtils().getExecutable(flutterProject);

      verify(operatingSystemUtils.makeExecutable(gradlew)).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      OperatingSystemUtils: () => operatingSystemUtils,
      GradleUtils: () => gradleUtils,
    });

    testUsingContext("doesn't give execute permission to gradle if not needed", () {
      final FlutterProject flutterProject = MockFlutterProject();
      final AndroidProject androidProject = MockAndroidProject();
      when(flutterProject.android).thenReturn(androidProject);

      final FileStat gradleStat = MockFileStat();
      when(gradleStat.mode).thenReturn(0x49 /* a+x */);

      final File gradlew = MockFile();
      when(gradlew.path).thenReturn('gradlew');
      when(gradlew.absolute).thenReturn(gradlew);
      when(gradlew.statSync()).thenReturn(gradleStat);
      when(gradlew.existsSync()).thenReturn(true);

      final Directory androidDirectory = MockDirectory();
      when(androidDirectory.childFile(gradlewFilename)).thenReturn(gradlew);
      when(androidProject.hostAppGradleRoot).thenReturn(androidDirectory);

      when(gradleUtils.injectGradleWrapperIfNeeded(any)).thenReturn(null);

      GradleUtils().getExecutable(flutterProject);

      verifyNever(operatingSystemUtils.makeExecutable(gradlew));
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      OperatingSystemUtils: () => operatingSystemUtils,
      GradleUtils: () => gradleUtils,
    });
  });
}

class MockAndroidProject extends Mock implements AndroidProject {}
class MockDirectory extends Mock implements Directory {}
class MockFile extends Mock implements File {}
class MockFileStat extends Mock implements FileStat {}
class MockFlutterProject extends Mock implements FlutterProject {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockGradleUtils extends Mock implements GradleUtils {}

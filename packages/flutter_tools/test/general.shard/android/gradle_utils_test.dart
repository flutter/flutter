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
      memoryFileSystem = MemoryFileSystem();
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
            'distributionUrl=https\\://services.gradle.org/distributions/gradle-5.6.2-all.zip\n');
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
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
          'distributionUrl=https\\://services.gradle.org/distributions/gradle-5.6.2-all.zip\n');
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });


  group('migrateToR8', () {
    MemoryFileSystem memoryFileSystem;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
    });

    testUsingContext("throws ToolExit if gradle.properties doesn't exist", () {
      final Directory sampleAppAndroid = globals.fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      expect(() {
        gradleUtils.migrateToR8(sampleAppAndroid);
      }, throwsToolExit(message: 'Expected file ${sampleAppAndroid.path}'));

    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('throws ToolExit if it cannot write gradle.properties', () {
      final MockDirectory sampleAppAndroid = MockDirectory();
      final MockFile gradleProperties = MockFile();

      when(gradleProperties.path).thenReturn('foo/gradle.properties');
      when(gradleProperties.existsSync()).thenReturn(true);
      when(gradleProperties.readAsStringSync()).thenReturn('');
      when(gradleProperties.writeAsStringSync('android.enableR8=true\n', mode: FileMode.append))
        .thenThrow(const FileSystemException());

      when(sampleAppAndroid.childFile('gradle.properties'))
        .thenReturn(gradleProperties);

      expect(() {
        gradleUtils.migrateToR8(sampleAppAndroid);
      },
      throwsToolExit(message:
        'The tool failed to add `android.enableR8=true` to foo/gradle.properties. '
        'Please update the file manually and try this command again.'));
    });

    testUsingContext('does not update gradle.properties if it already uses R8', () {
      final Directory sampleAppAndroid = globals.fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);
      sampleAppAndroid.childFile('gradle.properties')
        .writeAsStringSync('android.enableR8=true');

      gradleUtils.migrateToR8(sampleAppAndroid);

      expect(testLogger.traceText,
        contains('gradle.properties already sets `android.enableR8`'));
      expect(sampleAppAndroid.childFile('gradle.properties').readAsStringSync(),
        equals('android.enableR8=true'));
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('sets android.enableR8=true', () {
      final Directory sampleAppAndroid = globals.fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);
      sampleAppAndroid.childFile('gradle.properties')
        .writeAsStringSync('org.gradle.jvmargs=-Xmx1536M\n');

      gradleUtils.migrateToR8(sampleAppAndroid);

      expect(testLogger.traceText, contains('set `android.enableR8=true` in gradle.properties'));
      expect(
        sampleAppAndroid.childFile('gradle.properties').readAsStringSync(),
        equals(
          'org.gradle.jvmargs=-Xmx1536M\n'
          'android.enableR8=true\n'
        ),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('appends android.enableR8=true to the new line', () {
      final Directory sampleAppAndroid = globals.fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);
      sampleAppAndroid.childFile('gradle.properties')
        .writeAsStringSync('org.gradle.jvmargs=-Xmx1536M');

      gradleUtils.migrateToR8(sampleAppAndroid);

      expect(testLogger.traceText, contains('set `android.enableR8=true` in gradle.properties'));
      expect(
        sampleAppAndroid.childFile('gradle.properties').readAsStringSync(),
        equals(
          'org.gradle.jvmargs=-Xmx1536M\n'
          'android.enableR8=true\n'
        ),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any()
    });
  });

  group('GradleUtils.getExecutable', () {
    final String gradlewFilename = globals.platform.isWindows ? 'gradlew.bat' : 'gradlew';

    MemoryFileSystem memoryFileSystem;
    OperatingSystemUtils operatingSystemUtils;
    MockGradleUtils gradleUtils;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      operatingSystemUtils = MockOperatingSystemUtils();
      gradleUtils = MockGradleUtils();
    });

    testUsingContext('returns the gradlew path', () {
      final Directory androidDirectory = globals.fs.directory('/android')..createSync();
      androidDirectory.childFile('gradlew').createSync();
      androidDirectory.childFile('gradlew.bat').createSync();
      androidDirectory.childFile('gradle.properties').createSync();

      when(gradleUtils.injectGradleWrapperIfNeeded(any)).thenReturn(null);
      when(gradleUtils.migrateToR8(any)).thenReturn(null);

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
      when(gradleUtils.migrateToR8(any)).thenReturn(null);

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
      when(gradleUtils.migrateToR8(any)).thenReturn(null);

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
      when(gradleUtils.migrateToR8(any)).thenReturn(null);

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

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
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

    testUsingContext('Inject the wrapper when all files are missing', () {
      final Directory sampleAppAndroid = fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      injectGradleWrapperIfNeeded(sampleAppAndroid);

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

    testUsingContext('Inject the wrapper when some files are missing', () {
      final Directory sampleAppAndroid = fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      // There's an existing gradlew
      sampleAppAndroid.childFile('gradlew').writeAsStringSync('existing gradlew');

      injectGradleWrapperIfNeeded(sampleAppAndroid);

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

    testUsingContext('Gives executable permission to gradle', () {
      final Directory sampleAppAndroid = fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      // Make gradlew in the wrapper executable.
      os.makeExecutable(gradleWrapperDirectory.childFile('gradlew'));

      injectGradleWrapperIfNeeded(sampleAppAndroid);

      final File gradlew = sampleAppAndroid.childFile('gradlew');
      expect(gradlew.existsSync(), isTrue);
      expect(gradlew.statSync().modeString().contains('x'), isTrue);
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      OperatingSystemUtils: () => OperatingSystemUtils(),
    });
  });
}
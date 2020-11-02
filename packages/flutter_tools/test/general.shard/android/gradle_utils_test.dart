// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' hide gradleUtils;
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
   group('injectGradleWrapperIfNeeded', () {
    MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      final Directory gradleWrapperDirectory = fileSystem.directory(
          fileSystem.path.join('cache', 'bin', 'cache', 'artifacts', 'gradle_wrapper'));
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

    testWithoutContext('injects the wrapper when all files are missing', () {
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      GradleUtils(
        fileSystem: fileSystem,
        operatingSystemUtils: MockOperatingSystemUtils(),
        logger: BufferLogger.test(),
        cache: Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any()),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio()
      ).injectGradleWrapperIfNeeded(sampleAppAndroid);

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
    });

    testWithoutContext('injects the wrapper when some files are missing', () {
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      // There's an existing gradlew
      sampleAppAndroid.childFile('gradlew').writeAsStringSync('existing gradlew');

      GradleUtils(
        fileSystem: fileSystem,
        operatingSystemUtils: MockOperatingSystemUtils(),
        logger: BufferLogger.test(),
        cache: Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any()),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio()
      ).injectGradleWrapperIfNeeded(sampleAppAndroid);

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
    });
  });


  group('migrateToR8', () {
    MemoryFileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testWithoutContext("throws ToolExit if gradle.properties doesn't exist", () {
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      final GradleUtils gradleUtils = GradleUtils(
        fileSystem: fileSystem,
        operatingSystemUtils: MockOperatingSystemUtils(),
        logger: BufferLogger.test(),
        cache: Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any()),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio()
      );

      expect(() => gradleUtils.migrateToR8(sampleAppAndroid),
        throwsToolExit(message: 'Expected file ${sampleAppAndroid.path}'));
    });

    testWithoutContext('does not update gradle.properties if it already uses R8', () {
      final BufferLogger logger = BufferLogger.test();
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);
      sampleAppAndroid.childFile('gradle.properties')
        .writeAsStringSync('android.enableR8=true');

      GradleUtils(
        fileSystem: fileSystem,
        operatingSystemUtils: MockOperatingSystemUtils(),
        logger: logger,
        cache: Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any()),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio()
      ).migrateToR8(sampleAppAndroid);

      expect(logger.traceText,
        contains('gradle.properties already sets `android.enableR8`'));
      expect(sampleAppAndroid.childFile('gradle.properties').readAsStringSync(),
        equals('android.enableR8=true'));
    });

    testWithoutContext('sets android.enableR8=true', () {
     final BufferLogger logger = BufferLogger.test();
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);
      sampleAppAndroid.childFile('gradle.properties')
        .writeAsStringSync('org.gradle.jvmargs=-Xmx1536M\n');

      GradleUtils(
        fileSystem: fileSystem,
        operatingSystemUtils: MockOperatingSystemUtils(),
        logger: logger,
        cache: Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any()),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio()
      ).migrateToR8(sampleAppAndroid);

      expect(logger.traceText, contains('set `android.enableR8=true` in gradle.properties'));
      expect(
        sampleAppAndroid.childFile('gradle.properties').readAsStringSync(),
        equals(
          'org.gradle.jvmargs=-Xmx1536M\n'
          'android.enableR8=true\n'
        ),
      );
    });

    testWithoutContext('appends android.enableR8=true to the new line', () {
      final BufferLogger logger = BufferLogger.test();
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);
      sampleAppAndroid.childFile('gradle.properties')
        .writeAsStringSync('org.gradle.jvmargs=-Xmx1536M');

      GradleUtils(
        fileSystem: fileSystem,
        operatingSystemUtils: MockOperatingSystemUtils(),
        logger: logger,
        cache: Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any()),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio()
      ).migrateToR8(sampleAppAndroid);

      expect(logger.traceText, contains('set `android.enableR8=true` in gradle.properties'));
      expect(
        sampleAppAndroid.childFile('gradle.properties').readAsStringSync(),
        equals(
          'org.gradle.jvmargs=-Xmx1536M\n'
          'android.enableR8=true\n'
        ),
      );
    });
  });

  group('GradleUtils.getExecutable', () {
    MemoryFileSystem fileSystem;
    OperatingSystemUtils operatingSystemUtils;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      operatingSystemUtils = MockOperatingSystemUtils();
    });

    testWithoutContext('returns the gradlew path', () {
     final Directory gradleWrapperDirectory = fileSystem.directory(
        fileSystem.path.join('cache', 'bin', 'cache', 'artifacts', 'gradle_wrapper'));
      gradleWrapperDirectory.createSync(recursive: true);
      gradleWrapperDirectory
        .childFile('gradlew')
        .writeAsStringSync('irrelevant');
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .createSync(recursive: true);
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('gradlew').createSync();
      androidDirectory.childFile('gradlew.bat').createSync();
      androidDirectory.childFile('gradle.properties').createSync();

      expect(
        GradleUtils(
          fileSystem: fileSystem,
          operatingSystemUtils: operatingSystemUtils,
          logger: BufferLogger.test(),
          cache: Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any()),
          platform: FakePlatform(),
          androidStudio: FakeAndroidStudio()
        ).getExecutable(setUpFlutterProject(fileSystem)),
        androidDirectory.childFile('gradlew').path,
      );
    });
  });
}

FlutterProject setUpFlutterProject(FileSystem fileSystem) {
  return FlutterProjectFactory(logger: BufferLogger.test(), fileSystem: fileSystem)
    .fromDirectory(fileSystem.currentDirectory);
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String get javaPath => 'java';
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/android/migrations/android_studio_java_gradle_conflict_migration.dart';
import 'package:flutter_tools/src/android/migrations/top_level_gradle_build_file_migration.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String otherGradleVersionWrapper = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-6.6-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''';

const String gradleWrapperToMigrate = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-6.7-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''';

const String gradleWrapperToMigrateTo = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-7.6.1-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''';

final Version androidStudioDolphin = Version(2021, 3, 1);

void main() {
  group('Android migration', () {
    group('migrate the Gradle "clean" task to lazy declaration', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger bufferLogger;
      late FakeAndroidProject project;
      late File topLevelGradleBuildFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem.test();
        bufferLogger = BufferLogger.test();
        project = FakeAndroidProject(
          root: memoryFileSystem.currentDirectory.childDirectory('android')..createSync(),
        );
        topLevelGradleBuildFile = project.hostAppGradleRoot.childFile('build.gradle');
      });

      testUsingContext('skipped if files are missing', () {
        final TopLevelGradleBuildFileMigration androidProjectMigration = TopLevelGradleBuildFileMigration(
          project,
          bufferLogger,
        );
        androidProjectMigration.migrate();
        expect(topLevelGradleBuildFile.existsSync(), isFalse);
        expect(bufferLogger.traceText, contains('Top-level Gradle build file not found, skipping migration of task "clean".'));
      });

      testUsingContext('skipped if nothing to upgrade', () {
        topLevelGradleBuildFile.writeAsStringSync('''
tasks.register("clean", Delete) {
  delete rootProject.buildDir
}
        ''');

        final TopLevelGradleBuildFileMigration androidProjectMigration = TopLevelGradleBuildFileMigration(
          project,
          bufferLogger,
        );
        final DateTime previousLastModified = topLevelGradleBuildFile.lastModifiedSync();
        androidProjectMigration.migrate();

        expect(topLevelGradleBuildFile.lastModifiedSync(), previousLastModified);
      });

      testUsingContext('top-level build.gradle is migrated', () {
        topLevelGradleBuildFile.writeAsStringSync('''
task clean(type: Delete) {
    delete rootProject.buildDir
}
''');

        final TopLevelGradleBuildFileMigration androidProjectMigration = TopLevelGradleBuildFileMigration(
          project,
          bufferLogger,
        );
        androidProjectMigration.migrate();

        expect(bufferLogger.traceText, contains('Migrating "clean" Gradle task to lazy declaration style.'));
        expect(topLevelGradleBuildFile.readAsStringSync(), equals('''
tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
'''));
      });
    });

    group('migrate the gradle version to one that does not conflict with the '
        'Android Studio-provided java version', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger bufferLogger;
      late FakeAndroidProject project;
      late File gradleWrapperPropertiesFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem.test();
        bufferLogger = BufferLogger.test();
        project = FakeAndroidProject(
          root: memoryFileSystem.currentDirectory.childDirectory('android')..createSync(),
        );
        project.hostAppGradleRoot.childDirectory(gradleDirectoryName)
            .childDirectory(gradleWrapperDirectoryName)
            .createSync(recursive: true);
        gradleWrapperPropertiesFile = project.hostAppGradleRoot
            .childDirectory(gradleDirectoryName)
            .childDirectory(gradleWrapperDirectoryName)
            .childFile(gradleWrapperPropertiesFilename);
      });

      testWithoutContext('skipped if files are missing', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: androidStudioDolphin),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '17'),
        );
        migration.migrate();
        expect(gradleWrapperPropertiesFile.existsSync(), isFalse);
        expect(bufferLogger.traceText, contains(gradleWrapperNotFound));
      });


      testWithoutContext('skipped if android studio is null', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '17'),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(gradleWrapperToMigrate);
        migration.migrate();
        expect(bufferLogger.traceText, contains(androidStudioNotFound));
        expect(gradleWrapperPropertiesFile.readAsStringSync(),
            gradleWrapperToMigrate);
      });

      testWithoutContext('skipped if android studio version is null', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: null),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '17'),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(gradleWrapperToMigrate);
        migration.migrate();
        expect(bufferLogger.traceText, contains(androidStudioNotFound));
        expect(gradleWrapperPropertiesFile.readAsStringSync(),
            gradleWrapperToMigrate);
      });

      testWithoutContext('skipped if error is encountered in migrate()', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: androidStudioFlamingo),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeErroringAndroidSdk(),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(gradleWrapperToMigrate);
        migration.migrate();
        expect(bufferLogger.traceText, contains(errorWhileMigrating));
        expect(gradleWrapperPropertiesFile.readAsStringSync(),
            gradleWrapperToMigrate);
      });

      testWithoutContext('skipped if android studio version is less than flamingo', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: androidStudioDolphin),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '17'),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(gradleWrapperToMigrate);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), gradleWrapperToMigrate);
        expect(bufferLogger.traceText, contains(androidStudioVersionBelowFlamingo));
      });

      testWithoutContext('skipped if bundled java version is less than 17', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: androidStudioFlamingo),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '16'),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(gradleWrapperToMigrate);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), gradleWrapperToMigrate);
        expect(bufferLogger.traceText, contains(javaVersionNot17));
      });

      testWithoutContext('nothing is changed if gradle version not one that was '
          'used by flutter create', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: androidStudioFlamingo),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '17'),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(otherGradleVersionWrapper);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), otherGradleVersionWrapper);
        expect(bufferLogger.traceText, isEmpty);
      });

      testWithoutContext('change is made with one of the specific gradle versions'
          ' we migrate for', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: androidStudioFlamingo),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '17'),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(gradleWrapperToMigrate);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), gradleWrapperToMigrateTo);
        expect(bufferLogger.statusText, contains('Conflict detected between '
            'Android Studio Java version and Gradle version, upgrading Gradle '
            'version from 6.7 to $gradleVersion7_6_1.'));
      });

      testWithoutContext('change is not made when opt out flag is set', () {
        final AndroidStudioJavaGradleConflictMigration migration = AndroidStudioJavaGradleConflictMigration(
          bufferLogger,
          project: project,
          androidStudio: FakeAndroidStudio(version: androidStudioFlamingo),
          fileSystem: FakeFileSystem(),
          processUtils: FakeProcessUtils(),
          platform: FakePlatform(),
          os: FakeOperatingSystemUtils(),
          androidSdk: FakeAndroidSdk(javaVersion: '17'),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(gradleWrapperToMigrate + optOutFlag);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), gradleWrapperToMigrate + optOutFlag);
        expect(bufferLogger.traceText, contains(optOutFlagEnabled));
      });
    });
  });
}

class FakeAndroidProject extends Fake implements AndroidProject {
  FakeAndroidProject({required Directory root}) : hostAppGradleRoot = root;

  @override
  Directory hostAppGradleRoot;
}

class FakeAndroidStudio extends Fake implements AndroidStudio {
  FakeAndroidStudio({required Version? version}) {
    _version = version;
  }

  late Version? _version;

  @override
  Version? get version => _version;
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  FakeAndroidSdk({required String javaVersion}) {
    _javaVersion = javaVersion;
  }

  late String _javaVersion;

  @override
  String? getJavaVersion({
    required AndroidStudio? androidStudio,
    required FileSystem fileSystem,
    required OperatingSystemUtils operatingSystemUtils,
    required Platform platform,
    required ProcessUtils processUtils,
  }) {
    return _javaVersion;
  }
}

class FakeErroringAndroidSdk extends Fake implements AndroidSdk {
  FakeErroringAndroidSdk();

  @override
  String? getJavaVersion({
    required AndroidStudio? androidStudio,
    required FileSystem fileSystem,
    required OperatingSystemUtils operatingSystemUtils,
    required Platform platform,
    required ProcessUtils processUtils,
  }) {
    throw const FileSystemException();
  }
}

class FakeFileSystem extends Fake implements FileSystem {}
class FakeProcessUtils extends Fake implements ProcessUtils {}
class FakePlatform extends Fake implements Platform {}
class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {}

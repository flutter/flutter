// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/migrations/gradle_version_conflict_migration.dart';
import 'package:flutter_tools/src/android/migrations/top_level_gradle_build_file_migration.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const String oldGradleVersionWrapper = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-6.7-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''';

const String recentGradleVersionWrapper = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-7.4-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''';

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
        project.hostAppGradleRoot.childDirectory('gradle').childDirectory('wrapper').createSync(recursive: true);
        gradleWrapperPropertiesFile = project.hostAppGradleRoot
            .childDirectory('gradle')
            .childDirectory('wrapper')
            .childFile('gradle-wrapper.properties');
      });

      testWithoutContext('skipped if files are missing', () {
        final GradleVersionConflictMigration migration = GradleVersionConflictMigration(
          project,
          bufferLogger,
          FakeAndroidStudioDolphin(),
        );
        migration.migrate();
        expect(gradleWrapperPropertiesFile.existsSync(), isFalse);
        expect(bufferLogger.traceText, contains('gradle-wrapper.properties not found, skipping gradle version compatibility check.'));
      });


      testWithoutContext('skipped if android studio is null', () {
        final GradleVersionConflictMigration migration = GradleVersionConflictMigration(
          project,
          bufferLogger,
          null,
        );
        gradleWrapperPropertiesFile.writeAsStringSync(oldGradleVersionWrapper);
        migration.migrate();
        expect(bufferLogger.traceText, contains('Android Studio version could not be detected, '
            'skipping gradle version compatibility check.'));
      });

      testWithoutContext('skipped if android studio version is less than flamingo', () {
        final GradleVersionConflictMigration migration = GradleVersionConflictMigration(
          project,
          bufferLogger,
          FakeAndroidStudioDolphin(),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(oldGradleVersionWrapper);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), oldGradleVersionWrapper);
        expect(bufferLogger.traceText, isEmpty);
      });

      testWithoutContext('nothing is changed if gradle version is high enough', () {
        final GradleVersionConflictMigration migration = GradleVersionConflictMigration(
          project,
          bufferLogger,
          FakeAndroidStudioFlamingo(),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(recentGradleVersionWrapper);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), recentGradleVersionWrapper);
        expect(bufferLogger.traceText, isEmpty);
      });

      testWithoutContext('change is made with sub 7 gradle', () {
        final GradleVersionConflictMigration migration = GradleVersionConflictMigration(
          project,
          bufferLogger,
          FakeAndroidStudioFlamingo(),
        );
        gradleWrapperPropertiesFile.writeAsStringSync(oldGradleVersionWrapper);
        migration.migrate();
        expect(gradleWrapperPropertiesFile.readAsStringSync(), recentGradleVersionWrapper);
        expect(bufferLogger.traceText, contains('Conflict detected between versions of Android Studio '
            'and gradle, upgrading gradle version from 6.7 to 7.4'));
      });
    });
  });
}

class FakeAndroidProject extends Fake implements AndroidProject {
  FakeAndroidProject({required Directory root}) : hostAppGradleRoot = root;

  @override
  Directory hostAppGradleRoot;
}

class FakeAndroidStudioDolphin extends Fake implements AndroidStudio {
  @override
  Version get version => Version(2021, 3, 1);
}

class FakeAndroidStudioFlamingo extends Fake implements AndroidStudio {
  @override
  Version get version => Version(2022, 2, 1);
}

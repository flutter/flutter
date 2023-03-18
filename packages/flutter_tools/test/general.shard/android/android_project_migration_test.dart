// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/migrations/gradle_lazy_clean_task_migration.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/project_migrator.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('Android migration', () {
    
    testWithoutContext('migrators succeed', () {
      final FakeAndroidMigrator fakeAndroidMigrator = FakeAndroidMigrator();
      final ProjectMigration migration = ProjectMigration(<ProjectMigrator>[fakeAndroidMigrator]);
      migration.run();
    });

    group('migrate the Gradle "clean" task to lazy declaration', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger bufferLogger;
      late FakeAndroidProject project;
      late File topLevelGradleBuildFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        bufferLogger = BufferLogger.test();
        project = FakeAndroidProject();
        project.hostAppGradleRoot = memoryFileSystem.currentDirectory;
        topLevelGradleBuildFile = project.hostAppGradleRoot.childFile('build.gradle');
      });

      testUsingContext('skipped if files are missing', () {
        final GradleLazyCleanTaskMigrator androidProjectMigration = GradleLazyCleanTaskMigrator(
          project,
          bufferLogger,
        );
        androidProjectMigration.migrate();
        expect(topLevelGradleBuildFile.existsSync(), isFalse);

        expect(bufferLogger.traceText, contains('Top-level Gradle build file not found, skipping "clean" task migration.'));
        expect(testLogger.statusText, isEmpty);
      });

      testUsingContext('skipped if nothing to upgrade', () {
        topLevelGradleBuildFile.writeAsStringSync('''
tasks.register("clean", Delete) {
  delete rootProject.buildDir
}
        ''');

        final GradleLazyCleanTaskMigrator androidProjectMigration = GradleLazyCleanTaskMigrator(
          project,
          bufferLogger,
        );
        final DateTime topLevelGradleBuildFileLastModified = topLevelGradleBuildFile.lastModifiedSync();
        androidProjectMigration.migrate();

        expect(topLevelGradleBuildFile.lastModifiedSync(), topLevelGradleBuildFileLastModified);
        expect(testLogger.statusText, isEmpty);
      });

      testUsingContext('top-level build.gradle is migrated', () {
        topLevelGradleBuildFile.writeAsStringSync('''
task clean(type: Delete) {
    delete rootProject.buildDir
}
''');

        final GradleLazyCleanTaskMigrator androidProjectMigration = GradleLazyCleanTaskMigrator(
          project,
          bufferLogger,
        );
        androidProjectMigration.migrate();

        expect(bufferLogger.traceText, contains('Migrating "clean" Gradle task to lazy declaration style.'));
        expect(testLogger.statusText, isEmpty);

        expect(topLevelGradleBuildFile.readAsStringSync(), equals('''
tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
'''));
      });
    });
  });
}

// TODO: FakeAndroidProject is already present in test/general.shard/plugins_test.dart – should we use it here?
class FakeAndroidProject extends Fake implements AndroidProject {
  @override
  Directory hostAppGradleRoot = MemoryFileSystem.test().currentDirectory;
}

class FakeAndroidMigrator extends ProjectMigrator {
  FakeAndroidMigrator()
    : super(BufferLogger.test());

  @override
  void migrate() {}

  @override
  String migrateLine(String line) {
    return line;
  }
}

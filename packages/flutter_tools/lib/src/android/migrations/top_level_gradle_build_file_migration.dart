// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

const String _eagerCleanTaskDeclaration = '''
task clean(type: Delete) {
    delete rootProject.buildDir
}
''';

const String _lazyCleanTaskDeclaration = '''
tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
''';

/// Migrate the Gradle "clean" task to use modern, lazy declaration style.
class TopLevelGradleBuildFileMigration extends ProjectMigrator {
  TopLevelGradleBuildFileMigration(
    AndroidProject project,
    super.logger,
  ) : _topLevelGradleBuildFile = project.hostAppGradleRoot.childFile('build.gradle');

  final File _topLevelGradleBuildFile;

  @override
  void migrate() {
    if (!_topLevelGradleBuildFile.existsSync()) {
      logger.printTrace('Top-level Gradle build file not found, skipping "clean" task migration.');
      return;
    }

    processFileLines(_topLevelGradleBuildFile);
  }

  @override
  String migrateFileContents(String fileContents) {
    String newContents = fileContents;
    if (newContents.contains(_eagerCleanTaskDeclaration)) {
      logger.printTrace('Migrating "clean" Gradle task to lazy declaration style.');
      newContents = newContents.replaceAll(_eagerCleanTaskDeclaration, _lazyCleanTaskDeclaration);
    }
    
    return newContents;
  }
}

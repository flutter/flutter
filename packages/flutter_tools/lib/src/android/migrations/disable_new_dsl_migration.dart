// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

const String _newDslFlagText = '''
# This newDsl flag was added automatically by Flutter migrator
android.newDsl=false''';

// Gradle Properties are case sensitive so the AGP config must be this exact flag
final RegExp _newDslRegex = RegExp(r'^\s*android\.newDsl(?=[ \t=:])', multiLine: true);

/// Migrate from enabled new DSL by default to disabled new DSL by default.
/// For more details see: https://developer.android.com/build/releases/agp-9-0-0-release-notes#android-gradle-plugin-changed-dsl
class DisableNewDslMigration extends ProjectMigrator {
  DisableNewDslMigration(AndroidProject project, super.logger)
    : _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (!_gradlePropertiesFile.existsSync()) {
      logger.printTrace(
        'The gradle.properties file was not found. Creating it with a disabled new DSL flag.',
      );
      try {
        await _gradlePropertiesFile.writeAsString('$_newDslFlagText\n');
      } on FileSystemException catch (e) {
        logger.printError('Failed to write to the gradle.properties during migration: $e');
      }
      return;
    }

    String contents;

    try {
      contents = await _gradlePropertiesFile.readAsString();
    } on FileSystemException catch (e) {
      logger.printError('Failed to read gradle.properties during migration: $e');
      return;
    }

    // Skip migration if the newDsl flag already exists
    if (contents.contains(_newDslRegex)) {
      logger.printTrace(
        'The developer has already configured the new DSL flag, skipping migration.',
      );
      return;
    }

    // TODO(jesswon): Remove once try/catch is added to the write processFile: https://github.com/flutter/flutter/issues/184595
    try {
      processFileLines(_gradlePropertiesFile);
    } on FileSystemException catch (e) {
      logger.printError('Failed to process/migrate the gradle.properties during migration: $e');
    }
  }

  @override
  String migrateFileContents(String fileContents) {
    logger.printTrace('Migrating to disable new DSL by default.');

    final bool hasNewDsl = fileContents.contains(_newDslRegex);

    if (hasNewDsl) {
      return fileContents;
    }

    final propertyToAppend = StringBuffer();
    propertyToAppend.writeln(_newDslFlagText);

    final prefix = fileContents.isEmpty || fileContents.endsWith('\n') ? '' : '\n';

    return '$fileContents$prefix$propertyToAppend';
  }
}

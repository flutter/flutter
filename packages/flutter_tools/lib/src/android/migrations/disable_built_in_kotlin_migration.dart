// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

const String _builtInKotlinFlagText = '''
# This builtInKotlin flag was added automatically by Flutter migrator
android.builtInKotlin=false''';

// Gradle Properties are case sensitive so the AGP config must be this exact flag
final RegExp _builtInKotlinRegex = RegExp(
  r'^\s*android\.builtInKotlin(?=[ \t=:])',
  multiLine: true,
);

/// Migrate from enabled Built-in Kotlin by default to disabled Built-in Kotlin by default.
/// For more details see: http://flutter.dev/go/android-built-in-kotlin-support
class DisableBuiltInKotlinMigration extends ProjectMigrator {
  DisableBuiltInKotlinMigration(AndroidProject project, super.logger)
    : _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (!_gradlePropertiesFile.existsSync()) {
      logger.printTrace(
        'The gradle.properties file was not found. Creating it with a disabled Built-in Kotlin flag.',
      );
      try {
        await _gradlePropertiesFile.writeAsString('$_builtInKotlinFlagText\n');
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

    // Skip migration if the Built-in Kotlin flag already exists
    if (contents.contains(_builtInKotlinRegex)) {
      logger.printTrace(
        'The developer has already configured the Built-In Kotlin flag, skipping migration.',
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
    logger.printTrace('Migrating to disable Built-in Kotlin by default.');

    final bool hasBuiltInKotlin = fileContents.contains(_builtInKotlinRegex);

    if (hasBuiltInKotlin) {
      return fileContents;
    }

    final propertyToAppend = StringBuffer();
    propertyToAppend.writeln(_builtInKotlinFlagText);

    final prefix = fileContents.isEmpty || fileContents.endsWith('\n') ? '' : '\n';

    return '$fileContents$prefix$propertyToAppend';
  }
}

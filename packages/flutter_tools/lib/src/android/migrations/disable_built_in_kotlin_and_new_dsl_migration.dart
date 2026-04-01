// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

const String _newDslFlag = '''
# The newDsl flag was added automatically by Flutter migrator
android.newDsl=false''';
const String _builtInKotlinFlag = '''
# The builtInKotlin flag was added automatically by Flutter migrator
android.builtInKotlin=false''';

// Gradle Properties are case sensitive so the AGP config must be this exact flag
final RegExp _newDslRegex = RegExp(r'^\s*android\.newDsl(?=[ \t=:])', multiLine: true);
final RegExp _builtInKotlinRegex = RegExp(
  r'^\s*android\.builtInKotlin(?=[ \t=:])',
  multiLine: true,
);

/// Migrate from enabled Built-in Kotlin by default to disabled Built-in Kotlin by default.
/// For more details see: http://flutter.dev/go/android-built-in-kotlin-support
class DisableBuiltInKotlinAndNewDslMigration extends ProjectMigrator {
  DisableBuiltInKotlinAndNewDslMigration(AndroidProject project, super.logger)
    : _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (_gradlePropertiesFile.existsSync()) {
      final String contents = await _gradlePropertiesFile.readAsString();

      // Skip migration if both flags are already present
      if (contents.contains(_builtInKotlinRegex) && contents.contains(_newDslRegex)) {
        logger.printTrace(
          'The developer has already configured the Built-In Kotlin and new DSL flags, skipping migration.',
        );
        return;
      }

      processFileLines(_gradlePropertiesFile);
    } else {
      logger.printTrace(
        'The gradle.properties file was not found. Creating it with disabled Built-in Kotlin and disabled new DSL flag.',
      );
      await _gradlePropertiesFile.writeAsString('$_newDslFlag\n$_builtInKotlinFlag\n');
    }
  }

  @override
  String migrateFileContents(String fileContents) {
    final bool hasNewDsl = fileContents.contains(_newDslRegex);
    final bool hasBuiltInKotlin = fileContents.contains(_builtInKotlinRegex);

    if (hasNewDsl && hasBuiltInKotlin) {
      return fileContents;
    }

    final propertiesToAppend = StringBuffer();
    if (!hasNewDsl) {
      logger.printTrace('Migrating to disable new DSL by default.');
      propertiesToAppend.writeln(_newDslFlag);
    }
    if (!hasBuiltInKotlin) {
      logger.printTrace('Migrating to disable Built-in Kotlin by default.');
      propertiesToAppend.writeln(_builtInKotlinFlag);
    }

    final prefix = fileContents.isEmpty || fileContents.endsWith('\n') ? '' : '\n';

    return '$fileContents$prefix$propertiesToAppend';
  }
}

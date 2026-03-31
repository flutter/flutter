// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

const String _disableBuiltInKotlin = r'''
android.newDsl=false
android.builtInKotlin=false
''';

// Gradle Properties are case sensitive so the AGP config must be this exact flag
const String _builtInKotlinFlag = 'android.builtInKotlin';
final RegExp _builtInKotlinRegex = RegExp(r'android\.builtInKotlin');

/// Migrate from enabled Built-in Kotlin by default to disabled Built-in Kotlin by default.
/// For more details see: [link here]
class DisableBuiltInKotlinMigration extends ProjectMigrator {
  DisableBuiltInKotlinMigration(AndroidProject project, super.logger)
    : _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (_gradlePropertiesFile.existsSync()) {
      final String contents = await _gradlePropertiesFile.readAsString();

      if (contents.contains(_builtInKotlinRegex)) {
        logger.printTrace(
          'The developer has already configured the Built-In Kotlin flag, skipping migration of disabling Built-in Kotlin.',
        );
        return;
      }

      processFileLines(_gradlePropertiesFile);
    } else {
      logger.printTrace(
        'The gradle.properties file was not found. Creating it with disabled Built-in Kotlin.',
      );
      await _gradlePropertiesFile.writeAsString('$_disableBuiltInKotlin\n');
    }
  }

  @override
  String migrateFileContents(String fileContents) {
    logger.printTrace('Migrating to disable Built-in Kotlin by default.');

    final String prefix = fileContents.isEmpty || fileContents.endsWith('\n') ? '' : '\n';

    final String newContents = '$fileContents$prefix$_disableBuiltInKotlin\n';

    return newContents;
  }
}

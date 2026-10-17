// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';
import '../gradle_errors.dart';
import 'disable_new_dsl_migration.dart';

/// The comment the app and module templates write above `android.newDsl=false`.
const String _templateMarker = '# This newDsl flag was added by the Flutter template';

/// The comment [DisableNewDslMigration] writes above `android.newDsl=false`.
const String _migratorMarker = '# This newDsl flag was added automatically by Flutter migrator';

/// Matches an `android.newDsl` entry whose value is `false`, with any of the
/// `=`, `:` or whitespace separators that a properties file allows.
final RegExp _newDslFalseRegex = RegExp(r'^\s*android\.newDsl(?:\s*[=:]\s*|\s+)false\s*$');

/// Removes the `android.newDsl=false` opt-out that Flutter wrote to
/// `gradle.properties`, in projects for which
/// [usesBuiltInKotlinWithoutKotlinAndroidPlugin] is true.
///
/// Only a Flutter marker comment immediately followed by an
/// `android.newDsl=false` line is removed. An opt-out without a marker, or with
/// another value, belongs to the developer and stays.
class RemoveNewDslOptOutMigration extends ProjectMigrator {
  RemoveNewDslOptOutMigration(AndroidProject project, super.logger)
    : _project = project,
      _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final AndroidProject _project;
  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (!_gradlePropertiesFile.existsSync()) {
      return;
    }
    final String contents;
    try {
      contents = await _gradlePropertiesFile.readAsString();
    } on FileSystemException catch (e) {
      logger.printError('Failed to read gradle.properties during migration: $e');
      return;
    }
    if (!usesBuiltInKotlinWithoutKotlinAndroidPlugin(_project, contents)) {
      return;
    }
    processFileLines(_gradlePropertiesFile);
  }

  @override
  String migrateFileContents(String fileContents) {
    final List<String> lines = fileContents.split('\n');
    final kept = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final String marker = lines[i].trim();
      if ((marker == _templateMarker || marker == _migratorMarker) &&
          i + 1 < lines.length &&
          _newDslFalseRegex.hasMatch(lines[i + 1])) {
        i++;
        continue;
      }
      kept.add(lines[i]);
    }
    if (kept.length == lines.length) {
      return fileContents;
    }
    logger.printStatus(
      'Removed the android.newDsl=false opt-out that Flutter added to '
      '${_gradlePropertiesFile.path}, because the project uses built-in Kotlin. '
      'The Android Gradle Plugin builds this project with android.newDsl enabled. '
      'For details, see $kOptOutOfNewDslDocsUrl',
    );
    return kept.join('\n');
  }
}

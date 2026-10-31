// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';
import '../gradle_errors.dart';
import 'disable_new_dsl_migration.dart';

export 'disable_new_dsl_migration.dart' show kNewDslMigratorMarker, kNewDslTemplateMarker;

/// Matches an `android.newDsl` entry whose value is `false` with any `=`, `:`,
/// or whitespace separator allowed by `.properties` files.
final RegExp _newDslFalseRegex = RegExp(r'^\s*android\.newDsl(?:\s*[=:]\s*|\s+)false\s*$');

/// Removes the `android.newDsl=false` opt-out written by Flutter in
/// `gradle.properties` once [hasBuiltInKotlinEnabled] is true and
/// [AndroidProject.newDslBlockingBuildFiles] is empty.
///
/// Only a [kNewDslTemplateMarker] or [kNewDslMigratorMarker] line immediately
/// followed by an `android.newDsl=false` line is removed. An `android.newDsl`
/// entry without a Flutter marker, or with another value, belongs to the
/// developer and remains untouched.
class RemoveNewDslOptOutMigration extends ProjectMigrator {
  RemoveNewDslOptOutMigration(AndroidProject project, super.logger, {this._disableNewDslMigration})
    : _project = project,
      _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final AndroidProject _project;
  final File _gradlePropertiesFile;
  final DisableNewDslMigration? _disableNewDslMigration;

  @override
  Future<void> migrate() async {
    if (_disableNewDslMigration?.addedOptOut ?? false) {
      return;
    }
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
    if (!_hasRemovableMarkerPair(contents) || !hasBuiltInKotlinEnabled(contents)) {
      return;
    }
    final List<String>? blocking = _project.newDslBlockingBuildFiles;
    if (blocking == null) {
      return;
    }
    if (blocking.isNotEmpty) {
      logger.printTrace(
        'Keeping the android.newDsl=false opt-out because the following build '
        'files block the new DSL: ${blocking.join(', ')}',
      );
      return;
    }
    processFileLines(_gradlePropertiesFile);
  }

  static bool _hasRemovableMarkerPair(String fileContents) {
    final List<String> lines = fileContents.split('\n');
    for (var i = 0; i + 1 < lines.length; i++) {
      final String marker = lines[i].trim();
      if ((marker == kNewDslTemplateMarker || marker == kNewDslMigratorMarker) &&
          _newDslFalseRegex.hasMatch(lines[i + 1])) {
        return true;
      }
    }
    return false;
  }

  @override
  String migrateFileContents(String fileContents) {
    final List<String> lines = fileContents.split('\n');
    final kept = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final String marker = lines[i].trim();
      if ((marker == kNewDslTemplateMarker || marker == kNewDslMigratorMarker) &&
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
    logger.printWarning(
      'Removed the android.newDsl=false opt-out added by Flutter to '
      '${_gradlePropertiesFile.path} because built-in Kotlin is enabled and '
      'scanned Gradle build files use no APIs removed by the new DSL. '
      'Android Gradle Plugin now builds the project with android.newDsl enabled. '
      'If the build fails, add android.newDsl=false back without the comment '
      '"$kNewDslTemplateMarker" or "$kNewDslMigratorMarker" above android.newDsl=false; '
      'Flutter removes android.newDsl=false again when preceded by either comment. '
      'For details, see $kOptOutOfNewDslDocsUrl',
    );
    return kept.join('\n');
  }
}

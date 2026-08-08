// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';
import '../gradle_errors.dart';

/// The marker comment the project templates placed above the opt-out.
const String _templateMarkerComment = '# This newDsl flag was added by the Flutter template';

/// The marker comment [the former DisableNewDslMigration] placed above the opt-out.
const String _migratorMarkerComment =
    '# This newDsl flag was added automatically by Flutter migrator';

/// Matches the opt-out line Flutter wrote (tolerating whitespace and the `:` separator).
/// Deliberately does NOT match `android.newDsl=true` or other values: if the developer
/// edited the line, it is theirs now and stays.
final RegExp _newDslOptOutPattern = RegExp(r'^\s*android\.newDsl\s*[=:]\s*false\s*$');

/// Removes the `android.newDsl=false` opt-out that Flutter previously added to
/// `gradle.properties` (through the project templates and through the former
/// `DisableNewDslMigration`), now that the Flutter Gradle Plugin supports the Android
/// Gradle Plugin's new DSL.
///
/// Only line pairs Flutter wrote are removed: one of the two known marker comments
/// immediately followed by the `android.newDsl=false` property line. The removal is
/// anchored on the `android.newDsl` property line - never on marker wording alone -
/// so the adjacent `android.builtInKotlin` marker/flag lines (owned by the separate
/// built-in Kotlin migration) and hand-added opt-outs are never touched.
class RemoveNewDslOptOutMigration extends ProjectMigrator {
  RemoveNewDslOptOutMigration(AndroidProject project, super.logger)
    : _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (!_gradlePropertiesFile.existsSync()) {
      // Nothing to remove. (The former DisableNewDslMigration created this file when it
      // was missing, writing only the marker and the flag; that case is handled by the
      // pair removal below, leaving an empty file.)
      return;
    }
    processFileLines(_gradlePropertiesFile);
  }

  @override
  String migrateFileContents(String fileContents) {
    final List<String> lines = fileContents.split('\n');
    final result = <String>[];
    var removed = false;
    for (var i = 0; i < lines.length; i++) {
      final String trimmed = lines[i].trim();
      final bool isFlutterMarker =
          trimmed == _templateMarkerComment || trimmed == _migratorMarkerComment;
      if (isFlutterMarker && i + 1 < lines.length && _newDslOptOutPattern.hasMatch(lines[i + 1])) {
        // Skip the marker comment and the opt-out line it annotates.
        i++;
        removed = true;
        continue;
      }
      result.add(lines[i]);
    }
    if (!removed) {
      return fileContents;
    }
    logger.printStatus(
      'Removed the android.newDsl opt-out that Flutter previously added to '
      '${_gradlePropertiesFile.path}; Android builds now use the Android Gradle '
      "Plugin's new DSL. If your Android build fails after this change, see "
      '$kNewDslBreakingChangeDocsUrl',
    );
    return result.join('\n');
  }
}

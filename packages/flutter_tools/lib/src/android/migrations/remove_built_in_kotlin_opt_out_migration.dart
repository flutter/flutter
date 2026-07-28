// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

/// The marker comment the project templates placed above the opt-out.
const String _templateMarkerComment = '# This builtInKotlin flag was added by the Flutter template';

/// The marker comment [the former DisableBuiltInKotlinMigration] placed above the opt-out.
const String _migratorMarkerComment =
    '# This builtInKotlin flag was added automatically by Flutter migrator';

/// Matches the opt-out line Flutter wrote (tolerating whitespace and the `:` separator).
/// Deliberately does NOT match `android.builtInKotlin=true` or other values: if the developer
/// edited the line, it is theirs now and stays.
final RegExp _builtInKotlinOptOutPattern = RegExp(r'^\s*android\.builtInKotlin\s*[=:]\s*false\s*$');

/// Removes the `android.builtInKotlin=false` opt-out that Flutter previously added to
/// `gradle.properties` (through the project templates and through the former
/// `DisableBuiltInKotlinMigration`), now that the Flutter Gradle Plugin requires the Android
/// Gradle Plugin's built-in Kotlin support when using the new DSL on AGP 9+.
///
/// Only line pairs Flutter wrote are removed: one of the two known marker comments
/// immediately followed by the `android.builtInKotlin=false` property line. The removal is
/// anchored on the `android.builtInKotlin` property line - never on marker wording alone -
/// so hand-added opt-outs are never touched.
class RemoveBuiltInKotlinOptOutMigration extends ProjectMigrator {
  RemoveBuiltInKotlinOptOutMigration(AndroidProject project, super.logger)
    : _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (!_gradlePropertiesFile.existsSync()) {
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
      if (isFlutterMarker &&
          i + 1 < lines.length &&
          _builtInKotlinOptOutPattern.hasMatch(lines[i + 1])) {
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
      'Removed the android.builtInKotlin opt-out that Flutter previously added to '
      '${_gradlePropertiesFile.path}; Android builds now use the Android Gradle '
      "Plugin's built-in Kotlin support.",
    );
    return result.join('\n');
  }
}

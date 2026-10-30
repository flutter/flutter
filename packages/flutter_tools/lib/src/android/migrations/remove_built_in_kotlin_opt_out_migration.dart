// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';
import '../gradle_errors.dart';

/// The comment the app and module templates wrote above
/// `android.builtInKotlin=false`.
const String _templateMarker = '# This builtInKotlin flag was added by the Flutter template';

/// The comment `DisableBuiltInKotlinMigration` writes above
/// `android.builtInKotlin=false`.
const String _migratorMarker =
    '# This builtInKotlin flag was added automatically by Flutter migrator';

/// Matches an `android.builtInKotlin` entry whose value is `false`, with any of
/// the `=`, `:` or whitespace separators that a properties file allows.
final RegExp _builtInKotlinFalseRegex = RegExp(
  r'^\s*android\.builtInKotlin(?:\s*[=:]\s*|\s+)false\s*$',
);

/// Removes the `android.builtInKotlin=false` opt-out that Flutter wrote to
/// `gradle.properties`, when the app does not apply the `kotlin-android`
/// plugin.
///
/// Only a Flutter marker comment immediately followed by an
/// `android.builtInKotlin=false` line is removed. An opt-out without a marker,
/// or with another value, belongs to the developer and stays.
///
/// Runs before `RemoveNewDslOptOutMigration`, which then removes the
/// `android.newDsl=false` opt-out in the same build.
class RemoveBuiltInKotlinOptOutMigration extends ProjectMigrator {
  RemoveBuiltInKotlinOptOutMigration(AndroidProject project, super.logger)
    : _project = project,
      _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final AndroidProject _project;
  final File _gradlePropertiesFile;

  @override
  Future<void> migrate() async {
    if (!_gradlePropertiesFile.existsSync()) {
      return;
    }
    // Apps that apply kotlin-android fail to build with built-in Kotlin, so
    // their opt-out stays until the developer removes the plugin.
    if (_project.appliesKotlinAndroidPlugin) {
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
          _builtInKotlinFalseRegex.hasMatch(lines[i + 1])) {
        i++;
        continue;
      }
      kept.add(lines[i]);
    }
    if (kept.length == lines.length) {
      return fileContents;
    }
    logger.printWarning(
      'Removed the android.builtInKotlin=false opt-out that Flutter added to '
      '${_gradlePropertiesFile.path}, because the app does not apply the '
      'kotlin-android plugin. The Android Gradle Plugin builds this project with '
      'built-in Kotlin. If a plugin still applies kotlin-android, the build fails '
      'and names that plugin. To keep the opt-out, add android.builtInKotlin=false '
      'and android.newDsl=false without the Flutter comment above them. '
      'For details, see $kMigrateToBuiltInKotlinDocsUrl',
    );
    return kept.join('\n');
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

/// Marker comment written above `android.newDsl=false` by the app and module
/// templates.
const String kNewDslTemplateMarker = '# This newDsl flag was added by the Flutter template';

/// Marker comment written above `android.newDsl=false` by [DisableNewDslMigration].
const String kNewDslMigratorMarker =
    '# This newDsl flag was added automatically by Flutter migrator';

const String _newDslFlagText = '$kNewDslMigratorMarker\nandroid.newDsl=false';

// Gradle Properties are case sensitive, matching exact `android.newDsl` entries
// including bare keys without an `=`, `:`, or whitespace separator.
final RegExp _newDslRegex = RegExp(r'^[ \t]*android\.newDsl(?=[ \t=:]|\r?$)', multiLine: true);

/// Captures the value of each `android.builtInKotlin` entry, including bare
/// keys with an empty value.
///
/// A `.properties` file separates a key from a value with `=`, `:`, or
/// whitespace; bare keys without a separator resolve to `""` in
/// `java.util.Properties`, while trailing whitespace remains part of the value.
final RegExp _builtInKotlinEntryRegex = RegExp(
  r'^[ \t]*android\.builtInKotlin(?:(?:[ \t]*[=:][ \t]*|[ \t]+)([^\r\n]*)|[ \t]*)\r?$',
  multiLine: true,
);

/// Whether [gradleProperties] sets `android.builtInKotlin` to `true`.
///
/// Evaluates the last `android.builtInKotlin` entry in [gradleProperties]
/// using `java.util.Properties` parsing rules and case-insensitive `'true'`
/// matching, mirroring `FlutterPluginUtils.isBuiltInKotlinEnabled` via Kotlin
/// `String.toBoolean()`. Trailing whitespace (such as `'true '`) or a bare
/// `android.builtInKotlin` line without a value evaluates to `false`.
bool hasBuiltInKotlinEnabled(String gradleProperties) {
  final RegExpMatch? lastEntry = _builtInKotlinEntryRegex.allMatches(gradleProperties).lastOrNull;
  return (lastEntry?.group(1) ?? '').toLowerCase() == 'true';
}

/// Whether [project] can build with `android.newDsl` enabled.
///
/// Requires [hasBuiltInKotlinEnabled] on [gradleProperties] and an empty
/// [AndroidProject.newDslBlockingBuildFiles] list across the app, module,
/// deferred component, and native Android plugin Gradle build scripts.
///
/// Applying `kotlin-android` or referencing legacy AGP DSL and variant APIs
/// fails when `android.newDsl` is enabled, so projects with blocking build
/// files or unresolved plugin metadata keep the `android.newDsl=false`
/// opt-out.
bool isReadyForNewDsl(AndroidProject project, String gradleProperties) {
  if (!hasBuiltInKotlinEnabled(gradleProperties)) {
    return false;
  }
  return project.newDslBlockingBuildFiles?.isEmpty ?? false;
}

/// Migrate from enabled new DSL by default to disabled new DSL by default.
///
/// Projects where [isReadyForNewDsl] returns `true` skip adding the opt-out
/// and build with the Android Gradle Plugin default (`android.newDsl=true`).
/// For details, see: https://developer.android.com/build/releases/agp-9-0-0-release-notes#android-gradle-plugin-changed-dsl
class DisableNewDslMigration extends ProjectMigrator {
  DisableNewDslMigration(AndroidProject project, super.logger)
    : _project = project,
      _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final AndroidProject _project;
  final File _gradlePropertiesFile;

  bool _addedOptOut = false;

  /// Whether [migrate] wrote `android.newDsl=false` during the current run.
  bool get addedOptOut => _addedOptOut;

  @override
  Future<void> migrate() async {
    _addedOptOut = false;
    if (!_gradlePropertiesFile.existsSync()) {
      logger.printTrace(
        'The gradle.properties file was not found. Creating it with a disabled new DSL flag.',
      );
      try {
        await _gradlePropertiesFile.writeAsString('$_newDslFlagText\n');
        _addedOptOut = true;
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

    // Skip migration if the newDsl flag already exists.
    if (contents.contains(_newDslRegex)) {
      logger.printTrace(
        'The developer has already configured the new DSL flag, skipping migration.',
      );
      return;
    }

    if (isReadyForNewDsl(_project, contents)) {
      logger.printTrace(
        'Built-in Kotlin is enabled and scanned Gradle build files do not '
        'block the new DSL, skipping the new DSL opt-out.',
      );
      return;
    }

    processFileLines(_gradlePropertiesFile);
  }

  @override
  String migrateFileContents(String fileContents) {
    logger.printTrace('Migrating to disable new DSL by default.');

    final bool hasNewDsl = fileContents.contains(_newDslRegex);

    if (hasNewDsl) {
      return fileContents;
    }

    _addedOptOut = true;
    final propertyToAppend = StringBuffer();
    propertyToAppend.writeln(_newDslFlagText);

    final prefix = fileContents.isEmpty || fileContents.endsWith('\n') ? '' : '\n';

    return '$fileContents$prefix$propertyToAppend';
  }
}

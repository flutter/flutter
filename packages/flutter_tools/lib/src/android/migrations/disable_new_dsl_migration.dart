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

/// Captures the value of each `android.builtInKotlin` entry. A properties file
/// separates a key from its value with `=`, `:` or whitespace. Like
/// `java.util.Properties`, the value keeps its trailing whitespace.
final RegExp _builtInKotlinValueRegex = RegExp(
  r'^[ \t]*android\.builtInKotlin(?:[ \t]*[=:][ \t]*|[ \t]+)(.*)$',
  multiLine: true,
);

/// Whether [gradleProperties], the content of the project's `gradle.properties`
/// file, enables built-in Kotlin, and the app does not apply the
/// `kotlin-android` plugin.
///
/// The `kotlin-android` plugin fails to apply when `android.newDsl` is enabled,
/// so only these projects can build without the `android.newDsl=false` opt-out.
///
/// The last `android.builtInKotlin` entry decides. Its value, as
/// `java.util.Properties` reads it, must be `true`, ignoring case: the test that
/// the Flutter Gradle Plugin's `FlutterPluginUtils.isBuiltInKotlinEnabled`
/// applies through Kotlin's `String.toBoolean()`. A value with trailing
/// whitespace, such as `true `, is not `true`.
/// Without an entry this returns false: `DisableBuiltInKotlinMigration` adds
/// `android.builtInKotlin=false` to such projects.
bool usesBuiltInKotlinWithoutKotlinAndroidPlugin(AndroidProject project, String gradleProperties) {
  final RegExpMatch? lastEntry = _builtInKotlinValueRegex.allMatches(gradleProperties).lastOrNull;
  final bool builtInKotlin = lastEntry != null && lastEntry.group(1)!.toLowerCase() == 'true';
  return builtInKotlin && !project.appliesKotlinAndroidPlugin;
}

/// Migrate from enabled new DSL by default to disabled new DSL by default.
///
/// Projects for which [usesBuiltInKotlinWithoutKotlinAndroidPlugin] is true
/// are skipped; `RemoveNewDslOptOutMigration` handles them.
/// For more details see: https://developer.android.com/build/releases/agp-9-0-0-release-notes#android-gradle-plugin-changed-dsl
class DisableNewDslMigration extends ProjectMigrator {
  DisableNewDslMigration(AndroidProject project, super.logger)
    : _project = project,
      _gradlePropertiesFile = project.hostAppGradleRoot.childFile('gradle.properties');

  final AndroidProject _project;
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

    if (usesBuiltInKotlinWithoutKotlinAndroidPlugin(_project, contents)) {
      logger.printTrace(
        'The project uses built-in Kotlin without the kotlin-android plugin, '
        'skipping the new DSL opt-out.',
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

    final propertyToAppend = StringBuffer();
    propertyToAppend.writeln(_newDslFlagText);

    final prefix = fileContents.isEmpty || fileContents.endsWith('\n') ? '' : '\n';

    return '$fileContents$prefix$propertyToAppend';
  }
}

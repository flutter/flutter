// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../base/version.dart';
import '../../project.dart';
import '../gradle_utils.dart';

/// Gradle version that projects are upgraded to.
///
/// Matches the minimum Gradle version that the Flutter Gradle Plugin accepts
/// (`errorGradleVersion` in DependencyVersionChecker.kt) and is the minimum
/// Gradle version required by [agpTargetVersion].
@visibleForTesting
const gradleTargetVersion = '9.3.1';

/// Android Gradle Plugin (AGP) version that projects are upgraded to.
///
/// Matches the minimum AGP version that the Flutter Gradle Plugin accepts
/// (`errorAGPVersion` in DependencyVersionChecker.kt).
@visibleForTesting
const agpTargetVersion = '9.1.1';

/// Kotlin Gradle Plugin (KGP) version that projects are upgraded to.
///
/// Matches the minimum KGP version that the Flutter Gradle Plugin accepts
/// (`errorKGPVersion` in DependencyVersionChecker.kt).
@visibleForTesting
const kgpTargetVersion = '2.4.10';

/// Gradle versions written by `flutter create` that are upgraded to
/// [gradleTargetVersion].
///
/// Only versions that a Flutter release wrote into a project template are
/// listed, so that versions chosen by a developer are left alone.
///  * 9.1.0: Flutter 3.44.0 to 3.44.9.
@visibleForTesting
const gradleVersionsToUpgradeFrom = <String>{'9.1.0'};

/// AGP versions written by `flutter create` that are upgraded to
/// [agpTargetVersion].
///  * 9.0.1: Flutter 3.44.0 to 3.44.9.
///  * 9.1.0: Flutter 3.47.0 to 3.47.9.
@visibleForTesting
const agpVersionsToUpgradeFrom = <String>{'9.0.1', '9.1.0'};

/// KGP versions written by `flutter create` that are upgraded to
/// [kgpTargetVersion].
///  * 2.3.20: Flutter 3.44.0 to 3.44.9.
///  * 2.4.0: Flutter 3.47.0 to 3.47.9.
@visibleForTesting
const kgpVersionsToUpgradeFrom = <String>{'2.3.20', '2.4.0'};

/// Text that can be added anywhere in `settings.gradle` or
/// `settings.gradle.kts`, for example in a comment, to opt out of the AGP and
/// KGP upgrade.
@visibleForTesting
const pluginVersionOptOutFlag = 'NoFlutterAndroidPluginVersionUpgrade';

/// Text that can be added anywhere in `gradle-wrapper.properties`, for example
/// in a comment, to opt out of the Gradle upgrade.
///
/// This is the same flag that `AndroidStudioJavaGradleConflictMigration`
/// honors.
@visibleForTesting
const gradleWrapperOptOutFlag = 'NoFlutterGradleWrapperUpgrade';

/// Matches an uncommented AGP or KGP plugin declaration with a version in a
/// `plugins {}` block. For example:
///
///  * Kotlin DSL: `id("com.android.application") version "9.1.0" apply false`
///  * Groovy DSL: `id "com.android.library" version "9.1.0" apply false`
///
/// `(?<=^[^/]*)` skips declarations that follow `//` on the same line.
final _pluginVersionRegExp = RegExp(
  r'''(?<=^[^/]*)\bid\s*\(?\s*(?<quote>['"])(?<id>com\.android\.application|com\.android\.library|org\.jetbrains\.kotlin\.android)\k<quote>\s*\)?\s+version\s*\(?\s*\k<quote>(?<version>[^'"]+)\k<quote>''',
);

/// Upgrades the Gradle, Android Gradle Plugin (AGP), and Kotlin Gradle Plugin
/// (KGP) versions that earlier `flutter create` templates wrote, and that are
/// now below the minimum versions that Flutter supports.
///
/// Without this migration, projects created with Flutter 3.44 or 3.47 fail to
/// build after the developer upgrades Flutter, even though the developer never
/// changed these versions.
///
/// To avoid surprising developers who manage these versions themselves, this
/// migration:
///
///  * Only changes versions that a Flutter template wrote (see
///    [gradleVersionsToUpgradeFrom], [agpVersionsToUpgradeFrom] and
///    [kgpVersionsToUpgradeFrom]), and only to the minimum supported version,
///    which is a patch or minor upgrade within the same major version.
///  * Only changes declarations in the `plugins {}` block of
///    `settings.gradle(.kts)` and the `distributionUrl` of
///    `gradle-wrapper.properties`, which is where the templates put them.
///    Versions that come from a version catalog or a variable aren't changed.
///  * Only upgrades AGP when the project's Gradle version is known to support
///    [agpTargetVersion].
///  * Can be turned off with [pluginVersionOptOutFlag] or
///    [gradleWrapperOptOutFlag].
class TemplateDependencyVersionMigration extends ProjectMigrator {
  TemplateDependencyVersionMigration(AndroidProject project, super.logger)
    : _gradleWrapperPropertiesFile = getGradleWrapperFile(project.hostAppGradleRoot),
      _settingsGradleFile = _findSettingsFile(project.hostAppGradleRoot);

  final File _gradleWrapperPropertiesFile;
  final File? _settingsGradleFile;

  /// The Gradle version that the project uses after the wrapper is migrated.
  ///
  /// Null if the version can't be determined.
  Version? _gradleVersionAfterMigration;

  /// Which file [migrateLine] is processing.
  var _migratingSettings = false;

  /// Whether [migrateLine] changed a version in the file being processed.
  var _changedVersion = false;

  static File? _findSettingsFile(Directory hostAppGradleRoot) {
    for (final name in <String>['settings.gradle', 'settings.gradle.kts']) {
      final File file = hostAppGradleRoot.childFile(name);
      if (file.existsSync()) {
        return file;
      }
    }
    return null;
  }

  @override
  Future<void> migrate() async {
    _migrateGradleWrapper();
    _migrateSettings();
  }

  void _migrateGradleWrapper() {
    if (!_gradleWrapperPropertiesFile.existsSync()) {
      logger.printTrace(
        '${_gradleWrapperPropertiesFile.basename} not found, skipping Gradle version upgrade.',
      );
      return;
    }
    final String contents;
    try {
      contents = _gradleWrapperPropertiesFile.readAsStringSync();
    } on FileSystemException catch (e) {
      logger.printTrace('Failed to read ${_gradleWrapperPropertiesFile.basename}: $e');
      return;
    }
    final RegExpMatch? match = gradleOrgVersionMatch.firstMatch(contents);
    final String? currentVersion = match?.group(1);
    if (currentVersion == null) {
      logger.printTrace(
        'Gradle version not found in ${_gradleWrapperPropertiesFile.basename}, '
        'skipping Gradle version upgrade.',
      );
      return;
    }
    _gradleVersionAfterMigration = Version.parse(currentVersion);
    if (!gradleVersionsToUpgradeFrom.contains(currentVersion)) {
      return;
    }
    if (contents.contains(gradleWrapperOptOutFlag)) {
      logger.printTrace(
        "Skipping Gradle version upgrade because '$gradleWrapperOptOutFlag' is in "
        '${_gradleWrapperPropertiesFile.basename}.',
      );
      return;
    }
    _migratingSettings = false;
    _changedVersion = false;
    processFileLines(_gradleWrapperPropertiesFile);
    if (_changedVersion) {
      _printOptOutHint(_gradleWrapperPropertiesFile, gradleWrapperOptOutFlag);
    }
    // processFileLines leaves the file unchanged when it can't write it.
    final RegExpMatch? migrated = gradleOrgVersionMatch.firstMatch(
      _gradleWrapperPropertiesFile.readAsStringSync(),
    );
    _gradleVersionAfterMigration = Version.parse(migrated?.group(1));
  }

  void _migrateSettings() {
    final File? settingsFile = _settingsGradleFile;
    if (settingsFile == null) {
      logger.printTrace(
        'settings.gradle(.kts) not found, skipping Android Gradle Plugin and '
        'Kotlin Gradle Plugin version upgrade.',
      );
      return;
    }
    final String contents;
    try {
      contents = settingsFile.readAsStringSync();
    } on FileSystemException catch (e) {
      logger.printTrace('Failed to read ${settingsFile.basename}: $e');
      return;
    }
    if (contents.contains(pluginVersionOptOutFlag)) {
      logger.printTrace(
        'Skipping Android Gradle Plugin and Kotlin Gradle Plugin version upgrade '
        "because '$pluginVersionOptOutFlag' is in ${settingsFile.basename}.",
      );
      return;
    }
    _migratingSettings = true;
    _changedVersion = false;
    processFileLines(settingsFile);
    if (_changedVersion) {
      _printOptOutHint(settingsFile, pluginVersionOptOutFlag);
    }
  }

  void _printOptOutHint(File file, String optOutFlag) {
    logger.printStatus(
      'To keep the previous version, undo the change and add a comment '
      "containing '$optOutFlag' to ${file.basename}.",
    );
  }

  @override
  String? migrateLine(String line) {
    return _migratingSettings ? _migrateSettingsLine(line) : _migrateGradleWrapperLine(line);
  }

  String _migrateGradleWrapperLine(String line) {
    final RegExpMatch? match = gradleOrgVersionMatch.firstMatch(line);
    final String? currentVersion = match?.group(1);
    if (currentVersion == null || !gradleVersionsToUpgradeFrom.contains(currentVersion)) {
      return line;
    }
    logger.printStatus(
      'Upgrading Gradle from $currentVersion to $gradleTargetVersion, the minimum '
      'version that Flutter supports.',
    );
    _changedVersion = true;
    return line.replaceFirst('gradle-$currentVersion-', 'gradle-$gradleTargetVersion-');
  }

  String _migrateSettingsLine(String line) {
    final RegExpMatch? match = _pluginVersionRegExp.firstMatch(line);
    if (match == null) {
      return line;
    }
    final String pluginId = match.namedGroup('id')!;
    final String currentVersion = match.namedGroup('version')!;
    final String quote = match.namedGroup('quote')!;

    final String pluginName;
    final String targetVersion;
    if (pluginId == 'org.jetbrains.kotlin.android') {
      if (!kgpVersionsToUpgradeFrom.contains(currentVersion)) {
        return line;
      }
      pluginName = 'the Kotlin Gradle Plugin';
      targetVersion = kgpTargetVersion;
    } else {
      if (!agpVersionsToUpgradeFrom.contains(currentVersion)) {
        return line;
      }
      final Version? gradleVersion = _gradleVersionAfterMigration;
      if (gradleVersion == null || gradleVersion < Version.parse(gradleTargetVersion)!) {
        logger.printTrace(
          'Skipping Android Gradle Plugin upgrade from $currentVersion because '
          'AGP $agpTargetVersion requires Gradle $gradleTargetVersion or later, '
          'and the project uses Gradle ${gradleVersion ?? 'of an unknown version'}.',
        );
        return line;
      }
      pluginName = 'the Android Gradle Plugin';
      targetVersion = agpTargetVersion;
    }
    logger.printStatus(
      'Upgrading $pluginName from $currentVersion to $targetVersion, the minimum '
      'version that Flutter supports.',
    );
    _changedVersion = true;
    final int versionStart = match.end - quote.length - currentVersion.length;
    return line.replaceRange(versionStart, versionStart + currentVersion.length, targetVersion);
  }
}

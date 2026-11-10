// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../base/version.dart';
import '../../project.dart';
import '../gradle_utils.dart';
import 'android_studio_java_gradle_conflict_migration.dart' show optOutFlag;

// The targets are the lowest versions that the Flutter Gradle Plugin accepts
// without a warning (the `warn*Version` values in DependencyVersionChecker.kt),
// so that a migrated project builds cleanly and keeps building after the next
// increase of the minimum versions. template_dependency_version_migration_test.dart
// keeps them in sync.
//
// When those versions are raised, add the template versions of the releases
// that are now below them to the `*ToUpgrade` sets, including the previous
// targets below. See packages/flutter_tools/lib/src/android/README.md.

/// Gradle version that projects are upgraded to.
@visibleForTesting
const templateGradleUpgradeTarget = '9.5.0';

/// Android Gradle Plugin (AGP) version that projects are upgraded to when
/// their Gradle version supports it.
@visibleForTesting
const templateAgpUpgradeTarget = '9.3.1';

/// AGP version that projects are upgraded to when their Gradle version
/// doesn't support [templateAgpUpgradeTarget], for example because the Gradle
/// wrapper pins a checksum or opted out of upgrades.
///
/// The minimum AGP version that Flutter supports (`errorAGPVersion` in
/// DependencyVersionChecker.kt).
@visibleForTesting
const minimumAgpUpgradeTarget = '9.1.1';

/// Kotlin Gradle Plugin (KGP) version that projects are upgraded to.
@visibleForTesting
const templateKgpUpgradeTarget = '2.4.20';

/// Gradle versions that `flutter create` wrote and that are upgraded to
/// [templateGradleUpgradeTarget].
///
/// Only template versions are listed, so that versions chosen by a developer
/// are left alone.
///  * 9.1.0: Flutter 3.44 and the pre-releases before Flutter 3.47.
///  * 9.3.1: Flutter 3.47 and the pre-releases before Flutter 3.50.
@visibleForTesting
const templateGradleVersionsToUpgrade = <String>{'9.1.0', '9.3.1'};

/// AGP versions that `flutter create` wrote and that are upgraded to
/// [templateAgpUpgradeTarget] or [minimumAgpUpgradeTarget].
///  * 9.0.1: Flutter 3.44 and the pre-releases before Flutter 3.47.
///  * 9.1.0: Flutter 3.47 and the pre-releases before Flutter 3.50.
@visibleForTesting
const templateAgpVersionsToUpgrade = <String>{'9.0.1', '9.1.0'};

/// KGP versions that `flutter create` wrote and that are upgraded to
/// [templateKgpUpgradeTarget].
///  * 2.3.20: Flutter 3.44 and the pre-releases before Flutter 3.47.
///  * 2.4.0: Flutter 3.47 and the pre-releases before Flutter 3.50.
@visibleForTesting
const templateKgpVersionsToUpgrade = <String>{'2.3.20', '2.4.0'};

/// Text that can be added anywhere in `settings.gradle` or
/// `settings.gradle.kts`, for example in a comment, to opt out of
/// [TemplateAndroidPluginVersionMigration].
@visibleForTesting
const pluginVersionOptOutFlag = 'NoFlutterAndroidPluginVersionUpgrade';

/// Gradle distribution types that `flutter create` and `gradle wrapper` write.
///
/// Other suffixes, such as `rc-1-all`, are pre-releases whose upgraded URL
/// might not exist.
const _gradleDistributionTypes = <String>{'all', 'bin'};

/// Matches an uncommented `distributionSha256Sum` in `gradle-wrapper.properties`.
final _distributionSha256SumRegExp = RegExp(r'^\s*distributionSha256Sum\s*[=:]', multiLine: true);

/// Matches an AGP or KGP plugin declaration with a literal version in a
/// `plugins {}` block, such as:
///
///  * Kotlin DSL: `id("com.android.application") version "9.1.0" apply false`
///  * Groovy DSL: `id 'com.android.library' version '9.1.0' apply false`
///
/// `(?<=^[^/*]*)` skips declarations in `//` and `/* */` comments.
///
/// This is separate from the AGP and KGP version regexes in gradle_utils.dart
/// because it must also match `com.android.library`, which editable add-to-app
/// host apps declare, and needs the text before the version as a group so that
/// only the version is replaced.
final _pluginDeclarationRegExp = RegExp(
  r'''(?<=^[^/*]*)(?<prefix>\bid\s*\(?\s*(?<quote>['"])(?<id>com\.android\.application|com\.android\.library|org\.jetbrains\.kotlin\.android)\k<quote>\s*\)?\s+version\s*\(?\s*\k<quote>)(?<version>[^'"]+)(?=\k<quote>)''',
);

/// The Gradle version in [gradleWrapperFile], or null if it's missing or
/// can't be read.
Version? _readGradleVersion(File gradleWrapperFile) {
  if (!gradleWrapperFile.existsSync()) {
    return null;
  }
  try {
    final RegExpMatch? match = gradleOrgVersionMatch.firstMatch(
      gradleWrapperFile.readAsStringSync(),
    );
    if (match == null || !_gradleDistributionTypes.contains(match.group(2))) {
      return null;
    }
    return Version.parse(match.group(1));
  } on FileSystemException {
    return null;
  }
}

/// Upgrades the Gradle version that earlier `flutter create` templates wrote
/// to `gradle-wrapper.properties` and that is now below the minimum version
/// that Flutter supports.
///
/// Must run before [TemplateAndroidPluginVersionMigration], which only
/// upgrades AGP when the Gradle version supports it.
///
/// Only changes the versions in [templateGradleVersionsToUpgrade] in a
/// `services.gradle.org` `distributionUrl`, so that versions chosen by a
/// developer, mirrors, and pre-releases are left alone. The opt-out flag of
/// `AndroidStudioJavaGradleConflictMigration` also turns this migration off.
class TemplateGradleWrapperVersionMigration extends ProjectMigrator {
  TemplateGradleWrapperVersionMigration(AndroidProject project, super.logger)
    : _gradleWrapperFile = getGradleWrapperFile(project.hostAppGradleRoot);

  final File _gradleWrapperFile;
  String? _upgradedFromVersion;

  @override
  Future<void> migrate() async {
    if (!_gradleWrapperFile.existsSync()) {
      logger.printTrace('${_gradleWrapperFile.basename} not found, skipping Gradle upgrade.');
      return;
    }
    final String contents;
    try {
      contents = _gradleWrapperFile.readAsStringSync();
    } on FileSystemException catch (e) {
      logger.printTrace('Failed to read ${_gradleWrapperFile.basename}: $e');
      return;
    }
    if (contents.contains(optOutFlag)) {
      logger.printTrace(
        "Skipping Gradle upgrade because '$optOutFlag' is in ${_gradleWrapperFile.basename}.",
      );
      return;
    }
    if (_distributionSha256SumRegExp.hasMatch(contents)) {
      // The checksum belongs to the current distribution, so changing only the
      // URL would make the wrapper fail to verify the download.
      logger.printTrace(
        'Skipping Gradle upgrade because ${_gradleWrapperFile.basename} pins '
        'distributionSha256Sum.',
      );
      return;
    }
    processFileLines(_gradleWrapperFile);
    final String? fromVersion = _upgradedFromVersion;
    if (fromVersion == null) {
      return;
    }
    // processFileLines logs and leaves the file unchanged when it can't write it.
    if (_readGradleVersion(_gradleWrapperFile) != Version.parse(templateGradleUpgradeTarget)) {
      return;
    }
    logger.printStatus(
      'Upgraded Gradle from $fromVersion to $templateGradleUpgradeTarget, the lowest '
      'version that Flutter supports without a warning. To keep the previous version, '
      'undo the change, '
      "add a comment containing '$optOutFlag' to ${_gradleWrapperFile.basename}, and "
      'build with --android-skip-build-dependency-validation.',
    );
  }

  @override
  String migrateLine(String line) {
    final RegExpMatch? match = gradleOrgVersionMatch.firstMatch(line);
    final String? currentVersion = match?.group(1);
    if (currentVersion == null ||
        !templateGradleVersionsToUpgrade.contains(currentVersion) ||
        !_gradleDistributionTypes.contains(match!.group(2))) {
      return line;
    }
    _upgradedFromVersion = currentVersion;
    return line.replaceFirst('gradle-$currentVersion-', 'gradle-$templateGradleUpgradeTarget-');
  }
}

/// Upgrades the Android Gradle Plugin (AGP) and Kotlin Gradle Plugin (KGP)
/// versions that earlier `flutter create` templates wrote to the `plugins {}`
/// block of `settings.gradle(.kts)` and that are now below the minimum
/// versions that Flutter supports.
///
/// Without this migration, projects created with Flutter 3.44 or 3.47 fail to
/// build after the developer upgrades Flutter, even though the developer never
/// chose these versions.
///
/// To avoid surprising developers who manage these versions themselves, this
/// migration:
///
///  * Only changes the versions in [templateAgpVersionsToUpgrade] and
///    [templateKgpVersionsToUpgrade], and stays within the same major version.
///    AGP 8 projects are left alone because moving to AGP 9 needs other
///    changes.
///  * Only changes literal versions in `plugins {}` declarations, which is
///    where the templates put them. Versions from a version catalog or a
///    variable aren't changed.
///  * Upgrades AGP to [templateAgpUpgradeTarget] when the project's Gradle
///    version supports it, otherwise to [minimumAgpUpgradeTarget] when Gradle
///    supports that, and otherwise leaves AGP alone, so that it doesn't create
///    an AGP and Gradle version pair that can't build.
///  * Can be turned off with [pluginVersionOptOutFlag].
class TemplateAndroidPluginVersionMigration extends ProjectMigrator {
  TemplateAndroidPluginVersionMigration(AndroidProject project, super.logger)
    : _settingsFile = project.settingsGradleFile,
      _gradleWrapperFile = getGradleWrapperFile(project.hostAppGradleRoot);

  final File _settingsFile;
  final File _gradleWrapperFile;

  /// The AGP version that the project's Gradle version supports, or null if
  /// AGP can't be upgraded.
  String? _agpTarget;

  final _upgrades = <String>[];

  @override
  Future<void> migrate() async {
    if (!_settingsFile.existsSync()) {
      logger.printTrace(
        '${_settingsFile.basename} not found, skipping Android Gradle Plugin and '
        'Kotlin Gradle Plugin upgrade.',
      );
      return;
    }
    final String contents;
    try {
      contents = _settingsFile.readAsStringSync();
    } on FileSystemException catch (e) {
      logger.printTrace('Failed to read ${_settingsFile.basename}: $e');
      return;
    }
    if (contents.contains(pluginVersionOptOutFlag)) {
      logger.printTrace(
        'Skipping Android Gradle Plugin and Kotlin Gradle Plugin upgrade because '
        "'$pluginVersionOptOutFlag' is in ${_settingsFile.basename}.",
      );
      return;
    }
    final Version? gradleVersion = _readGradleVersion(_gradleWrapperFile);
    // Not gradle_utils.validateGradleAndAgp, which also rejects Gradle versions
    // newer than the newest one Flutter knows about.
    bool supports(String agpVersion) =>
        gradleVersion != null && gradleVersion >= Version.parse(getGradleVersionFor(agpVersion))!;
    _agpTarget = supports(templateAgpUpgradeTarget)
        ? templateAgpUpgradeTarget
        : supports(minimumAgpUpgradeTarget)
        ? minimumAgpUpgradeTarget
        : null;
    if (_agpTarget != templateAgpUpgradeTarget) {
      logger.printTrace(
        'AGP $templateAgpUpgradeTarget requires Gradle '
        '${getGradleVersionFor(templateAgpUpgradeTarget)} or later, and the project uses '
        'Gradle ${gradleVersion ?? 'of an unknown version'}, so the Android Gradle Plugin '
        '${_agpTarget == null ? 'is not upgraded' : 'is upgraded to $_agpTarget at most'}.',
      );
    }
    processFileLines(_settingsFile);
    if (_upgrades.isEmpty) {
      return;
    }
    // processFileLines logs an error when it can't write the file, which can
    // leave the file unchanged or empty. Only report upgrades that were written.
    final String migrated = _settingsFile.readAsStringSync();
    if (migrated.trim().isEmpty || _needsUpgrade(migrated)) {
      return;
    }
    _upgrades.forEach(logger.printStatus);
    logger.printStatus(
      'To keep the previous versions, undo the change, add a comment containing '
      "'$pluginVersionOptOutFlag' to ${_settingsFile.basename}, and build with "
      '--android-skip-build-dependency-validation.',
    );
  }

  /// The version to upgrade the plugin declared by [match] to, or null if it
  /// shouldn't change.
  String? _targetVersionFor(RegExpMatch match) {
    final String currentVersion = match.namedGroup('version')!;
    return switch (match.namedGroup('id')) {
      'org.jetbrains.kotlin.android' when templateKgpVersionsToUpgrade.contains(currentVersion) =>
        templateKgpUpgradeTarget,
      'com.android.application' || 'com.android.library'
          when templateAgpVersionsToUpgrade.contains(currentVersion) =>
        _agpTarget,
      _ => null,
    };
  }

  /// Whether [contents] still has a declaration that this migration upgrades.
  bool _needsUpgrade(String contents) => contents
      .split('\n')
      .any(
        (String line) => _pluginDeclarationRegExp
            .allMatches(line)
            .any((RegExpMatch match) => _targetVersionFor(match) != null),
      );

  @override
  String migrateLine(String line) {
    return line.replaceFirstMapped(_pluginDeclarationRegExp, (Match match) {
      final m = match as RegExpMatch;
      final String? targetVersion = _targetVersionFor(m);
      if (targetVersion == null) {
        return m[0]!;
      }
      final pluginName = m.namedGroup('id') == 'org.jetbrains.kotlin.android'
          ? 'the Kotlin Gradle Plugin'
          : 'the Android Gradle Plugin';
      _upgrades.add(
        targetVersion == minimumAgpUpgradeTarget
            ? 'Upgraded $pluginName from ${m.namedGroup('version')} to $targetVersion, the '
                  'minimum version that Flutter supports. To upgrade to $templateAgpUpgradeTarget '
                  'and remove the warning, upgrade Gradle to '
                  '${getGradleVersionFor(templateAgpUpgradeTarget)} or later.'
            : 'Upgraded $pluginName from ${m.namedGroup('version')} to $targetVersion, the '
                  'lowest version that Flutter supports without a warning.',
      );
      return '${m.namedGroup('prefix')}$targetVersion';
    });
  }
}

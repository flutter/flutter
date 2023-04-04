// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../base/version.dart';
import '../../project.dart';
import '../android_studio.dart';

final Version _androidStudioFlamingo = Version(2022, 2, 0);
final RegExp _gradleVersionMatch = RegExp(
  r'distributionUrl=https\\://services\.gradle\.org/distributions/gradle-((?:\d|\.)+)-(?:all|bin)\.zip');
final Version _lowestSupportedGradleVersion = Version(7, 3, 0);
const String _newVersionFullDependency = r'distributionUrl=https\://services.gradle.org/distributions/gradle-7.4-all.zip';

/// Migrate to a newer version of gradle when the existing does not support
/// the version of Java provided by the detected Android Studio version.
///
/// For more info see the Gradle-Java compatibility matrix:
/// https://docs.gradle.org/current/userguide/compatibility.html
class GradleJavaVersionConflictMigration extends ProjectMigrator {
  GradleJavaVersionConflictMigration(
      AndroidProject project,
      super.logger,
      AndroidStudio? androidStudio,
      ) : _androidStudio = androidStudio,
          _gradleWrapperPropertiesFile = project.hostAppGradleRoot
      .childDirectory('gradle').childDirectory('wrapper').childFile('gradle-wrapper.properties');
  final File _gradleWrapperPropertiesFile;
  final AndroidStudio? _androidStudio;

  @override
  void migrate() {
    if (!_gradleWrapperPropertiesFile.existsSync()) {
      logger.printTrace('gradle-wrapper.properties not found, skipping gradle version compatibility check.');
      return;
    }

    if (_androidStudio == null) {
      logger.printTrace('Android Studio version could not be detected, '
          'skipping gradle version compatibility check.');
      return;
    } else if (_androidStudio!.version.compareTo(_androidStudioFlamingo) < 0) {
      //Version of Android Studio is less than impacted version, no migration necessary.
      return;
    }

    processFileLines(_gradleWrapperPropertiesFile);
  }

  @override
  String migrateLine(String line) {
    final RegExpMatch? match = _gradleVersionMatch.firstMatch(line);
    if (match == null) {
      return line;
    }
    if (match.groupCount < 1) {
      logger.printTrace('Failed to parse gradle version, skipping gradle version compatibility check.');
      return line;
    }
    final String existingVersionString = match[1]!;
    final Version existingVersion = Version.parse(existingVersionString)!;
    if (existingVersion.compareTo(_lowestSupportedGradleVersion) < 0) {
      logger.printTrace('Conflict detected between versions of Android Studio '
          'and gradle, upgrading gradle version from $existingVersion to 7.4');
      return _newVersionFullDependency;
    } else {
      //Version of gradle is already high enough, no migration necessary.
      return line;
    }
  }
}

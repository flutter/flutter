// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';
import '../gradle_utils.dart';

/// Replacement value for https://developer.android.com/reference/tools/gradle-api/8.0/com/android/build/api/dsl/BaseFlavor#minSdkVersion(kotlin.Int)
/// that instead of using a value defaults to the version defined by the
/// flutter sdk as the minimum supported by flutter.
@visibleForTesting
const replacementMinSdkText = 'minSdkVersion flutter.minSdkVersion';

@visibleForTesting
const groovyReplacementWithEquals = 'minSdkVersion = flutter.minSdkVersion';

@visibleForTesting
const kotlinReplacementMinSdkText = 'minSdk = flutter.minSdkVersion';

@visibleForTesting
const appGradleNotFoundWarning =
    'Module level build.gradle file not found, skipping minSdkVersion migration.';

class MinSdkVersionMigration extends ProjectMigrator {
  MinSdkVersionMigration(AndroidProject project, super.logger) : _project = project;

  final AndroidProject _project;

  @override
  Future<void> migrate() async {
    // Skip applying migration in modules as the FlutterExtension is not applied.
    if (_project.isModule) {
      return;
    }
    try {
      processFileLines(_project.appGradleFile);
    } on FileSystemException {
      // Skip if we cannot find the app level build.gradle file.
      logger.printTrace(appGradleNotFoundWarning);
    }
  }

  @override
  String migrateFileContents(String fileContents) {
    if (_project.appGradleFile.path.endsWith('.kts')) {
      // For Kotlin Gradle files, only the equals syntax is valid and we should use 'minSdk'.
      return fileContents.replaceAll(tooOldMinSdkVersionEqualsMatch, kotlinReplacementMinSdkText);
    }

    // For Groovy Gradle files, both space and equals syntax are valid, and the property name is 'minSdkVersion'.
    return fileContents
        .replaceAll(tooOldMinSdkVersionSpaceMatch, replacementMinSdkText)
        .replaceAll(tooOldMinSdkVersionEqualsMatch, groovyReplacementWithEquals);
  }
}

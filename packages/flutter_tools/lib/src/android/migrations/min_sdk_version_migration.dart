// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

@visibleForTesting
const String minSdk16 = 'minSdkVersion 16';
@visibleForTesting
const String minSdk17 = 'minSdkVersion 17';
@visibleForTesting
const String minSdk18 = 'minSdkVersion 18';
@visibleForTesting
const String flutterMinSdk = 'minSdkVersion flutter.minSdkVersion';

class MinSdkVersionMigration extends ProjectMigrator {
  MinSdkVersionMigration(
      AndroidProject project,
      super.logger,
  ) : _project = project;


  final AndroidProject _project;

  @override
  void migrate() {
    final File appLevelGradleBuildFile = _project.hostAppGradleRoot
        .childDirectory('app')
        .childFile('build.gradle');

    // Skip if we cannot find the app level build.gradle file.
    if (!appLevelGradleBuildFile.existsSync()) {
      return;
    }

    // This migrator only applies to app projects, so exit early if we are in
    // a module or a plugin. TODO: Determine if this enough to confirm this is
    // in fact an app. Also determine if we need to do this as all?
    if (_project.isModule || _project.isPlugin) {
      return;
    }

    processFileLines(appLevelGradleBuildFile);
  }

  @override
  String migrateFileContents(String fileContents) {
    return fileContents.replaceAll(minSdk16, flutterMinSdk)
        .replaceAll(minSdk17, flutterMinSdk)
        .replaceAll(minSdk18, flutterMinSdk);
  }
}

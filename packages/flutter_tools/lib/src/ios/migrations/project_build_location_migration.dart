// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../project.dart';
import 'ios_migrator.dart';

// Update the xcodeproj build location. Legacy build location does not work with Swift Packages.
class ProjectBuildLocationMigration extends IOSMigrator {
  ProjectBuildLocationMigration(
    IosProject project,
    Logger logger,
  ) : _xcodeProjectWorkspaceData = project.xcodeProjectWorkspaceData,
      super(logger);

  final File _xcodeProjectWorkspaceData;

  @override
  bool migrate() {
    if (!_xcodeProjectWorkspaceData.existsSync()) {
      logger.printTrace('Xcode project workspace data not found, skipping build location migration.');
      return true;
    }

    final String contents = _xcodeProjectWorkspaceData.readAsStringSync();

    const String legacyBuildLocation = 'location = "group:';
    const String defaultBuildLocation = 'location = "self:';

    final String newContents = contents.replaceAll(legacyBuildLocation, defaultBuildLocation);
    if (contents != newContents) {
      logger.printStatus('Legacy build location detected, removing.');
      _xcodeProjectWorkspaceData.writeAsStringSync(newContents.toString());
    }

    return true;
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

/// Update the minimum macOS deployment version to the minimum allowed by Xcode without causing a warning.
class MacOSDeploymentTargetMigration extends ProjectMigrator {
  MacOSDeploymentTargetMigration(
    MacOSProject project,
    super.logger,
  )   : _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
        _podfile = project.podfile;

  final File _xcodeProjectInfoFile;
  final File _podfile;

  @override
  bool migrate() {
    if (_xcodeProjectInfoFile.existsSync()) {
      processFileLines(_xcodeProjectInfoFile);
    } else {
      logger.printTrace('Xcode project not found, skipping macOS deployment target version migration.');
    }

    if (_podfile.existsSync()) {
      processFileLines(_podfile);
    } else {
      logger.printTrace('Podfile not found, skipping global platform macOS version migration.');
    }

    return true;
  }

  @override
  String? migrateLine(String line) {
    // Xcode project file changes.
    const String deploymentTargetOriginal = 'MACOSX_DEPLOYMENT_TARGET = 10.11;';

    // Podfile changes.
    const String podfilePlatformVersionOriginal = "platform :osx, '10.11'";

    if (line.contains(deploymentTargetOriginal) || line.contains(podfilePlatformVersionOriginal)) {
      if (!migrationRequired) {
        // Only print for the first discovered change found.
        logger.printStatus('Updating minimum macOS deployment target to 10.13.');
      }

      const String deploymentTargetReplacement = 'MACOSX_DEPLOYMENT_TARGET = 10.13;';
      const String podfilePlatformVersionReplacement = "platform :osx, '10.13'";
      return line
          .replaceAll(deploymentTargetOriginal, deploymentTargetReplacement)
          .replaceAll(podfilePlatformVersionOriginal, podfilePlatformVersionReplacement);
    }

    return line;
  }
}

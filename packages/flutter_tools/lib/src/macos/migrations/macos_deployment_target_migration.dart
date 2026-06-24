// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

/// Update the minimum macOS deployment version to the minimum allowed by Xcode without causing a warning.
class MacOSDeploymentTargetMigration extends ProjectMigrator {
  MacOSDeploymentTargetMigration(MacOSProject project, super.logger)
    : _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
      _podfile = project.podfile;

  final File _xcodeProjectInfoFile;
  final File _podfile;

  @override
  Future<void> migrate() async {
    if (_xcodeProjectInfoFile.existsSync()) {
      processFileLines(_xcodeProjectInfoFile);
    } else {
      logger.printTrace(
        'Xcode project not found, skipping macOS deployment target version migration.',
      );
    }

    if (_podfile.existsSync()) {
      processFileLines(_podfile);
    } else {
      logger.printTrace('Podfile not found, skipping global platform macOS version migration.');
    }
  }

  @override
  String? migrateLine(String line) {
    final targetVersionRegex = RegExp(r'MACOSX_DEPLOYMENT_TARGET = (10\.\d+|11\.\d+);');
    final podfilePlatformVersionRegex = RegExp(r"platform :osx, '(10\.\d+|11\.\d+)'");

    final bool hasTargetVersion = targetVersionRegex.hasMatch(line);
    final bool hasPodfileVersion = podfilePlatformVersionRegex.hasMatch(line);

    if (hasTargetVersion || hasPodfileVersion) {
      if (!migrationRequired) {
        logger.printStatus('Updating minimum macOS deployment target to 12.0.');
      }

      if (hasTargetVersion) {
        return line.replaceAllMapped(targetVersionRegex, (Match match) {
          return 'MACOSX_DEPLOYMENT_TARGET = 12.0;';
        });
      }
      if (hasPodfileVersion) {
        return line.replaceAllMapped(podfilePlatformVersionRegex, (Match match) {
          return "platform :osx, '12.0'";
        });
      }
    }

    return line;
  }
}

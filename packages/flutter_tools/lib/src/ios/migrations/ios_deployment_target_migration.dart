// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

/// Update the minimum iOS deployment version to the minimum allowed by Xcode without causing a warning.
class IOSDeploymentTargetMigration extends ProjectMigrator {
  IOSDeploymentTargetMigration(IosProject project, super.logger)
    : _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
      _podfile = project.podfile,
      _appFrameworkInfoPlist = project.appFrameworkInfoPlist;

  final File _xcodeProjectInfoFile;
  final File _podfile;
  final File _appFrameworkInfoPlist;

  @override
  Future<void> migrate() async {
    if (_xcodeProjectInfoFile.existsSync()) {
      processFileLines(_xcodeProjectInfoFile);
    } else {
      logger.printTrace(
        'Xcode project not found, skipping iOS deployment target version migration.',
      );
    }

    if (_appFrameworkInfoPlist.existsSync()) {
      processFileLines(_appFrameworkInfoPlist);
    } else {
      logger.printTrace('AppFrameworkInfo.plist not found, skipping minimum OS version migration.');
    }

    if (_podfile.existsSync()) {
      processFileLines(_podfile);
    } else {
      logger.printTrace('Podfile not found, skipping global platform iOS version migration.');
    }
  }

  @override
  String migrateFileContents(String fileContents) {
    const minimumOSVersionOriginal8 = '''
  <key>MinimumOSVersion</key>
  <string>8.0</string>
''';
    const minimumOSVersionOriginal9 = '''
  <key>MinimumOSVersion</key>
  <string>9.0</string>
''';
    const minimumOSVersionOriginal11 = '''
  <key>MinimumOSVersion</key>
  <string>11.0</string>
''';
    const minimumOSVersionOriginal12 = '''
  <key>MinimumOSVersion</key>
  <string>12.0</string>
''';
    const minimumOSVersionOriginal13 = '''
  <key>MinimumOSVersion</key>
  <string>13.0</string>
''';
    const minimumOSVersionReplacement = '';

    return fileContents
        .replaceAll(minimumOSVersionOriginal8, minimumOSVersionReplacement)
        .replaceAll(minimumOSVersionOriginal9, minimumOSVersionReplacement)
        .replaceAll(minimumOSVersionOriginal11, minimumOSVersionReplacement)
        .replaceAll(minimumOSVersionOriginal12, minimumOSVersionReplacement)
        .replaceAll(minimumOSVersionOriginal13, minimumOSVersionReplacement);
  }

  @override
  String? migrateLine(String line) {
    // Xcode project file changes.
    const deploymentTargetOriginal8 = 'IPHONEOS_DEPLOYMENT_TARGET = 8.0;';
    const deploymentTargetOriginal9 = 'IPHONEOS_DEPLOYMENT_TARGET = 9.0;';
    const deploymentTargetOriginal11 = 'IPHONEOS_DEPLOYMENT_TARGET = 11.0;';
    const deploymentTargetOriginal12 = 'IPHONEOS_DEPLOYMENT_TARGET = 12.0;';

    // Podfile changes.
    const podfilePlatformVersionOriginal9 = "platform :ios, '9.0'";
    const podfilePlatformVersionOriginal11 = "platform :ios, '11.0'";
    const podfilePlatformVersionOriginal12 = "platform :ios, '12.0'";

    if (line.contains(deploymentTargetOriginal8) ||
        line.contains(deploymentTargetOriginal9) ||
        line.contains(deploymentTargetOriginal11) ||
        line.contains(deploymentTargetOriginal12) ||
        line.contains(podfilePlatformVersionOriginal9) ||
        line.contains(podfilePlatformVersionOriginal11) ||
        line.contains(podfilePlatformVersionOriginal12)) {
      if (!migrationRequired) {
        // Only print for the first discovered change found.
        logger.printStatus('Updating minimum iOS deployment target to 13.0.');
      }

      const deploymentTargetReplacement = 'IPHONEOS_DEPLOYMENT_TARGET = 13.0;';
      const podfilePlatformVersionReplacement = "platform :ios, '13.0'";
      return line
          .replaceAll(deploymentTargetOriginal8, deploymentTargetReplacement)
          .replaceAll(deploymentTargetOriginal9, deploymentTargetReplacement)
          .replaceAll(deploymentTargetOriginal11, deploymentTargetReplacement)
          .replaceAll(deploymentTargetOriginal12, deploymentTargetReplacement)
          .replaceAll(podfilePlatformVersionOriginal9, podfilePlatformVersionReplacement)
          .replaceAll(podfilePlatformVersionOriginal11, podfilePlatformVersionReplacement)
          .replaceAll(podfilePlatformVersionOriginal12, podfilePlatformVersionReplacement);
    }

    return line;
  }
}

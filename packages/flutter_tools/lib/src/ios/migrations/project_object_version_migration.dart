// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

/// Migrate the Xcode project for Xcode 13 compatibility to avoid an "Update to recommended settings" Xcode warning.
class ProjectObjectVersionMigration extends ProjectMigrator {
  ProjectObjectVersionMigration(
    IosProject project,
    Logger logger,
  )   : _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
        _xcodeProjectSchemeFile = project.xcodeProjectSchemeFile,
        super(logger);

  final File _xcodeProjectInfoFile;
  final File _xcodeProjectSchemeFile;

  @override
  bool migrate() {
    if (_xcodeProjectInfoFile.existsSync()) {
      processFileLines(_xcodeProjectInfoFile);
    } else {
      logger.printTrace('Xcode project not found, skipping Xcode compatibility migration.');
    }
    if (_xcodeProjectSchemeFile.existsSync()) {
      processFileLines(_xcodeProjectSchemeFile);
    } else {
      logger.printTrace('Runner scheme not found, skipping Xcode compatibility migration.');
    }

    return true;
  }

  @override
  String? migrateLine(String line) {
    String updatedString = line;
    final Map<Pattern, String> originalToReplacement = <Pattern, String>{
      // objectVersion has only been 46 and 50 in the iOS template.
      'objectVersion = 46;': 'objectVersion = 50;',
      // LastUpgradeCheck is in the Xcode project file, not scheme file.
      // Value has been 0730, 0800, 1020, and 1300 in the template.
      RegExp(r'LastUpgradeCheck = \d+;'): 'LastUpgradeCheck = 1300;',
      // LastUpgradeVersion is in the scheme file, not Xcode project file.
      RegExp(r'LastUpgradeVersion = "\d+"'): 'LastUpgradeVersion = "1300"',
    };

    originalToReplacement.forEach((Pattern original, String replacement) {
      if (line.contains(original)) {
        updatedString = line.replaceAll(original, replacement);
        if (!migrationRequired && updatedString != line) {
          // Only print once.
          logger.printStatus('Updating project for Xcode compatibility.');
        }
      }
    });

    return updatedString;
  }
}

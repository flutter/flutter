// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../globals.dart' as globals;
import '../../ios/plist_parser.dart';
import '../../xcode_project.dart';

/// Update the minimum macOS deployment version to the minimum allowed by Xcode without causing a warning.
class FlutterApplicationMigration extends ProjectMigrator {
  FlutterApplicationMigration(
    MacOSProject project,
    super.logger,
  ) : _infoPlistFile = project.defaultHostInfoPlist;

  final File _infoPlistFile;

  @override
  void migrate() {
    if (_infoPlistFile.existsSync()) {
      final String? principleClass =
          globals.plistParser.getStringValueFromFile(_infoPlistFile.path, PlistParser.kNSPrincipalClassKey);
      if (principleClass == null || principleClass == 'NSApplication') {
        // No NSPrincipalClass defined, or already converted. No migration
        // needed.
        return;
      }
      if (principleClass != 'FlutterApplication') {
        // If the principle class wasn't already migrated to
        // FlutterApplication, there's no need to revert the migration.
        return;
      }
      logger.printStatus('Updating ${_infoPlistFile.basename} to use NSApplication instead of FlutterApplication.');
      final bool success = globals.plistParser.replaceKey(_infoPlistFile.path, key: PlistParser.kNSPrincipalClassKey, value: 'NSApplication');
      if (!success) {
        logger.printError('Updating ${_infoPlistFile.basename} failed.');
      }
    }
  }
}

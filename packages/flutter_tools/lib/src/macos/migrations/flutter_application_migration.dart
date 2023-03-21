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
      if (principleClass == null || principleClass == 'FlutterApplication') {
        // No NSPrincipalClass defined, or already converted, so no migration
        // needed.
        return;
      }
      if (principleClass != 'NSApplication') {
        // Only replace NSApplication values, since we don't know why they might
        // have substituted something else.
        logger.printTrace('${_infoPlistFile.basename} has an '
          '${PlistParser.kNSPrincipalClassKey} of $principleClass, not '
          'NSApplication, skipping FlutterApplication migration.\nYou will need '
          'to modify your application class to derive from FlutterApplication.');
        return;
      }
      logger.printStatus('Updating ${_infoPlistFile.basename} to use FlutterApplication instead of NSApplication.');
      final bool success = globals.plistParser.replaceKey(_infoPlistFile.path, key: PlistParser.kNSPrincipalClassKey, value: 'FlutterApplication');
      if (!success) {
        logger.printError('Updating ${_infoPlistFile.basename} failed.');
      }
    } else {
      logger.printTrace('${_infoPlistFile.basename} not found, skipping FlutterApplication migration.');
    }
  }
}

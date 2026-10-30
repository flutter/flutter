// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../ios/plist_parser.dart';
import '../../xcode_project.dart';

/// Migrate principle class from FlutterApplication to NSApplication.
///
/// For several weeks, we required macOS apps to use FlutterApplication as the
/// app's NSPrincipalClass rather than NSApplication. During that time an
/// automated migration migrated the NSPrincipalClass in the Info.plist from
/// NSApplication to FlutterApplication. Now that this is no longer necessary,
/// we apply the reverse migration for anyone who was previously migrated.
class FlutterApplicationMigration extends ProjectMigrator {
  FlutterApplicationMigration(MacOSProject project, super.logger, {required this._plistParser})
    : _infoPlistFile = project.defaultHostInfoPlist;

  final File _infoPlistFile;
  final PlistParser _plistParser;

  @override
  Future<void> migrate() async {
    if (_infoPlistFile.existsSync()) {
      final String? principalClass = _plistParser.getValueFromFile<String>(
        _infoPlistFile.path,
        PlistParser.kNSPrincipalClassKey,
      );
      if (principalClass == null || principalClass == 'NSApplication') {
        // No NSPrincipalClass defined, or already converted. No migration
        // needed.
        return;
      }
      if (principalClass != 'FlutterApplication') {
        // If the principal class wasn't already migrated to
        // FlutterApplication, there's no need to revert the migration.
        return;
      }
      logger.printStatus(
        'Updating ${_infoPlistFile.basename} to use NSApplication instead of FlutterApplication.',
      );
      final bool success = _plistParser.replaceKey(
        _infoPlistFile.path,
        key: PlistParser.kNSPrincipalClassKey,
        value: 'NSApplication',
      );
      if (!success) {
        logger.printError('Updating ${_infoPlistFile.basename} failed.');
      }
    }
  }
}

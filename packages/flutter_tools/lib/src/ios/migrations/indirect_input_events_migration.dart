// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

const String _kIndirectInputEventsKey = 'UIApplicationSupportsIndirectInputEvents';

/// Add "UIApplicationSupportsIndirectInputEvents: true" to the Info.plist.
class IndirectInputEventsMigration extends ProjectMigrator {
  IndirectInputEventsMigration(
    IosProject project,
    super.logger,
  ) : _infoPlist = project.defaultHostInfoPlist;

  final File _infoPlist;

  @override
  bool migrate() {
    if (!_infoPlist.existsSync()) {
      logger.printTrace('Info.plist not found, skipping indirect input events migration.');
      return true;
    }

    processFileLines(_infoPlist);
    return true;
  }

  @override
  String migrateFileContents(String fileContents) {
    if (fileContents.contains(_kIndirectInputEventsKey)) {
      // No migration needed if the key already exits.
      return fileContents;
    }
    logger.printTrace('Adding $_kIndirectInputEventsKey to Info.plist');
    const String plistEnd = '''
</dict>
</plist>
''';
    const String plistWithKey = '''
	<key>$_kIndirectInputEventsKey</key>
	<true/>
</dict>
</plist>
''';

    return fileContents.replaceAll(plistEnd, plistWithKey);
  }
}

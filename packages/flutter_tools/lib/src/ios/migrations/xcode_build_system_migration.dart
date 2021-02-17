// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../base/project_migrator.dart';
import '../../project.dart';

// Xcode legacy build system no longer supported by Xcode.
// Set in https://github.com/flutter/flutter/pull/21901/.
// Removed in https://github.com/flutter/flutter/pull/33684.
class XcodeBuildSystemMigration extends ProjectMigrator {
  XcodeBuildSystemMigration(
    IosProject project,
    Logger logger,
  ) : _xcodeWorkspaceSharedSettings = project.xcodeWorkspaceSharedSettings,
      super(logger);

  final File _xcodeWorkspaceSharedSettings;

  @override
  bool migrate() {
    if (!_xcodeWorkspaceSharedSettings.existsSync()) {
      logger.printTrace('Xcode workspace settings not found, skipping build system migration');
      return true;
    }

    final String contents = _xcodeWorkspaceSharedSettings.readAsStringSync();

    // Only delete this file when it is pointing to the legacy build system.
    const String legacyBuildSettingsWorkspace = '''
	<key>BuildSystemType</key>
	<string>Original</string>''';

    // contains instead of equals to ignore newline file ending variance.
    if (contents.contains(legacyBuildSettingsWorkspace)) {
      logger.printStatus('Legacy build system detected, removing ${_xcodeWorkspaceSharedSettings.path}');
      _xcodeWorkspaceSharedSettings.deleteSync();
    }

    return true;
  }
}

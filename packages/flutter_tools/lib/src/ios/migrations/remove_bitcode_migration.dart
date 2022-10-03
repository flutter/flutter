// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../base/version.dart';
import '../../macos/xcode.dart';
import '../../xcode_project.dart';

/// Remove deprecated bitcode build setting.
class RemoveBitcodeMigration extends ProjectMigrator {
  RemoveBitcodeMigration(
    IosProject project,
    Xcode xcode,
    super.logger,
  )   : _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
        _xcodeVersion = xcode.currentVersion;

  final File _xcodeProjectInfoFile;
  final Version? _xcodeVersion;

  @override
  bool migrate() {
    final Version? xcodeVersion = _xcodeVersion;
    if (xcodeVersion == null || xcodeVersion.major < 14) {
      logger.printTrace('Xcode version < 14, skipping removing bitcode migration.');
    } else if (!_xcodeProjectInfoFile.existsSync()) {
      logger.printTrace('Xcode project not found, skipping removing bitcode migration.');
    } else {
      processFileLines(_xcodeProjectInfoFile);
    }

    return true;
  }

  @override
  String? migrateLine(String line) {
    if (line.contains('ENABLE_BITCODE = YES;')) {
      if (!migrationRequired) {
        // Only print for the first discovered change found.
        logger.printWarning('Disabling deprecated bitcode Xcode build setting. See https://github.com/flutter/flutter/issues/107887 for additional details.');
      }
      return null;
    }

    return line;
  }
}

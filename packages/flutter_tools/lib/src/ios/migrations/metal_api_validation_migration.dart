// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

/// Remove Metal API validation setting that slows down applications.
class MetalAPIValidationMigrator extends ProjectMigrator {
  MetalAPIValidationMigrator(
    IosProject project,
    super.logger,
  )   : _xcodeProjectScheme = project.xcodeProjectSchemeFile();

  final File _xcodeProjectScheme;


  @override
  Future<void> migrate() async {
    if (_xcodeProjectScheme.existsSync()) {
      processFileLines(_xcodeProjectScheme);
    } else {
      logger.printTrace('default xcscheme file not found. Skipping Metal API validation migration.');
    }
  }

  @override
  String migrateFileContents(String fileContents) {
    // Look for a setting that is included in LaunchAction by default and
    // insert the opt out after it.
    const String kDebugServiceExtension = 'debugServiceExtension = "internal"';
    const String kReplacement = '''debugServiceExtension = "internal"\n    enableGPUValidationMode = "1"''';

    return fileContents.replaceFirst(kDebugServiceExtension, kReplacement);
  }

  @override
  String? migrateLine(String line) {
    return line;
  }
}

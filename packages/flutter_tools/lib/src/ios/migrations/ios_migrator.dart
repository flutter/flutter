// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../base/file_system.dart';
import '../../base/logger.dart';

/// iOS project is generated from a template on Flutter project creation.
/// Sometimes (due to behavior changes in Xcode, CocoaPods, etc) these files need to be altered
/// from the original template.
class IOSMigrator {
  IOSMigrator(this.logger);

  @protected
  final Logger logger;

  /// Returns whether migration was successful or was skipped.
  bool migrate() {
    return false;
  }

  /// [processLine] should return null if the line should be deleted.
  @protected
  void processFileLines(File file, String Function(String) processLine) {
    final List<String> lines = file.readAsLinesSync();

    final StringBuffer newProjectContents = StringBuffer();
    final String basename = file.basename;

    bool migrationRequired = false;
    for (final String line in lines) {
      final String newProjectLine = processLine(line);
      if (newProjectLine == null) {
        logger.printTrace('Migrating $basename, removing:');
        logger.printTrace('    $line');
        migrationRequired = true;
        continue;
      }
      if (newProjectLine != line) {
        logger.printTrace('Migrating $basename, replacing:');
        logger.printTrace('    $line');
        logger.printTrace('with:');
        logger.printTrace('    $newProjectLine');
        migrationRequired = true;
      }
      newProjectContents.writeln(newProjectLine);
    }

    if (migrationRequired) {
      logger.printStatus('Upgrading $basename');
      file.writeAsStringSync(newProjectContents.toString());
    }
  }
}

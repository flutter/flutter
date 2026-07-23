// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/project_migrator.dart';
import '../project.dart';

/// Adds `.widget_preview/` to the .gitignore file.
class WidgetPreviewGitignoreMigration extends ProjectMigrator {
  WidgetPreviewGitignoreMigration(FlutterProject project, super.logger)
    : _gitignoreFile = project.gitignoreFile;

  final File _gitignoreFile;

  @override
  Future<void> migrate() async {
    if (!_gitignoreFile.existsSync()) {
      logger.printTrace('.gitignore file not found, skipping widget preview .gitignore migration.');
      return;
    }

    final String originalContent = _gitignoreFile.readAsStringSync();

    // Skip if .gitignore is already migrated.
    if (originalContent.contains('.widget_preview/')) {
      return;
    }

    logger.printTrace('.gitignore does not ignore .widget_preview/ directory, updating.');

    final newContent = StringBuffer(originalContent);
    if (!originalContent.endsWith('\n')) {
      newContent.writeln();
    }
    newContent
      ..writeln('# Widget Preview related')
      ..writeln('.widget_preview/');

    _gitignoreFile.writeAsStringSync(newContent.toString());
  }
}

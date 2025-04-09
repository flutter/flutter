// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

abstract class WidgetPreviewScaffoldTestUtils {
  static final Set<String> _ignoreDiffSet = <String>{
    // The pubspec can't be compared directly to the template since the SDK version is populated
    // when the template is hydrated based on the current SDK version.
    'pubspec.yaml',
    'lib/src/generated_preview.dart',
  };

  /// Checks to see if the widget_preview_scaffold template files have been updated.
  ///
  /// Returns true if the widget_preview_scaffold project should be regenerated.
  static bool checkForTemplateUpdates({
    required Directory widgetPreviewScaffoldProject,
    required Directory widgetPreviewScaffoldTemplateDir,
  }) {
    bool updateDetected = false;
    for (final FileSystemEntity entity in Directory(
      widgetPreviewScaffoldTemplateDir.absolute.path,
    ).listSync(recursive: true)) {
      final String scaffoldPath =
          entity.path
              .replaceAll('.tmpl', '')
              .split('widget_preview_scaffold/')
              .last;
      if (_ignoreDiffSet.contains(scaffoldPath)) {
        continue;
      }
      final String resolvedScaffoldPath =
          '${widgetPreviewScaffoldProject.absolute.path}$scaffoldPath';
      if (entity is Directory) {
        if (!Directory(resolvedScaffoldPath).existsSync()) {
          stdout.writeln(
            'ERROR: Failed to find directory at $resolvedScaffoldPath.',
          );
          updateDetected = true;
        }
      } else if (entity is File) {
        final File scaffoldFile = File(resolvedScaffoldPath);
        if (!scaffoldFile.existsSync()) {
          stdout.writeln(
            'ERROR: Failed to find file at $resolvedScaffoldPath.',
          );
          updateDetected = true;
          continue;
        }
        final String templateContent = entity.readAsStringSync();
        final String scaffoldContent = scaffoldFile.readAsStringSync();
        if (templateContent != scaffoldContent) {
          stdout.writeln(
            'ERROR: The contents of $resolvedScaffoldPath do not match the contents of the template at '
            '${entity.path}.',
          );
          updateDetected = true;
        }
      } else {
        throw StateError(
          'Unexpected FileSystemEntity type: ${entity.runtimeType}',
        );
      }
    }
    return updateDetected;
  }
}

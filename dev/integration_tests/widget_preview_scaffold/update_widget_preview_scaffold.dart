// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'test/widget_preview_scaffold_change_detector.dart';

/// Regenerates the widget_preview_scaffold if needed.
void main() {
  if (WidgetPreviewScaffoldChangeDetector.checkForTemplateUpdates(
    widgetPreviewScaffoldProject: Directory(Platform.script.resolve('.').path),
    widgetPreviewScaffoldTemplateDir: Directory(
      Platform.script
          .resolve(
            path.join(
              '..',
              '..',
              '..',
              'packages',
              'flutter_tools',
              'templates',
              'widget_preview_scaffold',
            ),
          )
          .path,
    ),
  )) {
    stdout.writeln(
      'Changes detected in the widget_preview_scaffold project templates.',
    );
    stdout.writeln('Regenerating...');
    final args = <String>[
      'widget-preview',
      'start',
      '--scaffold-output-dir=${Platform.script.resolve('.').path}',
    ];
    stdout.writeln('Executing: flutter ${args.join(' ')}');
    final ProcessResult result = Process.runSync('flutter', args);
    stdout.writeln(result.stdout);
    stderr.writeln(result.stderr);
    stdout.writeln('Regenerated widget_preview_scaffold.');
  } else {
    stdout.writeln(
      'No changes detected in the widget_preview_scaffold project templates.',
    );
  }
}

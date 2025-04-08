// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path; // flutter_ignore: package_path_import

import 'widget_preview_scaffold/test/widget_preview_scaffold_test_utils.dart';

/// Regenerates the widget_preview_scaffold if needed.
void main() {
  if (WidgetPreviewScaffoldTestUtils.checkForTemplateUpdates(
    widgetPreviewScaffoldProject: Directory(
      Platform.script.resolve('widget_preview_scaffold/').path,
    ),
    widgetPreviewScaffoldTemplateDir: Directory(
      Platform.script.resolve(path.join('..', '..', 'templates', 'widget_preview_scaffold')).path,
    ),
  )) {
    stdout.writeln('Changes detected in the widget_preview_scaffold project templates.');
    stdout.writeln('Regenerating...');
    final List<String> args = <String>[
      'widget-preview',
      'start',
      '--scaffold-output-dir=${Platform.script.resolve('widget_preview_scaffold').path}',
    ];
    stdout.writeln('Executing: flutter ${args.join(' ')}');
    final ProcessResult result = Process.runSync('flutter', args);
    stdout.writeln(result.stdout);
    stderr.writeln(result.stderr);
    stdout.writeln('Regenerated widget_preview_scaffold.');
  } else {
    stdout.writeln('No changes detected in the widget_preview_scaffold project templates.');
  }
}

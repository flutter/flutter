// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// A helper script to reduce friction when iterating on the widget_preview_scaffold templates.
///
/// This script operates on the CWD and:
///  - Deletes .dart_tool/widget_preview_scaffold/
///  - Deletes the contents of $FLUTTER_ROOT/packages/flutter_tools/templates/widget_preview_scaffold/lib/
///  - Copies the contents of $FLUTTER_ROOT/packages/flutter_tools/test/widget_preview_scaffold.shard/widget_preview_scaffold/lib/
///    to $FLUTTER_ROOT/packages/flutter_tools/templates/widget_preview_scaffold/lib/ with the
///    correct template extension
///  - Runs `flutter widget-preview start`, with --dtd-uri=${args.first} if a DTD URI is provided
///    as an argument
///
/// NOTE: this script does not update the template_manifest.json, which must be done manually.
Future<void> main(List<String> args) async {
  final String flutterDev = Platform.script
      .resolve('../../../bin/flutter-dev${Platform.isWindows ? '.bat' : ''}')
      .toFilePath();
  final ProcessResult result = Process.runSync(flutterDev, <String>['widget-preview', 'clean']);
  if (result.exitCode != 0) {
    throw StateError('Failed to clean the widget_preview_scaffold.');
  }

  final widgetPreviewScaffoldLibDir = Directory(
    Platform.script
        .resolve('../test/widget_preview_scaffold.shard/widget_preview_scaffold/lib')
        .toFilePath(),
  );

  final widgetPreviewScaffoldTemplateLibDir = Directory(
    Platform.script.resolve('../templates/widget_preview_scaffold/lib').toFilePath(),
  );

  // Blow away the old templates as files may have moved.
  widgetPreviewScaffoldTemplateLibDir.deleteSync(recursive: true);

  final List<FileSystemEntity> files = widgetPreviewScaffoldLibDir.listSync(recursive: true);
  for (final file in files) {
    if (file is File) {
      final String copyDestination = path.join(
        widgetPreviewScaffoldTemplateLibDir.path,
        '${file.path.substring(widgetPreviewScaffoldLibDir.path.length + 1)}.tmpl',
      );
      Directory(path.dirname(copyDestination)).createSync(recursive: true);
      print('Copying $file to $copyDestination');
      file.copySync(copyDestination);
    }
  }

  final Process process = await Process.start(flutterDev, <String>[
    'widget-preview',
    'start',
    if (args.isNotEmpty) '--dtd-url=${args.first}',
  ]);
  process.stdout.transform(utf8.decoder).listen(stdout.writeln);
  process.stderr.transform(utf8.decoder).listen(stderr.writeln);
  await process.exitCode;
}

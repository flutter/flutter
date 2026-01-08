// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'widget_preview_scaffold_change_detector.dart';

void main() {
  test('Widget Preview Scaffold template change detection', () {
    expect(
      path.basename(Directory.current.path),
      'widget_preview_scaffold',
      reason:
          'This test must be run from dev/integration_tests/widget_preview_scaffold/',
    );
    if (WidgetPreviewScaffoldChangeDetector.checkForTemplateUpdates(
      widgetPreviewScaffoldProject: Directory.current,
      widgetPreviewScaffoldTemplateDir: Directory(
        path.join(
          '..',
          '..',
          '..',
          'packages',
          'flutter_tools',
          'templates',
          'widget_preview_scaffold',
        ),
      ),
    )) {
      stdout.writeln(
        'The widget_preview_scaffold contents do not match the widget_preview_scaffold '
        'templates. Run "dart dev/integration_tests/widget_preview_scaffold/'
        'update_widget_preview_scaffold.dart" to update widget_preview_scaffold with the latest '
        'template contents.',
      );
      fail('widget_preview_scaffold is not up to date.');
    }
  });
}

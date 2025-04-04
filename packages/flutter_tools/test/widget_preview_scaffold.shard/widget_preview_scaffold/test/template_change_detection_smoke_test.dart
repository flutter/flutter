// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'widget_preview_scaffold_test_utils.dart';

void main() {
  test('Widget Preview Scaffold template change detection', () {
    if (WidgetPreviewScaffoldTestUtils.checkForTemplateUpdates(
      widgetPreviewScaffoldProject: Directory(
        Platform.script.resolve('.').path,
      ),
      widgetPreviewScaffoldTemplateDir: Directory(
        '../../../templates/widget_preview_scaffold',
      ),
    )) {
      stdout.writeln(
        'The widget_preview_scaffold contents do not match the widget_preview_scaffold '
        'templates. Run "dart test/widget_preview_scaffold.shard/update_widget_preview_scaffold" '
        'to update widget_preview_scaffold with the latest template contents.',
      );
      fail(
        'widget_preview_scaffold.shard/widget_preview_scaffold is not up to date.',
      );
    }
  });
}

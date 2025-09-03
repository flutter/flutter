// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';
import 'package:widget_preview_scaffold/src/widget_preview_scaffold_controller.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets(
    'Help message is displayed with link to documentation when no previews are detected',
    (tester) async {
      final currentPreviews = <WidgetPreview>[];

      final controller = WidgetPreviewScaffoldController(
        dtdServicesOverride: FakeWidgetPreviewScaffoldDtdServices(),
        previews: () => currentPreviews,
      );
      // Start with no previews populated and verify the help message is displayed with a link to
      // documentation.
      await tester.pumpWidget(WidgetPreviewScaffold(controller: controller));

      final Finder noPreviewDetectedFinder = find.byType(
        NoPreviewsDetectedWidget,
      );
      final Finder widgetPreviewWidgetFinder = find.byType(WidgetPreviewWidget);
      final Finder documentationUrlFinder = find.text(
        NoPreviewsDetectedWidget.documentationUrl.toString(),
      );

      expect(noPreviewDetectedFinder, findsOne);
      expect(documentationUrlFinder, findsOne);
      expect(widgetPreviewWidgetFinder, findsNothing);

      currentPreviews.add(
        WidgetPreview(scriptUri: '', builder: () => const Text('Foo')),
      );

      // Fake a hot reload.
      controller.onHotReload();

      // Add previews and verify the help message is gone.
      await tester.pumpWidget(WidgetPreviewScaffold(controller: controller));

      expect(noPreviewDetectedFinder, findsNothing);
      expect(documentationUrlFinder, findsNothing);
      expect(widgetPreviewWidgetFinder, findsOne);
    },
  );
}

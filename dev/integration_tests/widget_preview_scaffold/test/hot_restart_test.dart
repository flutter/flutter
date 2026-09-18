// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets(
    'Restart Widget Previewer button invokes the DTD hot restart endpoint',
    (tester) async {
      final dtdServices = FakeWidgetPreviewScaffoldDtdServices();
      final widgetPreview = TestWidgetPreviewScaffold(
        controller: FakeWidgetPreviewScaffoldController(
          dtdServicesOverride: dtdServices,
        ),
      );

      await tester.pumpWidget(widgetPreview);
      final Finder restartButton = find.byType(WidgetPreviewerRestartButton);

      // Press the "Restart Widget Previewer" button and verify the request would have been sent
      // to DTD.
      expect(dtdServices.hotRestartInvoked, false);
      await tester.tap(restartButton);
      expect(dtdServices.hotRestartInvoked, true);
    },
  );

  testWidgets(
    'displays SnackBar when hot reload is rejected and hot restart is performed',
    (tester) async {
      final dtdServices = FakeWidgetPreviewScaffoldDtdServices()
        ..hotRestartTriggerEvent = true;
      final controller = FakeWidgetPreviewScaffoldController(
        dtdServicesOverride: dtdServices,
      );
      await controller.initialize();
      final widgetPreview = TestWidgetPreviewScaffold(controller: controller);

      await tester.pumpWidget(widgetPreview);
      await tester.pump();

      expect(
        find.text(
          'Hot reload rejected due to unsupported changes. Performed a hot restart instead.',
        ),
        findsOneWidget,
      );
      expect(controller.hotReloadRejectedRestartedListenable.value, isFalse);
      expect(dtdServices.hotRestartTriggerEvent, isFalse);
    },
  );
}

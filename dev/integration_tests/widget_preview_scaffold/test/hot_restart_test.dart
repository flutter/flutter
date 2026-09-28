// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';
import 'package:widget_preview_scaffold/src/widget_preview_scaffold_controller.dart';

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
        ..hotReloadRejectedTriggerEvent = true;
      final controller = FakeWidgetPreviewScaffoldController(
        dtdServicesOverride: dtdServices,
      );
      await controller.initialize();
      final widgetPreview = TestWidgetPreviewScaffold(controller: controller);

      await tester.pumpWidget(widgetPreview);
      await tester.pump();

      expect(
        find.text(WidgetPreviewScaffold.kHotReloadRejectedMessage),
        findsOneWidget,
      );
      expect(controller.hotReloadRejectedTriggerEvent, isFalse);
      expect(dtdServices.hotReloadRejectedTriggerEvent, isFalse);
    },
  );

  testWidgets('does not display SnackBar when hot reload was not rejected', (
    tester,
  ) async {
    final dtdServices = FakeWidgetPreviewScaffoldDtdServices();
    final controller = FakeWidgetPreviewScaffoldController(
      dtdServicesOverride: dtdServices,
    );
    await controller.initialize();
    final widgetPreview = TestWidgetPreviewScaffold(controller: controller);

    await tester.pumpWidget(widgetPreview);
    await tester.pump();

    expect(
      find.text(WidgetPreviewScaffold.kHotReloadRejectedMessage),
      findsNothing,
    );
    expect(controller.hotReloadRejectedTriggerEvent, isFalse);
  });

  testWidgets(
    'previewer scroll notifications do not affect AppBar previews without a Scaffold',
    (tester) async {
      final dtdServices = FakeWidgetPreviewScaffoldDtdServices();
      await dtdServices.setPreference(
        WidgetPreviewScaffoldController.kFilterBySelectedFilePreference,
        false,
      );
      final controller = FakeWidgetPreviewScaffoldController(
        dtdServicesOverride: dtdServices,
        previews: <WidgetPreview>[
          WidgetPreview.test(
            builder: () => AppBar(
              title: const Text('Preview AppBar'),
              backgroundColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.scrolledUnder)
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            previewData: const Preview(size: Size(300, 100)),
          ),
          for (var i = 0; i < 10; i++)
            WidgetPreview.test(
              builder: () => Text('Item $i'),
              previewData: const Preview(size: Size(300, 200)),
            ),
        ],
      );
      await controller.initialize();
      controller.layoutType = LayoutType.listView;
      final widgetPreview = TestWidgetPreviewScaffold(controller: controller);

      await tester.pumpWidget(widgetPreview);
      await tester.pumpAndSettle();

      Color? appBarColor() {
        final Material material = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(AppBar),
                matching: find.byType(Material),
              )
              .first,
        );
        return material.color;
      }

      final double dyBefore = tester.getTopLeft(find.byType(AppBar)).dy;
      expect(appBarColor(), equals(Colors.green));
      await tester.drag(find.byType(ListView).first, const Offset(0, -50));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(AppBar)).dy, lessThan(dyBefore));
      expect(appBarColor(), equals(Colors.green));
    },
  );
}

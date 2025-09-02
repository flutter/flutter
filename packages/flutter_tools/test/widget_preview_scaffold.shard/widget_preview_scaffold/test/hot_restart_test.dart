// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets(
    'Restart Widget Previewer button invokes the DTD hot restart endpoint',
    (tester) async {
      final FakeWidgetPreviewScaffoldDtdServices dtdServices =
          FakeWidgetPreviewScaffoldDtdServices();
      final WidgetPreviewScaffold widgetPreview = WidgetPreviewScaffold(
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
}

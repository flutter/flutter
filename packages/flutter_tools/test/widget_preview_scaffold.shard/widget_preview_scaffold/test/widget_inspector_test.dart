// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets(
    'WidgetInspector is manually injected into each WidgetPreviewWidget',
    (tester) async {
      final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
      const int kNumPreviewedWidgets = 3;
      const String kTestText = 'Foo';
      final WidgetPreviewerWidgetScaffolding widgetPreview =
          WidgetPreviewerWidgetScaffolding(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < kNumPreviewedWidgets; ++i)
                  WidgetPreviewWidget(
                    preview: WidgetPreview(builder: () => Text('$kTestText$i')),
                  ),
              ],
            ),
          );

      await tester.pumpWidget(widgetPreview);

      // By default, the widget preview scaffold sets
      // WidgetsBinding.debugExcludeRootWidgetInspector = true (we copy
      // this behavior in the WidgetPreviewerWidgetScaffolding utility class),
      // which prevents WidgetInspector from being injected into the widget
      // tree by WidgetApp.
      //
      // While debugShowWidgetInspectorOverride is false, we expect for there
      // to be no instances of WidgetInspector in the tree.
      final Finder widgetInspectorFinder = find.byType(WidgetInspector);
      expect(binding.debugShowWidgetInspectorOverride, false);
      expect(widgetInspectorFinder, findsNothing);

      // When debugShowWidgetInspectorOverride is set to true, instances of
      // WidgetInspector are inserted into each preview instance, allowing for
      // the widget inspector to only highlight widgets selected within widget
      // previews and not the actual scaffolding.
      binding.debugShowWidgetInspectorOverride = true;
      await tester.pump();
      expect(widgetInspectorFinder, findsExactly(kNumPreviewedWidgets));
    },
  );

  testWidgets('WidgetInspector is not injected with no previews defined', (
    tester,
  ) async {
    final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
    final WidgetPreviewerWidgetScaffolding widgetPreview =
        WidgetPreviewerWidgetScaffolding(child: SizedBox());

    await tester.pumpWidget(widgetPreview);

    // By default, the widget preview scaffold sets
    // WidgetsBinding.debugExcludeRootWidgetInspector = true (we copy
    // this behavior in the WidgetPreviewerWidgetScaffolding utility class),
    // which prevents WidgetInspector from being injected into the widget
    // tree by WidgetApp.
    //
    // While debugShowWidgetInspectorOverride is false, we expect for there
    // to be no instances of WidgetInspector in the tree.
    final Finder widgetInspectorFinder = find.byType(WidgetInspector);
    expect(binding.debugShowWidgetInspectorOverride, false);
    expect(widgetInspectorFinder, findsNothing);

    // When debugShowWidgetInspectorOverride is set to true, we still shouldn't
    // find an instance of WidgetInspector since there's no previews being
    // rendered.
    binding.debugShowWidgetInspectorOverride = true;
    await tester.pump();
    expect(widgetInspectorFinder, findsNothing);
  });
}

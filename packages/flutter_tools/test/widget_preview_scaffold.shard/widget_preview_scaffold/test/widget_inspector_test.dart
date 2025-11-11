// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/split.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_inspector_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  testWidgets(
    'WidgetInspector is manually injected into each WidgetPreviewWidget',
    (tester) async {
      final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
      const int kNumPreviewedWidgets = 3;
      const String kTestText = 'Foo';
      final controller = FakeWidgetPreviewScaffoldController();
      final widgetPreview = WidgetPreviewerWidgetScaffolding(
        child: Column(
          children: <Widget>[
            for (int i = 0; i < kNumPreviewedWidgets; ++i)
              WidgetPreviewWidget(
                controller: controller,
                preview: WidgetPreview.test(
                  builder: () => Text('$kTestText$i'),
                  previewData: Preview(),
                ),
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

  testWidgets('WidgetInspector navigates to Preview application location', (
    tester,
  ) async {
    final dtd = FakeWidgetPreviewScaffoldDtdServices();
    // Install the WidgetInspectorService override (this is done in the
    // constructor body).
    WidgetPreviewScaffoldInspectorService(dtdServices: dtd);
    final controller = FakeWidgetPreviewScaffoldController(
      dtdServicesOverride: dtd,
    );
    await controller.initialize();

    final service = WidgetInspectorService.instance;
    service.isSelectMode = true;

    const kLine = 123;
    const kColumn = 456;
    const kScriptUri = 'file:///script/containing/preview.dart';

    final widgetPreview = WidgetPreviewerWidgetScaffolding(
      child: Column(
        children: <Widget>[
          WidgetPreviewWidget(
            controller: controller,
            preview: WidgetPreview.test(
              builder: () => Text(''),
              previewData: Preview(),
              line: kLine,
              column: kColumn,
              scriptUri: kScriptUri,
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(widgetPreview);
    final element = find.byType(PreviewWidget).evaluate().first;

    // Select the WidgetPreviewWidget, which acts as the root entry of the
    // preview within the inspector.
    expect(service.selection.current, isNull);
    // ignore: invalid_use_of_protected_member
    service.setSelection(element);

    // Ensure that a navigation event has been sent to the IDE via DTD as a
    // result of the inspector selection.
    expect(dtd.navigationEvents, hasLength(1));

    // The navigation event should be to the location of the preview provided
    // to the WidgetPreviewWidget, not the actual creation location of the
    // WidgetPreviewWidget.annotation location
    final codeLocation = dtd.navigationEvents.single;
    expect(codeLocation.uri, kScriptUri);
    expect(codeLocation.line, kLine);
    expect(codeLocation.column, kColumn);
  });

  testWidgets('Embedded DevTools Widget Inspector can be toggled', (
    tester,
  ) async {
    final controller = FakeWidgetPreviewScaffoldController();
    final widgetPreview = TestWidgetPreviewScaffold(controller: controller);

    await tester.pumpWidget(widgetPreview);

    final Finder widgetInspectorToggleFinder = find.byType(
      WidgetInspectorToggle,
    );
    // We use the presence of a SplitPane to determine if the embedded widget inspector is open
    // rather than trying to create test implementations for all components needed for
    // WebViewWidget.
    //
    // The widget inspector is hidden by default.
    final Finder splitFinder = find.byType(SplitPane);
    expect(widgetInspectorToggleFinder, findsOne);
    expect(controller.widgetInspectorVisible.value, false);
    expect(splitFinder, findsNothing);

    // Display the embedded widget inspector.
    await tester.tap(widgetInspectorToggleFinder);
    await tester.pump();

    expect(widgetInspectorToggleFinder, findsOne);
    expect(controller.widgetInspectorVisible.value, true);
    expect(splitFinder, findsOne);

    // Hide the embedded widget inspector.
    await tester.tap(widgetInspectorToggleFinder);
    await tester.pump();

    expect(widgetInspectorToggleFinder, findsOne);
    expect(controller.widgetInspectorVisible.value, false);
    expect(splitFinder, findsNothing);
  });
}

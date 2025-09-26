// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/controls.dart';
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  const kScript1 = 'file:///script1.dart';
  const kScript2 = 'file:///script2.dart';
  final previews = <WidgetPreview>[
    WidgetPreview(
      builder: () => Text('widget1'),
      scriptUri: kScript1,
      previewData: Preview(group: 'group'),
      packageName: '',
    ),
    WidgetPreview(
      builder: () => Text('widget2'),
      scriptUri: kScript2,
      previewData: Preview(group: 'group'),
      packageName: '',
    ),
  ];

  late FakeWidgetPreviewScaffoldDtdServices dtdServices;
  late FakeWidgetPreviewScaffoldController controller;
  late WidgetPreviewScaffold widgetPreview;

  setUp(() async {
    dtdServices = FakeWidgetPreviewScaffoldDtdServices();
    controller = FakeWidgetPreviewScaffoldController(
      dtdServicesOverride: dtdServices,
      previews: previews,
    );
    await controller.initialize();
    widgetPreview = WidgetPreviewScaffold(controller: controller);
  });

  testWidgets('Filter previews based on currently selected file', (
    tester,
  ) async {
    // Ensure the Editor service is available.
    expect(dtdServices.editorServiceAvailable.value, true);

    // No file is selected, so no previews should be visible.
    await tester.pumpWidget(widgetPreview);
    expect(controller.filterBySelectedFileListenable.value, true);
    expect(dtdServices.selectedSourceFile.value, isNull);
    expect(controller.filteredPreviewSetListenable.value, isEmpty);

    // Select kScript1
    dtdServices.selectedSourceFile.value = TextDocument(
      uriAsString: kScript1,
      version: 0,
    );
    await tester.pumpWidget(widgetPreview);

    // Verify only previews from kScript1 are displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, kScript1);
    expect(
      controller
          .filteredPreviewSetListenable
          .value
          .single
          .previews
          .single
          .scriptUri,
      kScript1,
    );

    // Select a 'null' script. This simulates focusing on a non-source file
    // (e.g., the embedded widget previewer).
    dtdServices.selectedSourceFile.value = null;

    // Verify the selected source file is null but previews from kScript1 are
    // still displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, null);
    expect(
      controller
          .filteredPreviewSetListenable
          .value
          .single
          .previews
          .single
          .scriptUri,
      kScript1,
    );

    // Select kScript2
    dtdServices.selectedSourceFile.value = TextDocument(
      uriAsString: kScript2,
      version: 0,
    );
    await tester.pumpWidget(widgetPreview);

    // Verify only previews from kScript2 are displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, kScript2);
    expect(
      controller
          .filteredPreviewSetListenable
          .value
          .single
          .previews
          .single
          .scriptUri,
      kScript2,
    );

    final Finder filterBySelectedFileToggle = find.byType(
      FilterBySelectedFileToggle,
    );

    // Press the "Filter by selected file" button and disable preview filtering.
    expect(controller.filterBySelectedFileListenable.value, true);
    await tester.tap(filterBySelectedFileToggle);
    expect(controller.filterBySelectedFileListenable.value, false);
    // Verify the currently selected source is still kScript2 but all previews are displayed.
    expect(dtdServices.selectedSourceFile.value?.uriAsString, kScript2);
    expect(controller.filteredPreviewSetListenable.value, hasLength(1));
    expect(
      controller.filteredPreviewSetListenable.value.first.previews,
      previews,
    );
  });

  testWidgets('Filter previews is responsive to Editor service availablility', (
    tester,
  ) async {
    // Disable the Editor service to mimic a preview session not managed by an IDE.
    dtdServices.editorServiceAvailable.value = false;

    // The Editor service isn't available, so the filter by selected file toggle should not be
    // shown and all previews should be rendered.
    await tester.pumpWidget(widgetPreview);
    final Finder filterBySelectedFileToggle = find.byTooltip(
      FilterBySelectedFileToggle.kTooltip,
    );
    expect(filterBySelectedFileToggle, findsNothing);
    expect(controller.filteredPreviewSetListenable.value, hasLength(1));
    expect(
      controller.filteredPreviewSetListenable.value.first.previews,
      previews,
    );

    // Mimic an IDE registering the Editor service after the previewer starts.
    dtdServices.editorServiceAvailable.value = true;

    // The Editor service is available, so the filter by selected file toggle should be shown.
    await tester.pumpWidget(widgetPreview);
    expect(filterBySelectedFileToggle, findsOne);

    // No file is selected, so no previews should be visible.
    await tester.pumpWidget(widgetPreview);
    expect(controller.filterBySelectedFileListenable.value, true);
    expect(dtdServices.selectedSourceFile.value, isNull);
    expect(controller.filteredPreviewSetListenable.value, isEmpty);
  });
}
